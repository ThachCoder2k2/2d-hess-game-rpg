class_name GridMovementComponent
extends EnemyComponent


func setup(world: GridWorld, start_cell: Vector2i) -> bool:
	if actor == null:
		return false
	actor.grid_world = world
	actor.current_cell = start_cell
	if not world.register_actor(actor, start_cell):
		return false
	actor.position = world.cell_to_world(start_cell)
	return true


func get_current_cell() -> Vector2i:
	return actor.current_cell if actor != null else Vector2i.ZERO


func get_facing() -> Vector2i:
	return actor.facing if actor != null else Vector2i.DOWN


func get_legal_moves() -> Array[Vector2i]:
	if actor == null or actor.grid_world == null:
		return []
	if actor.definition != null and actor.definition.movement != null:
		return actor.grid_world.get_destinations(actor, actor.current_cell, actor.definition.movement.allowed_directions)
	return actor.grid_world.get_cardinal_destinations(actor, actor.current_cell)


func request_step(direction: Vector2i) -> bool:
	if actor == null or actor.is_moving or actor.grid_world == null or direction == Vector2i.ZERO:
		return false
	actor.facing = direction
	var destination := actor.current_cell + direction
	if not actor.grid_world.begin_move(actor, destination):
		return false
	_start_step(destination)
	return true


func _start_step(destination: Vector2i) -> void:
	actor.is_moving = true
	var origin := actor.current_cell
	actor.emit_signal("step_started", origin, destination)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(actor, "position", actor.grid_world.cell_to_world(destination), actor.step_duration)
	tween.finished.connect(_finish_step.bind(destination))


func _finish_step(destination: Vector2i) -> void:
	if actor == null or not is_instance_valid(actor) or actor.grid_world == null:
		return
	if not actor.grid_world.cell_by_actor.has(actor):
		actor.is_moving = false
		return
	actor.grid_world.finish_move(actor, destination)
	actor.current_cell = destination
	actor.position = actor.grid_world.cell_to_world(destination).round()
	actor.is_moving = false
	actor.emit_signal("step_finished", destination)
