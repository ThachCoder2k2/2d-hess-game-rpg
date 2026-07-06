class_name BlackPawn
extends FreeEnemy


func create_enemy_definition() -> EnemyDefinition:
	return load("res://resources/enemies/pawn_recruit.tres") as EnemyDefinition


func create_attack_pattern() -> AttackPattern:
	return PawnPattern.new()


func create_archetype() -> EnemyArchetype:
	var data := EnemyArchetype.new()
	data.role = &"skirmisher"
	data.future_threat_score = 36.0
	data.pickup_score = 72.0
	data.turn_threat_score = 52.0
	data.preferred_distance = 2
	return data
