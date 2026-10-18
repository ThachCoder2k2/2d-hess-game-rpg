class_name EcsWorld
extends Node

## The ECS runtime: entity ids, component stores, the systems and their tick loop, and every
## queue and record the systems and presentation share. See docs/ecs-conversion-plan.md and
## docs/game-base-plan.md 14.1 and 14.5: every world field lands here once, so a later milestone
## adds behaviour to a field and never a new field to the hot file.

## component key (StringName) -> { entity id (int) -> component data (Object) }
var store_by_component: Dictionary = {}
var next_entity_id := 1
## The systems in the order they tick; Schedule.populate() fills it in the order of ecs/schedule/.
var systems: Array[EcsSystem] = []
var grid := EcsGrid.new()
## The one attack token (EncounterDirector port): only the holder may
## telegraph/strike. 0 = free. EnemyAISystem takes it; HealthSystem frees it
## when the holder dies.
var attack_token_owner := 0
## When true, _process stops ticking — tests drive tick(delta) by hand instead.
var manual_tick := false

## True while the simulation is held still: a cutscene beat, a pause. A frozen world ticks only
## the systems that answer true to runs_while_frozen() (the command system, so the freeze can end,
## and the view system, so the picture keeps being drawn); every other system, and so every timer
## and every enemy, waits exactly where it was. The queues below keep accepting requests while
## frozen; they are served when the world thaws. Presentation freezes and thaws the world with
## the `freeze_requested` and `unfreeze_requested` commands, never by writing the field.
var frozen := false

## The facts of this run that the story and the progression ask about (see WorldFlags). A fresh,
## empty object for every world; the shell carries what must outlive a room (M3b).
var flags := WorldFlags.new()

## The assists and settings that change how the simulation plays (see Tuning). Presentation changes
## it only with the `tuning_set` command.
var tuning := Tuning.new()

## What the player's controls look like this tick (see InputSnapshot). The shell fills it before
## ticking; the simulation never reads the Input singleton.
var input_snapshot := InputSnapshot.new()

## The read-only picture the HUD draws from (see HudSnapshot). HudSnapshotSystem builds it.
var hud_snapshot := HudSnapshot.new()

## Cross-system messages (step_blocked, step_finished, damaged...), declared in ecs/events/events.gd.
## The HUD/camera bridge consumes them via drain_events after each tick.
var pending_events: Array[Dictionary] = []

## Damage requests ({target, source, amount, direction, tags}) built only by Events.emit_damage()
## and consumed exclusively by HealthSystem the same tick.
var damage_events: Array[Dictionary] = []

## Heal requests ({target, source, amount}) built only by Events.emit_heal() and consumed
## exclusively by HealthSystem the same tick, after the damage requests.
var heal_events: Array[Dictionary] = []

## Requests from presentation and settings (freeze, set a flag, change tuning...): the ONLY channel
## into the simulation (docs/game-base-plan.md D-38). Each is a Dictionary with a "type", pushed
## with push_command() and drained by CommandSystem at the head of the next tick.
var commands: Array[Dictionary] = []

## command type (StringName) -> the Callable that applies it. Called by CommandSystem, in queue
## order, at the head of the tick, with the command Dictionary; it returns "" when it applied the
## command or the reason it could not. A system that owns the state a command changes registers
## the handler in setup() with register_command_handler().
var command_handler_by_type: Dictionary = {}

## Cosmetic instructions for the puppet views (play a clip, a bow, a wake), pushed by whoever stages
## the scene and consumed only by ViewSyncSystem, the one system that touches nodes. They never
## change the simulation.
var view_commands: Array[Dictionary] = []


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


## Queues an event for presentation. In debug builds the event must match its declaration in
## ecs/events/events.gd (declared, status EMITTED, exactly the documented keys).
func emit_event(event: Dictionary) -> void:
	assert(Events.problem_with(event).is_empty(), Events.problem_with(event))
	pending_events.append(event)


func drain_events() -> Array[Dictionary]:
	var drained: Array[Dictionary] = pending_events.duplicate()
	pending_events.clear()
	return drained


## Queues a request for the simulation; CommandSystem applies it at the head of the next tick.
## Build it with the functions of ecs/events/commands.gd. In debug builds it must match its
## declaration there.
func push_command(command: Dictionary) -> void:
	assert(Commands.problem_with(command).is_empty(), Commands.problem_with(command))
	commands.append(command)


## Queues a cosmetic instruction for the views; ViewSyncSystem plays it on its next tick. Build it
## with the functions of ecs/events/commands.gd (Commands.play_state).
func push_view_command(view_command: Dictionary) -> void:
	assert(Commands.view_command_problem_with(view_command).is_empty(), Commands.view_command_problem_with(view_command))
	view_commands.append(view_command)


## Makes `handler` the one that applies commands of `command_type` (see command_handler_by_type).
func register_command_handler(command_type: StringName, handler: Callable) -> void:
	command_handler_by_type[command_type] = handler


## Runs one tick: every system in order. A frozen world runs only the systems that
## runs_while_frozen(); `frozen` is checked before each one, so a command that freezes the world at
## the head of the tick stops the rest of that same tick.
func tick(delta: float) -> void:
	for system in systems:
		if frozen and not system.runs_while_frozen():
			continue
		system.tick(delta)


func _process(delta: float) -> void:
	if not manual_tick:
		tick(delta)
