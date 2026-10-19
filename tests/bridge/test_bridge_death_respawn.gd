extends UnboundTest

## Bridge characterization (M1a, ported in M3b): death and respawn through the in-game scene.
## The hero is killed through the real damage path (HealthSystem consuming
## world.damage_events, exactly like an enemy strike). RoomOutcomeBridge then freezes the room,
## resets the carry, shows the result panel, waits 0.85 s and asks GameFlow to start the room
## again. The rebuilt room must be the SAME zone from the run the SaveService holds, with the hero
## on its entry, full Courage and control back.
##
## CHANGED BY D-16/R17 (M3b): the death handler used to write the save before the reload. Autosave is
## for success events only and a death is not one, so a death now writes nothing (the run in memory
## already holds everything the hero earned: each earning wrote the save when it happened).
##
## CHANGED BY M3b step 2 (the plan, 9.1: "never reload_current_scene"): a death and the R key (restart_room, gone in M4: D-18) used to
## reload the whole scene, which would reload the title once AppRoot is the main scene (M4). GameFlow
## now rebuilds the room inside the scene: the same Main node stays, its old world and zone node and
## hero view are replaced by fresh ones. Three checks pinned the reload itself and say so below:
## "the old main is freed" (now: the old world is freed and the scene is the same node), "the scene
## has not reloaded yet" (now: the room has not been rebuilt yet) and "the scene's own CurrentZone node
## is the live zone" (now: the respawn builds a fresh zone node even in the scene's own zone).

const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "death_respawn"

const T1 := &"t1_white_kings_fall"
const T2 := &"t2_fallen_sword_tile"

func _init() -> void:
	suite_title = "BRIDGE DEATH RESPAWN TEST"
	call_deferred("_run")


