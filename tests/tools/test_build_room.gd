extends UnboundTest

## tools/build_room.gd (docs/game-base-plan.md 7.5, 15 M5): an ASCII layout becomes a room scene written as TEXT with
## uids, its tiles painted through the cell-kind painter, and the scene it wrote is booted and compared with the layout
## before it is kept. This suite holds the promises the plan makes of it:
##
##  - THE PROOF. The Stage 1 room t4_broken_rule_yard, drawn as a layout and built into a scratch folder, boots to the
##    same grid as the hand-made scene: bounds, origin, every cell's kind, doors, entries, enemies, the pickup and the
##    room's meta. The real Stage 1 scenes are never touched, not even when forced.
##  - IT REFUSES to overwrite a scene unless the scene is the tool's own, unedited output (the manifest), and says why.
##  - EVERY KIND on the legend builds and boots: terrain (gap, leapable block, chalk, corruption), entry, door,
##    enemy, pickup, unlock, gate, traversal crossing, state variant.
##  - A build that fails leaves nothing behind. Output is deterministic. The text rows land in rooms.po once.
##  - The shipped tb1 scene is the tool's output for its layout while nobody has edited it.

const RoomLayout := preload("res://tools/room_layout.gd")
const RoomBuilder := preload("res://tools/room_builder.gd")
const RoomSceneWriter := preload("res://tools/room_scene_writer.gd")
const BuiltRoomsManifest := preload("res://tools/built_rooms_manifest.gd")
const CellKindPainter := preload("res://tools/cell_kind_painter.gd")

const SCRATCH_ROOT := "user://build_room_test"
const T4_LAYOUT := "res://tests/fixtures/layouts/t4_broken_rule_yard.txt"
const T4_HAND_MADE := "res://content/rooms/t4_broken_rule_yard/room.tscn"
const TB1_LAYOUT := "res://tools/layouts/tb1_toybox_gate.txt"
const TB1_SCENE := "res://content/rooms/tb1_toybox_gate/room.tscn"

## Every kind of object and every kind of terrain on one board (18x9, an arena, so the centred origin is covered too).
const KITCHEN_SINK_LAYOUT := """[room]
id = kitchen_sink
size = 18x9
act = 3
district = bookshelf
archetype = islands
recipe = boss
status = greybox
time_of_night = small_hours
checkpoint_on_entry = true
tileset = greybox
name = Kitchen Sink
start = Everything the builder knows, once.

[grid]
##################
#................#
#.A.....oo...=...#
#..B....oo....+..#
#.......oo.......#
#...C.C..GGG.R~~.#
#..P....H...U..F.#
#...S.....Z......#
##################

[objects]
A = entry id=start
B = exit to=h1_chess_rug_hub:from_boss clear locked="Not until every piece is down."
C = enemy def=pawn_recruit
R = enemy def=knight_tracker name=KnightOnTheFar
P = pickup weapon=pencil_spear persistent
U = unlock id=rule_step text="The pawn learns to leap."
F = gate id=shortcut_gate opens=right
G = traversal verb=chalk_path
Z = traversal verb=rule_step
H = variant id=hub_state_2 requires=boss.knight_captain forbids=ending.boxed
S = entry id=second_door
"""


func _init() -> void:
	suite_title = "TEST BUILD ROOM"
	_remove_tree(SCRATCH_ROOT)
	DirAccess.make_dir_recursive_absolute(SCRATCH_ROOT)
	_the_proof_rebuild_of_a_stage_one_room()
	_the_stage_one_scenes_are_never_touched()
	_it_refuses_to_overwrite()
	_every_kind_builds_and_boots()
	_a_failed_build_leaves_nothing_behind()
	_the_text_rows_are_added_once()
	_the_shipped_scene_is_the_tools_output()
	_the_painter_lists_tiles_by_kind()
	_remove_tree(SCRATCH_ROOT)
	finish()


