extends UnboundTest

## Every enemy is placed (docs/game-base-plan.md 5.3, 7.5 Placement, M5 acceptance): "a lint asserts that every enemy in this table is placed in at least one
## room, because pages and previews depend on it". Three parts:
##   1. the plan's table. The Placed in column of 5.3 (tests/fixtures/plan_encounter_table.gd, PLACED_IN) and the rows of 7.4 say the same thing: each
##      enemy is live in every room its column names (fenced in tb1, bs1 and bt1), and every live piece of a row is named by the column for that room;
##   2. the lint is shown able to fail (a COPY of the table is broken in five ways, one at a time, and each is named);
##   3. the shipped rooms. Every enemy of content/enemies/ is parked in at least one scene (enforced: nothing is placed nowhere), every boss room has
##      its stand-in guard (the column's `boss guards`), and the (enemy, room) pairs of the column are held in the scenes where the stubs hold
##      them. The pairs a stub does not hold are REPORT lines: ub2 is a gauntlet whose waves are M13's, and the summons of a boss are M8b's.

const PlanLints := preload("res://tests/support/plan_lints.gd")
const PlanEncounterTable := preload("res://tests/fixtures/plan_encounter_table.gd")
const PlanRoomTable := preload("res://tests/fixtures/plan_room_table.gd")


func _init() -> void:
	suite_title = "TEST ENEMY PLACEMENT"
	_check_the_table()
	_check_the_lint_can_fail()
	_check_the_shipped_rooms()
	finish()


func _check_the_table() -> void:
	var problems := PlanLints.placement_problems(PlanEncounterTable.ROWS)
	for sentence in problems:
		printerr("  %s" % sentence)
	_expect(problems.is_empty(), "the plan's table passes: the Placed in column of 5.3 and the rooms of 7.4 name the same enemies in the same rooms")
	var pairs := 0
	var fenced_pairs := 0
	for enemy_id: StringName in PlanEncounterTable.PLACED_IN:
		for code: StringName in PlanEncounterTable.PLACED_IN[enemy_id]:
			if code not in [&"boss_guards", &"boss_summons"]:
				pairs += 1
	for enemy_id: StringName in PlanEncounterTable.FENCED_PLACEMENTS:
		fenced_pairs += (PlanEncounterTable.FENCED_PLACEMENTS[enemy_id] as Array).size()
	_expect(PlanEncounterTable.PLACED_IN.size() == 10 and pairs == 34 and fenced_pairs == 3, "ten enemies, %d (enemy, room) pairs of which %d are fenced (tb1, bs1, bt1), were judged: the column of 5.3 as transcribed" % [pairs, fenced_pairs])
	var every_enemy_is_in_the_column := true
	var every_enemy_has_a_room := true
	for enemy_id: StringName in ContentDb.ids(&"enemies"):
		var definition := ContentDb.fetch(&"enemies", enemy_id) as EnemyDefinition
		var is_ordinary := definition.defeat_flag == &""
		every_enemy_is_in_the_column = every_enemy_is_in_the_column and (not is_ordinary or PlanEncounterTable.PLACED_IN.has(enemy_id))
		var placed := false
		for row in PlanEncounterTable.ROWS:
			placed = placed or enemy_id in PlanLints.every_live_piece(row)
		every_enemy_has_a_room = every_enemy_has_a_room and placed
	_expect(every_enemy_is_in_the_column, "every ordinary enemy of content/enemies/ (the eight of 5.3) is in the Placed in column")
	_expect(every_enemy_has_a_room, "...and every enemy of content/enemies/, the six bosses too, is live in at least one row of the table")


