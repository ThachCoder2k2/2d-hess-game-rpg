extends UnboundTest

## The "Chơi thử" (things to try) of docs/OWNER_GUIDE.md section 7, done in the rooms the build has today,
## in the order the guide gives them, so that every step the owner is told to try can actually be done.
## (The first version of those steps asked for things the rooms cannot do: a death in T1, a gate in Stage 1,
## a spear no pawn can reach, a way back no pawn could walk.)
##
## One continuous play-through of the real scene, the real bridges and a throwaway save, from a clean save:
##   - the hero MOVES only by tapping arrow keys along a path (Support.walk_to_cell / walk_through_door):
##     through every door, in both directions, and onto the sword in T2;
##   - the hero brings a pawn down only with the SWORD, by the real input path (Support.kill_with_sword: walk
##     beside it, push toward it to face it, press the attack key until it falls). A pawn the sword cannot reach
##     (not in the grid, walled in) fails the step, which a damage request never did: T4's Backstep Pawn stood on
##     a wall cell for the whole of M3b and this suite, killing it with a request, passed;
##   - where the guide says "let the pawn hit you" (step 1) or "let the guard pick it up" (step 4) the REAL enemy
##     AI runs and the test waits for it. The ONE stand-in left is the wound of step 3: "take a wound" is a one
##     point hit on the hero (Support.damage_player), because letting one of T4's three awake pawns land exactly
##     one blow is a matter of timing, not of the rooms. To keep the other rooms quiet while the hero crosses
##     them, the enemy AI is removed in steps 2 and 3 (the pieces stand still and are hit by the sword).
##
##   Step 1  dying and rising again       T3: walk up to the pawn, stand still; R does the same
##   Step 2  a cleared room stays clear   the sword clears T3; T3 empty after a trip and after R; T4, left uncleared, comes back whole
##   Step 3  a checkpoint refills         wounded in T4, still wounded after a trip to T3 and back, the sword clears T4, full again at B1's door
##   Step 4  a floor weapon goes home     B1: a guard takes the Ruler Blade; R: it is on the floor again
##   Step 5  quit and open again          the last SAVE's room, not the last room walked into
##
## The steps run in the order the guide gives them and each can be done from the state the one before left, on a
## save that was clean at the start. (The first version of the guide said "do step 3 again from T3", which is
## impossible once step 2 has cleared T3: a cleared room is empty for good, D-17.)

const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "owner_guide_steps"

const T1 := &"t1_white_kings_fall"
const T2 := &"t2_fallen_sword_tile"
const T3 := &"t3_first_pawn_clash"
const T4 := &"t4_broken_rule_yard"
const B1 := &"b1_black_pawn_captain"

## Every reason the run was saved for, in order.
var saved_reasons: Array[StringName] = []


func _init() -> void:
	suite_title = "OWNER GUIDE STEPS TEST"
	watchdog_seconds = 58.0
	call_deferred("_run")


