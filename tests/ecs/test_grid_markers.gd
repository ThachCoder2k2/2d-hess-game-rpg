extends UnboundTest

## The grid's generic marker store (docs/game-base-plan.md 14.1, EcsGrid.marker_by_cell): a new kind of room
## marker (M5's traversal gap, M6's trigger) adds a baker and no field to the grid, so it can land in a lane of
## its own without editing the hot file. This suite holds the store's rules: a kind and a cell give at most one
## marker, a marker must be on the board, kinds do not see each other, and reading an absent marker is safe.

const GAP_KIND := &"traversal_gap"
const TRIGGER_KIND := &"trigger"


func _init() -> void:
	suite_title = "GRID MARKERS TEST"
	var grid := EcsGrid.new()
	_expect(grid.marker_by_cell.is_empty() and grid.marker_cells(GAP_KIND).is_empty(), "a fresh grid holds no marker of any kind")
	_expect(not grid.has_marker(GAP_KIND, Vector2i(3, 3)) and grid.marker_at(GAP_KIND, Vector2i(3, 3)).is_empty(), "asking for a marker that is not there is safe and answers nothing")

	_expect(grid.add_marker(GAP_KIND, Vector2i(5, 4), {"believe_cost": 0}), "a marker is added on a cell of the board")
	_expect(grid.has_marker(GAP_KIND, Vector2i(5, 4)) and grid.marker_at(GAP_KIND, Vector2i(5, 4)) == {"believe_cost": 0}, "the marker's data is read back from its cell")
	_expect(not grid.add_marker(GAP_KIND, Vector2i(5, 4), {"believe_cost": 9}) and grid.marker_at(GAP_KIND, Vector2i(5, 4)) == {"believe_cost": 0}, "a cell holds one marker per kind: a second add changes nothing")
	_expect(not grid.add_marker(GAP_KIND, Vector2i(-1, 0)) and not grid.add_marker(GAP_KIND, Vector2i(16, 4)) and not grid.has_marker(GAP_KIND, Vector2i(16, 4)), "a marker off the board is refused")

	_expect(grid.add_marker(TRIGGER_KIND, Vector2i(5, 4), {"beat": &"first_clue"}), "another kind may share the cell")
	_expect(grid.marker_at(TRIGGER_KIND, Vector2i(5, 4)) == {"beat": &"first_clue"} and grid.marker_at(GAP_KIND, Vector2i(5, 4)) == {"believe_cost": 0}, "kinds do not see each other's data")

	grid.add_marker(GAP_KIND, Vector2i(2, 6))
	grid.add_marker(GAP_KIND, Vector2i(9, 1))
	grid.add_marker(GAP_KIND, Vector2i(1, 4))
	_expect(grid.marker_cells(GAP_KIND) == [Vector2i(9, 1), Vector2i(1, 4), Vector2i(5, 4), Vector2i(2, 6)], "marker_cells lists a kind row by row, left to right")
	_expect(grid.marker_at(GAP_KIND, Vector2i(2, 6)).is_empty() and grid.has_marker(GAP_KIND, Vector2i(2, 6)), "a marker added with no data is there, with empty data")

	_expect(grid.remove_marker(GAP_KIND, Vector2i(5, 4)) and not grid.has_marker(GAP_KIND, Vector2i(5, 4)) and grid.has_marker(TRIGGER_KIND, Vector2i(5, 4)), "removing a marker takes only that kind's marker off the cell")
	_expect(not grid.remove_marker(GAP_KIND, Vector2i(5, 4)), "removing a marker that is not there says so")
	grid.remove_marker(TRIGGER_KIND, Vector2i(5, 4))
	_expect(not grid.marker_by_cell.has(TRIGGER_KIND), "a kind with no marker left leaves no empty entry behind")
	finish()
