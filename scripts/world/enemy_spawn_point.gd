@tool
class_name EnemySpawnPoint
extends GridMarker

enum EnemyKind { PAWN, KNIGHT }

@export var active := true
@export var enemy_kind := EnemyKind.PAWN
@export var enemy_scene: PackedScene
@export var definition: EnemyDefinition
@export var starting_weapon: EnemyWeapon
@export var show_editor_preview := true:
	set(value):
		show_editor_preview = value
		_sync_preview_visibility()


func create_enemy() -> FreeEnemy:
	if not active:
		return null
	if enemy_scene == null:
		push_warning("EnemySpawnPoint '%s' needs an enemy_scene (assign black_pawn.tscn or knight_enemy.tscn)." % name)
		return null
	var enemy := enemy_scene.instantiate() as FreeEnemy
	if enemy == null:
		push_warning("EnemySpawnPoint '%s' scene is not FreeEnemy-compatible." % name)
		return null
	if definition != null:
		enemy.definition = definition
	return enemy


func create_starting_weapon() -> EnemyWeapon:
	return starting_weapon.duplicate(true) if starting_weapon != null else null


func _ready_marker() -> void:
	_sync_preview_visibility()


func _sync_preview_visibility() -> void:
	var preview := get_node_or_null("Preview") as CanvasItem
	if preview != null:
		preview.visible = Engine.is_editor_hint() and show_editor_preview


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var color := Color("#ff9a75", 0.85) if enemy_kind == EnemyKind.PAWN else Color("#8ec8e8", 0.85)
	var glow := color
	glow.a = 0.22
	draw_circle(Vector2.ZERO, 7.0, color)
	draw_circle(Vector2.ZERO, 10.0, glow)
	draw_rect(Rect2(Vector2(-8, -8), Vector2(16, 16)), Color("#fff4d6", 0.75), false, 1.5)
