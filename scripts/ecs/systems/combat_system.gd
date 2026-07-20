class_name CombatSystem
extends EcsSystem

## The player attack lifecycle as timers instead of coroutines: consume
## AttackIntent, lock target cells at swing start, resolve damage at impact,
## release the cooldown after recovery. Damage goes into world.damage_events;
## HealthSystem applies it. Timing rules ported from the node-era
## PlayerCombatComponent (impact_delay wait, then recovery - impact_delay).


func tick(delta: float) -> void:
	for entity_id in world.query([EcsComponents.PLAYER_COMBAT, EcsComponents.GRID_POS, EcsComponents.FACING]):
		var combat: EcsComponents.PlayerCombat = world.get_component(entity_id, EcsComponents.PLAYER_COMBAT)
		combat.attack_visual_time = maxf(0.0, combat.attack_visual_time - delta)
		if combat.skill_cooldown_left > 0.0:
			combat.skill_cooldown_left = maxf(0.0, combat.skill_cooldown_left - delta)
			world.emit_event({"type": &"skill_cooldown", "entity": entity_id, "time_left": combat.skill_cooldown_left})

		# Consume the intent every tick — a press during cooldown is swallowed,
		# never banked (matches the node-era behavior).
		var kind: StringName = &"none"
		var intent: EcsComponents.AttackIntent = world.get_component(entity_id, EcsComponents.ATTACK_INTENT)
		if intent != null and intent.kind != &"none":
			kind = intent.kind
			intent.kind = &"none"

		if combat.attack_on_cooldown:
			if combat.impact_left > 0.0:
				combat.impact_left -= delta
				if combat.impact_left <= 0.0:
					_resolve_impact(entity_id, combat)
			else:
				combat.recovery_left -= delta
				if combat.recovery_left <= 0.0:
					combat.attack_on_cooldown = false
					combat.active_attack = null
			continue

		if kind == &"none" or not _can_start_attack(entity_id):
			continue

		var profile: AttackProfile = combat.wooden_sword
		if kind == &"skill":
			if combat.skill_cooldown_left > 0.0:
				continue
			profile = combat.pencil_thrust
			combat.skill_cooldown_left = combat.skill_cooldown_duration
			world.emit_event({"type": &"skill_cooldown", "entity": entity_id, "time_left": combat.skill_cooldown_left})
		if profile == null:
			continue

		var grid_pos: EcsComponents.GridPos = world.get_component(entity_id, EcsComponents.GRID_POS)
		var facing: EcsComponents.Facing = world.get_component(entity_id, EcsComponents.FACING)
		combat.attack_on_cooldown = true
		combat.active_attack = profile
		combat.pending_cells = profile.get_target_cells(grid_pos.cell, facing.direction)
		combat.impact_left = profile.impact_delay
		combat.recovery_left = maxf(0.0, profile.recovery - profile.impact_delay)
		combat.attack_visual_time = profile.impact_delay + 0.10
		world.emit_event({"type": &"attack_started", "entity": entity_id, "cells": combat.pending_cells})


func _can_start_attack(entity_id: int) -> bool:
	var move: EcsComponents.MoveState = world.get_component(entity_id, EcsComponents.MOVE_STATE)
	if move != null and move.moving:
		return false
	var tag: EcsComponents.PlayerTag = world.get_component(entity_id, EcsComponents.PLAYER_TAG)
	return tag == null or tag.control_enabled


func _resolve_impact(entity_id: int, combat: EcsComponents.PlayerCombat) -> void:
	var facing: EcsComponents.Facing = world.get_component(entity_id, EcsComponents.FACING)
	var hit_count := 0
	for target_cell in combat.pending_cells:
		var target := world.grid.entity_at(target_cell)
		if target != 0 and target != entity_id and world.has_component(target, EcsComponents.HEALTH):
			world.damage_events.append({
				"target": target,
				"amount": combat.active_attack.damage,
				"direction": facing.direction if facing != null else Vector2i.ZERO,
			})
			hit_count += 1
	world.emit_event({"type": &"attack_landed", "entity": entity_id, "cells": combat.pending_cells, "hit_count": hit_count, "profile": combat.active_attack})
	combat.pending_cells = []
