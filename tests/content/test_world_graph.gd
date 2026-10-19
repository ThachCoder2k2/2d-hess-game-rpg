extends UnboundTest

## The world graph (content/world/world.tres, docs/game-base-plan.md 7.1, 15 M5 acceptance) holds together with the room
## scenes: every exit resolves to an existing room and entry, every room has an entry, no room is an orphan, every lock
## says why. WorldCheck does the checking (one implementation, also run by ContentDb.validate_cross_refs() and
## tools/print_world_map.gd); this suite asserts each of its checks on the real content, then BREAKS a copy of the world
## in one named way per check and requires the exact complaint, because a check that cannot fail proves nothing.
## It also holds the shape of the data classes (WorldGraph, WorldLock, FlagId) and the move of the 72x40 kingdom out
## of the graph (plan D-02): it is a fixture the tests load by path.

const MINIMUM_ROOMS := 7
const MINIMUM_EDGES := 12
const MINIMUM_LOCKS := 3
const KINGDOM_ZONE_ID := &"kingdom"


func _init() -> void:
	suite_title = "TEST WORLD GRAPH"
	var graph := ContentDb.world()
	if not _expect(graph != null, "the world graph loads"):
		finish()
		return
	var scan_by_room := _scans_of(graph)
	_check_the_real_world(graph, scan_by_room)
	_check_the_graph_as_data(graph)
	_check_every_check_can_fail(graph)
	_check_the_lock_and_flag_classes()
	finish()


# --------------------------------------------------------------------------- the real world
func _check_the_real_world(graph: WorldGraph, scan_by_room: Dictionary[StringName, RoomScan]) -> void:
	_expect(graph.rooms.size() >= MINIMUM_ROOMS and graph.edges.size() >= MINIMUM_EDGES and graph.locks.size() >= MINIMUM_LOCKS,
		"the graph lists %d rooms, %d doors and %d locks (at least %d, %d and %d, so an empty walk cannot pass)" % [graph.rooms.size(), graph.edges.size(), graph.locks.size(), MINIMUM_ROOMS, MINIMUM_EDGES, MINIMUM_LOCKS])
	_expect(scan_by_room.size() == graph.rooms.size(), "every room of the graph has a scene that reads (%d of %d)" % [scan_by_room.size(), graph.rooms.size()])
	var problems_by_check := _run(graph, scan_by_room)
	for check in WorldCheck.CHECKS:
		var sentences: PackedStringArray = problems_by_check[check]
		for sentence in sentences:
			printerr("  %s: %s" % [check, sentence])
		_expect(sentences.is_empty(), "the world passes the check '%s' (%d problem(s))" % [check, sentences.size()])

	# The claims of the milestone, counted in the open so a check that quietly looked at nothing shows.
	var doors_resolved := 0
	var entries_found := 0
	for room_id in scan_by_room:
		var scan := scan_by_room[room_id]
		entries_found += scan.entry_ids.size()
		for door in scan.exits:
			if graph.has_zone(door["target_zone"]) and door["target_entry"] in scan_by_room[door["target_zone"]].entry_ids:
				doors_resolved += 1
	_expect(doors_resolved == graph.edges.size() and doors_resolved >= MINIMUM_EDGES, "every exit resolves to an existing room and entry: %d doors, %d edges" % [doors_resolved, graph.edges.size()])
	var rooms_without_entry := 0
	for scan: RoomScan in scan_by_room.values():
		if scan.entry_ids.is_empty():
			rooms_without_entry += 1
	_expect(rooms_without_entry == 0 and entries_found >= graph.rooms.size(), "every room has an entry marker (%d entries in %d rooms)" % [entries_found, graph.rooms.size()])
	_expect(graph.reachable_room_ids().size() == graph.rooms.size(), "no room is an orphan: all %d rooms can be reached from %s" % [graph.rooms.size(), graph.start_room_id])
	var locks_without_a_message := 0
	for lock in graph.locks:
		if lock.message_key.is_empty() or not TextService.has_key(lock.message_key):
			locks_without_a_message += 1
	_expect(locks_without_a_message == 0, "every lock has a message key with an English row (%d lock(s))" % graph.locks.size())

	_expect(not graph.has_zone(KINGDOM_ZONE_ID) and graph.get_zone_scene(KINGDOM_ZONE_ID) == null, "the 72x40 kingdom is not in the graph (it is a test fixture, plan D-02)")
	var kingdom_in_a_door := false
	for scan: RoomScan in scan_by_room.values():
		for door in scan.exits:
			if door["target_zone"] == KINGDOM_ZONE_ID:
				kingdom_in_a_door = true
	_expect(not kingdom_in_a_door, "and no door of any room leads into it")
	var kingdom_scene := TestPaths.new(self).load_scene(TestPaths.new(self).kingdom_scene())
	_expect(kingdom_scene != null and kingdom_scene.can_instantiate(), "while the fixture itself still loads from tests/fixtures/")


