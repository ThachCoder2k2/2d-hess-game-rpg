class_name WorldCheck
extends RefCounted

## Holds the world graph (content/world/world.tres) and the room scenes together (docs/game-base-plan.md 7.1, 15 M5):
## the checks only a reader of both can make. WorldGraph.validate() checks the file as data; this class checks that
## every door of every room is declared and resolves, that every room can be arrived in and reached, that every
## locked door says why, and that the map keeps to its districts. One implementation, three readers:
## ContentDb.validate_cross_refs() reports it, tests/content/test_world_graph.gd asserts it check by check
## (and breaks a graph on purpose to prove each check can fail), and tools/print_world_map.gd prints it.
##
## It is pure over what it is given: a graph, a RoomScan per room, the room folders and two small lookups. It loads
## nothing and prints nothing, so a test can hand it a graph it has just broken.

## Names of the checks; the keys of run()'s answer, in the order they are reported.
const CHECK_GRAPH := &"graph"
const CHECK_FOLDERS := &"folders"
const CHECK_SCENES := &"scenes"
const CHECK_ENTRIES := &"entries"
const CHECK_EXITS_RESOLVE := &"exits_resolve"
const CHECK_EDGES_MATCH_DOORS := &"edges_match_doors"
const CHECK_RETURN_DOORS := &"return_doors"
const CHECK_NO_ORPHAN_ROOMS := &"no_orphan_rooms"
const CHECK_LOCKS := &"locks"
const CHECK_PROGRESSION := &"progression"
const CHECK_MAP := &"map"
const CHECK_ROOM_META := &"room_meta"
const CHECKS: Array[StringName] = [
	CHECK_GRAPH, CHECK_FOLDERS, CHECK_SCENES, CHECK_ENTRIES, CHECK_EXITS_RESOLVE, CHECK_EDGES_MATCH_DOORS,
	CHECK_RETURN_DOORS, CHECK_NO_ORPHAN_ROOMS, CHECK_LOCKS, CHECK_PROGRESSION, CHECK_MAP, CHECK_ROOM_META,
]


