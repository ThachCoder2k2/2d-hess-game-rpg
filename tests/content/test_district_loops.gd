extends UnboundTest

## The monotony guard's first rule (docs/game-base-plan.md D-02, 5.7, 7.1, M5 acceptance): every district has at least one loop or shortcut, so the
## pawn is never walking a corridor of rooms there and back. Read on the world graph (content/world/world.tres), the doors the pawn really walks:
## a room is on a LOOP when there is a way out and a different way back through at least three rooms (a door that opens both ways is a back-and-forth,
## not a loop; a one-way shortcut home closes one). Three parts:
##   1. the world as it is: the Chess Rug (through its hub), the Toybox, the Bookshelf, the Block Tower and the Dollhouse have a loop; the Under-Bed has
##      none, by the plan's own design, and is listed as an EXEMPTION with its reason (the Black King's door ends the run, 7.2, where every other
##      district's last door leads home), and so is the Desk, which is the Ending's one room. An exemption that outlives its reason fails the suite,
##      so the list cannot rot;
##   2. the lint is shown able to fail on a COPY of the graph: the Toybox's shortcut home taken away, the Under-Bed given a loop (its exemption turns
##      stale), and an exemption for a district no room belongs to;
##   3. the plan's shortcuts (5.7: "every district ends with a one-way shortcut home to H1", M9 to M13's `test_district_shortcuts`) are stated as facts
##      here, and the report says when the exemption is decided.

const PlanLints := preload("res://tests/support/plan_lints.gd")

## District -> why it has no loop or shortcut by design: the Under-Bed, whose boss's door leads out of the game (7.2: [ubb] --> e1 --> credits), and the
## Desk, which is one room, the Ending.
const EXEMPTIONS := {
	&"under_bed": "the descent: the Black King's door ends the run (plan 7.2) where every other district's last door leads home, and the lid closes behind the pawn (S22)",
	&"desk": "one room, the Ending: the run ends there (7.2), so there is no way out to make a loop of",
}
const DESK_ONLY := {&"desk": "one room, the Ending: the run ends there (7.2), so there is no way out to make a loop of"}


func _init() -> void:
	suite_title = "TEST DISTRICT LOOPS"
	var graph := ContentDb.world()
	var scan_by_room := PlanLints.scans_of(graph)
	var district_of := {}
	for room_id in scan_by_room:
		district_of[room_id] = scan_by_room[room_id].district
	_check_the_world(graph, district_of)
	_check_the_lint_can_fail(graph, district_of)
	_report(graph)
	finish()


func _check_the_world(graph: WorldGraph, district_of: Dictionary) -> void:
	var problems := PlanLints.district_loop_problems(graph, district_of, EXEMPTIONS)
	for sentence in problems:
		printerr("  %s" % sentence)
	_expect(problems.is_empty(), "every district of the world has a loop or shortcut, but the Under-Bed and the Desk, which are exempted with their reasons (D-02)")
	# The facts: which districts are on a loop, and which room proves it.
	var proof_by_district := {}
	for room_id: StringName in graph.room_ids():
		var district: StringName = district_of[room_id]
		if not proof_by_district.has(district) and PlanLints.is_on_a_loop(graph, room_id):
			proof_by_district[district] = room_id
	_expect(proof_by_district.keys().size() == 5 and not proof_by_district.has(&"under_bed") and not proof_by_district.has(&"desk"), "five districts stand on a loop (%s); the Under-Bed and the Desk do not" % ", ".join(PackedStringArray(proof_by_district.keys().map(func(district: StringName) -> String: return String(district)))))
	for district: StringName in [&"toybox", &"bookshelf", &"block_tower", &"dollhouse"]:
		_expect(proof_by_district.has(district), "%s: a room of it stands on a loop (%s)" % [district, proof_by_district.get(district)])
	_expect(proof_by_district.get(&"chess_rug") == &"h1_chess_rug_hub", "the Chess Rug's loop is its hub: every spoke is a way out of H1 and a way back (%s)" % proof_by_district.get(&"chess_rug"))
	# A back-and-forth is not a loop: a nook that opens onto one room only.
	_expect(not PlanLints.is_on_a_loop(graph, &"tbo_crayon_cache") and not PlanLints.is_on_a_loop(graph, &"t1_white_kings_fall") and not PlanLints.is_on_a_loop(graph, &"e1_morning_desk"), "a nook (tbo), the first room (t1) and the Ending (e1) are NOT on a loop: a door that opens both ways, or a way that leads nowhere, is no loop")
	_expect(PlanLints.is_on_a_loop(graph, &"tb4_lid_path") and PlanLints.is_on_a_loop(graph, &"tb2_l_jump_lanes") and PlanLints.is_on_a_loop(graph, &"h1_chess_rug_hub"), "...and the Toybox's shortcut room (tb4), its middle room (tb2) and the hub are: out through tb1, home through tb4")
	# The shortcuts the loops are made of.
	var shortcuts: Array[String] = []
	for edge in graph.edges:
		if edge.one_way and edge.to_room == &"h1_chess_rug_hub":
			shortcuts.append(String(edge.from_room).get_slice("_", 0))
	_expect(shortcuts == ["tb4", "bs4", "bt4", "dh4"], "the four districts that end in a shortcut have its one-way door home to H1 (%s): 5.7's rule, which test_district_shortcuts (M9 to M13) holds in full" % ", ".join(PackedStringArray(shortcuts)))


