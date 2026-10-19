extends UnboundTest

## GameFlow (shell/game_flow.gd, M3b step 2): the one request the in-game scene can make of its flow,
## "start the room again", raised by a death and by the R key, and served WITHOUT reloading the scene.
## test_bridge_death_respawn pins the outcome of a death and of R (zone, entry, Courage, control, the
## fresh hero view); this suite pins the flow around it: one rebuild per request however many ask, a
## rebuild that waits for a zone trip under way, a death beat that does not rebuild a room the restart
## key already rebuilt, and the leftovers a rebuild must not inherit (an open Book, the old world's marks
## on the board, a despawn timer from the old world).

const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "game_flow"

const T1 := &"t1_white_kings_fall"
const T2 := &"t2_fallen_sword_tile"
const T3 := &"t3_first_pawn_clash"
const T4 := &"t4_broken_rule_yard"

var respawned_reasons: Array[StringName] = []
var requested_reasons: Array[StringName] = []


func _init() -> void:
	suite_title = "GAME FLOW TEST"
	call_deferred("_run")


func _run() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	var main := await Support.boot_main(self)
	var flow: GameFlow = main.get("game_flow")
	flow.respawned.connect(func(reason: StringName) -> void: respawned_reasons.append(reason))
	flow.respawn_requested.connect(func(reason: StringName) -> void: requested_reasons.append(reason))
	var max_courage := Support.player_health(main).max_value
	_expect(flow.state == GameFlow.State.PLAYING and not flow.respawn_is_pending(), "a new scene is playing with no request waiting")

	# --- One rebuild per request, however many ask in the same frame ---
	flow.request_respawn(GameFlow.REASON_RESTART_KEY)
	flow.request_respawn(GameFlow.REASON_RESTART_KEY)
	flow.request_respawn(GameFlow.REASON_DEFEATED)
	_expect(flow.respawn_is_pending() and requested_reasons == [GameFlow.REASON_RESTART_KEY], "the first request is accepted and announced, the others in the same frame are ignored")
	_expect(await Support.wait_for_respawn(self, main), "the accepted request rebuilds the room at the end of the frame")
	await process_frame
	_expect(respawned_reasons == [GameFlow.REASON_RESTART_KEY] and not flow.respawn_is_pending(), "exactly one rebuild happened, for the first request's reason")

	# --- A rebuild waits for a zone trip under way, then rebuilds where the trip went ---
	var door := Support.exit_cell(main, main.get("current_room"), T2)
	Support.teleport_player(main, door + Vector2i.LEFT)
	var intent: EcsComponents.MoveIntent = Support.ecs_of(main).get_component(Support.player_id_of(main), EcsComponents.MOVE_INTENT)
	intent.direction = Vector2i.RIGHT
	_expect(Support.pump_until(main, func() -> bool: return Support.travel_in_progress(main), 1.0), "setup: the hero steps through the door and a trip starts")
	respawned_reasons.clear()
	flow.request_respawn(GameFlow.REASON_RESTART_KEY)
	await process_frame
	_expect(respawned_reasons.is_empty() and Support.travel_in_progress(main), "the rebuild does not cut into a trip: it waits")
	var world_during_trip := Support.ecs_of(main)
	var waited := true
	var started_msec := Time.get_ticks_msec()
	while respawned_reasons.is_empty() and Time.get_ticks_msec() - started_msec < Support.REAL_TIME_WAIT_CAP_MSEC:
		await process_frame
	waited = not respawned_reasons.is_empty()
	await process_frame
	_expect(waited and not Support.travel_in_progress(main), "once the trip has ended the room is rebuilt")
	_expect(main.get("current_zone_id") == T2 and Support.ecs_of(main) != world_during_trip, "and rebuilt where the trip went (T2), not where it left")
	_expect(is_zero_approx((main.get_node("FadeLayer/FadeRect") as ColorRect).modulate.a), "with the fade layer clear")
	_expect(Support.player_tag(main).control_enabled and Support.player_health(main).current == max_courage, "and the hero in control at full Courage")

	# --- The restart key during the death beat: the beat's own request finds nothing left to do ---
	respawned_reasons.clear()
	Support.damage_player(main, 99)
	_expect(Support.room_ending(main), "setup: the hero fell and the defeat beat is running")
	var world_that_fell := Support.ecs_of(main)
	await create_timer(0.2).timeout
	flow.request_respawn(GameFlow.REASON_RESTART_KEY)
	_expect(await Support.wait_for_respawn(self, main), "the restart key rebuilds the room during the beat")
	var world_after_restart := Support.ecs_of(main)
	await create_timer(1.0).timeout
	_expect(respawned_reasons == [GameFlow.REASON_RESTART_KEY] and Support.ecs_of(main) == world_after_restart, "and the death beat, when it ends, does not rebuild the room a second time")
	_expect(world_that_fell != world_after_restart and not Support.room_ending(main), "the rebuilt room is live")

	# --- A despawn timer of the old world must not touch the new one ---
	# T4 holds three pawns, so the one that falls does not clear the room (a cleared room stays cleared, D-17,
	# and would not be rebuilt with its pawns: T3, with one pawn, used to stand here).
	await Support.travel_to(main, T4, &"west_entry")
	Support.remove_enemy_ai(main)
	var old_enemy_id: int = main.get("cast")["enemies"][0]
	Events.emit_damage(Support.ecs_of(main), old_enemy_id, 99, Vector2i.ZERO, Support.player_id_of(main))
	Support.pump(main, Support.SIM_STEP_SECONDS)
	_expect(Support.ecs_of(main).get_component(old_enemy_id, EcsComponents.HEALTH).current == 0, "setup: one of T4's pawns fell a moment before the restart")
	flow.request_respawn(GameFlow.REASON_RESTART_KEY)
	_expect(await Support.wait_for_respawn(self, main), "setup: the restart rebuilt T4")
	var new_enemy_id: int = main.get("cast")["enemies"][0]
	var new_enemy_view := main.get("cast")["view_by_entity"][new_enemy_id] as Node2D
	await create_timer(DespawnBridge.DEFEAT_CLIP_SECONDS + 0.3).timeout
	_expect(new_enemy_id == old_enemy_id, "setup: the new world numbers its pawn the same as the old one did")
	_expect(Support.ecs_of(main).get_component(new_enemy_id, EcsComponents.VIEW_REF) != null and is_instance_valid(new_enemy_view) and not new_enemy_view.is_queued_for_deletion(), "the old pawn's despawn timer did not strip the new pawn's view")

	# --- What a rebuild must not inherit ---
	var board := main.get("board") as PrototypeBoard
	var marked_cells: Array[Vector2i] = [Vector2i(3, 3)]
	board.set_telegraph(77, marked_cells)
	board.set_enemy_intent(77, EnemyIntent.wait(0.5))
	Support.send_key(KEY_B, true)
	Support.pump(main, 0.05)
	Support.send_key(KEY_B, false)
	Support.pump(main, 0.05)
	var book := main.get_node("RuleBookUI") as RuleBookUI
	_expect(book.visible and not Support.player_tag(main).control_enabled, "setup: the Book is open over a marked board")
	flow.request_respawn(GameFlow.REASON_RESTART_KEY)
	_expect(await Support.wait_for_respawn(self, main), "setup: the restart key is pressed")
	_expect(not book.visible and Support.player_tag(main).control_enabled, "the rebuilt room has the Book closed and the hero in control")
	_expect(board.telegraphs.is_empty() and board.enemy_intents.is_empty(), "the board overlay carries none of the old world's marks")

	# --- Nothing piles up, and the scene's own nodes stay ---
	var world_count := 0
	for child in main.get_children():
		if child is EcsWorld:
			world_count += 1
	_expect(world_count == 1, "exactly one EcsWorld is parented to the scene after all those rebuilds")
	_expect(main.get_node_or_null("MusicPlayer") != null and tree_current_scene_is(main), "the music player and the scene itself were never replaced (no reload)")
	_expect(Support.run_of(save_service).room_id == T4, "and the run, which the rebuilds read, names the zone the hero was last sent to")

	# --- A fall during a trip's fade-out still ends in a rebuild at the checkpoint, as the reload did ---
	respawned_reasons.clear()
	await Support.travel_to(main, T2, &"west_entry")
	var door_back := Support.exit_cell(main, main.get("current_room"), T3)
	Support.teleport_player(main, door_back + Vector2i.LEFT)
	var back_intent: EcsComponents.MoveIntent = Support.ecs_of(main).get_component(Support.player_id_of(main), EcsComponents.MOVE_INTENT)
	back_intent.direction = Vector2i.RIGHT
	Support.pump_until(main, func() -> bool: return Support.travel_in_progress(main), 1.0)
	Support.damage_player(main, 99)
	await Support.wait_for_travel(self, main)
	_expect(respawned_reasons.is_empty() and Support.player_health(main).current == max_courage, "setup: the trip finished and the new room's hero is unhurt (the fall happened in the old world)")
	started_msec = Time.get_ticks_msec()
	while respawned_reasons.is_empty() and Time.get_ticks_msec() - started_msec < Support.REAL_TIME_WAIT_CAP_MSEC:
		await process_frame
	_expect(respawned_reasons == [GameFlow.REASON_DEFEATED] and main.get("current_zone_id") == T3, "the defeat beat still starts the room again at the checkpoint, though a trip swapped the world meanwhile")

	# --- With the engine driving the frames (the real loop, not pumped by hand) ---
	# Everything above ticks the scene by hand. Here the engine calls _process, so a death's request is
	# served between two real frames, and R goes through the real input path.
	Support.remove_enemy_ai(main)
	respawned_reasons.clear()
	main.set_process(true)
	await process_frame
	var live_world := Support.ecs_of(main)
	Events.emit_damage(live_world, Support.player_id_of(main), 99, Vector2i.LEFT, 0)
	started_msec = Time.get_ticks_msec()
	while respawned_reasons.is_empty() and Time.get_ticks_msec() - started_msec < Support.REAL_TIME_WAIT_CAP_MSEC:
		await process_frame
	_expect(respawned_reasons == [GameFlow.REASON_DEFEATED], "with the engine ticking the world, a fall is answered by a rebuild after the defeat beat")
	_expect(Support.ecs_of(main) != live_world and Support.player_tag(main).control_enabled and not Support.room_ending(main), "and the new room is live with the hero in control")
	main.set_process(false)
	Support.remove_enemy_ai(main)
	main.set_process(true)
	respawned_reasons.clear()
	await process_frame
	Input.action_press(&"restart_room")
	await process_frame
	Input.action_release(&"restart_room")
	started_msec = Time.get_ticks_msec()
	while respawned_reasons.is_empty() and Time.get_ticks_msec() - started_msec < Support.REAL_TIME_WAIT_CAP_MSEC:
		await process_frame
	main.set_process(false)
	_expect(respawned_reasons == [GameFlow.REASON_RESTART_KEY], "the restart key, pressed through the real input path, is answered by one rebuild")

	Support.end_suite(self, save_service)


func tree_current_scene_is(candidate: Node) -> bool:
	return current_scene != null and current_scene == candidate
