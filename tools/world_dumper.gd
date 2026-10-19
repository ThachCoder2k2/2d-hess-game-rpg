extends RefCounted

## Builds the deterministic world dump (docs/game-base-plan.md 13.7): boot one
## room headless, run a fixed number of manual ticks, and describe the result as
## sorted plain text. Same room + same code = byte-identical text, so a diff
## against tests/baselines/dump_<room>.txt is the cross-milestone regression check
## (screenshots are owner-review artefacts, not gates).
##
## Shared by tools/dump_world.gd (the command line) and
## tests/architecture/test_dump_baselines.gd, so both produce the same bytes.
## There is no class_name on purpose: callers preload() this script, which keeps
## it usable on a fresh checkout before the editor import pass has run.
##
## The boot path mirrors shell/game_root.gd (_make_world + boot_zone): the same systems in
## the same order (both ask Schedule.populate), the player view placed on the "start" entry marker,
## then EcsBoot.boot with no taken pickups and no opened gates (a fresh save).
## It deliberately skips the SaveService, the HUD, the board overlay and audio: they
## depend on the player's save file or on real time, and this dump must not.
## The player gives no input, so the ticks show what the room does by itself.
##
## Sections: [grid], [board] (ASCII map), [entities at boot] (every component
## value), [entities after N ticks], [nodes] (sorted node paths) and [textures]
## (sorted sprite and tile-set texture paths). Floats print with 4 decimals.
## Nodes under an ActorView print structure only: animations and ViewSyncSystem
## drive their transforms, which depend on frame timing.
## Words print as their TEXT KEYS (a piece is "enemy:ENEMY_PAWN_RECRUIT_PIECE", a door's line is "ROOM_T3_..._LOCKED"),
## never as the sentence: a baseline checks what the room does, so rewriting a line in a .po file must not change it.

## The player's puppet view, the same scene shell/game_root.tscn instances as PawnHero.
const PLAYER_VIEW_SCENE_PATH := "res://presentation/views/actors/player.tscn"
const BASELINE_DIRECTORY := "res://tests/baselines"
## Short room codes with a recorded baseline: the six Stage-1 rooms (docs/game-base-plan.md 15 M1a item 6).
const BASELINE_ROOM_IDS: Array[String] = ["t1", "t2", "t3", "t4", "b1", "h1"]
const DEFAULT_TICK_COUNT := 120
const TICK_SECONDS := 1.0 / 60.0
const DUMP_FORMAT_VERSION := 1
## Seeds the global RNG so a future system that rolls dice still dumps the same text.
const DUMP_RANDOM_SEED := 20260712
const START_ENTRY_ID: StringName = &"start"
## Where shell/game_root.tscn parks PawnHero when a room has no entry marker.
const DEFAULT_PLAYER_POSITION := Vector2(144, 212)
const FALLBACK_PLAYER_CELL := Vector2i(3, 7)
const NO_ENTRY_CELL := Vector2i(-1, -1)
## The order an entity's components are printed in. The dump used to sort the component keys, but
## StringName sorts by memory address, not by letters: the order followed the order in which the
## engine first met each name, so loading scripts in another order (the schedule in M3a does) moved
## lines in every baseline without anything having changed. This list is exactly the order the
## M1a baselines recorded, now written down; a key it does not list prints after them, by name.
const COMPONENT_DUMP_ORDER: Array[StringName] = [
	EcsComponents.PICKUP_ITEM,
	EcsComponents.WEAPON_SLOT,
	EcsComponents.ENEMY_AI,
	EcsComponents.PLAYER_COMBAT,
	EcsComponents.VIEW_REF,
	EcsComponents.PLAYER_INPUT,
	EcsComponents.PLAYER_TAG,
	EcsComponents.MOVE_STATE,
	EcsComponents.MOVE_INTENT,
	EcsComponents.ATTACK_INTENT,
	EcsComponents.HEALTH,
	EcsComponents.FACING,
	EcsComponents.GRID_POS,
]
const MAX_VALUE_DEPTH := 3
const MAX_COLLECTION_ITEMS := 24
const MAX_BOARD_WIDTH := 96
## cell kind -> the character the [board] map draws for a cell of that kind (CellKinds ids).
const BOARD_SYMBOL_BY_KIND: Dictionary = {
	&"floor": ".",
	&"wall": "#",
	&"gap": "~",
	&"leapable_block": "b",
	&"chalk": "c",
	&"corruption": "x",
}

