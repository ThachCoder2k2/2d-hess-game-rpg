class_name PawnHero
extends GridActor

signal courage_changed(value: int)
signal attack_landed(target_cells: Array[Vector2i], hit_count: int, profile: AttackProfile)
signal skill_cooldown_changed(time_left: float)
signal defeated

const DIRECTIONS := {
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN,
	"move_left": Vector2i.LEFT,
	"move_right": Vector2i.RIGHT,
}

@export var courage := 3
@export var held_repeat_delay := 0.22
@export var invulnerability_duration := 0.70
@export var pencil_thrust_cooldown := 1.25

var wooden_sword: AttackProfile
var pencil_thrust: AttackProfile
var buffered_direction := Vector2i.ZERO
var attack_on_cooldown := false
var active_attack: AttackProfile
var attack_visual_time := 0.0
var bump_visual_time := 0.0
var hurt_visual_time := 0.0
var hold_time := 0.0
var skill_cooldown_left := 0.0
var last_held_direction := Vector2i.ZERO
var is_invulnerable := false
var control_enabled := true


func _ready() -> void:
	wooden_sword = AttackProfile.new()
	wooden_sword.display_name = "Wooden Sword"
	wooden_sword.range_cells = 1
	wooden_sword.damage = 1
	wooden_sword.impact_delay = 0.07
	wooden_sword.recovery = 0.30
	wooden_sword.color = Color("#fff2a8")

	pencil_thrust = AttackProfile.new()
	pencil_thrust.display_name = "Pencil Thrust"
	pencil_thrust.range_cells = 2
	pencil_thrust.damage = 1
	pencil_thrust.impact_delay = 0.11
	pencil_thrust.recovery = 0.52
	pencil_thrust.color = Color("#8ec8e8")

	step_started.connect(func(_origin: Vector2i, _destination: Vector2i): queue_redraw())
	step_finished.connect(_on_step_finished)
	queue_redraw()


func _process(delta: float) -> void:
	attack_visual_time = maxf(0.0, attack_visual_time - delta)
	bump_visual_time = maxf(0.0, bump_visual_time - delta)
	hurt_visual_time = maxf(0.0, hurt_visual_time - delta)
	if skill_cooldown_left > 0.0:
		skill_cooldown_left = maxf(0.0, skill_cooldown_left - delta)
		emit_signal("skill_cooldown_changed", skill_cooldown_left)
	if attack_visual_time > 0.0 or bump_visual_time > 0.0 or hurt_visual_time > 0.0:
		queue_redraw()

	if not control_enabled:
		return

	if Input.is_action_just_pressed("attack"):
		try_attack(wooden_sword)
	if Input.is_action_just_pressed("skill_1") and skill_cooldown_left <= 0.0:
		if can_start_attack():
			skill_cooldown_left = pencil_thrust_cooldown
			emit_signal("skill_cooldown_changed", skill_cooldown_left)
			try_attack(pencil_thrust)

	var pressed_direction := _just_pressed_direction()
	if pressed_direction != Vector2i.ZERO:
		if Input.is_action_pressed("turn_mode"):
			try_turn(pressed_direction)
		elif is_moving or attack_on_cooldown:
			buffered_direction = pressed_direction
		else:
			_attempt_step(pressed_direction)
		hold_time = 0.0
		last_held_direction = pressed_direction
		return

	if Input.is_action_pressed("turn_mode"):
		hold_time = 0.0
		last_held_direction = Vector2i.ZERO
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


func try_turn(direction: Vector2i) -> bool:
	if direction == Vector2i.ZERO or is_moving or attack_on_cooldown or not control_enabled:
		return false
	facing = direction
	buffered_direction = Vector2i.ZERO
	queue_redraw()
	return true


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
	if buffered_direction != Vector2i.ZERO and not attack_on_cooldown and control_enabled:
		var direction := buffered_direction
		buffered_direction = Vector2i.ZERO
		_attempt_step(direction)


