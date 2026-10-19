class_name Schedule
extends RefCounted

## The order the simulation ticks in, assembled from one file per stage (docs/game-base-plan.md
## 13.4). The order is data here and nowhere else: shell/game_root.gd and tools/world_dumper.gd
## both call populate() and keep no list of their own, and a test fails if either grows one.
##
## To add a system: put its file in ecs/systems/<folder>/ with `const PHASE := &"<stage>"` and add
## one line to that stage's file in ecs/schedule/. To add a stage (rare), add its file and one line
## to PHASE_SCRIPTS at the place it runs. test_schedule_order holds the whole planned order and
## test_schedule_complete fails on an unlisted, doubly listed or misfiled system.

## The stages, in the order they run in a tick.
const PHASE_SCRIPTS: Array[GDScript] = [
	preload("res://ecs/schedule/command.gd"),
	preload("res://ecs/schedule/input.gd"),
	preload("res://ecs/schedule/decide.gd"),
	preload("res://ecs/schedule/cell_effects.gd"),
	preload("res://ecs/schedule/move.gd"),
	preload("res://ecs/schedule/act.gd"),
	preload("res://ecs/schedule/resolve.gd"),
	preload("res://ecs/schedule/react.gd"),
	preload("res://ecs/schedule/progress.gd"),
	preload("res://ecs/schedule/view.gd"),
]


## One instance of every stage, in running order.
static func phases() -> Array[SchedulePhase]:
	var stages: Array[SchedulePhase] = []
	for phase_script in PHASE_SCRIPTS:
		stages.append(phase_script.new() as SchedulePhase)
	return stages


## Every system script of every stage, flattened in the order they run.
static func system_scripts() -> Array[GDScript]:
	var scripts: Array[GDScript] = []
	for stage in phases():
		scripts.append_array(stage.systems())
	return scripts


## A fresh instance of every system, in running order.
static func build_systems() -> Array[EcsSystem]:
	var built: Array[EcsSystem] = []
	for system_script in system_scripts():
		built.append(system_script.new() as EcsSystem)
	return built


## Registers every system on the world in running order: the one way a world gets its systems.
## A test that wants only some of them still calls world.add_system() by hand.
static func populate(world: EcsWorld) -> void:
	for system in build_systems():
		world.add_system(system)
