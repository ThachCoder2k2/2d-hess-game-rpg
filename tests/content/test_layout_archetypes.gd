extends UnboundTest

## The monotony guard's second rule (docs/game-base-plan.md D-02, 7.1, M5 acceptance): no two consecutive rooms of the critical path share a
## layout_archetype, so the route does not read as door-connected rectangles (the owner's verdict of 2026-07-29). Three parts:
##   1. the plan's table (tests/fixtures/plan_room_table.gd: the archetype column of 7.4) walked along the critical path;
##   2. the lint is shown able to fail (a COPY of the archetypes is broken three ways and each is named);
##   3. the shipped scenes: the archetype every room's RoomEncounter carries IS the plan's, and the same rule walks them, enforced.
## (This check began in test_plan_rooms at M5 step 2, which now leaves the monotony guard to this suite.)

const PlanLints := preload("res://tests/support/plan_lints.gd")
const PlanRoomTable := preload("res://tests/fixtures/plan_room_table.gd")


func _init() -> void:
	suite_title = "TEST LAYOUT ARCHETYPES"
	var table_archetypes := {}
	for row in PlanRoomTable.ROWS:
		table_archetypes[row["id"]] = row["archetype"]
	_check_the_table(table_archetypes)
	_check_the_lint_can_fail(table_archetypes)
	_check_the_scenes(table_archetypes)
	finish()


func _check_the_table(table_archetypes: Dictionary) -> void:
	var problems := PlanLints.archetype_problems(table_archetypes, PlanRoomTable.CRITICAL_PATH)
	for sentence in problems:
		printerr("  %s" % sentence)
	_expect(problems.is_empty(), "no two rooms in a row of the plan's critical path share an archetype")
	var steps := PlanRoomTable.CRITICAL_PATH.size() - 1
	_expect(steps == 34, "%d steps of the route were compared (35 rooms of the walk, the hub five times)" % steps)
	var distinct := {}
	for archetype in table_archetypes.values():
		distinct[archetype] = true
	_expect(distinct.size() >= 25, "the 34 rooms use %d different archetypes (at least 25): winding, yard, fence, lanes, track, arena, islands, hub... " % distinct.size())
	var arenas := 0
	for archetype in table_archetypes.values():
		arenas += 1 if archetype == &"arena" else 0
	_expect(arenas == 5, "the arena is the one archetype that repeats, for the Captain, the Knight, the Rook, the Queen and the King: %d, never twice in a row (a hub, a shortcut or a test stands between)" % arenas)


func _check_the_lint_can_fail(table_archetypes: Dictionary) -> void:
	var path := PlanRoomTable.CRITICAL_PATH
	_expect(PlanLints.archetype_problems(table_archetypes.duplicate(), path).is_empty(), "control: a copy of the archetypes is clean, so each break below is the only difference")

	var same_as_its_neighbour := table_archetypes.duplicate()
	same_as_its_neighbour[&"tb2_l_jump_lanes"] = &"fence"
	_expect_named(PlanLints.archetype_problems(same_as_its_neighbour, path), "tb1_toybox_gate and tb2_l_jump_lanes follow each other on the critical path and share the layout archetype 'fence' (D-02)", "tb2 drawn as a fence like tb1: the pair is named")

	var boss_beside_a_boss_shaped_room := table_archetypes.duplicate()
	boss_beside_a_boss_shaped_room[&"h1_chess_rug_hub"] = &"arena"
	var arena_problems := PlanLints.archetype_problems(boss_beside_a_boss_shaped_room, path)
	_expect_named(arena_problems, "b1_black_pawn_captain and h1_chess_rug_hub follow each other on the critical path and share the layout archetype 'arena'", "the hub drawn as an arena after the first boss: named")

	var unknown_room := table_archetypes.duplicate()
	unknown_room.erase(&"bs3_torn_page_bridge")
	_expect_named(PlanLints.archetype_problems(unknown_room, path), "a room of the critical path has no archetype", "a room with no archetype at all: named, not skipped")

	_expect(PlanLints.archetype_problems(table_archetypes, path).is_empty(), "the breaks are gone: the real archetypes are judged clean again")


func _check_the_scenes(table_archetypes: Dictionary) -> void:
	var graph := ContentDb.world()
	var scan_by_room := PlanLints.scans_of(graph)
	var scene_archetypes := {}
	var same_as_the_plan := 0
	for room_id: StringName in scan_by_room:
		scene_archetypes[room_id] = scan_by_room[room_id].layout_archetype
		if scene_archetypes[room_id] == table_archetypes.get(room_id):
			same_as_the_plan += 1
	_expect(scan_by_room.size() == 34 and same_as_the_plan == 34, "the archetype of each of the 34 scenes is the plan's (%d of %d)" % [same_as_the_plan, scan_by_room.size()])
	var problems := PlanLints.archetype_problems(scene_archetypes, PlanRoomTable.CRITICAL_PATH)
	for sentence in problems:
		printerr("  %s" % sentence)
	_expect(problems.is_empty(), "no two rooms in a row of the critical path, walked on the shipped scenes, share an archetype (the route of the doors, T1 to the Desk)")
	# The route of the graph itself is the route of the plan (the doors lead where the table says).
	var doors_follow_the_route := true
	for index in range(1, PlanRoomTable.CRITICAL_PATH.size()):
		var door_exists := false
		for edge in graph.edges_from(PlanRoomTable.CRITICAL_PATH[index - 1]):
			door_exists = door_exists or edge.to_room == PlanRoomTable.CRITICAL_PATH[index]
		doors_follow_the_route = doors_follow_the_route and door_exists
	_expect(doors_follow_the_route, "every step of the critical path is a door of the world graph (the route that was compared is one a pawn can walk)")


func _expect_named(problems: PackedStringArray, fragment: String, label: String) -> void:
	var named := false
	for sentence in problems:
		named = named or sentence.contains(fragment)
	_expect(named, "the lint can fail: %s (it said: %s)" % [label, "; ".join(problems).left(260)])