# --------------------------------------------------------------------------- the proof
func _the_proof_rebuild_of_a_stage_one_room() -> void:
	var scene_path := SCRATCH_ROOT.path_join("t4/room.tscn")
	var answer := _build(FileAccess.get_file_as_string(T4_LAYOUT), "t4_broken_rule_yard", scene_path)
	for problem: String in answer["problems"]:
		printerr("  %s" % problem)
	if not _expect(bool(answer["ok"]), "the Stage 1 room t4 drawn as a layout builds into a scratch folder"):
		return
	var built := _snapshot_of(load(scene_path) as PackedScene)
	var hand_made := _snapshot_of(load(T4_HAND_MADE) as PackedScene)
	for key: String in hand_made:
		_expect(built.get(key) == hand_made[key], "the rebuilt room boots to the hand-made room's %s%s" % [key, "" if built.get(key) == hand_made[key] else " (built %s, hand-made %s)" % [built.get(key), hand_made[key]]])
	_expect(built == hand_made, "...so the whole booted picture of the rebuilt room equals the hand-made one (%d facts compared)" % hand_made.size())
	_expect((hand_made["walls"] as Array).size() >= 50 and (hand_made["enemies"] as Dictionary).size() == 3 and (hand_made["exits"] as Dictionary).size() == 2 and (hand_made["entries"] as Dictionary).size() == 2 and (hand_made["pickups"] as Array).size() == 1, "setup: the picture compared is not empty (walls, three enemies, two doors, two entries, one pickup)")

	# What the hand-made room does not have: tiles made of the kit's own tiles, cell by cell, in the checker.
	var room := (load(scene_path) as PackedScene).instantiate()
	var tile_layer := room.get_node("RoomArt/TileMap") as TileMapLayer
	_expect(tile_layer != null and tile_layer.tile_set != null and tile_layer.tile_set.resource_path == ContentDb.path_of(&"tilesets", &"kingdom"), "the rebuilt room's tiles are a TileMapLayer of the kit the layout names")
	_expect(tile_layer.get_used_cells().size() == 16 * 9 and tile_layer.position == Vector2(64, 36), "every cell of the board is painted, one tile each, from the board's origin")
	var painter := CellKindPainter.new(tile_layer.tile_set)
	var kind_by_cell := painter.kinds_by_cell(tile_layer)
	var layout: RefCounted = RoomLayout.parse(FileAccess.get_file_as_string(T4_LAYOUT), "t4_broken_rule_yard")
	var disagreements := 0
	for row in range(9):
		for column in range(16):
			if kind_by_cell.get(Vector2i(column, row)) != layout.kind_at(Vector2i(column, row)):
				disagreements += 1
	_expect(disagreements == 0, "and the kind each painted tile reads as is the kind the layout states for its cell")
	_expect(tile_layer.get_cell_atlas_coords(Vector2i(1, 1)) != tile_layer.get_cell_atlas_coords(Vector2i(2, 1)), "neighbouring floor cells alternate between the kit's two floor tiles, so the grid reads without an overlay")
	room.free()

	# The scene is plain text with a uid on its header and on every reference, and nothing a re-save would write.
	var text := FileAccess.get_file_as_string(scene_path)
	var header := text.get_slice("\n", 0)
	_expect(header.begins_with("[gd_scene") and header.contains("format=3") and header.contains("uid=\"uid://"), "the scene is text with a uid on its header (%s)" % header)
	var path_only_lines := 0
	var reference_lines := 0
	for line in text.split("\n"):
		if line.begins_with("[ext_resource"):
			reference_lines += 1
			if not line.contains("uid=\"uid://"):
				path_only_lines += 1
	_expect(reference_lines >= 8 and path_only_lines == 0, "...and a uid on every one of its %d [ext_resource] lines" % reference_lines)
	_expect(not text.contains("unique_id") and not text.contains("Polygon2D") and not text.contains("Line2D") and not text.contains("background"), "...and no painted background, polygon or line: the room is tiles and markers")


