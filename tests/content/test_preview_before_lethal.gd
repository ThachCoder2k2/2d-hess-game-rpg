extends UnboundTest

## R27, "preview before lethal" (docs/game-base-plan.md 3.5, 7.5, M5 acceptance): every enemy family is shown fenced (telegraph-only) on the
## critical path before a live piece of it can hurt. The graph audit runs over the plan's 7.4 table (tests/fixtures/plan_encounter_table.gd), which is
## what the plan says it is for: the rule is judged before a room has to be right. The rule itself is PlanLints.family_timeline().
##
## Three parts:
##   1. the table as the plan wrote it passes, and the facts behind the pass are stated in the open (which room introduces which family,
##      and where its first live piece stands), so a walk that looked at nothing cannot pass;
##   2. the lint is shown able to fail: six rooms of a COPY of the table are broken one at a time and each break is named (the real table
##      is never touched, and is judged clean again at the end);
##   3. the shipped scenes. Four families (pawn, knight, bishop, rook) enter the rooms where the plan introduces them, and that is enforced.
##      The fenced instance itself cannot be enforced: no piece has a telegraph-only mode yet, so a stub parks every piece LIVE, and the queen's
##      and the king's introductions (a fenced lane in dh3, a fenced pulse in ub3) are not pieces at all. Those are REPORT lines, below.

const PlanLints := preload("res://tests/support/plan_lints.gd")
const PlanEncounterTable := preload("res://tests/fixtures/plan_encounter_table.gd")
const PlanRoomTable := preload("res://tests/fixtures/plan_room_table.gd")


func _init() -> void:
	suite_title = "TEST PREVIEW BEFORE LETHAL"
	_check_the_table()
	_check_the_lint_can_fail()
	_check_the_scenes()
	finish()


func _check_the_table() -> void:
	var timeline := PlanLints.family_timeline(PlanEncounterTable.ROWS, PlanRoomTable.CRITICAL_PATH)
	for sentence: String in timeline["problems"]:
		printerr("  %s" % sentence)
	_expect((timeline["problems"] as PackedStringArray).is_empty(), "the plan's table passes: every family is introduced before its first live piece")
	var introduced_by: Dictionary = timeline["introduced_by"]
	var first_live: Dictionary = timeline["first_live"]
	_expect(introduced_by == {&"pawn": &"t3_first_pawn_clash", &"knight": &"tb1_toybox_gate", &"bishop": &"bs1_book_spine_steps", &"rook": &"bt1_block_yard", &"queen": &"dh3_royal_stage", &"king": &"ub3_rule_engine"},
		"the six families are introduced where the plan says: the pawn by T3's lone Recruit (intro), the knight in tb1, the bishop in bs1, the rook in bt1 (fenced), the queen's lane in dh3, the king's pulse in ub3 (%s)" % [introduced_by])
	_expect(first_live == {&"pawn": &"t3_first_pawn_clash", &"knight": &"tb2_l_jump_lanes", &"bishop": &"bs2_diagonal_chapel", &"rook": &"bt2_ruler_bridge", &"queen": &"dhb_queen_of_tricks", &"king": &"ubb_black_king"},
		"...and the first live piece of each stands later (tb2, bs2, bt2, the Queen's own arena, the King's own arena): %s" % [first_live])
	var route := PlanLints.route_order(PlanRoomTable.CRITICAL_PATH)
	var every_family_earlier := true
	for family: StringName in introduced_by:
		every_family_earlier = every_family_earlier and route.find(introduced_by[family]) <= route.find(first_live[family])
	_expect(every_family_earlier and route.size() == 31, "on the %d rooms of the critical path, no family is introduced after its first live piece" % route.size())


