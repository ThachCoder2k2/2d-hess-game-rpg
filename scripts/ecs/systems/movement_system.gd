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
				_check_zone_exit(entity_id, move.to_cell)
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
		_try_open_gate(entity_id, destination, direction)
		if world.grid.begin_move(entity_id, destination):
			move.from_cell = grid_pos.cell
			move.to_cell = destination
			move.progress = 0.0
			move.moving = true
			world.emit_event({"type": &"step_started", "entity": entity_id, "cell": destination})
		else:
			world.emit_event({"type": &"step_blocked", "entity": entity_id, "direction": direction})


## One-way shortcut gates: a player pushing INTO the gate cell while moving
## in its opens_from direction unbars it forever (the step then proceeds
## onto ordinary floor). Any other approach stays a wall. Enemies never
## open gates.
func _try_open_gate(entity_id: int, destination: Vector2i, direction: Vector2i) -> void:
	var gate: Dictionary = world.grid.gate_by_cell.get(destination, {})
	if gate.is_empty() or direction != gate.get("opens_from", Vector2i.ZERO):
		return
	if world.get_component(entity_id, EcsComponents.PLAYER_TAG) == null:
		return
	world.grid.open_gate(destination)
	world.emit_event({
		"type": &"gate_opened",
		"entity": entity_id,
		"gate": gate.get("id", &""),
		"cell": destination,
	})


## Door cells (EcsGrid.exit_by_cell, baked from ZoneExitMarkers): the player
## landing on one asks the bridge for a zone travel. Enemies never travel.
func _check_zone_exit(entity_id: int, cell: Vector2i) -> void:
	if world.get_component(entity_id, EcsComponents.PLAYER_TAG) == null:
		return
	var exit: Dictionary = world.grid.exit_by_cell.get(cell, {})
	if exit.is_empty():
		return
	world.emit_event({
		"type": &"zone_exit",
		"entity": entity_id,
		"zone": exit.get("zone", &""),
		"entry": exit.get("entry", &"start"),
	})
