class_name HealthComponent
extends EntityComponent

## Overrides the entity's Health at spawn. Drag under a view to give one
## specific enemy more health than its definition, or tune the player's
## courage per room.

@export_range(1, 9) var max_health := 3
@export_range(0.0, 3.0, 0.05) var invulnerability_duration := 0.70


func apply(world: EcsWorld, entity_id: int) -> void:
	var health: EcsComponents.Health = world.get_component(entity_id, EcsComponents.HEALTH)
	if health == null:
		health = world.add_component(entity_id, EcsComponents.HEALTH, EcsComponents.Health.new())
	health.current = max_health
	health.max_value = max_health
	health.invulnerability_duration = invulnerability_duration
