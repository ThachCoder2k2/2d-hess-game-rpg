@tool
class_name BlockerMarker
extends Node2D

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
@export var show_editor_label := true:
	set(value):
		show_editor_label = value
		_sync_editor_label()

var _syncing_position := false


func _ready() -> void:
	if sync_position_to_grid:
		_sync_position_to_grid()
	_sync_editor_label()
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or not sync_position_to_grid or _syncing_position:
		return
	var snapped_cell := _position_to_grid_cell(position)
	if snapped_cell != grid_cell:
		grid_cell = snapped_cell


func get_blocked_cell() -> Vector2i:
	return grid_cell


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


func _sync_editor_label() -> void:
	var label := get_node_or_null("EditorLabel") as CanvasItem
	if label != null:
		label.visible = Engine.is_editor_hint() and show_editor_label


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_rect(Rect2(Vector2(-14, -14), Vector2(28, 28)), Color("#fff4d6", 0.55), false, 1.0)
