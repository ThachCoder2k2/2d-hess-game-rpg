class_name GridWorld
extends Node

@export var cell_size := 32
@export var grid_origin := Vector2(64, 36)
@export var bounds := Rect2i(0, 0, 16, 9)

## cell -> true. Walls/blockers: cells nothing may enter (from BlockerMarkers or solid tiles).
var blocked_cells: Dictionary = {}
## cell -> actor. Who is standing on each cell right now. Kept in sync with cell_by_actor.
var actor_by_cell: Dictionary = {}
## actor -> cell. Reverse lookup of actor_by_cell, so both directions are O(1).
var cell_by_actor: Dictionary = {}
## destination cell -> actor. A moving actor claims its destination BEFORE the step
## tween plays (begin_move) and the claim clears when the step lands (finish_move).
## While sliding, the actor protects both its origin (still occupied) and its
## destination (reserved) — no one can race into either. Enemies target the hero's
## reserved cell, which is what makes dodging telegraphs possible and fair.
var move_reservations: Dictionary = {}
## cell -> pickup. Weapons lying on the floor, one per cell.
var item_by_cell: Dictionary = {}


func cell_to_world(cell: Vector2i) -> Vector2:
	return grid_origin + Vector2(cell * cell_size) + Vector2.ONE * cell_size * 0.5


func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(floor((world_position.x - grid_origin.x) / cell_size), floor((world_position.y - grid_origin.y) / cell_size))


func is_inside(cell: Vector2i) -> bool:
	return bounds.has_point(cell)


func is_walkable(cell: Vector2i) -> bool:
	return is_inside(cell) and not blocked_cells.has(cell)


func register_actor(actor: Node, cell: Vector2i) -> bool:
	if not is_walkable(cell) or actor_by_cell.has(cell) or move_reservations.has(cell):
		return false
	actor_by_cell[cell] = actor
	cell_by_actor[actor] = cell
	return true


func unregister_actor(actor: Node) -> void:
	if not cell_by_actor.has(actor):
		return
	var cell: Vector2i = cell_by_actor[actor]
	actor_by_cell.erase(cell)
	cell_by_actor.erase(actor)
	for reserved_cell in move_reservations.keys():
		if move_reservations[reserved_cell] == actor:
			move_reservations.erase(reserved_cell)


func can_begin_move(actor: Node, destination: Vector2i) -> bool:
	if not is_walkable(destination):
		return false
	if actor_by_cell.has(destination) and actor_by_cell[destination] != actor:
		return false
	if move_reservations.has(destination) and move_reservations[destination] != actor:
		return false
	return cell_by_actor.has(actor)


func begin_move(actor: Node, destination: Vector2i) -> bool:
	if not can_begin_move(actor, destination):
		return false
	move_reservations[destination] = actor
	return true


func finish_move(actor: Node, destination: Vector2i) -> void:
	if not cell_by_actor.has(actor):
		return
	var origin: Vector2i = cell_by_actor[actor]
	actor_by_cell.erase(origin)
	move_reservations.erase(destination)
	actor_by_cell[destination] = actor
	cell_by_actor[actor] = destination


func actor_at(cell: Vector2i) -> Node:
	return actor_by_cell.get(cell)


func add_block(cell: Vector2i) -> bool:
	if not is_inside(cell) or actor_by_cell.has(cell) or move_reservations.has(cell):
		return false
	blocked_cells[cell] = true
	return true


func remove_block(cell: Vector2i) -> void:
	blocked_cells.erase(cell)


func register_item(item: Node, cell: Vector2i) -> bool:
	if not is_inside(cell) or item_by_cell.has(cell):
		return false
	item_by_cell[cell] = item
	return true


func unregister_item(item: Node) -> void:
	for cell in item_by_cell.keys():
		if item_by_cell[cell] == item:
			item_by_cell.erase(cell)
			return


func item_at(cell: Vector2i) -> Node:
	return item_by_cell.get(cell)


func get_item_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in item_by_cell:
		cells.append(cell)
	return cells


func get_reserved_cell(actor: Node) -> Vector2i:
	for cell: Vector2i in move_reservations:
		if move_reservations[cell] == actor:
			return cell
	return cell_by_actor.get(actor, Vector2i(-999, -999))


func get_reservation_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in move_reservations:
		cells.append(cell)
	return cells


func get_occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in actor_by_cell:
		cells.append(cell)
	return cells


func get_grid_path(actor: Node, origin: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if not is_inside(origin) or not is_inside(goal):
		return []
	var pathfinder := AStarGrid2D.new()
	pathfinder.region = bounds
	pathfinder.cell_size = Vector2.ONE
	pathfinder.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	pathfinder.update()
	for cell: Vector2i in blocked_cells:
		pathfinder.set_point_solid(cell)
	for cell: Vector2i in actor_by_cell:
		if actor_by_cell[cell] != actor and cell != goal:
			pathfinder.set_point_solid(cell)
	for cell: Vector2i in move_reservations:
		if move_reservations[cell] != actor and cell != goal:
			pathfinder.set_point_solid(cell)
	var packed_path := pathfinder.get_id_path(origin, goal)
	var path: Array[Vector2i] = []
	for cell in packed_path:
		path.append(cell)
	return path


func get_path_distance(actor: Node, origin: Vector2i, goal: Vector2i) -> int:
	var path := get_grid_path(actor, origin, goal)
	return path.size() - 1 if not path.is_empty() else 999999


func get_next_path_cell(actor: Node, origin: Vector2i, goal: Vector2i) -> Vector2i:
	var path := get_grid_path(actor, origin, goal)
	return path[1] if path.size() > 1 else origin


func is_plannable_cell(actor: Node, cell: Vector2i) -> bool:
	if not is_walkable(cell):
		return false
	if actor_by_cell.has(cell) and actor_by_cell[cell] != actor:
		return false
	if move_reservations.has(cell) and move_reservations[cell] != actor:
		return false
	return true


func get_cardinal_destinations(actor: Node, origin: Vector2i) -> Array[Vector2i]:
	return get_destinations(actor, origin, [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT])


func get_destinations(actor: Node, origin: Vector2i, directions: Array[Vector2i]) -> Array[Vector2i]:
	var destinations: Array[Vector2i] = []
	for direction in directions:
		var destination: Vector2i = origin + direction
		if can_begin_move(actor, destination):
			destinations.append(destination)
	return destinations