func _check_the_lint_can_fail() -> void:
	var rows := PlanEncounterTable.copy_of_rows()
	_expect(PlanLints.preview_problems(rows, PlanRoomTable.CRITICAL_PATH).is_empty(), "control: the copy of the table is clean, so each break below is the only difference")

	var without_knight_preview := PlanEncounterTable.copy_of_rows()
	_row(without_knight_preview, &"tb1_toybox_gate")["fenced"] = []
	_expect_named(PlanLints.preview_problems(without_knight_preview, PlanRoomTable.CRITICAL_PATH), "tb2_l_jump_lanes: a knight ('knight_tracker') is live here and no fenced preview of the knight family appears earlier", "the knight's fenced preview taken out of tb1: its first live piece in tb2 is named")

	var preview_in_the_same_room := PlanEncounterTable.copy_of_rows()
	_row(preview_in_the_same_room, &"bs1_book_spine_steps")["fenced"] = []
	_row(preview_in_the_same_room, &"bs2_diagonal_chapel")["fenced"] = [&"bishop"]
	_expect_named(PlanLints.preview_problems(preview_in_the_same_room, PlanRoomTable.CRITICAL_PATH), "bs2_diagonal_chapel: a bishop ('bishop_zoner') is live here and no fenced preview of the bishop family appears earlier", "the bishop's preview moved into the room where it is live: a preview must come EARLIER, so bs2 is named")

	var preview_after_the_rook := PlanEncounterTable.copy_of_rows()
	_row(preview_after_the_rook, &"bt1_block_yard")["fenced"] = []
	_row(preview_after_the_rook, &"bt3_breakable_wall_test")["fenced"] = [&"rook"]
	_expect_named(PlanLints.preview_problems(preview_after_the_rook, PlanRoomTable.CRITICAL_PATH), "bt2_ruler_bridge: a rook ('wooden_rook') is live here", "the rook's preview moved after the room where the Wooden Rook is live: bt2 is named")

	var without_queen_lane := PlanEncounterTable.copy_of_rows()
	_row(without_queen_lane, &"dh3_royal_stage")["fenced"] = []
	_expect_named(PlanLints.preview_problems(without_queen_lane, PlanRoomTable.CRITICAL_PATH), "dhb_queen_of_tricks: a queen ('queen_of_tricks') is live here and no fenced preview of the queen family appears earlier", "the Queen's fenced lane taken out of dh3: the Queen's arena is named")

	var without_intro := PlanEncounterTable.copy_of_rows()
	_row(without_intro, &"t3_first_pawn_clash")["intro"] = false
	_expect_named(PlanLints.preview_problems(without_intro, PlanRoomTable.CRITICAL_PATH), "t3_first_pawn_clash: a pawn ('pawn_recruit') is live here and no fenced preview of the pawn family appears earlier", "T3 without its intro flag: the first pawn has no preview and is named")

	var ghost_piece := PlanEncounterTable.copy_of_rows()
	_row(ghost_piece, &"tb2_l_jump_lanes")["live"] = [&"knight_tracker", &"ghost_pawn"]
	_expect_named(PlanLints.preview_problems(ghost_piece, PlanRoomTable.CRITICAL_PATH), "the piece 'ghost_pawn' is no enemy of content/enemies/", "a piece that is no enemy is named, not skipped")

	_expect(PlanLints.preview_problems(PlanEncounterTable.ROWS, PlanRoomTable.CRITICAL_PATH).is_empty(), "the breaks are gone: the real table is judged clean again (the copies were the only thing broken)")


func _check_the_scenes() -> void:
	var graph := ContentDb.world()
	var scan_by_room := PlanLints.scans_of(graph)
	_expect(scan_by_room.size() == 34, "all 34 rooms of the graph read (%d)" % scan_by_room.size())
	# The first room on the route that parks a piece of each family (every parked piece is live in a stub).
	var first_parked_by_family := {}
	for room_id in PlanLints.route_order(PlanRoomTable.CRITICAL_PATH):
		var scan: RoomScan = scan_by_room.get(room_id)
		if scan == null:
			continue
		for definition in scan.enemy_definitions:
			var family: StringName = definition.visual.piece_type
			if not first_parked_by_family.has(family):
				first_parked_by_family[family] = room_id
	var introduced_by: Dictionary = PlanLints.family_timeline(PlanEncounterTable.ROWS, PlanRoomTable.CRITICAL_PATH)["introduced_by"]
	for family: StringName in [&"pawn", &"knight", &"bishop", &"rook"]:
		_expect(first_parked_by_family.get(family) == introduced_by[family], "the shipped rooms bring in the %s family where the plan introduces it (%s)" % [family, introduced_by[family]])
	var not_yet_enforced: Array[String] = []
	for family: StringName in [&"queen", &"king"]:
		not_yet_enforced.append("%s: the plan introduces it in %s (a fenced %s), the first room that parks one is %s" % [family, introduced_by[family], "lane" if family == &"queen" else "pulse", first_parked_by_family.get(family)])
	var live_in_the_introducing_room := 0
	for family: StringName in [&"knight", &"bishop", &"rook"]:
		var room_id: StringName = introduced_by[family]
		var scan: RoomScan = scan_by_room[room_id]
		for definition in scan.enemy_definitions:
			if definition.visual.piece_type == family:
				live_in_the_introducing_room += 1
	print("REPORT preview_before_lethal (scenes): the fenced instance of a family cannot be checked in the shipped rooms yet. %d piece(s) stand LIVE in the rooms the plan fences them in (tb1, bs1, bt1), and the queen's and the king's previews are not pieces at all: %s." % [live_in_the_introducing_room, "; ".join(PackedStringArray(not_yet_enforced))])
	print("REPORT preview_before_lethal (scenes): report-only. It becomes enforcing when a piece has a telegraph-only mode and a room can mark a piece fenced (M8a, the attack stages), so the scene check can say 'the first LIVE instance of each family is preceded by a fenced one' the way the table check does today.")
	_expect(live_in_the_introducing_room >= 3, "(the report looked at the stand-ins: at least one live piece in each of tb1, bs1 and bt1)")


# --------------------------------------------------------------------------- helpers
func _row(rows: Array[Dictionary], room_id: StringName) -> Dictionary:
	for row in rows:
		if row["id"] == room_id:
			return row
	return {}


func _expect_named(problems: PackedStringArray, fragment: String, label: String) -> void:
	var named := false
	for sentence in problems:
		named = named or sentence.contains(fragment)
	_expect(named, "the lint can fail: %s (it said: %s)" % [label, "; ".join(problems).left(220)])
