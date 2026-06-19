class_name TrainingDummy
extends GridActor

signal defeated(dummy: TrainingDummy)

@export var health := 3
var flash_time := 0.0
var recoil := Vector2.ZERO


func _process(delta: float) -> void:
	if flash_time > 0.0:
		flash_time = maxf(0.0, flash_time - delta)
		recoil = recoil.move_toward(Vector2.ZERO, delta * 70.0)
		queue_redraw()


func take_damage(amount: int, direction := Vector2i.ZERO) -> void:
	health -= amount
	flash_time = 0.12
	recoil = Vector2(direction) * 4.0
	queue_redraw()
	if health <= 0:
		grid_world.unregister_actor(self)
		emit_signal("defeated", self)
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(1.15, 0.15), 0.18)
		tween.tween_callback(queue_free)


func _draw() -> void:
	var fill := Color.WHITE if flash_time > 0.0 else Color("#17191f")
	_draw_pixel_ellipse(Vector2(0, 9) + recoil, Vector2(10, 4), Color(0.05, 0.04, 0.05, 0.35))
	draw_circle(Vector2(0, -9) + recoil, 6.0, fill)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5, -3) + recoil, Vector2(5, -3) + recoil,
		Vector2(9, 7) + recoil, Vector2(-9, 7) + recoil
	]), fill)
	draw_rect(Rect2(Vector2(-11, 6) + recoil, Vector2(22, 5)), fill)
	draw_line(Vector2(-11, 11) + recoil, Vector2(11, 11) + recoil, Color("#d84a3a"), 2.0)


func _draw_pixel_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 16:
		var angle := TAU * float(index) / 16.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
