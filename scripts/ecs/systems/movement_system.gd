class_name MovementSystem
extends EcsSystem

## Consumes MoveIntent through the grid's reserve -> commit protocol and
## advances MoveState. Emits step_started / step_finished / step_blocked
## events; facing follows the attempted direction (as GridActor.try_step did).


func tick(delta: float) -> void:
	for entity_id in world.query([EcsComponents.GRID_POS, EcsComponents.MOVE_STATE]):
		var grid_pos: EcsComponents.GridPos = world.get_component(entity_id, EcsComponents.GRID_POS)
		var move: EcsComponents.MoveState = world.get_component(entity_id, EcsComponents.MOVE_STATE)

		if move.moving:
			move.progress = minf(1.0, move.progress + delta / maxf(move.duration, 0.001))
			if move.progress >= 1.0:
				world.grid.finish_move(entity_id, move.to_cell)
				grid_pos.cell = move.to_cell
				move.moving = false
				world.emit_event({"type": &"step_finished", "entity": entity_id, "cell": move.to_cell})
			continue

		var intent: EcsComponents.MoveIntent = world.get_component(entity_id, EcsComponents.MOVE_INTENT)
		if intent == null or intent.direction == Vector2i.ZERO:
			continue
		var direction := intent.direction
		intent.direction = Vector2i.ZERO

		var facing: EcsComponents.Facing = world.get_component(entity_id, EcsComponents.FACING)
		if facing != null:
			facing.direction = direction

		var destination := grid_pos.cell + direction
		if world.grid.begin_move(entity_id, destination):
			move.from_cell = grid_pos.cell
			move.to_cell = destination
			move.progress = 0.0
			move.moving = true
			world.emit_event({"type": &"step_started", "entity": entity_id, "cell": destination})
		else:
			world.emit_event({"type": &"step_blocked", "entity": entity_id, "direction": direction})
