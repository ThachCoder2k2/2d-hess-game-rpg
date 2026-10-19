extends UnboundTest

## Stage 1 can be played from the first room to the hub by a player, which is what no suite checked before the second
## review of M3b: an independent verifier found that T4 could never be cleared (its Backstep Pawn stood on a wall
## cell, out of the sword's reach), so its east door never opened and nobody could reach B1 or H1, while every suite
## went green. test_bridge_backtracking walks the other way (H1 back to T1), and test_owner_guide_steps stops at B1.
##
## One continuous run of the real scene, the real bridges and a throwaway save, from a clean save, as a player does it:
## the hero walks by key presses (Support.walk_through_door, walk_to_cell), takes the sword in T2, and in T3, T4 and B1
## brings every piece down with the sword (Support.kill_with_sword: walk beside it, face it, press attack), then walks
## through the east door the clear opened. Nothing is teleported, no trip is asked for by name and no damage request
## stands in for a stroke. The enemy AI is removed in each room so that the run does not depend on the timing of
## blows (test_owner_guide_steps lets the real AI fight in T3 and B1).

const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "route_on_foot"

const T1 := &"t1_white_kings_fall"
const T2 := &"t2_fallen_sword_tile"
const T3 := &"t3_first_pawn_clash"
const T4 := &"t4_broken_rule_yard"
const B1 := &"b1_black_pawn_captain"
const H1 := &"h1_chess_rug_hub"

## zone -> the zone its east door leads to, in the order a player meets them after the sword.
const NEXT_ROOM_AFTER_THE_FIGHT := {T3: T4, T4: B1, B1: H1}


func _init() -> void:
	suite_title = "BRIDGE ROUTE ON FOOT TEST"
	watchdog_seconds = 58.0
	call_deferred("_run")


func _run() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	var main := await Support.boot_main(self)
	var run := Support.run_of(save_service)
	_expect(main.get("current_zone_id") == T1, "setup: a clean save starts in T1")

	_expect(await Support.walk_through_door(self, main, T2) and main.get("current_zone_id") == T2, "T1 -> T2 on foot")
	var sword_cell: Vector2i = Support.ecs_of(main).grid.player_unlock_by_cell.keys()[0]
	var skill_slot := (main.get("hud") as GameHud).skill_label
	_expect(skill_slot.text == "FIND SWORD", "T2: before the sword the skill slot says to find it")
	_expect(await Support.walk_to_cell(self, main, sword_cell) and Support.player_combat(main).sword_unlocked, "T2: the hero walks onto the sword and takes it")
	Support.pump(main, 0.1)
	_expect(skill_slot.text == "Q THRUST READY", "T2: and the skill slot reads ready at once, not after the next room or the first swing")
	_expect(await Support.walk_through_door(self, main, T3) and main.get("current_zone_id") == T3, "T2 -> T3 on foot")

	for zone: StringName in NEXT_ROOM_AFTER_THE_FIGHT:
		Support.remove_enemy_ai(main)
		var enemy_count := Support.total_enemies(main)
		_expect(main.get("current_zone_id") == zone and enemy_count >= 1, "%s: the hero stands in the room with %d piece(s) alive" % [zone, enemy_count])
		var fallen := 0
		for index in range(enemy_count):
			if await Support.kill_with_sword(self, main, main.get("cast")["enemies"][index]):
				fallen += 1
		_expect(fallen == enemy_count, "%s: the sword brings down all %d (%d fell)" % [zone, enemy_count, fallen])
		_expect(run.cleared_room_ids.has(String(zone)), "%s: the room is cleared" % zone)
		var next_zone: StringName = NEXT_ROOM_AFTER_THE_FIGHT[zone]
		_expect(await Support.walk_through_door(self, main, next_zone) and main.get("current_zone_id") == next_zone, "%s -> %s on foot: the door the clear opened" % [zone, next_zone])

	_expect(main.get("current_zone_id") == H1, "the run ends in the hub")
	Support.end_suite(self, save_service)
