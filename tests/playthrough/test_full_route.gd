extends UnboundTest

## The whole game, start to end (docs/game-base-plan.md 1.1 D1 and D21, 15 M5, G4; requirements 115, 124, 190, 228 and 229): a bot boots the project's main scene, presses New
## Game on the title, walks every room of the critical path in the order of the plan's route (T1 to B1, the hub, then the five districts with the hub between them,
## then the Desk), clears each room (the pieces by the sword, a boss by a damage event, which M5 allows), goes through each door the clear or the boss's fall opened,
## walks onto the Desk's last door, lets the ending cards play and the credits roll, and stops on the title, in under 90 seconds of real time. Nothing is teleported,
## no trip is asked for by name, and the save is a throwaway folder. The bot is tests/playthrough/route_bot.gd.
##
## It asserts what only a whole walk can show: the rooms were met in the plan's order; each ordinary piece fell to the sword and each of the six bosses set its flag,
## which opened the hub's door to the next district (D-21); the six boss falls are six autosaves; the run reached the ending, wrote the completed mark and came
## back to the title which shows it. Before it leaves a room it also steps onto every door the route has not earned yet and requires it to stay shut and say its
## line. And it writes the slow bot's clear time of every room to docs/route_times.md (D-03: a baseline, not a minimum, since a player beats the bot in most rooms;
## the plan's M9 measures the true minima). The file is rewritten only when its text changed, so a run that changed nothing leaves the working tree as it was; the same visits always
## give the same text (the clock is the game's own, advanced by hand), which the report's own checks hold.

const Support := preload("res://tests/bridge/bridge_support.gd")
const ShellSupport := preload("res://tests/shell/shell_support.gd")
const RouteBot := preload("res://tests/playthrough/route_bot.gd")
const SaveServiceScript := preload("res://shell/save/save_service.gd")
const PlanRoomTable := preload("res://tests/fixtures/plan_room_table.gd")
const PlanEncounterTable := preload("res://tests/fixtures/plan_encounter_table.gd")

const SUITE_NAME := "full_route"
## The plan's budget for the whole walk (15 M5 acceptance), in seconds of real time. The suite's watchdog is a little above it, so that a walk over the
## budget is told as a budget broken and a walk that hangs is told by the watchdog.
const ROUTE_BUDGET_SECONDS := 90.0
const WATCHDOG_SECONDS := 100.0
const ROUTE_TIMES_PATH := "res://docs/route_times.md"


func _init() -> void:
	suite_title = "FULL ROUTE TEST"
	watchdog_seconds = WATCHDOG_SECONDS
	call_deferred("_run")


func _run() -> void:
	_check_the_report_text()
	var started_msec := Time.get_ticks_msec()
	var bot := RouteBot.new(self, SUITE_NAME)
	var save_service := bot.save_service
	var route := PlanRoomTable.CRITICAL_PATH

	_expect(await bot.begin_new_game(), "boot -> title -> New Game: the game scene is on screen, in T1, and the run has begun")
	if bot.game == null:
		Support.end_suite(self, save_service)
		return
	_expect(bot.game.get("current_zone_id") == route[0] and bot.app.game_flow.state == GameFlow.State.PLAYING, "the first room is %s and the flow is PLAYING" % route[0])

	var walked := await bot.walk_the_route(route)
	for sentence in bot.problems:
		printerr("  %s" % sentence)
	_expect(walked, "the bot walks all %d steps of the critical path, each room cleared and left by the door to the next" % route.size())
	if not walked:
		Support.end_suite(self, save_service)
		return
	var rooms_walked: Array[StringName] = []
	for visit in bot.visits:
		rooms_walked.append(visit["room"])
	_expect(rooms_walked == route.slice(0, route.size() - 1), "the rooms were met in the order of the plan's route (7.2): t1 to b1, the hub, tb1 to tb4, the hub, bs1 to bs4, the hub, bt1 to bt4, the hub, dh1 to dh4, the hub, ub1 to ubb (%d visits before the Desk)" % rooms_walked.size())
	_check_the_pieces_and_the_bosses(bot, save_service)
	_check_the_shut_doors(bot)

	bot.flags_at_the_end = Support.ecs_of(bot.game).flags.to_dictionary()
	var ended := await bot.play_the_ending()
	for sentence in bot.problems:
		printerr("  %s" % sentence)
	_expect(ended, "the Desk's door ends the run: the ending cards, the credits, and the title")
	_check_the_ending(bot, save_service)

	var elapsed_seconds := float(Time.get_ticks_msec() - started_msec) / 1000.0
	_expect(elapsed_seconds < ROUTE_BUDGET_SECONDS, "boot to credits took %.1f s of real time, under the plan's %.0f s" % [elapsed_seconds, ROUTE_BUDGET_SECONDS])
	_check_the_measurements(bot)
	Support.end_suite(self, save_service)


