extends UnboundTest

## The threat budget (docs/game-base-plan.md 5.3, R18, R28, M5 acceptance): Teach rooms carry 3 or less, Test and Twist rooms 3 to 6 (per wave in a
## gauntlet; a room flagged `intro` is exempt from the floor), the room before a boss carries 6 or less and less than the boss's phase-1 budget,
## and the shapes thrown at once stay under the cap of the act (2/2/2/2/3/4, bosses 2/3/3/3/4/4). The plan's 7.4 table "is the lint fixture of
## R4, R18 and R28 ... run against this table in M5, before any room is built", so the rules run over that table
## (tests/fixtures/plan_encounter_table.gd) with the threat points the enemy definitions carry (EnemyDefinition.threat_points, so a number tuned in a
## `.tres` is judged here), and the caps come from RoomEncounter (the same constants the Inspector's warnings use).
##
## Three parts: the table as the plan wrote it passes, with the numbers behind the pass stated in the open; the lint is shown able to fail (a COPY of
## the table is broken in nine ways, one at a time, and each is named; the real table is judged clean again at the end); and the shipped rooms:
## their meta is the plan's numbers (enforced, in test_room_data_audit), and the pieces they PARK are weighed against it here in report-only mode,
## because a stub parks live what the plan fences (tb1, bs1, bt1), a gauntlet's waves all at once (ub2) and no hazard at all.

const PlanLints := preload("res://tests/support/plan_lints.gd")
const PlanEncounterTable := preload("res://tests/fixtures/plan_encounter_table.gd")
const PlanRoomTable := preload("res://tests/fixtures/plan_room_table.gd")

## The boss of each arena and the phase-1 budget the plan gives it (5.3: B1 6, KB 7, BSB 7, BTB 8, Queen 8, King 9), read from the definitions.
const BOSS_BUDGETS := {
	&"black_pawn_captain": 6, &"knight_captain": 7, &"bishop_oracle": 7, &"rook_warden": 8, &"queen_of_tricks": 8, &"black_king": 9,
}


func _init() -> void:
	suite_title = "TEST THREAT BUDGET"
	_check_the_table()
	_check_the_lint_can_fail()
	_check_the_shipped_rooms()
	finish()


func _check_the_table() -> void:
	var problems := PlanLints.threat_budget_problems(PlanEncounterTable.ROWS, PlanRoomTable.CRITICAL_PATH)
	for sentence in problems:
		printerr("  %s" % sentence)
	_expect(problems.is_empty(), "the plan's table passes every budget rule: sums, shapes, Teach, Test and Twist, waves, the room before a boss")
	# The facts behind the pass, so a walk that judged nothing cannot pass.
	var by_recipe := {}
	for row in PlanEncounterTable.ROWS:
		var recipe := String(PlanRoomTable.row_of(row["id"])["recipe"])
		if not by_recipe.has(recipe):
			by_recipe[recipe] = []
		(by_recipe[recipe] as Array).append(row)
	var teach_threats: Array[int] = []
	for row: Dictionary in by_recipe["teach"]:
		teach_threats.append(int(row["threat"]))
	_expect(teach_threats == [0, 1, 3, 2], "the four Teach rooms (t2, tb1, bs1, bt1) carry %s threat: all 3 or less (R4)" % [teach_threats])
	var test_twist_threats: Array[int] = []
	for row: Dictionary in by_recipe["test"] + by_recipe["twist"]:
		test_twist_threats.append(int(row["threat"]))
	test_twist_threats.sort()
	_expect(test_twist_threats == [1, 4, 4, 5, 5, 5, 5, 5, 5, 6, 6, 6], "the twelve Test and Twist rooms carry %s: 3 to 6, but T3's 1 (the intro room, exempt from the floor)" % [test_twist_threats])
	var boss_budgets: Dictionary = {}
	for room_id: StringName in PlanRoomTable.BOSS_OF_ROOM:
		boss_budgets[PlanRoomTable.BOSS_OF_ROOM[room_id]] = PlanLints.threat_points_of(PlanRoomTable.BOSS_OF_ROOM[room_id])
	_expect(boss_budgets == BOSS_BUDGETS, "the six bosses' threat_points are their phase-1 budgets: %s" % [boss_budgets])
	var before_boss: Array[String] = []
	var path := PlanRoomTable.CRITICAL_PATH
	for index in range(1, path.size()):
		if PlanRoomTable.BOSS_OF_ROOM.has(path[index]):
			var before := PlanEncounterTable.row_of(path[index - 1])
			var boss := PlanEncounterTable.row_of(path[index])
			before_boss.append("%s %d < %d" % [String(path[index - 1]).get_slice("_", 0), before["threat"], boss["threat"]])
			_expect(int(before["threat"]) <= RoomEncounter.ROOM_BEFORE_BOSS_THREAT_LIMIT and int(before["threat"]) < int(boss["threat"]), "%s: the room before %s carries %d, at most %d and below the boss's %d (R18)" % [path[index - 1], path[index], before["threat"], RoomEncounter.ROOM_BEFORE_BOSS_THREAT_LIMIT, boss["threat"]])
	_expect(before_boss.size() == 6, "six rooms stand before a boss: %s" % ", ".join(PackedStringArray(before_boss)))
	var gauntlet := PlanEncounterTable.row_of(&"ub2_last_board")
	var wave_threats: Array[int] = []
	for wave: Array in gauntlet["waves"]:
		wave_threats.append(PlanEncounterTable.threat_of(wave, PlanLints.threat_points_of))
	_expect(wave_threats == [4, 6, 6] and int(gauntlet["threat"]) == 6, "the gauntlet's three waves weigh %s, each 6 or less (per wave, not summed), and the room's budget is the biggest wave" % [wave_threats])
	var rated_pieces := 0
	for row in PlanEncounterTable.ROWS:
		rated_pieces += PlanLints.every_live_piece(row).size()
	_expect(rated_pieces >= 40, "%d live pieces and hazards were weighed (at least 40, so an empty walk cannot pass)" % rated_pieces)


