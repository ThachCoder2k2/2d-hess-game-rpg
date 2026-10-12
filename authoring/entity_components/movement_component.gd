class_name MovementComponent
extends EntityComponent

## Step timing as an editor node: bakes into MoveState at spawn. On enemies
## the definition's MovementConfig already owns this — use this node for the
## player (no definition) or a per-instance override.

@export_range(0.05, 1.0, 0.01) var step_duration := 0.18


func apply(world: EcsWorld, entity_id: int) -> void:
	var move: EcsComponents.MoveState = world.get_component(entity_id, EcsComponents.MOVE_STATE)
	if move == null:
		move = world.add_component(entity_id, EcsComponents.MOVE_STATE, EcsComponents.MoveState.new())
	move.duration = step_duration