## Why the last call returned "" (unknown room, missing scene...). Empty after a success.
var last_error := ""

## The "Main" node every dump hangs the room, the player and the ECS world under,
## so node paths read like the real game's (CurrentZone/..., PawnHero/...).
var _dump_root: Node2D


## The baseline file for a short room code, e.g. res://tests/baselines/dump_t1.txt.
func baseline_path(room_id: String) -> String:
	return BASELINE_DIRECTORY.path_join("dump_%s.txt" % room_id)


## Resolves "t1", "t1_white_kings_fall" or a res:// (or, for a scene a test builds, user://) scene path to
## { "zone_id": String, "scene_path": String }. Empty dictionary + last_error when unknown.
func resolve_room(room_id: String) -> Dictionary:
	if room_id.begins_with("res://") or room_id.begins_with("user://"):
		return {"zone_id": room_id.get_file().get_basename(), "scene_path": room_id}
	var world_graph := ContentDb.world()
	if world_graph == null:
		last_error = "cannot load the world graph (%s)" % ContentDb.path_of(&"world", &"world")
		return {}
	var matching_zone_ids: Array[String] = []
	for zone_id: StringName in world_graph.room_ids():
		var zone_text := String(zone_id)
		if zone_text == room_id or zone_text.begins_with(room_id + "_"):
			matching_zone_ids.append(zone_text)
	matching_zone_ids.sort()
	if matching_zone_ids.size() != 1:
		last_error = "room '%s' matches %d zones in the world graph (%s)" % [room_id, matching_zone_ids.size(), ", ".join(matching_zone_ids)]
		return {}
	var zone_scene := world_graph.get_zone_scene(StringName(matching_zone_ids[0]))
	if zone_scene == null:
		last_error = "zone '%s' has no scene" % matching_zone_ids[0]
		return {}
	return {"zone_id": matching_zone_ids[0], "scene_path": zone_scene.resource_path}


## Every zone id in the world graph, sorted (for --list).
func list_zone_ids() -> Array[String]:
	var zone_ids: Array[String] = []
	var world_graph := ContentDb.world()
	if world_graph != null:
		for zone_id: StringName in world_graph.room_ids():
			zone_ids.append(String(zone_id))
	zone_ids.sort()
	return zone_ids


## Boots the room under tree.root, ticks it, returns the dump text and frees everything it created.
## Returns "" (and sets last_error) when the room cannot be resolved or loaded.
func dump_room(tree: SceneTree, room_id: String, tick_count := DEFAULT_TICK_COUNT) -> String:
	last_error = ""
	var resolved := resolve_room(room_id)
	if resolved.is_empty():
		return ""
	var room_scene := load(String(resolved["scene_path"])) as PackedScene
	var player_scene := load(PLAYER_VIEW_SCENE_PATH) as PackedScene
	if room_scene == null or player_scene == null:
		last_error = "cannot load %s or %s" % [resolved["scene_path"], PLAYER_VIEW_SCENE_PATH]
		return ""

	seed(DUMP_RANDOM_SEED)
	_dump_root = Node2D.new()
	_dump_root.name = "Main"
	tree.root.add_child(_dump_root)
	var player_view := player_scene.instantiate() as ActorView
	player_view.name = "PawnHero"
	player_view.position = DEFAULT_PLAYER_POSITION
	_dump_root.add_child(player_view)
	var room := room_scene.instantiate()
	room.name = "CurrentZone"
	_dump_root.add_child(room)

	var world := EcsWorld.new()
	world.name = "EcsWorld"
	world.manual_tick = true
	_dump_root.add_child(world)
	Schedule.populate(world)

	# The room's own grid origin first, as shell/game_root.gd does: the entry marker's position is turned
	# into a cell with it, and a board that is not 16x9 has another origin than the grid's default.
	EcsBoot.shape_grid(world, room)
	var entry_cell := _find_entry_cell(world, room)
	if entry_cell != NO_ENTRY_CELL:
		player_view.position = world.grid.cell_to_world(entry_cell)
	var boot_options := EcsBootOptions.for_scene(player_view, room)
	boot_options.fallback_player_cell = FALLBACK_PLAYER_CELL
	var cast := EcsBoot.boot(world, boot_options)

	var lines := PackedStringArray()
	lines.append("# dump_world v%d: deterministic world dump. Regenerate with tools/dump_world.gd (see tools/README.md)." % DUMP_FORMAT_VERSION)
	lines.append("room: %s" % resolved["zone_id"])
	lines.append("scene: %s" % resolved["scene_path"])
	lines.append("ticks: %d x %s s, player idle (no input)" % [tick_count, _format_float(TICK_SECONDS)])
	lines.append("entry_cell: %s" % _format_value(entry_cell, 0))
	lines.append("cast: player=%d enemies=%s pickups=%d" % [int(cast.get("player", 0)), _format_value(cast.get("enemies", []), 0), cast.get("pickup_name_by_entity", {}).size()])
	lines.append("")
	_append_grid_section(lines, world)
	lines.append("")
	_append_board_section(lines, world)
	lines.append("")
	lines.append("[entities at boot]")
	_append_entity_details(lines, world)
	for _tick in range(tick_count):
		world.tick(TICK_SECONDS)
	var drained_events := world.drain_events()
	lines.append("")
	lines.append("[entities after %d ticks]" % tick_count)
	_append_entity_summaries(lines, world)
	lines.append("events drained: %d" % drained_events.size())
	lines.append("")
	_append_node_sections(lines)

	var text := "\n".join(lines) + "\n"
	_dump_root.get_parent().remove_child(_dump_root)
	_dump_root.free()
	_dump_root = null
	return text