## The hub's doors the route has not earned (M5 review: a hub door that lost its flag lock kept this suite green, only test_world_graph noticed). Before it left
## the hub each time, the bot stepped onto every district door whose district the route had not reached yet, and none took it anywhere and each said its own line:
## four doors after the first boss, then three, two and one (ten probes), and each of the five district doors was probed at least once.
func _check_the_shut_doors(bot: RouteBot) -> void:
	var probes := bot.shut_door_probes
	_expect(probes.size() == 10, "the bot tried ten doors the route had not earned yet: 4 + 3 + 2 + 1 of the hub's district doors (%d)" % probes.size())
	var every_probe_says_its_line := true
	var doors_probed: Array[StringName] = []
	var lines_heard: Array[String] = []
	for probe in probes:
		every_probe_says_its_line = every_probe_says_its_line and not String(probe["expected"]).is_empty() and probe["line"] == probe["expected"] and probe["room"] == &"h1_chess_rug_hub"
		if probe["door_to"] not in doors_probed:
			doors_probed.append(probe["door_to"])
		if probe["line"] not in lines_heard:
			lines_heard.append(probe["line"])
	_expect(every_probe_says_its_line, "every shut door stayed shut and said its own line, a real sentence, never the generic one")
	_expect(doors_probed.size() == 4, "the doors probed are the four districts after the Toybox (%d): %s" % [doors_probed.size(), doors_probed])
	_expect(lines_heard.size() == 4, "each of the four doors has a line of its own (%d different lines were heard)" % lines_heard.size())


