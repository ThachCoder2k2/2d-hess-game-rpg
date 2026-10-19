@tool
class_name GridMarker
extends Node2D

## Base for editor-draggable room markers. Owns grid-cell authoring: dragging the
## node in the editor snaps it to a cell, and setting grid_cell moves the node.
## Subclasses add their own data (spawn scene, weapon, ...), preview node, and
## _draw. Every marker subclass must keep its own @tool annotation.
##
## The cells are the room's own: a marker whose parent is a RoomEncounter snaps to the room's board_size and
## to the origin that centres that board in the view (EcsGrid.centred_origin, the one EcsBoot gives the grid), so a
## 16x9 room starts at (64, 36) and an 18x9 arena at (32, 36) and a marker in either lands on the cell
## its grid_cell says. Without such a parent (a marker scene opened on its own) the board is the 16x9 default.

const PREVIEW_GRID_ORIGIN := Vector2(64, 36)
const PREVIEW_CELL_SIZE := 32
const PREVIEW_BOUNDS := Rect2i(0, 0, 16, 9)

@export var grid_cell := Vector2i.ZERO:
	set(value):
		grid_cell = value
		if sync_position_to_grid:
			_sync_position_to_grid()
@export var sync_position_to_grid := true:
	set(value):
		sync_position_to_grid = value
		if sync_position_to_grid:
			_sync_position_to_grid()

var _syncing_position := false


func _ready() -> void:
	if sync_position_to_grid:
		_sync_position_to_grid()
	_ready_marker()
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or not sync_position_to_grid or _syncing_position:
		return
	var snapped_cell := _position_to_grid_cell(position)
	if snapped_cell != grid_cell:
		grid_cell = snapped_cell


## Override to refresh preview/label visibility once the node is ready.
func _ready_marker() -> void:
	pass


## The cells of the board this marker is placed on: the parent room's board_size, else the 16x9 default.
func board_cells() -> Vector2i:
	var parent_board: Variant = get_parent().get("board_size") if get_parent() != null else null
	if parent_board is Vector2i and parent_board.x > 0 and parent_board.y > 0:
		return parent_board
	return PREVIEW_BOUNDS.size


## World position of the top-left corner of cell (0, 0) of this marker's room (see the header).
func board_origin() -> Vector2:
	if board_cells() == PREVIEW_BOUNDS.size:
		return PREVIEW_GRID_ORIGIN
	return EcsGrid.centred_origin(board_cells(), PREVIEW_CELL_SIZE, EcsBoot.project_view_size())


func _sync_position_to_grid() -> void:
	_syncing_position = true
	position = board_origin() + Vector2(grid_cell * PREVIEW_CELL_SIZE) + Vector2.ONE * PREVIEW_CELL_SIZE * 0.5
	_syncing_position = false


func _position_to_grid_cell(world_position: Vector2) -> Vector2i:
	var raw := (world_position - board_origin() - Vector2.ONE * PREVIEW_CELL_SIZE * 0.5) / float(PREVIEW_CELL_SIZE)
	var cell := Vector2i(int(round(raw.x)), int(round(raw.y)))
	var board := board_cells()
	return Vector2i(
		clampi(cell.x, 0, board.x - 1),
		clampi(cell.y, 0, board.y - 1)
	)