## Runs every check. Returns check name -> sentences (an empty list = that check passes); every name of CHECKS is a key.
##   scan_by_room     room id -> RoomScan of its scene (a room whose scene is missing or unreadable is left out)
##   folder_ids       the ids of the folders under content/rooms/
##   scene_path_of    Callable(room_id) -> the res:// path a room's scene must live at
##   has_text_key     Callable(key) -> true when the English files have a row for the text key
static func run(graph: WorldGraph, scan_by_room: Dictionary[StringName, RoomScan], folder_ids: Array[StringName], scene_path_of: Callable, has_text_key: Callable) -> Dictionary[StringName, PackedStringArray]:
	var graph_problems := PackedStringArray()
	var folder_problems := PackedStringArray()
	var scene_problems := PackedStringArray()
	var entry_problems := PackedStringArray()
	var exit_problems := PackedStringArray()
	var edge_problems := PackedStringArray()
	var return_problems := PackedStringArray()
	var orphan_problems := PackedStringArray()
	var lock_problems := PackedStringArray()
	var progression_problems := PackedStringArray()
	var map_problems := PackedStringArray()
	var meta_problems := PackedStringArray()

	for sentence in graph.validate():
		graph_problems.append("world/world: %s" % sentence)
	_check_folders(graph, folder_ids, scene_path_of, folder_problems)
	for room_id in graph.room_ids():
		var label := "rooms/%s" % room_id
		if not scan_by_room.has(room_id):
			scene_problems.append("%s: the scene does not load as a scene that can be instanced." % label)
			continue
		var scan: RoomScan = scan_by_room[room_id]
		if not scan.root_is_room_encounter:
			scene_problems.append("%s: the scene root is not a RoomEncounter." % label)
		elif scan.declared_zone_id != room_id:
			scene_problems.append("%s: the root's zone_id is '%s' but the zone is '%s'; they must be equal." % [label, scan.declared_zone_id, room_id])
		_check_entries(label, scan, entry_problems)
		_check_exits_resolve(label, scan, scan_by_room, graph, exit_problems)
		_check_edges_match_doors(room_id, scan, graph, edge_problems)
		_check_locks_match_doors(room_id, scan, graph, lock_problems)
		_check_map(label, room_id, scan, graph, map_problems)
		for sentence in scan.configuration_problems:
			meta_problems.append("%s: %s" % [label, sentence])
		if not scan.start_message_key.is_empty() and not has_text_key.call(scan.start_message_key):
			meta_problems.append("%s: room_message '%s' has no row in the English files." % [label, scan.start_message_key])
	for edge in graph.edges:
		if edge != null and not graph.has_zone(edge.from_room):
			edge_problems.append("world/world: the door %s/%s is in a room the graph does not list." % [edge.from_room, edge.door])
	_check_return_doors(graph, return_problems)
	_check_no_orphan_rooms(graph, orphan_problems)
	for lock in graph.locks:
		if lock != null and not lock.message_key.is_empty() and not has_text_key.call(lock.message_key):
			lock_problems.append("world/world: lock '%s' says '%s', which has no row in the English files." % [lock.lock_id, lock.message_key])

	_check_progression(graph, scan_by_room, progression_problems)

	var problems_by_check: Dictionary[StringName, PackedStringArray] = {}
	problems_by_check[CHECK_GRAPH] = graph_problems
	problems_by_check[CHECK_FOLDERS] = folder_problems
	problems_by_check[CHECK_SCENES] = scene_problems
	problems_by_check[CHECK_ENTRIES] = entry_problems
	problems_by_check[CHECK_EXITS_RESOLVE] = exit_problems
	problems_by_check[CHECK_EDGES_MATCH_DOORS] = edge_problems
	problems_by_check[CHECK_RETURN_DOORS] = return_problems
	problems_by_check[CHECK_NO_ORPHAN_ROOMS] = orphan_problems
	problems_by_check[CHECK_LOCKS] = lock_problems
	problems_by_check[CHECK_PROGRESSION] = progression_problems
	problems_by_check[CHECK_MAP] = map_problems
	problems_by_check[CHECK_ROOM_META] = meta_problems
	return problems_by_check


## Every sentence of a run(), in report order.
static func flatten(problems_by_check: Dictionary[StringName, PackedStringArray]) -> PackedStringArray:
	var all := PackedStringArray()
	for check in CHECKS:
		all.append_array(problems_by_check.get(check, PackedStringArray()))
	return all



static func _check_folders(graph: WorldGraph, folder_ids: Array[StringName], scene_path_of: Callable, problems: PackedStringArray) -> void:
	for room_id in graph.room_ids():
		if room_id not in folder_ids:
			problems.append("world/world: zone '%s' has no folder content/rooms/%s/." % [room_id, room_id])
			continue
		var scene := graph.get_zone_scene(room_id)
		var expected_path: String = scene_path_of.call(room_id)
		if scene != null and scene.resource_path != expected_path:
			problems.append("world/world: zone '%s' points at %s, not at %s." % [room_id, scene.resource_path, expected_path])
	for folder_id in folder_ids:
		if not graph.has_zone(folder_id):
			problems.append("rooms/%s: no zone of content/world/world.tres leads here (add it to the graph)." % folder_id)


static func _check_entries(label: String, scan: RoomScan, problems: PackedStringArray) -> void:
	if scan.entry_ids.is_empty():
		problems.append("%s: the room has no entry marker, so the pawn can never arrive in it." % label)
	var seen: Dictionary[StringName, bool] = {}
	for entry_id in scan.entry_ids:
		if seen.has(entry_id):
			problems.append("%s: the entry '%s' is declared twice." % [label, entry_id])
		seen[entry_id] = true


