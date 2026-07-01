class_name PrototypeBoard
extends Node2D

var grid_world: GridWorld
var telegraphs: Dictionary = {}
var impact_cells: Array[Vector2i] = []
var impact_time := 0.0
var impact_color := Color("#fff2a8")
var debug_enabled := true
var enemy_intents: Dictionary = {}
var effect_time := 0.0


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


func set_debug_enabled(value: bool) -> void:
	debug_enabled = value
	queue_redraw()


func set_enemy_intent(enemy: FreeEnemy, intent: EnemyIntent) -> void:
	enemy_intents[enemy] = intent
	queue_redraw()


func clear_enemy_debug(enemy: FreeEnemy) -> void:
	enemy_intents.erase(enemy)
	queue_redraw()


func _process(delta: float) -> void:
	effect_time += delta
	if impact_time > 0.0:
		impact_time = maxf(0.0, impact_time - delta)
		queue_redraw()
	if not telegraphs.is_empty():
		queue_redraw()
	if debug_enabled and not enemy_intents.is_empty():
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
		var progress := 0.0
		if source.has_method("get_telegraph_progress"):
			progress = source.get_telegraph_progress()
		for cell: Vector2i in telegraphs[source]:
			if grid_world.is_inside(cell):
				_draw_danger_cell(origin, size, cell, progress)

	if impact_time > 0.0:
		for cell in impact_cells:
			if grid_world.is_inside(cell):
				draw_rect(Rect2(origin + Vector2(cell * size), Vector2.ONE * size), Color(impact_color, 0.68))

	if debug_enabled:
		_draw_debug_layer(origin, size)
	_draw_playground_border(origin, size)


func _draw_danger_cell(origin: Vector2, size: int, cell: Vector2i, progress: float) -> void:
	var rect := Rect2(origin + Vector2(cell * size), Vector2.ONE * size)
	var pulse := 0.5 + 0.5 * sin(effect_time * TAU * 4.0)
	var warning_alpha := lerpf(0.30, 0.68, progress) + pulse * 0.08
	draw_rect(rect, Color("#d84a3a", warning_alpha))

	var inset := lerpf(8.0, 2.0, progress) + pulse * 1.5
	var inner := rect.grow(-inset)
	draw_rect(inner, Color("#ffefe0", 0.14 + progress * 0.14))
	draw_rect(inner, Color("#fff2a8", 0.72 + progress * 0.24), false, 2.0)

	var center := rect.get_center()
	var slash_color := Color("#ff9a75", 0.74 + progress * 0.22)
	draw_line(rect.position + Vector2(6, 6), rect.end - Vector2(6, 6), slash_color, 2.0 + progress)
	draw_line(rect.position + Vector2(size - 6, 6), rect.position + Vector2(6, size - 6), slash_color, 2.0 + progress)
	draw_circle(center, 2.0 + progress * 3.0 + pulse * 1.5, Color("#fff4d6", 0.55 + progress * 0.32))


func _draw_debug_layer(origin: Vector2, size: int) -> void:
	var board_rect := Rect2(origin, Vector2(grid_world.bounds.size * size))
	draw_rect(board_rect, Color("#6ee7f2", 0.9), false, 2.0)

	for cell in grid_world.get_occupied_cells():
		_draw_debug_cell(cell, Color("#fff4d6", 0.8), 1.5)
	for cell in grid_world.blocked_cells:
		_draw_debug_cell(cell, Color("#ffd34e", 0.95), 2.0)
	for cell in grid_world.get_reservation_cells():
		_draw_debug_cell(cell, Color("#4da3ff", 0.95), 2.0)
	for cell in grid_world.get_item_cells():
		_draw_debug_cell(cell, Color("#63d68b", 0.95), 2.0)

	var stale: Array[Node] = []
	for enemy: Node in enemy_intents:
		if not is_instance_valid(enemy) or not enemy is FreeEnemy:
			stale.append(enemy)
			continue
		_draw_intent_path(enemy, enemy_intents[enemy])
	for enemy in stale:
		enemy_intents.erase(enemy)


func _draw_debug_cell(cell: Vector2i, color: Color, width: float) -> void:
	if not grid_world.is_inside(cell):
		return
	var rect := Rect2(
		grid_world.grid_origin + Vector2(cell * grid_world.cell_size) + Vector2.ONE * 2.0,
		Vector2.ONE * float(grid_world.cell_size - 4)
	)
	draw_rect(rect, color, false, width)


func _draw_intent_path(enemy: FreeEnemy, intent: EnemyIntent) -> void:
	var start := enemy.position
	var color := _intent_color(intent.type)
	if intent.type == EnemyIntent.Type.MOVE:
		var goal := enemy.committed_goal if grid_world.is_inside(enemy.committed_goal) else intent.destination
		var route := grid_world.get_grid_path(enemy, enemy.current_cell, goal)
		var segment_start := start
		if route.size() <= 1:
			route = [enemy.current_cell, intent.destination]
		for index in range(1, route.size()):
			var segment_end := grid_world.cell_to_world(route[index])
			draw_dashed_line(segment_start, segment_end, color, 2.0, 6.0)
			draw_circle(segment_end, 3.0, color)
			segment_start = segment_end
		return
	var targets: Array[Vector2i] = []
	match intent.type:
		EnemyIntent.Type.ATTACK:
			targets = intent.target_cells
		EnemyIntent.Type.TURN:
			var turn_target := enemy.current_cell + intent.direction
			targets = [turn_target]
		_:
			targets = [enemy.current_cell]

	for target_cell in targets:
		if not grid_world.is_inside(target_cell):
			continue
		var finish := grid_world.cell_to_world(target_cell)
		draw_dashed_line(start, finish, color, 2.0, 6.0)
		draw_circle(finish, 4.0, color)


func _intent_color(type: EnemyIntent.Type) -> Color:
	match type:
		EnemyIntent.Type.ATTACK:
			return Color("#ff665e")
		EnemyIntent.Type.MOVE:
			return Color("#57d9f2")
		EnemyIntent.Type.PICKUP:
			return Color("#63d68b")
		EnemyIntent.Type.TURN:
			return Color("#ffd34e")
		_:
			return Color("#aeb5bd")


func _draw_playground_border(origin: Vector2, size: int) -> void:
	var board_width := grid_world.bounds.size.x * size
	var board_height := grid_world.bounds.size.y * size
	for y in range(0, board_height, 64):
		var color := Color("#2c78c4") if int(y / 64) % 2 == 0 else Color("#4e8a66")
		draw_rect(Rect2(origin + Vector2(-10, y + 9), Vector2(7, 18)), color)
		draw_rect(Rect2(origin + Vector2(board_width + 3, y + 37), Vector2(7, 18)), color)