func _run() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	save_service.autosaved.connect(func(_slot: int, reason: StringName) -> void: saved_reasons.append(reason))
	var main := await Support.boot_main(self)
	var max_courage := Support.player_health(main).max_value
	var run := Support.run_of(save_service)

	# --- The way there: T1, T2 (the sword), T3 ---
	_expect(await Support.walk_through_door(self, main, T2), "setup: the hero walks T1 -> T2")
	var sword_cell := _cell_of_the_unlock(main)
	_expect(await Support.walk_to_cell(self, main, sword_cell) and Support.player_combat(main).sword_unlocked, "setup: and walks onto the glowing sword in T2 and takes it")
	_expect(saved_reasons == [&"unlock_gained"], "setup: taking the sword is a success event and saves (%s)" % [saved_reasons])
	_expect(await Support.walk_through_door(self, main, T3), "setup: the hero walks T2 -> T3")
	var t3_entry := Support.entry_cell(main, main.get("current_room"), &"west_entry")
	_expect(main.get("current_zone_id") == T3 and Support.player_cell(main) == t3_entry and Support.total_enemies(main) == 1, "setup: the hero stands on T3's west entry with its one pawn alive")

	# --- Step 1: dying and rising again ---
	var t3_idle_seconds := 0.0
	while t3_idle_seconds < 8.0:
		Support.pump(main, 0.5)
		t3_idle_seconds += 0.5
	_expect(not Support.room_ending(main) and Support.player_health(main).current == max_courage, "step 1: standing still on the entry of T3 is safe: the pawn does not come looking (so the guide says to walk up to it)")
	var pawn_id: int = main.get("cast")["enemies"][0]
	var pawn_cell: Vector2i = (Support.ecs_of(main).get_component(pawn_id, EcsComponents.GRID_POS) as EcsComponents.GridPos).cell
	await Support.walk_to_cell(self, main, pawn_cell + Vector2i.LEFT)
	saved_reasons.clear()
	var seconds_to_fall := 0.0
	while not Support.room_ending(main) and seconds_to_fall < 30.0:
		Support.pump(main, 0.5)
		seconds_to_fall += 0.5
	_expect(Support.room_ending(main) and Support.player_health(main).current == 0, "step 1: next to the pawn, standing still, the hero is struck down (%.1f s)" % seconds_to_fall)
	_expect(await Support.wait_for_respawn(self, main), "step 1: and about a second later the room starts again")
	_expect(main.get("current_zone_id") == T3 and Support.player_cell(main) == t3_entry, "step 1: in T3, on the entry the hero walked in by")
	_expect(Support.player_health(main).current == max_courage and Support.hud_courage_pips(main) == max_courage, "step 1: with full Courage, on the HUD too")
	_expect(Support.total_enemies(main) == 1 and _all_enemies_are_whole(main) and Support.player_combat(main).sword_unlocked, "step 1: the pawn is whole and the sword is still in the hand")
	_expect(saved_reasons.is_empty(), "step 1: the fall saved nothing")
	var world_after_the_fall := Support.ecs_of(main)
	await _choose_restart_room(main)
	_expect(Support.ecs_of(main) != world_after_the_fall and main.get("current_zone_id") == T3 and Support.player_cell(main) == t3_entry and Support.player_health(main).current == max_courage, "step 1: Restart Room in the pause menu does the same without falling")

	# --- Step 2: a cleared room stays clear, an uncleared one comes back whole ---
	Support.remove_enemy_ai(main)
	_expect(await Support.kill_with_sword(self, main, main.get("cast")["enemies"][0]), "step 2: the hero walks up to the T3 pawn and brings it down with the sword")
	_expect(run.cleared_room_ids.has(String(T3)) and saved_reasons.has(&"room_cleared"), "step 2: T3 is cleared and the clear is saved")
	_expect(await Support.walk_through_door(self, main, T4), "step 2: T3's east door is open now and the hero walks into T4")
	_expect(Support.total_enemies(main) == 3, "step 2: T4 has three pawns")
	_expect(await Support.walk_through_door(self, main, T3), "step 2: the hero walks back out of T4 by its west door")
	_expect(main.get("current_zone_id") == T3 and Support.total_enemies(main) == 0, "step 2: T3 is empty")
	await _choose_restart_room(main)
	_expect(main.get("current_zone_id") == T3 and Support.total_enemies(main) == 0 and run.cleared_room_ids.has(String(T3)), "step 2: and Restart Room in T3 does not bring the pawn back")
	_expect(await Support.walk_through_door(self, main, T4), "step 2: the hero goes into T4 again")
	Support.remove_enemy_ai(main)
	_expect(await Support.kill_with_sword(self, main, main.get("cast")["enemies"][0]), "step 2: the hero walks up to one of T4's three pawns and brings it down with the sword")
	_expect((main.get("hud") as GameHud).enemy_count.count_label.text == "ENEMIES 2/3" and not run.cleared_room_ids.has(String(T4)), "step 2: T4 is not cleared")
	_expect(await Support.walk_through_door(self, main, T3) and await Support.walk_through_door(self, main, T4), "step 2: the hero leaves T4 by its west door and comes back")
	_expect(Support.total_enemies(main) == 3 and _all_enemies_are_whole(main), "step 2: all three pawns are back, at full health")

	# --- Step 3: a checkpoint refills Courage, an ordinary door does not ---
	# The hero is in T4 with all three pawns alive (the end of step 2). The wound is the one stand-in of this suite.
	_expect(Support.total_enemies(main) == 3 and Support.player_health(main).current == max_courage, "step 3: the hero stands in T4 with its three pawns alive and full Courage")
	Support.damage_player(main, 1)
	Support.wait_out_invulnerability(main)
	_expect(Support.player_health(main).current == max_courage - 1 and Support.hud_courage_pips(main) == max_courage - 1, "step 3: wounded in T4 (a stand-in for a blow of one of its pawns): one pip is gone")
	_expect(await Support.walk_through_door(self, main, T3) and await Support.walk_through_door(self, main, T4), "step 3: the hero leaves T4 by its west door, into the empty T3, and comes back")
	Support.pump(main, 0.3)
	_expect(Support.player_health(main).current == max_courage - 1 and not run.has_checkpoint(), "step 3: an ordinary door heals nothing and neither T3 nor T4 is a checkpoint")
	_expect(Support.total_enemies(main) == 3, "step 3: T4's three pawns are back")
	Support.remove_enemy_ai(main)
	for index in range(3):
		_expect(await Support.kill_with_sword(self, main, main.get("cast")["enemies"][index]), "step 3: the hero's sword brings down T4's pawn number %d" % [index + 1])
	_expect(run.cleared_room_ids.has(String(T4)), "step 3: the three pawns of T4 are down and T4 is cleared")
	saved_reasons.clear()
	_expect(await Support.walk_through_door(self, main, B1), "step 3: the hero walks across T4 and through its east door into B1")
	Support.pump(main, 0.3)
	_expect(main.get("current_zone_id") == B1 and Support.player_health(main).current == max_courage and Support.hud_courage_pips(main) == max_courage, "step 3: B1's door is a checkpoint: Courage is full again, pips included")
	_expect(run.checkpoint_zone_id == B1 and run.checkpoint_entry_id == &"west_entry" and saved_reasons.has(&"checkpoint_reached"), "step 3: the checkpoint is B1's west entry, and it was saved")

	# --- Step 4: the floor weapon of B1 goes home with the room ---
	var b1_entry := Support.player_cell(main)
	var weapons_held_at_the_start := _enemies_holding_a_weapon(main)
	_expect(Support.ecs_of(main).grid.get_item_cells().size() == 1 and weapons_held_at_the_start < Support.total_enemies(main), "step 4: the Ruler Blade lies on B1's floor and one piece of the room has no weapon in hand to take it (%d of %d hold their own)" % [weapons_held_at_the_start, Support.total_enemies(main)])
	var waited_for_the_blade := 0.0
	while Support.ecs_of(main).grid.get_item_cells().size() == 1 and waited_for_the_blade < 10.0 and not Support.room_ending(main):
		Support.pump(main, 0.25)
		waited_for_the_blade += 0.25
	_expect(Support.ecs_of(main).grid.get_item_cells().is_empty() and _enemies_holding_a_weapon(main) == weapons_held_at_the_start + 1, "step 4: standing on the entry, the hero watches a guard walk over and pick the blade up (%.1f s)" % waited_for_the_blade)
	await _choose_restart_room(main)
	_expect(main.get("current_zone_id") == B1 and Support.player_cell(main) == b1_entry and Support.player_health(main).current == max_courage, "step 4: Restart Room: B1 starts again, the hero on the entry it walked in by")
	_expect(Support.ecs_of(main).grid.get_item_cells().size() == 1 and _enemies_holding_a_weapon(main) == weapons_held_at_the_start, "step 4: the blade is on the floor again and the guard's hands are empty")
	_expect(Support.total_enemies(main) == 3 and _all_enemies_are_whole(main), "step 4: the boss and its two guards are whole")

	# --- Step 5: quit and open again: the room of the LAST SAVE ---
	saved_reasons.clear()
	Support.remove_enemy_ai(main)
	_expect(await Support.walk_through_door(self, main, T4) and await Support.walk_through_door(self, main, T3), "step 5: the hero walks back through the west doors of B1 and T4, into T3")
	_expect(saved_reasons.is_empty() and run.room_id == T3, "step 5: two ordinary trips saved nothing; the run is in T3 in memory only")
	main.free()
	Support.forget_the_run(save_service)
	var relaunched := await Support.boot_main(self)
	run = Support.run_of(save_service)
	_expect(relaunched.get("current_zone_id") == B1 and Support.player_cell(relaunched) == b1_entry, "step 5: after quitting and opening again the game is in B1, on its entry: the room of the last save, not the last room walked into")
	_expect(Support.player_health(relaunched).current == max_courage and Support.player_combat(relaunched).sword_unlocked, "step 5: with full Courage and the sword in the hand")
	_expect(run.cleared_room_ids.has(String(T3)) and run.cleared_room_ids.has(String(T4)) and run.checkpoint_zone_id == B1, "step 5: T3 and T4 are still cleared and B1 is still the checkpoint")
	await Support.travel_to(relaunched, T3, &"west_entry")
	_expect(Support.total_enemies(relaunched) == 0, "step 5: and T3 is still empty")

	Support.end_suite(self, save_service)


