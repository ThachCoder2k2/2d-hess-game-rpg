class_name GridActor
extends Node2D

signal step_started(origin: Vector2i, destination: Vector2i)
signal step_finished(destination: Vector2i)

## Draw-order base for pieces. Sprites are ~1.5 cells tall and anchored at their
## feet, so a piece one row lower on screen must draw over the piece/tiles above
## it: z_index = ROW_Z_BASE + current_cell.y, updated whenever the cell changes.
const ROW_Z_BASE := 2

@export var current_cell := Vector2i.ZERO
@export var step_duration := 0.18

var grid_world: GridWorld
var facing := Vector2i.DOWN
var is_moving := false


func setup(world: GridWorld, start_cell: Vector2i) -> bool:
	grid_world = world
	current_cell = start_cell
	if not grid_world.register_actor(self, current_cell):
		return false
	position = grid_world.cell_to_world(current_cell)
	update_depth_from_row()
	return true


## Lower rows draw on top (top-down depth for taller-than-cell sprites).
func update_depth_from_row() -> void:
	z_index = ROW_Z_BASE + current_cell.y


func try_step(direction: Vector2i) -> bool:
	if is_moving or grid_world == null or direction == Vector2i.ZERO:
		return false
	facing = direction
	var destination := current_cell + direction
	if not grid_world.begin_move(self, destination):
		return false
	_start_step(destination)
	return true


func _start_step(destination: Vector2i) -> void:
	is_moving = true
	var origin := current_cell
	emit_signal("step_started", origin, destination)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", grid_world.cell_to_world(destination), step_duration)
	tween.finished.connect(_finish_step.bind(destination))


func _finish_step(destination: Vector2i) -> void:
	grid_world.finish_move(self, destination)
	current_cell = destination
	position = grid_world.cell_to_world(current_cell).round()
	update_depth_from_row()
	is_moving = false
	emit_signal("step_finished", current_cell)


func _exit_tree() -> void:
	if grid_world != null:
		grid_world.unregister_actor(self)

