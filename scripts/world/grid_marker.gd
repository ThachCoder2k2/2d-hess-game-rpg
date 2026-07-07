@tool
class_name GridMarker
extends Node2D

## Base for editor-draggable room markers. Owns grid-cell authoring: dragging the
## node in the editor snaps it to a cell, and setting grid_cell moves the node.
## Subclasses add their own data (spawn scene, weapon, ...), preview node, and
## _draw. Every marker subclass must keep its own @tool annotation.

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


func _sync_position_to_grid() -> void:
	_syncing_position = true
	position = PREVIEW_GRID_ORIGIN + Vector2(grid_cell * PREVIEW_CELL_SIZE) + Vector2.ONE * PREVIEW_CELL_SIZE * 0.5
	_syncing_position = false


func _position_to_grid_cell(world_position: Vector2) -> Vector2i:
	var raw := (world_position - PREVIEW_GRID_ORIGIN - Vector2.ONE * PREVIEW_CELL_SIZE * 0.5) / float(PREVIEW_CELL_SIZE)
	var cell := Vector2i(int(round(raw.x)), int(round(raw.y)))
	return Vector2i(
		clampi(cell.x, PREVIEW_BOUNDS.position.x, PREVIEW_BOUNDS.end.x - 1),
		clampi(cell.y, PREVIEW_BOUNDS.position.y, PREVIEW_BOUNDS.end.y - 1)
	)
