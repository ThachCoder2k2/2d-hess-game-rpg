extends UnboundTest

## The PlayerSnapshot in the zone swap (docs/game-base-plan.md 14.2, M3b step 3): two swaps in a row through
## real exits, with the table of 14.2 checked row by row against the hero that arrives.
##   carried: Courage (current and max), the unlocked sword, the world's flags and counters;
##   per-room, so reset by the swap: the skill cooldown and the swing, the invulnerability window, the facing
##   (the entry's room sets it, so it is never restored by a swap).
## A swap carries the pawn as it was when the trip began (a hit during the fade-out reaches only the old world:
## test_bridge_health_carry pins that), and the carry is gone once the new world has it. A death starts the
## room again with full Courage but keeps what is persistent: the flags, the unlocks.

const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "carry_zone_swaps"

const T1 := &"t1_white_kings_fall"
const T2 := &"t2_fallen_sword_tile"
const T3 := &"t3_first_pawn_clash"


func _init() -> void:
	suite_title = "PLAYER CARRY ZONE SWAPS TEST"
	call_deferred("_run")


func _run() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	var main := await Support.boot_main(self)
	var max_courage := Support.player_health(main).max_value
	var facing_at_launch: Vector2i = (Support.ecs_of(main).get_component(Support.player_id_of(main), EcsComponents.FACING) as EcsComponents.Facing).direction

	# --- Set the pawn up in T1: wounded, with flags, mid-cooldown ---
	Support.damage_player(main, 2)
	Support.wait_out_invulnerability(main)
	Support.ecs_of(main).push_command(Commands.set_flag(&"beat.intro seen", true))
	Support.ecs_of(main).push_command(Commands.set_flag(&"child.trust", 2))
	Support.pump(main, Support.SIM_STEP_SECONDS)
	var combat := Support.player_combat(main)
	combat.skill_cooldown_left = 50.0
	combat.attack_on_cooldown = true
	_expect(Support.player_health(main).current == max_courage - 2 and not combat.sword_unlocked, "setup: the pawn is down to 1 Courage in T1, without the sword, in the middle of a cooldown")

	# --- Swap 1: T1 -> T2 ---
	_expect(await Support.walk_through_exit(self, main, T2, Vector2i.RIGHT), "swap 1: the pawn walks through T1's exit to T2")
	var health := Support.player_health(main)
	_expect(health.current == max_courage - 2 and health.max_value == max_courage, "Courage, current and max, is carried")
	_expect(Support.ecs_of(main).flags.get_flag(&"beat.intro seen") == true and Support.ecs_of(main).flags.get_flag(&"child.trust") == 2, "the flags and counters are carried")
	_expect(Support.health_carry(main) == -1, "the carry is gone once the new world has it")
	combat = Support.player_combat(main)
	_expect(is_zero_approx(combat.skill_cooldown_left) and not combat.attack_on_cooldown and combat.active_attack == null and combat.pending_cells.is_empty(), "the skill cooldown and the swing are per-room: the new pawn starts with none")
	_expect(is_zero_approx(health.invulnerable_left) and is_zero_approx(health.flash_left), "so is the invulnerability window")
	var facing_after_swap: Vector2i = (Support.ecs_of(main).get_component(Support.player_id_of(main), EcsComponents.FACING) as EcsComponents.Facing).direction
	_expect(facing_after_swap == facing_at_launch and facing_after_swap != Vector2i.RIGHT, "and so is the facing (the pawn stepped RIGHT through the door): a swap does not restore it, the room's entry sets it")
	_expect(Support.hud_courage_pips(main) == max_courage - 2, "the HUD shows the carried Courage")

	# --- In T2 the pawn finds the sword and changes a counter ---
	var sword_cell: Vector2i = Support.ecs_of(main).grid.player_unlock_by_cell.keys()[0]
	Support.teleport_player(main, sword_cell + Vector2i.LEFT)
	Support.step_player(main, Vector2i.RIGHT)
	_expect(Support.player_combat(main).sword_unlocked, "setup: the pawn picked up the wooden sword in T2")
	Support.ecs_of(main).push_command(Commands.set_flag(&"child.trust", 3))
	Support.pump(main, Support.SIM_STEP_SECONDS)
	Support.player_combat(main).skill_cooldown_left = 50.0

	# --- Swap 2: T2 -> T3, looked at while the fade-out is still running ---
	var door := Support.exit_cell(main, main.get("current_room"), T3)
	Support.teleport_player(main, door + Vector2i.LEFT)
	var intent: EcsComponents.MoveIntent = Support.ecs_of(main).get_component(Support.player_id_of(main), EcsComponents.MOVE_INTENT)
	intent.direction = Vector2i.RIGHT
	_expect(Support.pump_until(main, func() -> bool: return Support.travel_in_progress(main), 1.0), "swap 2: the pawn steps onto T2's exit")
	var carried: PlayerSnapshot = main.get("zone_travel_bridge").carried_player_snapshot
	_expect(carried != null and carried.courage_current == max_courage - 2 and carried.courage_max == max_courage, "mid-trip the bridge holds a PlayerSnapshot of the pawn as the trip began: Courage")
	_expect(carried != null and carried.unlocked_skill_ids == [PlayerSnapshot.SWORD_UNLOCK_ID] and carried.flags.get("child.trust") == 3, "its unlocked skills and flags")
	await Support.wait_for_travel(self, main)
	_expect(main.get("current_zone_id") == T3, "the second swap reached T3")
	health = Support.player_health(main)
	combat = Support.player_combat(main)
	_expect(health.current == max_courage - 2 and health.max_value == max_courage, "after two swaps in a row Courage is still the same 1 of 3: travel never heals")
	_expect(combat.sword_unlocked, "the sword found in T2 is in the hand that arrives in T3")
	_expect(Support.ecs_of(main).flags.get_flag(&"child.trust") == 3 and Support.ecs_of(main).flags.get_flag(&"beat.intro seen") == true, "the flags carry through both swaps, the counter at the value it had last")
	_expect(is_zero_approx(combat.skill_cooldown_left) and (Support.ecs_of(main).get_component(Support.player_id_of(main), EcsComponents.FACING) as EcsComponents.Facing).direction == facing_at_launch, "the per-room rows are fresh again")
	_expect(Support.health_carry(main) == -1 and Support.hud_courage_pips(main) == max_courage - 2, "the carry is consumed again, and the HUD shows the Courage")

	# --- A death keeps what is persistent and gives back what is not ---
	Support.damage_player(main, 99)
	_expect(await Support.wait_for_respawn(self, main), "the pawn falls in T3 and the room starts again")
	_expect(Support.player_health(main).current == max_courage, "with full Courage: a rebuild carries no Courage")
	_expect(Support.player_combat(main).sword_unlocked and Support.ecs_of(main).flags.get_flag(&"child.trust") == 3, "but the sword and the flags, which are persistent, are still the pawn's")

	Support.end_suite(self, save_service)