func _check_the_lint_can_fail(graph: WorldGraph, district_of: Dictionary) -> void:
	var control := PlanLints.copy_of_graph(graph)
	_expect(PlanLints.district_loop_problems(control, district_of, EXEMPTIONS).is_empty(), "control: a copy of the graph is clean, so each break below is the only difference")

	var no_shortcut := PlanLints.copy_of_graph(graph)
	no_shortcut.edges.erase(no_shortcut.find_edge(&"tb4_lid_path", &"Exit_To_H1"))
	_expect_named(PlanLints.district_loop_problems(no_shortcut, district_of, EXEMPTIONS), "toybox: no room of this district stands on a loop or a shortcut of the doors (D-02)", "the Toybox's shortcut home taken away: the district is a corridor, named")

	var two_ways_home := PlanLints.copy_of_graph(graph)
	two_ways_home.find_edge(&"tb4_lid_path", &"Exit_To_H1").one_way = false
	_expect(PlanLints.district_loop_problems(two_ways_home, district_of, EXEMPTIONS).is_empty(), "...while the shortcut being two-way changes nothing: the way home is still a second way, the loop stays")

	var looped_under_bed := PlanLints.copy_of_graph(graph)
	var back_to_the_gate := WorldEdge.new()
	back_to_the_gate.from_room = &"ub3_rule_engine"
	back_to_the_gate.door = &"Exit_To_UB1"
	back_to_the_gate.to_room = &"ub1_castle_gate"
	back_to_the_gate.to_entry = &"from_ub3"
	back_to_the_gate.one_way = true
	looped_under_bed.edges.append(back_to_the_gate)
	_expect_named(PlanLints.district_loop_problems(looped_under_bed, district_of, EXEMPTIONS), "under_bed: it has a loop now, so its exemption", "a one-way door from ub3 back to the gate gives the Under-Bed a loop: its exemption is stale and must go")
	_expect(PlanLints.district_loop_problems(looped_under_bed, district_of, DESK_ONLY).is_empty(), "...and without the exemption the looped Under-Bed passes")

	_expect_named(PlanLints.district_loop_problems(graph, district_of, {&"under_bed": "x", &"desk": "y", &"attic": "no such district"}), "attic: exempted from the loop rule but no room belongs to it", "an exemption for a district no room belongs to: named")
	_expect_named(PlanLints.district_loop_problems(graph, district_of, DESK_ONLY), "under_bed: no room of this district stands on a loop or a shortcut of the doors", "with no exemption the Under-Bed is a corridor, named")

	_expect(PlanLints.district_loop_problems(graph, district_of, EXEMPTIONS).is_empty(), "the breaks are gone: the real graph is judged clean again")


func _report(graph: WorldGraph) -> void:
	print("REPORT district_loops: the Under-Bed has no loop or shortcut and is EXEMPTED here, with its reason: %s. The Desk is one room: %s." % [EXEMPTIONS[&"under_bed"], EXEMPTIONS[&"desk"]])
	print("REPORT district_loops: it is report-only for the Under-Bed. It stops being an exemption, and the suite says so (a stale exemption fails), the day M13 gives Act 6 a loop (the memories wall of ub1 or the alcoves of ubb); if the owner keeps the descent one-way, the exemption stays and this is the place it is written down.")
	print("REPORT district_loops: %d doors judged on %d rooms; the plan's one-way shortcut of every district is held in full by test_district_shortcuts (requirement 114, M9 to M13)." % [graph.edges.size(), graph.rooms.size()])


func _expect_named(problems: PackedStringArray, fragment: String, label: String) -> void:
	var named := false
	for sentence in problems:
		named = named or sentence.contains(fragment)
	_expect(named, "the lint can fail: %s (it said: %s)" % [label, "; ".join(problems).left(260)])
