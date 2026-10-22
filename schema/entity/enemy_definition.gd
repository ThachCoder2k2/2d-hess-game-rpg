class_name EnemyDefinition
extends Resource

## How a boss's defeat flag begins: `boss.` and then the boss's own id (`boss.knight_captain`).
const BOSS_FLAG_PREFIX := "boss."

@export var id: StringName
## Text key (ENEMY_<ID>_NAME in story.po): the piece's full name ("Pencil Pawn"). The words live in the .po files.
@export var display_name := "ENEMY_UNKNOWN_NAME"
## Text key (ENEMY_<ID>_PIECE in story.po): the short label shown in HUD/status text (e.g. "Pawn", "Knight").
## Authored per definition instead of guessed from the display name in code.
@export var piece_name := "ENEMY_UNKNOWN_PIECE"
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
## The world flag set when this piece falls (docs/game-base-plan.md 5.4, 7.3): a boss names `boss.<id>`, which
## is what the hub's doors wait for (a flag lock in content/world/world.tres). Empty for every ordinary piece.
## BossDefeatSystem reads it; nothing else needs to know which pieces are bosses.
@export var defeat_flag: StringName = &""


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
	if defeat_flag != &"":
		if not FlagId.is_valid(defeat_flag):
			warnings.append("defeat_flag '%s' is not a flag id (lowercase words, groups joined by a dot: boss.knight_captain)." % defeat_flag)
		elif not String(defeat_flag).begins_with(BOSS_FLAG_PREFIX):
			warnings.append("defeat_flag '%s' must start with '%s': a piece's fall is told by the flag of its boss id." % [defeat_flag, BOSS_FLAG_PREFIX])
		elif String(defeat_flag).trim_prefix(BOSS_FLAG_PREFIX) != String(id):
			warnings.append("defeat_flag '%s' must end with the piece's own id '%s'." % [defeat_flag, id])
	return warnings