## The rebuild is a SCRATCH copy: whatever is asked of the tool, the real Stage 1 scenes keep their bytes.
func _the_stage_one_scenes_are_never_touched() -> void:
	var stage_one := [&"t1_white_kings_fall", &"t2_fallen_sword_tile", &"t3_first_pawn_clash", &"t4_broken_rule_yard", &"b1_black_pawn_captain", &"h1_chess_rug_hub"]
	var hash_before: Dictionary = {}
	for room_id: StringName in stage_one:
		hash_before[room_id] = FileAccess.get_sha256(ContentDb.path_of(&"rooms", room_id))
	var layout_text := FileAccess.get_file_as_string(T4_LAYOUT)
	var plain := _build(layout_text, "t4_broken_rule_yard", T4_HAND_MADE, false, SCRATCH_ROOT.path_join("manifest_plain.json"))
	_expect(not bool(plain["ok"]) and _says(plain, "already exists"), "asked to build over the hand-made t4, the tool refuses: the scene exists")
	var forced := _build(layout_text, "t4_broken_rule_yard", T4_HAND_MADE, true, SCRATCH_ROOT.path_join("manifest_forced.json"))
	_expect(not bool(forced["ok"]) and _says(forced, "the manifest has no row for it, so this tool did not build it"), "...and so does --force, because the tool did not build that scene")
	var tracked_manifest: Dictionary = BuiltRoomsManifest.read_manifest()
	for room_id: StringName in stage_one:
		_expect(not (tracked_manifest["scenes"] as Dictionary).has(ContentDb.path_of(&"rooms", room_id)), "the tracked manifest lists no Stage 1 scene, %s among them: the tool never built it" % room_id)
		_expect(FileAccess.get_sha256(ContentDb.path_of(&"rooms", room_id)) == hash_before[room_id], "%s has the bytes it had" % room_id)


# --------------------------------------------------------------------------- the refusal
func _it_refuses_to_overwrite() -> void:
	var layout_text := FileAccess.get_file_as_string(T4_LAYOUT)
	var scene_path := SCRATCH_ROOT.path_join("refusal/room.tscn")
	var manifest_path := SCRATCH_ROOT.path_join("refusal/built.json")
	var first := _build(layout_text, "t4_broken_rule_yard", scene_path, false, manifest_path)
	_expect(bool(first["ok"]), "a scene that does not exist is built")
	var built_hash := FileAccess.get_sha256(scene_path)
	var manifest: Dictionary = BuiltRoomsManifest.read_manifest(manifest_path)
	var row: Dictionary = (manifest["scenes"] as Dictionary).get(scene_path, {})
	_expect(row.get("room_id") == "t4_broken_rule_yard" and row.get("scene_sha256") == built_hash and row.get("layout_sha256") == layout_text.sha256_text(), "the manifest records what was built: the room, the layout's hash and the scene's hash")

	var again := _build(layout_text, "t4_broken_rule_yard", scene_path, false, manifest_path)
	_expect(not bool(again["ok"]) and _says(again, "already exists") and _says(again, "--force"), "a second build over the same scene is refused, and the sentence names the way out")
	_expect(FileAccess.get_sha256(scene_path) == built_hash, "...and the scene is untouched")

	var forced := _build(layout_text, "t4_broken_rule_yard", scene_path, true, manifest_path)
	_expect(bool(forced["ok"]) and FileAccess.get_sha256(scene_path) == built_hash, "--force rebuilds a scene the tool built and nobody edited, and the bytes are the same (the build is deterministic, the uid comes from the id)")

	# The owner opens the scene and moves a marker: the scene is the truth now.
	var edited_text := FileAccess.get_file_as_string(scene_path).replace("position = Vector2(464, 180)", "position = Vector2(464, 212)")
	_write(scene_path, edited_text)
	var after_edit := _build(layout_text, "t4_broken_rule_yard", scene_path, true, manifest_path)
	_expect(not bool(after_edit["ok"]) and _says(after_edit, "was edited after the tool built it"), "--force is refused once the scene was edited since the tool built it: the owner's work is not thrown away")
	_expect(FileAccess.get_file_as_string(scene_path) == edited_text, "...and the edited scene is exactly as the owner left it")

	# A scene the tool did not build, however it came to be there.
	var stranger_path := SCRATCH_ROOT.path_join("refusal/stranger.tscn")
	_write(stranger_path, "[gd_scene format=3]\n\n[node name=\"Stranger\" type=\"Node2D\"]\n")
	var stranger := _build(layout_text, "t4_broken_rule_yard", stranger_path, true, manifest_path)
	_expect(not bool(stranger["ok"]) and _says(stranger, "this tool did not build it"), "--force is refused for a scene the manifest has no row for")
	_expect(FileAccess.get_file_as_string(stranger_path).contains("Stranger"), "...and that scene is untouched")

	# A manifest that is not a manifest stops the build before anything is written.
	_write(SCRATCH_ROOT.path_join("refusal/broken.json"), "[1, 2, 3]")
	var broken := _build(layout_text, "t4_broken_rule_yard", SCRATCH_ROOT.path_join("refusal/new/room.tscn"), false, SCRATCH_ROOT.path_join("refusal/broken.json"))
	_expect(not bool(broken["ok"]) and _says(broken, "is not a manifest") and not FileAccess.file_exists(SCRATCH_ROOT.path_join("refusal/new/room.tscn")), "a manifest that is not a manifest stops the build, and nothing is written")

	# A layout with a problem builds nothing.
	var bad := _build(layout_text.replace("id = t4_broken_rule_yard", "id = t5_other"), "t4_broken_rule_yard", SCRATCH_ROOT.path_join("refusal/bad/room.tscn"), false, manifest_path)
	_expect(not bool(bad["ok"]) and _says(bad, "the file is called t4_broken_rule_yard.txt") and not FileAccess.file_exists(SCRATCH_ROOT.path_join("refusal/bad/room.tscn")), "a layout with a problem is refused with its sentence, and nothing is written")


