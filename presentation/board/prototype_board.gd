class_name PrototypeBoard
extends Node2D

## Runtime combat overlay only: telegraph danger cells, hit flashes, and the F3
## debug view. Reads the board geometry and occupancy from the grid (duck-typed, so this script
## names no ecs class) and every other fact about the simulation (telegraph progress, where each
## enemy stands and what it is heading for) from the HudSnapshot; telegraphs and intents are keyed
## by entity id. It never touches a component: presentation reads events and the snapshot
## (docs/game-base-plan.md 13.1). This node draws nothing in the editor.

@export_group("Impact Theme")
@export var player_miss_color := Color("#d84a3a")
@export var enemy_impact_color := Color("#ff9a75")

@export_group("Telegraph Theme")
@export var danger_cell_color := Color("#d84a3a")
@export var danger_inner_color := Color("#ffefe0")
@export var danger_outline_color := Color("#fff2a8")
@export var danger_slash_color := Color("#ff9a75")
@export var danger_center_color := Color("#fff4d6")

@export_group("Debug Theme")
@export var debug_board_color := Color("#6ee7f2")
@export var debug_occupied_color := Color("#fff4d6")
@export var debug_blocked_color := Color("#ffd34e")
@export var debug_reserved_color := Color("#4da3ff")
@export var debug_item_color := Color("#63d68b")
@export var debug_attack_path_color := Color("#ff665e")
@export var debug_move_path_color := Color("#57d9f2")
@export var debug_pickup_path_color := Color("#63d68b")
@export var debug_turn_path_color := Color("#ffd34e")
@export var debug_wait_path_color := Color("#aeb5bd")

## The board geometry/occupancy service (EcsGrid).
var grid_world
## The read-only picture of the simulation (EcsWorld.hud_snapshot), for telegraph progress and
## the F3 intent paths. Optional: without it telegraphs draw at zero progress and intent paths
## are skipped.
var hud_snapshot: HudSnapshot
## entity id -> locked cells while that entity telegraphs.
var telegraphs: Dictionary = {}
var impact_cells: Array[Vector2i] = []
var impact_time := 0.0
var impact_color := Color("#fff2a8")
var debug_enabled := true
## entity id -> the EnemyIntent it chose last (F3 path drawing).
var enemy_intents: Dictionary = {}
var effect_time := 0.0


func setup(world, snapshot: HudSnapshot = null) -> void:
	grid_world = world
	hud_snapshot = snapshot
	queue_redraw()


func show_player_attack(cells: Array[Vector2i], hit_count: int, profile: AttackProfile) -> void:
	impact_cells = cells
	impact_color = profile.color if hit_count > 0 else player_miss_color
	impact_time = 0.14
	queue_redraw()


func show_enemy_attack(cells: Array[Vector2i]) -> void:
	impact_cells = cells
	impact_color = enemy_impact_color
	impact_time = 0.16
	queue_redraw()


func set_telegraph(source_entity: int, cells: Array[Vector2i]) -> void:
	telegraphs[source_entity] = cells
	queue_redraw()


func clear_telegraph(source_entity: int) -> void:
	telegraphs.erase(source_entity)
	queue_redraw()


func set_debug_enabled(value: bool) -> void:
	debug_enabled = value
	queue_redraw()


func set_enemy_intent(source_entity: int, intent: EnemyIntent) -> void:
	enemy_intents[source_entity] = intent
	queue_redraw()


func clear_enemy_debug(source_entity: int) -> void:
	enemy_intents.erase(source_entity)
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


## How far through its telegraph the enemy is, 0.0 to 1.0 (0.0 for an enemy the snapshot does not brief).
func _telegraph_progress(source_entity: int) -> float:
	if hud_snapshot == null:
		return 0.0
	var brief: HudSnapshot.EnemyBrief = hud_snapshot.enemy_brief_by_entity.get(source_entity)
	return brief.telegraph_progress if brief != null else 0.0


func _draw() -> void:
	if grid_world == null:
		return
	var origin: Vector2 = grid_world.grid_origin
	var size: int = grid_world.cell_size

	for source_entity in telegraphs:
		var progress := _telegraph_progress(source_entity)
		for cell: Vector2i in telegraphs[source_entity]:
			if grid_world.is_inside(cell):
				_draw_danger_cell(origin, size, cell, progress)

	if impact_time > 0.0:
		for cell in impact_cells:
			if grid_world.is_inside(cell):
				draw_rect(Rect2(origin + Vector2(cell * size), Vector2.ONE * size), Color(impact_color, 0.68))

	if debug_enabled:
		_draw_debug_layer(origin, size)