## The "[entities at boot]" lines for a world that some other tool booted (tools/actor_dumper.gd
## describes one actor at a time): every entity, every component, every script variable, printed
## exactly as the room dumps print them. `dump_root` is the node that node paths are written
## relative to, so a `view_ref` reads `node(Actor)` and not an engine path.
func describe_world_entities(world: EcsWorld, dump_root: Node) -> PackedStringArray:
	_dump_root = dump_root
	var lines := PackedStringArray()
	_append_entity_details(lines, world)
	_dump_root = null
	return lines


## The cell of the entry marker named "start", else the first marker, like game_root.gd._find_entry_cell.
func _find_entry_cell(world: EcsWorld, room: Node) -> Vector2i:
	var fallback := NO_ENTRY_CELL
	for child in room.get_children():
		var entry := child as ZoneEntryMarker
		if entry == null:
			continue
		var cell := world.grid.world_to_cell(entry.position)
		if entry.entry_id == START_ENTRY_ID:
			return cell
		if fallback == NO_ENTRY_CELL:
			fallback = cell
	return fallback


# --------------------------------------------------------------------------- grid + board
func _append_grid_section(lines: PackedStringArray, world: EcsWorld) -> void:
	var grid := world.grid
	lines.append("[grid]")
	lines.append("bounds: position=%s size=%s" % [_format_value(grid.bounds.position, 0), _format_value(grid.bounds.size, 0)])
	lines.append("cell_size: %d" % grid.cell_size)
	lines.append("grid_origin: %s" % _format_position(grid.grid_origin))
	var blocked_cells := _sorted_cells(grid.blocked_cells.keys())
	lines.append("blocked_cells: %d" % blocked_cells.size())
	var blocked_cell_texts := PackedStringArray()
	for cell in blocked_cells:
		blocked_cell_texts.append(_format_cell(cell))
	lines.append("  " + " ".join(blocked_cell_texts))
	var kinds_beyond_walls := _kinds_beyond_walls(grid)
	if not kinds_beyond_walls.is_empty():
		lines.append("cell_kinds: " + _format_cell_kind_counts(grid))
	lines.append("exits: %d" % grid.exit_by_cell.size())
	for cell in _sorted_cells(grid.exit_by_cell.keys()):
		lines.append("  %s %s" % [_format_cell(cell), _format_value(grid.exit_by_cell[cell], 1)])
	lines.append("gates: %d" % grid.gate_by_cell.size())
	for cell in _sorted_cells(grid.gate_by_cell.keys()):
		lines.append("  %s %s" % [_format_cell(cell), _format_value(grid.gate_by_cell[cell], 1)])
	lines.append("player_unlocks: %d" % grid.player_unlock_by_cell.size())
	for cell in _sorted_cells(grid.player_unlock_by_cell.keys()):
		lines.append("  %s %s" % [_format_cell(cell), _format_value(grid.player_unlock_by_cell[cell], 1)])
	lines.append("items: %d" % grid.item_by_cell.size())
	for cell in _sorted_cells(grid.item_by_cell.keys()):
		lines.append("  %s entity=%d" % [_format_cell(cell), int(grid.item_by_cell[cell])])


