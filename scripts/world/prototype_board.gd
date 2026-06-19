class_name PrototypeBoard
extends Node2D

var grid_world: GridWorld
var telegraphs: Dictionary = {}
var impact_cells: Array[Vector2i] = []
var impact_time := 0.0
var impact_color := Color("#fff2a8")


func setup(world: GridWorld) -> void:
	grid_world = world
	queue_redraw()


func show_player_attack(cells: Array[Vector2i], hit_count: int, profile: AttackProfile) -> void:
	impact_cells = cells
	impact_color = profile.color if hit_count > 0 else Color("#d84a3a")
	impact_time = 0.14
	queue_redraw()


func show_enemy_attack(cells: Array[Vector2i]) -> void:
	impact_cells = cells
	impact_color = Color("#ff9a75")
	impact_time = 0.16
	queue_redraw()


func set_telegraph(source: Node, cells: Array[Vector2i]) -> void:
	telegraphs[source] = cells
	queue_redraw()


func clear_telegraph(source: Node) -> void:
	telegraphs.erase(source)
	queue_redraw()


func _process(delta: float) -> void:
	if impact_time > 0.0:
		impact_time = maxf(0.0, impact_time - delta)
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

	for source in telegraphs:
		if not is_instance_valid(source):
			continue
		for cell: Vector2i in telegraphs[source]:
			if grid_world.is_inside(cell):
				var rect := Rect2(origin + Vector2(cell * size), Vector2.ONE * size)
				draw_rect(rect, Color("#d84a3a", 0.48))
				draw_line(rect.position + Vector2(5, 5), rect.end - Vector2(5, 5), Color("#ff9a75"), 2.0)
				draw_line(rect.position + Vector2(size - 5, 5), rect.position + Vector2(5, size - 5), Color("#ff9a75"), 2.0)

	if impact_time > 0.0:
		for cell in impact_cells:
			if grid_world.is_inside(cell):
				draw_rect(Rect2(origin + Vector2(cell * size), Vector2.ONE * size), Color(impact_color, 0.68))

	_draw_playground_border(origin, size)


func _draw_playground_border(origin: Vector2, size: int) -> void:
	var board_width := grid_world.bounds.size.x * size
	var board_height := grid_world.bounds.size.y * size
	for y in range(0, board_height, 64):
		var color := Color("#2c78c4") if int(y / 64) % 2 == 0 else Color("#4e8a66")
		draw_rect(Rect2(origin + Vector2(-10, y + 9), Vector2(7, 18)), color)
		draw_rect(Rect2(origin + Vector2(board_width + 3, y + 37), Vector2(7, 18)), color)
