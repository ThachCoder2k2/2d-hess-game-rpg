extends UnboundTest

## The room data audit (docs/game-base-plan.md 3.5 R4, R28, R32, 7.4, 7.5, requirements 87, 88 and 127, D-02, M5 acceptance), run over the plan's 7.4
## table (tests/fixtures/plan_encounter_table.gd) and over the world's rooms:
##   - the Teach ladder (R4): a Teach room introduces at most one new verb or shape, and the new shape is shown fenced before any live instance;
##   - one new geometry at a time (req 88): no room meets more than one new shape;
##   - every room answers (req 127): what it teaches, what feeling it is after, which district and act it is in (the plan's room table), and why it is
##     next to its neighbours (a door stays in a district, or goes to the hub, or into the Ending);
##   - each district has a format-breaker (D-02, 7.5): an objective kind other than clear, and the four the plan names are exactly that;
##   - the emotional arc on the table (R32): the intensities are the plan's check, no three in a row are equal, the bosses never fall.
## And the rooms themselves: the encounter meta of every one of the 34 scenes IS the plan's row (objective kind, threat, shapes, intro, intensity),
## enforced, so what the lints judge in the table is what the Inspector shows on the room.
##
## The lint is shown able to fail: a COPY of the table (and of the graph) is broken in twelve ways, one at a time, and each is named; the real data is
## judged clean again at the end. Two plan rules cannot be checked on stub rooms yet and are REPORT lines: the near group of at most two common enemies
## (there are no aggro groups until M8a) and the shapes a boss throws (the boss frameworks are M8b).

const PlanLints := preload("res://tests/support/plan_lints.gd")
const PlanEncounterTable := preload("res://tests/fixtures/plan_encounter_table.gd")
const PlanRoomTable := preload("res://tests/fixtures/plan_room_table.gd")


func _init() -> void:
	suite_title = "TEST ROOM DATA AUDIT"
	var graph := ContentDb.world()
	var scan_by_room := PlanLints.scans_of(graph)
	_check_the_table()
	_check_the_graph(graph, scan_by_room)
	_check_the_scenes_are_the_plans_rows(scan_by_room)
	_check_the_lint_can_fail(graph, scan_by_room)
	_report_what_cannot_be_checked_yet(scan_by_room)
	finish()


