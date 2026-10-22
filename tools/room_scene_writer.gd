extends RefCounted

## Turns a read layout (tools/room_layout.gd) into a room scene written as TEXT, and checks the scene it wrote
## (a helper, not a command; no class_name, preload it). The command line is tools/build_room.gd.
##
## Why text: a ResourceSaver re-save drops every uid (docs/game-base-plan.md 13.7), so the scene is written by hand
## as a .tscn with `uid=` on the header and on every [ext_resource], each taken from the file it names. The one thing
## that is not text is the TileMap's tile data: nobody hand-edits that blob (CLAUDE.md), so the tiles are PAINTED, cell
## by cell, through tools/cell_kind_painter.gd, which states the KIND of every cell next to the tile chosen for it
## and refuses a tile that does not read as that kind. The painted layer's own bytes are what the scene stores.
##
## The room is composed of individual tiles and markers (owner decision of 2026-10-12): no painted background, no
## polygons. The scene it writes has the shape of a hand-made room: a RoomEncounter root carrying the meta, a RoomArt
## node holding the TileMap and an empty SetDressing node for the owner's props, and the markers EcsBoot bakes.
##
##     var written := RoomSceneWriter.scene_text(layout, "")            # { "text", "problems", "text_rows" }
##     var problems := RoomSceneWriter.verify_scene(path, layout)       # boots the scene and compares the grid

const CellKindPainter := preload("res://tools/cell_kind_painter.gd")

const ROOM_ROOT_SCENE := "res://authoring/room_encounter.tscn"
const ACTOR_BASE_SCENE := "res://presentation/views/actors/actor_view_base.tscn"
const PICKUP_MARKER_SCENE := "res://authoring/markers/pickup_spawn_point.tscn"
const WEAPON_PICKUP_SCENE := "res://presentation/views/weapon_pickup.tscn"
const UNLOCK_MARKER_SCENE := "res://authoring/markers/player_unlock_marker.tscn"
const GATE_MARKER_SCENE := "res://authoring/markers/gate_marker.tscn"
const ENTRY_MARKER_SCRIPT := "res://authoring/markers/zone_entry_marker.gd"
const EXIT_MARKER_SCRIPT := "res://authoring/markers/zone_exit_marker.gd"
const TRAVERSAL_MARKER_SCRIPT := "res://authoring/markers/traversal_gap_marker.gd"
const VARIANT_MARKER_SCRIPT := "res://authoring/markers/state_variant_marker.gd"
## A scene's uid is made from its room id, so a rebuild of the same room keeps the uid and every reference to it.
const UID_SEED_PREFIX := "unbound-pawn-room:"


