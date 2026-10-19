extends UnboundTest

## A ray stops at blockers (docs/game-base-plan.md 5.11, 15 M3a): EcsGrid.ray_cells(origin, direction,
## max_cells, stop_kinds) lists the cells a straight line covers, nearest first, and ends before the board's
## edge or before the first cell whose kind stops it. Rook charges, Bishop lanes and Queen lines (M8a, M9
## and after) are made of it; no attack uses it yet. This suite fixes what "blocker" means: walls and
## blocks stop a ray, gaps, chalk and corruption do not, and a caller may name its own kinds.

const CENTRE := Vector2i(8, 4)
const EIGHT_DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]


func _init() -> void:
	suite_title = "RAY STOPS AT BLOCKERS TEST"
	_check_an_open_board()
	_check_the_edge_of_the_board()
	_check_walls_and_blocks_stop_a_ray()
	_check_gaps_chalk_and_corruption_do_not()
	_check_the_caller_may_name_its_own_kinds()
	_check_pieces()
	_check_degenerate_asks()
	_check_diagonals_do_not_cut_corners_or_leak()
	_check_rook_bishop_and_queen_shapes()
	_check_the_rays_of_random_boards()
	finish()


func _check_an_open_board() -> void:
	var grid := EcsGrid.new()
	_expect(grid.ray_cells(CENTRE, Vector2i.RIGHT, 3) == [Vector2i(9, 4), Vector2i(10, 4), Vector2i(11, 4)], "a ray to the right from (8, 4) covers the next cells, nearest first, and not the origin")
	_expect(grid.ray_cells(CENTRE, Vector2i.UP, 2) == [Vector2i(8, 3), Vector2i(8, 2)] and grid.ray_cells(CENTRE, Vector2i.LEFT, 1) == [Vector2i(7, 4)], "up goes toward row 0 and a ray of one cell is one cell")
	_expect(grid.ray_cells(CENTRE, Vector2i(1, 1), 3) == [Vector2i(9, 5), Vector2i(10, 6), Vector2i(11, 7)], "a diagonal ray steps one column and one row at a time")
	var every_direction_has_its_length := true
	for direction in EIGHT_DIRECTIONS:
		var cells := grid.ray_cells(CENTRE, direction, 2)
		if cells.size() != 2 or cells[0] != CENTRE + direction or cells[1] != CENTRE + direction * 2:
			every_direction_has_its_length = false
	_expect(every_direction_has_its_length, "all eight directions give two cells for two asked, each one step further along")
	_expect(grid.ray_cells(CENTRE, Vector2i.RIGHT, 3) is Array and grid.ray_cells(CENTRE, Vector2i.RIGHT, 3).get_typed_builtin() == TYPE_VECTOR2I, "the answer is a typed Array[Vector2i]")


func _check_the_edge_of_the_board() -> void:
	var grid := EcsGrid.new()
	_expect(grid.ray_cells(CENTRE, Vector2i.RIGHT, 99).size() == 7 and grid.ray_cells(CENTRE, Vector2i.RIGHT, 99)[6] == Vector2i(15, 4), "a ray that is long enough ends at the last column of a 16-wide board: 7 cells from column 8")
	_expect(grid.ray_cells(CENTRE, Vector2i.LEFT, 99).size() == 8 and grid.ray_cells(CENTRE, Vector2i.UP, 99).size() == 4 and grid.ray_cells(CENTRE, Vector2i.DOWN, 99).size() == 4, "and at the other three edges (8, 4 and 4 cells)")
	_expect(grid.ray_cells(Vector2i(0, 0), Vector2i.LEFT, 5).is_empty() and grid.ray_cells(Vector2i(15, 8), Vector2i.DOWN, 5).is_empty(), "a ray that starts at an edge and points out covers nothing")
	_expect(grid.ray_cells(Vector2i(14, 7), Vector2i(1, 1), 5) == [Vector2i(15, 8)], "a diagonal ray ends when it leaves the board by either edge")
	grid.bounds = Rect2i(0, 0, 18, 9)
	_expect(grid.ray_cells(CENTRE, Vector2i.RIGHT, 99).size() == 9, "and the board is the grid's own bounds: an 18-wide arena gives 9 cells from column 8")
	grid.bounds = Rect2i(2, 2, 4, 4)
	_expect(grid.ray_cells(Vector2i(3, 3), Vector2i.LEFT, 9) == [Vector2i(2, 3)], "bounds that do not start at the origin work too")


