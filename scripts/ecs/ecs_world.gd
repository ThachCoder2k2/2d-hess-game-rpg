class_name EcsWorld
extends Node

## The ECS runtime: entity ids, component stores, system tick loop, and the
## cross-system event queue. See docs/ecs-conversion-plan.md.

## component key (StringName) -> { entity id (int) -> component data (Object) }
var store_by_component: Dictionary = {}
var next_entity_id := 1
var systems: Array[EcsSystem] = []
## Cross-system messages (step_blocked, step_finished, damaged...). The
## HUD/camera bridge consumes them via drain_events after each tick.
var pending_events: Array[Dictionary] = []
## Damage requests ({target, amount, direction}) written by CombatSystem (and
## later EnemyAISystem), consumed exclusively by HealthSystem the same tick.
var damage_events: Array[Dictionary] = []
var grid := EcsGrid.new()
## When true, _process stops ticking — tests drive tick(delta) by hand instead.
var manual_tick := false


func create_entity() -> int:
	var entity_id := next_entity_id
	next_entity_id += 1
	return entity_id


func destroy_entity(entity_id: int) -> void:
	for store: Dictionary in store_by_component.values():
		store.erase(entity_id)
	grid.unregister_entity(entity_id)


func add_component(entity_id: int, component_key: StringName, data: Object) -> Object:
	if not store_by_component.has(component_key):
		store_by_component[component_key] = {}
	store_by_component[component_key][entity_id] = data
	return data


func get_component(entity_id: int, component_key: StringName) -> Variant:
	var store: Dictionary = store_by_component.get(component_key, {})
	return store.get(entity_id)


func has_component(entity_id: int, component_key: StringName) -> bool:
	return store_by_component.get(component_key, {}).has(entity_id)


func remove_component(entity_id: int, component_key: StringName) -> void:
	if store_by_component.has(component_key):
		store_by_component[component_key].erase(entity_id)


## All entity ids owning every listed component, smallest store first for speed.
func query(component_keys: Array[StringName]) -> Array[int]:
	var result: Array[int] = []
	if component_keys.is_empty():
		return result
	var smallest: Dictionary = store_by_component.get(component_keys[0], {})
	for component_key in component_keys:
		var store: Dictionary = store_by_component.get(component_key, {})
		if store.size() < smallest.size():
			smallest = store
	for entity_id: int in smallest.keys():
		var owns_all := true
		for component_key in component_keys:
			if not store_by_component.get(component_key, {}).has(entity_id):
				owns_all = false
				break
		if owns_all:
			result.append(entity_id)
	return result


func add_system(system: EcsSystem) -> void:
	system.setup(self)
	systems.append(system)


func emit_event(event: Dictionary) -> void:
	pending_events.append(event)


func drain_events() -> Array[Dictionary]:
	var drained: Array[Dictionary] = pending_events.duplicate()
	pending_events.clear()
	return drained


func tick(delta: float) -> void:
	for system in systems:
		system.tick(delta)


func _process(delta: float) -> void:
	if not manual_tick:
		tick(delta)
