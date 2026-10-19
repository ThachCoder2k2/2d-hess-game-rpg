extends UnboundTest

## Support.kill_with_sword is how the suites that follow a player bring a pawn down (walk beside it, face it, press
## the attack key). It exists because a damage request needs no cell: T4's Backstep Pawn stood on a wall cell, was
## never in the grid and could never be hit by a sword, and every suite that "killed" it with a request still
## passed. A helper that cannot say no would let that happen again, so this suite proves it says no:
##   - without the sword in the hand the hero cannot bring a pawn down (the attack key is locked);
##   - a pawn that is not in the grid cannot be reached (what a pawn parked on a wall cell is);
##   - a pawn walled in on four sides cannot be reached (no cell to strike from);
## and says yes, by the real input path, when the pawn is where a sword can reach it: the hero walks to the cell
## beside it, turns to face it and strikes until it falls, and the room is cleared by that.

const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "kill_with_sword"

const T3 := &"t3_first_pawn_clash"


func _init() -> void:
	suite_title = "KILL WITH SWORD TEST"
	call_deferred("_run")


func _run() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	var main := await Support.boot_main(self)
	await Support.travel_to(main, T3, &"west_entry")
	Support.remove_enemy_ai(main)
	var ecs := Support.ecs_of(main)
	var pawn_id: int = main.get("cast")["enemies"][0]
	var pawn_health: EcsComponents.Health = ecs.get_component(pawn_id, EcsComponents.HEALTH)
	var pawn_cell: Vector2i = ecs.grid.cell_by_entity[pawn_id]
	var entry_cell := Support.player_cell(main)
	_expect(Support.total_enemies(main) == 1 and not Support.player_combat(main).sword_unlocked, "setup: T3 holds its one pawn and the hero has no sword yet")

	_expect(not await Support.kill_with_sword(self, main, pawn_id), "no sword in the hand: the pawn cannot be brought down")
	_expect(pawn_health.current == pawn_health.max_value and Support.player_cell(main) == entry_cell, "and nothing happened: the pawn is whole and the hero has not moved")

	Support.give_the_sword(main, save_service)
	ecs.grid.unregister_entity(pawn_id)
	_expect(not await Support.kill_with_sword(self, main, pawn_id), "a pawn that is not in the grid cannot be reached (it is what a pawn parked on a wall cell is)")
	_expect(pawn_health.current == pawn_health.max_value and Support.player_cell(main) == entry_cell, "and the hero did not walk anywhere to look for it")
	_expect(ecs.grid.register_entity(pawn_id, pawn_cell), "setup: the pawn is put back on its cell")

	var walls: Array[Vector2i] = []
	for direction: Vector2i in Support.ACTION_BY_DIRECTION:
		walls.append(pawn_cell + direction)
		ecs.grid.add_block(pawn_cell + direction)
	_expect(not await Support.kill_with_sword(self, main, pawn_id), "a pawn walled in on four sides cannot be reached: there is no cell to strike from")
	_expect(pawn_health.current == pawn_health.max_value, "and it is whole")
	for wall_cell in walls:
		ecs.grid.set_cell_kind(wall_cell, CellKinds.FLOOR)

	_expect(await Support.kill_with_sword(self, main, pawn_id), "with the sword in the hand and the way open, the hero brings the pawn down")
	_expect(pawn_health.current == 0 and not ecs.grid.cell_by_entity.has(pawn_id), "by the sword: the pawn is down and has left the grid")
	_expect(Support.player_cell(main) != entry_cell and absi(Support.player_cell(main).x - pawn_cell.x) + absi(Support.player_cell(main).y - pawn_cell.y) == 1, "having walked to the cell beside where it stood")
	_expect(Support.run_of(save_service).cleared_room_ids.has(String(T3)), "and that cleared the room")

	Support.end_suite(self, save_service)