func _check_the_lint_can_fail() -> void:
	var control := PlanEncounterTable.copy_of_rows()
	_expect(PlanLints.threat_budget_problems(control, PlanRoomTable.CRITICAL_PATH).is_empty(), "control: the copy of the table is clean, so each break below is the only difference")

	var another_knight := PlanEncounterTable.copy_of_rows()
	_row(another_knight, &"tb2_l_jump_lanes")["live"] = [&"knight_tracker", &"charging_pawn", &"knight_tracker"]
	var knight_problems := PlanLints.threat_budget_problems(another_knight, PlanRoomTable.CRITICAL_PATH)
	_expect_named(knight_problems, "tb2_l_jump_lanes: its live pieces add up to 8 threat but the plan's table says 5", "a second Knight in tb2: the sum no longer matches the plan")
	_expect_named(PlanLints.threat_budget_problems(_with(another_knight, &"tb2_l_jump_lanes", "threat", 8), PlanRoomTable.CRITICAL_PATH), "A test room carries at most 6 threat (R18): threat_budget is 8", "...and once the number is 8 it is over the ceiling of a Test room (R18)")

	var heavy_teach := _with(PlanEncounterTable.copy_of_rows(), &"bs1_book_spine_steps", "threat", 5)
	_expect_named(PlanLints.threat_budget_problems(heavy_teach, PlanRoomTable.CRITICAL_PATH), "A Teach room carries at most 3 threat (R4): threat_budget is 5", "a Teach room of 5 threat: R4 names it")

	var intro_taken_away := _with(PlanEncounterTable.copy_of_rows(), &"t3_first_pawn_clash", "intro", false)
	_expect_named(PlanLints.threat_budget_problems(intro_taken_away, PlanRoomTable.CRITICAL_PATH), "t3_first_pawn_clash: A test room carries at least 3 threat (R18) unless it is flagged `intro`", "T3's intro flag taken away: its single Recruit is under the floor of a Test room")

	var too_many_shapes := _with(PlanEncounterTable.copy_of_rows(), &"dh2_mixed_court", "shapes", 4)
	_expect_named(PlanLints.threat_budget_problems(too_many_shapes, PlanRoomTable.CRITICAL_PATH), "act 5 allows 3 threat shapes at once in a normal room (R28): threat_shapes is 4", "four shapes at once in Act 5, where a normal room may throw three (R28)")

	var heavy_wave := PlanEncounterTable.copy_of_rows()
	_row(heavy_wave, &"ub2_last_board")["waves"] = [[&"knight_tracker", &"pawn_recruit"], [&"bishop_zoner", &"charging_pawn", &"pawn_recruit"], [&"wooden_rook", &"pawn_armed", &"knight_tracker"]]
	_expect_named(PlanLints.threat_budget_problems(heavy_wave, PlanRoomTable.CRITICAL_PATH), "ub2_last_board: wave 3: A test room carries at most 6 threat (R18): threat_budget is 9", "a third wave of 9 threat: the wave is named, the gauntlet is judged per wave")

	var heavy_room_before_the_boss := _with(PlanEncounterTable.copy_of_rows(), &"t4_broken_rule_yard", "threat", 7)
	_expect_named(PlanLints.threat_budget_problems(heavy_room_before_the_boss, PlanRoomTable.CRITICAL_PATH), "t4_broken_rule_yard: the room before the boss of b1_black_pawn_captain carries 7 threat, at most 6 allowed (R18)", "the room before the first boss at 7 threat: named")

	var weak_boss := _with(PlanEncounterTable.copy_of_rows(), &"b1_black_pawn_captain", "threat", 5)
	_expect_named(PlanLints.threat_budget_problems(weak_boss, PlanRoomTable.CRITICAL_PATH), "t4_broken_rule_yard: the room before the boss of b1_black_pawn_captain carries 5 threat, which is not below the boss's phase-1 budget of 5 (R18)", "a boss whose phase-1 budget is not above the room before it: named")

	var lost_a_pulse := PlanEncounterTable.copy_of_rows()
	_row(lost_a_pulse, &"ub3_rule_engine")["live"] = [&"pawn_recruit", &"tile_rewrite_pulse", &"tile_rewrite_pulse"]
	_expect_named(PlanLints.threat_budget_problems(lost_a_pulse, PlanRoomTable.CRITICAL_PATH), "ub3_rule_engine: its live pieces add up to 3 threat but the plan's table says 4", "a rewrite pulse taken out of ub3: the hazards are counted")

	var unrated := PlanEncounterTable.copy_of_rows()
	_row(unrated, &"t3_first_pawn_clash")["live"] = [&"ghost_pawn"]
	_expect_named(PlanLints.threat_budget_problems(unrated, PlanRoomTable.CRITICAL_PATH), "the piece 'ghost_pawn' has no threat_points", "a piece that is no enemy: named, not counted as zero")

	_expect(PlanLints.threat_budget_problems(PlanEncounterTable.ROWS, PlanRoomTable.CRITICAL_PATH).is_empty(), "the breaks are gone: the real table is judged clean again")