## Builds the scene text for `layout`. `kept_header_uid_text` is the uid of a scene already at the target path
## ("" for a new scene). Returns { "text": String, "problems": PackedStringArray, "text_rows": Array[Dictionary] }
## where `text_rows` lists the English rows the scene's text keys need ({ key, text, purpose }), for the
## builder to add to content/story/text/en/rooms.po. `text` is empty when there are problems.
static func scene_text(layout: RefCounted, kept_header_uid_text: String) -> Dictionary:
	var answer := {"text": "", "problems": PackedStringArray(), "text_rows": [] as Array[Dictionary]}
	if not (layout.problems as PackedStringArray).is_empty():
		answer["problems"] = (layout.problems as PackedStringArray).duplicate()
		return answer
	var problems := PackedStringArray()
	var tileset_path := ContentDb.path_of(&"tilesets", StringName(layout.tileset_id))
	var tile_set := load(tileset_path) as TileSet
	if tile_set == null:
		problems.append("the tileset %s does not load" % tileset_path)
		answer["problems"] = problems
		return answer

	var board_origin := EcsGrid.centred_origin(layout.size, 32, EcsBoot.project_view_size())
	var tile_data_text := _painted_tile_data(layout, tile_set, board_origin, problems)
	if not problems.is_empty():
		answer["problems"] = problems
		return answer

	var resources := ExternalResources.new()
	var root_scene_id := resources.add("PackedScene", ROOM_ROOT_SCENE, "room")
	var tileset_id := resources.add("TileSet", tileset_path, "tileset")
	var node_blocks := PackedStringArray()
	var text_rows: Array[Dictionary] = []

	var root_block := PackedStringArray()
	root_block.append("[node name=\"%s\" instance=ExtResource(\"%s\")]" % [_root_node_name(layout.room_id), root_scene_id])
	root_block.append("room_message = \"%s\"" % layout.text_key("START"))
	root_block.append("zone_id = &\"%s\"" % layout.room_id)
	root_block.append("board_size = Vector2i(%d, %d)" % [layout.size.x, layout.size.y])
	if layout.checkpoint_on_entry:
		root_block.append("checkpoint_on_entry = true")
	root_block.append("act = %d" % layout.act)
	root_block.append("district = &\"%s\"" % layout.district)
	root_block.append("layout_archetype = &\"%s\"" % layout.archetype)
	root_block.append("recipe = %d" % layout.recipe)
	root_block.append("content_status = %d" % layout.status)
	root_block.append("time_of_night = %d" % layout.time_of_night)
	if layout.objective_kind != RoomEncounter.ObjectiveKind.CLEAR:
		root_block.append("objective_kind = %d" % layout.objective_kind)
	if layout.threat_budget != 0:
		root_block.append("threat_budget = %d" % layout.threat_budget)
	if layout.threat_shapes != 0:
		root_block.append("threat_shapes = %d" % layout.threat_shapes)
	if layout.intro:
		root_block.append("intro = true")
	if layout.intensity != 0:
		root_block.append("intensity = %d" % layout.intensity)
	node_blocks.append("\n".join(root_block))
	text_rows.append({"key": layout.text_key("NAME"), "text": layout.name_text, "purpose": "the room's name on the save card and the checkpoint line"})
	text_rows.append({"key": layout.text_key("START"), "text": layout.start_text, "purpose": "what the room says as the pawn comes in"})

	node_blocks.append("[node name=\"RoomArt\" type=\"Node2D\" parent=\".\"]\nz_index = -20")
	node_blocks.append("[node name=\"TileMap\" type=\"TileMapLayer\" parent=\"RoomArt\"]\nposition = Vector2(%s, %s)\ntile_set = ExtResource(\"%s\")\ntile_map_data = PackedByteArray(\"%s\")" % [_number(board_origin.x), _number(board_origin.y), tileset_id, tile_data_text])
	node_blocks.append("[node name=\"SetDressing\" type=\"Node2D\" parent=\"RoomArt\"]")

	for placement in layout.placements():
		var block := _placement_block(layout, placement, board_origin, resources, text_rows, problems)
		if not block.is_empty():
			node_blocks.append(block)
	if not problems.is_empty():
		answer["problems"] = problems
		return answer

	var header_uid_text := kept_header_uid_text if not kept_header_uid_text.is_empty() else uid_text_for_room(layout.room_id)
	var text := PackedStringArray()
	text.append("[gd_scene load_steps=%d format=3 uid=\"%s\"]" % [resources.count() + 1, header_uid_text])
	text.append("")
	text.append(resources.lines())
	text.append("")
	text.append("\n\n".join(node_blocks))
	answer["text"] = "\n".join(text) + "\n"
	answer["text_rows"] = text_rows
	return answer


## The uid every build of room `room_id` gives its scene: a hash of the id, so it is the same on every machine and on
## every rebuild. (ResourceUID ids are 63-bit.)
static func uid_text_for_room(room_id: String) -> String:
	var digest := (UID_SEED_PREFIX + room_id).sha256_buffer()
	var uid_value := 0
	for byte_index in range(8):
		uid_value = (uid_value << 8) | int(digest[byte_index])
	uid_value = uid_value & 0x7FFFFFFFFFFFFFFF
	return ResourceUID.id_to_text(maxi(uid_value, 1))


