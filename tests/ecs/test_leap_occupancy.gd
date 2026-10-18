extends UnboundTest

## A leap's occupancy (docs/game-base-plan.md 5.11, ledger req 9, 15 M3a): a step holds BOTH of its cells
## until it lands (the origin stays occupied, the destination is reserved), and a leap does not. At takeoff
## EcsGrid.begin_leap lets go of the origin and reserves the landing cell; while it is in the air the piece
## stands on no cell, so nothing aimed at a cell finds it, and nobody can take its landing cell; at
## touchdown (finish_leap) it stands on the cell it reserved. No skill uses it yet (Rule Step, M7a, and
## the Knight's leap, M8a, are the first); this suite is what they stand on.

const FROM := Vector2i(2, 4)
const TO := Vector2i(4, 5)


func _init() -> void:
	suite_title = "LEAP OCCUPANCY TEST"
	_check_a_step_holds_both_cells_as_it_always_did()
	_check_takeoff()
	_check_nobody_takes_the_landing_cell_and_anybody_takes_the_origin()
	_check_an_airborne_piece_cannot_do_anything_else()
	_check_touchdown()
	_check_what_a_takeoff_refuses()
	_check_a_piece_that_falls_in_the_air()
	_check_what_a_leap_may_pass_over()
	_check_the_pathfinder_around_a_leap()
	_check_untargetable_in_flight()
	_check_the_books_balance_through_random_play()
	finish()


func _board_with_leaper() -> EcsGrid:
	var grid := EcsGrid.new()
	grid.register_entity(1, FROM)
	return grid


func _check_a_step_holds_both_cells_as_it_always_did() -> void:
	var grid := _board_with_leaper()
	grid.begin_move(1, FROM + Vector2i.RIGHT)
	_expect(grid.entity_at(FROM) == 1 and grid.get_reserved_cell(1) == FROM + Vector2i.RIGHT and grid.cell_by_entity[1] == FROM, "a step holds its origin (occupied) and its destination (reserved) until it lands")
	_expect(not grid.can_begin_move(2, FROM) and not grid.can_begin_move(2, FROM + Vector2i.RIGHT), "so nobody can enter either cell")


func _check_takeoff() -> void:
	var grid := _board_with_leaper()
	var version_before := grid.layout_version
	_expect(grid.can_begin_leap(1, FROM, TO), "a piece standing on a cell may take off for any free walkable cell of the board, however far")
	_expect(grid.begin_leap(1, FROM, TO), "takeoff is accepted")
	_expect(grid.entity_at(FROM) == 0, "the origin is released at takeoff: nobody stands there")
	_expect(grid.entity_at(TO) == 0, "and nobody stands on the landing cell yet: the piece is in the air")
	_expect(grid.get_reserved_cell(1) == TO and grid.move_reservations.get(TO) == 1 and grid.move_reservations.size() == 1, "the landing cell is reserved for it, and it holds nothing else")
	_expect(grid.is_airborne(1) and grid.leap_landing_cell(1) == TO and grid.leap_by_entity[1] == {"from": FROM, "to": TO}, "the grid knows it is in the air, where from and where to")
	_expect(not grid.cell_by_entity.has(1) and grid.entity_by_cell.is_empty(), "it stands on no cell: it is in neither index")
	_expect(grid.get_occupied_cells().is_empty() and grid.get_reservation_cells() == [TO], "the occupied cells are none and the reserved cells are the landing cell")
	_expect(grid.layout_version == version_before, "a leap is not a change of the terrain")
	_expect(not grid.is_airborne(2) and grid.leap_landing_cell(2) == EcsGrid.NO_CELL, "a piece that never took off is not in the air and has no landing cell")


