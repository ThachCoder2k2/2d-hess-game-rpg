class_name EnemyActor
extends FreeEnemy

var movement_component: GridMovementComponent
var brain_component: EnemyBrainComponent
var attack_component: AttackComponent
var health_component: HealthComponent
var equipment_component: EquipmentComponent
var enemy_debug_component: EnemyDebugComponent


func _ready() -> void:
	super()
	_configure_components()


func setup(world: GridWorld, start_cell: Vector2i) -> bool:
	_ensure_ai_data()
	_configure_components()
	if movement_component != null:
		return movement_component.setup(world, start_cell)
	return super(world, start_cell)


func try_step(direction: Vector2i) -> bool:
	_configure_components()
	if movement_component != null:
		return movement_component.request_step(direction)
	return super(direction)


func get_cardinal_move_options() -> Array[Vector2i]:
	_configure_components()
	if movement_component != null:
		return movement_component.get_legal_moves()
	return super()


func equip(item: EnemyWeapon) -> void:
	_configure_components()
	if equipment_component != null:
		equipment_component.try_equip(item)
		return
	super(item)


func can_collect_weapon(pickup: WeaponPickup) -> bool:
	_configure_components()
	return equipment_component != null and not equipment_component.is_armed() and pickup != null and equipment_component.can_equip(pickup.weapon)


func collect_weapon_pickup(pickup: WeaponPickup) -> bool:
	_configure_components()
	return equipment_component != null and equipment_component.collect_from(pickup)


func get_attack_cells(origin := current_cell, direction := facing) -> Array[Vector2i]:
	_configure_components()
	if equipment_component != null:
		return equipment_component.get_attack_cells(origin, direction)
	return super(origin, direction)


func get_attack_damage() -> int:
	_configure_components()
	return equipment_component.get_damage() if equipment_component != null else super()


func get_attack_telegraph_time() -> float:
	_configure_components()
	return equipment_component.get_telegraph_time() if equipment_component != null else super()


func get_attack_recovery_time() -> float:
	_configure_components()
	return equipment_component.get_recovery_time() if equipment_component != null else super()


func take_damage(amount: int, direction := Vector2i.ZERO) -> void:
	_configure_components()
	if health_component != null:
		health_component.apply_damage(amount, direction)
		return
	super(amount, direction)


func get_positioning_bonus(destination: Vector2i, direction: Vector2i, context: EnemyContext) -> float:
	var bonus := super(destination, direction, context)
	_ensure_ai_data()
	if archetype == null or archetype.role != &"flanker":
		return bonus
	if weapon == null and context.hero_cell in get_unarmed_attack_cells(destination, direction):
		bonus += 30.0
	if last_move_direction != Vector2i.ZERO:
		var previous_axis := last_move_direction.abs()
		var next_axis := direction.abs()
		if previous_axis != next_axis:
			bonus += 12.0
	return bonus


func _configure_components() -> void:
	movement_component = get_node_or_null("GridMovementComponent")
	brain_component = get_node_or_null("EnemyBrainComponent")
	attack_component = get_node_or_null("AttackComponent")
	health_component = get_node_or_null("HealthComponent")
	equipment_component = get_node_or_null("EquipmentComponent")
	enemy_debug_component = get_node_or_null("DebugComponent")
	var components: Array[EnemyComponent] = [
		movement_component,
		brain_component,
		attack_component,
		health_component,
		equipment_component,
		enemy_debug_component,
	]
	for component in components:
		if component != null:
			component.configure(self)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if definition == null:
		warnings.append("Assign an EnemyDefinition.")
	else:
		warnings.append_array(definition.validate())
	if get_node_or_null("GridMovementComponent") is not GridMovementComponent:
		warnings.append("GridMovementComponent is missing.")
	if get_node_or_null("EnemyBrainComponent") is not EnemyBrainComponent:
		warnings.append("EnemyBrainComponent is missing.")
	if get_node_or_null("AttackComponent") is not AttackComponent:
		warnings.append("AttackComponent is missing.")
	if get_node_or_null("HealthComponent") is not HealthComponent:
		warnings.append("HealthComponent is missing.")
	if get_node_or_null("EquipmentComponent") is not EquipmentComponent:
		warnings.append("EquipmentComponent is missing.")
	return warnings