## The root node's name: the first word of the id in capitals, then the rest in PascalCase (t3_first_pawn_clash ->
## T3_FirstPawnClash), as the hand-made rooms are named.
static func _root_node_name(room_id: String) -> String:
	var words := room_id.split("_", false)
	var rest := PackedStringArray()
	for word_index in range(1, words.size()):
		rest.append(words[word_index].capitalize())
	return "%s_%s" % [words[0].to_upper(), "".join(rest)] if not rest.is_empty() else words[0].to_upper()


## Paints the board and returns the layer's bytes as base64 (what a scene stores for tile_map_data).
## Every cell goes through CellKindPainter.paint() with the kind the layout states; floor cells alternate
## between the first two floor tiles of the kit in a checker, so the grid reads without a grid-line overlay.
static func _painted_tile_data(layout: RefCounted, tile_set: TileSet, board_origin: Vector2, problems: PackedStringArray) -> String:
	var painter := CellKindPainter.new(tile_set)
	var layer := TileMapLayer.new()
	layer.tile_set = tile_set
	layer.position = board_origin
	var floor_tiles := painter.atlas_coords_of_kind(CellKinds.FLOOR)
	for row_index in range(layout.size.y):
		for column_index in range(layout.size.x):
			var cell := Vector2i(column_index, row_index)
			var kind: StringName = layout.kind_at(cell)
			var preferred := CellKindPainter.NO_PREFERENCE
			if kind == CellKinds.FLOOR and floor_tiles.size() >= 2:
				preferred = floor_tiles[(column_index + row_index) % 2]
			var painted_problem := painter.paint(layer, cell, kind, preferred)
			if not painted_problem.is_empty():
				problems.append("%s (the %s '%s' of the layout)" % [painted_problem, kind, layout.character_at(cell)])
				layer.free()
				return ""
	var kind_by_cell := painter.kinds_by_cell(layer)
	for row_index in range(layout.size.y):
		for column_index in range(layout.size.x):
			var cell := Vector2i(column_index, row_index)
			if kind_by_cell.get(cell, &"") != layout.kind_at(cell):
				problems.append("cell %s was painted as '%s' but the layout says '%s'" % [cell, kind_by_cell.get(cell, &""), layout.kind_at(cell)])
	var base64 := Marshalls.raw_to_base64(layer.tile_map_data)
	layer.free()
	return base64