# --------------------------------------------------------------------------- every kind
func _every_kind_builds_and_boots() -> void:
	var scene_path := SCRATCH_ROOT.path_join("sink/room.tscn")
	var answer := _build(KITCHEN_SINK_LAYOUT, "kitchen_sink", scene_path)
	for problem: String in answer["problems"]:
		printerr("  %s" % problem)
	if not _expect(bool(answer["ok"]), "a layout with every kind of terrain and every kind of object builds, boots and matches (the builder checks the grid itself)"):
		return
	var scene := load(scene_path) as PackedScene
	var room := scene.instantiate()
	var world := EcsWorld.new()
	var cast := EcsBoot.boot(world, EcsBootOptions.for_scene(null, room))
	var grid := world.grid

	_expect(grid.bounds.size == Vector2i(18, 9) and grid.grid_origin == Vector2(32, 36), "an 18x9 arena boots with the arena origin (32, 36)")
	_expect(grid.kind_at(Vector2i(8, 2)) == CellKinds.GAP and grid.kind_at(Vector2i(13, 2)) == CellKinds.CHALK and grid.kind_at(Vector2i(14, 3)) == CellKinds.LEAPABLE_BLOCK and grid.kind_at(Vector2i(14, 5)) == CellKinds.CORRUPTION and grid.kind_at(Vector2i(0, 0)) == CellKinds.WALL and grid.kind_at(Vector2i(5, 5)) == CellKinds.FLOOR,
		"o is a gap, = chalk, + a leapable block, ~ corruption, # a wall and . floor (the cell kinds the tiles say)")
	_expect(grid.is_walkable(Vector2i(13, 2)) and grid.is_walkable(Vector2i(14, 5)) and not grid.is_walkable(Vector2i(8, 2)) and not grid.is_walkable(Vector2i(14, 3)), "chalk and corruption can be walked on; a gap and a block cannot")

	_expect(grid.exit_by_cell.get(Vector2i(3, 3), {}) == {"zone": &"h1_chess_rug_hub", "entry": &"from_boss", "requires_room_clear": true, "locked_message": "ROOM_KITCHEN_SINK_LOCKED"}, "a door is baked with its target, its clear lock and its line")
	_expect((cast["enemies"] as Array).size() == 3, "three enemies boot (the character C twice, R once)")
	_expect(room.get_node_or_null("PawnRecruit") != null and room.get_node_or_null("PawnRecruit_2") != null and room.get_node_or_null("KnightOnTheFar") != null, "repeated enemies are numbered and a given name= is kept")
	_expect(grid.item_at(Vector2i(3, 6)) != 0 and (cast["persistent_pickup_by_entity"] as Dictionary).size() == 1 and (cast["pickup_name_by_entity"] as Dictionary).values() == ["PencilSpearPickup"], "a pickup is baked, persistent, named after its weapon")
	_expect(grid.player_unlock_by_cell.get(Vector2i(12, 6), {}) == {"id": &"rule_step", "message": "ROOM_KITCHEN_SINK_UNLOCK_RULE_STEP"}, "an unlock is baked on its cell with its id and its line")
	_expect(grid.gate_by_cell.get(Vector2i(15, 6), {}) == {"id": &"shortcut_gate", "opens_from": Vector2i.RIGHT} and not grid.is_walkable(Vector2i(15, 6)), "a gate is a wall that opens from its side")

	# Crossings: three neighbouring cells are one Chalk Path crossing; the lone one is a Rule Step hole.
	var chalk_gap := room.get_node("TraversalGap") as TraversalGapMarker
	var step_gap := room.get_node("TraversalGap_2") as TraversalGapMarker
	_expect(chalk_gap.verb == &"chalk_path" and chalk_gap.length == 3 and chalk_gap.direction == Vector2i.RIGHT and chalk_gap.grid_cell == Vector2i(9, 5) and chalk_gap.free_when_calm, "the three G cells are ONE free Chalk Path crossing of length 3 running right")
	_expect(step_gap.verb == &"rule_step" and step_gap.length == 1 and step_gap.grid_cell == Vector2i(10, 7), "...and the lone Z is a one-cell Rule Step hole")
	for cell in chalk_gap.get_cells():
		_expect(grid.has_marker(TraversalGapMarker.KIND, cell) and grid.kind_at(cell) == CellKinds.GAP, "the crossing cell %s is baked into the marker store over a gap" % cell)
	var variant := room.get_node("Variant_HubState2") as StateVariantMarker
	_expect(variant.variant_id == &"hub_state_2" and variant.requires_flags == [&"boss.knight_captain"] and variant.forbids_flags == [&"ending.boxed"] and variant.configuration_problems().is_empty(), "a state variant carries its id and its condition, and is clean")
	_expect(grid.world_to_cell(variant.position) == Vector2i(8, 6), "...and stands on its cell")

	var root_room := room as RoomEncounter
	_expect(root_room.checkpoint_on_entry and root_room.recipe == RoomEncounter.Recipe.BOSS and root_room.content_status == RoomEncounter.ContentStatus.GREYBOX and root_room.time_of_night == RoomEncounter.TimeOfNight.SMALL_HOURS and root_room.act == 3 and root_room.district == &"bookshelf" and root_room.layout_archetype == &"islands", "the meta of the layout is the meta of the root")
	room.free()
	world.free()