func _check_nobody_takes_the_landing_cell_and_anybody_takes_the_origin() -> void:
	var grid := _board_with_leaper()
	grid.begin_leap(1, FROM, TO)
	_expect(not grid.can_begin_move(2, TO) and not grid.register_entity(2, TO), "nobody can step onto, or be placed on, the landing cell while the leaper is in the air")
	grid.register_entity(3, TO + Vector2i.LEFT)
	_expect(not grid.begin_move(3, TO), "a neighbour cannot reserve it")
	grid.register_entity(4, Vector2i(6, 6))
	_expect(not grid.can_begin_leap(4, Vector2i(6, 6), TO) and not grid.begin_leap(4, Vector2i(6, 6), TO), "another leaper cannot land there either")
	_expect(not grid.add_block(TO) and not grid.set_cell_kind(TO, CellKinds.GAP), "no wall or gap grows on it")
	_expect(grid.set_cell_kind(TO, CellKinds.CHALK), "though chalk, which does not take the cell away, may")

	# The origin is free at once.
	_expect(grid.register_entity(5, FROM), "a piece can be placed on the cell the leaper left")
	grid.unregister_entity(5)
	grid.register_entity(6, FROM + Vector2i.LEFT)
	_expect(grid.begin_move(6, FROM) and grid.entity_at(FROM + Vector2i.LEFT) == 6, "or step onto it")
	grid.finish_move(6, FROM)
	_expect(grid.entity_at(FROM) == 6, "and holds it while the leaper is still in the air")


func _check_an_airborne_piece_cannot_do_anything_else() -> void:
	var grid := _board_with_leaper()
	grid.begin_leap(1, FROM, TO)
	_expect(not grid.can_begin_move(1, FROM + Vector2i.RIGHT) and not grid.begin_move(1, FROM + Vector2i.RIGHT), "a piece in the air cannot start a step")
	_expect(not grid.can_begin_leap(1, FROM, Vector2i(8, 8)) and not grid.begin_leap(1, TO, Vector2i(8, 8)), "or take off again, from where it left or from where it will land")
	_expect(grid.get_reserved_cell(1) == TO and grid.move_reservations.size() == 1, "and its one reservation is still the landing cell")
	_expect(not grid.finish_leap(2), "touching down is refused for a piece that never took off")


func _check_touchdown() -> void:
	var grid := _board_with_leaper()
	grid.begin_leap(1, FROM, TO)
	grid.register_entity(2, FROM)
	_expect(grid.finish_leap(1), "touchdown is accepted")
	_expect(grid.entity_at(TO) == 1 and grid.cell_by_entity[1] == TO, "the piece stands on the cell it reserved, in both indexes")
	_expect(grid.move_reservations.is_empty() and grid.leap_by_entity.is_empty() and not grid.is_airborne(1), "and the reservation and the leap are gone")
	_expect(grid.entity_at(FROM) == 2, "the piece that took the origin in the meantime is undisturbed")
	_expect(not grid.finish_leap(1), "touching down twice is refused")
	_expect(grid.can_begin_move(1, TO + Vector2i.RIGHT) and grid.begin_move(1, TO + Vector2i.RIGHT), "and a piece that has landed steps again")
	grid.finish_move(1, TO + Vector2i.RIGHT)
	_expect(grid.entity_at(TO + Vector2i.RIGHT) == 1 and grid.entity_at(TO) == 0, "as any piece does")

	# A leap there and back: the cells end as they began.
	var there_and_back := _board_with_leaper()
	there_and_back.begin_leap(1, FROM, TO)
	there_and_back.finish_leap(1)
	there_and_back.begin_leap(1, TO, FROM)
	there_and_back.finish_leap(1)
	_expect(there_and_back.entity_by_cell == {FROM: 1} and there_and_back.cell_by_entity == {1: FROM} and there_and_back.move_reservations.is_empty() and there_and_back.leap_by_entity.is_empty(), "a leap there and a leap back leave the grid exactly as it was")


