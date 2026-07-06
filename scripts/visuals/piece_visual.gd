class_name PieceVisual
extends Node2D

enum PieceKind { HERO_PAWN, BLACK_PAWN, BLACK_KNIGHT }
const ENEMY_STATE_TELEGRAPH := 1

@export var piece_kind := PieceKind.HERO_PAWN
@export var body_color := Color("#fff4d6")
@export var hurt_color := Color("#ff8170")
@export var flash_color := Color.WHITE
@export var telegraph_color := Color("#5a2025")
@export var accent_color := Color("#d84a3a")
@export var eye_color := Color("#493f3a")
@export var shadow_color := Color(0.05, 0.04, 0.05, 0.35)
@export var warning_color := Color("#ff665e")
@export var warning_ring_color := Color("#fff2a8")
@export var default_weapon_color := Color("#f5c542")
@export var handle_color := Color("#7b4d2c")
@export var show_health := false
@export var show_facing_mark := true
@export var weapon_anchor := Vector2(5, -2)
@export_range(1.0, 32.0, 0.5) var weapon_rest_length := 18.0

var facing := Vector2i.UP
var cell_size := 32
var is_moving := false
var is_invulnerable := false
var bump_time := 0.0
var hurt_time := 0.0
var flash_time := 0.0
var recoil := Vector2.ZERO
var attack_visual_time := 0.0
var attack_range := 1
var active_weapon_color := Color("#f5c542")
var weapon_visible := false
var telegraph_active := false
var telegraph_progress := 0.0
var health := 1
var max_health := 1


func sync_from_hero(hero: Node) -> void:
	facing = hero.get("facing")
	var world = hero.get("grid_world")
	cell_size = world.cell_size if world != null else cell_size
	is_moving = hero.get("is_moving")
	is_invulnerable = hero.get("is_invulnerable")
	bump_time = hero.get("bump_visual_time")
	hurt_time = hero.get("hurt_visual_time")
	attack_visual_time = hero.get("attack_visual_time")
	var active_attack = hero.get("active_attack")
	attack_range = active_attack.get("range_cells") if active_attack != null else 1
	active_weapon_color = active_attack.get("color") if active_attack != null else default_weapon_color
	weapon_visible = true
	telegraph_active = false
	recoil = Vector2.ZERO
	queue_redraw()


func sync_from_enemy(enemy: Node) -> void:
	facing = enemy.get("facing")
	var world = enemy.get("grid_world")
	cell_size = world.cell_size if world != null else cell_size
	recoil = enemy.get("recoil")
	flash_time = enemy.get("flash_time")
	telegraph_active = enemy.get("state") == ENEMY_STATE_TELEGRAPH
	telegraph_progress = enemy.call("get_telegraph_progress") if enemy.has_method("get_telegraph_progress") else 0.0
	var enemy_weapon = enemy.get("weapon")
	weapon_visible = enemy_weapon != null
	active_weapon_color = enemy_weapon.get("color") if enemy_weapon != null else default_weapon_color
	health = enemy.get("health")
	max_health = enemy.call("get_max_health") if enemy.has_method("get_max_health") else maxi(health, 1)
	queue_redraw()


func _draw() -> void:
	if is_invulnerable and int(Time.get_ticks_msec() / 70.0) % 2 == 0:
		return
	match piece_kind:
		PieceKind.BLACK_KNIGHT:
			_draw_knight()
		PieceKind.BLACK_PAWN:
			_draw_enemy_pawn()
		_:
			_draw_hero_pawn()


func _current_body_color() -> Color:
	if flash_time > 0.0:
		return flash_color
	if hurt_time > 0.0:
		return hurt_color
	if telegraph_active:
		return telegraph_color
	return body_color


func _draw_hero_pawn() -> void:
	var bob := -2.0 if is_moving else 0.0
	if bump_time > 0.0:
		bob += sin(bump_time * 80.0) * 2.0
	var fill := _current_body_color()
	_draw_pixel_ellipse(Vector2(0, 9), Vector2(11, 4), Color(0.08, 0.06, 0.08, 0.38))
	draw_circle(Vector2(0, -10 + bob), 6.0, fill)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5, -4 + bob), Vector2(5, -4 + bob), Vector2(9, 7 + bob), Vector2(-9, 7 + bob)
	]), fill.darkened(0.08))
	draw_rect(Rect2(-11, 6 + bob, 22, 5), fill)
	draw_line(Vector2(-11, 11 + bob), Vector2(11, 11 + bob), eye_color, 2.0)
	draw_circle(Vector2(-2, -11 + bob), 1.0, eye_color)
	_draw_hero_weapon(bob)


