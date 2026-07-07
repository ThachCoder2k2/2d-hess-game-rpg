class_name PieceVisual
extends Node2D

enum PieceKind { HERO_PAWN, BLACK_PAWN, BLACK_KNIGHT }
const ENEMY_STATE_TELEGRAPH := 1

@export var piece_kind := PieceKind.HERO_PAWN
@export var show_health := false
@export var show_facing_mark := true
@export var motion_root_path: NodePath = ^"MotionRoot"
@export var sprite_root_path: NodePath = ^"MotionRoot/SpriteRoot"
@export var body_sprite_path: NodePath = ^"MotionRoot/SpriteRoot/BodySprite"
@export var weapon_pivot_path: NodePath = ^"MotionRoot/SpriteRoot/WeaponPivot"
@export var weapon_sprite_path: NodePath = ^"MotionRoot/SpriteRoot/WeaponPivot/WeaponSprite"
@export var telegraph_aura_path: NodePath = ^"TelegraphAura"
@export var facing_arrow_path: NodePath = ^"MotionRoot/SpriteRoot/FacingArrow"
@export var health_pips_path: NodePath = ^"MotionRoot/SpriteRoot/HealthPips"
@export var animation_player_path: NodePath = ^"AnimationPlayer"
@export var default_weapon_texture: Texture2D
@export var spear_texture: Texture2D
@export var ruler_blade_texture: Texture2D
@export var full_health_texture: Texture2D
@export var empty_health_texture: Texture2D
@export var normal_modulate := Color.WHITE
@export var hurt_modulate := Color("#ff8170")
@export var flash_modulate := Color.WHITE
@export var telegraph_modulate := Color("#d14a52")
@export var weapon_anchor := Vector2(8, -4)
@export_range(1.0, 64.0, 0.5) var weapon_rest_length := 18.0

var facing := Vector2i.UP
var health := 1
var max_health := 1

var _motion_root: Node2D
var _sprite_root: Node2D
var _body_sprite: Sprite2D
var _weapon_pivot: Node2D
var _weapon_sprite: Sprite2D
var _telegraph_aura: Sprite2D
var _facing_arrow: Sprite2D
var _health_pips: Node2D
var _animation_player: AnimationPlayer
var _was_hurt := false
var _was_attacking := false
var _was_telegraphing := false


func _ready() -> void:
	_resolve_nodes()
	_play_animation(&"idle")


func sync_from_hero(hero: Node) -> void:
	_resolve_nodes()
	facing = hero.get("facing")
	var is_moving: bool = hero.get("is_moving")
	var is_invulnerable: bool = hero.get("is_invulnerable")
	var bump_time: float = hero.get("bump_visual_time")
	var hurt_time: float = hero.get("hurt_visual_time")
	var attack_visual_time: float = hero.get("attack_visual_time")
	var active_attack = hero.get("active_attack")
	var attack_range := 1
	if active_attack != null:
		attack_range = int(active_attack.get("range_cells"))
	var attacking := attack_visual_time > 0.0

	_apply_body_state(hurt_time > 0.0, false, is_invulnerable)
	_apply_recoil(Vector2.ZERO, is_moving, bump_time)
	_apply_facing_mark(false)
	_apply_telegraph(false, 0.0)
	_apply_weapon(attacking, _texture_for_attack(active_attack), attack_range, attacking)
	_apply_health(0, 0)

	if hurt_time > 0.0 and not _was_hurt:
		_play_animation(&"hurt")
	elif attacking and not _was_attacking:
		_play_animation(&"attack")
	elif not attacking and not _was_hurt:
		_play_animation(_locomotion_anim(is_moving))
	_was_hurt = hurt_time > 0.0
	_was_attacking = attacking
	_was_telegraphing = false


func sync_from_enemy(enemy: Node) -> void:
	_resolve_nodes()
	facing = enemy.get("facing")
	var recoil: Vector2 = enemy.get("recoil")
	var flash_time: float = enemy.get("flash_time")
	var telegraphing := int(enemy.get("state")) == ENEMY_STATE_TELEGRAPH
	var telegraph_progress: float = enemy.call("get_telegraph_progress") if enemy.has_method("get_telegraph_progress") else 0.0
	var enemy_weapon = enemy.get("weapon")
	var weapon_visible := enemy_weapon != null
	var is_moving := bool(enemy.get("is_moving"))
	health = int(enemy.get("health"))
	max_health = int(enemy.call("get_max_health")) if enemy.has_method("get_max_health") else maxi(health, 1)

	_apply_body_state(flash_time > 0.0, telegraphing, false)
	_apply_recoil(recoil, false, 0.0)
	_apply_facing_mark(show_facing_mark)
	_apply_telegraph(telegraphing, telegraph_progress)
	_apply_weapon(weapon_visible, _texture_for_weapon(enemy_weapon), 1, false)
	_apply_health(health, max_health)

	if flash_time > 0.0 and not _was_hurt:
		_play_animation(&"hurt")
	elif telegraphing and not _was_telegraphing:
		_play_animation(&"telegraph")
	elif not telegraphing and not _was_hurt:
		_play_animation(_locomotion_anim(is_moving))
	_was_hurt = flash_time > 0.0
	_was_attacking = false
	_was_telegraphing = telegraphing