static func _check_exits_resolve(label: String, scan: RoomScan, scan_by_room: Dictionary[StringName, RoomScan], graph: WorldGraph, problems: PackedStringArray) -> void:
	for door in scan.exits:
		if bool(door.get("ends_run", false)):
			continue
		var door_label := "%s/%s" % [label, door["door"]]
		var target_zone: StringName = door["target_zone"]
		var target_entry: StringName = door["target_entry"]
		if not graph.has_zone(target_zone):
			problems.append("%s: a door leads to zone '%s', which is not in content/world/world.tres." % [door_label, target_zone])
		elif not scan_by_room.has(target_zone):
			problems.append("%s: a door leads to zone '%s', whose scene could not be read." % [door_label, target_zone])
		elif target_entry not in scan_by_room[target_zone].entry_ids:
			problems.append("%s: a door leads to entry '%s' of zone '%s', which has no such entry marker." % [door_label, target_entry, target_zone])


## Doors and edges are two accounts of the same thing and must agree in both directions.
static func _check_edges_match_doors(room_id: StringName, scan: RoomScan, graph: WorldGraph, problems: PackedStringArray) -> void:
	var door_names: Array[StringName] = []
	for door in scan.exits:
		door_names.append(door["door"])
		var door_label := "rooms/%s/%s" % [room_id, door["door"]]
		var edge := graph.find_edge(room_id, door["door"])
		if bool(door.get("ends_run", false)):
			if edge != null:
				problems.append("%s: the door ends the run and leads nowhere, so no edge may declare it." % door_label)
			continue
		if edge == null:
			problems.append("%s: no edge of content/world/world.tres declares this door (add a WorldEdge for it)." % door_label)
		elif edge.to_room != door["target_zone"] or edge.to_entry != door["target_entry"]:
			problems.append("%s: the door leads to %s/%s but its edge says %s/%s." % [door_label, door["target_zone"], door["target_entry"], edge.to_room, edge.to_entry])
	for edge in graph.edges_from(room_id):
		if edge.door not in door_names:
			problems.append("world/world: the edge %s/%s has no door of that name in the room." % [room_id, edge.door])


## A locked edge and its door say the same thing: a `room_clear` lock is a door that waits for the room to be cleared
## and its line is the door's locked_message; a `flag` lock is a door that waits for that flag (`requires_flag`) and
## its line is the door's locked_message too; a door that waits for either is held by a lock of that kind. A skill lock
## (`skill_lock_id`) is data only: the door waits for nothing on its account.
static func _check_locks_match_doors(room_id: StringName, scan: RoomScan, graph: WorldGraph, problems: PackedStringArray) -> void:
	for door in scan.exits:
		if bool(door.get("ends_run", false)):
			continue
		var door_label := "rooms/%s/%s" % [room_id, door["door"]]
		var edge := graph.find_edge(room_id, door["door"])
		var lock := graph.find_lock(edge.lock_id) if edge != null and edge.lock_id != &"" else null
		var required_flag := StringName(door.get("requires_flag", &""))
		if bool(door["requires_room_clear"]):
			if String(door["locked_message"]).strip_edges().is_empty():
				problems.append("%s: the door stays shut until the room is cleared but gives no reason: its locked_message is empty." % door_label)
			if edge != null and (lock == null or lock.kind != WorldLock.KIND_ROOM_CLEAR):
				problems.append("%s: the door waits for the room to be cleared, so its edge needs a room_clear lock." % door_label)
			elif lock != null and lock.message_key != String(door["locked_message"]):
				problems.append("%s: the door says '%s' but its lock says '%s'." % [door_label, door["locked_message"], lock.message_key])
		elif lock != null and lock.kind == WorldLock.KIND_ROOM_CLEAR:
			problems.append("%s: its edge is held by a room_clear lock but the door does not wait for a clear (requires_room_clear is off)." % door_label)
		if required_flag != &"":
			if String(door["locked_message"]).strip_edges().is_empty():
				problems.append("%s: the door waits for the flag %s but gives no reason: its locked_message is empty." % [door_label, required_flag])
			if edge != null and (lock == null or lock.kind != WorldLock.KIND_FLAG):
				problems.append("%s: the door waits for the flag %s, so its edge needs a flag lock." % [door_label, required_flag])
			elif lock != null and lock.subject != required_flag:
				problems.append("%s: the door waits for the flag %s but its lock waits for %s." % [door_label, required_flag, lock.subject])
			elif lock != null and lock.message_key != String(door["locked_message"]):
				problems.append("%s: the door says '%s' but its lock says '%s'." % [door_label, door["locked_message"], lock.message_key])
		elif lock != null and lock.kind == WorldLock.KIND_FLAG:
			problems.append("%s: its edge is held by the flag lock '%s' but the door does not wait for a flag (requires_flag is empty)." % [door_label, lock.lock_id])