# --------------------------------------------------------------------------- the graph as data
func _check_the_graph_as_data(graph: WorldGraph) -> void:
	_expect(graph.validate().is_empty(), "the shipped graph passes its own validate()")
	_expect(graph.start_room_id == &"t1_white_kings_fall" and graph.has_zone(graph.start_room_id), "the game starts in T1")
	var hub := graph.find_room(&"h1_chess_rug_hub")
	_expect(hub != null and graph.room_at_slot(hub.map_slot) == hub, "a room is found by id and by its map slot")
	_expect(graph.find_edge(&"h1_chess_rug_hub", &"Exit_To_Boss") != null and graph.find_edge(&"h1_chess_rug_hub", &"no_such_door") == null, "an edge is found by its room and door name")
	_expect(graph.edges_from(&"h1_chess_rug_hub").size() == 2, "the hub has two doors out (the boss and the toybox)")
	_expect(graph.find_lock(&"b1_clear") != null and graph.find_lock(&"b1_clear").kind == WorldLock.KIND_ROOM_CLEAR, "a lock is found by id")
	_expect(graph.region_of(&"toybox") != null and graph.region_of(&"nowhere") == null, "a district's region is found by name")
	var all_districts_have_a_region := true
	for district in WorldGraph.DISTRICT_IDS:
		if graph.region_of(district) == null:
			all_districts_have_a_region = false
	_expect(all_districts_have_a_region, "every district of the plan (7.1) has a region of the map")
	var doors_to_room := graph.reachable_room_ids()
	_expect(doors_to_room.get(&"t1_white_kings_fall", -1) == 0 and doors_to_room.get(&"h1_chess_rug_hub", -1) == 5 and doors_to_room.get(&"tb1_toybox_gate", -1) == 6, "the route from T1 to the hub is five doors, and the Toybox is one more")