func _check_what_a_takeoff_refuses() -> void:
	var cases: Array[Dictionary] = []
	var wall_board := _board_with_leaper()
	wall_board.set_cell_kind(TO, CellKinds.WALL)
	cases.append({"label": "a wall", "grid": wall_board, "entity": 1, "from": FROM, "to": TO})
	var gap_board := _board_with_leaper()
	gap_board.set_cell_kind(TO, CellKinds.GAP)
	cases.append({"label": "a gap (a leap crosses a gap, it cannot land in one)", "grid": gap_board, "entity": 1, "from": FROM, "to": TO})
	var block_board := _board_with_leaper()
	block_board.set_cell_kind(TO, CellKinds.LEAPABLE_BLOCK)
	cases.append({"label": "a leapable block", "grid": block_board, "entity": 1, "from": FROM, "to": TO})
	var occupied_board := _board_with_leaper()
	occupied_board.register_entity(2, TO)
	cases.append({"label": "a cell a piece stands on", "grid": occupied_board, "entity": 1, "from": FROM, "to": TO})
	var reserved_board := _board_with_leaper()
	reserved_board.register_entity(2, TO + Vector2i.UP)
	reserved_board.begin_move(2, TO)
	cases.append({"label": "a cell another piece has reserved", "grid": reserved_board, "entity": 1, "from": FROM, "to": TO})
	cases.append({"label": "a cell off the board", "grid": _board_with_leaper(), "entity": 1, "from": FROM, "to": Vector2i(16, 4)})
	cases.append({"label": "the cell it stands on", "grid": _board_with_leaper(), "entity": 1, "from": FROM, "to": FROM})
	cases.append({"label": "a takeoff from a cell it does not stand on", "grid": _board_with_leaper(), "entity": 1, "from": FROM + Vector2i.UP, "to": TO})
	cases.append({"label": "a piece that is not on the board", "grid": _board_with_leaper(), "entity": 9, "from": FROM, "to": TO})
	var stepping_board := _board_with_leaper()
	stepping_board.begin_move(1, FROM + Vector2i.LEFT)
	cases.append({"label": "a piece in the middle of a step", "grid": stepping_board, "entity": 1, "from": FROM, "to": TO})
	for case in cases:
		var grid: EcsGrid = case["grid"]
		var before := [grid.entity_by_cell.duplicate(), grid.cell_by_entity.duplicate(), grid.move_reservations.duplicate(), grid.leap_by_entity.duplicate()]
		var refused := not grid.begin_leap(case["entity"], case["from"], case["to"]) and not grid.can_begin_leap(case["entity"], case["from"], case["to"])
		var untouched := before == [grid.entity_by_cell, grid.cell_by_entity, grid.move_reservations, grid.leap_by_entity]
		_expect(refused and untouched, "a takeoff for %s is refused and changes nothing" % case["label"])
	var chalk_board := _board_with_leaper()
	chalk_board.set_cell_kind(TO, CellKinds.CHALK)
	_expect(chalk_board.begin_leap(1, FROM, TO), "but chalk and corruption can be landed on, being walkable")
	var corruption_board := _board_with_leaper()
	corruption_board.set_cell_kind(TO, CellKinds.CORRUPTION)
	_expect(corruption_board.begin_leap(1, FROM, TO), "(corruption too)")


func _check_a_piece_that_falls_in_the_air() -> void:
	var grid := _board_with_leaper()
	grid.begin_leap(1, FROM, TO)
	grid.register_entity(2, FROM)
	grid.unregister_entity(1)
	_expect(grid.move_reservations.is_empty() and grid.leap_by_entity.is_empty() and not grid.is_airborne(1), "a piece defeated in the air frees its landing cell and leaves no leap behind")
	_expect(grid.entity_at(FROM) == 2, "and does not take the origin's new occupant with it")
	_expect(grid.register_entity(3, TO), "the landing cell can be used again")

	var world := EcsWorld.new()
	world.grid.register_entity(world.create_entity(), FROM)
	var leaper := world.create_entity()
	world.grid.register_entity(leaper, Vector2i(7, 7))
	world.grid.begin_leap(leaper, Vector2i(7, 7), Vector2i(9, 7))
	world.destroy_entity(leaper)
	_expect(world.grid.move_reservations.is_empty() and world.grid.leap_by_entity.is_empty(), "destroying an entity in the air through the world does the same")
	world.free()


