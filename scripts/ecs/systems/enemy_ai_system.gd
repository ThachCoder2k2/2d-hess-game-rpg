class_name EnemyAISystem
extends EcsSystem

## The FreeEnemy brain as a system: observe -> decide -> telegraph -> commit ->
## recover, with intent scoring ported verbatim from
## scripts/actors/free_enemy.gd (behavior-parity rule in
## docs/ecs-conversion-plan.md). EnemyIntent (RefCounted) is reused unchanged.
## The attack token lives on the world (EncounterDirector port).


func tick(delta: float) -> void:
	var hero_id := _find_player()
	for entity_id in world.query([EcsComponents.ENEMY_AI, EcsComponents.GRID_POS, EcsComponents.FACING, EcsComponents.MOVE_STATE]):
		var ai: EcsComponents.EnemyAI = world.get_component(entity_id, EcsComponents.ENEMY_AI)
		if ai.state == EcsComponents.EnemyAI.STATE_DEFEATED:
			continue
		var move: EcsComponents.MoveState = world.get_component(entity_id, EcsComponents.MOVE_STATE)
		if hero_id == 0 or move.moving:
			continue
		ai.state_time_left -= delta
		if ai.state_time_left > 0.0:
			continue
		match ai.state:
			EcsComponents.EnemyAI.STATE_OBSERVE:
				_choose_action(entity_id, ai, hero_id)
			EcsComponents.EnemyAI.STATE_TELEGRAPH:
				_resolve_attack(entity_id, ai, hero_id)
			EcsComponents.EnemyAI.STATE_COMMIT:
				_resolve_attack(entity_id, ai, hero_id)
			EcsComponents.EnemyAI.STATE_RECOVER:
				ai.state = EcsComponents.EnemyAI.STATE_OBSERVE
				ai.state_time_left = ai.observe_delay


func _find_player() -> int:
	var players := world.query([EcsComponents.PLAYER_TAG, EcsComponents.GRID_POS])
	return players[0] if not players.is_empty() else 0


func _choose_action(entity_id: int, ai: EcsComponents.EnemyAI, hero_id: int) -> void:
	var grid_pos: EcsComponents.GridPos = world.get_component(entity_id, EcsComponents.GRID_POS)
	var facing: EcsComponents.Facing = world.get_component(entity_id, EcsComponents.FACING)
	var self_cell := grid_pos.cell
	var facing_direction := facing.direction

	# Context capture (EnemyContext port): enemies target the hero's reserved
	# cell while the hero slides — that is what makes dodging fair.
	var hero_pos: EcsComponents.GridPos = world.get_component(hero_id, EcsComponents.GRID_POS)
	var hero_cell := hero_pos.cell
	var reserved := world.grid.get_reserved_cell(hero_id)
	if reserved != Vector2i(-999, -999) and reserved != hero_cell:
		hero_cell = reserved
	var legal_moves := world.grid.get_destinations(entity_id, self_cell, ai.allowed_directions)
	var item_cells := world.grid.get_item_cells()
	var attack_available := world.attack_token_owner == 0 or world.attack_token_owner == entity_id

	var intents := _build_intents(entity_id, ai, self_cell, facing_direction, hero_cell, legal_moves, item_cells, attack_available)
	var best := intents[0]
	for candidate in intents:
		if candidate.score > best.score:
			best = candidate
	world.emit_event({"type": &"intent_changed", "entity": entity_id, "action": best.action_id, "score": best.score})
	_execute_intent(entity_id, ai, best)


