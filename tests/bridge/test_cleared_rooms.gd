extends UnboundTest

## D-17 and the room-local half of D-16 (docs/game-base-plan.md 5.2, 9.3), driven through the real scene:
## a cleared room stays cleared, an uncleared room starts over, and a floor weapon is back on the floor
## whenever its room starts again.
##   - ObjectiveSystem says `room_cleared`; SaveBridge writes the zone into the run's cleared rooms and
##     saves (a success event, reason room_cleared);
##   - every later boot of that zone (a return visit, a death inside it, a relaunch) spawns none of its
##     enemies and removes their parked views, and its HUD counts 0/0; its exits that need the room cleared
##     are open;
##   - a room that was left uncleared comes back whole: all its enemies at full health, even after a death;
##   - the pencil spear an enemy picked up is on the floor again after a death.
## Autosave reasons are watched through SaveService.autosaved, so "saved for the clear and for nothing
## else" is read off the service, not guessed.

const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "cleared_rooms"

const T2 := &"t2_fallen_sword_tile"
const T3 := &"t3_first_pawn_clash"
const T4 := &"t4_broken_rule_yard"

var saved_reasons: Array[StringName] = []


func _init() -> void:
	suite_title = "CLEARED ROOMS TEST"
	call_deferred("_run")


func _run() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	save_service.autosaved.connect(func(_slot: int, reason: StringName) -> void: saved_reasons.append(reason))
	var main := await Support.boot_main(self)
	Support.give_the_sword(main, save_service)
	var max_courage := Support.player_health(main).max_value

	# --- Clearing T3 (one pawn) is remembered and saved ---
	await Support.travel_to(main, T3, &"west_entry")
	Support.remove_enemy_ai(main)
	_expect(Support.total_enemies(main) == 1 and not Support.run_of(save_service).cleared_room_ids.has(String(T3)), "setup: T3 begins with its pawn and the run has not cleared it")
	saved_reasons.clear()
	_expect(await _kill_enemy(main, 0), "the hero's sword brings the last pawn down")
	_expect(Support.run_of(save_service).cleared_room_ids.has(String(T3)), "the run records T3 as cleared")
	_expect(saved_reasons == [&"room_cleared"], "and the clear is the success event that saved: %s" % [saved_reasons])
	_expect(_saved_cleared_rooms(save_service).has(String(T3)), "the save file holds T3 among the cleared rooms at once")
	saved_reasons.clear()
	Support.pump(main, 1.0)
	_expect(saved_reasons.is_empty(), "a cleared room does not save again while the pawn stands in it")

	# --- It stays cleared: a return visit, an open exit, a death inside it ---
	await Support.travel_to(main, T2, &"from_t3")
	saved_reasons.clear()
	await Support.travel_to(main, T3, &"west_entry")
	_expect(main.get("cast")["enemies"].is_empty() and Support.total_enemies(main) == 0, "back in T3 nothing is spawned: the pawn stays down")
	_expect(_parked_enemy_views(main).is_empty(), "and the pawn's parked view is gone from the room, not left standing as a puppet")
	_expect((main.get("hud") as GameHud).enemy_count.count_label.text == "ENEMIES 0/0", "the HUD counts no enemies")
	_expect(not saved_reasons.has(&"room_cleared"), "entering a cleared room is not a clear: nothing is saved for it")
	var door_to_t4 := Support.exit_cell(main, main.get("current_room"), T4)
	Support.teleport_player(main, door_to_t4 + Vector2i.LEFT)
	var intent: EcsComponents.MoveIntent = Support.ecs_of(main).get_component(Support.player_id_of(main), EcsComponents.MOVE_INTENT)
	intent.direction = Vector2i.RIGHT
	_expect(Support.pump_until(main, func() -> bool: return Support.travel_in_progress(main), 1.0), "the exit that needs the room cleared is open: the way on starts a trip")
	await Support.wait_for_travel(self, main)
	_expect(main.get("current_zone_id") == T4, "and leads to T4")

	await Support.travel_to(main, T3, &"west_entry")
	saved_reasons.clear()
	Support.damage_player(main, 99)
	_expect(await Support.wait_for_respawn(self, main), "a fall in the cleared room starts it again")
	_expect(main.get("current_zone_id") == T3 and main.get("cast")["enemies"].is_empty(), "the rebuilt T3 is still empty: a death does not bring the pawn back")
	_expect(Support.player_health(main).current == max_courage and Support.run_of(save_service).cleared_room_ids.has(String(T3)), "the hero is whole again and the clear is still on record")
	_expect(saved_reasons.is_empty(), "and the fall saved nothing")

	# --- An uncleared room starts over: leaving it, and a death inside it ---
	await Support.travel_to(main, T4, &"west_entry")
	Support.remove_enemy_ai(main)
	var pawn_count := Support.total_enemies(main)
	_expect(pawn_count == 3 and not Support.run_of(save_service).cleared_room_ids.has(String(T4)), "setup: T4 begins with three pawns and is not cleared")
	_expect(await _kill_enemy(main, 0), "the hero's sword brings one of the three down")
	_expect(not Support.run_of(save_service).cleared_room_ids.has(String(T4)) and (main.get("hud") as GameHud).enemy_count.count_label.text == "ENEMIES 2/3", "T4 is not cleared and the HUD counts 2/3")
	await Support.travel_to(main, T3, &"west_entry")
	await Support.travel_to(main, T4, &"west_entry")
	_expect(Support.total_enemies(main) == 3 and _all_enemies_are_whole(main), "leaving T4 uncleared and coming back: all three pawns are back at full health")

	# --- Room-local floor weapons: gone from the floor while an enemy holds one, back after a death ---
	var enemy_ai := Support.remove_enemy_ai(main) as EnemyAISystem
	_expect(enemy_ai != null, "setup: the enemy AI system is at hand to let a pawn take the spear")
	var ecs := Support.ecs_of(main)
	var spear_cell: Vector2i = ecs.grid.get_item_cells()[0]
	var enemy_id: int = main.get("cast")["enemies"][0]
	var enemy_position: EcsComponents.GridPos = ecs.get_component(enemy_id, EcsComponents.GRID_POS)
	enemy_position.cell = spear_cell
	saved_reasons.clear()
	enemy_ai.call("_collect_local_item", enemy_id)
	Support.route_events(main)
	_expect(ecs.grid.get_item_cells().is_empty() and (ecs.get_component(enemy_id, EcsComponents.WEAPON_SLOT) as EcsComponents.WeaponSlot).weapon != null, "a pawn takes the spear off the floor and holds it")
	_expect(saved_reasons.is_empty(), "and that is no success event: nothing is saved")
	Support.damage_player(main, 99)
	_expect(await Support.wait_for_respawn(self, main), "the hero falls in T4 and the room starts again")
	var reborn_ecs := Support.ecs_of(main)
	var reborn_enemy_id: int = main.get("cast")["enemies"][0]
	_expect(reborn_ecs.grid.get_item_cells().size() == 1, "the spear is back on the floor")
	_expect((reborn_ecs.get_component(reborn_enemy_id, EcsComponents.WEAPON_SLOT) as EcsComponents.WeaponSlot).weapon == null, "and the pawn that held it has nothing in its hand")
	_expect(Support.total_enemies(main) == 3 and _all_enemies_are_whole(main), "all three pawns are whole: a death resets the room it happened in")
	_expect(saved_reasons.is_empty(), "no save for any of it")

	# --- A relaunch keeps T3 cleared and T4 whole ---
	await Support.travel_to(main, T3, &"west_entry")
	Support.write_the_run(save_service)
	main.free()
	Support.forget_the_run(save_service)
	var relaunched := await Support.boot_main(self)
	_expect(relaunched.get("current_zone_id") == T3 and relaunched.get("cast")["enemies"].is_empty(), "after quitting and relaunching, T3 is still empty")
	await Support.travel_to(relaunched, T4, &"west_entry")
	_expect(Support.total_enemies(relaunched) == 3, "and T4, which was never cleared, still has its three pawns")

	Support.end_suite(self, save_service)


## Brings the `index`-th enemy of the room down with the hero's sword, by the real input path (walk beside it, face
## it, press attack), so a room whose pawn the sword cannot reach fails here and not only in play. The enemy AI is
## removed first by the caller. True when the pawn fell.
func _kill_enemy(main: Node, index: int) -> bool:
	return await Support.kill_with_sword(self, main, main.get("cast")["enemies"][index])


func _all_enemies_are_whole(main: Node) -> bool:
	for enemy_id: int in main.get("cast")["enemies"]:
		var health: EcsComponents.Health = Support.ecs_of(main).get_component(enemy_id, EcsComponents.HEALTH)
		if health == null or health.current != health.max_value:
			return false
	return true


## The ActorViews still parked in the room that carry an enemy definition.
func _parked_enemy_views(main: Node) -> Array[ActorView]:
	var views: Array[ActorView] = []
	for child in (main.get("current_room") as Node).get_children():
		var view := child as ActorView
		if view != null and view.definition != null and not view.is_queued_for_deletion():
			views.append(view)
	return views


func _saved_cleared_rooms(save_service: Node) -> Array:
	return Support.read_save_file(save_service).get_value("world", "cleared_room_ids", [])
