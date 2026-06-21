class_name BlackPawn
extends FreeEnemy


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


func _draw() -> void:
	var fill := Color.WHITE if flash_time > 0.0 else Color("#17191f")
	if state == State.TELEGRAPH:
		fill = Color("#5a2025")
	_draw_pixel_ellipse(Vector2(0, 9) + recoil, Vector2(10, 4), Color(0.05, 0.04, 0.05, 0.35))
	draw_circle(Vector2(0, -9) + recoil, 6.0, fill)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5, -3) + recoil, Vector2(5, -3) + recoil,
		Vector2(9, 7) + recoil, Vector2(-9, 7) + recoil
	]), fill)
	draw_rect(Rect2(Vector2(-11, 6) + recoil, Vector2(22, 5)), fill)
	draw_line(Vector2(-11, 11) + recoil, Vector2(11, 11) + recoil, Color("#d84a3a"), 2.0)
	_draw_facing_mark()
	_draw_weapon()


func _draw_facing_mark() -> void:
	var side := Vector2(-facing.y, facing.x)
	var tip := Vector2(facing) * 13.0
	draw_polyline(PackedVector2Array([tip - Vector2(facing) * 4.0 + side * 3.0, tip, tip - Vector2(facing) * 4.0 - side * 3.0]), Color("#ff7665"), 2.0)


func _draw_weapon() -> void:
	if weapon == null:
		return
	var start := Vector2(facing) * 5.0
	var finish := Vector2(facing) * 18.0
	draw_line(start, finish, weapon.color, 3.0)


func _draw_pixel_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 16:
		var angle := TAU * float(index) / 16.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