func _check_what_a_leap_may_pass_over() -> void:
	var grid := EcsGrid.new()
	var cells := {
		CellKinds.FLOOR: Vector2i(1, 1), CellKinds.WALL: Vector2i(2, 1), CellKinds.GAP: Vector2i(3, 1),
		CellKinds.LEAPABLE_BLOCK: Vector2i(4, 1), CellKinds.CHALK: Vector2i(5, 1), CellKinds.CORRUPTION: Vector2i(6, 1),
	}
	for kind: StringName in cells:
		grid.set_cell_kind(cells[kind], kind)
	_expect(grid.can_leap_over(cells[CellKinds.FLOOR]) and grid.can_leap_over(cells[CellKinds.GAP]) and grid.can_leap_over(cells[CellKinds.LEAPABLE_BLOCK]) and grid.can_leap_over(cells[CellKinds.CHALK]) and grid.can_leap_over(cells[CellKinds.CORRUPTION]), "a leap passes over floor, a gap, a leapable block, chalk and corruption")
	_expect(not grid.can_leap_over(cells[CellKinds.WALL]), "but not over a wall")
	grid.gate_by_cell[Vector2i(8, 1)] = {"id": &"shortcut", "opens_from": Vector2i.LEFT}
	grid.add_block(Vector2i(8, 1))
	_expect(not grid.can_leap_over(Vector2i(8, 1)), "nor over a closed gate, which is a wall")
	grid.open_gate(Vector2i(8, 1))
	_expect(grid.can_leap_over(Vector2i(8, 1)), "until it is opened")
	grid.exit_by_cell[Vector2i(0, 5)] = {"zone": &"t1", "entry": &"start"}
	_expect(not grid.can_leap_over(Vector2i(0, 5)), "nor over a door (an exit)")
	grid.register_entity(1, Vector2i(9, 2))
	_expect(grid.can_leap_over(Vector2i(9, 2)), "a piece does not stop a leap: it passes over it")
	_expect(not grid.can_leap_over(Vector2i(-1, 2)) and not grid.can_leap_over(Vector2i(16, 2)), "and there is nothing to leap over off the board")


## Other pieces plan around the leaper's landing cell (it is a reservation) and through its origin (it is
## free), which is the whole point of letting the origin go.
func _check_the_pathfinder_around_a_leap() -> void:
	var grid := EcsGrid.new()
	for row in range(0, 9):
		if row != 4:
			grid.add_block(Vector2i(3, row))
	grid.register_entity(1, Vector2i(3, 4))
	grid.register_entity(2, Vector2i(1, 4))
	_expect(grid.get_grid_path(2, Vector2i(1, 4), Vector2i(5, 4)).is_empty(), "setup: a wall with one doorway, and the doorway is held by a piece, so there is no way through")
	grid.begin_leap(1, Vector2i(3, 4), Vector2i(5, 3))
	var through := grid.get_grid_path(2, Vector2i(1, 4), Vector2i(5, 4))
	_expect(not through.is_empty() and Vector2i(3, 4) in through, "once the piece has leapt the doorway is free and the other piece plans through it (%s)" % [through])
	var to_landing := grid.get_grid_path(2, Vector2i(1, 4), Vector2i(5, 3))
	_expect(not to_landing.is_empty() and to_landing[to_landing.size() - 1] == Vector2i(5, 3), "a goal that is a reserved cell can still be the goal of a path (the grid has always allowed it)")
	var past_landing := grid.get_grid_path(2, Vector2i(1, 4), Vector2i(5, 2))
	_expect(not past_landing.is_empty() and Vector2i(5, 3) not in past_landing, "but no path goes through the landing cell (%s)" % [past_landing])


