extends UnboundTest

## The cached pathfinder (docs/game-base-plan.md 5.11, risk 15, 15 M3a): EcsGrid builds one AStarGrid2D per
## layout_version and a question only marks the pieces in the way solid for its own length, where it used to
## build a pathfinder per question (a pass over the whole board, a dozen times per enemy decision). Two
## things must hold: the answers are exactly the old answers, and the cache is rebuilt exactly when the
## layout changes. This suite holds the second by counting builds and the first by running the old code
## (tests/support/reference_pathing.gd) on the same board, question for question.

const ReferencePathing := preload("res://tests/support/reference_pathing.gd")


func _init() -> void:
	suite_title = "PATH CACHE TEST"
	_check_a_question_does_not_build_a_pathfinder()
	_check_the_cache_is_rebuilt_when_the_layout_changes()
	_check_pieces_do_not_dirty_the_cache()
	_check_a_question_leaves_the_pathfinder_as_it_found_it()
	_check_the_answers_are_the_old_answers()
	_check_it_is_faster_on_a_big_board()
	finish()


func _check_a_question_does_not_build_a_pathfinder() -> void:
	var grid := EcsGrid.new()
	_expect(grid.pathfinder_build_count == 0, "a grid nobody asked builds no pathfinder")
	grid.add_block(Vector2i(5, 4))
	grid.register_entity(1, Vector2i(2, 4))
	grid.get_grid_path(1, Vector2i(2, 4), Vector2i(8, 4))
	_expect(grid.pathfinder_build_count == 1, "the first question builds one")
	for question in range(200):
		grid.get_grid_path(1, Vector2i(2, 4), Vector2i(8, question % 9))
		grid.get_path_distance(1, Vector2i(2, 4), Vector2i(10, 2))
		grid.get_next_path_cell(1, Vector2i(2, 4), Vector2i(12, 7))
	_expect(grid.pathfinder_build_count == 1, "and 600 more questions build none: the walls did not change")
	_expect(grid.get_grid_path(1, Vector2i(-1, 4), Vector2i(8, 4)).is_empty() and grid.get_grid_path(1, Vector2i(2, 4), Vector2i(8, 40)).is_empty() and grid.pathfinder_build_count == 1, "a question with a cell off the board is answered empty without building anything")


