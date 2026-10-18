extends UnboundTest

## Damage knows who dealt it (docs/game-base-plan.md 14.3, requirements R8, R10, R14): a damage
## request is `{target, source, amount, direction, tags}`, built only by Events.emit_damage(),
## and HealthSystem carries `source` and `tags` on into the `damaged` and `defeated` events, so
## the death frame can show the origin (R8), the first death by a family can write its margin
## note (R10) and the final blow can be traced to the player (R14). The two producers that exist,
## CombatSystem and EnemyAISystem, are driven for real and their requests are read back.


func _init() -> void:
	suite_title = "EMIT DAMAGE TEST"
	_check_the_request_payload()
	_check_health_passes_source_and_tags_on()
	_check_the_player_sword_names_its_wielder()
	_check_an_armed_enemy_names_itself_and_its_weapon_tags()
	_check_an_unarmed_enemy_names_itself()
	finish()


func _make_world() -> EcsWorld:
	var world := EcsWorld.new()
	world.manual_tick = true
	root.add_child(world)
	return world


func _events_of_type(events: Array[Dictionary], event_type: StringName) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for event in events:
		if event.get("type") == event_type:
			found.append(event)
	return found


func _check_the_request_payload() -> void:
	var world := _make_world()
	var tags: Array[StringName] = [&"line"]
	Events.emit_damage(world, 7, 2, Vector2i.LEFT, 3, tags)
	_expect(world.damage_events.size() == 1, "emit_damage queues exactly one request")
	var request := world.damage_events[0]
	var request_keys: Array[String] = []
	for key: String in request:
		request_keys.append(key)
	request_keys.sort()
	var documented_keys := Events.DAMAGE_REQUEST_KEYS.duplicate()
	documented_keys.sort()
	_expect(request_keys == documented_keys, "a damage request carries exactly target, source, amount, direction and tags")
	_expect(request["target"] == 7 and request["source"] == 3 and request["amount"] == 2 and request["direction"] == Vector2i.LEFT, "the request carries the values it was given")
	_expect(request["tags"] == tags, "the request carries the tags it was given")
	tags.append(&"later")
	_expect(request["tags"].size() == 1, "the request keeps its own copy of the tags, a later edit of the caller's array does not reach it")
	Events.emit_damage(world, 8, 1, Vector2i.ZERO, 0)
	_expect(world.damage_events[1]["tags"].is_empty() and world.damage_events[1]["source"] == 0, "a request with no tags and no source says so: empty tags, source 0")
	world.queue_free()


func _check_health_passes_source_and_tags_on() -> void:
	var world := _make_world()
	world.add_system(HealthSystem.new())
	var victim := EcsActorFactory.spawn_enemy(world, ContentDb.fetch(&"enemies", &"pawn_recruit") as EnemyDefinition, Vector2i(5, 5))
	var health: EcsComponents.Health = world.get_component(victim, EcsComponents.HEALTH)
	health.current = 3
	health.max_value = 3
	var attacker := 42
	var tags: Array[StringName] = [&"line", &"melee"]

	Events.emit_damage(world, victim, 1, Vector2i.RIGHT, attacker, tags)
	world.tick(0.016)
	var damaged_events := _events_of_type(world.drain_events(), Events.DAMAGED)
	_expect(damaged_events.size() == 1, "a damage request produces one `damaged` event")
	if damaged_events.size() == 1:
		var damaged := damaged_events[0]
		_expect(damaged["entity"] == victim and damaged["amount"] == 1 and damaged["remaining"] == 2, "`damaged` still says who, how much and what is left")
		_expect(damaged["source"] == attacker and damaged["tags"] == tags and damaged["direction"] == Vector2i.RIGHT, "`damaged` carries the source, the tags and the direction of the blow")

	Events.emit_damage(world, victim, 99, Vector2i.LEFT, attacker, tags)
	world.tick(0.016)
	var after_lethal := world.drain_events()
	var defeated_events := _events_of_type(after_lethal, Events.DEFEATED)
	_expect(defeated_events.size() == 1 and defeated_events[0]["entity"] == victim, "a lethal request produces one `defeated` event")
	if defeated_events.size() == 1:
		_expect(defeated_events[0]["source"] == attacker and defeated_events[0]["tags"] == tags, "`defeated` names the entity whose blow did it and that blow's tags (R8, R14)")

	# A request built the old way, by hand and without source or tags, still lands: it reads as "no source".
	var second_victim := EcsActorFactory.spawn_enemy(world, ContentDb.fetch(&"enemies", &"pawn_recruit") as EnemyDefinition, Vector2i(7, 5))
	world.damage_events.append({"target": second_victim, "amount": 1, "direction": Vector2i.DOWN})
	world.tick(0.016)
	var legacy_events := _events_of_type(world.drain_events(), Events.DAMAGED)
	_expect(legacy_events.size() == 1 and legacy_events[0]["source"] == 0 and legacy_events[0]["tags"].is_empty(), "a request without source and tags reads as source 0 and no tags, not as an error")
	world.queue_free()


