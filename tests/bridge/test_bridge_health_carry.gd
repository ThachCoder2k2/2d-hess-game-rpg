extends UnboundTest

## Bridge characterization (M1a, ported in M3b): the Courage carried across zone changes.
## ZoneTravelBridge.travel_to (it was main._travel_to) captures the hero when the trip starts (a PlayerSnapshot
## since M3b step 3; it was the integer player_health_carry), and GameRoot.boot_zone (it was main._boot_zone)
## has EcsBoot apply it to the freshly spawned player and then the bridge forgets it. This suite pins that
## contract, including its sharp edges, because the game_root.gd split (M3b step 2) moved exactly this
## write/apply/consume ordering. test_player_carry_zone_swaps holds the rest of what the snapshot carries.

const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "health_carry"

const T1 := &"t1_white_kings_fall"
const T2 := &"t2_fallen_sword_tile"
const T3 := &"t3_first_pawn_clash"

func _init() -> void:
	suite_title = "BRIDGE HEALTH CARRY TEST"
	call_deferred("_run")


func _run() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	var main := await Support.boot_main(self)
	var max_courage := Support.player_health(main).max_value
	_expect(max_courage == 3 and Support.player_health(main).current == max_courage, "boot starts the hero at full courage")

	# --- A full-health hero crosses a door at full health ---
	var health_before_trip := Support.player_health(main).current
	_expect(await Support.walk_through_exit(self, main, T2, Vector2i.RIGHT), "T1 -> T2 through the real exit")
	_expect(Support.player_health(main).current == health_before_trip, "health after the trip equals health before it (full)")
	_expect(Support.health_carry(main) == -1, "the carry is consumed after the full-health trip")

	# --- A wounded hero keeps the wound across two consecutive doors ---
	Support.damage_player(main, 2)
	_expect(Support.player_health(main).current == 1, "setup: a strike of 2 leaves 1 courage")
	Support.wait_out_invulnerability(main)
	health_before_trip = Support.player_health(main).current
	var door_to_t3 := Support.exit_cell(main, main.get("current_room"), T3)
	Support.teleport_player(main, door_to_t3 + Vector2i.LEFT)
	var intent: EcsComponents.MoveIntent = Support.ecs_of(main).get_component(Support.player_id_of(main), EcsComponents.MOVE_INTENT)
	intent.direction = Vector2i.RIGHT
	Support.pump_until(main, func() -> bool: return Support.travel_in_progress(main), 1.0)
	_expect(Support.health_carry(main) == health_before_trip, "mid-trip the carry equals the health before travel")
	await Support.wait_for_travel(self, main)
	_expect(main.get("current_zone_id") == T3, "T2 -> T3 through the real exit")
	_expect(Support.player_health(main).current == health_before_trip, "carried health equals health before travel (wounded)")
	_expect(Support.health_carry(main) == -1, "the carry is consumed after the wounded trip")
	_expect(Support.hud_courage_pips(main) == health_before_trip, "the HUD courage matches the carried health")

	await Support.travel_to(main, T2, &"from_t3")
	_expect(main.get("current_zone_id") == T2, "T3 -> T2 through the bridge entry point")
	_expect(Support.player_health(main).current == health_before_trip, "a second hop keeps the same health (travel never heals)")
	_expect(Support.health_carry(main) == -1, "the carry is consumed again after the second hop")

	# --- A plain re-boot with no pending carry restores full health ---
	# (T2 has no enemies, so re-booting its already-booted node is safe here.)
	Support.reboot_zone(main, &"west_entry")
	_expect(Support.player_health(main).current == max_courage, "CHARACTERIZATION: boot_zone without a pending carry heals to full (health only survives via travel)")

	# --- Carry edge values, applied by a plain boot_zone ---
	Support.plant_health_carry(main, 99)
	Support.reboot_zone(main, &"west_entry")
	_expect(Support.player_health(main).current == max_courage, "a carry above max is clamped to max courage")
	_expect(Support.health_carry(main) == -1, "the clamped carry is consumed too")
	Support.plant_health_carry(main, 2)
	Support.reboot_zone(main, &"west_entry")
	_expect(Support.player_health(main).current == 2 and Support.hud_courage_pips(main) == 2, "a pending carry of 2 is applied and the HUD follows")
	Support.plant_health_carry(main, 0)
	Support.reboot_zone(main, &"west_entry")
	_expect(Support.player_health(main).current == max_courage, "CHARACTERIZATION: a carry of 0 is not applied (only a carry above 0 counts)")
	_expect(Support.health_carry(main) == -1, "a carry of 0 is consumed too")

	# --- CHARACTERIZATION: the carry is a snapshot taken when the trip starts ---
	# A hit that lands during the fade-out reaches only the old world's hero; the
	# new hero boots with the health recorded at travel start.
	_expect(Support.player_health(main).current == max_courage, "setup: the hero starts the snapshot trip at full courage")
	var door_again := Support.exit_cell(main, main.get("current_room"), T3)
	Support.teleport_player(main, door_again + Vector2i.LEFT)
	var snapshot_intent: EcsComponents.MoveIntent = Support.ecs_of(main).get_component(Support.player_id_of(main), EcsComponents.MOVE_INTENT)
	snapshot_intent.direction = Vector2i.RIGHT
	Support.pump_until(main, func() -> bool: return Support.travel_in_progress(main), 1.0)
	_expect(Support.health_carry(main) == max_courage, "the snapshot trip recorded a full-health carry")
	Support.damage_player(main, 1)
	_expect(Support.player_health(main).current == max_courage - 1, "setup: the old world's hero took a hit during the fade-out")
	await Support.wait_for_travel(self, main)
	_expect(main.get("current_zone_id") == T3, "setup: the snapshot trip reached T3")
	_expect(Support.player_health(main).current == max_courage, "CHARACTERIZATION: a hit taken after travel started is not carried (the start-of-trip snapshot wins)")

	# --- Health is never written to disk ---
	Support.damage_player(main, 1)
	var wounded_courage := Support.player_health(main).current
	_expect(wounded_courage == max_courage - 1, "setup: the hero is wounded when the run is saved")
	Support.write_the_run(save_service)
	var saved := Support.read_save_file(save_service)
	var mentions_current_health := false
	for section in saved.get_sections():
		for key in saved.get_section_keys(section):
			if key.contains("health") or key.contains("carry") or key == "courage_current":
				mentions_current_health = true
	_expect(not saved.get_sections().is_empty() and not mentions_current_health, "the save file stores no health or carry (every launch starts the zone fresh); Courage max is saved, current Courage is not")
	# A relaunch: the saved run is continued by a brand new main, and the hero starts it at full courage.
	main.free()
	Support.forget_the_run(save_service)
	var relaunched := await Support.boot_main(self)
	_expect(Support.health_carry(relaunched) == -1 and Support.player_health(relaunched).current == max_courage, "a save/load round trip leaves no carry behind: the relaunched hero starts at full courage")

	Support.end_suite(self, save_service)