func _check_the_cache_is_rebuilt_when_the_layout_changes() -> void:
	var grid := EcsGrid.new()
	grid.register_entity(1, Vector2i(1, 4))
	var straight := grid.get_grid_path(1, Vector2i(1, 4), Vector2i(6, 4))
	_expect(straight.size() == 6 and grid.pathfinder_build_count == 1, "setup: on an open board the way is straight (6 cells), from one pathfinder")

	grid.set_cell_kind(Vector2i(3, 4), CellKinds.WALL)
	var around := grid.get_grid_path(1, Vector2i(1, 4), Vector2i(6, 4))
	_expect(grid.pathfinder_build_count == 2 and Vector2i(3, 4) not in around and around.size() == 8, "a new wall rebuilds it on the next question, and the way goes round (8 cells)")

	grid.set_cell_kind(Vector2i(3, 4), CellKinds.WALL)
	grid.get_grid_path(1, Vector2i(1, 4), Vector2i(6, 4))
	_expect(grid.pathfinder_build_count == 2, "putting a wall where there already is one changes nothing and rebuilds nothing")

	grid.set_cell_kind(Vector2i(3, 4), CellKinds.GAP)
	grid.get_grid_path(1, Vector2i(1, 4), Vector2i(6, 4))
	_expect(grid.pathfinder_build_count == 3, "a wall that becomes a gap is a change of the layout and rebuilds")

	grid.set_cell_kind(Vector2i(3, 4), CellKinds.CHALK)
	var over_chalk := grid.get_grid_path(1, Vector2i(1, 4), Vector2i(6, 4))
	_expect(grid.pathfinder_build_count == 4 and over_chalk.size() == 6 and Vector2i(3, 4) in over_chalk, "chalk laid over the gap rebuilds it, and the way is straight again over the chalk")

	grid.gate_by_cell[Vector2i(4, 4)] = {"id": &"shortcut", "opens_from": Vector2i.LEFT}
	grid.add_block(Vector2i(4, 4))
	grid.get_grid_path(1, Vector2i(1, 4), Vector2i(6, 4))
	var builds_with_gate := grid.pathfinder_build_count
	grid.open_gate(Vector2i(4, 4))
	var through_gate := grid.get_grid_path(1, Vector2i(1, 4), Vector2i(6, 4))
	_expect(builds_with_gate == 5 and grid.pathfinder_build_count == 6 and through_gate.size() == 6, "a gate that opens rebuilds it, and the shortcut is used (6 cells)")

	grid.bounds = Rect2i(0, 0, 18, 9)
	var wider := grid.get_grid_path(1, Vector2i(1, 4), Vector2i(17, 4))
	_expect(grid.pathfinder_build_count == 7 and wider.size() == 17, "a bigger board rebuilds it, and a goal in the new columns can be reached (17 cells)")
	grid.bounds = Rect2i(0, 0, 8, 9)
	_expect(grid.get_grid_path(1, Vector2i(1, 4), Vector2i(17, 4)).is_empty() and grid.get_grid_path(1, Vector2i(1, 4), Vector2i(6, 4)).size() == 6 and grid.pathfinder_build_count == 8, "and a smaller one rebuilds it again: the columns that are gone are off the board")

	var refused := EcsGrid.new()
	refused.register_entity(1, Vector2i(2, 2))
	refused.get_grid_path(1, Vector2i(2, 2), Vector2i(5, 5))
	refused.add_block(Vector2i(2, 2))
	refused.set_cell_kind(Vector2i(30, 30), CellKinds.WALL)
	refused.get_grid_path(1, Vector2i(2, 2), Vector2i(5, 5))
	_expect(refused.pathfinder_build_count == 1, "a wall refused (a piece stands there, or the cell is off the board) is no change of the layout, so nothing is rebuilt")


func _check_pieces_do_not_dirty_the_cache() -> void:
	var grid := EcsGrid.new()
	grid.set_cell_kind(Vector2i(6, 3), CellKinds.WALL)
	grid.register_entity(1, Vector2i(1, 1))
	grid.register_entity(2, Vector2i(4, 1))
	grid.get_grid_path(1, Vector2i(1, 1), Vector2i(8, 1))
	var builds := grid.pathfinder_build_count
	grid.begin_move(2, Vector2i(4, 2))
	grid.get_grid_path(1, Vector2i(1, 1), Vector2i(8, 1))
	grid.finish_move(2, Vector2i(4, 2))
	grid.register_entity(3, Vector2i(5, 5))
	grid.begin_leap(3, Vector2i(5, 5), Vector2i(9, 5))
	grid.get_grid_path(1, Vector2i(1, 1), Vector2i(8, 1))
	grid.finish_leap(3)
	grid.unregister_entity(2)
	grid.get_grid_path(1, Vector2i(1, 1), Vector2i(8, 1))
	_expect(grid.pathfinder_build_count == builds, "pieces stepping, leaping, landing and leaving are not changes of the layout: the same pathfinder answers throughout")


