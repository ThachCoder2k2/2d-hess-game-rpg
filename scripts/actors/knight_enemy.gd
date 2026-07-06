class_name KnightEnemy
extends FreeEnemy


func create_enemy_definition() -> EnemyDefinition:
	return load("res://resources/enemies/knight_tracker.tres") as EnemyDefinition


func create_attack_pattern() -> AttackPattern:
	return KnightPattern.new()


func create_archetype() -> EnemyArchetype:
	var data := EnemyArchetype.new()
	data.role = &"flanker"
	data.future_threat_score = 58.0
	data.distance_score = 7.0
	data.pickup_score = 50.0
	data.preferred_distance = 3
	return data


func get_positioning_bonus(destination: Vector2i, direction: Vector2i, context: EnemyContext) -> float:
	var bonus := super(destination, direction, context)
	if weapon == null and context.hero_cell in get_unarmed_attack_cells(destination, direction):
		bonus += 30.0
	if last_move_direction != Vector2i.ZERO:
		var previous_axis := last_move_direction.abs()
		var next_axis := direction.abs()
		if previous_axis != next_axis:
			bonus += 12.0
	return bonus
