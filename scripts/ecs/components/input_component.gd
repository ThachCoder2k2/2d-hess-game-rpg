class_name InputComponent
extends EntityComponent

## Player input feel as an editor node: bakes into PlayerInput at spawn.
## Player-only — enemies have no PlayerInput component, so this is a no-op
## on them.

@export_range(0.05, 1.0, 0.01) var held_repeat_delay := 0.22


func apply(world: EcsWorld, entity_id: int) -> void:
	var input_state: EcsComponents.PlayerInput = world.get_component(entity_id, EcsComponents.PLAYER_INPUT)
	if input_state == null:
		return
	input_state.held_repeat_delay = held_repeat_delay
