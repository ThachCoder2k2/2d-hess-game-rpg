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


func _draw() -> void:
	var fill := Color.WHITE if flash_time > 0.0 else Color("#20242c")
	if state == State.TELEGRAPH:
		fill = Color("#623146")
	_draw_shadow()
	var path := PackedVector2Array([
		Vector2(-10, 10) + recoil,
		Vector2(-7, -2) + recoil,
		Vector2(-3, -12) + recoil,
		Vector2(7, -8) + recoil,
		Vector2(11, 0) + recoil,
		Vector2(5, -2) + recoil,
		Vector2(8, 10) + recoil,
	])
	draw_colored_polygon(path, fill)
	draw_circle(Vector2(3, -7) + recoil, 1.2, Color("#ff7665"))
	draw_rect(Rect2(Vector2(-11, 7) + recoil, Vector2(22, 5)), fill)
	_draw_weapon()


func _draw_weapon() -> void:
	if weapon == null:
		return
	draw_line(Vector2(5, -2), Vector2(facing) * 18.0, weapon.color, 3.0)


func _draw_shadow() -> void:
	var points := PackedVector2Array()
	for index in 16:
		var angle := TAU * float(index) / 16.0
		points.append(Vector2(cos(angle) * 11.0, 10.0 + sin(angle) * 4.0) + recoil)
	draw_colored_polygon(points, Color(0.05, 0.04, 0.05, 0.35))
