extends UnboundTest

## Every room of docs/game-base-plan.md 7.4 exists with the plan's id, size, archetype, role, act and district, holds the pieces of
## the right family, and is passable by the rules it will have (M5 step 2). The plan's table is data in tests/fixtures/plan_room_table.gd
## and the shipped scenes are held to it, one row at a time, so a room that drifts from the plan (a renamed id, a 16x9 arena, a
## boss with no Recruit beside it) is named. The row counts are asserted in the open so a walk that looked at nothing shows.
## Also here: the proof that no stub asks for a crossing that nobody can make yet. (The monotony guard of D-02, no two rooms in a row of the
## critical path sharing an archetype, is test_layout_archetypes; its loops are test_district_loops.)

const PlanRoomTable := preload("res://tests/fixtures/plan_room_table.gd")


func _init() -> void:
	suite_title = "TEST PLAN ROOMS"
	var graph := ContentDb.world()
	var scan_by_room := _scans_of(graph)
	_check_the_table_is_the_plan(graph)
	_check_every_room_is_the_plans(graph, scan_by_room)
	_check_the_pieces_of_every_room(scan_by_room)
	_check_the_doors_that_wait_for_a_clear(graph, scan_by_room)
	_check_the_bosses()
	_check_no_stub_has_a_crossing()
	finish()


func _scans_of(graph: WorldGraph) -> Dictionary[StringName, RoomScan]:
	var scan_by_room: Dictionary[StringName, RoomScan] = {}
	for room_id in graph.room_ids():
		var scan := RoomScan.of(graph.get_zone_scene(room_id))
		if scan != null:
			scan_by_room[room_id] = scan
	return scan_by_room


func _check_the_table_is_the_plan(graph: WorldGraph) -> void:
	_expect(PlanRoomTable.ROWS.size() == 34, "the table holds the plan's 34 shipping rooms (%d)" % PlanRoomTable.ROWS.size())
	var ids_in_the_table: Array[StringName] = []
	for row in PlanRoomTable.ROWS:
		ids_in_the_table.append(row["id"])
	var ids_in_the_graph := graph.room_ids()
	ids_in_the_graph.sort()
	var sorted_table_ids := ids_in_the_table.duplicate()
	sorted_table_ids.sort()
	_expect(sorted_table_ids == ids_in_the_graph, "the graph lists exactly those rooms and no other (no dev_sandbox: that is M6's, and not a shipping room)")
	var per_act := {}
	for row in PlanRoomTable.ROWS:
		per_act[row["act"]] = int(per_act.get(row["act"], 0)) + 1
	_expect(per_act == {1: 6, 2: 6, 3: 6, 4: 6, 5: 5, 6: 4, 7: 1}, "by act: 6, 6, 6, 6, 5, 4 and the Ending's 1, as plan 7.4 lists them (%s)" % [per_act])
	var optional_rooms := 0
	var boss_rooms := 0
	for row in PlanRoomTable.ROWS:
		optional_rooms += 1 if row["recipe"] == "optional" else 0
		boss_rooms += 1 if row["recipe"] == "boss" else 0
	_expect(optional_rooms == 3 and boss_rooms == 6, "three optional rooms (tbo, bso, bto) and six boss rooms")


func _check_every_room_is_the_plans(graph: WorldGraph, scan_by_room: Dictionary[StringName, RoomScan]) -> void:
	var stage_one := [&"t1_white_kings_fall", &"t2_fallen_sword_tile", &"t3_first_pawn_clash", &"t4_broken_rule_yard", &"b1_black_pawn_captain", &"h1_chess_rug_hub"]
	var stubs := 0
	var arenas_18_wide := 0
	for row in PlanRoomTable.ROWS:
		var room_id: StringName = row["id"]
		var scan: RoomScan = scan_by_room.get(room_id)
		if not _expect(scan != null and graph.has_zone(room_id), "%s: the room is in the graph and its scene reads" % room_id):
			continue
		_expect(scan.board_size == row["size"], "%s: the board is %s (the plan says %s)" % [room_id, scan.board_size, row["size"]])
		_expect(scan.layout_archetype == row["archetype"], "%s: the layout archetype is '%s' (the plan says '%s')" % [room_id, scan.layout_archetype, row["archetype"]])
		_expect(scan.recipe_name == row["recipe"], "%s: the role is %s (the plan says %s)" % [room_id, scan.recipe_name, row["recipe"]])
		_expect(scan.act == row["act"] and scan.district == row["district"], "%s: act %d in the %s (the plan says act %d, %s)" % [room_id, scan.act, scan.district, row["act"], row["district"]])
		_expect(scan.configuration_problems.is_empty(), "%s: the room's own meta check finds nothing wrong" % room_id)
		if room_id in stage_one:
			_expect(scan.status_name == "greybox", "%s: a Stage 1 room is GREYBOX (%s)" % [room_id, scan.status_name])
		else:
			_expect(scan.status_name == "stub", "%s: a room made at M5 is a STUB (%s)" % [room_id, scan.status_name])
			stubs += 1
		_expect(scan.checkpoint_on_entry == (row["recipe"] == "boss" or row["archetype"] == &"hub"), "%s: only a hub and a boss room is a checkpoint (D-16)" % room_id)
		if scan.board_size == Vector2i(18, 9):
			arenas_18_wide += 1
		_expect(scan.start_message_key == "ROOM_%s_START" % String(room_id).to_upper() and TextService.has_key("ROOM_%s_NAME" % String(room_id).to_upper()), "%s: it has a name and an arrival line, both text keys with an English row" % room_id)
	_expect(stubs == 28, "28 rooms are stubs: the 27 new ones and tb1 (%d)" % stubs)
	_expect(arenas_18_wide == 6, "six rooms are 18 wide: the five arenas of the districts and ub2 (D-02: arenas up to 18x9; %d)" % arenas_18_wide)


