@tool
class_name PickupSpawnPoint
extends Node2D

const PREVIEW_GRID_ORIGIN := Vector2(64, 36)
const PREVIEW_CELL_SIZE := 32

@export var active := true
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
@export var weapon: EnemyWeapon


func _ready() -> void:
	if sync_position_to_grid:
		_sync_position_to_grid()


func create_weapon() -> EnemyWeapon:
	return weapon.duplicate(true) if active and weapon != null else null


func _sync_position_to_grid() -> void:
	position = PREVIEW_GRID_ORIGIN + Vector2(grid_cell * PREVIEW_CELL_SIZE) + Vector2.ONE * PREVIEW_CELL_SIZE * 0.5


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var color := Color("#e8b83f", 0.85)
	if weapon != null:
		color = weapon.color
	var fill := color
	fill.a = 0.22
	draw_rect(Rect2(Vector2(-8, -8), Vector2(16, 16)), fill)
	draw_rect(Rect2(Vector2(-8, -8), Vector2(16, 16)), Color("#fff4d6", 0.75), false, 1.5)
	draw_line(Vector2(-7, 5), Vector2(7, -5), color, 2.5)