func _check_the_shipped_rooms() -> void:
	var graph := ContentDb.world()
	var scan_by_room := PlanLints.scans_of(graph)
	var matches: Array[String] = []
	var differs: Array[String] = []
	var rooms_with_meta_in_the_rules := 0
	for row in PlanEncounterTable.ROWS:
		var room_id: StringName = row["id"]
		var scan: RoomScan = scan_by_room.get(room_id)
		if not _expect(scan != null, "%s: the scene reads" % room_id):
			continue
		var scene_problems := RoomEncounter.threat_problems(PlanLints.recipe_of(room_id), scan.act, scan.threat_budget, scan.threat_shapes, scan.intro)
		_expect(scene_problems.is_empty(), "%s: the meta of the scene (threat %d, shapes %d%s) obeys the budget rules (%s)" % [room_id, scan.threat_budget, scan.threat_shapes, ", intro" if scan.intro else "", "; ".join(scene_problems)])
		rooms_with_meta_in_the_rules += 1
		var parked := PlanLints.parked_threat_of(scan)
		if parked == scan.threat_budget:
			matches.append(String(room_id).get_slice("_", 0))
		else:
			differs.append("%s parks %d against a designed %d" % [String(room_id).get_slice("_", 0), parked, scan.threat_budget])
	_expect(rooms_with_meta_in_the_rules == 34, "the budget rules were applied to the meta of all 34 scenes")
	print("REPORT threat_budget (scenes): the pieces the shipped rooms PARK weigh the room's designed budget in %d of 34 rooms (%s). The others: %s." % [matches.size(), ", ".join(PackedStringArray(matches)), "; ".join(PackedStringArray(differs))])
	print("REPORT threat_budget (scenes): report-only. A stub parks live what the plan fences (tb1, bs1, bt1), every piece of a gauntlet at once (ub2), a guard beside each boss and no hazard (the toy train of tb3 is M9's, the rewrite pulses of ub3 are M13's). It becomes enforcing when the fenced mode (M8a), the waves (M13) and the hazards exist, room by room as each stage lands.")
	_expect(matches.size() + differs.size() == 34 and matches.size() >= 10, "(the report weighed all 34 rooms, and at least ten already match their design)")


# --------------------------------------------------------------------------- helpers
func _row(rows: Array[Dictionary], room_id: StringName) -> Dictionary:
	for row in rows:
		if row["id"] == room_id:
			return row
	return {}


## `rows` with one key of one row set (the rows are the caller's copy).
func _with(rows: Array[Dictionary], room_id: StringName, key: String, value: Variant) -> Array[Dictionary]:
	_row(rows, room_id)[key] = value
	return rows


func _expect_named(problems: PackedStringArray, fragment: String, label: String) -> void:
	var named := false
	for sentence in problems:
		named = named or sentence.contains(fragment)
	_expect(named, "the lint can fail: %s (it said: %s)" % [label, "; ".join(problems).left(260)])