func _check_the_table() -> void:
	var rows := PlanEncounterTable.ROWS
	var path := PlanRoomTable.CRITICAL_PATH
	for sentence in PlanLints.every_room_answers_problems(rows):
		printerr("  %s" % sentence)
	_expect(PlanLints.every_room_answers_problems(rows).is_empty(), "every one of the 34 rooms answers: what it teaches, what feeling it is after, its district and act, listed once and in route order (req 127)")
	_expect(PlanLints.one_new_shape_problems(rows, path).is_empty(), "no room meets more than one new shape for the first time (req 88: one new geometry at a time)")
	_expect(PlanLints.teach_ladder_problems(rows, path).is_empty(), "every Teach room introduces at most one new verb or shape, and shows a new shape fenced first (R4)")
	_expect(PlanLints.format_breaker_problems(rows).is_empty(), "every district has a format-breaker, and the four the plan names (tb3, bs3, bt2, dh1) have an objective kind other than clear (D-02, 7.5)")
	var arc_problems := PlanLints.arc_problems(rows, path)
	for sentence in arc_problems:
		printerr("  %s" % sentence)
	_expect(arc_problems.is_empty(), "the intensities of the route are the plan's check, no three in a row are equal, the bosses never fall and no two boss-grade rooms follow each other (R32)")

	# The facts behind the passes, in the open.
	var new_shapes_by_room := PlanLints.new_shapes_of_each_room(rows, path)
	var rooms_with_a_new_shape: Dictionary = {}
	for room_id: StringName in new_shapes_by_room:
		if not (new_shapes_by_room[room_id] as Array).is_empty():
			rooms_with_a_new_shape[room_id] = new_shapes_by_room[room_id][0]
	_expect(rooms_with_a_new_shape == {
		&"t3_first_pawn_clash": &"diagonal_slash", &"t4_broken_rule_yard": &"straight_bar", &"tb1_toybox_gate": &"knight_landing", &"tb2_l_jump_lanes": &"charge_line",
		&"tb3_toy_track_ambush": &"train_lane", &"bs1_book_spine_steps": &"diagonal_lane", &"bt1_block_yard": &"rook_line", &"dh3_royal_stage": &"union_lines", &"ub3_rule_engine": &"tile_rewrite",
	}, "nine rooms bring a new shape, one each, in the order the plan teaches them: the pawn's diagonal, the Armed bar, the Knight (fenced), the charge line, the train, the Bishop (fenced), the Rook (fenced), the Queen's lanes (fenced), the rewrite (fenced): %s" % [rooms_with_a_new_shape])
	var teach_rooms := 0
	for room_row in PlanRoomTable.ROWS:
		teach_rooms += 1 if room_row["recipe"] == "teach" else 0
	_expect(teach_rooms == 4, "four Teach rooms were laddered (t2, tb1, bs1, bt1: %d)" % teach_rooms)
	var breakers := {}
	for room_id: StringName in [&"tb3_toy_track_ambush", &"bs3_torn_page_bridge", &"bt2_ruler_bridge", &"dh1_foyer"]:
		breakers[room_id] = PlanEncounterTable.row_of(room_id)["objective"]
	_expect(breakers == {&"tb3_toy_track_ambush": &"reach", &"bs3_torn_page_bridge": &"reach", &"bt2_ruler_bridge": &"survive", &"dh1_foyer": &"none"}, "the four format-breakers are a train chase (reach), a page slide (reach), a hold-the-line timer (survive) and a tea party (none): %s" % [breakers])
	var bosses: Array[int] = []
	for room_id in path:
		if PlanRoomTable.BOSS_OF_ROOM.has(room_id):
			bosses.append(int(PlanEncounterTable.row_of(room_id)["intensity"]))
	_expect(bosses == [7, 8, 8, 9, 9, 10], "the boss intensities run %s (non-decreasing, no three equal)" % [bosses])


func _check_the_graph(graph: WorldGraph, scan_by_room: Dictionary[StringName, RoomScan]) -> void:
	var problems := PlanLints.adjacency_problems(graph, scan_by_room)
	for sentence in problems:
		printerr("  %s" % sentence)
	_expect(problems.is_empty(), "every one of the %d doors joins two rooms of one district, or goes to or from the hub, or enters the Ending (why adjacent)" % graph.edges.size())
	_expect(graph.edges.size() == 69, "the doors judged are the world's 69")


## The encounter meta of a scene is the row of the plan.
func _check_the_scenes_are_the_plans_rows(scan_by_room: Dictionary[StringName, RoomScan]) -> void:
	var judged := 0
	for row in PlanEncounterTable.ROWS:
		var room_id: StringName = row["id"]
		var scan: RoomScan = scan_by_room.get(room_id)
		if not _expect(scan != null, "%s: the scene reads" % room_id):
			continue
		var same := scan.objective_kind_name == String(row["objective"]) and scan.threat_budget == int(row["threat"]) and scan.threat_shapes == int(row["shapes"]) \
			and scan.intro == bool(row["intro"]) and scan.intensity == int(row["intensity"])
		_expect(same, "%s: the scene carries the plan's row (objective %s, threat %d, shapes %d, intro %s, intensity %d); it says %s, %d, %d, %s, %d" % [room_id, row["objective"], row["threat"], row["shapes"], row["intro"], row["intensity"], scan.objective_kind_name, scan.threat_budget, scan.threat_shapes, scan.intro, scan.intensity])
		judged += 1
	_expect(judged == 34, "all 34 scenes were held to the plan's table (%d)" % judged)