## The pieces that were in the way for one question must not stay in the way for the next.
func _check_a_question_leaves_the_pathfinder_as_it_found_it() -> void:
	var grid := EcsGrid.new()
	for row in range(0, 9):
		if row != 4:
			grid.add_block(Vector2i(5, row))
	grid.register_entity(1, Vector2i(2, 4))
	grid.register_entity(2, Vector2i(5, 4))
	_expect(grid.get_grid_path(1, Vector2i(2, 4), Vector2i(8, 4)).is_empty(), "setup: a piece stands in the only doorway, so there is no way through")
	var pathfinder: AStarGrid2D = grid._pathfinder
	var solid_cells := 0
	for x in range(0, 16):
		for y in range(0, 9):
			if pathfinder.is_point_solid(Vector2i(x, y)):
				solid_cells += 1
	_expect(solid_cells == grid.blocked_cells.size() and not pathfinder.is_point_solid(Vector2i(5, 4)), "after the question the doorway is not solid in the kept pathfinder: only the %d walls are" % grid.blocked_cells.size())
	grid.unregister_entity(2)
	_expect(grid.get_grid_path(1, Vector2i(2, 4), Vector2i(8, 4)).size() == 7, "and when the piece leaves, the next question goes through the doorway (7 cells)")
	grid.register_entity(3, Vector2i(8, 4))
	var to_occupied_goal := grid.get_grid_path(1, Vector2i(2, 4), Vector2i(8, 4))
	_expect(to_occupied_goal.size() == 7, "a goal a piece stands on is still a goal: the cell is not solid for a question that ends there")
	var past_it := grid.get_grid_path(1, Vector2i(2, 4), Vector2i(9, 4))
	_expect(not past_it.is_empty() and Vector2i(8, 4) not in past_it, "a goal one cell past the piece is reached round it, never through it")
	_expect(not pathfinder.is_point_solid(Vector2i(8, 4)), "and the piece's cell is not left solid either")
	var after_all := true
	for x in range(0, 16):
		for y in range(0, 9):
			if pathfinder.is_point_solid(Vector2i(x, y)) != grid.blocked_cells.has(Vector2i(x, y)):
				after_all = false
	_expect(after_all and grid.pathfinder_build_count == 1, "at the end the kept pathfinder is solid exactly on the walls, and it is still the first one")


# --------------------------------------------------------------------------- the old answers
## 5000 questions on 40 random boards (a fixed seed), put to the new grid and to the old code at once: the
## same boards, the same pieces, the same reservations, the same leaps in the air. The paths must be equal
## cell for cell, not merely equally long, because an enemy walks the path the pathfinder gives.
func _check_the_answers_are_the_old_answers() -> void:
	var generator := RandomNumberGenerator.new()
	generator.seed = 20261019
	var kinds: Array = CellKinds.RULES_BY_KIND.keys()
	var questions := 0
	var found_a_path := 0
	var found_no_path := 0
	var mismatch := ""
	for board_index in range(40):
		var new_grid := EcsGrid.new()
		var old_grid := ReferencePathing.ReferenceGrid.new()
		var columns := generator.randi_range(6, 20)
		var rows := generator.randi_range(5, 11)
		new_grid.bounds = Rect2i(0, 0, columns, rows)
		old_grid.bounds = Rect2i(0, 0, columns, rows)
		var wall_count := generator.randi_range(0, columns * rows / 3)
		for _wall in range(wall_count):
			var wall_cell := Vector2i(generator.randi_range(0, columns - 1), generator.randi_range(0, rows - 1))
			var kind: StringName = kinds[generator.randi_range(0, kinds.size() - 1)]
			new_grid.set_cell_kind(wall_cell, kind)
			old_grid.set_cell_kind(wall_cell, kind)
		for entity_id in range(1, generator.randi_range(2, 9)):
			var piece_cell := Vector2i(generator.randi_range(0, columns - 1), generator.randi_range(0, rows - 1))
			var placed := new_grid.register_entity(entity_id, piece_cell)
			old_grid.register_entity(entity_id, piece_cell)
			if not placed:
				continue
			var roll := generator.randi_range(0, 3)
			var step_directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
			var target: Vector2i = piece_cell + step_directions[generator.randi_range(0, 3)]
			if roll == 0:
				new_grid.begin_move(entity_id, target)
				old_grid.begin_move(entity_id, target)
			elif roll == 1:
				var landing := Vector2i(generator.randi_range(0, columns - 1), generator.randi_range(0, rows - 1))
				new_grid.begin_leap(entity_id, piece_cell, landing)
				old_grid.begin_leap(entity_id, piece_cell, landing)
		for _question in range(125):
			var asking := generator.randi_range(0, 9)
			var origin := Vector2i(generator.randi_range(-1, columns), generator.randi_range(-1, rows))
			var goal := Vector2i(generator.randi_range(-1, columns), generator.randi_range(-1, rows))
			var new_path := new_grid.get_grid_path(asking, origin, goal)
			var old_path := old_grid.get_grid_path(asking, origin, goal)
			questions += 1
			if new_path.is_empty():
				found_no_path += 1
			else:
				found_a_path += 1
			if new_path != old_path or new_grid.get_path_distance(asking, origin, goal) != old_grid.get_path_distance(asking, origin, goal) or new_grid.get_next_path_cell(asking, origin, goal) != old_grid.get_next_path_cell(asking, origin, goal):
				mismatch = "board %d: entity %d from %s to %s: new %s, old %s" % [board_index, asking, origin, goal, new_path, old_path]
				break
		if not mismatch.is_empty():
			break
	_expect(mismatch.is_empty(), "%d random questions on 40 random boards get the old answer, cell for cell, and so do their distances and next steps (%s)" % [questions, mismatch])
	_expect(found_a_path > 1000 and found_no_path > 500, "setup: the questions were not trivial: %d had a path and %d had none" % [found_a_path, found_no_path])


