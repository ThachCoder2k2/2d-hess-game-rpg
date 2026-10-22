extends RefCounted

## The route bot (docs/game-base-plan.md 15 M5, D-03): plays the game from the title to the title again, the way the tests of M3b and M4 already play a
## room, and measures the shortest clear of every room it passes. NOT a test (the runner only collects test_*.gd) and without a class_name: tests load it with
##   const RouteBot := preload("res://tests/playthrough/route_bot.gd")
## tests/playthrough/test_full_route.gd is its one user; the plan's M9 reuses it with real fights to replace the plan's minutes (D-03).
##
## What it does, with nothing teleported and no trip asked for by name:
##   - boots AppRoot, the project's main scene, presses New Game on the title, and holds the game scene still so that the bot drives the simulation by hand
##     (Support.pump: a step is 0.05 s of game time), which makes every number below the same on every machine and every run;
##   - in each room of the route: turns the enemies' AI off (the pieces stand still: this is a FLOOR of the time, which no player reaches), walks onto whatever
##     the room gives for the stepping (T2's sword), brings every ordinary piece down with the sword by key presses (Support.kill_with_sword: walk beside it, face
##     it, strike until it falls) and brings a boss down by a damage event, which the plan allows until the boss fights exist (M8b);
##   - walks to the door that leads to the next room of the route by key presses (Support.walk_through_door) and steps onto it;
##   - at the Desk walks to the door that ends the run, lets the ending cards play, lets the credits end, and stops on the title.
## What a room's number is: game seconds from the arrival (the room has booted) to the step onto the door that leads on, read off the run's own play-time
## clock (SaveService.state.play_time_seconds, which the game scene advances by the delta of every simulated step). The walk of the next trip (the fades) costs none.
##
## It never judges: it records `visits` and `problems` (a sentence for each thing that went wrong, at which room), and the test judges them.

const Support := preload("res://tests/bridge/bridge_support.gd")
const ShellSupport := preload("res://tests/shell/shell_support.gd")
const PlanEncounterTable := preload("res://tests/fixtures/plan_encounter_table.gd")
const PlanRoomTable := preload("res://tests/fixtures/plan_room_table.gd")

## The fade the bot uses after the boot, in seconds of real time.
const FADE_SECONDS := 0.04
## How long the bot lets the damage event of a boss's fall run through the simulation, in game seconds.
const BOSS_FALL_SECONDS := 0.1
## The ending cards are advanced in steps of this many seconds until the screen says it is done.
const ENDING_STEP_SECONDS := 0.5
const NO_CELL := Vector2i(-999, -999)

## One entry per room the bot passed through, in the order it walked: {"room": StringName, "visit": int (1 for the first time the bot was in this room), "seconds": float,
## "pieces_by_sword": int, "bosses_by_event": int}.
var visits: Array[Dictionary] = []
## One sentence for each thing that went wrong, in the order it happened. Empty = the whole walk went through.
var problems := PackedStringArray()
## The success events the run saved on (SaveService.autosaved), in order.
var autosave_reasons: Array[StringName] = []
## The cards of the ending the bot saw, by index; the screen and flow states it met after the door that ends the run.
var cards_seen: Array[int] = []
var reached_ending_state := false
var reached_credits_state := false
var finished_on_title := false
## The flags of the world the bot left the last room with, and the zone it stood in when it asked for the end.
var flags_at_the_end: Dictionary = {}

var suite: UnboundTest
var save_service: Node
var app: AppRoot
var game: GameRoot

## The visit of the last room of the route, begun by walk_the_route() and finished by play_the_ending() (the Desk is left by the door that ends the run).
var _pending_visit: Dictionary = {}
var _pending_arrival_seconds := 0.0


## The bot isolates the save itself, before anything boots (Support.install_isolated_save_service: a throwaway folder named after `suite_name`), so it can never
## read or write the player's own run; `save_service` is that service, and the suite ends with Support.end_suite(suite, bot.save_service).
func _init(suite_of_the_bot: UnboundTest, suite_name: String) -> void:
	suite = suite_of_the_bot
	save_service = Support.install_isolated_save_service(suite, suite_name)
	save_service.connect("autosaved", func(_slot: int, reason: StringName) -> void: autosave_reasons.append(reason))


# --------------------------------------------------------------------------- the walk
## Boots the app and presses New Game. True when the game scene is on screen and held still.
func begin_new_game() -> bool:
	app = await ShellSupport.boot_app(suite)
	app.transition.default_fade_seconds = FADE_SECONDS
	var title := ShellSupport.title_of(app)
	if title == null:
		problems.append("the app did not open on the title screen")
		return false
	title.new_game_button.pressed.emit()
	await app.until_settled()
	game = ShellSupport.game_of(app)
	if game == null:
		problems.append("New Game did not start the game scene")
		return false
	ShellSupport.hold_the_game_still(app)
	return true


