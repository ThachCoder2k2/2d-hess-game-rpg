@tool
class_name HeroStartMarker
extends Node2D

const PREVIEW_GRID_ORIGIN := Vector2(64, 36)
const PREVIEW_CELL_SIZE := 32
const PREVIEW_BOUNDS := Rect2i(0, 0, 16, 9)

@export var grid_cell := Vector2i(3, 7):
	set(value):
		grid_cell = value
		if sync_position_to_grid:
			_sync_position_to_grid()
@export var sync_position_to_grid := true:
	set(value):
		sync_position_to_grid = value
		if sync_position_to_grid:
			_sync_position_to_grid()
@export var show_editor_preview := true:
	set(value):
		show_editor_preview = value
		_sync_preview_visibility()

var _syncing_position := false


func _ready() -> void:
	if sync_position_to_grid:
		_sync_position_to_grid()
	_sync_preview_visibility()
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or not sync_position_to_grid or _syncing_position:
		return
	var snapped_cell := _position_to_grid_cell(position)
	if snapped_cell != grid_cell:
		grid_cell = snapped_cell


func get_hero_start_cell() -> Vector2i:
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


func _sync_preview_visibility() -> void:
	var preview := get_node_or_null("Preview") as CanvasItem
	if preview != null:
		preview.visible = Engine.is_editor_hint() and show_editor_preview


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_circle(Vector2.ZERO, 11.0, Color("#fff4d6", 0.18))
	draw_circle(Vector2.ZERO, 7.0, Color("#fff4d6", 0.78))
	draw_rect(Rect2(Vector2(-9, -9), Vector2(18, 18)), Color("#493f3a", 0.75), false, 1.5)