func _build_intents(entity_id: int, ai: EcsComponents.EnemyAI, self_cell: Vector2i, facing_direction: Vector2i, hero_cell: Vector2i, legal_moves: Array[Vector2i], item_cells: Array[Vector2i], attack_available: bool) -> Array[EnemyIntent]:
	var profile := ai.decision_profile
	var intents: Array[EnemyIntent] = []
	var attack_cells := _get_attack_cells(entity_id, ai, self_cell, facing_direction)
	if attack_available and hero_cell in attack_cells:
		intents.append(EnemyIntent.attack(attack_cells, profile.attack_score))

	if world.grid.item_at(self_cell) != 0 and _weapon(entity_id) == null:
		intents.append(EnemyIntent.pickup(profile.pickup_score + profile.local_pickup_bonus))

	var pursuit_cell := _get_pursuit_goal(entity_id, ai, self_cell, hero_cell, item_cells)
	var next_path_cell := world.grid.get_next_path_cell(entity_id, self_cell, pursuit_cell)
	var has_fresh_move := false
	for destination in legal_moves:
		if destination not in ai.recent_cells:
			has_fresh_move = true
			break

	for destination in legal_moves:
		var direction := destination - self_cell
		var score := _score_destination(entity_id, ai, destination, direction, self_cell, hero_cell, pursuit_cell, next_path_cell, has_fresh_move)
		intents.append(EnemyIntent.move(destination, direction, score))

	if (ai.attack_pattern != null and ai.attack_pattern.uses_facing) or _weapon(entity_id) != null:
		for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if direction == facing_direction:
				continue
			var turn_score := 4.0
			if hero_cell in _get_attack_cells(entity_id, ai, self_cell, direction):
				turn_score += profile.turn_threat_score
			else:
				var old_distance := _facing_distance(self_cell, hero_cell, facing_direction)
				var new_distance := _facing_distance(self_cell, hero_cell, direction)
				turn_score += float(old_distance - new_distance) * profile.turn_progress_weight
			intents.append(EnemyIntent.turn(direction, turn_score))

	intents.append(EnemyIntent.wait(profile.wait_score))
	for intent in intents:
		if not String(intent.action_id).begins_with("move_"):
			intent.score -= float(ai.action_memory.count(intent.action_id)) * profile.repetition_penalty
	return intents


func _score_destination(entity_id: int, ai: EcsComponents.EnemyAI, destination: Vector2i, direction: Vector2i, self_cell: Vector2i, hero_cell: Vector2i, pursuit_cell: Vector2i, next_path_cell: Vector2i, penalize_recent: bool) -> float:
	var profile := ai.decision_profile
	var old_distance := world.grid.get_path_distance(entity_id, self_cell, pursuit_cell)
	var new_distance := world.grid.get_path_distance(entity_id, destination, pursuit_cell)
	if old_distance >= 999999 or new_distance >= 999999:
		old_distance = _manhattan(self_cell, pursuit_cell)
		new_distance = _manhattan(destination, pursuit_cell)
	var score := float(old_distance - new_distance) * profile.distance_score
	if destination == next_path_cell:
		score += profile.path_step_bonus
	if penalize_recent and destination in ai.recent_cells:
		score -= profile.recent_cell_penalty
	if _weapon(entity_id) == null and world.grid.item_at(destination) != 0:
		score += profile.pickup_score
	if hero_cell in _get_attack_cells(entity_id, ai, destination, direction):
		score += profile.future_threat_score
	var hero_distance := _manhattan(destination, hero_cell)
	score -= absf(float(hero_distance - profile.preferred_distance)) * profile.preferred_distance_weight
	return score + _positioning_bonus(entity_id, ai, destination, direction, hero_cell)


func _positioning_bonus(entity_id: int, ai: EcsComponents.EnemyAI, destination: Vector2i, direction: Vector2i, hero_cell: Vector2i) -> float:
	var profile := ai.decision_profile
	if profile == null:
		return 0.0
	var bonus := 0.0
	if profile.flank_bonus != 0.0 and _weapon(entity_id) == null and ai.attack_pattern != null \
			and hero_cell in ai.attack_pattern.get_attack_cells(world.grid, destination, direction):
		bonus += profile.flank_bonus
	if profile.axis_change_bonus != 0.0 and ai.last_move_direction != Vector2i.ZERO \
			and ai.last_move_direction.abs() != direction.abs():
		bonus += profile.axis_change_bonus
	return bonus