# --------------------------------------------------------------------------- every check can fail
func _check_every_check_can_fail(graph: WorldGraph) -> void:
	var healthy_scans := _scans_of(graph)
	var healthy_copy := _copy_of(graph)
	_expect(WorldCheck.flatten(_run(healthy_copy, healthy_scans)).is_empty(), "control: a copy of the world passes every check, so the breakages below are the only difference")

	# graph: the file as data.
	var no_start := _copy_of(graph)
	no_start.start_room_id = &"nowhere"
	_expect_complaint(_run(no_start, _scans_of(no_start)), WorldCheck.CHECK_GRAPH, "The start room 'nowhere' is not one of the rooms", "a start room that is not a room is reported")
	var shared_slot := _copy_of(graph)
	shared_slot.find_room(&"tb1_toybox_gate").map_slot = shared_slot.find_room(&"h1_chess_rug_hub").map_slot
	_expect_complaint(_run(shared_slot, _scans_of(shared_slot)), WorldCheck.CHECK_GRAPH, "both sit on map slot", "two rooms on one map slot are reported")
	var off_the_map := _copy_of(graph)
	off_the_map.find_room(&"tb1_toybox_gate").map_slot = Vector2i(8, 0)
	_expect_complaint(_run(off_the_map, _scans_of(off_the_map)), WorldCheck.CHECK_GRAPH, "outside the 8 x 10 map", "a map slot outside the 8 x 10 grid is reported")
	var overlapping := _copy_of(graph)
	overlapping.region_of(&"toybox").slots = Rect2i(5, 3, 3, 5)
	_expect_complaint(_run(overlapping, _scans_of(overlapping)), WorldCheck.CHECK_GRAPH, "overlap", "two overlapping district regions are reported")

	# folders and scenes.
	var no_folder := _copy_of(graph)
	var ghost_room := WorldRoom.new()
	ghost_room.room_id = &"ghost_room"
	ghost_room.scene = graph.get_zone_scene(&"tb1_toybox_gate")
	ghost_room.map_slot = Vector2i(7, 7)
	no_folder.rooms.append(ghost_room)
	_expect_complaint(_run(no_folder, _scans_of(no_folder)), WorldCheck.CHECK_FOLDERS, "zone 'ghost_room' has no folder content/rooms/ghost_room/", "a room without a folder is reported")
	var wrong_zone_id := _scans_of(graph)
	wrong_zone_id[&"tb1_toybox_gate"].declared_zone_id = &"someone_else"
	_expect_complaint(_run(graph, wrong_zone_id), WorldCheck.CHECK_SCENES, "the root's zone_id is 'someone_else' but the zone is 'tb1_toybox_gate'", "a room scene whose zone_id differs from its room is reported")

	# entries: every room has an entry.
	var no_entry := _scans_of(graph)
	no_entry[&"tb1_toybox_gate"].entry_ids.clear()
	_expect_complaint(_run(graph, no_entry), WorldCheck.CHECK_ENTRIES, "rooms/tb1_toybox_gate: the room has no entry marker", "a room with no entry marker is reported")

	# exits: every exit resolves.
	var door_to_nowhere := _scans_of(graph)
	door_to_nowhere[&"t1_white_kings_fall"].exits[0]["target_zone"] = &"atlantis"
	_expect_complaint(_run(graph, door_to_nowhere), WorldCheck.CHECK_EXITS_RESOLVE, "rooms/t1_white_kings_fall/Exit_To_T2: a door leads to zone 'atlantis', which is not in content/world/world.tres", "a door to a room the graph lacks is reported")
	var typo_in_entry := _scans_of(graph)
	typo_in_entry[&"t1_white_kings_fall"].exits[0]["target_entry"] = &"west_entrance"
	_expect_complaint(_run(graph, typo_in_entry), WorldCheck.CHECK_EXITS_RESOLVE, "a door leads to entry 'west_entrance' of zone 't2_fallen_sword_tile', which has no such entry marker", "a door to an entry that does not exist is reported, not quietly replaced by the first entry")

	# doors and edges are two accounts of one thing.
	var undeclared_door := _scans_of(graph)
	undeclared_door[&"tb1_toybox_gate"].exits.append({"door": &"Exit_Extra", "target_zone": &"h1_chess_rug_hub", "target_entry": &"from_toybox", "requires_room_clear": false, "locked_message": ""})
	_expect_complaint(_run(graph, undeclared_door), WorldCheck.CHECK_EDGES_MATCH_DOORS, "rooms/tb1_toybox_gate/Exit_Extra: no edge of content/world/world.tres declares this door", "a door no edge declares is reported")
	var edge_without_a_door := _copy_of(graph)
	var phantom_edge := WorldEdge.new()
	phantom_edge.from_room = &"tb1_toybox_gate"
	phantom_edge.door = &"Exit_Phantom"
	phantom_edge.to_room = &"h1_chess_rug_hub"
	phantom_edge.to_entry = &"from_toybox"
	edge_without_a_door.edges.append(phantom_edge)
	_expect_complaint(_run(edge_without_a_door, _scans_of(edge_without_a_door)), WorldCheck.CHECK_EDGES_MATCH_DOORS, "the edge tb1_toybox_gate/Exit_Phantom has no door of that name in the room", "an edge with no door is reported")
	var disagreeing := _copy_of(graph)
	disagreeing.find_edge(&"tb1_toybox_gate", &"Exit_To_H1").to_entry = &"from_boss"
	_expect_complaint(_run(disagreeing, _scans_of(disagreeing)), WorldCheck.CHECK_EDGES_MATCH_DOORS, "the door leads to h1_chess_rug_hub/from_toybox but its edge says h1_chess_rug_hub/from_boss", "a door and an edge that name different targets are reported")

	# return doors.
	var one_way_trap := _copy_of(graph)
	one_way_trap.edges.erase(one_way_trap.find_edge(&"tb1_toybox_gate", &"Exit_To_H1"))
	var one_way_trap_scans := _scans_of(one_way_trap)
	one_way_trap_scans[&"tb1_toybox_gate"].exits.clear()
	var trap_problems := _run(one_way_trap, one_way_trap_scans)
	_expect_complaint(trap_problems, WorldCheck.CHECK_RETURN_DOORS, "the door h1_chess_rug_hub/Exit_To_Act2Toybox leads to 'tb1_toybox_gate', which has no door back to 'h1_chess_rug_hub'", "a way in with no way back is reported")
	one_way_trap.find_edge(&"h1_chess_rug_hub", &"Exit_To_Act2Toybox").one_way = true
	_expect((_run(one_way_trap, one_way_trap_scans)[WorldCheck.CHECK_RETURN_DOORS] as PackedStringArray).is_empty(), "...and marking the edge one_way says it is meant")

	# orphans.
	var orphan := _copy_of(graph)
	var island := WorldRoom.new()
	island.room_id = &"island_room"
	island.scene = graph.get_zone_scene(&"tb1_toybox_gate")
	island.map_slot = Vector2i(7, 7)
	orphan.rooms.append(island)
	_expect_complaint(_run(orphan, _scans_of(orphan)), WorldCheck.CHECK_NO_ORPHAN_ROOMS, "room 'island_room' cannot be reached from the start room 't1_white_kings_fall' by any door", "a room no door leads to is reported as an orphan")

	# locks.
	var silent_lock := _copy_of(graph)
	silent_lock.find_lock(&"b1_clear").message_key = ""
	_expect_complaint(_run(silent_lock, _scans_of(silent_lock)), WorldCheck.CHECK_GRAPH, "Lock 'b1_clear' has no message_key", "a lock with no message key is reported")
	var wordless_lock := _copy_of(graph)
	wordless_lock.find_lock(&"b1_clear").message_key = "ROOM_NO_SUCH_LINE_ANYWHERE"
	_expect_complaint(_run(wordless_lock, _scans_of(wordless_lock)), WorldCheck.CHECK_LOCKS, "lock 'b1_clear' says 'ROOM_NO_SUCH_LINE_ANYWHERE', which has no row", "a lock whose message key has no English row is reported")
	var wrong_kind := _copy_of(graph)
	wrong_kind.find_lock(&"t3_clear").kind = WorldLock.KIND_FLAG
	wrong_kind.find_lock(&"t3_clear").subject = &"boss.black_pawn_captain"
	_expect_complaint(_run(wrong_kind, _scans_of(wrong_kind)), WorldCheck.CHECK_LOCKS, "the door waits for the room to be cleared, so its edge needs a room_clear lock", "a door that waits for a clear but is held by another kind of lock is reported")
	var unlocked_edge := _copy_of(graph)
	unlocked_edge.find_edge(&"t4_broken_rule_yard", &"Exit_To_B1").lock_id = &""
	_expect_complaint(_run(unlocked_edge, _scans_of(unlocked_edge)), WorldCheck.CHECK_LOCKS, "the door waits for the room to be cleared, so its edge needs a room_clear lock", "a shut door whose edge names no lock is reported")
	var different_words := _copy_of(graph)
	different_words.find_lock(&"t4_clear").message_key = "ROOM_T3_FIRST_PAWN_CLASH_LOCKED"
	_expect_complaint(_run(different_words, _scans_of(different_words)), WorldCheck.CHECK_LOCKS, "the door says 'ROOM_T4_BROKEN_RULE_YARD_LOCKED' but its lock says 'ROOM_T3_FIRST_PAWN_CLASH_LOCKED'", "a door and its lock that say different things are reported")
	var lock_on_an_open_door := _copy_of(graph)
	lock_on_an_open_door.find_edge(&"t2_fallen_sword_tile", &"Exit_To_T3").lock_id = &"t3_clear"
	_expect_complaint(_run(lock_on_an_open_door, _scans_of(lock_on_an_open_door)), WorldCheck.CHECK_LOCKS, "its edge is held by a room_clear lock but the door does not wait for a clear", "a clear-lock on a door that never waits for a clear is reported")
	var unused_lock := _copy_of(graph)
	var spare := WorldLock.new()
	spare.lock_id = &"spare"
	spare.kind = WorldLock.KIND_FLAG
	spare.subject = &"boss.knight_captain"
	spare.message_key = "ROOM_T3_FIRST_PAWN_CLASH_LOCKED"
	unused_lock.locks.append(spare)
	_expect_complaint(_run(unused_lock, _scans_of(unused_lock)), WorldCheck.CHECK_GRAPH, "Lock 'spare' holds no door", "a lock that holds no door is reported")

	# the map.
	var out_of_region := _copy_of(graph)
	out_of_region.find_room(&"tb1_toybox_gate").map_slot = Vector2i(0, 0)
	_expect_complaint(_run(out_of_region, _scans_of(out_of_region)), WorldCheck.CHECK_MAP, "map slot (0, 0) is outside the region of its district 'toybox'", "a room placed outside its district's region is reported")
	var no_district := _scans_of(graph)
	no_district[&"tb1_toybox_gate"].district = &""
	_expect_complaint(_run(graph, no_district), WorldCheck.CHECK_MAP, "the room names no district", "a room that names no district is reported")

	# room meta.
	var bad_meta := _scans_of(graph)
	bad_meta[&"t1_white_kings_fall"].configuration_problems.append("act 9 is not an act")
	_expect_complaint(_run(graph, bad_meta), WorldCheck.CHECK_ROOM_META, "rooms/t1_white_kings_fall: act 9 is not an act", "what a room's own configuration check says is carried into the world check")
	var no_start_line := _scans_of(graph)
	no_start_line[&"t1_white_kings_fall"].start_message_key = "ROOM_NO_SUCH_START_LINE"
	_expect_complaint(_run(graph, no_start_line), WorldCheck.CHECK_ROOM_META, "room_message 'ROOM_NO_SUCH_START_LINE' has no row", "a start line with no English row is reported")


