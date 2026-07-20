class_name AISpec
extends ComponentSpec

## Overrides the entity's AI personality at spawn: a per-instance
## DecisionConfig beats the shared EnemyDefinition.decision, so one parked
## enemy can play a different role (same idea as the old per-enemy brain
## component, now as pure spawn data).

@export var decision: DecisionConfig


func apply(world: EcsWorld, entity_id: int) -> void:
	if decision == null:
		return
	var ai: EcsComponents.EnemyAI = world.get_component(entity_id, EcsComponents.ENEMY_AI)
	if ai == null:
		return
	ai.decision_profile = decision
	ai.observe_delay = decision.observe_delay
	if ai.definition != null and ai.definition.difficulty != null:
		ai.observe_delay *= ai.definition.difficulty.observe_time_multiplier
	ai.state_time_left = ai.observe_delay