## Walks the whole route: `route` is the rooms in the order they are met (the hub more than once); the last room is left by the door that ends the run,
## which is `play_the_ending()`'s. True when every room was cleared and left by the door to the next.
func walk_the_route(route: Array[StringName]) -> bool:
	var times_in_room := {}
	for index in route.size():
		var room_id := route[index]
		if StringName(game.get("current_zone_id")) != room_id:
			problems.append("%s: the pawn should be here and stands in %s" % [room_id, game.get("current_zone_id")])
			return false
		times_in_room[room_id] = int(times_in_room.get(room_id, 0)) + 1
		var arrived_at := _seconds_played()
		var visit := {"room": room_id, "visit": times_in_room[room_id], "seconds": 0.0, "pieces_by_sword": 0, "bosses_by_event": 0}
		if not await _clear_the_room(room_id, visit):
			return false
		if index == route.size() - 1:
			_pending_visit = visit
			_pending_arrival_seconds = arrived_at
			return true
		var next_room := route[index + 1]
		if not await Support.walk_through_door(suite, game, next_room):
			problems.append("%s: the pawn could not walk to the door that leads to %s and through it" % [room_id, next_room])
			return false
		visit["seconds"] = _seconds_played() - arrived_at
		visits.append(visit)
	return true


## At the Desk: walks to the door that ends the run, lets the cards play and the credits end. True when the run ended on the title.
func play_the_ending() -> bool:
	var room_id := StringName(game.get("current_zone_id"))
	if _pending_visit.is_empty():
		problems.append("%s: the route did not end in a room that waits for the ending" % room_id)
		return false
	var door := Support.exit_cell(game, game.get("current_room"), &"")
	if door == NO_CELL:
		problems.append("%s: no door that ends the run" % room_id)
		return false
	if not await Support.walk_to_cell(suite, game, door):
		problems.append("%s: the pawn could not walk to the door that ends the run" % room_id)
		return false
	_pending_visit["seconds"] = _seconds_played() - _pending_arrival_seconds
	visits.append(_pending_visit)
	var flow := app.game_flow
	reached_ending_state = flow.state == GameFlow.State.ENDING
	if not reached_ending_state:
		problems.append("%s: the door that ends the run did not start the ending (the flow is %s)" % [room_id, flow.state])
		return false
	await app.until_settled()
	var ending_screen := app.screen as EndingScreen
	if ending_screen == null:
		problems.append("the ending cards did not come on screen")
		return false
	var guard := 0
	while not ending_screen.is_finished() and guard < 200:
		if ending_screen.card_index() not in cards_seen:
			cards_seen.append(ending_screen.card_index())
		ending_screen.advance(ENDING_STEP_SECONDS)
		guard += 1
	reached_credits_state = flow.state == GameFlow.State.CREDITS
	await app.until_settled()
	var credits := app.screen as CreditsScreen
	if credits == null:
		problems.append("the credits did not roll after the ending cards")
		return false
	credits.finished.emit()
	await app.until_settled()
	finished_on_title = flow.state == GameFlow.State.TITLE and ShellSupport.title_of(app) != null
	if not finished_on_title:
		problems.append("the run did not end on the title screen")
	return finished_on_title


# --------------------------------------------------------------------------- one room
## Turns the AI off, takes what the stepping needs, brings every piece down and fills in the visit. False when a piece could not be reached or did not fall.
func _clear_the_room(room_id: StringName, visit: Dictionary) -> bool:
	Support.remove_enemy_ai(game)
	var ecs := Support.ecs_of(game)
	# What lies on the floor for the stepping (T2's sword): walk onto it.
	for unlock_cell: Vector2i in ecs.grid.player_unlock_by_cell.keys():
		if not await Support.walk_to_cell(suite, game, unlock_cell):
			problems.append("%s: the pawn could not walk onto the unlock at %s" % [room_id, unlock_cell])
			return false
		Support.pump(game, 0.1)
	var enemy_ids: Array = (game.get("cast")["enemies"] as Array).duplicate()
	for enemy_id: int in enemy_ids:
		var ai: EcsComponents.EnemyAI = ecs.get_component(enemy_id, EcsComponents.ENEMY_AI)
		if ai == null or ai.definition == null:
			continue
		if ai.definition.defeat_flag != &"":
			Events.emit_damage(ecs, enemy_id, 999, Vector2i.ZERO, Support.player_id_of(game))
			Support.pump(game, BOSS_FALL_SECONDS)
			visit["bosses_by_event"] += 1
		elif await Support.kill_with_sword(suite, game, enemy_id):
			visit["pieces_by_sword"] += 1
		else:
			problems.append("%s: the sword could not bring down the %s" % [room_id, ai.definition.id])
			return false
	return true


func _seconds_played() -> float:
	return float(Support.run_of(save_service).play_time_seconds)


# --------------------------------------------------------------------------- what the walk measured
## The visits of one room, in the order they were walked.
func visits_of(room_id: StringName) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for visit in visits:
		if visit["room"] == room_id:
			found.append(visit)
	return found


## The shortest clear of a room over all the visits (the hub is visited five times), in game seconds; -1.0 when the bot never was there.
func minimum_seconds_of(room_id: StringName) -> float:
	var shortest := -1.0
	for visit in visits_of(room_id):
		if shortest < 0.0 or float(visit["seconds"]) < shortest:
			shortest = float(visit["seconds"])
	return shortest