# --------------------------------------------------------------------------- the lock and flag classes
func _check_the_lock_and_flag_classes() -> void:
	_expect(FlagId.is_valid(&"boss.knight_captain") and FlagId.is_valid(&"prompt.move") and FlagId.is_valid(&"completed"), "a flag id is lowercase words joined by _, in groups joined by a dot")
	_expect(not FlagId.is_valid(&"Boss.Knight") and not FlagId.is_valid(&"") and not FlagId.is_valid(&"boss.") and not FlagId.is_valid(&"1boss") and not FlagId.is_valid(&"boss knight"), "...and a capital, an empty name, a trailing dot, a leading digit or a space is not")

	var flag_lock := WorldLock.new()
	flag_lock.lock_id = &"toybox_open"
	flag_lock.kind = WorldLock.KIND_FLAG
	flag_lock.subject = &"boss.black_pawn_captain"
	flag_lock.message_key = "ROOM_H1_CHESS_RUG_HUB_LOCKED_TOYBOX"
	_expect(flag_lock.validate().is_empty(), "a flag lock (the hub's doors, M5 step 2) with a flag, a key and an id is valid")
	flag_lock.subject = &"Boss Captain"
	_expect(_any_contains(flag_lock.validate(), "needs a flag id as its subject"), "a flag lock whose subject is no flag id is reported")
	var counter_lock := WorldLock.new()
	counter_lock.lock_id = &"three_calls"
	counter_lock.kind = WorldLock.KIND_COUNTER_AT_LEAST
	counter_lock.subject = &"child_calls_used"
	counter_lock.at_least = 3
	counter_lock.message_key = "ROOM_DH1_FOYER_LOCKED"
	_expect(counter_lock.validate().is_empty(), "a counter lock with a counter and a number is valid")
	var unlock_lock := WorldLock.new()
	unlock_lock.lock_id = &"needs_step"
	unlock_lock.kind = WorldLock.KIND_UNLOCK
	unlock_lock.subject = &"rule_step"
	unlock_lock.message_key = "ROOM_BS1_LOCKED"
	_expect(unlock_lock.validate().is_empty(), "an unlock lock (the skill locks of M7c) with an unlock id is valid")
	unlock_lock.subject = &""
	_expect(_any_contains(unlock_lock.validate(), "needs an unlock id as its subject"), "an unlock lock with no unlock id is reported")
	var clear_lock := WorldLock.new()
	clear_lock.lock_id = &"clear_here"
	clear_lock.kind = WorldLock.KIND_ROOM_CLEAR
	clear_lock.subject = &"boss.x"
	clear_lock.message_key = "words and not a key"
	var clear_problems := clear_lock.validate()
	_expect(_any_contains(clear_problems, "subject must be empty") and _any_contains(clear_problems, "is not a text key"), "a room_clear lock that names a subject, and a message that is words and not a key, are reported")
	var unnamed := WorldLock.new()
	unnamed.kind = "teleport"
	_expect(_any_contains(unnamed.validate(), "lowercase snake_case") and _any_contains(unnamed.validate(), "has the kind 'teleport'") and _any_contains(unnamed.validate(), "has no message_key"), "a lock with no id, an unknown kind and no message is reported three times over")
	_expect(WorldLock.KINDS == ["room_clear", "flag", "unlock", "counter_at_least"], "the lock kinds are the plan's (5.7): room clear, flag, unlock id, counter")

	# The Inspector offers the kinds from the @export_enum hint; the class lists them again in KINDS. They must be one list.
	var hint := ""
	for property in WorldLock.new().get_property_list():
		if property["name"] == "kind":
			hint = String(property["hint_string"])
	_expect(hint == ",".join(WorldLock.KINDS), "the Inspector's list of lock kinds equals WorldLock.KINDS (%s)" % hint)