# --------------------------------------------------------------------------- a failed build
func _a_failed_build_leaves_nothing_behind() -> void:
	# The kingdom kit has no tile for a gap: the painter refuses, and the tool says which cell and what to do.
	var needs_a_gap := KITCHEN_SINK_LAYOUT.replace("tileset = greybox", "tileset = kingdom").replace("id = kitchen_sink", "id = needs_a_gap")
	var path := SCRATCH_ROOT.path_join("needs_a_gap/room.tscn")
	var answer := _build(needs_a_gap, "needs_a_gap", path)
	_expect(not bool(answer["ok"]) and _says(answer, "the TileSet has no tile whose kind is 'gap'") and _says(answer, "add one in the TileSet editor"), "a layout that needs a kind of cell the kit has no tile for is refused with the painter's sentence")
	_expect(not FileAccess.file_exists(path), "...and writes nothing")

	# When the scene it wrote does not match the layout the build is undone: a new scene is removed, a rebuilt one gets
	# its old text back. (The write itself cannot be made to fail from here, so the undo is exercised directly.)
	var undo_path := SCRATCH_ROOT.path_join("undo/room.tscn")
	_write(undo_path, "what the tool just wrote")
	RoomBuilder._put_back(undo_path, false, "")
	_expect(not FileAccess.file_exists(undo_path), "undoing a build that made a new scene removes it")
	_write(undo_path, "what the tool just wrote")
	RoomBuilder._put_back(undo_path, true, "what was there before")
	_expect(FileAccess.get_file_as_string(undo_path) == "what was there before", "...and undoing a rebuild puts the old scene back, byte for byte")