func _get_pursuit_goal(entity_id: int, ai: EcsComponents.EnemyAI, self_cell: Vector2i, hero_cell: Vector2i, item_cells: Array[Vector2i]) -> Vector2i:
	if _goal_is_valid(entity_id, ai, self_cell, hero_cell, item_cells) and ai.goal_decisions_left > 0:
		ai.goal_decisions_left -= 1
		return ai.committed_goal
	var item_goal := Vector2i(-999, -999)
	if _weapon(entity_id) == null:
		item_goal = _nearest_item_cell(entity_id, self_cell, item_cells)
	if item_goal != Vector2i(-999, -999):
		ai.committed_goal = item_goal
		ai.committed_goal_kind = &"weapon"
	else:
		ai.committed_goal = _find_attack_setup_goal(entity_id, ai, self_cell, hero_cell)
		ai.committed_goal_kind = &"attack_setup"
		ai.committed_target_snapshot = hero_cell
	ai.goal_decisions_left = ai.goal_commitment_decisions
	return ai.committed_goal


func _goal_is_valid(entity_id: int, ai: EcsComponents.EnemyAI, self_cell: Vector2i, hero_cell: Vector2i, item_cells: Array[Vector2i]) -> bool:
	if ai.committed_goal_kind == &"weapon":
		return _weapon(entity_id) == null and ai.committed_goal in item_cells and self_cell != ai.committed_goal
	if ai.committed_goal_kind == &"attack_setup":
		return ai.committed_target_snapshot == hero_cell and world.grid.is_plannable_cell(entity_id, ai.committed_goal)
	return false


func _nearest_item_cell(entity_id: int, self_cell: Vector2i, item_cells: Array[Vector2i]) -> Vector2i:
	var result := Vector2i(-999, -999)
	var best_distance := 999999
	for cell in item_cells:
		if not world.grid.is_plannable_cell(entity_id, cell):
			continue
		var distance := world.grid.get_path_distance(entity_id, self_cell, cell)
		if distance < best_distance:
			best_distance = distance
			result = cell
	return result


func _find_attack_setup_goal(entity_id: int, ai: EcsComponents.EnemyAI, self_cell: Vector2i, hero_cell: Vector2i) -> Vector2i:
	var best_cell := hero_cell
	var best_distance := 999999
	var bounds := world.grid.bounds
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			var candidate := Vector2i(x, y)
			if not world.grid.is_plannable_cell(entity_id, candidate):
				continue
			var can_attack_from_cell := false
			for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				if hero_cell in _get_attack_cells(entity_id, ai, candidate, direction):
					can_attack_from_cell = true
					break
			if not can_attack_from_cell:
				continue
			var distance := world.grid.get_path_distance(entity_id, self_cell, candidate)
			if distance < best_distance:
				best_distance = distance
				best_cell = candidate
	return best_cell if best_distance < 999999 else hero_cell


func _execute_intent(entity_id: int, ai: EcsComponents.EnemyAI, intent: EnemyIntent) -> void:
	ai.action_memory.append(intent.action_id)
	while ai.action_memory.size() > 3:
		ai.action_memory.pop_front()
	match intent.type:
		EnemyIntent.Type.ATTACK:
			if world.attack_token_owner != 0 and world.attack_token_owner != entity_id:
				ai.state = EcsComponents.EnemyAI.STATE_RECOVER
				ai.state_time_left = 0.12
				return
			world.attack_token_owner = entity_id
			ai.locked_attack_cells = intent.target_cells.duplicate()
			ai.state = EcsComponents.EnemyAI.STATE_TELEGRAPH
			ai.telegraph_duration = _telegraph_time(entity_id, ai)
			ai.state_time_left = ai.telegraph_duration
			world.emit_event({"type": &"telegraph_started", "entity": entity_id, "cells": ai.locked_attack_cells})
		EnemyIntent.Type.MOVE:
			ai.last_move_direction = intent.direction
			var move_intent: EcsComponents.MoveIntent = world.get_component(entity_id, EcsComponents.MOVE_INTENT)
			if move_intent != null:
				move_intent.direction = intent.direction
			# The reservation guarantees arrival, so the revisit memory can
			# record the destination at order time.
			ai.recent_cells.append(intent.destination)
			while ai.recent_cells.size() > ai.path_memory_size:
				ai.recent_cells.pop_front()
			ai.state = EcsComponents.EnemyAI.STATE_RECOVER
			ai.state_time_left = ai.move_recovery_time
		EnemyIntent.Type.PICKUP:
			_collect_local_item(entity_id)
			ai.state = EcsComponents.EnemyAI.STATE_RECOVER
			ai.state_time_left = 0.10
		EnemyIntent.Type.TURN:
			var facing: EcsComponents.Facing = world.get_component(entity_id, EcsComponents.FACING)
			facing.direction = intent.direction
			ai.state = EcsComponents.EnemyAI.STATE_RECOVER
			ai.state_time_left = 0.12
		EnemyIntent.Type.WAIT:
			ai.state = EcsComponents.EnemyAI.STATE_RECOVER
			ai.state_time_left = ai.observe_delay * 0.65