## The cell kinds the grid holds besides plain floor and plain walls, in CellKinds order. Empty on every board
## that exists today: a wall is the blocked_cells line above and floor is the rest, so the dump prints
## nothing more until a room has a gap, a leapable block, chalk or corruption (docs/game-base-plan.md 5.11).
func _kinds_beyond_walls(grid: EcsGrid) -> Array[StringName]:
	var kinds: Array[StringName] = []
	for kind: StringName in CellKinds.RULES_BY_KIND:
		if kind != CellKinds.FLOOR and kind != CellKinds.WALL and grid.cell_kind_by_cell.values().has(kind):
			kinds.append(kind)
	return kinds


## How many cells of each kind that is not plain floor the grid holds, in CellKinds order ("wall=50 gap=2").
func _format_cell_kind_counts(grid: EcsGrid) -> String:
	var texts := PackedStringArray()
	for kind: StringName in CellKinds.RULES_BY_KIND:
		var count := grid.cell_kind_by_cell.values().count(kind)
		if kind != CellKinds.FLOOR and count > 0:
			texts.append("%s=%d" % [kind, count])
	return " ".join(texts)


## An ASCII map of the booted board. P player, e enemy, i item, X exit, G gate, U unlock, # wall, . floor, and,
## when the board has them, ~ gap, b leapable block, c chalk, x corruption (named in the legend only when
## the board holds one, so a board of walls and floor reads as it always did).
func _append_board_section(lines: PackedStringArray, world: EcsWorld) -> void:
	var grid := world.grid
	var legend := "[board] P player, e enemy, i item, X exit, G gate, U unlock, # wall, . floor"
	for kind in _kinds_beyond_walls(grid):
		legend += ", %s %s" % [BOARD_SYMBOL_BY_KIND[kind], String(kind).replace("_", " ")]
	lines.append(legend)
	if grid.bounds.size.x > MAX_BOARD_WIDTH:
		lines.append("(board wider than %d cells, map omitted)" % MAX_BOARD_WIDTH)
		return
	for row in range(grid.bounds.position.y, grid.bounds.end.y):
		var row_text := ""
		for column in range(grid.bounds.position.x, grid.bounds.end.x):
			var cell := Vector2i(column, row)
			var occupant := grid.entity_at(cell)
			var symbol: String = BOARD_SYMBOL_BY_KIND.get(grid.kind_at(cell), "?")
			if grid.gate_by_cell.has(cell):
				symbol = "G"
			if grid.exit_by_cell.has(cell):
				symbol = "X"
			if grid.player_unlock_by_cell.has(cell):
				symbol = "U"
			if grid.item_at(cell) != 0:
				symbol = "i"
			if occupant != 0:
				symbol = "P" if world.has_component(occupant, EcsComponents.PLAYER_TAG) else "e"
			row_text += symbol
		lines.append(row_text)


# --------------------------------------------------------------------------- entities
func _all_entity_ids(world: EcsWorld) -> Array[int]:
	var seen: Dictionary = {}
	for store: Dictionary in world.store_by_component.values():
		for entity_id: int in store:
			seen[entity_id] = true
	var entity_ids: Array[int] = []
	for entity_id: int in seen:
		entity_ids.append(entity_id)
	entity_ids.sort()
	return entity_ids