func _draw_danger_cell(origin: Vector2, size: int, cell: Vector2i, progress: float) -> void:
	var rect := Rect2(origin + Vector2(cell * size), Vector2.ONE * size)
	var pulse := 0.5 + 0.5 * sin(effect_time * TAU * 4.0)
	var warning_alpha := lerpf(0.30, 0.68, progress) + pulse * 0.08
	draw_rect(rect, Color(danger_cell_color, warning_alpha))

	var inset := lerpf(8.0, 2.0, progress) + pulse * 1.5
	var inner := rect.grow(-inset)
	draw_rect(inner, Color(danger_inner_color, 0.14 + progress * 0.14))
	draw_rect(inner, Color(danger_outline_color, 0.72 + progress * 0.24), false, 2.0)

	var center := rect.get_center()
	var slash_color := Color(danger_slash_color, 0.74 + progress * 0.22)
	draw_line(rect.position + Vector2(6, 6), rect.end - Vector2(6, 6), slash_color, 2.0 + progress)
	draw_line(rect.position + Vector2(size - 6, 6), rect.position + Vector2(6, size - 6), slash_color, 2.0 + progress)
	draw_circle(center, 2.0 + progress * 3.0 + pulse * 1.5, Color(danger_center_color, 0.55 + progress * 0.32))


func _draw_debug_layer(origin: Vector2, size: int) -> void:
	var board_rect := Rect2(origin, Vector2(grid_world.bounds.size * size))
	draw_rect(board_rect, Color(debug_board_color, 0.9), false, 2.0)

	for cell in grid_world.get_occupied_cells():
		_draw_debug_cell(cell, Color(debug_occupied_color, 0.8), 1.5)
	for cell in grid_world.blocked_cells:
		_draw_debug_cell(cell, Color(debug_blocked_color, 0.95), 2.0)
	for cell in grid_world.get_reservation_cells():
		_draw_debug_cell(cell, Color(debug_reserved_color, 0.95), 2.0)
	for cell in grid_world.get_item_cells():
		_draw_debug_cell(cell, Color(debug_item_color, 0.95), 2.0)

	if hud_snapshot == null:
		return
	var stale: Array = []
	for source_entity in enemy_intents.keys():
		var brief: HudSnapshot.EnemyBrief = hud_snapshot.enemy_brief_by_entity.get(source_entity)
		if brief == null:
			stale.append(source_entity)
			continue
		_draw_intent_path(brief, enemy_intents[source_entity], source_entity)
	for source_entity in stale:
		enemy_intents.erase(source_entity)


func _draw_debug_cell(cell: Vector2i, color: Color, width: float) -> void:
	if not grid_world.is_inside(cell):
		return
	var rect := Rect2(
		grid_world.grid_origin + Vector2(cell * grid_world.cell_size) + Vector2.ONE * 2.0,
		Vector2.ONE * float(grid_world.cell_size - 4)
	)
	draw_rect(rect, color, false, width)


func _draw_intent_path(brief: HudSnapshot.EnemyBrief, intent: EnemyIntent, source_entity: int) -> void:
	var current_cell := brief.cell
	var start: Vector2 = grid_world.cell_to_world(current_cell)
	var color := _intent_color(intent.type)
	if intent.type == EnemyIntent.Type.MOVE:
		var goal: Vector2i = brief.committed_goal if grid_world.is_inside(brief.committed_goal) else intent.destination
		var route: Array[Vector2i] = grid_world.get_grid_path(source_entity, current_cell, goal)
		var segment_start := start
		if route.size() <= 1:
			route = [current_cell, intent.destination]
		for index in range(1, route.size()):
			var segment_end: Vector2 = grid_world.cell_to_world(route[index])
			draw_dashed_line(segment_start, segment_end, color, 2.0, 6.0)
			draw_circle(segment_end, 3.0, color)
			segment_start = segment_end
		return
	var targets: Array[Vector2i] = []
	match intent.type:
		EnemyIntent.Type.ATTACK:
			targets = intent.target_cells
		EnemyIntent.Type.TURN:
			targets = [current_cell + intent.direction]
		_:
			targets = [current_cell]

	for target_cell in targets:
		if not grid_world.is_inside(target_cell):
			continue
		var finish: Vector2 = grid_world.cell_to_world(target_cell)
		draw_dashed_line(start, finish, color, 2.0, 6.0)
		draw_circle(finish, 4.0, color)


func _intent_color(type: EnemyIntent.Type) -> Color:
	match type:
		EnemyIntent.Type.ATTACK:
			return debug_attack_path_color
		EnemyIntent.Type.MOVE:
			return debug_move_path_color
		EnemyIntent.Type.PICKUP:
			return debug_pickup_path_color
		EnemyIntent.Type.TURN:
			return debug_turn_path_color
		_:
			return debug_wait_path_color
