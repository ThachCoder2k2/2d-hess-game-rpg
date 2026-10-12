class_name EcsActorFactory
extends RefCounted

## Builds entities from the same .tres content the node game uses — the
## Resource stays the single source of truth. Ports FreeEnemy._apply_definition
## (movement timing, decision observe delay, unarmed pattern timings, and the
## difficulty multipliers).


static func spawn_player(world: EcsWorld, cell: Vector2i, wooden_sword: AttackProfile, pencil_thrust: AttackProfile, courage := 3) -> int:
	var entity_id := world.create_entity()
	var grid_pos: EcsComponents.GridPos = world.add_component(entity_id, EcsComponents.GRID_POS, EcsComponents.GridPos.new())
	grid_pos.cell = cell
	var facing: EcsComponents.Facing = world.add_component(entity_id, EcsComponents.FACING, EcsComponents.Facing.new())
	facing.direction = Vector2i.DOWN
	world.add_component(entity_id, EcsComponents.MOVE_INTENT, EcsComponents.MoveIntent.new())
	world.add_component(entity_id, EcsComponents.MOVE_STATE, EcsComponents.MoveState.new())
	world.add_component(entity_id, EcsComponents.PLAYER_TAG, EcsComponents.PlayerTag.new())
	world.add_component(entity_id, EcsComponents.PLAYER_INPUT, EcsComponents.PlayerInput.new())
	world.add_component(entity_id, EcsComponents.ATTACK_INTENT, EcsComponents.AttackIntent.new())
	var health: EcsComponents.Health = world.add_component(entity_id, EcsComponents.HEALTH, EcsComponents.Health.new())
	health.current = courage
	health.max_value = courage
	var combat: EcsComponents.PlayerCombat = world.add_component(entity_id, EcsComponents.PLAYER_COMBAT, EcsComponents.PlayerCombat.new())
	combat.wooden_sword = wooden_sword
	combat.pencil_thrust = pencil_thrust
	world.grid.register_entity(entity_id, cell)
	return entity_id


static func spawn_enemy(world: EcsWorld, definition: EnemyDefinition, cell: Vector2i) -> int:
	var entity_id := world.create_entity()
	var grid_pos: EcsComponents.GridPos = world.add_component(entity_id, EcsComponents.GRID_POS, EcsComponents.GridPos.new())
	grid_pos.cell = cell
	var facing: EcsComponents.Facing = world.add_component(entity_id, EcsComponents.FACING, EcsComponents.Facing.new())
	facing.direction = Vector2i.DOWN
	world.add_component(entity_id, EcsComponents.MOVE_INTENT, EcsComponents.MoveIntent.new())
	var move: EcsComponents.MoveState = world.add_component(entity_id, EcsComponents.MOVE_STATE, EcsComponents.MoveState.new())
	var health: EcsComponents.Health = world.add_component(entity_id, EcsComponents.HEALTH, EcsComponents.Health.new())
	var ai: EcsComponents.EnemyAI = world.add_component(entity_id, EcsComponents.ENEMY_AI, EcsComponents.EnemyAI.new())
	var slot: EcsComponents.WeaponSlot = world.add_component(entity_id, EcsComponents.WEAPON_SLOT, EcsComponents.WeaponSlot.new())

	ai.definition = definition
	if definition != null:
		health.current = definition.max_health
		health.max_value = definition.max_health
		if definition.movement != null:
			move.duration = definition.movement.step_duration
			ai.move_recovery_time = definition.movement.move_recovery
			ai.allowed_directions = definition.movement.allowed_directions.duplicate()
			ai.path_memory_size = definition.movement.path_memory_size
			ai.goal_commitment_decisions = definition.movement.goal_commitment_decisions
		ai.decision_profile = definition.decision
		if ai.decision_profile != null:
			ai.observe_delay = ai.decision_profile.observe_delay
		if definition.unarmed_attack != null:
			ai.attack_pattern = definition.unarmed_attack
			ai.unarmed_telegraph_time = ai.attack_pattern.telegraph_duration
			ai.unarmed_recovery_time = ai.attack_pattern.recovery_duration
		if definition.difficulty != null:
			ai.observe_delay *= definition.difficulty.observe_time_multiplier
			move.duration *= definition.difficulty.movement_time_multiplier
			ai.move_recovery_time *= definition.difficulty.recovery_time_multiplier
			ai.unarmed_telegraph_time *= definition.difficulty.telegraph_time_multiplier
			ai.unarmed_recovery_time *= definition.difficulty.recovery_time_multiplier
		if definition.default_weapon != null:
			slot.weapon = definition.default_weapon.duplicate(true)
	ai.state = EcsComponents.EnemyAI.STATE_OBSERVE
	ai.state_time_left = ai.observe_delay
	world.grid.register_entity(entity_id, cell)
	return entity_id


static func spawn_pickup(world: EcsWorld, weapon: EnemyWeapon, cell: Vector2i) -> int:
	var entity_id := world.create_entity()
	var grid_pos: EcsComponents.GridPos = world.add_component(entity_id, EcsComponents.GRID_POS, EcsComponents.GridPos.new())
	grid_pos.cell = cell
	var pickup: EcsComponents.PickupItem = world.add_component(entity_id, EcsComponents.PICKUP_ITEM, EcsComponents.PickupItem.new())
	pickup.weapon = weapon
	world.grid.register_item(entity_id, cell)
	return entity_id