func _entity_label(world: EcsWorld, entity_id: int) -> String:
	if world.has_component(entity_id, EcsComponents.PLAYER_TAG):
		return "player"
	var ai: EcsComponents.EnemyAI = world.get_component(entity_id, EcsComponents.ENEMY_AI)
	if ai != null:
		return "enemy:%s" % (ai.definition.piece_name if ai.definition != null else "no_definition")
	var pickup: EcsComponents.PickupItem = world.get_component(entity_id, EcsComponents.PICKUP_ITEM)
	if pickup != null:
		return "pickup:%s" % (pickup.weapon.display_name if pickup.weapon != null else "no_weapon")
	return "entity"


## Every component of every entity, with every script variable, in COMPONENT_DUMP_ORDER.
func _append_entity_details(lines: PackedStringArray, world: EcsWorld) -> void:
	var component_keys := _ordered_component_keys(world)
	for entity_id in _all_entity_ids(world):
		var grid_pos: EcsComponents.GridPos = world.get_component(entity_id, EcsComponents.GRID_POS)
		lines.append("entity %d %s cell=%s" % [entity_id, _entity_label(world, entity_id), _format_cell(grid_pos.cell) if grid_pos != null else "none"])
		for component_key: StringName in component_keys:
			var component: Object = world.get_component(entity_id, component_key)
			if component != null:
				lines.append("  %s: %s" % [component_key, _format_properties(component, 1)])


## The component keys the world holds, listed ones first in COMPONENT_DUMP_ORDER and the rest by name.
func _ordered_component_keys(world: EcsWorld) -> Array[StringName]:
	var listed_keys: Array[StringName] = []
	var unlisted_names: Array[String] = []
	for component_key: StringName in world.store_by_component.keys():
		if component_key in COMPONENT_DUMP_ORDER:
			listed_keys.append(component_key)
		else:
			unlisted_names.append(String(component_key))
	listed_keys.sort_custom(func(first: StringName, second: StringName) -> bool: return COMPONENT_DUMP_ORDER.find(first) < COMPONENT_DUMP_ORDER.find(second))
	unlisted_names.sort()
	for unlisted_name in unlisted_names:
		listed_keys.append(StringName(unlisted_name))
	return listed_keys


## One compact line per entity: where it is and what state it is in.
func _append_entity_summaries(lines: PackedStringArray, world: EcsWorld) -> void:
	for entity_id in _all_entity_ids(world):
		var parts := PackedStringArray()
		var grid_pos: EcsComponents.GridPos = world.get_component(entity_id, EcsComponents.GRID_POS)
		parts.append("cell=%s" % (_format_cell(grid_pos.cell) if grid_pos != null else "none"))
		var facing: EcsComponents.Facing = world.get_component(entity_id, EcsComponents.FACING)
		if facing != null:
			parts.append("facing=%s" % _format_cell(facing.direction))
		var move: EcsComponents.MoveState = world.get_component(entity_id, EcsComponents.MOVE_STATE)
		if move != null:
			parts.append("moving=%s" % str(move.moving).to_lower())
		var health: EcsComponents.Health = world.get_component(entity_id, EcsComponents.HEALTH)
		if health != null:
			parts.append("health=%d/%d" % [health.current, health.max_value])
		var ai: EcsComponents.EnemyAI = world.get_component(entity_id, EcsComponents.ENEMY_AI)
		if ai != null:
			parts.append("ai_state=%d" % ai.state)
		lines.append("entity %d %s %s" % [entity_id, _entity_label(world, entity_id), " ".join(parts)])


# --------------------------------------------------------------------------- nodes + textures
func _append_node_sections(lines: PackedStringArray) -> void:
	var node_lines: Array[String] = []
	var texture_lines: Array[String] = []
	for child in _dump_root.get_children():
		if child is EcsWorld:
			continue
		_collect_node(child, _stable_name(String(child.name)), false, node_lines, texture_lines)
	node_lines.sort()
	texture_lines.sort()
	lines.append("[nodes] %d" % node_lines.size())
	lines.append_array(PackedStringArray(node_lines))
	lines.append("")
	lines.append("[textures] %d" % texture_lines.size())
	lines.append_array(PackedStringArray(texture_lines))