# --------------------------------------------------------------------------- untargetable
func _check_untargetable_in_flight() -> void:
	var world := EcsWorld.new()
	world.manual_tick = true
	root.add_child(world)
	world.add_system(HealthSystem.new())
	var definition := ContentDb.fetch(&"enemies", &"pawn_recruit") as EnemyDefinition
	var leaper := EcsActorFactory.spawn_enemy(world, definition, FROM)
	var health: EcsComponents.Health = world.get_component(leaper, EcsComponents.HEALTH)
	var starting_health := health.current
	_expect(starting_health >= 2, "setup: the leaper can take a blow and live (%d)" % starting_health)

	world.grid.begin_leap(leaper, FROM, TO)
	Events.emit_damage(world, leaper, 1, Vector2i.RIGHT, 0)
	world.tick(0.016)
	var events_in_flight := world.drain_events()
	_expect(health.current == starting_health and events_in_flight.is_empty(), "a blow aimed at a piece in the air changes nothing and says nothing")
	_expect(world.damage_events.is_empty(), "and the request was consumed, not left to land after the touchdown")

	world.grid.finish_leap(leaper)
	Events.emit_damage(world, leaper, 1, Vector2i.RIGHT, 0)
	world.tick(0.016)
	var damaged_after := world.drain_events().filter(func(event: Dictionary) -> bool: return event["type"] == Events.DAMAGED)
	_expect(health.current == starting_health - 1 and damaged_after.size() == 1, "the same blow after the touchdown lands: it is the flight that protects, nothing else")

	# What a strike finds is found by cell: the cells of a leap are empty for the whole of the flight.
	var strike_world := EcsWorld.new()
	var target := strike_world.create_entity()
	strike_world.grid.register_entity(target, FROM)
	strike_world.grid.begin_leap(target, FROM, TO)
	var cells_a_strike_could_hit: Array[Vector2i] = [FROM, TO, FROM + Vector2i.RIGHT, TO + Vector2i.LEFT]
	var found: Array[int] = []
	for cell in cells_a_strike_could_hit:
		found.append(strike_world.grid.entity_at(cell))
	_expect(found == [0, 0, 0, 0], "a strike that looks for who stands on the origin, the landing cell or the cells between finds nobody during the flight")
	strike_world.grid.finish_leap(target)
	_expect(strike_world.grid.entity_at(TO) == target, "and finds the piece again once it lands")
	world.queue_free()
	strike_world.free()


