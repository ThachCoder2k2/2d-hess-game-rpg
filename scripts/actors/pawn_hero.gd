class_name PawnHero
extends GridActor

signal courage_changed(value: int)
signal damaged(amount: int, remaining: int)
signal attack_landed(target_cells: Array[Vector2i], hit_count: int, profile: AttackProfile)
signal skill_cooldown_changed(time_left: float)
signal defeated

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
var skill_cooldown_left := 0.0
var is_invulnerable := false
var control_enabled := true

## Behavior components (input/combat/health), mirroring the enemy skeleton.
## Scene children normally; combat/health are created on demand so bare-script
## instances (tests) still work without a scene.
var input_component: PlayerInputComponent
var combat_component: PlayerCombatComponent
var health_component: PlayerHealthComponent

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
	_configure_components()
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


func try_turn(direction: Vector2i) -> bool:
	if direction == Vector2i.ZERO or is_moving or attack_on_cooldown or not control_enabled:
		return false
	facing = direction
	buffered_direction = Vector2i.ZERO
	return true


func _attempt_step(direction: Vector2i) -> void:
	if not try_step(direction):
		bump_visual_time = 0.10


func _on_step_finished(_destination: Vector2i) -> void:
	_flush_buffered_step()


func _flush_buffered_step() -> void:
	if buffered_direction == Vector2i.ZERO or attack_on_cooldown or not control_enabled:
		return
	var direction := buffered_direction
	buffered_direction = Vector2i.ZERO
	_attempt_step(direction)


func try_attack(profile: AttackProfile = null) -> bool:
	return await _resolve_combat_component().try_attack(profile)


func try_skill() -> bool:
	return _resolve_combat_component().try_skill()


func can_start_attack() -> bool:
	return _resolve_combat_component().can_start_attack()


func get_attack_cells(profile: AttackProfile = null) -> Array[Vector2i]:
	_ensure_attack_profiles()
	if profile == null:
		profile = wooden_sword
	return profile.get_target_cells(current_cell, facing)


func get_attack_cell() -> Vector2i:
	return current_cell + facing


func take_damage(amount: int, _direction := Vector2i.ZERO) -> bool:
	return _resolve_health_component().apply_damage(amount)


## Scene children are the normal path; combat/health are created on demand so a
## bare-script PawnHero (tests) still fights and takes damage without a scene.
## Input is scene-only: a bare instance simply has no controls, which is correct.
func _configure_components() -> void:
	input_component = get_node_or_null("PlayerInputComponent") as PlayerInputComponent
	if input_component != null:
		input_component.configure(self)
	_resolve_combat_component()
	_resolve_health_component()


func _resolve_combat_component() -> PlayerCombatComponent:
	if combat_component == null or not is_instance_valid(combat_component):
		combat_component = get_node_or_null("PlayerCombatComponent") as PlayerCombatComponent
	if combat_component == null:
		combat_component = PlayerCombatComponent.new()
		combat_component.name = "PlayerCombatComponent"
		add_child(combat_component)
	combat_component.configure(self)
	return combat_component


func _resolve_health_component() -> PlayerHealthComponent:
	if health_component == null or not is_instance_valid(health_component):
		health_component = get_node_or_null("PlayerHealthComponent") as PlayerHealthComponent
	if health_component == null:
		health_component = PlayerHealthComponent.new()
		health_component.name = "PlayerHealthComponent"
		add_child(health_component)
	health_component.configure(self)
	return health_component


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if get_node_or_null("PlayerInputComponent") is not PlayerInputComponent:
		warnings.append("PlayerInputComponent is missing (no controls).")
	if get_node_or_null("PlayerCombatComponent") is not PlayerCombatComponent:
		warnings.append("PlayerCombatComponent is missing.")
	if get_node_or_null("PlayerHealthComponent") is not PlayerHealthComponent:
		warnings.append("PlayerHealthComponent is missing.")
	return warnings


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
