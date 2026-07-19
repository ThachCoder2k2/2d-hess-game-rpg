class_name EcsGrid
extends RefCounted

## The spatial-index service for entities: occupancy, blocks, and the
## reserve -> commit movement protocol, ported 1:1 from GridWorld
## (scripts/core/grid_world.gd) with int entity ids instead of Node refs.
## The flip phase (plan D) decides which of the two survives.

var cell_size := 32
var grid_origin := Vector2(64, 36)
var bounds := Rect2i(0, 0, 16, 9)

## cell -> true. Walls: cells nothing may enter.
var blocked_cells: Dictionary = {}
## cell -> entity id. Who stands on each cell right now.
var entity_by_cell: Dictionary = {}
## entity id -> cell. Reverse of entity_by_cell, both directions O(1).
var cell_by_entity: Dictionary = {}
## destination cell -> entity id. A mover claims its destination BEFORE the
## slide starts (begin_move); the claim clears when the step lands
## (finish_move). While sliding, origin stays occupied and destination stays
## reserved — nobody can race into either.
var move_reservations: Dictionary = {}


func cell_to_world(cell: Vector2i) -> Vector2:
	return grid_origin + Vector2(cell * cell_size) + Vector2.ONE * cell_size * 0.5


func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(floor((world_position.x - grid_origin.x) / cell_size), floor((world_position.y - grid_origin.y) / cell_size))


func is_inside(cell: Vector2i) -> bool:
	return bounds.has_point(cell)


func is_walkable(cell: Vector2i) -> bool:
	return is_inside(cell) and not blocked_cells.has(cell)


func add_block(cell: Vector2i) -> bool:
	if not is_inside(cell) or entity_by_cell.has(cell) or move_reservations.has(cell):
		return false
	blocked_cells[cell] = true
	return true


func register_entity(entity_id: int, cell: Vector2i) -> bool:
	if not is_walkable(cell) or entity_by_cell.has(cell) or move_reservations.has(cell):
		return false
	entity_by_cell[cell] = entity_id
	cell_by_entity[entity_id] = cell
	return true


func unregister_entity(entity_id: int) -> void:
	if not cell_by_entity.has(entity_id):
		return
	var cell: Vector2i = cell_by_entity[entity_id]
	entity_by_cell.erase(cell)
	cell_by_entity.erase(entity_id)
	for reserved_cell in move_reservations.keys():
		if move_reservations[reserved_cell] == entity_id:
			move_reservations.erase(reserved_cell)


func entity_at(cell: Vector2i) -> int:
	return entity_by_cell.get(cell, 0)


func can_begin_move(entity_id: int, destination: Vector2i) -> bool:
	if not is_walkable(destination):
		return false
	if entity_by_cell.has(destination) and entity_by_cell[destination] != entity_id:
		return false
	if move_reservations.has(destination) and move_reservations[destination] != entity_id:
		return false
	return cell_by_entity.has(entity_id)


func begin_move(entity_id: int, destination: Vector2i) -> bool:
	if not can_begin_move(entity_id, destination):
		return false
	move_reservations[destination] = entity_id
	return true


func finish_move(entity_id: int, destination: Vector2i) -> void:
	if not cell_by_entity.has(entity_id):
		return
	var origin: Vector2i = cell_by_entity[entity_id]
	entity_by_cell.erase(origin)
	move_reservations.erase(destination)
	entity_by_cell[destination] = entity_id
	cell_by_entity[entity_id] = destination


func get_reserved_cell(entity_id: int) -> Vector2i:
	for reserved_cell in move_reservations:
		if move_reservations[reserved_cell] == entity_id:
			return reserved_cell
	return Vector2i(-999, -999)


## cell -> pickup entity id. Weapons lying on the floor, one per cell.
var item_by_cell: Dictionary = {}


func register_item(item_entity_id: int, cell: Vector2i) -> bool:
	if not is_inside(cell) or item_by_cell.has(cell):
		return false
	item_by_cell[cell] = item_entity_id
	return true


func take_item(cell: Vector2i) -> int:
	var item_entity_id: int = item_by_cell.get(cell, 0)
	item_by_cell.erase(cell)
	return item_entity_id


func item_at(cell: Vector2i) -> int:
	return item_by_cell.get(cell, 0)


func get_item_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in item_by_cell:
		cells.append(cell)
	return cells


## Pathing — ported 1:1 from GridWorld (other movers and reservations are
## solid unless they sit on the goal).
func get_grid_path(entity_id: int, origin: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if not is_inside(origin) or not is_inside(goal):
		return []
	var pathfinder := AStarGrid2D.new()
	pathfinder.region = bounds
	pathfinder.cell_size = Vector2.ONE
	pathfinder.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	pathfinder.update()
	for cell: Vector2i in blocked_cells:
		pathfinder.set_point_solid(cell)
	for cell: Vector2i in entity_by_cell:
		if entity_by_cell[cell] != entity_id and cell != goal:
			pathfinder.set_point_solid(cell)
	for cell: Vector2i in move_reservations:
		if move_reservations[cell] != entity_id and cell != goal:
			pathfinder.set_point_solid(cell)
	var packed_path := pathfinder.get_id_path(origin, goal)
	var path: Array[Vector2i] = []
	for cell in packed_path:
		path.append(cell)
	return path


func get_path_distance(entity_id: int, origin: Vector2i, goal: Vector2i) -> int:
	var path := get_grid_path(entity_id, origin, goal)
	return path.size() - 1 if not path.is_empty() else 999999


func get_next_path_cell(entity_id: int, origin: Vector2i, goal: Vector2i) -> Vector2i:
	var path := get_grid_path(entity_id, origin, goal)
	return path[1] if path.size() > 1 else origin


func is_plannable_cell(entity_id: int, cell: Vector2i) -> bool:
	if not is_walkable(cell):
		return false
	if entity_by_cell.has(cell) and entity_by_cell[cell] != entity_id:
		return false
	if move_reservations.has(cell) and move_reservations[cell] != entity_id:
		return false
	return true


func get_destinations(entity_id: int, origin: Vector2i, directions: Array[Vector2i]) -> Array[Vector2i]:
	var destinations: Array[Vector2i] = []
	for direction in directions:
		var destination: Vector2i = origin + direction
		if can_begin_move(entity_id, destination):
			destinations.append(destination)
	return destinations
