class_name HealthSystem
extends EcsSystem

## Applies world.damage_events to Health components and decays hit-feedback
## timers. Rules ported from the node era: invulnerability window on hit for
## player-tagged entities only; defeat disables player control but leaves the
## entity, while non-players leave the grid (despawn handled by the view
## bridge on the defeated event).


func tick(delta: float) -> void:
	var queued := world.damage_events
	world.damage_events = []
	for event in queued:
		_apply_damage(int(event.get("target", 0)), int(event.get("amount", 0)))

	for entity_id in world.query([EcsComponents.HEALTH]):
		var health: EcsComponents.Health = world.get_component(entity_id, EcsComponents.HEALTH)
		health.invulnerable_left = maxf(0.0, health.invulnerable_left - delta)
		health.flash_left = maxf(0.0, health.flash_left - delta)
		health.hurt_visual_time = maxf(0.0, health.hurt_visual_time - delta)


func _apply_damage(target_id: int, amount: int) -> void:
	var health: EcsComponents.Health = world.get_component(target_id, EcsComponents.HEALTH)
	if health == null or health.current <= 0 or health.invulnerable_left > 0.0:
		return
	health.current = maxi(0, health.current - amount)
	health.flash_left = 0.12
	health.hurt_visual_time = 0.18
	world.emit_event({"type": &"damaged", "entity": target_id, "amount": amount, "remaining": health.current})
	var tag: EcsComponents.PlayerTag = world.get_component(target_id, EcsComponents.PLAYER_TAG)
	if health.current <= 0:
		if tag != null:
			tag.control_enabled = false
		else:
			world.grid.unregister_entity(target_id)
		world.emit_event({"type": &"defeated", "entity": target_id})
	elif tag != null:
		health.invulnerable_left = health.invulnerability_duration
