class_name CombatComponent
extends EntityComponent

## The player's combat loadout as an editor node: attack profiles + skill
## cooldown bake into the PlayerCombat component at spawn. Swap the .tres in
## the Inspector to change the kit — no code.

@export var wooden_sword: AttackProfile
@export var pencil_thrust: AttackProfile
@export_range(0.1, 5.0, 0.05) var skill_cooldown_duration := 1.25


func apply(world: EcsWorld, entity_id: int) -> void:
	var combat: EcsComponents.PlayerCombat = world.get_component(entity_id, EcsComponents.PLAYER_COMBAT)
	if combat == null:
		combat = world.add_component(entity_id, EcsComponents.PLAYER_COMBAT, EcsComponents.PlayerCombat.new())
	combat.wooden_sword = wooden_sword
	combat.pencil_thrust = pencil_thrust
	combat.skill_cooldown_duration = skill_cooldown_duration