## Every way in has a way back, unless the edge says it is a one-way shortcut.
static func _check_return_doors(graph: WorldGraph, problems: PackedStringArray) -> void:
	for edge in graph.edges:
		if edge == null or edge.one_way or not graph.has_zone(edge.to_room):
			continue
		var comes_back := false
		for return_edge in graph.edges_from(edge.to_room):
			if return_edge.to_room == edge.from_room:
				comes_back = true
				break
		if not comes_back:
			problems.append("world/world: the door %s/%s leads to '%s', which has no door back to '%s' (mark the edge one_way if that is meant)." % [edge.from_room, edge.door, edge.to_room, edge.from_room])


## No room is an orphan: every room can be reached from the start room by walking through doors.
static func _check_no_orphan_rooms(graph: WorldGraph, problems: PackedStringArray) -> void:
	var reachable := graph.reachable_room_ids()
	for room_id in graph.room_ids():
		if not reachable.has(room_id):
			problems.append("world/world: room '%s' cannot be reached from the start room '%s' by any door." % [room_id, graph.start_room_id])


## A room's slot lies inside the region of its district.
static func _check_map(label: String, room_id: StringName, scan: RoomScan, graph: WorldGraph, problems: PackedStringArray) -> void:
	var room := graph.find_room(room_id)
	if room == null:
		return
	var region := graph.region_of(scan.district)
	if scan.district == &"":
		problems.append("%s: the room names no district, so its map slot %s belongs to no region." % [label, room.map_slot])
	elif region == null:
		problems.append("%s: its district '%s' has no region in content/world/world.tres." % [label, scan.district])
	elif not region.slots.has_point(room.map_slot):
		problems.append("%s: map slot %s is outside the region of its district '%s' (%s)." % [label, room.map_slot, scan.district, region.slots])