func _check_the_lint_can_fail() -> void:
	_expect(PlanLints.placement_problems(PlanEncounterTable.copy_of_rows()).is_empty(), "control: a copy of the table is clean, so each break below is the only difference")

	var without_armed := PlanEncounterTable.copy_of_rows()
	_row(without_armed, &"t4_broken_rule_yard")["live"] = [&"pawn_recruit", &"backstep_pawn"]
	_expect_named(PlanLints.placement_problems(without_armed), "pawn_armed: the plan places it in t4 (t4_broken_rule_yard) but that room's row does not hold it", "the Armed Pawn taken out of t4: the column's placement is not held")

	var stray_piece := PlanEncounterTable.copy_of_rows()
	_row(stray_piece, &"tb1_toybox_gate")["live"] = [&"pawn_recruit", &"pawn_armed"]
	_expect_named(PlanLints.placement_problems(stray_piece), "tb1_toybox_gate: the row holds 'pawn_armed' but the plan's Placed in column does not name this room for it", "an Armed Pawn placed in tb1: the column does not name that room")

	var without_iron_rook := PlanEncounterTable.copy_of_rows()
	_row(without_iron_rook, &"bt3_breakable_wall_test")["live"] = [&"wooden_rook", &"pawn_recruit"]
	_expect_named(PlanLints.placement_problems(without_iron_rook), "iron_rook: the plan places it in bt3 (bt3_breakable_wall_test) but that room's row does not hold it", "the Iron Rook taken out of bt3")
	_expect_named(PlanLints.placement_problems(without_iron_rook), "iron_rook: it is placed in no room at all", "...and it is then placed nowhere, which is named")

	var unfenced_knight := PlanEncounterTable.copy_of_rows()
	_row(unfenced_knight, &"tb1_toybox_gate")["fenced"] = []
	_expect_named(PlanLints.placement_problems(unfenced_knight), "knight_tracker: the plan places it in tb1 (tb1_toybox_gate) but that room's row does not hold it fenced", "the fenced Knight taken out of tb1: the fenced placement is named as fenced")

	var misspelt_room := PlanEncounterTable.copy_of_rows()
	_row(misspelt_room, &"dh2_mixed_court")["id"] = &"dh2x_mixed_court"
	_expect_named(PlanLints.placement_problems(misspelt_room), "knight_tracker: the plan places it in 'dh2', which is no room of the table", "a column that names a room the table does not have")

	_expect(PlanLints.placement_problems(PlanEncounterTable.ROWS).is_empty(), "the breaks are gone: the real table is judged clean again")


func _check_the_shipped_rooms() -> void:
	var graph := ContentDb.world()
	var scan_by_room := PlanLints.scans_of(graph)
	# Every enemy is parked in at least one scene.
	var unplaced := PlanLints.unplaced_enemy_ids(scan_by_room)
	_expect(unplaced.is_empty(), "every one of the %d enemies of content/enemies/ is parked in at least one shipped room (unplaced: %s)" % [ContentDb.ids(&"enemies").size(), ", ".join(PackedStringArray(unplaced))])
	_expect(ContentDb.ids(&"enemies").size() == 14, "the registry holds the 14 enemies of the plan: 8 ordinary pieces and 6 bosses")
	var without_bt3 := scan_by_room.duplicate()
	without_bt3.erase(&"bt3_breakable_wall_test")
	_expect(PlanLints.unplaced_enemy_ids(without_bt3) == [&"iron_rook"], "the scan can fail: with bt3 (the only room that parks the Iron Rook) taken out, the Iron Rook is reported unplaced (%s)" % [PlanLints.unplaced_enemy_ids(without_bt3)])

	# Boss guards: every boss room has its stand-in Recruit.
	var boss_rooms_without_a_guard: Array[String] = []
	var boss_rooms := 0
	for room_id: StringName in PlanRoomTable.BOSS_OF_ROOM:
		boss_rooms += 1
		if &"pawn_recruit" not in PlanLints.parked_enemy_ids(scan_by_room[room_id]):
			boss_rooms_without_a_guard.append(String(room_id))
	_expect(boss_rooms == 6 and boss_rooms_without_a_guard.is_empty(), "each of the six boss rooms parks its guard, a Recruit (the column's `boss guards`; without one: %s)" % ", ".join(PackedStringArray(boss_rooms_without_a_guard)))

	# The pairs of the column.
	var held := 0
	var not_held: Array[String] = []
	for enemy_id: StringName in PlanEncounterTable.PLACED_IN:
		for code: StringName in PlanEncounterTable.PLACED_IN[enemy_id]:
			if code in [&"boss_guards", &"boss_summons"]:
				continue
			var room_id := PlanLints.room_id_of_code(code)
			var scan: RoomScan = scan_by_room.get(room_id)
			if scan != null and enemy_id in PlanLints.parked_enemy_ids(scan):
				held += 1
			else:
				not_held.append("%s in %s" % [enemy_id, code])
	_expect(held + not_held.size() == 34, "all 34 (enemy, room) pairs of the column were looked up in the scenes (%d held, %d not)" % [held, not_held.size()])
	_expect(not_held == ["charging_pawn in ub2", "wooden_rook in ub2"], "every pair is held by the scenes but the two of the gauntlet ub2 (%s): when ub2 gets its waves this line goes, and the whole column is enforced" % [not_held])
	print("REPORT enemy_placement (scenes): %d of the 34 (enemy, room) pairs of the Placed in column stand in the shipped rooms; the stub does not park: %s. ub2 is a gauntlet whose waves are M13's (the stub parks a single wave's pieces), so its Charging Pawn and Rook wait there." % [held, "; ".join(PackedStringArray(not_held))])
	print("REPORT enemy_placement (scenes): the column's `boss summons` (the Armed Pawn a boss calls) are the boss frameworks' (M8b) and have no room to stand in. Report-only for those pairs until the waves (M13) and the boss summons (M8b) exist; the check for the rest is enforcing above.")


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
	_expect(named, "the lint can fail: %s (it said: %s)" % [label, "; ".join(problems).left(260)])