func _resolve_attack(entity_id: int, ai: EcsComponents.EnemyAI, hero_id: int) -> void:
	world.emit_event({"type": &"telegraph_finished", "entity": entity_id})
	var facing: EcsComponents.Facing = world.get_component(entity_id, EcsComponents.FACING)
	var hero_pos: EcsComponents.GridPos = world.get_component(hero_id, EcsComponents.GRID_POS)
	# Damage checks the hero's CURRENT cell against the locked cells — stepping
	# out during the telegraph dodges the strike.
	if hero_pos != null and hero_pos.cell in ai.locked_attack_cells:
		world.damage_events.append({
			"target": hero_id,
			"amount": _attack_damage(entity_id, ai),
			"direction": facing.direction,
		})
	world.emit_event({"type": &"attack_resolved", "entity": entity_id, "cells": ai.locked_attack_cells.duplicate()})
	ai.locked_attack_cells = []
	if world.attack_token_owner == entity_id:
		world.attack_token_owner = 0
	ai.state = EcsComponents.EnemyAI.STATE_RECOVER
	ai.state_time_left = _recovery_time(entity_id, ai)


func _collect_local_item(entity_id: int) -> void:
	var grid_pos: EcsComponents.GridPos = world.get_component(entity_id, EcsComponents.GRID_POS)
	var item_id := world.grid.item_at(grid_pos.cell)
	if item_id == 0:
		return
	var pickup: EcsComponents.PickupItem = world.get_component(item_id, EcsComponents.PICKUP_ITEM)
	var slot: EcsComponents.WeaponSlot = world.get_component(entity_id, EcsComponents.WEAPON_SLOT)
	if pickup == null or pickup.weapon == null or slot == null:
		return
	slot.weapon = pickup.weapon
	world.grid.take_item(grid_pos.cell)
	world.destroy_entity(item_id)
	world.emit_event({"type": &"weapon_changed", "entity": entity_id, "weapon": slot.weapon})


func _weapon(entity_id: int) -> EnemyWeapon:
	var slot: EcsComponents.WeaponSlot = world.get_component(entity_id, EcsComponents.WEAPON_SLOT)
	return slot.weapon if slot != null else null


func _get_attack_cells(entity_id: int, ai: EcsComponents.EnemyAI, origin: Vector2i, direction: Vector2i) -> Array[Vector2i]:
	var weapon := _weapon(entity_id)
	if weapon != null:
		return weapon.get_attack_cells(origin, direction)
	if ai.attack_pattern != null:
		return ai.attack_pattern.get_attack_cells(world.grid, origin, direction)
	return []


func _telegraph_time(entity_id: int, ai: EcsComponents.EnemyAI) -> float:
	var weapon := _weapon(entity_id)
	return weapon.telegraph_time if weapon != null else ai.unarmed_telegraph_time


func _recovery_time(entity_id: int, ai: EcsComponents.EnemyAI) -> float:
	var weapon := _weapon(entity_id)
	return weapon.recovery_time if weapon != null else ai.unarmed_recovery_time


func _attack_damage(entity_id: int, ai: EcsComponents.EnemyAI) -> int:
	var weapon := _weapon(entity_id)
	if weapon != null:
		return weapon.damage
	return ai.attack_pattern.damage if ai.attack_pattern != null else 1


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func _facing_distance(origin: Vector2i, destination: Vector2i, direction: Vector2i) -> int:
	var delta := destination - origin
	return absi(delta.x - direction.x) + absi(delta.y - direction.y)
