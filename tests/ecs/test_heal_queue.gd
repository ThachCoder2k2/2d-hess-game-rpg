extends UnboundTest

## The heal queue (docs/game-base-plan.md 14.1, D-16): world.heal_events carries {target, source,
## amount}, built only by Events.emit_heal(), and HealthSystem serves it the same tick, after the
## damage. A heal restores up to the maximum, never past it; says `healed` with what it really
## restored; says nothing when nothing changed; and never brings back an entity that is down.
## Checkpoints (M3b) are its first producer.


func _init() -> void:
	suite_title = "HEAL QUEUE TEST"
	var world := EcsWorld.new()
	world.manual_tick = true
	root.add_child(world)
	world.add_system(HealthSystem.new())
	var sword := ContentDb.fetch(&"skills", &"wooden_sword") as AttackProfile
	var thrust := ContentDb.fetch(&"skills", &"pencil_thrust") as AttackProfile
	var hero := EcsActorFactory.spawn_player(world, Vector2i(3, 3), sword, thrust, 3)
	var health: EcsComponents.Health = world.get_component(hero, EcsComponents.HEALTH)

	Events.emit_heal(world, hero, 2, 9)
	var request_keys: Array[String] = []
	for key: String in world.heal_events[0]:
		request_keys.append(key)
	request_keys.sort()
	var documented_keys := Events.HEAL_REQUEST_KEYS.duplicate()
	documented_keys.sort()
	_expect(request_keys == documented_keys, "a heal request carries exactly target, source and amount")
	_expect(world.heal_events[0]["target"] == hero and world.heal_events[0]["amount"] == 2 and world.heal_events[0]["source"] == 9, "the request carries the values it was given")
	world.heal_events.clear()

	health.current = 1
	Events.emit_heal(world, hero, 1, 9)
	world.tick(0.016)
	var healed := _events_of_type(world.drain_events(), Events.HEALED)
	_expect(health.current == 2 and healed.size() == 1, "a heal of 1 raises courage from 1 to 2 and says so once")
	if healed.size() == 1:
		_expect(healed[0]["entity"] == hero and healed[0]["amount"] == 1 and healed[0]["remaining"] == 2 and healed[0]["source"] == 9, "`healed` names the entity, the points restored, what it has now and who healed it")
	_expect(world.heal_events.is_empty(), "the queue is empty after the tick")

	Events.emit_heal(world, hero, 5)
	world.tick(0.016)
	healed = _events_of_type(world.drain_events(), Events.HEALED)
	_expect(health.current == health.max_value, "a heal larger than the room left stops at the maximum (%d)" % health.max_value)
	_expect(healed.size() == 1 and healed[0]["amount"] == 1 and healed[0]["source"] == 0, "`healed` reports the 1 point it really restored, from source 0 (the world)")

	Events.emit_heal(world, hero, 2)
	world.tick(0.016)
	_expect(_events_of_type(world.drain_events(), Events.HEALED).is_empty(), "a heal on a full entity says nothing")

	Events.emit_heal(world, hero, 0)
	Events.emit_heal(world, hero, -3)
	health.current = 1
	world.tick(0.016)
	_expect(health.current == 1 and _events_of_type(world.drain_events(), Events.HEALED).is_empty(), "a heal of zero or less changes nothing and says nothing")

	Events.emit_heal(world, 9999, 1)
	world.tick(0.016)
	_expect(_events_of_type(world.drain_events(), Events.HEALED).is_empty(), "a heal aimed at nothing that can be healed is dropped quietly")

	health.current = 3
	health.invulnerable_left = 0.0
	Events.emit_damage(world, hero, 1, Vector2i.LEFT, 0)
	Events.emit_heal(world, hero, 1)
	world.tick(0.016)
	var kinds: Array = world.drain_events().map(func(event: Dictionary) -> StringName: return event["type"])
	_expect(health.current == 3 and kinds == [Events.DAMAGED, Events.HEALED], "in one tick the blow lands first and the heal after it (3 -> 2 -> 3)")

	health.current = 1
	health.invulnerable_left = 0.0
	Events.emit_damage(world, hero, 5, Vector2i.LEFT, 0)
	Events.emit_heal(world, hero, 3)
	world.tick(0.016)
	var after_fall := world.drain_events()
	_expect(health.current == 0, "a blow that fells the hero still fells it when a heal arrives in the same tick: a heal never revives")
	_expect(_events_of_type(after_fall, Events.HEALED).is_empty() and _events_of_type(after_fall, Events.DEFEATED).size() == 1, "and only `defeated` is said")

	Events.emit_heal(world, hero, 3)
	world.tick(0.016)
	_expect(health.current == 0, "a heal a tick later does not revive it either")
	world.queue_free()
	finish()


func _events_of_type(events: Array[Dictionary], event_type: StringName) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for event in events:
		if event.get("type") == event_type:
			found.append(event)
	return found
