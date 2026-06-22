class_name EquipmentComponent
extends EnemyComponent

var equipped_weapon: EnemyWeapon


func configure(host: FreeEnemy) -> void:
	super(host)
	if equipped_weapon == null and actor.weapon != null:
		equipped_weapon = actor.weapon
	if equipped_weapon == null and actor.definition != null and actor.definition.default_weapon != null:
		try_equip(actor.definition.default_weapon.duplicate(true))


func get_weapon() -> EnemyWeapon:
	return equipped_weapon


func try_equip(weapon: EnemyWeapon) -> bool:
	if actor == null or weapon == null or not can_equip(weapon):
		return false
	equipped_weapon = weapon
	actor.weapon = weapon
	actor.emit_signal("weapon_changed", actor, weapon)
	actor.queue_redraw()
	return true


func can_equip(weapon: EnemyWeapon) -> bool:
	if actor == null or actor.definition == null or actor.definition.allowed_weapon_tags.is_empty():
		return true
	for tag in weapon.tags:
		if tag in actor.definition.allowed_weapon_tags:
			return true
	return false


func collect_from(pickup: WeaponPickup) -> bool:
	if actor == null or pickup == null or not is_instance_valid(pickup):
		return false
	var candidate := pickup.weapon
	if candidate == null or not can_equip(candidate):
		return false
	return try_equip(pickup.take(actor))


func is_armed() -> bool:
	return get_weapon() != null


func get_attack_cells(origin: Vector2i, facing: Vector2i) -> Array[Vector2i]:
	if equipped_weapon != null:
		return equipped_weapon.get_attack_cells(origin, facing)
	return actor.get_unarmed_attack_cells(origin, facing) if actor != null else []


func get_damage() -> int:
	if equipped_weapon != null:
		return equipped_weapon.damage
	return actor.attack_pattern.damage if actor != null and actor.attack_pattern != null else 1


func get_telegraph_time() -> float:
	return equipped_weapon.telegraph_time if equipped_weapon != null else actor.unarmed_telegraph_time


func get_recovery_time() -> float:
	return equipped_weapon.recovery_time if equipped_weapon != null else actor.unarmed_recovery_time
