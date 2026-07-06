class_name PickupVisual
extends Node2D

@export var preview_weapon: EnemyWeapon
@export var pickup_sprite_path: NodePath = ^"MotionRoot/SpriteRoot/PickupSprite"
@export var glow_sprite_path: NodePath = ^"GlowSprite"
@export var animation_player_path: NodePath = ^"AnimationPlayer"
@export var combined_pickup_texture: Texture2D
@export var spear_texture: Texture2D
@export var ruler_blade_texture: Texture2D

var weapon: EnemyWeapon
var visual_time := 0.0

var _pickup_sprite: Sprite2D
var _glow_sprite: Sprite2D
var _animation_player: AnimationPlayer


func _ready() -> void:
	_resolve_nodes()
	_play_animation(&"idle")
	_apply_texture()


func sync_from_pickup(pickup: Node) -> void:
	_resolve_nodes()
	weapon = pickup.get("weapon")
	visual_time = pickup.get("visual_time")
	_apply_texture()
	_apply_glow()
	_play_animation(&"idle")


func _resolve_nodes() -> void:
	if _pickup_sprite == null:
		_pickup_sprite = get_node_or_null(pickup_sprite_path) as Sprite2D
	if _glow_sprite == null:
		_glow_sprite = get_node_or_null(glow_sprite_path) as Sprite2D
	if _animation_player == null:
		_animation_player = get_node_or_null(animation_player_path) as AnimationPlayer


func _apply_texture() -> void:
	if _pickup_sprite == null:
		return
	var display_weapon := weapon if weapon != null else preview_weapon
	_pickup_sprite.texture = _texture_for_weapon(display_weapon)


func _apply_glow() -> void:
	if _glow_sprite == null:
		return
	var pulse := 0.5 + 0.5 * sin(visual_time * TAU * 2.0)
	_glow_sprite.scale = Vector2.ONE * (0.60 + pulse * 0.08)
	_glow_sprite.modulate.a = 0.34 + pulse * 0.22


func _texture_for_weapon(display_weapon: EnemyWeapon) -> Texture2D:
	if display_weapon == null:
		return combined_pickup_texture
	if display_weapon.id == &"ruler_blade":
		return ruler_blade_texture if ruler_blade_texture != null else combined_pickup_texture
	if display_weapon.id == &"pencil_spear":
		return spear_texture if spear_texture != null else combined_pickup_texture
	if display_weapon.shape == EnemyWeapon.Shape.FAN:
		return ruler_blade_texture if ruler_blade_texture != null else combined_pickup_texture
	return spear_texture if spear_texture != null else combined_pickup_texture


func _play_animation(animation_name: StringName) -> void:
	if _animation_player == null or not _animation_player.has_animation(animation_name):
		return
	if _animation_player.current_animation == animation_name and _animation_player.is_playing():
		return
	_animation_player.play(animation_name)