## The room-by-room facts of the walk: every piece fell, every boss set its flag and was saved.
func _check_the_pieces_and_the_bosses(bot: RouteBot, save_service: Node) -> void:
	var run := Support.run_of(save_service)
	var graph := ContentDb.world()
	var pieces_expected := 0
	var pieces_felled := 0
	var bosses_expected := 0
	var bosses_felled := 0
	var rooms_with_pieces: Array[StringName] = []
	var every_room_has_its_count := true
	for visit in bot.visits:
		var scan := RoomScan.of(graph.get_zone_scene(visit["room"]))
		var ordinary := 0
		var bosses := 0
		for definition in scan.enemy_definitions:
			if definition.defeat_flag != &"":
				bosses += 1
			else:
				ordinary += 1
		# The pieces of a room are felled on the first visit; a later visit finds the room cleared and empty (D-17).
		if int(visit["visit"]) == 1:
			pieces_expected += ordinary
			bosses_expected += bosses
			every_room_has_its_count = every_room_has_its_count and int(visit["pieces_by_sword"]) == ordinary and int(visit["bosses_by_event"]) == bosses
			if ordinary + bosses > 0:
				rooms_with_pieces.append(visit["room"])
		pieces_felled += int(visit["pieces_by_sword"])
		bosses_felled += int(visit["bosses_by_event"])
	_expect(every_room_has_its_count, "in every room the bot felled what the scene parks: each ordinary piece by the sword, each boss by a damage event")
	_expect(pieces_expected >= 20 and pieces_felled == pieces_expected, "%d ordinary pieces fell to the sword, on foot, all the pieces of the route's rooms (%d expected)" % [pieces_felled, pieces_expected])
	_expect(bosses_expected == 6 and bosses_felled == 6, "six bosses fell by a damage event, one in each arena (%d)" % bosses_felled)
	_expect(rooms_with_pieces.size() == 21, "%d rooms of the route hold pieces: every Test, Twist, Teach-with-pieces and boss room, and each was cleared" % rooms_with_pieces.size())
	var every_room_cleared := true
	for room_id in rooms_with_pieces:
		every_room_cleared = every_room_cleared and run.cleared_room_ids.has(String(room_id))
	_expect(every_room_cleared, "the run remembers every one of those rooms as cleared (D-17)")
	var bosses_in_the_flags := true
	var bosses_in_the_run := true
	for boss_id: StringName in PlanRoomTable.BOSS_OF_ROOM.values():
		bosses_in_the_flags = bosses_in_the_flags and Support.ecs_of(bot.game).flags.get_flag(StringName("boss.%s" % boss_id), false) == true
		bosses_in_the_run = bosses_in_the_run and run.defeated_boss_ids.has(String(boss_id))
	_expect(bosses_in_the_flags and bosses_in_the_run, "the six flags boss.<id> are set in the world the pawn carries, and the run remembers the six bosses for good")
	var boss_saves := bot.autosave_reasons.count(&"boss_defeated")
	_expect(boss_saves == 6, "the six falls are six autosaves with the reason boss_defeated (%d); the rest of the saves are success events too: %s" % [boss_saves, _reasons_text(bot.autosave_reasons)])
	var only_success_events := true
	for reason in bot.autosave_reasons:
		only_success_events = only_success_events and reason in SaveServiceScript.AUTOSAVE_REASONS
	_expect(only_success_events and bot.autosave_reasons.size() >= 20, "%d autosaves in all, each for a success event (R17): a trip between rooms writes nothing" % bot.autosave_reasons.size())
	_expect(Support.player_combat(bot.game).sword_unlocked and run.has_unlock(&"wooden_sword"), "the sword taken in T2 is still in the hand at the Desk, and in the run")


func _check_the_ending(bot: RouteBot, save_service: Node) -> void:
	_expect(bot.reached_ending_state, "stepping onto the Desk's door put the flow in ENDING")
	_expect(bot.cards_seen == range(ContentDb.ending().cards.size()) and ContentDb.ending().cards.size() >= 3, "every ending card was shown, in order (%s)" % [bot.cards_seen])
	_expect(bot.reached_credits_state, "after the last card the flow went on to the credits")
	_expect(bot.finished_on_title, "the credits ended on the title screen")
	_expect(save_service.call("is_completed"), "the run is marked completed")
	var title := ShellSupport.title_of(bot.app)
	_expect(title != null and not title.emptied_square.visible, "the title shows the completed board: one square is empty")


## The measurements: one clear time for each of the 31 rooms of the route, set against the plan's estimate, and the file that records them.
func _check_the_measurements(bot: RouteBot) -> void:
	var route := PlanRoomTable.CRITICAL_PATH
	var unique_rooms: Array[StringName] = []
	for room_id in route:
		if room_id not in unique_rooms:
			unique_rooms.append(room_id)
	_expect(unique_rooms.size() == 31 and bot.visits.size() == route.size(), "%d rooms measured in %d visits (the hub five times)" % [unique_rooms.size(), bot.visits.size()])
	var every_room_has_a_time := true
	var no_estimate_is_beaten_by_a_minimum_that_is_longer := true
	for room_id in unique_rooms:
		var shortest := bot.minimum_seconds_of(room_id)
		every_room_has_a_time = every_room_has_a_time and shortest > 0.0
		no_estimate_is_beaten_by_a_minimum_that_is_longer = no_estimate_is_beaten_by_a_minimum_that_is_longer and shortest / 60.0 <= float(PlanEncounterTable.row_of(room_id)["minutes"])
	_expect(every_room_has_a_time, "every room took game time to clear (a room with no time was not walked)")
	_expect(no_estimate_is_beaten_by_a_minimum_that_is_longer, "no room's bot time is longer than the plan's first-play estimate: the baseline stays under the estimate")
	_expect(bot.total_seconds() > 60.0 and bot.total_seconds() / 60.0 < 134.0, "the whole walk took %.1f game seconds, far under the plan's 134 minutes: the skeleton is short (stub rooms, no fights), and the file says so" % bot.total_seconds())

	var text := RouteBot.report_text(bot.visits, route)
	var existing := FileAccess.get_file_as_string(ROUTE_TIMES_PATH) if FileAccess.file_exists(ROUTE_TIMES_PATH) else ""
	if existing == text:
		print("REPORT route_times: docs/route_times.md already holds this measurement (%d rooms, %.2f game seconds): nothing rewritten." % [unique_rooms.size(), bot.total_seconds()])
		_expect(true, "docs/route_times.md holds the measurement of this run")
		return
	var file := FileAccess.open(ROUTE_TIMES_PATH, FileAccess.WRITE)
	if file == null:
		print("REPORT route_times: docs/route_times.md could not be written (error %d); the measurement of this run is not recorded." % FileAccess.get_open_error())
		_expect(true, "(the file could not be written here: a read-only checkout is no failure of the route)")
		return
	file.store_string(text)
	file.close()
	print("REPORT route_times: docs/route_times.md was REWRITTEN with this measurement (%d rooms, %.2f game seconds): the old text differed. Commit the new file." % [unique_rooms.size(), bot.total_seconds()])
	_expect(FileAccess.get_file_as_string(ROUTE_TIMES_PATH) == text, "docs/route_times.md was written with the measurement of this run")