static func _placement_block(layout: RefCounted, placement: Dictionary, board_origin: Vector2, resources: RefCounted, text_rows: Array[Dictionary], problems: PackedStringArray) -> String:
	var params: Dictionary = placement["params"]
	var flags: Array = placement["flags"]
	var node_name: String = placement["name"]
	var cell: Vector2i = placement["cell"]
	var position_text := "position = Vector2(%s, %s)" % [_number(board_origin.x + cell.x * 32 + 16), _number(board_origin.y + cell.y * 32 + 16)]
	var lines := PackedStringArray()
	match placement["kind"]:
		"entry":
			var script_id: String = resources.add("Script", ENTRY_MARKER_SCRIPT, "entry")
			lines.append("[node name=\"%s\" type=\"Marker2D\" parent=\".\"]" % node_name)
			lines.append(position_text)
			lines.append("script = ExtResource(\"%s\")" % script_id)
			lines.append("entry_id = &\"%s\"" % params["id"])
		"exit":
			var script_id: String = resources.add("Script", EXIT_MARKER_SCRIPT, "exit")
			var target_parts := String(params["to"]).split(":")
			lines.append("[node name=\"%s\" type=\"Marker2D\" parent=\".\"]" % node_name)
			lines.append(position_text)
			lines.append("script = ExtResource(\"%s\")" % script_id)
			lines.append("target_zone = &\"%s\"" % target_parts[0])
			lines.append("target_entry = &\"%s\"" % target_parts[1])
			if flags.has("clear") or params.has("needs_flag"):
				var key: String = layout.locked_key_of(placement)
				if flags.has("clear"):
					lines.append("requires_room_clear = true")
				if params.has("needs_flag"):
					lines.append("requires_flag = &\"%s\"" % params["needs_flag"])
				lines.append("locked_message = \"%s\"" % key)
				if params.has("locked"):
					text_rows.append({"key": key, "text": String(params["locked"]), "purpose": "say what holds this door"})
		"ending_exit":
			var script_id: String = resources.add("Script", EXIT_MARKER_SCRIPT, "exit")
			lines.append("[node name=\"%s\" type=\"Marker2D\" parent=\".\"]" % node_name)
			lines.append(position_text)
			lines.append("script = ExtResource(\"%s\")" % script_id)
			lines.append("target_zone = &\"\"")
			lines.append("ends_run = true")
		"enemy":
			var enemy_path := ContentDb.path_of(&"enemies", StringName(String(params["def"])))
			var base_id: String = resources.add("PackedScene", ACTOR_BASE_SCENE, "actor")
			var definition_id: String = resources.add("Resource", enemy_path, "enemy_%s" % params["def"])
			lines.append("[node name=\"%s\" parent=\".\" instance=ExtResource(\"%s\")]" % [node_name, base_id])
			lines.append(position_text)
			lines.append("definition = ExtResource(\"%s\")" % definition_id)
		"pickup":
			var weapon_path := ContentDb.path_of(&"pickups", StringName(String(params["weapon"])))
			var marker_id: String = resources.add("PackedScene", PICKUP_MARKER_SCENE, "pickup")
			var view_id: String = resources.add("PackedScene", WEAPON_PICKUP_SCENE, "pickup_view")
			var weapon_id: String = resources.add("Resource", weapon_path, "weapon_%s" % params["weapon"])
			lines.append("[node name=\"%s\" parent=\".\" instance=ExtResource(\"%s\")]" % [node_name, marker_id])
			lines.append("pickup_scene = ExtResource(\"%s\")" % view_id)
			lines.append("grid_cell = Vector2i(%d, %d)" % [cell.x, cell.y])
			lines.append("weapon = ExtResource(\"%s\")" % weapon_id)
			if flags.has("persistent"):
				lines.append("persistent = true")
		"unlock":
			var unlock_scene_id: String = resources.add("PackedScene", UNLOCK_MARKER_SCENE, "unlock")
			lines.append("[node name=\"%s\" parent=\".\" instance=ExtResource(\"%s\")]" % [node_name, unlock_scene_id])
			lines.append("grid_cell = Vector2i(%d, %d)" % [cell.x, cell.y])
			lines.append("unlock_id = &\"%s\"" % params["id"])
			var unlock_key: String = layout.unlock_key_of(placement)
			if not unlock_key.is_empty():
				lines.append("message = \"%s\"" % unlock_key)
				text_rows.append({"key": unlock_key, "text": String(params["text"]), "purpose": "the pawn gains the verb"})
		"gate":
			var gate_scene_id: String = resources.add("PackedScene", GATE_MARKER_SCENE, "gate")
			var opens: Vector2i = RoomLayoutReader.OPENS_DIRECTIONS[String(params.get("opens", "left"))]
			lines.append("[node name=\"%s\" parent=\".\" instance=ExtResource(\"%s\")]" % [node_name, gate_scene_id])
			lines.append(position_text)
			lines.append("gate_id = &\"%s\"" % params["id"])
			lines.append("opens_from = Vector2i(%d, %d)" % [opens.x, opens.y])
		"traversal":
			var script_id: String = resources.add("Script", TRAVERSAL_MARKER_SCRIPT, "traversal")
			var cells: Array = placement["cells"]
			var direction := Vector2i.RIGHT
			if cells.size() > 1:
				direction = (cells[1] as Vector2i) - (cells[0] as Vector2i)
			lines.append("[node name=\"%s\" type=\"Node2D\" parent=\".\"]" % node_name)
			lines.append("script = ExtResource(\"%s\")" % script_id)
			lines.append("grid_cell = Vector2i(%d, %d)" % [cell.x, cell.y])
			lines.append("verb = &\"%s\"" % params["verb"])
			lines.append("length = %d" % cells.size())
			lines.append("direction = Vector2i(%d, %d)" % [direction.x, direction.y])
			lines.append("free_when_calm = %s" % ("false" if flags.has("costly") else "true"))
		"variant":
			var script_id: String = resources.add("Script", VARIANT_MARKER_SCRIPT, "variant")
			lines.append("[node name=\"%s\" type=\"Node2D\" parent=\".\"]" % node_name)
			lines.append(position_text)
			lines.append("script = ExtResource(\"%s\")" % script_id)
			lines.append("variant_id = &\"%s\"" % params["id"])
			lines.append("requires_flags = %s" % _flag_array(String(params.get("requires", ""))))
			lines.append("forbids_flags = %s" % _flag_array(String(params.get("forbids", ""))))
		_:
			problems.append("the writer does not know the kind '%s'" % placement["kind"])
			return ""
	return "\n".join(lines)


