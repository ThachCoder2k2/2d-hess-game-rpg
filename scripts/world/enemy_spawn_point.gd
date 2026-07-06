@tool
class_name EnemySpawnPoint
extends Node2D

enum EnemyKind { PAWN, KNIGHT }

const PREVIEW_GRID_ORIGIN := Vector2(64, 36)
const PREVIEW_CELL_SIZE := 32

@export var active := true
@export var enemy_kind := EnemyKind.PAWN
@export var enemy_scene: PackedScene
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
@export var definition: EnemyDefinition
@export var starting_weapon: EnemyWeapon


func _ready() -> void:
	if sync_position_to_grid:
		_sync_position_to_grid()


func create_enemy() -> FreeEnemy:
	if not active:
		return null
	var enemy: FreeEnemy
	if enemy_scene != null:
		enemy = enemy_scene.instantiate() as FreeEnemy
	else:
		match enemy_kind:
			EnemyKind.KNIGHT:
				enemy = KnightEnemy.new()
			_:
				enemy = BlackPawn.new()
	if enemy == null:
		push_warning("EnemySpawnPoint '%s' needs a FreeEnemy-compatible scene." % name)
		return null
	if definition != null:
		enemy.definition = definition
	return enemy


func create_starting_weapon() -> EnemyWeapon:
	return starting_weapon.duplicate(true) if starting_weapon != null else null


func _sync_position_to_grid() -> void:
	position = PREVIEW_GRID_ORIGIN + Vector2(grid_cell * PREVIEW_CELL_SIZE) + Vector2.ONE * PREVIEW_CELL_SIZE * 0.5


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var color := Color("#ff9a75", 0.85) if enemy_kind == EnemyKind.PAWN else Color("#8ec8e8", 0.85)
	var glow := color
	glow.a = 0.22
	draw_circle(Vector2.ZERO, 7.0, color)
	draw_circle(Vector2.ZERO, 10.0, glow)
	draw_rect(Rect2(Vector2(-8, -8), Vector2(16, 16)), Color("#fff4d6", 0.75), false, 1.5)
