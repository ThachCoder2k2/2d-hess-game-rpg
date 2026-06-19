class_name PrototypeBoard
extends Node2D

var grid_world: GridWorld
var highlighted_cell := Vector2i(-1, -1)
var hit_flash_time := 0.0
var hit_success := false


func setup(world: GridWorld) -> void:
	grid_world = world
	queue_redraw()


func show_attack(cell: Vector2i, hit: bool) -> void:
	highlighted_cell = cell
	hit_success = hit
	hit_flash_time = 0.14
	queue_redraw()


func _process(delta: float) -> void:
	if hit_flash_time > 0.0:
		hit_flash_time = maxf(0.0, hit_flash_time - delta)
		queue_redraw()


func _draw() -> void:
	if grid_world == null:
		return
	var origin := grid_world.grid_origin
	var size := grid_world.cell_size
	draw_rect(Rect2(origin - Vector2(12, 12), Vector2(grid_world.bounds.size * size) + Vector2(24, 24)), Color("#30242a"))
	for y in grid_world.bounds.size.y:
		for x in grid_world.bounds.size.x:
			var cell := Vector2i(x, y)
			var color := Color("#c9a77d") if (x + y) % 2 == 0 else Color("#7f5f51")
			draw_rect(Rect2(origin + Vector2(cell * size), Vector2.ONE * size), color)
			draw_rect(Rect2(origin + Vector2(cell * size), Vector2.ONE * size), Color(0.18, 0.12, 0.14, 0.25), false, 1.0)

	for cell in grid_world.blocked_cells:
		var top_left := origin + Vector2(cell * size)
		draw_rect(Rect2(top_left + Vector2(3, 3), Vector2(size - 6, size - 6)), Color("#e8b83f"))
		draw_rect(Rect2(top_left + Vector2(7, 7), Vector2(size - 14, size - 14)), Color("#f5d56d"), false, 2.0)

	if hit_flash_time > 0.0 and grid_world.is_inside(highlighted_cell):
		var flash_color := Color("#fff2a8", 0.72) if hit_success else Color("#d84a3a", 0.62)
		draw_rect(Rect2(origin + Vector2(highlighted_cell * size), Vector2.ONE * size), flash_color)

	_draw_playground_border(origin, size)


func _draw_playground_border(origin: Vector2, size: int) -> void:
	var board_width := grid_world.bounds.size.x * size
	var board_height := grid_world.bounds.size.y * size
	for y in range(0, board_height, 64):
		var color := Color("#2c78c4") if int(y / 64) % 2 == 0 else Color("#4e8a66")
		draw_rect(Rect2(origin + Vector2(-10, y + 9), Vector2(7, 18)), color)
		draw_rect(Rect2(origin + Vector2(board_width + 3, y + 37), Vector2(7, 18)), color)
