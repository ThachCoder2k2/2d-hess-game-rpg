class_name WeaponComponent
extends EntityComponent

## Arms the entity at spawn: sets the WeaponSlot to a copy of the assigned
## EnemyWeapon .tres. Beats the definition's default_weapon, so one parked
## enemy can carry something special without a new definition.

@export var weapon: EnemyWeapon


func apply(world: EcsWorld, entity_id: int) -> void:
	if weapon == null:
		return
	var slot: EcsComponents.WeaponSlot = world.get_component(entity_id, EcsComponents.WEAPON_SLOT)
	if slot == null:
		slot = world.add_component(entity_id, EcsComponents.WEAPON_SLOT, EcsComponents.WeaponSlot.new())
	slot.weapon = weapon.duplicate(true)