func _resolve_nodes() -> void:
	if _motion_root == null:
		_motion_root = get_node_or_null(motion_root_path) as Node2D
	if _sprite_root == null:
		_sprite_root = get_node_or_null(sprite_root_path) as Node2D
	if _body_sprite == null:
		_body_sprite = get_node_or_null(body_sprite_path) as Sprite2D
	if _weapon_pivot == null:
		_weapon_pivot = get_node_or_null(weapon_pivot_path) as Node2D
	if _weapon_sprite == null:
		_weapon_sprite = get_node_or_null(weapon_sprite_path) as Sprite2D
	if _telegraph_aura == null:
		_telegraph_aura = get_node_or_null(telegraph_aura_path) as Sprite2D
	if _facing_arrow == null:
		_facing_arrow = get_node_or_null(facing_arrow_path) as Sprite2D
	if _health_pips == null:
		_health_pips = get_node_or_null(health_pips_path) as Node2D
	if _animation_player == null:
		_animation_player = get_node_or_null(animation_player_path) as AnimationPlayer


func _apply_body_state(hurt_or_flash: bool, telegraphing: bool, invulnerable: bool) -> void:
	if _body_sprite == null:
		return
	var tint := normal_modulate
	if telegraphing:
		tint = telegraph_modulate
	elif hurt_or_flash:
		tint = hurt_modulate if piece_kind == PieceKind.HERO_PAWN else flash_modulate
	if invulnerable and int(Time.get_ticks_msec() / 70.0) % 2 == 0:
		tint.a = 0.35
	_body_sprite.modulate = tint


func _apply_recoil(recoil: Vector2, is_moving: bool, bump_time: float) -> void:
	if _motion_root == null:
		return
	var bob := -1.0 if is_moving else 0.0
	if bump_time > 0.0:
		bob += sin(bump_time * 80.0) * 2.0
	_motion_root.position = recoil + Vector2(0.0, bob)


func _apply_facing_mark(visible: bool) -> void:
	if _facing_arrow == null:
		return
	_facing_arrow.visible = visible and facing != Vector2i.ZERO
	if _facing_arrow.visible:
		_facing_arrow.rotation = _rotation_for_facing(facing)


func _apply_telegraph(active: bool, progress: float) -> void:
	if _telegraph_aura == null:
		return
	_telegraph_aura.visible = active
	if active:
		var pulse := 0.92 + progress * 0.25
		_telegraph_aura.scale = Vector2.ONE * pulse
		_telegraph_aura.modulate.a = 0.55 + progress * 0.35


func _apply_weapon(visible: bool, texture: Texture2D, range_cells: int, attacking: bool) -> void:
	if _weapon_pivot == null or _weapon_sprite == null:
		return
	_weapon_pivot.visible = visible and texture != null and facing != Vector2i.ZERO
	if not _weapon_pivot.visible:
		return
	_weapon_sprite.texture = texture
	_weapon_pivot.position = weapon_anchor + Vector2(facing) * 4.0
	_weapon_pivot.rotation = _rotation_for_facing(facing)
	var reach := maxf(1.0, float(range_cells))
	_weapon_sprite.position = Vector2(0.0, -weapon_rest_length * (1.0 + (reach - 1.0) * 0.28))
	_weapon_sprite.scale = Vector2.ONE * (1.12 if attacking else 1.0)


func _apply_health(current: int, maximum: int) -> void:
	if _health_pips == null:
		return
	_health_pips.visible = show_health and maximum > 1
	if not _health_pips.visible:
		return
	var children := _health_pips.get_children()
	for index in children.size():
		var pip := children[index] as Sprite2D
		if pip == null:
			continue
		pip.visible = index < maximum
		pip.texture = full_health_texture if index < current else empty_health_texture


func _texture_for_attack(attack_profile) -> Texture2D:
	if attack_profile == null:
		return default_weapon_texture
	var profile_texture := attack_profile.get("texture") as Texture2D
	if profile_texture != null:
		return profile_texture
	var display_name := String(attack_profile.get("display_name")).to_lower()
	if display_name.contains("pencil") or int(attack_profile.get("range_cells")) > 1:
		return spear_texture if spear_texture != null else default_weapon_texture
	return default_weapon_texture


func _texture_for_weapon(enemy_weapon) -> Texture2D:
	if enemy_weapon == null:
		return default_weapon_texture
	var weapon_texture := enemy_weapon.get("texture") as Texture2D
	if weapon_texture != null:
		return weapon_texture
	var id := String(enemy_weapon.get("id"))
	if id == "ruler_blade":
		return ruler_blade_texture if ruler_blade_texture != null else default_weapon_texture
	if id == "pencil_spear":
		return spear_texture if spear_texture != null else default_weapon_texture
	var shape := int(enemy_weapon.get("shape"))
	if shape == EnemyWeapon.Shape.FAN:
		return ruler_blade_texture if ruler_blade_texture != null else default_weapon_texture
	return spear_texture if spear_texture != null else default_weapon_texture


func _rotation_for_facing(direction: Vector2i) -> float:
	if direction == Vector2i.ZERO:
		return 0.0
	return Vector2(direction).angle() + PI / 2.0


func _locomotion_anim(is_moving: bool) -> StringName:
	if is_moving and _animation_player != null and _animation_player.has_animation(&"step"):
		return &"step"
	return &"idle"


func _play_animation(animation_name: StringName) -> void:
	if _animation_player == null or not _animation_player.has_animation(animation_name):
		return
	if _animation_player.current_animation == animation_name and _animation_player.is_playing():
		return
	_animation_player.play(animation_name)
