extends SceneTree

## Phase B of the ECS conversion: the attack lifecycle (intent -> lock cells ->
## impact -> recovery), damage through the queue, invulnerability, defeat, and
## the locked-cells dodge rule.

var failures := 0


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)


func _drain_types(world: EcsWorld) -> Array:
	var types := []
	for event in world.drain_events():
		types.append(event.get("type"))
	return types


func _init() -> void:
	var world := EcsWorld.new()
	world.manual_tick = true
	root.add_child(world)
	world.add_system(MovementSystem.new())
	world.add_system(CombatSystem.new())
	world.add_system(HealthSystem.new())

	var sword := load("res://resources/attacks/wooden_sword.tres") as AttackProfile
	var thrust := load("res://resources/attacks/pencil_thrust.tres") as AttackProfile

	var hero := world.create_entity()
	var hero_pos: EcsComponents.GridPos = world.add_component(hero, EcsComponents.GRID_POS, EcsComponents.GridPos.new())
	hero_pos.cell = Vector2i(5, 5)
	var hero_facing: EcsComponents.Facing = world.add_component(hero, EcsComponents.FACING, EcsComponents.Facing.new())
	hero_facing.direction = Vector2i.LEFT
	world.add_component(hero, EcsComponents.MOVE_STATE, EcsComponents.MoveState.new())
	world.add_component(hero, EcsComponents.PLAYER_TAG, EcsComponents.PlayerTag.new())
	var hero_health: EcsComponents.Health = world.add_component(hero, EcsComponents.HEALTH, EcsComponents.Health.new())
	var hero_combat: EcsComponents.PlayerCombat = world.add_component(hero, EcsComponents.PLAYER_COMBAT, EcsComponents.PlayerCombat.new())
	hero_combat.wooden_sword = sword
	hero_combat.pencil_thrust = thrust
	var hero_attack: EcsComponents.AttackIntent = world.add_component(hero, EcsComponents.ATTACK_INTENT, EcsComponents.AttackIntent.new())
	world.grid.register_entity(hero, hero_pos.cell)

	var dummy := world.create_entity()
	var dummy_pos: EcsComponents.GridPos = world.add_component(dummy, EcsComponents.GRID_POS, EcsComponents.GridPos.new())
	dummy_pos.cell = Vector2i(4, 5)
	var dummy_health: EcsComponents.Health = world.add_component(dummy, EcsComponents.HEALTH, EcsComponents.Health.new())
	dummy_health.current = 2
	dummy_health.max_value = 2
	world.grid.register_entity(dummy, dummy_pos.cell)

	hero_attack.kind = &"sword"
	world.tick(0.016)
	_expect(hero_combat.attack_on_cooldown and hero_combat.pending_cells == [Vector2i(4, 5)], "sword swing locks the facing cell")
	hero_attack.kind = &"sword"
	world.tick(0.016)
	_expect(hero_attack.kind == &"none" and hero_combat.active_attack == sword, "cooldown swallows a second swing")

	for _i in range(10):
		world.tick(0.016)
	_expect(dummy_health.current == 1, "impact resolves damage once against the locked cell")
	var event_types := _drain_types(world)
	_expect(&"attack_landed" in event_types and &"damaged" in event_types, "impact emits attack_landed + damaged events")

	for _i in range(30):
		world.tick(0.016)
	_expect(not hero_combat.attack_on_cooldown, "recovery releases the cooldown")

	hero_attack.kind = &"sword"
	world.tick(0.016)
	for _i in range(40):
		world.tick(0.016)
	_expect(dummy_health.current == 0, "second swing after recovery lands")
	_expect(world.grid.entity_at(Vector2i(4, 5)) == 0, "defeated non-player leaves the grid")
	_expect(&"defeated" in _drain_types(world), "defeat emits its event")

	world.damage_events.append({"target": hero, "amount": 1, "direction": Vector2i.RIGHT})
	world.tick(0.016)
	world.damage_events.append({"target": hero, "amount": 1, "direction": Vector2i.RIGHT})
	world.tick(0.016)
	_expect(hero_health.current == 2, "invulnerability window swallows the second hit")
	for _i in range(50):
		world.tick(0.016)
	world.damage_events.append({"target": hero, "amount": 1, "direction": Vector2i.RIGHT})
	world.tick(0.016)
	_expect(hero_health.current == 1, "damage applies again after invulnerability decays")

	var runner := world.create_entity()
	var runner_pos: EcsComponents.GridPos = world.add_component(runner, EcsComponents.GRID_POS, EcsComponents.GridPos.new())
	runner_pos.cell = Vector2i(6, 5)
	var runner_health: EcsComponents.Health = world.add_component(runner, EcsComponents.HEALTH, EcsComponents.Health.new())
	runner_health.current = 2
	var runner_move: EcsComponents.MoveState = world.add_component(runner, EcsComponents.MOVE_STATE, EcsComponents.MoveState.new())
	var runner_intent: EcsComponents.MoveIntent = world.add_component(runner, EcsComponents.MOVE_INTENT, EcsComponents.MoveIntent.new())
	runner_move.duration = 0.05
	world.grid.register_entity(runner, runner_pos.cell)
	hero_facing.direction = Vector2i.RIGHT
	hero_attack.kind = &"sword"
	world.tick(0.016)
	_expect(hero_combat.pending_cells == [Vector2i(6, 5)], "swing locks the runner's cell")
	runner_intent.direction = Vector2i.RIGHT
	for _i in range(10):
		world.tick(0.016)
	_expect(runner_health.current == 2 and runner_pos.cell == Vector2i(7, 5), "stepping off the locked cell dodges the hit")

	var succeeded := failures == 0
	print("ECS COMBAT TEST: %s" % ["PASS" if succeeded else "FAIL (%d)" % failures])
	quit(0 if succeeded else 1)