# --------------------------------------------------------------------------- the text rows
func _the_text_rows_are_added_once() -> void:
	var po_path := SCRATCH_ROOT.path_join("rooms.po")
	var original := FileAccess.get_file_as_string("res://content/story/text/en/rooms.po")
	_write(po_path, original)
	var scene_path := SCRATCH_ROOT.path_join("rows/room.tscn")
	var manifest_path := SCRATCH_ROOT.path_join("rows/built.json")
	var options := {
		"layout_text": KITCHEN_SINK_LAYOUT, "expected_id": "kitchen_sink", "scene_path": scene_path, "manifest_path": manifest_path, "text_rows_path": po_path,
	}
	var first := RoomBuilder.build(options)
	var expected_keys: Array[String] = ["ROOM_KITCHEN_SINK_NAME", "ROOM_KITCHEN_SINK_START", "ROOM_KITCHEN_SINK_LOCKED", "ROOM_KITCHEN_SINK_UNLOCK_RULE_STEP"]
	_expect(bool(first["ok"]) and first["added_text_keys"] == expected_keys, "the English rows the scene's text keys need are added: name, start, the shut door's line and the unlock's line (%s)" % [first["added_text_keys"]])
	var po_text := FileAccess.get_file_as_string(po_path)
	_expect(po_text.begins_with(original.rstrip("\n")) and po_text.contains("msgid \"ROOM_KITCHEN_SINK_LOCKED\"\nmsgstr \"Not until every piece is down.\""), "...after the rows that were there, with the words the layout gave")
	var reader := preload("res://tests/support/po_file_reader.gd")
	var parsed: Dictionary = reader.parse(po_text)
	var kitchen_rows_have_comments := true
	for entry: Dictionary in parsed["entries"]:
		if String(entry["key"]).begins_with("ROOM_KITCHEN_SINK") and (entry["comments"] as PackedStringArray).is_empty():
			kitchen_rows_have_comments = false
	_expect((parsed["problems"] as PackedStringArray).is_empty() and kitchen_rows_have_comments, "...each with the translator comment the text lint asks for, and the file still reads without a problem")
	options["force"] = true
	var second := RoomBuilder.build(options)
	_expect(bool(second["ok"]) and (second["added_text_keys"] as Array).is_empty() and FileAccess.get_file_as_string(po_path) == po_text, "a rebuild adds no row twice: the first words stay, whoever edits them")
	_write(po_path, po_text.replace("Not until every piece is down.", "The owner's own line."))
	var third := RoomBuilder.build(options)
	_expect(bool(third["ok"]) and FileAccess.get_file_as_string(po_path).contains("The owner's own line."), "...and a line the owner rewrote is never put back")


# --------------------------------------------------------------------------- the shipped scene
func _the_shipped_scene_is_the_tools_output() -> void:
	var layout_text := FileAccess.get_file_as_string(TB1_LAYOUT)
	var layout: RefCounted = RoomLayout.parse(layout_text, "tb1_toybox_gate", TB1_LAYOUT)
	_expect((layout.problems as PackedStringArray).is_empty(), "the layout of tb1_toybox_gate is valid")
	var shipped_text := FileAccess.get_file_as_string(TB1_SCENE)
	var shipped_uid := RegEx.create_from_string("uid=\"(uid://[^\"]+)\"").search(shipped_text.get_slice("\n", 0))
	_expect(shipped_uid != null and shipped_uid.get_string(1) == RoomSceneWriter.uid_text_for_room("tb1_toybox_gate"), "the shipped scene's uid is the one the tool derives from the room id")
	var manifest: Dictionary = BuiltRoomsManifest.read_manifest()
	var row: Dictionary = (manifest["scenes"] as Dictionary).get(TB1_SCENE, {})
	_expect(row.get("room_id") == "tb1_toybox_gate", "the tracked manifest records the shipped scene as the tool's")
	if row.get("scene_sha256") == FileAccess.get_sha256(TB1_SCENE):
		# Nobody has edited it, so the layout must still say exactly what the scene says: they cannot drift.
		_expect(row.get("layout_sha256") == layout_text.sha256_text(), "the scene is unedited, so the layout it was built from is unedited too")
		var rebuilt := RoomSceneWriter.scene_text(layout, shipped_uid.get_string(1) if shipped_uid != null else "")
		_expect(String(rebuilt["text"]) == shipped_text, "...and building the layout again gives the shipped scene byte for byte")
	else:
		_expect(true, "the shipped scene was edited after the tool built it (the owner's work): the layout no longer describes it, and the tool will not rebuild it")