func try_attack(profile: AttackProfile = null) -> bool:
	if profile == null:
		profile = wooden_sword
	if not can_start_attack():
		return false
	attack_on_cooldown = true
	active_attack = profile
	attack_visual_time = profile.impact_delay + 0.10
	queue_redraw()
	var target_cells := profile.get_target_cells(current_cell, facing)
	await get_tree().create_timer(profile.impact_delay).timeout
	var hit_count := 0
	var hit_actors: Dictionary = {}
	for target_cell in target_cells:
		var target := grid_world.actor_at(target_cell)
		if target != null and target != self and target.has_method("take_damage") and not hit_actors.has(target):
			target.take_damage(profile.damage, facing)
			hit_actors[target] = true
			hit_count += 1
	emit_signal("attack_landed", target_cells, hit_count, profile)
	await get_tree().create_timer(maxf(0.0, profile.recovery - profile.impact_delay)).timeout
	attack_on_cooldown = false
	active_attack = null
	if buffered_direction != Vector2i.ZERO and control_enabled:
		var direction := buffered_direction
		buffered_direction = Vector2i.ZERO
		_attempt_step(direction)
	return true


func can_start_attack() -> bool:
	return not attack_on_cooldown and not is_moving and grid_world != null and control_enabled


func get_attack_cells(profile: AttackProfile = null) -> Array[Vector2i]:
	if profile == null:
		profile = wooden_sword
	return profile.get_target_cells(current_cell, facing)


func get_attack_cell() -> Vector2i:
	return current_cell + facing


func take_damage(amount: int, _direction := Vector2i.ZERO) -> bool:
	if is_invulnerable or courage <= 0:
		return false
	courage = maxi(0, courage - amount)
	hurt_visual_time = 0.18
	emit_signal("courage_changed", courage)
	queue_redraw()
	if courage <= 0:
		control_enabled = false
		emit_signal("defeated")
	else:
		_start_invulnerability()
	return true


func _start_invulnerability() -> void:
	is_invulnerable = true
	await get_tree().create_timer(invulnerability_duration).timeout
	is_invulnerable = false
	queue_redraw()


func _draw() -> void:
	if is_invulnerable and int(Time.get_ticks_msec() / 70) % 2 == 0:
		return
	var bob := -2.0 if is_moving else 0.0
	if bump_visual_time > 0.0:
		bob += sin(bump_visual_time * 80.0) * 2.0
	var body_color := Color("#ff8170") if hurt_visual_time > 0.0 else Color("#fff4d6")
	_draw_pixel_ellipse(Vector2(0, 9), Vector2(11, 4), Color(0.08, 0.06, 0.08, 0.38))
	draw_circle(Vector2(0, -10 + bob), 6.0, body_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5, -4 + bob), Vector2(5, -4 + bob), Vector2(9, 7 + bob), Vector2(-9, 7 + bob)
	]), body_color.darkened(0.08))
	draw_rect(Rect2(-11, 6 + bob, 22, 5), body_color)
	draw_line(Vector2(-11, 11 + bob), Vector2(11, 11 + bob), Color("#493f3a"), 2.0)
	draw_circle(Vector2(-2, -11 + bob), 1.0, Color("#493f3a"))

	var visual_range := active_attack.range_cells if active_attack != null else 1
	var weapon_color := active_attack.color if active_attack != null else Color("#f5c542")
	var sword_start := Vector2(facing) * 6.0 + Vector2(0, bob)
	var rest_length := 15.0
	var active_length := float(visual_range * grid_world.cell_size) - 7.0 if grid_world != null else 25.0
	var sword_end := Vector2(facing) * (active_length if attack_visual_time > 0.0 else rest_length) + Vector2(0, bob)
	draw_line(sword_start, sword_end, weapon_color, 3.0)
	draw_line(sword_start + Vector2(-facing.y, facing.x) * 4.0, sword_start - Vector2(-facing.y, facing.x) * 4.0, Color("#7b4d2c"), 2.0)
	if attack_visual_time > 0.0:
		var side := Vector2(-facing.y, facing.x)
		draw_polyline(PackedVector2Array([
			sword_end - side * 8.0,
			sword_end + Vector2(facing) * 5.0,
			sword_end + side * 8.0,
		]), weapon_color.lightened(0.25), 3.0)


func _draw_pixel_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 16:
		var angle := TAU * float(index) / 16.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