## Walks the whole world the way a player must, and says where the route breaks (the `progression` check). Starting in the
## start room with no flag set, the pawn passes a door when its lock allows it: no lock, a `room_clear` lock in a room
## that holds something to clear, or a `flag` lock whose flag is set. A boss's flag is set when the pawn can CLEAR the
## boss's room: the room holds at least one piece and has a door that waits for the clear (a boss room with no such
## door could be walked out of with the boss standing). A skill lock (`skill_lock_id`) holds nothing: the verbs do not
## exist yet, so the route stays open. The answer:
##   rooms_in_order   every room reached, in the order the walk found it
##   flags_in_order   every flag set on the way, in the order it was set
##   unreachable      the rooms the walk never reached
##   ending_rooms     the reached rooms that hold the door that ends the run
##   dead_clear_doors "room/door" of every door held by a clear in a room with nothing to clear
static func walk_the_route(graph: WorldGraph, scan_by_room: Dictionary[StringName, RoomScan]) -> Dictionary:
	var rooms_in_order: Array[StringName] = []
	var flags_in_order: Array[StringName] = []
	var ending_rooms: Array[StringName] = []
	var dead_clear_doors: Array[String] = []
	var reached: Dictionary[StringName, bool] = {}
	var flag_is_set: Dictionary[StringName, bool] = {}
	if graph.has_zone(graph.start_room_id):
		rooms_in_order.append(graph.start_room_id)
		reached[graph.start_room_id] = true
	var progressed := true
	while progressed:
		progressed = false
		# Rooms entered so far are judged again every round: a flag set later may open a door of an earlier room.
		for room_id in rooms_in_order.duplicate():
			var scan: RoomScan = scan_by_room.get(room_id)
			if scan == null:
				continue
			var can_be_cleared := not scan.enemy_definitions.is_empty()
			var holds_a_clear_door := false
			for door in scan.exits:
				holds_a_clear_door = holds_a_clear_door or bool(door["requires_room_clear"])
			if can_be_cleared and holds_a_clear_door:
				for definition in scan.enemy_definitions:
					if definition != null and definition.defeat_flag != &"" and not flag_is_set.has(definition.defeat_flag):
						flag_is_set[definition.defeat_flag] = true
						flags_in_order.append(definition.defeat_flag)
						progressed = true
			for edge in graph.edges_from(room_id):
				if reached.has(edge.to_room) or not graph.has_zone(edge.to_room):
					continue
				var lock := graph.find_lock(edge.lock_id) if edge.lock_id != &"" else null
				if lock != null and lock.kind == WorldLock.KIND_ROOM_CLEAR and not can_be_cleared:
					continue
				if lock != null and lock.kind == WorldLock.KIND_FLAG and not flag_is_set.has(lock.subject):
					continue
				reached[edge.to_room] = true
				rooms_in_order.append(edge.to_room)
				progressed = true
	var unreachable: Array[StringName] = []
	for room_id in graph.room_ids():
		if not reached.has(room_id):
			unreachable.append(room_id)
	for room_id in rooms_in_order:
		var scan: RoomScan = scan_by_room.get(room_id)
		if scan == null:
			continue
		for door in scan.exits:
			if bool(door.get("ends_run", false)) and room_id not in ending_rooms:
				ending_rooms.append(room_id)
			if bool(door["requires_room_clear"]) and scan.enemy_definitions.is_empty():
				dead_clear_doors.append("%s/%s" % [room_id, door["door"]])
	return {
		"rooms_in_order": rooms_in_order, "flags_in_order": flags_in_order, "unreachable": unreachable,
		"ending_rooms": ending_rooms, "dead_clear_doors": dead_clear_doors,
	}


## The route is walkable from the first room to the end: see walk_the_route().
static func _check_progression(graph: WorldGraph, scan_by_room: Dictionary[StringName, RoomScan], problems: PackedStringArray) -> void:
	if not graph.has_zone(graph.start_room_id):
		return
	var every_flag_that_is_set: Dictionary[StringName, bool] = {}
	for scan: RoomScan in scan_by_room.values():
		for definition in scan.enemy_definitions:
			if definition != null and definition.defeat_flag != &"":
				every_flag_that_is_set[definition.defeat_flag] = true
	for lock in graph.locks:
		if lock != null and lock.kind == WorldLock.KIND_FLAG and not every_flag_that_is_set.has(lock.subject):
			problems.append("world/world: the lock '%s' waits for the flag %s, which no piece of any room sets when it falls (a boss's definition names its flag)." % [lock.lock_id, lock.subject])
	var walk := walk_the_route(graph, scan_by_room)
	for door_name: String in walk["dead_clear_doors"]:
		problems.append("world/world: the door %s waits for its room to be cleared, but the room holds nothing to clear: nobody can ever pass it." % door_name)
	for room_id: StringName in walk["unreachable"]:
		# A room that is an orphan by plain doors is already reported by no_orphan_rooms; this one is cut off by a lock.
		if graph.reachable_room_ids().has(room_id):
			problems.append("world/world: room '%s' cannot be reached when the doors open in the order the bosses fall: the locks on the way never open (flags set on the way: %s)." % [room_id, ", ".join(PackedStringArray(walk["flags_in_order"]))])
	if (walk["ending_rooms"] as Array).is_empty() and not scan_by_room.is_empty():
		var any_ending_door := false
		for scan: RoomScan in scan_by_room.values():
			for door in scan.exits:
				any_ending_door = any_ending_door or bool(door.get("ends_run", false))
		if any_ending_door:
			problems.append("world/world: the door that ends the run is in a room the pawn can never reach.")
		else:
			problems.append("world/world: no door of any room ends the run (a ZoneExitMarker with ends_run), so the game can never reach its ending.")
