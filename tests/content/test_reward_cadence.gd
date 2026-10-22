extends UnboundTest

## Micro-rewards (docs/game-base-plan.md 3.5 R37, 7.4, M5 acceptance): "at least one persistent reward (Page, shard, keepsake drawing, hub change,
## rescue or earned story beat) per 6 minutes of critical path", read "over the Reward column of 7.4". The rule runs on the plan's table
## (tests/fixtures/plan_encounter_table.gd: the Reward and Min columns): the critical path is a timeline, a room's rewards land when its minutes are
## over, the hub's first visit is its own 4 minutes and each return a pass-through minute (7.4 Totals: "plus 4 H1 pass-throughs"), and no stretch
## between two rewards may pass 6 minutes. Three parts:
##   1. the table's Min column adds up to the plan's own totals per act (22, 18.5, 21, 20, 18.5, 22 and the Ending's 8, plus 4 pass-throughs: 134 minutes,
##      "about 130-136"), which is what makes the timeline the plan's; then the cadence rule passes, with the longest stretch stated;
##   2. the lint is shown able to fail (a COPY of the table is broken five ways and each is named);
##   3. a reading of the table that the lint found: the plan's Reward column leaves two long boss fights with no reward before their end (the Queen's room,
##      6.5 minutes, and the Black King's, 9). Both fights have story beats INSIDE them in the plan's own text (S20, the Queen's address; S24, the three
##      memory alcoves), which are earned story beats, so the fixture lists them as `mid_rewards`. The plan's table should say so (findings.md).
## The Ending is not a stretch to be punctuated: its eight minutes ARE the reward (R30), so a room of recipe `ending` ends the timeline.
## The shipped rooms hold no rewards yet (beats and pickups are M6 to M13), so there is no scene half: a REPORT line says when it becomes one.

const PlanLints := preload("res://tests/support/plan_lints.gd")
const PlanEncounterTable := preload("res://tests/fixtures/plan_encounter_table.gd")
const PlanRoomTable := preload("res://tests/fixtures/plan_room_table.gd")


func _init() -> void:
	suite_title = "TEST REWARD CADENCE"
	_check_the_table_is_the_plans()
	_check_the_cadence()
	_check_the_lint_can_fail()
	_report()
	finish()


func _check_the_table_is_the_plans() -> void:
	var minutes := PlanLints.minutes_by_act(PlanEncounterTable.ROWS, PlanRoomTable.CRITICAL_PATH)
	var expected := PlanEncounterTable.ACT_MINUTES.duplicate()
	expected[&"hub_passes"] = 4.0
	_expect(minutes == expected, "the Min column adds up to the plan's totals per act, 22, 18.5, 21, 20, 18.5, 22 and the Ending's 8, plus 4 hub pass-throughs (%s)" % [minutes])
	var total := 0.0
	for key in minutes:
		total += float(minutes[key])
	_expect(total >= 130.0 and total <= 136.0, "...which is %.1f minutes of critical path: the plan's 'about 130-136'" % total)
	var rewards := 0
	for row in PlanEncounterTable.ROWS:
		rewards += (row["rewards"] as Array).size() + (row.get("mid_rewards", []) as Array).size()
	_expect(rewards >= 40, "%d persistent rewards stand in the table (at least 40, so an empty walk cannot pass)" % rewards)


func _check_the_cadence() -> void:
	var rows := PlanEncounterTable.ROWS
	var problems := PlanLints.reward_cadence_problems(rows, PlanRoomTable.CRITICAL_PATH)
	for sentence in problems:
		printerr("  %s" % sentence)
	_expect(problems.is_empty(), "the plan's table passes R37: no stretch of the critical path between two persistent rewards is longer than %.0f minutes" % PlanEncounterTable.REWARD_WINDOW_MINUTES)
	var timeline := PlanLints.reward_timeline(rows, PlanRoomTable.CRITICAL_PATH)
	_expect((timeline["events"] as Array).size() >= 35 and is_equal_approx(float(timeline["minutes"]), 126.0), "the timeline holds %d reward moments over %.0f minutes of fights and walks (the Ending's 8 more are the reward itself)" % [(timeline["events"] as Array).size(), timeline["minutes"]])
	var longest := PlanLints.longest_reward_gap(rows, PlanRoomTable.CRITICAL_PATH)
	_expect(is_equal_approx(longest, 6.0), "the longest stretch without a reward is exactly %.1f minutes: the plan keeps to its window with nothing to spare (b1, tbb, bsb, btb and ub2 all reach it)" % longest)
	for room_id: StringName in [&"dhb_queen_of_tricks", &"ubb_black_king"]:
		var row := PlanEncounterTable.row_of(room_id)
		_expect(not (row.get("mid_rewards", []) as Array).is_empty(), "%s: a fight longer than the window holds a reward of its own inside (%s)" % [room_id, String(PlanEncounterTable.row_of(room_id)["mid_rewards"][0][1])])


