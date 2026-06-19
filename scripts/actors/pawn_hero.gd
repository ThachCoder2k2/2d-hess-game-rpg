class_name PawnHero
extends GridActor

signal courage_changed(value: int)
signal attack_landed(target_cell: Vector2i, hit: bool)

const DIRECTIONS := {
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN,
	"move_left": Vector2i.LEFT,
	"move_right": Vector2i.RIGHT,
}

@export var courage := 3
@export var attack_recovery := 0.30
@export var held_repeat_delay := 0.22

var buffered_direction := Vector2i.ZERO
var attack_on_cooldown := false
var attack_visual_time := 0.0
var bump_visual_time := 0.0
var hold_time := 0.0
var last_held_direction := Vector2i.ZERO


func _ready() -> void:
	step_started.connect(func(_origin: Vector2i, _destination: Vector2i): queue_redraw())
	step_finished.connect(_on_step_finished)
	queue_redraw()


func _process(delta: float) -> void:
	attack_visual_time = maxf(0.0, attack_visual_time - delta)
	bump_visual_time = maxf(0.0, bump_visual_time - delta)
	if attack_visual_time > 0.0 or bump_visual_time > 0.0:
		queue_redraw()

	if Input.is_action_just_pressed("attack"):
		try_attack()

	var pressed_direction := _just_pressed_direction()
	if pressed_direction != Vector2i.ZERO:
		if is_moving or attack_on_cooldown:
			buffered_direction = pressed_direction
		else:
			_attempt_step(pressed_direction)
		hold_time = 0.0
		last_held_direction = pressed_direction
		return

	var held_direction := _held_direction()
	if held_direction == Vector2i.ZERO:
		hold_time = 0.0
		last_held_direction = Vector2i.ZERO
		return

	if held_direction != last_held_direction:
		hold_time = 0.0
		last_held_direction = held_direction
	else:
		hold_time += delta

	if not is_moving and not attack_on_cooldown and hold_time >= held_repeat_delay:
		hold_time = 0.0
		_attempt_step(held_direction)


func _just_pressed_direction() -> Vector2i:
	for action in DIRECTIONS:
		if Input.is_action_just_pressed(action):
			return DIRECTIONS[action]
	return Vector2i.ZERO


func _held_direction() -> Vector2i:
	for action in DIRECTIONS:
		if Input.is_action_pressed(action):
			return DIRECTIONS[action]
	return Vector2i.ZERO


func _attempt_step(direction: Vector2i) -> void:
	if not try_step(direction):
		bump_visual_time = 0.10
		queue_redraw()


func _on_step_finished(_destination: Vector2i) -> void:
	queue_redraw()
	if buffered_direction != Vector2i.ZERO and not attack_on_cooldown:
		var direction := buffered_direction
		buffered_direction = Vector2i.ZERO
		_attempt_step(direction)


func try_attack() -> bool:
	if attack_on_cooldown or is_moving or grid_world == null:
		return false
	attack_on_cooldown = true
	attack_visual_time = 0.16
	queue_redraw()
	var target_cell := get_attack_cell()
	await get_tree().create_timer(0.07).timeout
	var target := grid_world.actor_at(target_cell)
	var hit := target != null and target != self and target.has_method("take_damage")
	if hit:
		target.take_damage(1, facing)
	emit_signal("attack_landed", target_cell, hit)
	await get_tree().create_timer(maxf(0.0, attack_recovery - 0.07)).timeout
	attack_on_cooldown = false
	if buffered_direction != Vector2i.ZERO:
		var direction := buffered_direction
		buffered_direction = Vector2i.ZERO
		_attempt_step(direction)
	return true


func get_attack_cell() -> Vector2i:
	return current_cell + facing


func take_damage(amount: int, _direction := Vector2i.ZERO) -> void:
	courage = maxi(0, courage - amount)
	emit_signal("courage_changed", courage)
	queue_redraw()


func _draw() -> void:
	var bob := -2.0 if is_moving else 0.0
	if bump_visual_time > 0.0:
		bob += sin(bump_visual_time * 80.0) * 2.0
	_draw_pixel_ellipse(Vector2(0, 9), Vector2(11, 4), Color(0.08, 0.06, 0.08, 0.38))
	draw_circle(Vector2(0, -10 + bob), 6.0, Color("#fff4d6"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5, -4 + bob), Vector2(5, -4 + bob), Vector2(9, 7 + bob), Vector2(-9, 7 + bob)
	]), Color("#f2dfb6"))
	draw_rect(Rect2(-11, 6 + bob, 22, 5), Color("#fff4d6"))
	draw_line(Vector2(-11, 11 + bob), Vector2(11, 11 + bob), Color("#493f3a"), 2.0)
	draw_circle(Vector2(-2, -11 + bob), 1.0, Color("#493f3a"))

	var sword_start := Vector2(facing) * 6.0 + Vector2(0, bob)
	var sword_end := Vector2(facing) * (25.0 if attack_visual_time > 0.0 else 15.0) + Vector2(0, bob)
	draw_line(sword_start, sword_end, Color("#f5c542"), 3.0)
	draw_line(sword_start + Vector2(-facing.y, facing.x) * 4.0, sword_start - Vector2(-facing.y, facing.x) * 4.0, Color("#7b4d2c"), 2.0)
	if attack_visual_time > 0.0:
		var side := Vector2(-facing.y, facing.x)
		draw_polyline(PackedVector2Array([
			sword_end - side * 8.0,
			sword_end + Vector2(facing) * 5.0,
			sword_end + side * 8.0,
		]), Color("#fff2a8"), 3.0)


func _draw_pixel_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 16:
		var angle := TAU * float(index) / 16.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