# --------------------------------------------------------------------------- the cost
## On the 72 x 40 kingdom a pathfinder per question touches 2880 cells before it looks for anything, and an
## enemy asks about cells a few steps away (its aggro radius is 7). The cached grid skips that pass. A long
## question is dominated by the search itself and gains little, so the speed is asserted on the questions an
## enemy asks and merely printed for a path across the whole world. The bound (3x) is far below what it
## measures, so a noisy machine cannot fail it.
func _check_it_is_faster_on_a_big_board() -> void:
	var new_grid := EcsGrid.new()
	var old_grid := ReferencePathing.ReferenceGrid.new()
	for grid: EcsGrid in [new_grid, old_grid]:
		grid.bounds = Rect2i(0, 0, 72, 40)
		for x in range(0, 72):
			if x % 9 != 4:
				grid.set_cell_kind(Vector2i(x, 20), CellKinds.WALL)
		for entity_id in range(1, 9):
			grid.register_entity(entity_id, Vector2i(entity_id * 8, 30))
	var questions := 400
	var near_origin := Vector2i(30, 30)
	var new_paths: Array = []
	var started_usec := Time.get_ticks_usec()
	for question in range(questions):
		new_paths.append(new_grid.get_grid_path(1, near_origin, near_origin + Vector2i(question % 7 - 3, (question / 7) % 7 - 3)))
	var new_usec := Time.get_ticks_usec() - started_usec
	var old_paths: Array = []
	started_usec = Time.get_ticks_usec()
	for question in range(questions):
		old_paths.append(old_grid.get_grid_path(1, near_origin, near_origin + Vector2i(question % 7 - 3, (question / 7) % 7 - 3)))
	var old_usec := Time.get_ticks_usec() - started_usec
	print("PERF: %d short paths on the 72 x 40 board: %.1f ms with the cached pathfinder, %.1f ms building one per question (%.0fx)" % [questions, new_usec / 1000.0, old_usec / 1000.0, float(old_usec) / maxf(float(new_usec), 1.0)])
	_expect(new_paths == old_paths and not (new_paths[10] as Array).is_empty(), "setup: both give the same %d short paths" % questions)
	_expect(new_grid.pathfinder_build_count == 1, "and the cached grid built one pathfinder for all of them")
	_expect(old_usec >= new_usec * 3, "the cached grid answers %d short questions at least 3 times faster than a pathfinder per question (%d us against %d us)" % [questions, new_usec, old_usec])

	var long_started_usec := Time.get_ticks_usec()
	var long_new: Array[Vector2i] = new_grid.get_grid_path(1, Vector2i(8, 30), Vector2i(60, 8))
	var long_new_usec := Time.get_ticks_usec() - long_started_usec
	long_started_usec = Time.get_ticks_usec()
	var long_old: Array[Vector2i] = old_grid.get_grid_path(1, Vector2i(8, 30), Vector2i(60, 8))
	var long_old_usec := Time.get_ticks_usec() - long_started_usec
	print("PERF: one path of %d cells across the whole world: %d us cached, %d us built per question" % [long_new.size(), long_new_usec, long_old_usec])
	_expect(long_new == long_old and long_new.size() > 60, "and a path across the whole world (%d cells) is the same path" % long_new.size())