func _check_the_player_sword_names_its_wielder() -> void:
	var world := _make_world()
	world.add_system(CombatSystem.new())
	world.add_system(HealthSystem.new())
	var sword := ContentDb.fetch(&"skills", &"wooden_sword") as AttackProfile
	var thrust := ContentDb.fetch(&"skills", &"pencil_thrust") as AttackProfile
	var hero := EcsActorFactory.spawn_player(world, Vector2i(5, 5), sword, thrust)
	var hero_facing: EcsComponents.Facing = world.get_component(hero, EcsComponents.FACING)
	hero_facing.direction = Vector2i.LEFT
	var hero_combat: EcsComponents.PlayerCombat = world.get_component(hero, EcsComponents.PLAYER_COMBAT)
	hero_combat.sword_unlocked = true
	var dummy := EcsActorFactory.spawn_enemy(world, ContentDb.fetch(&"enemies", &"pawn_recruit") as EnemyDefinition, Vector2i(4, 5))

	var attack_intent: EcsComponents.AttackIntent = world.get_component(hero, EcsComponents.ATTACK_INTENT)
	attack_intent.kind = &"sword"
	var damaged_events: Array[Dictionary] = []
	for _tick in range(20):
		world.tick(0.016)
		damaged_events.append_array(_events_of_type(world.drain_events(), Events.DAMAGED))
	_expect(damaged_events.size() == 1 and damaged_events[0]["entity"] == dummy, "the sword swing damages the pawn in front of the hero once")
	if damaged_events.size() == 1:
		_expect(damaged_events[0]["source"] == hero, "the player's sword names the player as the source of its damage")
		_expect(damaged_events[0]["direction"] == Vector2i.LEFT and damaged_events[0]["amount"] == sword.damage, "the swing's direction is the way the hero faces and its amount the sword's damage")
	world.queue_free()


func _check_an_armed_enemy_names_itself_and_its_weapon_tags() -> void:
	var world := _make_world()
	world.add_system(EnemyAISystem.new())
	world.add_system(HealthSystem.new())
	var sword := ContentDb.fetch(&"skills", &"wooden_sword") as AttackProfile
	var thrust := ContentDb.fetch(&"skills", &"pencil_thrust") as AttackProfile
	var hero := EcsActorFactory.spawn_player(world, Vector2i(3, 3), sword, thrust)
	var pawn := EcsActorFactory.spawn_enemy(world, ContentDb.fetch(&"enemies", &"pawn_recruit") as EnemyDefinition, Vector2i(3, 2))
	var spear := EnemyWeapon.pencil_spear()
	var weapon_slot: EcsComponents.WeaponSlot = world.get_component(pawn, EcsComponents.WEAPON_SLOT)
	weapon_slot.weapon = spear
	var pawn_ai: EcsComponents.EnemyAI = world.get_component(pawn, EcsComponents.ENEMY_AI)
	# The strike is about to resolve on the hero's cell: the telegraph has run out.
	pawn_ai.state = EcsComponents.EnemyAI.STATE_TELEGRAPH
	pawn_ai.locked_attack_cells = [Vector2i(3, 3)]
	pawn_ai.state_time_left = 0.0
	world.attack_token_owner = pawn
	world.tick(0.016)
	var damaged_events := _events_of_type(world.drain_events(), Events.DAMAGED)
	_expect(damaged_events.size() == 1 and damaged_events[0]["entity"] == hero, "a resolved enemy strike damages the hero standing in its locked cell")
	if damaged_events.size() == 1:
		_expect(damaged_events[0]["source"] == pawn, "an enemy strike names that enemy as the source")
		_expect(damaged_events[0]["tags"] == spear.tags and not spear.tags.is_empty(), "an armed strike carries its weapon's own tags (%s)" % str(spear.tags))
		_expect(damaged_events[0]["amount"] == spear.damage and damaged_events[0]["direction"] == Vector2i.DOWN, "an armed strike deals its weapon's damage in the way the enemy faces")
	world.queue_free()


func _check_an_unarmed_enemy_names_itself() -> void:
	var world := _make_world()
	world.add_system(EnemyAISystem.new())
	world.add_system(HealthSystem.new())
	var sword := ContentDb.fetch(&"skills", &"wooden_sword") as AttackProfile
	var thrust := ContentDb.fetch(&"skills", &"pencil_thrust") as AttackProfile
	var hero := EcsActorFactory.spawn_player(world, Vector2i(2, 3), sword, thrust)
	var pawn := EcsActorFactory.spawn_enemy(world, ContentDb.fetch(&"enemies", &"pawn_recruit") as EnemyDefinition, Vector2i(3, 2))
	var pawn_ai: EcsComponents.EnemyAI = world.get_component(pawn, EcsComponents.ENEMY_AI)
	pawn_ai.state = EcsComponents.EnemyAI.STATE_TELEGRAPH
	pawn_ai.locked_attack_cells = [Vector2i(2, 3)]
	pawn_ai.state_time_left = 0.0
	world.attack_token_owner = pawn
	world.tick(0.016)
	var damaged_events := _events_of_type(world.drain_events(), Events.DAMAGED)
	_expect(damaged_events.size() == 1 and damaged_events[0]["entity"] == hero and damaged_events[0]["source"] == pawn, "an unarmed strike names the enemy as the source too")
	if damaged_events.size() == 1:
		_expect(damaged_events[0]["tags"].is_empty(), "an unarmed pattern carries no tags yet (the attack framework of M8a gives it some)")
	world.queue_free()