## The report text is a pure function of the visits: the same visits give the same text, a longer room gives a different one, the hub shows its shortest visit.
func _check_the_report_text() -> void:
	var route: Array[StringName] = [&"t1_white_kings_fall", &"t2_fallen_sword_tile", &"h1_chess_rug_hub", &"tb1_toybox_gate", &"h1_chess_rug_hub"]
	var visits: Array[Dictionary] = [
		{"room": &"t1_white_kings_fall", "visit": 1, "seconds": 2.5, "pieces_by_sword": 0, "bosses_by_event": 0},
		{"room": &"t2_fallen_sword_tile", "visit": 1, "seconds": 3.0, "pieces_by_sword": 0, "bosses_by_event": 0},
		{"room": &"h1_chess_rug_hub", "visit": 1, "seconds": 2.0, "pieces_by_sword": 0, "bosses_by_event": 0},
		{"room": &"tb1_toybox_gate", "visit": 1, "seconds": 4.0, "pieces_by_sword": 2, "bosses_by_event": 0},
		{"room": &"h1_chess_rug_hub", "visit": 2, "seconds": 1.5, "pieces_by_sword": 0, "bosses_by_event": 0},
	]
	var text := RouteBot.report_text(visits, route)
	_expect(text == RouteBot.report_text(visits, route), "the report text is the same for the same visits")
	_expect(text.contains("| `h1_chess_rug_hub` | rest | 2 | 0 | 0 | 1.50 s | 4.0 min |"), "the hub, visited twice, shows its shortest visit (1.50 s) against the plan's 4 minutes")
	_expect(text.contains("| `tb1_toybox_gate` | teach | 1 | 2 | 0 | 4.00 s | 3.0 min |"), "a room shows its pieces felled by the sword and its plan estimate")
	_expect(text.contains("| **the whole route** | **13.00 s** |"), "the whole route is the sum of every visit (13.00 s)")
	_expect(text.contains("| the hub's returns (4) | 1.50 s |"), "the hub's returns are summed apart from the first visits")
	var longer := visits.duplicate(true)
	longer[1]["seconds"] = 3.05
	_expect(RouteBot.report_text(longer, route) != text, "a room that got longer by a twentieth of a second changes the text: a change in the game is a change in the file")
	_expect(not text.contains("tbo_crayon_cache") and text.contains("optional nooks"), "the optional nooks are not in the table, and the text says why")


## A reasons list as one sentence (reason: count, ...).
func _reasons_text(reasons: Array[StringName]) -> String:
	var counts := {}
	for reason in reasons:
		counts[reason] = int(counts.get(reason, 0)) + 1
	var parts := PackedStringArray()
	for reason: StringName in counts:
		parts.append("%s %d" % [reason, counts[reason]])
	return ", ".join(parts)

