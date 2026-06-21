class_name EquipmentComponent
extends EnemyComponent


func get_weapon() -> EnemyWeapon:
	return actor.weapon if actor != null else null


func equip(weapon: EnemyWeapon) -> void:
	if actor != null:
		actor.equip(weapon)


func is_armed() -> bool:
	return get_weapon() != null
