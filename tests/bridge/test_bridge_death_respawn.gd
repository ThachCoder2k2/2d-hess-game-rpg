extends SceneTree

## Bridge characterization (M1a): death and respawn through scripts/main.gd.
## The hero is killed through the real damage path (HealthSystem consuming
## world.damage_events, exactly like an enemy strike). main._on_defeated then
## calls _on_player_defeated, which freezes the room, resets the carry, saves,
## shows the result panel, waits 0.85 s and reloads the scene. The reloaded
## main must boot the SAME zone from WorldState and hand control back.

const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "death_respawn"

const T1 := &"t1_white_kings_fall"
const T2 := &"t2_fallen_sword_tile"

var failures := 0


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)


func _init() -> void:
	Support.arm_watchdog(self, "BRIDGE DEATH RESPAWN TEST")
	call_deferred("_run")


func _run() -> void:
	var world_state := Support.install_isolated_world_state(self, SUITE_NAME)
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
	Support.remove_isolated_save(world_state)
	var hud := main.get("hud") as GameHud
	Support.damage_player(main, 99)
	_expect(Support.player_health(main).current == 0, "the damage path takes the hero to 0 courage")
	_expect(bool(main.get("room_ending")), "death marks the room as ending")
	_expect(not Support.player_tag(main).control_enabled, "control is off after the fatal blow")
	_expect(world_state.get("player_health_carry") == -1, "death clears the health carry")
	_expect(FileAccess.file_exists(String(world_state.get("isolated_save_path"))), "death saves WorldState before the reload")
	_expect(hud.result_panel.visible and hud.result_label.text.begins_with("THE PAWN FALLS"), "the result panel shows the defeat message")
	_expect(hud.result_label.text.contains("THE CHILD RESETS THE BOARD"), "the result panel shows the reset subtitle")
	_expect(world_state.get("current_zone_id") == T2 and world_state.get("last_entry_id") == &"west_entry", "death leaves the run's zone and entry in WorldState")
	_expect(tree_current_scene_is(main), "the scene has not reloaded yet (the 0.85 s defeat beat)")
	var cell_at_death := Support.player_cell(main)
	var intent: EcsComponents.MoveIntent = Support.ecs_of(main).get_component(Support.player_id_of(main), EcsComponents.MOVE_INTENT)
	intent.direction = Vector2i.RIGHT
	Support.pump(main, 0.45)
	_expect(Support.player_cell(main) == cell_at_death and intent.direction == Vector2i.RIGHT, "CHARACTERIZATION: once the room is ending the simulation stops ticking")
	_expect(not bool(main.get("travel_in_progress")), "death is not a travel")

	# --- The reload boots the same zone and gives control back ---
	var reloaded := await Support.wait_for_reload(self, main)
	_expect(reloaded != null, "death reloads the main scene after its beat")
	if reloaded == null:
		_finish(world_state)
		return
	_expect(not is_instance_valid(main), "the old main is freed by the reload")
	main = reloaded
	_expect(main.get("current_zone_id") == T2 and main.get("current_room").get("zone_id") == T2, "death reboots the SAME zone (T2), not the scene default")
	_expect(world_state.get("current_zone_id") == T2, "WorldState still names T2 after the reboot")
	_expect(Support.player_cell(main) == Support.entry_cell(main, main.get("current_room"), &"west_entry"), "the hero respawns on the entry cell the run last used")
	_expect(Support.player_health(main).current == max_courage, "the respawned hero has full courage (death drops the carry)")
	_expect(Support.player_tag(main).control_enabled and not bool(main.get("room_ending")), "control returns and the room is live again")
	_expect(not (main.get("hud") as GameHud).result_panel.visible, "the defeat panel is gone after the reload")
	_expect(Support.player_combat(main).sword_unlocked, "progress survives death: the sword stays unlocked")
	var start_cell := Support.player_cell(main)
	await Support.hold_action(self, main, &"move_right", 0.45)
	_expect(Support.player_cell(main).x > start_cell.x, "real key input moves the respawned hero (control is truly back)")

	# --- Death in the scene-default zone: no zone swap is needed on reload ---
	await main._travel_to(T1, &"start")
	_expect(main.get("current_zone_id") == T1, "setup: the hero is back in T1")
	Support.damage_player(main, 99)
	var reloaded_t1 := await Support.wait_for_reload(self, main)
	_expect(reloaded_t1 != null, "death in T1 reloads the scene")
	if reloaded_t1 == null:
		_finish(world_state)
		return
	main = reloaded_t1
	_expect(main.get("current_zone_id") == T1 and Support.player_cell(main) == Support.entry_cell(main, main.get("current_room"), &"start"), "death in T1 respawns on T1's start entry")
	_expect(Support.player_health(main).current == max_courage and Support.player_tag(main).control_enabled, "the T1 respawn has full courage and control")
	_expect(main.get_node_or_null("CurrentZone") != null, "CHARACTERIZATION: with no swap needed the scene's own CurrentZone node is the live zone")

	# --- The restart key reloads the same way without a death ---
	await main._travel_to(T2, &"west_entry")
	Support.damage_player(main, 1)
	_expect(Support.player_health(main).current == max_courage - 1, "setup: a wounded hero presses the restart key")
	Input.action_press(&"restart_room")
	main._process(0.0)
	Input.action_release(&"restart_room")
	var restarted := await Support.wait_for_reload(self, main)
	_expect(restarted != null, "the restart key reloads the main scene")
	if restarted == null:
		_finish(world_state)
		return
	main = restarted
	_expect(main.get("current_zone_id") == T2, "the restart key reboots the same zone")
	_expect(Support.player_health(main).current == max_courage, "the restart key heals (the reload carries nothing)")

	_finish(world_state)


func tree_current_scene_is(candidate: Node) -> bool:
	return current_scene != null and current_scene == candidate


func _finish(world_state: Node) -> void:
	Support.release_all_actions()
	Support.remove_isolated_save(world_state)
	var succeeded := failures == 0
	print("BRIDGE DEATH RESPAWN TEST: %s" % ["PASS" if succeeded else "FAIL (%d)" % failures])
	quit(0 if succeeded else 1)
