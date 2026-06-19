class_name GridWorld
extends Node

@export var cell_size := 32
@export var grid_origin := Vector2(64, 36)
@export var bounds := Rect2i(0, 0, 16, 9)

var blocked_cells: Dictionary = {}
var occupied_cells: Dictionary = {}
var actor_cells: Dictionary = {}
var reservations: Dictionary = {}


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