func _draw_enemy_pawn() -> void:
	var fill := _current_body_color()
	_draw_pixel_ellipse(Vector2(0, 9) + recoil, Vector2(10, 4), shadow_color)
	_draw_attack_warning_aura()
	draw_circle(Vector2(0, -9) + recoil, 6.0, fill)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5, -3) + recoil, Vector2(5, -3) + recoil,
		Vector2(9, 7) + recoil, Vector2(-9, 7) + recoil
	]), fill)
	draw_rect(Rect2(Vector2(-11, 6) + recoil, Vector2(22, 5)), fill)
	draw_line(Vector2(-11, 11) + recoil, Vector2(11, 11) + recoil, accent_color, 2.0)
	_draw_facing_mark()
	_draw_enemy_weapon()
	_draw_health_pips()


func _draw_knight() -> void:
	var fill := _current_body_color()
	_draw_pixel_ellipse(Vector2(0, 10) + recoil, Vector2(11, 4), shadow_color)
	_draw_attack_warning_aura()
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
	draw_circle(Vector2(3, -7) + recoil, 1.2, accent_color)
	draw_rect(Rect2(Vector2(-11, 7) + recoil, Vector2(22, 5)), fill)
	_draw_enemy_weapon()
	_draw_health_pips()


func _draw_hero_weapon(bob: float) -> void:
	if not weapon_visible:
		return
	var visual_range: int = maxi(int(attack_range), 1)
	var sword_start := Vector2(facing) * 6.0 + Vector2(0, bob)
	var active_length := float(visual_range * cell_size) - 7.0
	var sword_end := Vector2(facing) * (active_length if attack_visual_time > 0.0 else weapon_rest_length) + Vector2(0, bob)
	draw_line(sword_start, sword_end, active_weapon_color, 3.0)
	draw_line(sword_start + Vector2(-facing.y, facing.x) * 4.0, sword_start - Vector2(-facing.y, facing.x) * 4.0, handle_color, 2.0)
	if attack_visual_time > 0.0:
		var side := Vector2(-facing.y, facing.x)
		draw_polyline(PackedVector2Array([
			sword_end - side * 8.0,
			sword_end + Vector2(facing) * 5.0,
			sword_end + side * 8.0,
		]), active_weapon_color.lightened(0.25), 3.0)


func _draw_enemy_weapon() -> void:
	if not weapon_visible:
		return
	var start := recoil + weapon_anchor
	var finish := recoil + Vector2(facing) * weapon_rest_length
	draw_line(start, finish, active_weapon_color, 3.0)


func _draw_facing_mark() -> void:
	if not show_facing_mark:
		return
	var side := Vector2(-facing.y, facing.x)
	var tip := recoil + Vector2(facing) * 13.0
	draw_polyline(PackedVector2Array([
		tip - Vector2(facing) * 4.0 + side * 3.0,
		tip,
		tip - Vector2(facing) * 4.0 - side * 3.0,
	]), accent_color.lightened(0.16), 2.0)


func _draw_health_pips() -> void:
	if not show_health:
		return
	var pip_count := maxi(max_health, 1)
	var start_x := -float(pip_count * 6 - 2) / 2.0
	for index in pip_count:
		var filled := index < health
		var pip_color := Color("#ff9a75") if filled else Color("#493f3a", 0.88)
		var outline := Color("#fff4d6", 0.80) if filled else Color("#241b22", 0.86)
		var rect := Rect2(Vector2(start_x + index * 6.0, -25.0), Vector2(4.0, 4.0))
		draw_rect(rect, pip_color)
		draw_rect(rect, outline, false, 1.0)


func _draw_attack_warning_aura() -> void:
	if not telegraph_active:
		return
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * TAU * 5.0)
	var fill := Color(warning_color, 0.20 + telegraph_progress * 0.26 + pulse * 0.08)
	var ring := Color(warning_ring_color, 0.62 + telegraph_progress * 0.30)
	var radius := lerpf(15.0, 22.0, pulse)
	draw_circle(recoil, radius, fill)
	draw_arc(recoil, radius + 2.0, -PI / 2.0, -PI / 2.0 + TAU * telegraph_progress, 24, ring, 2.4)
	if facing == Vector2i.ZERO:
		return
	var aim := Vector2(facing).normalized()
	var side := Vector2(-aim.y, aim.x)
	var tip := recoil + aim * (17.0 + telegraph_progress * 5.0)
	var base := recoil + aim * 6.0
	draw_line(base, tip, Color("#fff4d6", 0.82), 2.0)
	draw_polyline(PackedVector2Array([tip - aim * 5.0 + side * 4.0, tip, tip - aim * 5.0 - side * 4.0]), Color("#fff4d6", 0.9), 2.0)


func _draw_pixel_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 16:
		var angle := TAU * float(index) / 16.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