func _check_the_lint_can_fail() -> void:
	var path := PlanRoomTable.CRITICAL_PATH
	_expect(PlanLints.reward_cadence_problems(PlanEncounterTable.copy_of_rows(), path).is_empty(), "control: a copy of the table is clean, so each break below is the only difference")

	var no_drawing := PlanEncounterTable.copy_of_rows()
	_row(no_drawing, &"b1_black_pawn_captain")["rewards"] = []
	_expect_named(PlanLints.reward_cadence_problems(no_drawing, path), "10.0 minutes pass between t4_broken_rule_yard: ", "the first boss gives nothing: ten minutes between the Pencil and Pebble")

	var long_boss := PlanEncounterTable.copy_of_rows()
	_row(long_boss, &"bsb_bishop_oracle")["minutes"] = 8.0
	_expect_named(PlanLints.reward_cadence_problems(long_boss, path), "8.0 minutes pass between bs3_torn_page_bridge: Slant and bsb_bishop_oracle: Chalk Path", "a Bishop fight of 8 minutes: eight minutes between the rescue and the unlock")

	var no_alcove_beats := PlanEncounterTable.copy_of_rows()
	_row(no_alcove_beats, &"ubb_black_king")["mid_rewards"] = []
	_expect_named(PlanLints.reward_cadence_problems(no_alcove_beats, path), "9.0 minutes pass between ub3_rule_engine: Rule Engine margin note and ubb_black_king: Free Step", "the Black King's memory alcoves taken out: nine minutes in one fight, which is why the fixture lists them")

	var unknown_kind := PlanEncounterTable.copy_of_rows()
	_row(unknown_kind, &"tb1_toybox_gate")["rewards"] = [[&"margin", "Margin +1"]]
	var kind_problems := PlanLints.reward_cadence_problems(unknown_kind, path)
	_expect_named(kind_problems, "tb1_toybox_gate: the reward 'Margin +1' is of the kind 'margin', which R37 does not count", "a reward of a kind R37 does not list: named")

	var nothing_at_all := PlanEncounterTable.copy_of_rows()
	for row in nothing_at_all:
		row["rewards"] = []
		row["mid_rewards"] = []
	_expect_named(PlanLints.reward_cadence_problems(nothing_at_all, path), "minutes pass between", "a table with no reward anywhere is named, not passed as empty")

	_expect(PlanLints.reward_cadence_problems(PlanEncounterTable.ROWS, path).is_empty(), "the breaks are gone: the real table is judged clean again")


func _report() -> void:
	var optional_rewards: Array[String] = []
	for row in PlanEncounterTable.ROWS:
		if PlanRoomTable.row_of(row["id"])["recipe"] == "optional":
			for reward: Array in row["rewards"]:
				optional_rewards.append("%s %s" % [String(row["id"]).get_slice("_", 0), reward[1]])
	print("REPORT reward_cadence: judged on the plan's table (the Reward and Min columns of 7.4), which is where the plan says R37 runs. The shipped rooms hold none of these rewards yet: the Pages, keepsake drawings, rescues and story beats are M6 to M13's content and the hub changes are M6's and M9 to M13's. The three optional nooks (%s) are off the critical path and not counted." % ", ".join(PackedStringArray(optional_rewards)))
	print("REPORT reward_cadence: it becomes a check on the rooms (a pickup, a Page, a beat flagged persistent in each room) as each of those lands, and the route bot's measured minutes (docs/route_times.md) replace the plan's Min column then (D-03, M9).")


func _row(rows: Array[Dictionary], room_id: StringName) -> Dictionary:
	for row in rows:
		if row["id"] == room_id:
			return row
	return {}


func _expect_named(problems: PackedStringArray, fragment: String, label: String) -> void:
	var named := false
	for sentence in problems:
		named = named or sentence.contains(fragment)
	_expect(named, "the lint can fail: %s (it said: %s)" % [label, "; ".join(problems).left(260)])