## The cell of the first unlock marker of the room (the sword in T2).
func _cell_of_the_unlock(main: Node) -> Vector2i:
	var cells: Array = Support.ecs_of(main).grid.player_unlock_by_cell.keys()
	return cells[0] if not cells.is_empty() else Vector2i(-999, -999)


func _all_enemies_are_whole(main: Node) -> bool:
	for enemy_id: int in main.get("cast")["enemies"]:
		var health: EcsComponents.Health = Support.ecs_of(main).get_component(enemy_id, EcsComponents.HEALTH)
		if health == null or health.current != health.max_value:
			return false
	return true


func _enemies_holding_a_weapon(main: Node) -> int:
	var holding := 0
	for enemy_id: int in main.get("cast")["enemies"]:
		var slot: EcsComponents.WeaponSlot = Support.ecs_of(main).get_component(enemy_id, EcsComponents.WEAPON_SLOT)
		if slot != null and slot.weapon != null:
			holding += 1
	return holding


## Restart Room from the pause menu (the guide says "Esc, Restart Room", D-18), and the wait for the room to be rebuilt.
func _choose_restart_room(main: Node) -> void:
	var world_before := Support.ecs_of(main)
	Support.restart_room_from_the_menu(main)
	await Support.wait_for_respawn(self, main)
	_expect(Support.ecs_of(main) != world_before, "Restart Room rebuilt the room")