func _check_the_lint_can_fail(graph: WorldGraph, scan_by_room: Dictionary[StringName, RoomScan]) -> void:
	var path := PlanRoomTable.CRITICAL_PATH
	_expect(PlanLints.every_room_answers_problems(PlanEncounterTable.copy_of_rows()).is_empty(), "control: a copy of the table is clean, so each break below is the only difference")

	var silent := _with(PlanEncounterTable.copy_of_rows(), &"tb2_l_jump_lanes", "emotion", "")
	_expect_named(PlanLints.every_room_answers_problems(silent), "tb2_l_jump_lanes: the room does not say what feeling it is after", "a room that names no feeling: named")
	var lost_a_room := PlanEncounterTable.copy_of_rows()
	lost_a_room.erase(_row(lost_a_room, &"dh4_seal_stair"))
	_expect_named(PlanLints.every_room_answers_problems(lost_a_room), "the table lists the rooms", "a room of the plan with no row: named")

	var two_new_shapes := PlanEncounterTable.copy_of_rows()
	_row(two_new_shapes, &"tb1_toybox_gate")["live"] = [&"pawn_recruit", &"charging_pawn"]
	_expect_named(PlanLints.one_new_shape_problems(two_new_shapes, path), "tb1_toybox_gate: introduces 2 new shapes at once (charge_line, knight_landing)", "the Charging Pawn's line next to the fenced Knight in tb1: two new shapes in one room")
	_expect_named(PlanLints.teach_ladder_problems(two_new_shapes, path), "tb1_toybox_gate: a Teach room introduces at most one new verb or shape (R4) and this one introduces 2", "...and as a Teach room, R4 names it too")

	var live_before_fenced := PlanEncounterTable.copy_of_rows()
	_row(live_before_fenced, &"bs1_book_spine_steps")["live"] = [&"pawn_recruit", &"backstep_pawn", &"bishop_zoner"]
	_expect_named(PlanLints.teach_ladder_problems(live_before_fenced, path), "bs1_book_spine_steps: the new shape 'diagonal_lane' is live in a Teach room before it was shown fenced (R4)", "a live Bishop in the Teach room that was to show it fenced: named")

	var two_verbs := PlanEncounterTable.copy_of_rows()
	_row(two_verbs, &"t2_fallen_sword_tile")["verbs"] = [&"wooden_sword", &"pencil"]
	_expect_named(PlanLints.teach_ladder_problems(two_verbs, path), "t2_fallen_sword_tile: a Teach room introduces at most one new verb or shape (R4) and this one introduces 2", "two verbs in the first Teach room: named")

	var no_breaker := _with(PlanEncounterTable.copy_of_rows(), &"tb3_toy_track_ambush", "objective", &"clear")
	var no_breaker_problems := PlanLints.format_breaker_problems(no_breaker)
	_expect_named(no_breaker_problems, "toybox: no room of this district has an objective kind other than clear: no format-breaker", "the Toybox's train chase made a plain clear: the district has no format-breaker")
	_expect_named(no_breaker_problems, "tb3_toy_track_ambush: the plan names it the format-breaker of its district", "...and the room the plan names is named")

	var three_alike := _with(_with(PlanEncounterTable.copy_of_rows(), &"tb2_l_jump_lanes", "intensity", 3), &"tb3_toy_track_ambush", "intensity", 3)
	_expect_named(PlanLints.arc_problems(three_alike, path), "three rooms in a row share the intensity 3", "three rooms of intensity 3 in a row (tb1, tb2, tb3): R32 names it")
	var falling_boss := _with(PlanEncounterTable.copy_of_rows(), &"bsb_bishop_oracle", "intensity", 7)
	_expect_named(PlanLints.arc_problems(falling_boss, path), "the boss intensities fall from 8 to 7", "the Bishop Oracle softer than the Knight Captain: named")
	var two_boss_grade := _with(PlanEncounterTable.copy_of_rows(), &"tb4_lid_path", "intensity", 8)
	_expect_named(PlanLints.arc_problems(two_boss_grade, path), "two boss-grade rooms (8 or more) follow each other", "a shortcut of intensity 8 right after a boss of 8: named")

	var toybox_to_dollhouse := PlanLints.copy_of_graph(graph)
	var shortcut := WorldEdge.new()
	shortcut.from_room = &"tb2_l_jump_lanes"
	shortcut.door = &"Exit_To_DH2"
	shortcut.to_room = &"dh2_mixed_court"
	shortcut.to_entry = &"from_tb2"
	toybox_to_dollhouse.edges.append(shortcut)
	_expect(PlanLints.adjacency_problems(PlanLints.copy_of_graph(graph), scan_by_room).is_empty(), "control: a copy of the graph is clean")
	_expect_named(PlanLints.adjacency_problems(toybox_to_dollhouse, scan_by_room), "tb2_l_jump_lanes/Exit_To_DH2: the door joins the toybox to the dollhouse with no reason", "a door from the Toybox straight into the Dollhouse, past the hub: named")

	var every_clean := PlanLints.every_room_answers_problems(PlanEncounterTable.ROWS).is_empty() and PlanLints.one_new_shape_problems(PlanEncounterTable.ROWS, path).is_empty() and PlanLints.teach_ladder_problems(PlanEncounterTable.ROWS, path).is_empty() \
		and PlanLints.format_breaker_problems(PlanEncounterTable.ROWS).is_empty() and PlanLints.arc_problems(PlanEncounterTable.ROWS, path).is_empty() and PlanLints.adjacency_problems(graph, scan_by_room).is_empty()
	_expect(every_clean, "the breaks are gone: the real table and the real graph are judged clean again")