static func _flag_array(comma_separated: String) -> String:
	var items := PackedStringArray()
	for flag_text in comma_separated.split(",", false):
		items.append("&\"%s\"" % flag_text.strip_edges())
	return "Array[StringName]([%s])" % ", ".join(items)


## 144.0 -> "144", 144.5 -> "144.5": how a scene file writes a coordinate.
static func _number(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else String.num(value, 4)


## The [ext_resource] lines of a scene being written: one per file, an id made of a running number and a label, the
## uid of the file as Godot knows it (a scene or resource's header, a script's .uid sidecar, a picture's .import).
class ExternalResources:
	extends RefCounted

	var _entries: Array[Dictionary] = []
	var _id_by_path: Dictionary = {}

	## The id the scene uses for `path`, adding the line the first time.
	func add(resource_type: String, path: String, label: String) -> String:
		if _id_by_path.has(path):
			return _id_by_path[path]
		var resource_id := "%d_%s" % [_entries.size() + 1, label.replace(" ", "_")]
		_entries.append({"type": resource_type, "path": path, "id": resource_id})
		_id_by_path[path] = resource_id
		return resource_id

	func count() -> int:
		return _entries.size()

	func lines() -> String:
		var found := PackedStringArray()
		for entry in _entries:
			var uid_text := ""
			var uid_value := ResourceLoader.get_resource_uid(entry["path"])
			if uid_value != ResourceUID.INVALID_ID:
				uid_text = " uid=\"%s\"" % ResourceUID.id_to_text(uid_value)
			found.append("[ext_resource type=\"%s\"%s path=\"%s\" id=\"%s\"]" % [entry["type"], uid_text, entry["path"], entry["id"]])
		return "\n".join(found)


## Reads the OPENS_DIRECTIONS table without a second copy of it.
const RoomLayoutReader := preload("res://tools/room_layout.gd")


# --------------------------------------------------------------------------- checking the written scene
## Loads the scene at `scene_path`, boots it the way the game boots a room and compares what the grid holds with what
## the layout says: every cell's kind, every entry, door, enemy, pickup, unlock, gate and crossing on its cell, and
## the room's own meta. One sentence per difference; empty = the scene is the layout.
static func verify_scene(scene_path: String, layout: RefCounted) -> PackedStringArray:
	var problems := PackedStringArray()
	var scene := ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if scene == null or not scene.can_instantiate():
		problems.append("%s does not load as a scene" % scene_path)
		return problems
	var room := scene.instantiate()
	# In the tree, as in the game: a grid marker follows its room's board when it is ready, not when it is made.
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.root.add_child(room)
	var world := EcsWorld.new()
	var cast := EcsBoot.boot(world, EcsBootOptions.for_scene(null, room))
	var grid := world.grid

	if grid.bounds.size != layout.size:
		problems.append("the booted board is %s but the layout is %s" % [grid.bounds.size, layout.size])
	for row_index in range(layout.size.y):
		for column_index in range(layout.size.x):
			var cell := Vector2i(column_index, row_index)
			if grid.kind_at(cell) != layout.booted_kind_at(cell):
				problems.append("cell %s boots as '%s' but the layout says '%s'" % [cell, grid.kind_at(cell), layout.booted_kind_at(cell)])

	var room_encounter := room as RoomEncounter
	if room_encounter == null:
		problems.append("the scene root is not a RoomEncounter")
	else:
		for sentence in room_encounter.configuration_problems():
			problems.append("the room's meta: %s" % sentence)
		if room_encounter.zone_id != StringName(layout.room_id) or room_encounter.board_size != layout.size:
			problems.append("the room's zone_id or board_size differs from the layout")

	var enemy_cells: Array[Vector2i] = []
	for child in room.get_children():
		var view := child as ActorView
		if view != null and view.definition != null:
			enemy_cells.append(grid.world_to_cell(view.position))
	for placement in layout.placements():
		var cell: Vector2i = placement["cell"]
		var node := room.get_node_or_null(String(placement["name"]))
		if node == null:
			problems.append("the %s %s is not in the scene" % [placement["kind"], placement["name"]])
			continue
		match placement["kind"]:
			"entry":
				if grid.world_to_cell((node as Node2D).position) != cell:
					problems.append("the entry %s stands on %s but the layout says %s" % [placement["name"], grid.world_to_cell((node as Node2D).position), cell])
			"exit":
				var baked: Dictionary = grid.exit_by_cell.get(cell, {})
				var target_parts := String(placement["params"]["to"]).split(":")
				if baked.is_empty() or String(baked["zone"]) != target_parts[0] or String(baked["entry"]) != target_parts[1] or bool(baked["requires_room_clear"]) != placement["flags"].has("clear") \
						or String(baked.get("requires_flag", "")) != String(placement["params"].get("needs_flag", "")):
					problems.append("the door %s is not baked on %s as the layout says (%s)" % [placement["name"], cell, baked])
			"ending_exit":
				if not bool(grid.exit_by_cell.get(cell, {}).get("ends_run", false)):
					problems.append("the door that ends the run (%s) is not baked on %s" % [placement["name"], cell])
			"enemy":
				if cell not in enemy_cells or (node as ActorView).definition == null or (node as ActorView).definition.resource_path != ContentDb.path_of(&"enemies", StringName(String(placement["params"]["def"]))):
					problems.append("the enemy %s is not on %s with the definition %s" % [placement["name"], cell, placement["params"]["def"]])
			"pickup":
				if grid.item_at(cell) == 0:
					problems.append("no pickup was baked on %s for %s" % [cell, placement["name"]])
			"unlock":
				if String(grid.player_unlock_by_cell.get(cell, {}).get("id", "")) != String(placement["params"]["id"]):
					problems.append("the unlock %s is not baked on %s" % [placement["name"], cell])
			"gate":
				if String(grid.gate_by_cell.get(cell, {}).get("id", "")) != String(placement["params"]["id"]):
					problems.append("the gate %s is not baked on %s" % [placement["name"], cell])
			"traversal":
				for crossing_cell: Vector2i in placement["cells"]:
					if not grid.has_marker(TraversalGapMarker.KIND, crossing_cell) or grid.kind_at(crossing_cell) != CellKinds.GAP:
						problems.append("the crossing %s is not a baked traversal gap over a gap on %s" % [placement["name"], crossing_cell])
				for sentence in (node as TraversalGapMarker).configuration_problems():
					problems.append("the crossing %s: %s" % [placement["name"], sentence])
			"variant":
				for sentence in (node as StateVariantMarker).configuration_problems():
					problems.append("the variant %s: %s" % [placement["name"], sentence])
	if (cast["enemies"] as Array).size() != _count_of(layout, "enemy"):
		problems.append("%d enemies booted but the layout places %d" % [(cast["enemies"] as Array).size(), _count_of(layout, "enemy")])
	if room.get_parent() != null:
		room.get_parent().remove_child(room)
	room.free()
	world.free()
	return problems


static func _count_of(layout: RefCounted, kind: String) -> int:
	var total := 0
	for placement in layout.placements():
		if placement["kind"] == kind:
			total += 1
	return total
