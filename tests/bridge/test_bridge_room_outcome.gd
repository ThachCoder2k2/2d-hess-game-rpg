extends UnboundTest

## RoomOutcomeBridge (shell/bridges/room_outcome_bridge.gd, M3b step 2): how a room is won. The death
## half is pinned by test_bridge_death_respawn; this suite pins the other half, which no suite drove
## before the split: the enemy count follows the defeats, clearing a zone in world mode is quiet, a zone
## that carries an objective ends with the result panel when the objective says so, and a room outside
## the world graph (a standalone room) ends when every enemy is down. A win turns the hero's control
## off, shows the room's clear lines and stops the world from ticking.
## The pawns are killed through the real damage path (Events.emit_damage, consumed by HealthSystem).

const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "room_outcome"

const T2 := &"t2_fallen_sword_tile"
const T3 := &"t3_first_pawn_clash"
const T4 := &"t4_broken_rule_yard"


func _init() -> void:
	suite_title = "BRIDGE ROOM OUTCOME TEST"
	call_deferred("_run")


func _run() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	var main := await Support.boot_main(self)
	var hud := main.get("hud") as GameHud

	# --- World mode: the count follows the defeats and clearing a zone is quiet ---
	await Support.travel_to(main, T3, &"west_entry")
	Support.remove_enemy_ai(main)
	_expect(Support.total_enemies(main) == 1 and hud.encounter_label.text == "ENEMIES 1/1", "setup: T3 begins with one enemy and the HUD counts it")
	_kill_enemy(main, 0)
	_expect(hud.encounter_label.text == "ENEMIES 0/1", "a defeat takes one off the HUD count")
	_expect(not Support.room_ending(main) and not hud.result_panel.visible and Support.player_tag(main).control_enabled, "in world mode clearing a zone with no objective is quiet: no result panel, control stays on")

	# --- Outside the world graph a room ends when every enemy is down, with the stock lines ---
	# A won room can only be left by starting it again, so each phase boots the scene anew; the run
	# still names T3, so the new scene boots in T3 with its one pawn alive.
	main = await _boot_again(main, save_service)
	hud = main.get("hud") as GameHud
	_expect(main.get("current_zone_id") == T3 and Support.total_enemies(main) == 1, "setup: a relaunch boots T3 with its pawn alive")
	Support.remove_enemy_ai(main)
	main.set("world_graph", null)
	_kill_enemy(main, 0)
	_expect(Support.room_ending(main), "a standalone room ends when its last enemy falls")
	_expect(hud.result_label.text == "ROOM CLEARED\nPRESS R TO RESET" and hud.objective_label.text == "ROOM CLEARED", "with the stock clear lines when the room names none")
	_expect(not Support.player_tag(main).control_enabled, "and the hero's control is off")

	# --- An objective that counts defeats ends the room when it is met ---
	main = await _boot_again(main, save_service)
	hud = main.get("hud") as GameHud
	await Support.travel_to(main, T4, &"west_entry")
	Support.remove_enemy_ai(main)
	var enemy_count := Support.total_enemies(main)
	_expect(enemy_count >= 2, "setup: T4 holds at least two enemies (%d)" % enemy_count)
	var objective := RoomObjective.new()
	objective.win_condition = RoomObjective.WinCondition.DEFEAT_COUNT
	objective.required_defeats = 2
	objective.clear_message = "TWO DOWN"
	objective.clear_subtitle = "THE YARD GOES QUIET"
	main.get("current_room").set("objective", objective)
	_kill_enemy(main, 0)
	_expect(not Support.room_ending(main) and not hud.result_panel.visible, "one defeat of the two the objective asks for does not end the room")
	_kill_enemy(main, 1)
	_expect(Support.room_ending(main), "the second defeat meets the objective and ends the room")
	_expect(hud.result_panel.visible and hud.result_label.text == "TWO DOWN\nTHE YARD GOES QUIET", "the result panel shows the objective's clear lines")
	_expect(hud.objective_label.text == "TWO DOWN", "and the status line says the clear message")
	_expect(not Support.player_tag(main).control_enabled, "the hero's control is off after a win")
	var cell_at_win := Support.player_cell(main)
	var intent: EcsComponents.MoveIntent = Support.ecs_of(main).get_component(Support.player_id_of(main), EcsComponents.MOVE_INTENT)
	intent.direction = Vector2i.RIGHT
	Support.pump(main, 0.45)
	_expect(Support.player_cell(main) == cell_at_win, "the world stops ticking once the room has ended")
	# The world no longer ticks, so a late defeat can only arrive as an event: it must not end the room twice.
	Support.ecs_of(main).emit_event({"type": Events.DEFEATED, "entity": main.get("cast")["enemies"][enemy_count - 1], "source": 0, "tags": []})
	hud.set_status("sentinel")
	Support.route_events(main)
	_expect(Support.room_ending(main) and hud.objective_label.text == "sentinel", "a defeat that arrives after the win does not end the room a second time")

	Support.end_suite(self, save_service)


## Frees the scene and boots a new one from the run in memory, as a relaunch would.
func _boot_again(old_main: Node, save_service: Node) -> Node:
	Support.release_all_actions()
	old_main.free()
	Support.write_the_run(save_service)
	Support.forget_the_run(save_service)
	return await Support.boot_main(self)


## Kills the `index`-th enemy of the room the way a sword would (a damage request HealthSystem consumes).
func _kill_enemy(main: Node, index: int) -> void:
	var cast: Dictionary = main.get("cast")
	var enemy_id: int = cast["enemies"][index]
	Events.emit_damage(Support.ecs_of(main), enemy_id, 99, Vector2i.ZERO, Support.player_id_of(main))
	Support.pump(main, Support.SIM_STEP_SECONDS)
