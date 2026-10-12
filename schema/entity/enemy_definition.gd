class_name EnemyDefinition
extends Resource

@export var id: StringName
@export var display_name := "Enemy"
## Short label shown in HUD/status text (e.g. "Pawn", "Knight"). Authored per
## definition instead of guessed from the display name in code.
@export var piece_name := "Enemy"
@export var role: StringName = &"skirmisher"
@export_range(1, 100) var max_health := 2
@export var movement: MovementConfig
@export var decision: DecisionConfig
@export var unarmed_attack: AttackPattern
@export var allowed_weapon_tags: Array[StringName] = []
@export var weapon_preferences: Dictionary = {}
@export var visual: VisualDefinition
@export var difficulty: DifficultyProfile
@export var default_weapon: EnemyWeapon


func validate() -> PackedStringArray:
	var warnings := PackedStringArray()
	if id.is_empty():
		warnings.append("Enemy definition requires an id.")
	if movement == null:
		warnings.append("Enemy definition requires MovementConfig.")
	else:
		warnings.append_array(movement.validate())
	if decision == null:
		warnings.append("Enemy definition requires DecisionConfig.")
	if unarmed_attack == null:
		warnings.append("Enemy definition requires an unarmed AttackPattern.")
	if visual == null:
		warnings.append("Enemy definition requires VisualDefinition.")
	else:
		warnings.append_array(visual.validate())
	if difficulty == null:
		warnings.append("Enemy definition requires DifficultyProfile.")
	return warnings