func _collect_node(node: Node, node_path: String, inside_actor_view: bool, node_lines: Array[String], texture_lines: Array[String]) -> void:
	var parts: Array[String] = [node_path, node.get_class()]
	var script := node.get_script() as Script
	if script != null:
		parts.append("script=%s" % script.resource_path)
	var is_actor_view := node is ActorView
	if not inside_actor_view:
		# Static room geometry is deterministic. Under an ActorView the transforms are animation-driven.
		var canvas_item := node as CanvasItem
		# ViewSyncSystem blinks an invulnerable actor with Time.get_ticks_msec(), so an ActorView's own visibility is never dumped.
		if canvas_item != null and not canvas_item.visible and not is_actor_view:
			parts.append("visible=false")
		var node_2d := node as Node2D
		if node_2d != null:
			parts.append("position=%s" % _format_position(node_2d.position))
			if not is_zero_approx(node_2d.rotation):
				parts.append("rotation=%s" % _format_float(node_2d.rotation))
			if not node_2d.scale.is_equal_approx(Vector2.ONE):
				parts.append("scale=%s" % _format_position(node_2d.scale))
			if node_2d.z_index != 0:
				parts.append("z_index=%d" % node_2d.z_index)
	var tile_map_layer := node as TileMapLayer
	if tile_map_layer != null:
		parts.append("used_cells=%d" % tile_map_layer.get_used_cells().size())
		parts.append("tile_set=%s" % (tile_map_layer.tile_set.resource_path if tile_map_layer.tile_set != null else "null"))
		_collect_tile_set_textures(tile_map_layer, node_path, texture_lines)
	node_lines.append(" ".join(parts))
	if "texture" in node:
		var texture: Variant = node.get("texture")
		# A null texture is only worth a line where a texture is the point (a Sprite2D with no art is missing art).
		var is_art_node := node is Sprite2D or node is TextureRect or node is AnimatedSprite2D
		if (texture is Texture2D) or (texture == null and is_art_node):
			texture_lines.append("%s -> %s" % [node_path, _describe_texture(texture as Texture2D)])
	for child in node.get_children():
		_collect_node(child, node_path + "/" + _stable_name(String(child.name)), inside_actor_view or is_actor_view, node_lines, texture_lines)


func _collect_tile_set_textures(tile_map_layer: TileMapLayer, node_path: String, texture_lines: Array[String]) -> void:
	var tile_set := tile_map_layer.tile_set
	if tile_set == null:
		return
	for source_index in range(tile_set.get_source_count()):
		var atlas := tile_set.get_source(tile_set.get_source_id(source_index)) as TileSetAtlasSource
		if atlas != null:
			texture_lines.append("%s#tile_set_source%d -> %s" % [node_path, source_index, _describe_texture(atlas.texture)])


## Engine-generated names like "@Node2D@12" count up across a process; keep the type, drop the counter.
func _stable_name(node_name: String) -> String:
	if not node_name.begins_with("@"):
		return node_name
	var segments := node_name.split("@", false)
	return "@" + (segments[0] if not segments.is_empty() else "node")


func _describe_texture(texture: Texture2D) -> String:
	if texture == null:
		return "null"
	var atlas_texture := texture as AtlasTexture
	if atlas_texture != null:
		return "atlas(%s region=%s)" % [_describe_texture(atlas_texture.atlas), _format_value(atlas_texture.region, 0)]
	if texture.resource_path.is_empty():
		return "inline:%s %dx%d" % [texture.get_class(), texture.get_width(), texture.get_height()]
	return texture.resource_path


# --------------------------------------------------------------------------- value formatting
func _sorted_cells(cells: Array) -> Array[Vector2i]:
	var sorted_cells: Array[Vector2i] = []
	for cell: Vector2i in cells:
		sorted_cells.append(cell)
	sorted_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	return sorted_cells


func _format_cell(cell: Vector2i) -> String:
	return "(%d,%d)" % [cell.x, cell.y]


## Scene positions need 2 decimals, not 4: they are authored on a pixel grid.
func _format_position(position: Vector2) -> String:
	var snapped_position := position.snapped(Vector2(0.01, 0.01))
	return "(%.2f,%.2f)" % [snapped_position.x + 0.0, snapped_position.y + 0.0]


## 4 decimals, never "-0.0000", so a harmless sign flip cannot churn a baseline.
func _format_float(number: float) -> String:
	if is_nan(number):
		return "nan"
	if is_inf(number):
		return "inf" if number > 0.0 else "-inf"
	var rounded := snappedf(number, 0.0001)
	if is_zero_approx(rounded):
		rounded = 0.0
	return "%.4f" % rounded


