extends RefCounted

## Draws the world graph as text (a helper, not a command; no class_name, preload it): the logic behind
## tools/print_world_map.gd and tests/tools/test_print_world_map.gd. Four sections:
##
##   MAP     the slot grid (8 columns x 10 rows). A room is its short code in brackets; an empty slot shows the first
##           letter of the district whose region it lies in; between neighbours a connector says how they join:
##           `-` `|` a door both ways, `>` `v` `<` `^` a way one way only, `x` a way that has a lock.
##   ROOMS   every room: slot, district, act, recipe, archetype, status, size, doors out, entries in
##   EDGES   every door: room/door -> room/entry, one-way, lock, and the skill lock that will also hold it (M7c)
##   LOCKS   every lock: id, kind, subject, the key and the English words, the doors it holds
##   ROUTE   the whole world walked in the order the doors open, with the flag each boss sets and where the run ends
##
## and a last line of what WorldCheck finds wrong, so the map doubles as a QA report.

const CELL_WIDTH := 7
const DISTRICT_LETTER := {
	&"chess_rug": "c", &"toybox": "t", &"bookshelf": "b", &"block_tower": "k",
	&"dollhouse": "d", &"under_bed": "u", &"desk": "e", &"window": "w",
}


## The whole report for `graph`. `scan_by_room` is room id -> RoomScan (the meta of each room); a room without a scan
## still appears, with blanks.
static func map_text(graph: WorldGraph, scan_by_room: Dictionary[StringName, RoomScan]) -> String:
	var lines := PackedStringArray()
	lines.append("THE WORLD  %d rooms, %d doors, %d locks; the map is %d x %d slots; the game starts in %s" % [graph.rooms.size(), graph.edges.size(), graph.locks.size(), WorldGraph.MAP_COLUMNS, WorldGraph.MAP_ROWS, graph.start_room_id])
	lines.append("")
	lines.append("MAP  [code] a room; a letter marks an empty slot of a district (c chess rug, t toybox, b bookshelf, k block tower, d dollhouse, u under bed, e desk, w window); - | two ways, > v < ^ one way, x locked")
	lines.append_array(_map_lines(graph))
	lines.append("")
	lines.append("ROOMS  (code = the first word of the id)")
	lines.append_array(_room_lines(graph, scan_by_room))
	lines.append("")
	lines.append("EDGES  (room/door -> room/entry)")
	lines.append_array(_edge_lines(graph))
	lines.append("")
	lines.append("LOCKS")
	lines.append_array(_lock_lines(graph))
	lines.append("")
	lines.append("ROUTE  (every room in the order the doors open; a boss's flag is set when its room is cleared)")
	lines.append_array(_route_lines(graph, scan_by_room))
	lines.append("")
	lines.append_array(_check_lines(graph, scan_by_room))
	return "\n".join(lines) + "\n"


## room id -> RoomScan for every room of the graph whose scene reads.
static func scans_of(graph: WorldGraph) -> Dictionary[StringName, RoomScan]:
	var scan_by_room: Dictionary[StringName, RoomScan] = {}
	for room_id in graph.room_ids():
		var scan := RoomScan.of(graph.get_zone_scene(room_id))
		if scan != null:
			scan_by_room[room_id] = scan
	return scan_by_room


## The short code of a room: the first word of its id (t1, h1, tb1).
static func short_code(room_id: StringName) -> String:
	return String(room_id).get_slice("_", 0)


# --------------------------------------------------------------------------- the map
static func _map_lines(graph: WorldGraph) -> PackedStringArray:
	var lines := PackedStringArray()
	var header := "     "
	for column in range(WorldGraph.MAP_COLUMNS):
		header += _padded(str(column), CELL_WIDTH + 1)
	lines.append(header.rstrip(" "))
	for row in range(WorldGraph.MAP_ROWS):
		var cells_line := _padded(str(row), 4) + " "
		for column in range(WorldGraph.MAP_COLUMNS):
			var slot := Vector2i(column, row)
			cells_line += _slot_text(graph, slot)
			if column < WorldGraph.MAP_COLUMNS - 1:
				cells_line += _connector(graph, slot, slot + Vector2i.RIGHT, "-", ">", "<")
		lines.append(cells_line.rstrip(" "))
		if row < WorldGraph.MAP_ROWS - 1:
			var between_line := "     "
			for column in range(WorldGraph.MAP_COLUMNS):
				var vertical := _connector(graph, Vector2i(column, row), Vector2i(column, row + 1), "|", "v", "^")
				between_line += _padded(" " + vertical if vertical != " " else "", CELL_WIDTH + 1).substr(0, CELL_WIDTH + 1)
			lines.append(between_line.rstrip(" "))
	return lines