func _check_walls_and_blocks_stop_a_ray() -> void:
	var grid := EcsGrid.new()
	grid.set_cell_kind(Vector2i(11, 4), CellKinds.WALL)
	_expect(grid.ray_cells(CENTRE, Vector2i.RIGHT, 9) == [Vector2i(9, 4), Vector2i(10, 4)], "a ray ends before a wall: the wall is not in the list, nothing beyond it is")
	_expect(grid.ray_cells(CENTRE, Vector2i.RIGHT, 2) == [Vector2i(9, 4), Vector2i(10, 4)], "and a ray that falls short of the wall is not touched by it")
	_expect(grid.ray_cells(Vector2i(10, 4), Vector2i.RIGHT, 9).is_empty(), "a wall right next to the origin leaves an empty ray")
	_expect(grid.ray_cells(Vector2i(14, 4), Vector2i.LEFT, 9) == [Vector2i(13, 4), Vector2i(12, 4)], "from the far side the same wall stops it the same way")
	grid.set_cell_kind(Vector2i(8, 6), CellKinds.LEAPABLE_BLOCK)
	_expect(grid.ray_cells(CENTRE, Vector2i.DOWN, 9) == [Vector2i(8, 5)], "a leapable block is cover: a ray ends before it too")
	grid.gate_by_cell[Vector2i(8, 2)] = {"id": &"shortcut", "opens_from": Vector2i.DOWN}
	grid.add_block(Vector2i(8, 2))
	_expect(grid.ray_cells(CENTRE, Vector2i.UP, 9) == [Vector2i(8, 3)], "a closed gate, which is a wall, stops it")
	grid.open_gate(Vector2i(8, 2))
	_expect(grid.ray_cells(CENTRE, Vector2i.UP, 9).size() == 4, "and an opened gate no longer does: the ray runs to the edge (4 cells)")
	_expect(grid.ray_cells(CENTRE, Vector2i.LEFT, 9).size() == 8, "a ray in another direction is not stopped by walls that are not on its line")


func _check_gaps_chalk_and_corruption_do_not() -> void:
	var grid := EcsGrid.new()
	grid.set_cell_kind(Vector2i(10, 4), CellKinds.GAP)
	grid.set_cell_kind(Vector2i(11, 4), CellKinds.CHALK)
	grid.set_cell_kind(Vector2i(12, 4), CellKinds.CORRUPTION)
	_expect(grid.ray_cells(CENTRE, Vector2i.RIGHT, 5) == [Vector2i(9, 4), Vector2i(10, 4), Vector2i(11, 4), Vector2i(12, 4), Vector2i(13, 4)], "a ray flies over a gap, chalk and corruption and covers them (a Rook line fires across a gap)")
	grid.set_cell_kind(Vector2i(13, 4), CellKinds.WALL)
	_expect(grid.ray_cells(CENTRE, Vector2i.RIGHT, 9).size() == 4 and grid.ray_cells(CENTRE, Vector2i.RIGHT, 9)[3] == Vector2i(12, 4), "and still ends at the wall behind them")


func _check_the_caller_may_name_its_own_kinds() -> void:
	var grid := EcsGrid.new()
	grid.set_cell_kind(Vector2i(10, 4), CellKinds.GAP)
	grid.set_cell_kind(Vector2i(12, 4), CellKinds.WALL)
	var only_gaps: Array[StringName] = [CellKinds.GAP]
	_expect(grid.ray_cells(CENTRE, Vector2i.RIGHT, 9, only_gaps) == [Vector2i(9, 4)], "a ray told that gaps stop it ends before the gap")
	_expect(grid.ray_cells(CENTRE, Vector2i.RIGHT, 9, only_gaps).size() == 1, "and the wall further on is no longer its business")
	var only_walls: Array[StringName] = [CellKinds.WALL]
	_expect(grid.ray_cells(CENTRE, Vector2i.RIGHT, 9, only_walls).size() == 3, "a ray told that only walls stop it covers the gap and ends at the wall (3 cells)")
	var nothing: Array[StringName] = []
	_expect(grid.ray_cells(CENTRE, Vector2i.RIGHT, 9, nothing).size() == 7, "a ray told that nothing stops it runs to the edge of the board (7 cells)")
	var by_the_table := CellKinds.default_ray_stop_kinds()
	_expect(grid.ray_cells(CENTRE, Vector2i.RIGHT, 9, by_the_table) == grid.ray_cells(CENTRE, Vector2i.RIGHT, 9), "and naming the default kinds is the same as naming none")