func _report_what_cannot_be_checked_yet(scan_by_room: Dictionary[StringName, RoomScan]) -> void:
	# Near groups: the rule is "at most two common enemies in the near group"; with no aggro groups the whole room is the group.
	var crowded: Array[String] = []
	for room_id: StringName in PlanLints.route_order(PlanRoomTable.CRITICAL_PATH):
		var scan: RoomScan = scan_by_room.get(room_id)
		if scan == null:
			continue
		var common_pieces := 0
		for definition in scan.enemy_definitions:
			common_pieces += 1 if definition.defeat_flag == &"" else 0
		if common_pieces > 2:
			crowded.append("%s %d" % [String(room_id).get_slice("_", 0), common_pieces])
	print("REPORT room_data_audit: near groups. No piece belongs to an aggro group yet, so the whole room is read as the near group and %d room(s) park more than two common enemies: %s (the plan's own t4 lists three together: its Backstep Pawn is the far one). Report-only until M8a gives an encounter its groups; then 'at most two common enemies in the near group' (req 88) becomes enforcing here." % [crowded.size(), ", ".join(PackedStringArray(crowded))])
	print("REPORT room_data_audit: boss shapes. The plan states no shape count for a boss (R28 caps one by act, 2/3/3/3/4/4), so the six boss rows carry shapes 0 and R28 is judged on the rooms that are not a boss's only. Report-only until the boss frameworks (M8b) give every phase its shapes; then each boss phase is held to its cap here.")
	_expect(crowded.size() >= 1, "(the report looked at the rooms: at least one parks three common enemies)")


# --------------------------------------------------------------------------- helpers
func _row(rows: Array[Dictionary], room_id: StringName) -> Dictionary:
	for row in rows:
		if row["id"] == room_id:
			return row
	return {}


func _with(rows: Array[Dictionary], room_id: StringName, key: String, value: Variant) -> Array[Dictionary]:
	_row(rows, room_id)[key] = value
	return rows


func _expect_named(problems: PackedStringArray, fragment: String, label: String) -> void:
	var named := false
	for sentence in problems:
		named = named or sentence.contains(fragment)
	_expect(named, "the lint can fail: %s (it said: %s)" % [label, "; ".join(problems).left(260)])
