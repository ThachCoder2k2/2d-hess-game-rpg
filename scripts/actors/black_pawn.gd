class_name BlackPawn
extends GridActor

signal telegraph_started(source: BlackPawn, cells: Array[Vector2i])
signal telegraph_finished(source: BlackPawn)
signal attack_resolved(cells: Array[Vector2i])
signal defeated(pawn: BlackPawn)

enum State { IDLE, TELEGRAPH, RECOVER, DEFEATED }

@export var health := 2
@export var think_time := 0.45
@export var telegraph_time := 0.58
@export var recovery_time := 0.48

var target: PawnHero
var state := State.IDLE
var state_time := 0.0
var flash_time := 0.0
var recoil := Vector2.ZERO


func activate(hero: PawnHero) -> void:
	target = hero
	facing = Vector2i.DOWN
	state = State.IDLE
	state_time = think_time
	queue_redraw()


func _process(delta: float) -> void:
	flash_time = maxf(0.0, flash_time - delta)
	recoil = recoil.move_toward(Vector2.ZERO, delta * 70.0)
	if flash_time > 0.0:
		queue_redraw()
	if target == null or not is_instance_valid(target) or state == State.DEFEATED or is_moving:
		return
	state_time -= delta
	if state_time > 0.0:
		return
	match state:
		State.IDLE:
			_choose_action()
		State.TELEGRAPH:
			_resolve_attack()
		State.RECOVER:
			state = State.IDLE
			state_time = think_time


func get_attack_cells() -> Array[Vector2i]:
	return [
		current_cell + Vector2i(-1, 1),
		current_cell + Vector2i(1, 1),
	]


func _choose_action() -> void:
	var attack_cells := get_attack_cells()
	if target.current_cell in attack_cells:
		state = State.TELEGRAPH
		state_time = telegraph_time
		emit_signal("telegraph_started", self, attack_cells)
		queue_redraw()
		return
	if try_step(Vector2i.DOWN):
		state = State.RECOVER
		state_time = recovery_time
	else:
		state = State.RECOVER
		state_time = recovery_time


func _resolve_attack() -> void:
	var attack_cells := get_attack_cells()
	emit_signal("telegraph_finished", self)
	if target.current_cell in attack_cells:
		target.take_damage(1, Vector2i.DOWN)
	emit_signal("attack_resolved", attack_cells)
	state = State.RECOVER
	state_time = recovery_time
	queue_redraw()


func take_damage(amount: int, direction := Vector2i.ZERO) -> void:
	if state == State.DEFEATED:
		return
	health -= amount
	flash_time = 0.12
	recoil = Vector2(direction) * 4.0
	queue_redraw()
	if health <= 0:
		state = State.DEFEATED
		emit_signal("telegraph_finished", self)
		grid_world.unregister_actor(self)
		emit_signal("defeated", self)
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(1.15, 0.15), 0.18)
		tween.tween_callback(queue_free)


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
	if state == State.TELEGRAPH:
		draw_line(Vector2(-8, 2), Vector2(-14, 9), Color("#ff7665"), 2.0)
		draw_line(Vector2(8, 2), Vector2(14, 9), Color("#ff7665"), 2.0)


func _draw_pixel_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 16:
		var angle := TAU * float(index) / 16.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
