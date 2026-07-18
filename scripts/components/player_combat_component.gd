class_name PlayerCombatComponent
extends PlayerComponent

## The attack lifecycle: profile targeting, damage application, cooldown and
## recovery windows, and the skill cooldown. Cooldown/visual state stays on the
## player (appearance and the HUD read it); this node owns the sequence.


func can_start_attack() -> bool:
	return player != null and not player.attack_on_cooldown and not player.is_moving \
		and player.grid_world != null and player.control_enabled


func try_skill() -> bool:
	if player.skill_cooldown_left > 0.0 or not can_start_attack():
		return false
	player.skill_cooldown_left = player.pencil_thrust_cooldown
	player.emit_signal("skill_cooldown_changed", player.skill_cooldown_left)
	try_attack(player.pencil_thrust)
	return true


func try_attack(profile: AttackProfile = null) -> bool:
	player._ensure_attack_profiles()
	if profile == null:
		profile = player.wooden_sword
	if not can_start_attack():
		return false
	player.attack_on_cooldown = true
	player.active_attack = profile
	player.attack_visual_time = profile.impact_delay + 0.10
	var target_cells := profile.get_target_cells(player.current_cell, player.facing)
	var tree := player.get_tree()
	if tree == null:
		player.attack_on_cooldown = false
		player.active_attack = null
		return false
	await tree.create_timer(profile.impact_delay).timeout
	if not is_instance_valid(player) or not player.is_inside_tree():
		return false
	var hit_count := 0
	var hit_actors: Dictionary = {}
	for target_cell in target_cells:
		var target := player.grid_world.actor_at(target_cell)
		if target != null and target != player and target.has_method("take_damage") and not hit_actors.has(target):
			target.take_damage(profile.damage, player.facing)
			hit_actors[target] = true
			hit_count += 1
	player.emit_signal("attack_landed", target_cells, hit_count, profile)
	await tree.create_timer(maxf(0.0, profile.recovery - profile.impact_delay)).timeout
	if not is_instance_valid(player) or not player.is_inside_tree():
		return false
	player.attack_on_cooldown = false
	player.active_attack = null
	player._flush_buffered_step()
	return true
