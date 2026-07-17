class_name PawnHero
extends GridActor

signal courage_changed(value: int)
signal damaged(amount: int, remaining: int)
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
@export var wooden_sword: AttackProfile
@export var pencil_thrust: AttackProfile

@export_group("Appearance")
@export var hurt_modulate := Color("#ff8170")
@export var weapon_anchor := Vector2(4, -14)
@export_range(1.0, 64.0, 0.5) var weapon_rest_length := 18.0
## Shown while attacking when the active profile has no texture of its own.
@export var default_weapon_texture: Texture2D
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

## Edge-detection memory for choosing animation clips (play once on state change).
var _was_hurt := false
var _was_attacking := false

@onready var _motion_root: Node2D = get_node_or_null("MotionRoot")
@onready var _body_sprite: Sprite2D = get_node_or_null("MotionRoot/SpriteRoot/BodySprite")
@onready var _weapon_pivot: Node2D = get_node_or_null("MotionRoot/SpriteRoot/WeaponPivot")
@onready var _weapon_sprite: Sprite2D = get_node_or_null("MotionRoot/SpriteRoot/WeaponPivot/WeaponSprite")
@onready var _animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")


func _ready() -> void:
	_ensure_attack_profiles()
	step_finished.connect(_on_step_finished)


func _ensure_attack_profiles() -> void:
	# Scenes assign these in the Inspector; load the shared .tres only as a
	# null-safety fallback for bare-script instances (tests). Tuning lives in
	# the Resource, never duplicated here.
	if wooden_sword == null:
		wooden_sword = load("res://resources/attacks/wooden_sword.tres") as AttackProfile
	if pencil_thrust == null:
		pencil_thrust = load("res://resources/attacks/pencil_thrust.tres") as AttackProfile


func _process(delta: float) -> void:
	attack_visual_time = maxf(0.0, attack_visual_time - delta)
	bump_visual_time = maxf(0.0, bump_visual_time - delta)
	hurt_visual_time = maxf(0.0, hurt_visual_time - delta)
	if skill_cooldown_left > 0.0:
		skill_cooldown_left = maxf(0.0, skill_cooldown_left - delta)
		emit_signal("skill_cooldown_changed", skill_cooldown_left)
	_update_appearance()

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


func _on_step_finished(_destination: Vector2i) -> void:
	if buffered_direction != Vector2i.ZERO and not attack_on_cooldown and control_enabled:
		var direction := buffered_direction
		buffered_direction = Vector2i.ZERO
		_attempt_step(direction)


func try_attack(profile: AttackProfile = null) -> bool:
	_ensure_attack_profiles()
	if profile == null:
		profile = wooden_sword
	if not can_start_attack():
		return false
	attack_on_cooldown = true
	active_attack = profile
	attack_visual_time = profile.impact_delay + 0.10
	var target_cells := profile.get_target_cells(current_cell, facing)
	var tree := get_tree()
	if tree == null:
		attack_on_cooldown = false
		active_attack = null
		return false
	await tree.create_timer(profile.impact_delay).timeout
	if not is_inside_tree():
		return false
	var hit_count := 0
	var hit_actors: Dictionary = {}
	for target_cell in target_cells:
		var target := grid_world.actor_at(target_cell)
		if target != null and target != self and target.has_method("take_damage") and not hit_actors.has(target):
			target.take_damage(profile.damage, facing)
			hit_actors[target] = true
			hit_count += 1
	emit_signal("attack_landed", target_cells, hit_count, profile)
	await tree.create_timer(maxf(0.0, profile.recovery - profile.impact_delay)).timeout
	if not is_inside_tree():
		return false
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
	_ensure_attack_profiles()
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
	emit_signal("damaged", amount, courage)
	if courage <= 0:
		control_enabled = false
		emit_signal("defeated")
	else:
		_start_invulnerability()
	return true


func _start_invulnerability() -> void:
	is_invulnerable = true
	if not is_inside_tree():
		is_invulnerable = false
		return
	var tree := get_tree()
	if tree == null:
		is_invulnerable = false
		return
	await tree.create_timer(invulnerability_duration).timeout
	if not is_inside_tree():
		return
	is_invulnerable = false


## The hero drives its own sprites through typed references (canonical structure —
## no visual wrapper). MotionRoot takes procedural offsets; the AnimationPlayer
## animates SpriteRoot, so the two never fight. Null-guarded so bare-script
## instances in tests run headless without any sprites.
func _update_appearance() -> void:
	if _body_sprite == null:
		return
	var tint := hurt_modulate if hurt_visual_time > 0.0 else Color.WHITE
	if is_invulnerable and int(Time.get_ticks_msec() / 70.0) % 2 == 0:
		tint.a = 0.35
	_body_sprite.modulate = tint

	var bob := -1.0 if is_moving else 0.0
	if bump_visual_time > 0.0:
		bob += sin(bump_visual_time * 80.0) * 2.0
	_motion_root.position = Vector2(0.0, bob)

	_update_weapon()
	_update_clip()


func _update_weapon() -> void:
	var attacking := attack_visual_time > 0.0
	_weapon_pivot.visible = attacking and facing != Vector2i.ZERO
	if not _weapon_pivot.visible:
		return
	var weapon_texture := default_weapon_texture
	if active_attack != null and active_attack.texture != null:
		weapon_texture = active_attack.texture
	_weapon_sprite.texture = weapon_texture
	_weapon_pivot.position = weapon_anchor + Vector2(facing) * 4.0
	_weapon_pivot.rotation = Vector2(facing).angle() + PI / 2.0
	var reach := 1.0
	if active_attack != null:
		reach = maxf(1.0, float(active_attack.range_cells))
	_weapon_sprite.position = Vector2(0.0, -weapon_rest_length * (1.0 + (reach - 1.0) * 0.28))
	_weapon_sprite.scale = Vector2.ONE * 1.12


func _update_clip() -> void:
	var hurt := hurt_visual_time > 0.0
	var attacking := attack_visual_time > 0.0
	if hurt and not _was_hurt:
		_play_clip(&"hurt")
	elif attacking and not _was_attacking:
		_play_clip(&"attack")
	elif not attacking and not hurt:
		_play_clip(&"step" if is_moving else &"idle")
	_was_hurt = hurt
	_was_attacking = attacking


func _play_clip(clip: StringName) -> void:
	if _animation_player == null or not _animation_player.has_animation(clip):
		return
	if _animation_player.current_animation == clip and _animation_player.is_playing():
		return
	_animation_player.play(clip)
