class_name PickupVisual
extends Node2D

@export var shadow_color := Color(0.05, 0.04, 0.05, 0.35)
@export var glow_ring_color := Color("#fff2a8")
@export var handle_color := Color("#6b4f3c")
@export var sparkle_color := Color("#fff4d6")
@export var preview_weapon: EnemyWeapon

var weapon: EnemyWeapon
var visual_time := 0.0


func sync_from_pickup(pickup: Node) -> void:
	weapon = pickup.get("weapon")
	visual_time = pickup.get("visual_time")
	queue_redraw()


func _draw() -> void:
	var display_weapon := weapon if weapon != null else preview_weapon
	if display_weapon == null:
		return
	var pulse := 0.5 + 0.5 * sin(visual_time * TAU * 2.0)
	var bob := Vector2(0.0, -1.5 - pulse * 2.0)
	_draw_shadow()
	_draw_glow(pulse, display_weapon)
	if display_weapon.shape == EnemyWeapon.Shape.LINE:
		draw_line(Vector2(-10, 8) + bob, Vector2(10, -8) + bob, display_weapon.color, 4.0)
		draw_line(Vector2(-12, 5) + bob, Vector2(-7, 10) + bob, handle_color, 3.0)
	else:
		draw_rect(Rect2(Vector2(-11, -3) + bob, Vector2(22, 7)), display_weapon.color)
		for x in range(-8, 10, 4):
			draw_line(Vector2(x, -3) + bob, Vector2(x, 1) + bob, handle_color, 1.0)

	var sparkle := Color(sparkle_color, 0.70 + pulse * 0.25)
	draw_line(Vector2(13, -12) + bob, Vector2(13, -5) + bob, sparkle, 1.2)
	draw_line(Vector2(9, -8) + bob, Vector2(17, -8) + bob, sparkle, 1.2)


func _draw_glow(pulse: float, display_weapon: EnemyWeapon) -> void:
	var glow := display_weapon.color
	glow.a = 0.18 + pulse * 0.10
	draw_circle(Vector2(0, 1), 15.0 + pulse * 3.0, glow)
	draw_arc(Vector2(0, 1), 16.0 + pulse * 2.0, 0.0, TAU, 24, Color(glow_ring_color, 0.28 + pulse * 0.18), 1.5)


func _draw_shadow() -> void:
	var points := PackedVector2Array()
	for index in 16:
		var angle := TAU * float(index) / 16.0
		points.append(Vector2(cos(angle) * 13.0, 8.0 + sin(angle) * 4.0))
	draw_colored_polygon(points, shadow_color)
