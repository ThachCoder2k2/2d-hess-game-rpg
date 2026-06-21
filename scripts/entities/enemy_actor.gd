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
