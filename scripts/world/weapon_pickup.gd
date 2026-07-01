class_name WeaponPickup
extends Node2D

signal collected(pickup: WeaponPickup, collector: Node)

var grid_world: GridWorld
var current_cell := Vector2i.ZERO
var weapon: EnemyWeapon
var visual_time := 0.0


func setup(world: GridWorld, cell: Vector2i, item: EnemyWeapon) -> bool:
	grid_world = world
	current_cell = cell
	weapon = item
	if not grid_world.register_item(self, current_cell):
		return false
	position = grid_world.cell_to_world(current_cell)
	queue_redraw()
	return true


func take(collector: Node) -> EnemyWeapon:
	if weapon == null:
		return null
	var taken := weapon
	weapon = null
	grid_world.unregister_item(self)
	emit_signal("collected", self, collector)
	queue_free()
	return taken


func _exit_tree() -> void:
	if grid_world != null:
		grid_world.unregister_item(self)


func _process(delta: float) -> void:
	visual_time += delta
	queue_redraw()


func _draw() -> void:
	if weapon == null:
		return
	var pulse := 0.5 + 0.5 * sin(visual_time * TAU * 2.0)
	var bob := Vector2(0.0, -1.5 - pulse * 2.0)
	_draw_shadow()
	_draw_glow(pulse)
	if weapon.shape == EnemyWeapon.Shape.LINE:
		draw_line(Vector2(-10, 8) + bob, Vector2(10, -8) + bob, weapon.color, 4.0)
		draw_line(Vector2(-12, 5) + bob, Vector2(-7, 10) + bob, Color("#6b4f3c"), 3.0)
	else:
		draw_rect(Rect2(Vector2(-11, -3) + bob, Vector2(22, 7)), weapon.color)
		for x in range(-8, 10, 4):
			draw_line(Vector2(x, -3) + bob, Vector2(x, 1) + bob, Color("#6b4f3c"), 1.0)

	var sparkle_color := Color("#fff4d6", 0.70 + pulse * 0.25)
	draw_line(Vector2(13, -12) + bob, Vector2(13, -5) + bob, sparkle_color, 1.2)
	draw_line(Vector2(9, -8) + bob, Vector2(17, -8) + bob, sparkle_color, 1.2)


func _draw_glow(pulse: float) -> void:
	var glow := weapon.color
	glow.a = 0.18 + pulse * 0.10
	draw_circle(Vector2(0, 1), 15.0 + pulse * 3.0, glow)
	draw_arc(Vector2(0, 1), 16.0 + pulse * 2.0, 0.0, TAU, 24, Color("#fff2a8", 0.28 + pulse * 0.18), 1.5)


func _draw_shadow() -> void:
	var points := PackedVector2Array()
	for index in 16:
		var angle := TAU * float(index) / 16.0
		points.append(Vector2(cos(angle) * 13.0, 8.0 + sin(angle) * 4.0))
	draw_colored_polygon(points, Color(0.05, 0.04, 0.05, 0.35))