## One slot: `[t1]` for a room, `  c  ` / `.` for an empty one, padded to the cell width.
static func _slot_text(graph: WorldGraph, slot: Vector2i) -> String:
	var room := graph.room_at_slot(slot)
	if room != null:
		return _padded("[%s]" % short_code(room.room_id), CELL_WIDTH)
	for region in graph.regions:
		if region.slots.has_point(slot):
			return _padded(String(DISTRICT_LETTER.get(region.district, "?")), CELL_WIDTH)
	return _padded(".", CELL_WIDTH)


## The connector between two slots: " " when they are not both rooms joined by a door, else the character for how.
static func _connector(graph: WorldGraph, from_slot: Vector2i, to_slot: Vector2i, both_ways: String, forward_only: String, backward_only: String) -> String:
	var from_room := graph.room_at_slot(from_slot)
	var to_room := graph.room_at_slot(to_slot)
	if from_room == null or to_room == null:
		return " "
	var forward := _edges_between(graph, from_room.room_id, to_room.room_id)
	var backward := _edges_between(graph, to_room.room_id, from_room.room_id)
	if forward.is_empty() and backward.is_empty():
		return " "
	for edge in forward + backward:
		if edge.lock_id != &"":
			return "x"
	if not forward.is_empty() and not backward.is_empty():
		return both_ways
	return forward_only if not forward.is_empty() else backward_only


static func _edges_between(graph: WorldGraph, from_room_id: StringName, to_room_id: StringName) -> Array[WorldEdge]:
	var found: Array[WorldEdge] = []
	for edge in graph.edges_from(from_room_id):
		if edge.to_room == to_room_id:
			found.append(edge)
	return found


static func _padded(text: String, width: int) -> String:
	return text + " ".repeat(maxi(width - text.length(), 0))


# --------------------------------------------------------------------------- the tables
static func _room_lines(graph: WorldGraph, scan_by_room: Dictionary[StringName, RoomScan]) -> PackedStringArray:
	var lines := PackedStringArray()
	lines.append("  %s %s %s %s %s %s %s %s %s" % [_padded("room", 26), _padded("slot", 6), _padded("district", 12), _padded("act", 4), _padded("recipe", 9), _padded("archetype", 11), _padded("status", 9), _padded("size", 6), "doors out / in"])
	for room in graph.rooms:
		var scan: RoomScan = scan_by_room.get(room.room_id)
		var doors_in := 0
		for edge in graph.edges:
			if edge.to_room == room.room_id:
				doors_in += 1
		var district_text := String(scan.district) if scan != null else "?"
		var act_text := str(scan.act) if scan != null else "?"
		var recipe_text := scan.recipe_name if scan != null else "?"
		var archetype_text := String(scan.layout_archetype) if scan != null else "?"
		var status_text := scan.status_name if scan != null else "?"
		var size_text := "%dx%d" % [scan.board_size.x, scan.board_size.y] if scan != null else "?"
		lines.append("  %s %s %s %s %s %s %s %s %d / %d" % [_padded(String(room.room_id), 26), _padded("%d,%d" % [room.map_slot.x, room.map_slot.y], 6), _padded(district_text, 12), _padded(act_text, 4), _padded(recipe_text, 9), _padded(archetype_text, 11), _padded(status_text, 9), _padded(size_text, 6), graph.edges_from(room.room_id).size(), doors_in])
	return lines