func _check_pieces() -> void:
	var grid := EcsGrid.new()
	grid.register_entity(1, Vector2i(10, 4))
	_expect(grid.ray_cells(CENTRE, Vector2i.RIGHT, 4) == [Vector2i(9, 4), Vector2i(10, 4), Vector2i(11, 4), Vector2i(12, 4)], "a piece is not terrain: the ray covers its cell and goes on (a line of fire hits whoever stands in it)")
	_expect(grid.ray_cells(CENTRE, Vector2i.RIGHT, 4, CellKinds.default_ray_stop_kinds(), true) == [Vector2i(9, 4)], "told to stop before the occupied, it ends before the piece (a charge cannot run through anyone)")
	grid.register_entity(2, Vector2i(8, 7))
	grid.begin_move(2, Vector2i(8, 6))
	_expect(grid.ray_cells(CENTRE, Vector2i.DOWN, 9, CellKinds.default_ray_stop_kinds(), true) == [Vector2i(8, 5)], "and before a cell a piece has reserved: it is about to be there")
	_expect(grid.ray_cells(CENTRE, Vector2i.LEFT, 3, CellKinds.default_ray_stop_kinds(), true).size() == 3, "pieces off the line change nothing")
	grid.register_entity(3, CENTRE + Vector2i.UP * 2)
	grid.begin_leap(3, CENTRE + Vector2i.UP * 2, CENTRE + Vector2i(3, -2))
	_expect(grid.ray_cells(CENTRE, Vector2i.UP, 5, CellKinds.default_ray_stop_kinds(), true).size() == 4, "a piece in the air has left its cell, so it does not stop a charge there")
	_expect(grid.ray_cells(CENTRE + Vector2i(3, 0), Vector2i.UP, 5, CellKinds.default_ray_stop_kinds(), true).size() == 1, "but its landing cell is reserved, so a charge up that column ends before it (row 2)")


func _check_degenerate_asks() -> void:
	var grid := EcsGrid.new()
	_expect(grid.ray_cells(CENTRE, Vector2i.ZERO, 5).is_empty(), "a ray with no direction covers nothing (and does not loop)")
	_expect(grid.ray_cells(CENTRE, Vector2i.RIGHT, 0).is_empty() and grid.ray_cells(CENTRE, Vector2i.RIGHT, -3).is_empty(), "a ray of no cells, or fewer, covers nothing")
	_expect(grid.ray_cells(Vector2i(40, 40), Vector2i.LEFT, 5).is_empty(), "a ray from far off the board covers nothing: its first cell is off the board")
	_expect(grid.ray_cells(Vector2i(-3, 4), Vector2i.RIGHT, 5).is_empty(), "and a ray whose first cell is off the board never enters it from outside: the edge ends it at once")
	grid.set_cell_kind(CENTRE, CellKinds.WALL)
	_expect(grid.ray_cells(CENTRE, Vector2i.RIGHT, 2).size() == 2, "the origin itself is never looked at: a ray may start from a wall (a charger beside it, a gate)")
	_expect(grid.ray_cells(CENTRE, Vector2i(2, 0), 3) == [Vector2i(10, 4), Vector2i(12, 4), Vector2i(14, 4)], "a longer step is a ray that skips cells, as given")


## A diagonal passes between two walls that touch at a corner: rays are lines of cells, and the corner is
## not a cell. A wall on a neighbouring line does not stop it either.
func _check_diagonals_do_not_cut_corners_or_leak() -> void:
	var grid := EcsGrid.new()
	grid.set_cell_kind(Vector2i(9, 4), CellKinds.WALL)
	grid.set_cell_kind(Vector2i(8, 5), CellKinds.WALL)
	_expect(grid.ray_cells(CENTRE, Vector2i(1, 1), 3) == [Vector2i(9, 5), Vector2i(10, 6), Vector2i(11, 7)], "a diagonal ray passes between two walls that meet at a corner (the cells of its line are free)")
	grid.set_cell_kind(Vector2i(10, 6), CellKinds.WALL)
	_expect(grid.ray_cells(CENTRE, Vector2i(1, 1), 3) == [Vector2i(9, 5)], "and is stopped by a wall ON its line")
	_expect(grid.ray_cells(CENTRE, Vector2i(1, -1), 3).size() == 3, "while its other diagonal is untouched")


