extends SceneTree

## Phase C of the ECS conversion: enemy entities from EnemyDefinition .tres,
## AI pursuit, the telegraph -> dodge -> resolve loop, the shared attack
## token, pickups, and defeat.

var failures := 0


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)


func _tick(world: EcsWorld, seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		world.tick(0.016)
		elapsed += 0.016


func _init() -> void:
	var world := EcsWorld.new()
	world.manual_tick = true
	root.add_child(world)
	world.add_system(EnemyAISystem.new())
	world.add_system(MovementSystem.new())
	world.add_system(CombatSystem.new())
	world.add_system(HealthSystem.new())

	var definition := load("res://resources/enemies/pawn_recruit.tres") as EnemyDefinition
	var sword := load("res://resources/attacks/wooden_sword.tres") as AttackProfile
	var thrust := load("res://resources/attacks/pencil_thrust.tres") as AttackProfile

	var hero := EcsActorFactory.spawn_player(world, Vector2i(2, 3), sword, thrust)
	# Distance 7 = exactly the default aggro radius; the leash (zone_travel
	# suite) keeps anything farther asleep.
	var pawn := EcsActorFactory.spawn_enemy(world, definition, Vector2i(9, 3))
	var pawn_ai: EcsComponents.EnemyAI = world.get_component(pawn, EcsComponents.ENEMY_AI)
	var pawn_pos: EcsComponents.GridPos = world.get_component(pawn, EcsComponents.GRID_POS)
	var pawn_health: EcsComponents.Health = world.get_component(pawn, EcsComponents.HEALTH)
	var hero_pos: EcsComponents.GridPos = world.get_component(hero, EcsComponents.GRID_POS)
	var hero_health: EcsComponents.Health = world.get_component(hero, EcsComponents.HEALTH)

	_expect(pawn_health.current == definition.max_health, "enemy health comes from the definition")
	_expect(pawn_ai.decision_profile == definition.decision, "enemy AI profile comes from the definition")
	_expect(pawn_ai.attack_pattern == definition.unarmed_attack, "unarmed pattern comes from the definition")

	var pattern_cells := pawn_ai.attack_pattern.get_attack_cells(world.grid, Vector2i(6, 3), Vector2i.DOWN)
	_expect(Vector2i(5, 4) in pattern_cells and Vector2i(7, 4) in pattern_cells, "pawn pattern threatens both forward diagonals")

	var start_distance := world.grid.get_path_distance(pawn, pawn_pos.cell, hero_pos.cell)
	_tick(world, 4.0)
	var end_distance := world.grid.get_path_distance(pawn, pawn_pos.cell, hero_pos.cell)
	_expect(end_distance < start_distance, "AI pursuit closes the path distance (%d -> %d)" % [start_distance, end_distance])

	# Force a clean telegraph setup: park the enemy so the hero stands on a
	# threatened diagonal, then let one decision fire.
	world.grid.unregister_entity(pawn)
	pawn_pos.cell = Vector2i(3, 2)
	world.grid.register_entity(pawn, pawn_pos.cell)
	var pawn_facing: EcsComponents.Facing = world.get_component(pawn, EcsComponents.FACING)
	pawn_facing.direction = Vector2i.DOWN
	pawn_ai.state = EcsComponents.EnemyAI.STATE_OBSERVE
	pawn_ai.state_time_left = 0.01
	pawn_ai.action_memory.clear()
	world.grid.unregister_entity(hero)
	hero_pos.cell = Vector2i(2, 3)
	world.grid.register_entity(hero, hero_pos.cell)
	world.drain_events()
	world.tick(0.016)
	_expect(pawn_ai.state == EcsComponents.EnemyAI.STATE_TELEGRAPH and Vector2i(2, 3) in pawn_ai.locked_attack_cells, "adjacent diagonal hero triggers a telegraph")
	_expect(world.attack_token_owner == pawn, "telegraph takes the attack token")
	var telegraph_events := []
	for event in world.drain_events():
		telegraph_events.append(event.get("type"))
	_expect(&"telegraph_started" in telegraph_events, "telegraph emits its event")

	# Dodge: hero steps off the locked cell before the strike lands.
	world.grid.unregister_entity(hero)
	hero_pos.cell = Vector2i(2, 2)
	world.grid.register_entity(hero, hero_pos.cell)
	_tick(world, pawn_ai.telegraph_duration + 0.1)
	_expect(hero_health.current == hero_health.max_value, "hero dodges the telegraphed strike")
	_expect(world.attack_token_owner == 0, "a dodged strike still releases the token")

	# Token gate: with the token held elsewhere, no new telegraph starts.
	world.attack_token_owner = 999
	pawn_ai.state = EcsComponents.EnemyAI.STATE_OBSERVE
	pawn_ai.state_time_left = 0.01
	world.grid.unregister_entity(hero)
	hero_pos.cell = Vector2i(2, 3)
	world.grid.register_entity(hero, hero_pos.cell)
	world.tick(0.016)
	_expect(pawn_ai.state != EcsComponents.EnemyAI.STATE_TELEGRAPH, "a held token blocks a new telegraph")
	world.attack_token_owner = 0

	# Pickup: a weaponless enemy standing on a spear takes it.
	var spear := (load("res://resources/weapons/pencil_spear.tres") as EnemyWeapon).duplicate(true)
	EcsActorFactory.spawn_pickup(world, spear, pawn_pos.cell)
	pawn_ai.state = EcsComponents.EnemyAI.STATE_OBSERVE
	pawn_ai.state_time_left = 0.01
	pawn_ai.action_memory.clear()
	world.tick(0.016)
	var slot: EcsComponents.WeaponSlot = world.get_component(pawn, EcsComponents.WEAPON_SLOT)
	_expect(slot.weapon != null and slot.weapon.id == &"pencil_spear", "weaponless enemy picks up the local spear")
	_expect(world.grid.item_at(pawn_pos.cell) == 0, "taken pickup leaves the grid")

	# Defeat: damage to zero releases the grid cell and parks the AI.
	world.attack_token_owner = pawn
	world.damage_events.append({"target": pawn, "amount": 99, "direction": Vector2i.LEFT})
	world.tick(0.016)
	_expect(pawn_health.current == 0 and pawn_ai.state == EcsComponents.EnemyAI.STATE_DEFEATED, "lethal damage defeats the enemy")
	_expect(world.grid.entity_at(pawn_pos.cell) == 0, "defeated enemy frees its cell")
	_expect(world.attack_token_owner == 0, "defeat releases a held attack token")

	var succeeded := failures == 0
	print("ECS ENEMY TEST: %s" % ["PASS" if succeeded else "FAIL (%d)" % failures])
	quit(0 if succeeded else 1)