static func _edge_lines(graph: WorldGraph) -> PackedStringArray:
	var lines := PackedStringArray()
	for edge in graph.edges:
		var notes := PackedStringArray()
		if edge.one_way:
			notes.append("ONE WAY")
		if edge.lock_id != &"":
			var lock := graph.find_lock(edge.lock_id)
			notes.append("LOCK %s (%s)" % [edge.lock_id, lock.kind if lock != null else "missing"])
		if edge.skill_lock_id != &"":
			var skill_lock := graph.find_lock(edge.skill_lock_id)
			notes.append("SKILL %s (arrives in %s)" % [edge.skill_lock_id, skill_lock.arrives_in if skill_lock != null else "?"])
		lines.append("  %s -> %s%s" % [_padded("%s/%s" % [edge.from_room, edge.door], 48), "%s/%s" % [edge.to_room, edge.to_entry], ("   " + ", ".join(notes)) if not notes.is_empty() else ""])
	if lines.is_empty():
		lines.append("  (no doors)")
	return lines


static func _lock_lines(graph: WorldGraph) -> PackedStringArray:
	var lines := PackedStringArray()
	for lock in graph.locks:
		var subject_text := ""
		match lock.kind:
			WorldLock.KIND_ROOM_CLEAR:
				subject_text = "the room it is in is cleared"
			WorldLock.KIND_COUNTER_AT_LEAST:
				subject_text = "%s reaches %d" % [lock.subject, lock.at_least]
			_:
				subject_text = String(lock.subject)
		lines.append("  %s  %s: %s" % [_padded(String(lock.lock_id), 14), lock.kind, subject_text])
		lines.append("      says %s  \"%s\"" % [lock.message_key, TextService.t(lock.message_key)])
		var doors := PackedStringArray()
		for edge in graph.edges:
			if edge.lock_id == lock.lock_id or edge.skill_lock_id == lock.lock_id:
				doors.append("%s/%s" % [edge.from_room, edge.door])
		var holding_note := "" if lock.is_enforced() else "   (not held until %s: the doors are open today)" % lock.arrives_in
		lines.append("      holds %s%s" % [", ".join(doors) if not doors.is_empty() else "nothing", holding_note])
	if lines.is_empty():
		lines.append("  (no locks)")
	return lines


static func _route_lines(graph: WorldGraph, scan_by_room: Dictionary[StringName, RoomScan]) -> PackedStringArray:
	var lines := PackedStringArray()
	var walk := WorldCheck.walk_the_route(graph, scan_by_room)
	var number := 0
	for room_id: StringName in walk["rooms_in_order"]:
		number += 1
		var scan: RoomScan = scan_by_room.get(room_id)
		var notes := PackedStringArray()
		if scan != null:
			for definition in scan.enemy_definitions:
				if definition != null and definition.defeat_flag != &"":
					notes.append("sets %s" % definition.defeat_flag)
			for door in scan.exits:
				if bool(door.get("ends_run", false)):
					notes.append("the run ends here")
		lines.append(("  %2d %s%s" % [number, _padded(String(room_id), 26), ("  " + ", ".join(notes)) if not notes.is_empty() else ""]).rstrip(" "))
	for room_id: StringName in walk["unreachable"]:
		lines.append("  -- %s  NEVER REACHED" % room_id)
	if lines.is_empty():
		lines.append("  (no rooms)")
	return lines


static func _check_lines(graph: WorldGraph, scan_by_room: Dictionary[StringName, RoomScan]) -> PackedStringArray:
	var folder_ids: Array[StringName] = []
	for room_id in graph.room_ids():
		folder_ids.append(room_id)
	var scene_path_of := func(room_id: StringName) -> String: return ContentDb.path_of(&"rooms", room_id)
	var problems := WorldCheck.flatten(WorldCheck.run(graph, scan_by_room, folder_ids, scene_path_of, TextService.has_key))
	var lines := PackedStringArray()
	if problems.is_empty():
		lines.append("CHECKS  every door resolves, every room has an entry and can be reached, every lock says why, and the route can be walked to the ending: clean")
	else:
		lines.append("CHECKS  %d problem(s)" % problems.size())
		for problem in problems:
			lines.append("  - %s" % problem)
	return lines
