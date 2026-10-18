class_name HealthSystem
extends EcsSystem

## Applies world.damage_events (requests built by Events.emit_damage: target, source, amount,
## direction, tags) and then world.heal_events (built by Events.emit_heal: target, source, amount)
## to Health components, passes the source and tags on in the `damaged` and `defeated` events,
## says `healed` for a heal that restored something, and decays hit-feedback timers.
## Rules ported from the node era: invulnerability window on hit for player-tagged entities only;
## defeat disables player control but leaves the entity, while non-players leave the grid
## (despawn handled by the view bridge on the defeated event).

## The schedule stage this system is listed in (ecs/schedule/resolve.gd).
const PHASE := &"resolve"


func tick(delta: float) -> void:
	var queued := world.damage_events
	world.damage_events = []
	for request in queued:
		var tags: Array[StringName] = []
		tags.assign(request.get("tags", []))
		_apply_damage(int(request.get("target", 0)), int(request.get("amount", 0)), request.get("direction", Vector2i.ZERO), int(request.get("source", 0)), tags)

	# Heals come after the damage of the same tick, so a blow and a heal that arrive together
	# cannot bring a fallen entity back: a heal never revives.
	var queued_heals := world.heal_events
	world.heal_events = []
	for request in queued_heals:
		_apply_heal(int(request.get("target", 0)), int(request.get("amount", 0)), int(request.get("source", 0)))

	for entity_id in world.query([EcsComponents.HEALTH]):
		var health: EcsComponents.Health = world.get_component(entity_id, EcsComponents.HEALTH)
		health.invulnerable_left = maxf(0.0, health.invulnerable_left - delta)
		health.flash_left = maxf(0.0, health.flash_left - delta)
		health.hurt_visual_time = maxf(0.0, health.hurt_visual_time - delta)
		health.recoil = health.recoil.move_toward(Vector2.ZERO, delta * 70.0)


## Restores up to `amount` points, never past the maximum and never to an entity that is down.
## Says nothing when nothing was restored.
func _apply_heal(target_id: int, amount: int, source: int) -> void:
	var health: EcsComponents.Health = world.get_component(target_id, EcsComponents.HEALTH)
	if health == null or health.current <= 0 or amount <= 0:
		return
	var restored := mini(amount, health.max_value - health.current)
	if restored <= 0:
		return
	health.current += restored
	world.emit_event({
		"type": Events.HEALED,
		"entity": target_id,
		"amount": restored,
		"remaining": health.current,
		"source": source,
	})


func _apply_damage(target_id: int, amount: int, direction: Vector2i, source: int, tags: Array[StringName]) -> void:
	var health: EcsComponents.Health = world.get_component(target_id, EcsComponents.HEALTH)
	if health == null or health.current <= 0 or health.invulnerable_left > 0.0:
		return
	health.current = maxi(0, health.current - amount)
	health.flash_left = 0.12
	health.hurt_visual_time = 0.18
	health.recoil = Vector2(direction) * 4.0
	world.emit_event({
		"type": Events.DAMAGED,
		"entity": target_id,
		"amount": amount,
		"remaining": health.current,
		"direction": direction,
		"source": source,
		"tags": tags,
	})
	var tag: EcsComponents.PlayerTag = world.get_component(target_id, EcsComponents.PLAYER_TAG)
	if health.current <= 0:
		if tag != null:
			tag.control_enabled = false
		else:
			world.grid.unregister_entity(target_id)
			var ai: EcsComponents.EnemyAI = world.get_component(target_id, EcsComponents.ENEMY_AI)
			if ai != null:
				ai.state = EcsComponents.EnemyAI.STATE_DEFEATED
			if world.attack_token_owner == target_id:
				world.attack_token_owner = 0
		world.emit_event({"type": Events.DEFEATED, "entity": target_id, "source": source, "tags": tags})
	elif tag != null:
		health.invulnerable_left = health.invulnerability_duration