# --------------------------------------------------------------------------- the books balance
## 3000 random operations on six pieces (a fixed seed): place, step, finish a step, take off, land, remove,
## and put a wall or chalk down. After EVERY operation the indexes must agree: entity_by_cell and
## cell_by_entity are exact inverses; a piece is either standing (in both), stepping (in both, plus one
## reservation) or airborne (in neither, one reservation equal to its landing cell); no reservation belongs
## to anyone else; no piece stands in a blocked cell; no cell is both occupied and reserved.
func _check_the_books_balance_through_random_play() -> void:
	var grid := EcsGrid.new()
	var generator := RandomNumberGenerator.new()
	generator.seed = 20261019
	var steps_by_entity: Dictionary = {}
	var broken := ""
	var leaps_taken := 0
	var steps_taken := 0
	# The operations, with the weight each is given: placing and leaping are common so that the six pieces
	# are mostly on the board and mostly in the air or about to be.
	var operations: Array[int] = [0, 0, 0, 1, 1, 2, 2, 3, 3, 3, 3, 4, 4, 4, 5, 6, 7]
	for operation_index in range(3000):
		var entity_id := generator.randi_range(1, 6)
		var cell := Vector2i(generator.randi_range(0, 15), generator.randi_range(0, 8))
		match operations[generator.randi_range(0, operations.size() - 1)]:
			0:
				if not grid.cell_by_entity.has(entity_id) and not grid.is_airborne(entity_id):
					grid.register_entity(entity_id, cell)
			1:
				# Never a step onto the cell the piece already stands on: the game never asks for one.
				if not steps_by_entity.has(entity_id) and grid.cell_by_entity.get(entity_id, EcsGrid.NO_CELL) != cell and grid.begin_move(entity_id, cell):
					steps_by_entity[entity_id] = cell
					steps_taken += 1
			2:
				if steps_by_entity.has(entity_id):
					grid.finish_move(entity_id, steps_by_entity[entity_id])
					steps_by_entity.erase(entity_id)
			3:
				if grid.begin_leap(entity_id, grid.cell_by_entity.get(entity_id, EcsGrid.NO_CELL), cell):
					leaps_taken += 1
			4:
				grid.finish_leap(entity_id)
			5:
				grid.unregister_entity(entity_id)
				steps_by_entity.erase(entity_id)
			6:
				grid.set_cell_kind(cell, [CellKinds.WALL, CellKinds.GAP, CellKinds.CHALK, CellKinds.FLOOR][generator.randi_range(0, 3)])
			7:
				grid.set_cell_kind(cell, CellKinds.FLOOR)
		broken = _what_is_out_of_step(grid)
		if not broken.is_empty():
			broken = "after operation %d: %s" % [operation_index, broken]
			break
	_expect(broken.is_empty(), "after each of 3000 random operations the two indexes, the reservations and the leaps agree (%s)" % broken)
	_expect(leaps_taken >= 100 and steps_taken >= 50, "setup: the random play took %d leaps and %d steps, enough to mean something" % [leaps_taken, steps_taken])


## "" when the grid's books balance, else the first thing that does not.
func _what_is_out_of_step(grid: EcsGrid) -> String:
	for cell: Vector2i in grid.entity_by_cell:
		var occupant: int = grid.entity_by_cell[cell]
		if grid.cell_by_entity.get(occupant, EcsGrid.NO_CELL) != cell:
			return "entity_by_cell says %d stands on %s, cell_by_entity disagrees" % [occupant, cell]
		if grid.blocked_cells.has(cell):
			return "entity %d stands in the blocked cell %s" % [occupant, cell]
		if grid.move_reservations.has(cell):
			return "cell %s is occupied and reserved" % cell
	for entity_id: int in grid.cell_by_entity:
		if grid.entity_by_cell.get(grid.cell_by_entity[entity_id], 0) != entity_id:
			return "cell_by_entity says %d is on %s, entity_by_cell disagrees" % [entity_id, grid.cell_by_entity[entity_id]]
		if grid.leap_by_entity.has(entity_id):
			return "entity %d is both standing and in the air" % entity_id
	var reservations_explained := 0
	for reserved_cell: Vector2i in grid.move_reservations:
		var holder: int = grid.move_reservations[reserved_cell]
		if grid.leap_by_entity.has(holder):
			if grid.leap_by_entity[holder]["to"] != reserved_cell:
				return "airborne entity %d reserved %s but lands on %s" % [holder, reserved_cell, grid.leap_by_entity[holder]["to"]]
		elif not grid.cell_by_entity.has(holder):
			return "cell %s is reserved for entity %d, who is not on the board" % [reserved_cell, holder]
		if grid.blocked_cells.has(reserved_cell):
			return "the reserved cell %s is blocked" % reserved_cell
		reservations_explained += 1
	for entity_id: int in grid.leap_by_entity:
		if grid.get_reserved_cell(entity_id) != grid.leap_by_entity[entity_id]["to"]:
			return "airborne entity %d has not reserved its landing cell" % entity_id
	return "" if reservations_explained == grid.move_reservations.size() else "a reservation was not counted"