## Every game second the bot spent on the route, hub visits included.
func total_seconds() -> float:
	var total := 0.0
	for visit in visits:
		total += float(visit["seconds"])
	return total


# --------------------------------------------------------------------------- docs/route_times.md
## The text of docs/route_times.md for a list of visits (see `visits`). Pure, so a test can hand it made-up visits: the same visits give the same text on every
## machine, which is what lets the file be committed and a change in it be a change in the game. `route` is the rooms in the order they are met.
static func report_text(walked_visits: Array[Dictionary], route: Array[StringName]) -> String:
	var lines := PackedStringArray()
	lines.append("# Route times: the shortest clear of every room of the critical path")
	lines.append("")
	lines.append("Written by `tests/playthrough/test_full_route.gd` (the route bot, `tests/playthrough/route_bot.gd`) every time it runs. **Do not edit it by hand**: the next run puts the measurement back, and a change in it is a change in the game (a room that got longer, a door that moved).")
	lines.append("")
	lines.append("**What a number is.** Game seconds (the simulation's own clock, not the wall clock) from the moment the pawn arrives in a room to the moment it steps onto the door that leads on. The bot walks the shortest path by key presses, takes what the room gives for the stepping (T2's sword), brings every ordinary piece down with the sword (walk beside it, face it, strike until it falls) and brings a boss down with a damage event, which the plan allows until the boss fights exist (M8b). The enemies' AI is off, so nothing strikes the bot and nothing is dodged: this is a FLOOR that no player reaches, set beside the plan's first-play estimate (docs/game-base-plan.md 7.4, the Min column) so that the estimate can be replaced by a measurement (D-03). A room the pawn passes more than once (the hub, five times) shows its shortest visit.")
	lines.append("")
	lines.append("**What it is not.** A first-play time (nobody reads, learns, dies or looks around here), a boss's time (a stand-in boss falls to one damage event; the fight is M8b's and M9's measurements to make), or a time for the optional nooks (`tbo`, `bso`, `bto` are off the critical path, and each waits for a verb of M7c).")
	lines.append("")
	lines.append("| Room | Role | Visits | Pieces by sword | Bosses by damage event | Bot minimum | Plan estimate |")
	lines.append("|---|---|---|---|---|---|---|")
	var rooms_in_order: Array[StringName] = []
	for room_id in route:
		if room_id not in rooms_in_order:
			rooms_in_order.append(room_id)
	var seconds_by_act := {}
	var hub_pass_seconds := 0.0
	var total := 0.0
	for visit in walked_visits:
		total += float(visit["seconds"])
	var plan_total := 0.0
	var met: Array[StringName] = []
	for room_id in route:
		plan_total += PlanEncounterTable.HUB_PASS_THROUGH_MINUTES if room_id in met else float(PlanEncounterTable.row_of(room_id).get("minutes", 0.0))
		met.append(room_id)
	for room_id in rooms_in_order:
		var room_visits: Array[Dictionary] = []
		for visit in walked_visits:
			if visit["room"] == room_id:
				room_visits.append(visit)
		if room_visits.is_empty():
			continue
		var shortest := float(room_visits[0]["seconds"])
		var pieces := 0
		var bosses := 0
		for visit in room_visits:
			shortest = minf(shortest, float(visit["seconds"]))
			pieces = maxi(pieces, int(visit["pieces_by_sword"]))
			bosses = maxi(bosses, int(visit["bosses_by_event"]))
		var room_row := PlanRoomTable.row_of(room_id)
		var plan_row := PlanEncounterTable.row_of(room_id)
		lines.append("| `%s` | %s | %d | %d | %d | %.2f s | %.1f min |" % [room_id, room_row.get("recipe", ""), room_visits.size(), pieces, bosses, shortest, float(plan_row.get("minutes", 0.0))])
		var act := int(room_row.get("act", 0))
		seconds_by_act[act] = float(seconds_by_act.get(act, 0.0)) + float(room_visits[0]["seconds"])
		for visit_index in range(1, room_visits.size()):
			hub_pass_seconds += float(room_visits[visit_index]["seconds"])
	lines.append("")
	lines.append("| Act | First visits, game seconds | Plan, minutes |")
	lines.append("|---|---|---|")
	for act: int in seconds_by_act:
		lines.append("| %d | %.2f s | %.1f min |" % [act, seconds_by_act[act], float(PlanEncounterTable.ACT_MINUTES.get(act, 0.0))])
	lines.append("| the hub's returns (4) | %.2f s | %.1f min |" % [hub_pass_seconds, 4.0 * PlanEncounterTable.HUB_PASS_THROUGH_MINUTES])
	lines.append("| **the whole route** | **%.2f s** | **%.1f min** |" % [total, plan_total])
	lines.append("")
	lines.append("The plan's %.0f minutes are the sum of its Min column, the hub's four pass-throughs included (7.4 Totals: 130 to 136). The bot's total is the time the pawn needs when the game asks nothing of it but the walk and the strokes: until M9 puts real fights in the rooms it is the measure of the skeleton's length, not of the game's." % plan_total)
	lines.append("")
	return "\n".join(lines)
