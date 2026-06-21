class_name GridWorld
extends Node

@export var cell_size := 32
@export var grid_origin := Vector2(64, 36)
@export var bounds := Rect2i(0, 0, 16, 9)

var blocked_cells: Dictionary = {}
var occupied_cells: Dictionary = {}
var actor_cells: Dictionary = {}
var reservations: Dictionary = {}
var item_cells: Dictionary = {}


func cell_to_world(cell: Vector2i) -> Vector2:
	return grid_origin + Vector2(cell * cell_size) + Vector2.ONE * cell_size * 0.5


func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(floor((world_position.x - grid_origin.x) / cell_size), floor((world_position.y - grid_origin.y) / cell_size))


func is_inside(cell: Vector2i) -> bool:
	return bounds.has_point(cell)


func is_walkable(cell: Vector2i) -> bool:
	return is_inside(cell) and not blocked_cells.has(cell)


func register_actor(actor: Node, cell: Vector2i) -> bool:
	if not is_walkable(cell) or occupied_cells.has(cell):
		return false
	occupied_cells[cell] = actor
	actor_cells[actor] = cell
	return true


func unregister_actor(actor: Node) -> void:
	if not actor_cells.has(actor):
		return
	var cell: Vector2i = actor_cells[actor]
	occupied_cells.erase(cell)
	actor_cells.erase(actor)
	for reserved_cell in reservations.keys():
		if reservations[reserved_cell] == actor:
			reservations.erase(reserved_cell)


func can_begin_move(actor: Node, destination: Vector2i) -> bool:
	if not is_walkable(destination):
		return false
	if occupied_cells.has(destination) and occupied_cells[destination] != actor:
		return false
	if reservations.has(destination) and reservations[destination] != actor:
		return false
	return actor_cells.has(actor)


func begin_move(actor: Node, destination: Vector2i) -> bool:
	if not can_begin_move(actor, destination):
		return false
	reservations[destination] = actor
	return true


func finish_move(actor: Node, destination: Vector2i) -> void:
	if not actor_cells.has(actor):
		return
	var origin: Vector2i = actor_cells[actor]
	occupied_cells.erase(origin)
	reservations.erase(destination)
	occupied_cells[destination] = actor
	actor_cells[actor] = destination


func actor_at(cell: Vector2i) -> Node:
	return occupied_cells.get(cell)


func add_block(cell: Vector2i) -> bool:
	if not is_inside(cell) or occupied_cells.has(cell) or reservations.has(cell):
		return false
	blocked_cells[cell] = true
	return true


func remove_block(cell: Vector2i) -> void:
	blocked_cells.erase(cell)


func register_item(item: Node, cell: Vector2i) -> bool:
	if not is_inside(cell) or item_cells.has(cell):
		return false
	item_cells[cell] = item
	return true


func unregister_item(item: Node) -> void:
	for cell in item_cells.keys():
		if item_cells[cell] == item:
			item_cells.erase(cell)
			return


func item_at(cell: Vector2i) -> Node:
	return item_cells.get(cell)


func get_item_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in item_cells:
		cells.append(cell)
	return cells


func get_reserved_cell(actor: Node) -> Vector2i:
	for cell: Vector2i in reservations:
		if reservations[cell] == actor:
			return cell
	return actor_cells.get(actor, Vector2i(-999, -999))


func get_reservation_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in reservations:
		cells.append(cell)
	return cells


func get_occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in occupied_cells:
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
	for cell: Vector2i in occupied_cells:
		if occupied_cells[cell] != actor and cell != goal:
			pathfinder.set_point_solid(cell)
	for cell: Vector2i in reservations:
		if reservations[cell] != actor and cell != goal:
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
	if occupied_cells.has(cell) and occupied_cells[cell] != actor:
		return false
	if reservations.has(cell) and reservations[cell] != actor:
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