# --------------------------------------------------------------------------- helpers
func _scans_of(graph: WorldGraph) -> Dictionary[StringName, RoomScan]:
	var scan_by_room: Dictionary[StringName, RoomScan] = {}
	for room_id in graph.room_ids():
		var scan := RoomScan.of(graph.get_zone_scene(room_id))
		if scan != null:
			scan_by_room[room_id] = scan
	return scan_by_room


func _run(graph: WorldGraph, scan_by_room: Dictionary[StringName, RoomScan]) -> Dictionary[StringName, PackedStringArray]:
	var folder_ids: Array[StringName] = ContentDb.ids(&"rooms")
	var scene_path_of := func(room_id: StringName) -> String: return ContentDb.path_of(&"rooms", room_id)
	return WorldCheck.run(graph, scan_by_room, folder_ids, scene_path_of, TextService.has_key)


## A copy of the graph whose rooms, edges, locks and regions are new objects, so a test can break it without
## touching the one every other suite of the process reads.
func _copy_of(graph: WorldGraph) -> WorldGraph:
	var copy := WorldGraph.new()
	copy.start_room_id = graph.start_room_id
	for room in graph.rooms:
		var room_copy := WorldRoom.new()
		room_copy.room_id = room.room_id
		room_copy.scene = room.scene
		room_copy.map_slot = room.map_slot
		copy.rooms.append(room_copy)
	for edge in graph.edges:
		var edge_copy := WorldEdge.new()
		edge_copy.from_room = edge.from_room
		edge_copy.door = edge.door
		edge_copy.to_room = edge.to_room
		edge_copy.to_entry = edge.to_entry
		edge_copy.one_way = edge.one_way
		edge_copy.lock_id = edge.lock_id
		copy.edges.append(edge_copy)
	for lock in graph.locks:
		var lock_copy := WorldLock.new()
		lock_copy.lock_id = lock.lock_id
		lock_copy.kind = lock.kind
		lock_copy.subject = lock.subject
		lock_copy.at_least = lock.at_least
		lock_copy.message_key = lock.message_key
		copy.locks.append(lock_copy)
	for region in graph.regions:
		var region_copy := WorldRegion.new()
		region_copy.district = region.district
		region_copy.slots = region.slots
		copy.regions.append(region_copy)
	return copy


func _expect_complaint(problems_by_check: Dictionary[StringName, PackedStringArray], check: StringName, fragment: String, label: String) -> void:
	var sentences: PackedStringArray = problems_by_check[check]
	for sentence in sentences:
		if sentence.contains(fragment):
			_expect(true, "the check '%s' can fail: %s" % [check, label])
			return
	_expect(false, "the check '%s' can fail: %s (no sentence contains: %s; it said: %s)" % [check, label, fragment, " || ".join(sentences)])


func _any_contains(sentences: PackedStringArray, fragment: String) -> bool:
	for sentence in sentences:
		if sentence.contains(fragment):
			return true
	return false