func _run() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	var main := await Support.boot_main(self)
	var max_courage := Support.player_health(main).max_value

	# --- Set up a non-default zone with some progress, so a wrong respawn is visible ---
	_expect(await Support.walk_through_exit(self, main, T2, Vector2i.RIGHT), "setup: the hero travels T1 -> T2 through the real exit")
	var unlock_cells: Array = Support.ecs_of(main).grid.player_unlock_by_cell.keys()
	_expect(unlock_cells.size() == 1, "setup: T2 has its one sword unlock cell")
	var sword_cell: Vector2i = unlock_cells[0]
	Support.teleport_player(main, sword_cell + Vector2i.LEFT)
	Support.step_player(main, Vector2i.RIGHT)
	_expect(Support.player_combat(main).sword_unlocked, "setup: the hero picked up the wooden sword")
	Support.damage_player(main, 1)
	Support.wait_out_invulnerability(main)
	_expect(Support.player_health(main).current == max_courage - 1, "setup: the hero is wounded when the fatal blow lands")

	# --- The fatal blow, through the real damage path ---
	Support.remove_isolated_save(save_service)
	var hud := main.get("hud") as GameHud
	# The boot consumes the carry, so it is already -1 here and "death clears it"
	# would hold even if the room outcome never cleared anything. Plant a pending carry (what a
	# hero killed mid-fade-out of a travel would have left behind) so the assertion
	# below can only pass if the death handler really resets it.
	Support.plant_health_carry(main, 2)
	_expect(Support.health_carry(main) == 2, "setup: a stale health carry of 2 is pending when the fatal blow lands")
	var world_before_death := Support.ecs_of(main)
	var zone_node_before_death: Node = main.get("current_room")
	var hero_view_before_death: Node = main.get("player_view")
	Support.damage_player(main, 99)
	_expect(Support.player_health(main).current == 0, "the damage path takes the hero to 0 courage")
	_expect(Support.room_ending(main), "death marks the room as ending")
	_expect(not Support.player_tag(main).control_enabled, "control is off after the fatal blow")
	_expect(Support.health_carry(main) == -1, "death clears the pending health carry")
	_expect(not FileAccess.file_exists(String(save_service.call("slot_path", 0))), "CHANGED (R17, D-16): a death writes no save; autosave is for success events only")
	_expect(hud.result_panel.visible and hud.result_label.text.begins_with("THE PAWN FALLS"), "the result panel shows the defeat message")
	_expect(hud.result_label.text.contains("THE CHILD RESETS THE BOARD"), "the result panel shows the reset subtitle")
	_expect(Support.run_of(save_service).room_id == T2 and Support.run_of(save_service).room_entry_id == &"west_entry", "death leaves the run's zone and entry in the run")
	_expect(Support.ecs_of(main) == world_before_death and main.get("game_flow").respawn_is_pending() == false, "CHANGED (M3b step 2): the room has not been rebuilt yet (the 0.85 s defeat beat)")
	var cell_at_death := Support.player_cell(main)
	var intent: EcsComponents.MoveIntent = Support.ecs_of(main).get_component(Support.player_id_of(main), EcsComponents.MOVE_INTENT)
	intent.direction = Vector2i.RIGHT
	Support.pump(main, 0.45)
	_expect(Support.player_cell(main) == cell_at_death and intent.direction == Vector2i.RIGHT, "CHARACTERIZATION: once the room is ending the simulation stops ticking")
	_expect(not Support.travel_in_progress(main), "death is not a travel")

	# The dead hero's view holds the end of its defeat clip: this is what a fresh view must not inherit.
	await create_timer(0.3).timeout
	var dead_hero_playback: AnimationNodeStateMachinePlayback = hero_view_before_death.get_node("AnimationTree").get("parameters/playback")
	_expect(dead_hero_playback.get_current_node() == &"defeat", "setup: the fallen hero's view rests in its defeat pose")

	# --- GameFlow rebuilds the same zone and gives control back ---
	var respawned := await Support.wait_for_respawn(self, main)
	_expect(respawned, "CHANGED (M3b step 2): death rebuilds the room after its beat through GameFlow, with no scene reload")
	if not respawned:
		_finish(save_service)
		return
	_expect(tree_current_scene_is(main) and is_instance_valid(main), "CHANGED (M3b step 2): the scene itself stays: the same Main node is still the current scene")
	_expect(not is_instance_valid(world_before_death) and not is_instance_valid(zone_node_before_death), "CHANGED (M3b step 2): the old world and the old zone node are freed by the respawn")
	_expect(main.get("player_view") != hero_view_before_death and not is_instance_valid(hero_view_before_death) and (main.get("player_view") as Node).name == &"PawnHero", "the fallen hero's view is replaced by a fresh PawnHero")
	var reborn_playback: AnimationNodeStateMachinePlayback = (main.get("player_view") as Node).get_node("AnimationTree").get("parameters/playback")
	_expect(reborn_playback.get_current_node() != &"defeat", "and the fresh view is not lying in the defeat pose (it boots through the graph's wake)")
	_expect(main.get("game_flow").last_respawn_reason == &"defeated" and main.get("game_flow").state == GameFlow.State.PLAYING, "GameFlow records why, and is playing again")
	_expect(main.get("current_zone_id") == T2 and main.get("current_room").get("zone_id") == T2, "death reboots the SAME zone (T2), not the scene default")
	_expect(Support.run_of(save_service).room_id == T2, "the run still names T2 after the reboot")
	_expect(Support.player_cell(main) == Support.entry_cell(main, main.get("current_room"), &"west_entry"), "the hero respawns on the entry cell the run last used")
	_expect(Support.player_health(main).current == max_courage, "the respawned hero has full courage (death drops the carry)")
	_expect(Support.player_tag(main).control_enabled and not Support.room_ending(main), "control returns and the room is live again")
	_expect(not (main.get("hud") as GameHud).result_panel.visible, "the defeat panel is gone after the respawn")
	_expect(Support.player_combat(main).sword_unlocked, "progress survives death: the sword stays unlocked")
	var start_cell := Support.player_cell(main)
	await Support.hold_action(self, main, &"move_right", 0.45)
	_expect(Support.player_cell(main).x > start_cell.x, "real key input moves the respawned hero (control is truly back)")

	# --- Death in the scene-default zone ---
	await Support.travel_to(main, T1, &"start")
	_expect(main.get("current_zone_id") == T1, "setup: the hero is back in T1")
	var t1_node_before_death: Node = main.get("current_room")
	Support.damage_player(main, 99)
	var respawned_t1 := await Support.wait_for_respawn(self, main)
	_expect(respawned_t1, "death in T1 rebuilds the room")
	if not respawned_t1:
		_finish(save_service)
		return
	_expect(main.get("current_zone_id") == T1 and Support.player_cell(main) == Support.entry_cell(main, main.get("current_room"), &"start"), "death in T1 respawns on T1's start entry")
	_expect(Support.player_health(main).current == max_courage and Support.player_tag(main).control_enabled, "the T1 respawn has full courage and control")
	_expect(main.get("current_room") != t1_node_before_death and main.get("current_room").get("zone_id") == T1, "CHANGED (M3b step 2): the respawn builds a fresh zone node even in the scene's own zone; there is no reload to bring the authored CurrentZone node back")

	# --- The pause menu's Restart Room asks GameFlow the same way without a death (D-18: no restart key) ---
	await Support.travel_to(main, T2, &"west_entry")
	Support.damage_player(main, 1)
	_expect(Support.player_health(main).current == max_courage - 1, "setup: a wounded hero chooses Restart Room")
	Support.restart_room_from_the_menu(main)
	var restarted := await Support.wait_for_respawn(self, main)
	_expect(restarted, "Restart Room rebuilds the room through GameFlow, with no scene reload")
	if not restarted:
		_finish(save_service)
		return
	_expect(main.get("current_zone_id") == T2, "Restart Room reboots the same zone")
	_expect(Support.player_health(main).current == max_courage, "Restart Room heals (the rebuild carries nothing)")
	_expect(main.get("game_flow").last_respawn_reason == GameFlow.REASON_RESTART_MENU, "and GameFlow knows it was the menu, not a death")

	_finish(save_service)


func tree_current_scene_is(candidate: Node) -> bool:
	return current_scene != null and current_scene == candidate


func _finish(save_service: Node) -> void:
	Support.end_suite(self, save_service)