func _format_value(value: Variant, depth: int) -> String:
	match typeof(value):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return str(value).to_lower()
		TYPE_INT:
			return str(value)
		TYPE_FLOAT:
			return _format_float(value)
		TYPE_STRING, TYPE_STRING_NAME:
			return var_to_str(value)
		TYPE_VECTOR2:
			return "(%s, %s)" % [_format_float(value.x), _format_float(value.y)]
		TYPE_VECTOR2I:
			return "(%d, %d)" % [value.x, value.y]
		TYPE_RECT2:
			return "Rect2(%s, %s)" % [_format_value(value.position, depth), _format_value(value.size, depth)]
		TYPE_RECT2I:
			return "Rect2i(%s, %s)" % [_format_value(value.position, depth), _format_value(value.size, depth)]
		TYPE_COLOR:
			return "#" + (value as Color).to_html(true)
		TYPE_ARRAY:
			return _format_array(value, depth)
		TYPE_DICTIONARY:
			return _format_dictionary(value, depth)
		TYPE_OBJECT:
			return _format_object(value, depth)
	if typeof(value) >= TYPE_PACKED_BYTE_ARRAY and typeof(value) <= TYPE_PACKED_VECTOR4_ARRAY:
		return _format_array(Array(value), depth)
	return var_to_str(value)


func _format_array(items: Array, depth: int) -> String:
	if depth > MAX_VALUE_DEPTH:
		return "[%d items]" % items.size()
	var parts := PackedStringArray()
	for index in range(mini(items.size(), MAX_COLLECTION_ITEMS)):
		parts.append(_format_value(items[index], depth + 1))
	if items.size() > MAX_COLLECTION_ITEMS:
		parts.append("...+%d" % (items.size() - MAX_COLLECTION_ITEMS))
	return "[" + ", ".join(parts) + "]"


func _format_dictionary(dictionary: Dictionary, depth: int) -> String:
	if depth > MAX_VALUE_DEPTH:
		return "{%d keys}" % dictionary.size()
	var keys: Array = dictionary.keys()
	keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
	var parts := PackedStringArray()
	for key in keys.slice(0, MAX_COLLECTION_ITEMS):
		parts.append("%s: %s" % [_format_value(key, depth + 1), _format_value(dictionary[key], depth + 1)])
	if keys.size() > MAX_COLLECTION_ITEMS:
		parts.append("...+%d" % (keys.size() - MAX_COLLECTION_ITEMS))
	return "{" + ", ".join(parts) + "}"


func _format_object(object: Object, depth: int) -> String:
	if object == null or not is_instance_valid(object):
		return "null"
	var node := object as Node
	if node != null:
		if _dump_root != null and _dump_root.is_ancestor_of(node):
			return "node(%s)" % _stable_path(_dump_root.get_path_to(node))
		return "node(%s outside the dump)" % node.get_class()
	var resource := object as Resource
	if resource != null and not resource.resource_path.is_empty() and not resource.resource_path.contains("::"):
		return "%s@%s" % [_class_label(object), resource.resource_path]
	if depth > MAX_VALUE_DEPTH:
		return "<%s>" % _class_label(object)
	return "%s{%s}" % [_class_label(object), _format_properties(object, depth + 1)]


## The script's class_name when it has one, else the engine class.
func _class_label(object: Object) -> String:
	var script := object.get_script() as Script
	if script != null and not String(script.get_global_name()).is_empty():
		return String(script.get_global_name())
	return object.get_class()


## "name=value" for every script variable (so every @export and every plain var), sorted by name.
func _format_properties(object: Object, depth: int) -> String:
	var names: Array[String] = []
	for property: Dictionary in object.get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			names.append(String(property["name"]))
	names.sort()
	var parts := PackedStringArray()
	for property_name in names:
		parts.append("%s=%s" % [property_name, _format_value(object.get(property_name), depth)])
	return " ".join(parts)


func _stable_path(path: NodePath) -> String:
	var names := PackedStringArray()
	for index in range(path.get_name_count()):
		names.append(_stable_name(String(path.get_name(index))))
	return "/".join(names)