func _check_rook_bishop_and_queen_shapes() -> void:
	# A room with a pillar: what a Rook, a Bishop and a Queen standing at (8, 4) would cover.
	var grid := EcsGrid.new()
	grid.set_cell_kind(Vector2i(8, 2), CellKinds.WALL)
	grid.set_cell_kind(Vector2i(11, 7), CellKinds.WALL)
	var rook_cells := 0
	for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		rook_cells += grid.ray_cells(CENTRE, direction, 99).size()
	_expect(rook_cells == 1 + 4 + 8 + 7, "a Rook at (8, 4) covers 20 cells: 1 up (the pillar two cells up), 4 down, 8 left, 7 right (%d)" % rook_cells)
	var bishop_cells := 0
	for direction in [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
		bishop_cells += grid.ray_cells(CENTRE, direction, 99).size()
	_expect(bishop_cells == 2 + 4 + 4 + 4, "a Bishop covers 14 cells: down-right ends at the pillar (2), the others run out of board (4, 4, 4) (%d)" % bishop_cells)
	var queen_cells := 0
	for direction in EIGHT_DIRECTIONS:
		queen_cells += grid.ray_cells(CENTRE, direction, 99).size()
	_expect(queen_cells == rook_cells + bishop_cells, "and a Queen is the two together (34)")


## Rays over 400 random boards (a fixed seed) must satisfy what a ray IS, checked cell by cell without the
## function under test: every cell is on the board and exactly one step further than the one before; none
## is a cell whose kind stops it; and the ray ended for a reason: it is as long as asked, or the next cell is
## off the board or of a stopping kind.
func _check_the_rays_of_random_boards() -> void:
	var generator := RandomNumberGenerator.new()
	generator.seed = 20261019
	var kinds: Array = CellKinds.RULES_BY_KIND.keys()
	var problems := PackedStringArray()
	var rays_checked := 0
	for board_index in range(400):
		var grid := EcsGrid.new()
		for _scatter in range(generator.randi_range(0, 40)):
			grid.set_cell_kind(Vector2i(generator.randi_range(0, 15), generator.randi_range(0, 8)), kinds[generator.randi_range(0, kinds.size() - 1)])
		var stop_kinds: Array[StringName] = []
		if generator.randi_range(0, 3) > 0:
			stop_kinds = CellKinds.default_ray_stop_kinds()
		else:
			for kind: StringName in kinds:
				if generator.randi_range(0, 1) == 1:
					stop_kinds.append(kind)
		for _ray in range(10):
			var origin := Vector2i(generator.randi_range(0, 15), generator.randi_range(0, 8))
			var direction: Vector2i = EIGHT_DIRECTIONS[generator.randi_range(0, 7)]
			var max_cells := generator.randi_range(0, 20)
			var cells := grid.ray_cells(origin, direction, max_cells, stop_kinds)
			rays_checked += 1
			var expected_next := origin + direction
			for cell in cells:
				if cell != expected_next or not grid.bounds.has_point(cell) or grid.kind_at(cell) in stop_kinds:
					problems.append("board %d: ray from %s toward %s covered %s" % [board_index, origin, direction, cell])
				expected_next += direction
			var as_long_as_asked := cells.size() == max_cells
			var next_is_off_the_board := not grid.bounds.has_point(expected_next)
			var next_stops_it := grid.bounds.has_point(expected_next) and grid.kind_at(expected_next) in stop_kinds
			if not (as_long_as_asked or next_is_off_the_board or next_stops_it):
				problems.append("board %d: ray from %s toward %s ended after %d cells for no reason" % [board_index, origin, direction, cells.size()])
	_expect(problems.is_empty(), "%d random rays on 400 random boards each cover exactly the cells of their line up to a reason to stop (%s)" % [rays_checked, "; ".join(problems.slice(0, 3))])
