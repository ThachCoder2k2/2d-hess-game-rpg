extends UnboundTest

## The tick order is data in ecs/schedule/ (docs/game-base-plan.md 13.4) and this suite holds the
## whole planned order, including the systems that later milestones add. A system added by a
## later milestone must land at its planned place; one that lands elsewhere, or a stage moved,
## fails here. The six systems that existed before M3a must keep their relative order, because
## the order is what the simulation's behaviour (and every room dump) depends on.

## The stages in the order they run. One file per stage in ecs/schedule/.
const PLANNED_STAGE_ORDER: Array[StringName] = [
	&"command", &"input", &"decide", &"cell_effects", &"move",
	&"act", &"resolve", &"react", &"progress", &"view",
]

## Every system of plan 13.4, "<stage>/<class name>", in running order. CombatSystem runs beside
## SkillSystem until the M7b parity cutover; it sits first because it is the one that exists.
const PLANNED_SYSTEM_ORDER: Array[String] = [
	"command/CommandSystem",
	"input/PlayerInputSystem",
	"decide/EnemyAISystem",
	"cell_effects/CellEffectSystem",
	"move/MovementSystem",
	"act/CombatSystem",
	"act/SkillSystem",
	"act/StatusSystem",
	"resolve/HealthSystem",
	"resolve/KnockbackSystem",
	"react/InteractionSystem",
	"react/TriggerSystem",
	"react/ObjectiveSystem",
	"progress/BossPhaseSystem",
	"progress/CheckpointSystem",
	"progress/ProgressionSystem",
	"progress/StoryBeatSystem",
	"view/HudSnapshotSystem",
	"view/ViewSyncSystem",
]

## The systems that ran before M3a, in the order game_root.gd registered them.
const SYSTEMS_BEFORE_M3A: Array[String] = [
	"PlayerInputSystem", "EnemyAISystem", "MovementSystem", "CombatSystem", "HealthSystem", "ViewSyncSystem",
]


## Records the order in which the world ticks its systems.
class OrderProbe:
	extends EcsSystem

	var label := ""
	var tick_log: Array[String] = []

	func tick(_delta: float) -> void:
		tick_log.append(label)


func _init() -> void:
	suite_title = "SCHEDULE ORDER TEST"

	var stage_names: Array[StringName] = []
	for stage in Schedule.phases():
		stage_names.append(stage.phase_name())
	_expect(stage_names == PLANNED_STAGE_ORDER, "the stages run in the planned order: %s" % ", ".join(PackedStringArray(PLANNED_STAGE_ORDER)))
	var stage_names_are_file_names := true
	for stage_script in Schedule.PHASE_SCRIPTS:
		var stage := stage_script.new() as SchedulePhase
		stage_names_are_file_names = stage_names_are_file_names and stage.phase_name() == StringName(stage_script.resource_path.get_file().get_basename())
	_expect(stage_names_are_file_names, "every stage is named after its file in ecs/schedule/")

	var scheduled: Array[String] = _scheduled_entries()
	_expect(_is_subsequence(scheduled, PLANNED_SYSTEM_ORDER), "the systems that exist appear in the planned order of plan 13.4: %s" % ", ".join(PackedStringArray(scheduled)))
	_expect(_is_subsequence(["move/MovementSystem", "command/CommandSystem"], PLANNED_SYSTEM_ORDER) == false, "the order check can fail: a late system listed before an early one is caught")
	_expect(_is_subsequence(["view/ViewSyncSystem", "view/ViewSyncSystem"], PLANNED_SYSTEM_ORDER) == false, "the order check can fail: a system listed twice is caught")

	var scheduled_classes: Array[String] = []
	for entry in scheduled:
		scheduled_classes.append(entry.get_slice("/", 1))
	var old_systems_in_schedule: Array[String] = []
	for class_name_text in scheduled_classes:
		if class_name_text in SYSTEMS_BEFORE_M3A:
			old_systems_in_schedule.append(class_name_text)
	_expect(old_systems_in_schedule == SYSTEMS_BEFORE_M3A, "the six systems that existed before M3a tick in their old order: %s" % ", ".join(PackedStringArray(old_systems_in_schedule)))
	_expect(scheduled_classes.back() == "ViewSyncSystem", "ViewSyncSystem, the one system that touches nodes, runs last")
	_expect(scheduled_classes.front() == "CommandSystem", "CommandSystem, which drains world.commands, runs first: a request lands before anything simulates")

	var every_phase_const_matches := true
	for stage in Schedule.phases():
		for system_script in stage.systems():
			var declared_phase: Variant = system_script.get_script_constant_map().get(&"PHASE")
			if declared_phase != stage.phase_name():
				every_phase_const_matches = false
				printerr("  %s declares PHASE %s but is listed in stage %s" % [system_script.get_global_name(), declared_phase, stage.phase_name()])
	_expect(every_phase_const_matches, "every system's PHASE const names the stage that lists it")

	var world := EcsWorld.new()
	world.manual_tick = true
	root.add_child(world)
	Schedule.populate(world)
	var registered: Array[GDScript] = []
	for system in world.systems:
		registered.append(system.get_script() as GDScript)
	_expect(registered == Schedule.system_scripts(), "Schedule.populate registers exactly the scheduled systems, in order")
	world.queue_free()

	var probe_world := EcsWorld.new()
	probe_world.manual_tick = true
	root.add_child(probe_world)
	var shared_log: Array[String] = []
	for label in ["first", "second", "third"]:
		var probe := OrderProbe.new()
		probe.label = label
		probe.tick_log = shared_log
		probe_world.add_system(probe)
	probe_world.tick(0.016)
	probe_world.tick(0.016)
	var expected_log: Array[String] = ["first", "second", "third", "first", "second", "third"]
	_expect(shared_log == expected_log, "a world ticks its systems in registration order, every tick")
	probe_world.queue_free()

	finish()


## "<stage>/<class name>" for every system the schedule lists, in order.
func _scheduled_entries() -> Array[String]:
	var entries: Array[String] = []
	for stage in Schedule.phases():
		for system_script in stage.systems():
			entries.append("%s/%s" % [stage.phase_name(), system_script.get_global_name()])
	return entries


## True when every entry of `candidate` appears in `reference`, in the same order, each once.
func _is_subsequence(candidate: Array[String], reference: Array[String]) -> bool:
	var search_from := 0
	for entry in candidate:
		var found_at := reference.find(entry, search_from)
		if found_at == -1:
			return false
		search_from = found_at + 1
	return true
