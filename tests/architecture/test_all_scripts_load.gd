extends UnboundTest

## Every .gd file in the project must compile (docs/game-base-plan.md gates G2 and
## G4). The editor import pass does NOT prove this: a script that no scene, no
## autoload and no other test loads is never compiled by it, so a type error or a
## stale `preload("res://...")` path inside such a script prints nothing and the
## import pass still exits 0. M1b moves about 90 scripts and rewrites `res://`
## strings, so this suite loads every one of them. `load()` on a script with an
## error prints `SCRIPT ERROR: Parse Error` (which the runner's marker scan fails
## on) and hands back a script that cannot be instantiated (which this suite
## fails on by name).
##
## Not loaded on purpose:
##  - tests/fixtures/ holds suites that misbehave deliberately (a script error in
##    `_init()`, a hang), so loading them would defeat their purpose.
##  - Hidden folders (.godot, .git, .claude) are skipped by `TestPaths.list_files`.

## The project held 87 scripts to compile (93 tracked, minus the 7 harness
## fixtures, plus this suite) when this suite was written. The count may only grow
## with the game; a smaller number means the walk lost part of the tree.
const MINIMUM_SCRIPT_COUNT := 85

## Folder prefixes below `res://` whose scripts are never compiled by this suite.
const EXCLUDED_PREFIXES: Array[String] = ["res://tests/fixtures/"]

## How many unloadable scripts to name in the failure label before summarising.
const MAX_NAMED := 12


func _init() -> void:
	var paths := TestPaths.new(self)
	var all_scripts := paths.list_files("res://", "gd", MINIMUM_SCRIPT_COUNT, true)

	var scripts_to_load: Array[String] = []
	for script_path in all_scripts:
		if not _is_excluded(script_path):
			scripts_to_load.append(script_path)
	_expect(scripts_to_load.size() >= MINIMUM_SCRIPT_COUNT, "the walk found at least %d scripts to compile (found %d)" % [MINIMUM_SCRIPT_COUNT, scripts_to_load.size()])

	var unloadable: Array[String] = []
	for script_path in scripts_to_load:
		var loaded := load(script_path) as GDScript
		if loaded == null or not loaded.can_instantiate():
			unloadable.append(script_path)
	_expect(unloadable.is_empty(), "every .gd script in the project loads and compiles")
	for index in range(mini(unloadable.size(), MAX_NAMED)):
		printerr("FAIL: script does not compile: %s" % unloadable[index])
	if unloadable.size() > MAX_NAMED:
		printerr("FAIL: ... and %d more scripts do not compile" % (unloadable.size() - MAX_NAMED))

	finish()


func _is_excluded(script_path: String) -> bool:
	for prefix in EXCLUDED_PREFIXES:
		if script_path.begins_with(prefix):
			return true
	return false