func _check_the_pieces_of_every_room(scan_by_room: Dictionary[StringName, RoomScan]) -> void:
	var rooms_with_pieces_checked := 0
	var families_seen := {}
	for row in PlanRoomTable.ROWS:
		if row["enemies"] == null:
			continue
		var scan: RoomScan = scan_by_room.get(row["id"])
		if scan == null:
			continue
		var placed: Array[String] = []
		for definition in scan.enemy_definitions:
			placed.append(String(definition.id))
			families_seen[definition.visual.piece_type] = true
		placed.sort()
		var expected: Array[String] = []
		for enemy_id: StringName in row["enemies"]:
			expected.append(String(enemy_id))
		expected.sort()
		_expect(placed == expected, "%s parks %s (the plan's family; found %s)" % [row["id"], expected, placed])
		rooms_with_pieces_checked += 1
	_expect(rooms_with_pieces_checked == 29, "the pieces of 29 rooms were compared with the table: the 28 stubs and the hub, which holds none (%d)" % rooms_with_pieces_checked)
	var every_family := [&"pawn", &"knight", &"bishop", &"rook", &"queen", &"king"]
	var missing_families: Array[String] = []
	for family: StringName in every_family:
		if not families_seen.has(family):
			missing_families.append(String(family))
	_expect(missing_families.is_empty(), "every family of the plan stands in some new room: pawn, knight, bishop, rook, queen and king (missing: %s)" % ", ".join(PackedStringArray(missing_families)))


## A door waits for a clear in the rooms the plan gates, and nowhere else: a stub is passable by the rules the room will have.
func _check_the_doors_that_wait_for_a_clear(graph: WorldGraph, scan_by_room: Dictionary[StringName, RoomScan]) -> void:
	for row in PlanRoomTable.ROWS:
		var scan: RoomScan = scan_by_room.get(row["id"])
		if scan == null:
			continue
		var shut := 0
		for door in scan.exits:
			if bool(door["requires_room_clear"]):
				shut += 1
				_expect(not scan.enemy_definitions.is_empty(), "%s/%s: a door that waits for a clear is in a room with something to clear" % [row["id"], door["door"]])
		_expect(shut == row["clear_doors"], "%s has %d door(s) that wait for a clear (the plan gates %d)" % [row["id"], shut, row["clear_doors"]])
	# A door that waits for a flag leads to a district, and a skill lock never shuts a door in the runtime.
	var flag_doors := 0
	for scan: RoomScan in scan_by_room.values():
		for door in scan.exits:
			if StringName(door["requires_flag"]) != &"":
				flag_doors += 1
	_expect(flag_doors == 5, "five doors wait for a boss's flag: the hub's district doors (%d)" % flag_doors)
	var skill_edges := 0
	for edge in graph.edges:
		skill_edges += 1 if edge.skill_lock_id != &"" else 0
	_expect(skill_edges == 11, "eleven doors name a skill lock that arrives in M7c (the three hub doors, tb4 x2, bs2, bs4 x2, bt1, bt4 x2: %d); none shuts a door today" % skill_edges)


func _check_the_bosses() -> void:
	for room_id: StringName in PlanRoomTable.BOSS_OF_ROOM:
		var boss_id: StringName = PlanRoomTable.BOSS_OF_ROOM[room_id]
		var definition := ContentDb.fetch(&"enemies", boss_id) as EnemyDefinition
		_expect(definition != null and definition.defeat_flag == StringName("boss.%s" % boss_id), "%s: the boss %s sets boss.%s when it falls" % [room_id, boss_id, boss_id])
		var scene := ContentDb.fetch(&"rooms", room_id) as PackedScene
		var room := scene.instantiate()
		var bosses_in_room := 0
		for child in room.get_children():
			var view := child as ActorView
			if view != null and view.definition != null and view.definition.id == boss_id:
				bosses_in_room += 1
		room.free()
		_expect(bosses_in_room == 1, "%s holds exactly one %s" % [room_id, boss_id])


## A gap cell is allowed in a stub only beside the walk (a tear, a pit): no door or entry may be cut off from another by gaps, which
## is what test_room_doors_reachable walks on every booted room. Here: no room uses a `traversal` crossing, because the verbs that
## cross one do not exist until M7 and M10, and a crossing nobody can make would be a dead end.
func _check_no_stub_has_a_crossing() -> void:
	var crossings := 0
	for row in PlanRoomTable.ROWS:
		var room := (ContentDb.fetch(&"rooms", row["id"]) as PackedScene).instantiate()
		for child in room.get_children():
			if child is TraversalGapMarker:
				crossings += 1
		room.free()
	_expect(crossings == 0, "no room has a mandatory crossing (a TraversalGap) yet: the verbs that cross one are M7 and M10, so a stub never needs one (%d found)" % crossings)
