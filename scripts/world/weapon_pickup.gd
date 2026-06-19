class_name WeaponPickup
extends Node2D

signal collected(pickup: WeaponPickup, collector: Node)

var grid_world: GridWorld
var current_cell := Vector2i.ZERO
var weapon: EnemyWeapon


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


func _draw() -> void:
	if weapon == null:
		return
	_draw_shadow()
	if weapon.shape == EnemyWeapon.Shape.LINE:
		draw_line(Vector2(-10, 8), Vector2(10, -8), weapon.color, 4.0)
		draw_line(Vector2(-12, 5), Vector2(-7, 10), Color("#6b4f3c"), 3.0)
	else:
		draw_rect(Rect2(-11, -3, 22, 7), weapon.color)
		for x in range(-8, 10, 4):
			draw_line(Vector2(x, -3), Vector2(x, 1), Color("#6b4f3c"), 1.0)


func _draw_shadow() -> void:
	var points := PackedVector2Array()
	for index in 16:
		var angle := TAU * float(index) / 16.0
		points.append(Vector2(cos(angle) * 13.0, 8.0 + sin(angle) * 4.0))
	draw_colored_polygon(points, Color(0.05, 0.04, 0.05, 0.35))