func _the_painter_lists_tiles_by_kind() -> void:
	var greybox := ContentDb.fetch(&"tilesets", &"greybox") as TileSet
	_expect(greybox != null, "the greybox kit loads")
	var painter := CellKindPainter.new(greybox)
	for kind: StringName in CellKinds.RULES_BY_KIND:
		_expect(painter.has_tile_for(kind), "the greybox kit has a tile for the cell kind '%s'" % kind)
	_expect(painter.atlas_coords_of_kind(CellKinds.FLOOR) == [Vector2i(0, 0), Vector2i(1, 0)] and painter.atlas_coords_of_kind(CellKinds.WALL) == [Vector2i(2, 0)], "atlas_coords_of_kind lists the base tiles of a kind in the order the kit has them")
	_expect(painter.atlas_coords_of_kind(&"nonsense").is_empty(), "...and nothing for a kind that is not one")
	var kingdom := ContentDb.fetch(&"tilesets", &"kingdom") as TileSet
	_expect(not CellKindPainter.new(kingdom).has_tile_for(CellKinds.GAP), "the Stage 1 kit has no gap tile (a layout that needs one says so)")


# --------------------------------------------------------------------------- helpers
func _build(layout_text: String, expected_id: String, scene_path: String, force := false, manifest_path := "") -> Dictionary:
	var options := {"layout_text": layout_text, "expected_id": expected_id, "scene_path": scene_path, "force": force, "text_rows_path": ""}
	options["manifest_path"] = manifest_path if not manifest_path.is_empty() else SCRATCH_ROOT.path_join("manifest.json")
	return RoomBuilder.build(options)


func _says(answer: Dictionary, fragment: String) -> bool:
	for problem: String in answer["problems"]:
		if problem.contains(fragment):
			return true
	return false


## The facts of a booted room that a hand-made scene and a built one must share (the rebuilt grid IS the hand-made grid).
func _snapshot_of(scene: PackedScene) -> Dictionary:
	var room := scene.instantiate()
	var world := EcsWorld.new()
	var cast := EcsBoot.boot(world, EcsBootOptions.for_scene(null, room))
	var grid := world.grid
	var walls: Array = grid.blocked_cells.keys()
	walls.sort()
	var enemies: Dictionary = {}
	var entries: Dictionary = {}
	for child in room.get_children():
		var view := child as ActorView
		if view != null and view.definition != null:
			enemies[grid.world_to_cell(view.position)] = view.definition.resource_path
		elif child is ZoneEntryMarker:
			entries[(child as ZoneEntryMarker).entry_id] = grid.world_to_cell((child as Node2D).position)
	var pickups: Array = []
	for item_cell in grid.get_item_cells():
		pickups.append(item_cell)
	var pickup_names: Array = (cast["pickup_name_by_entity"] as Dictionary).values()
	pickup_names.sort()
	var room_encounter := room as RoomEncounter
	var snapshot := {
		"bounds": grid.bounds, "origin": grid.grid_origin, "cell_size": grid.cell_size,
		"cell_kinds": grid.cell_kind_by_cell.duplicate(), "walls": walls,
		"exits": grid.exit_by_cell.duplicate(true), "unlocks": grid.player_unlock_by_cell.duplicate(true), "gates": grid.gate_by_cell.duplicate(true),
		"enemies": enemies, "entries": entries, "pickups": pickups, "pickup_names": pickup_names,
		"persistent_pickups": (cast["persistent_pickup_by_entity"] as Dictionary).size(),
		"zone_id": room_encounter.zone_id, "start_line": room_encounter.room_message, "board_size": room_encounter.board_size,
		"act": room_encounter.act, "district": room_encounter.district, "archetype": room_encounter.layout_archetype,
		"recipe": room_encounter.recipe, "status": room_encounter.content_status, "time_of_night": room_encounter.time_of_night,
		"checkpoint": room_encounter.checkpoint_on_entry,
	}
	room.free()
	world.free()
	return snapshot


func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)
		file.close()


func _remove_tree(directory: String) -> void:
	if not DirAccess.dir_exists_absolute(directory):
		return
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	for sub_directory in DirAccess.get_directories_at(directory):
		_remove_tree(directory.path_join(sub_directory))
	DirAccess.remove_absolute(directory)
