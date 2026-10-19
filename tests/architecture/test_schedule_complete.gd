extends UnboundTest

## Architecture guard (docs/game-base-plan.md 13.3 and 15 M3a): every `*_system.gd` under
## ecs/systems/ is listed exactly once in ecs/schedule/, in the stage its PHASE const names, and
## the schedule lists nothing else. It replaces the old `systems.size() == 6` pin
## (encounter_hud_runtime_test.gd): a count says "six"; this says which six and where.
##
## It also holds the other half of "the order is data": shell/zone_stage.gd (which builds the in-game
## scene's world for shell/game_root.gd) and tools/world_dumper.gd build their worlds with
## Schedule.populate() and keep no list of their own to forget.

const ProjectFiles := preload("res://tests/architecture/project_files.gd")

## A system folder with fewer system files than this means the walk is broken, not complete.
const MINIMUM_SYSTEM_FILES := 6
const SYSTEM_FILE_SUFFIX := "_system.gd"
## The two files of ecs/schedule/ that are not stages.
const NON_STAGE_FILES: Array[String] = ["schedule.gd", "schedule_phase.gd"]


func _init() -> void:
	suite_title = "SCHEDULE COMPLETE TEST"
	var paths := TestPaths.new(self)

	var system_paths: Array[String] = []
	for script_path in ProjectFiles.collect_files(["gd"], paths.ecs_systems_directory()):
		if script_path.ends_with(SYSTEM_FILE_SUFFIX):
			system_paths.append(script_path)
	_expect(system_paths.size() >= MINIMUM_SYSTEM_FILES, "the walk found %d system files under ecs/systems/ (at least %d)" % [system_paths.size(), MINIMUM_SYSTEM_FILES])

	var listed_paths: Array[String] = []
	var stage_by_listed_path: Dictionary = {}
	for stage in Schedule.phases():
		for system_script in stage.systems():
			listed_paths.append(system_script.resource_path)
			stage_by_listed_path[system_script.resource_path] = stage.phase_name()

	var problems := _listing_problems(system_paths, listed_paths)
	_expect(problems.is_empty(), "every *_system.gd under ecs/systems/ is listed exactly once in ecs/schedule/ and nothing else is (%s)" % "; ".join(PackedStringArray(problems)))

	# The check must be able to fail: an unlisted system, a doubly listed one and a stranger.
	var unlisted_problems := _listing_problems(["res://ecs/systems/a/a_system.gd", "res://ecs/systems/b/b_system.gd"], ["res://ecs/systems/a/a_system.gd"])
	_expect(unlisted_problems.size() == 1 and unlisted_problems[0].contains("not listed"), "the listing check catches a system file the schedule forgot")
	var doubled_problems := _listing_problems(["res://ecs/systems/a/a_system.gd"], ["res://ecs/systems/a/a_system.gd", "res://ecs/systems/a/a_system.gd"])
	_expect(doubled_problems.size() == 1 and doubled_problems[0].contains("2 times"), "the listing check catches a system listed twice")
	var stranger_problems := _listing_problems(["res://ecs/systems/a/a_system.gd"], ["res://ecs/systems/a/a_system.gd", "res://elsewhere/other_system.gd"])
	_expect(stranger_problems.size() == 1 and stranger_problems[0].contains("not a *_system.gd under ecs/systems/"), "the listing check catches a listed script that is not a system file")

	var every_system_is_filed_right := true
	for listed_path: String in listed_paths:
		var system_script := load(listed_path) as GDScript
		if system_script == null:
			every_system_is_filed_right = false
			printerr("  cannot load the scheduled script %s" % listed_path)
			continue
		var declared_phase: Variant = system_script.get_script_constant_map().get(&"PHASE")
		if declared_phase != stage_by_listed_path[listed_path]:
			every_system_is_filed_right = false
			printerr("  %s declares PHASE %s but ecs/schedule/%s.gd lists it" % [listed_path, declared_phase, stage_by_listed_path[listed_path]])
		if not (system_script.new() is EcsSystem):
			every_system_is_filed_right = false
			printerr("  %s is scheduled but does not extend EcsSystem" % listed_path)
	_expect(every_system_is_filed_right, "every scheduled system extends EcsSystem and declares the PHASE of the stage that lists it")

	var stage_files: Array[String] = []
	for stage_path in ProjectFiles.collect_files(["gd"], paths.ecs_schedule_directory()):
		if stage_path.get_file() not in NON_STAGE_FILES:
			stage_files.append(stage_path)
	var stage_script_paths: Array[String] = []
	for stage_script in Schedule.PHASE_SCRIPTS:
		stage_script_paths.append(stage_script.resource_path)
	stage_files.sort()
	stage_script_paths.sort()
	_expect(stage_files == stage_script_paths, "every stage file in ecs/schedule/ is in Schedule.PHASE_SCRIPTS and the reverse (%d files)" % stage_files.size())

	# The scene builds its world through ZoneStage.make_world (M3b step 2 moved the world node out of game_root.gd).
	for owner_script_path in [paths.zone_stage_script(), paths.world_dumper_script()]:
		var owner_text := paths.read_text(owner_script_path)
		_expect(owner_text.contains("Schedule.populate("), "%s builds its world with Schedule.populate()" % owner_script_path.get_file())
		_expect(not owner_text.contains("add_system("), "%s keeps no list of systems of its own" % owner_script_path.get_file())
	var scene_text := paths.read_text(paths.main_script())
	_expect(scene_text.contains("ZoneStage.make_world(") and not scene_text.contains("add_system("), "%s builds its world through ZoneStage.make_world and keeps no list of systems of its own" % paths.main_script().get_file())

	finish()


## Problems between the system files found on disk and the scripts the schedule lists.
func _listing_problems(system_file_paths: Array, listed_script_paths: Array) -> Array[String]:
	var problems: Array[String] = []
	for system_file_path: String in system_file_paths:
		var times_listed := listed_script_paths.count(system_file_path)
		if times_listed == 0:
			problems.append("%s is not listed" % system_file_path)
		elif times_listed > 1:
			problems.append("%s is listed %d times" % [system_file_path, times_listed])
	for listed_path: String in listed_script_paths:
		if listed_path not in system_file_paths:
			problems.append("%s is listed but is not a *_system.gd under ecs/systems/" % listed_path)
	return problems
