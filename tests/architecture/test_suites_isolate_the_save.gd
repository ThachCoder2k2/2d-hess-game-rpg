extends UnboundTest

## Architecture guard (docs/game-base-plan.md 9.3, the tests-never-touch-the-real-save rule of the M3b brief):
## a suite that boots the game, or makes a SaveService, gives it a throwaway folder first. The game reads the
## save when it starts (ensure_session) and writes it at every success event, so a suite that boots
## shell/game_root.tscn without isolating the service would read the player's own run and overwrite it
## (the runner gives every process its own HOME, but a suite run by hand does not).
##
## Two rules over every .gd file under tests/:
##   1. A suite that boots the game (calls Support.boot_main() or ShellSupport.boot_app(), or names game_root.tscn, instantiates a scene
##      and adds a node to the tree) also isolates the save: it names the isolated-service helper, the save
##      support, or calls configure(). Reading the scene as text (the audio bus scan) boots nothing.
##   2. No suite names the player's real save files: user://saves, user://profile.cfg or user://world_state.cfg
##      as a string. A suite plants files under its own throwaway root instead.
## The helpers that define the isolation (the two support files) and the test of this guard are exempt.

const ProjectFiles := preload("res://tests/architecture/project_files.gd")

## Text that means the suite boots the game: a boot helper (the bridge suites' boot_main, the shell suites' boot_app,
## which boots AppRoot and with it a New Game or a Continue), or all three of the markers below together.
const BOOT_HELPERS: Array[String] = ["boot_main(", "boot_app("]
const BOOT_SCENE_MARKERS: Array[String] = ["game_root.tscn", ".instantiate()", "add_child("]
## Text that means the suite isolates the save before it does.
const ISOLATION_MARKERS: Array[String] = ["install_isolated_save_service", "SaveSupport.", ".configure("]
## Paths of the player's real save files, as a suite would have to write them to touch them.
const REAL_SAVE_PATHS: Array[String] = ["user://saves", "user://profile.cfg", "user://world_state.cfg"]
const EXEMPT_PATHS: Array[String] = [
	"res://tests/bridge/bridge_support.gd",
	"res://tests/shell/shell_support.gd",
	"res://tests/support/save_test_support.gd",
	"res://tests/support/paths.gd",
	"res://tests/architecture/test_suites_isolate_the_save.gd",
	"res://tests/architecture/test_save_written_only_by_save_service.gd",
]
## Fewer suites than this means the walk is broken, not clean.
const MINIMUM_FILES := 30


func _init() -> void:
	suite_title = "SUITES ISOLATE THE SAVE TEST"
	var checked_files := 0
	var booting_files: Array[String] = []
	var not_isolated: Array[String] = []
	var touching_real_saves: Array[String] = []
	for script_path in ProjectFiles.collect_files(["gd"], "res://tests"):
		if script_path in EXEMPT_PATHS or script_path.begins_with("res://tests/fixtures/"):
			continue
		checked_files += 1
		var text := ProjectFiles.read_text(script_path)
		if _boots_the_game(text):
			booting_files.append(script_path)
			if not _mentions_any(text, ISOLATION_MARKERS):
				not_isolated.append(script_path)
		for real_path in REAL_SAVE_PATHS:
			if text.contains("\"" + real_path) or text.contains("'" + real_path):
				touching_real_saves.append("%s names %s" % [script_path, real_path])

	_expect(checked_files >= MINIMUM_FILES, "the walk found %d test files (at least %d)" % [checked_files, MINIMUM_FILES])
	_expect(booting_files.size() >= 6, "the walk sees the suites that boot the game (%d: the bridge suites and the full-scene test)" % booting_files.size())
	_expect(not_isolated.is_empty(), "every suite that boots the game isolates the save first (not isolated: %s)" % ", ".join(PackedStringArray(not_isolated)))
	_expect(touching_real_saves.is_empty(), "no suite names the player's real save files (%s)" % "; ".join(PackedStringArray(touching_real_saves)))

	# The guard must be able to fail.
	var careless_suite := "var main := (load(\"res://shell/game_root.tscn\") as PackedScene).instantiate()\nroot.add_child(main)"
	_expect(_boots_the_game(careless_suite) and not _mentions_any(careless_suite, ISOLATION_MARKERS), "a suite that boots the game and never isolates the save is caught")
	_expect(_boots_the_game("var app := await ShellSupport.boot_app(self)") and not _mentions_any("var app := await ShellSupport.boot_app(self)", ISOLATION_MARKERS), "a suite that boots AppRoot and never isolates the save is caught too")
	_expect(not _boots_the_game("var scene_text := FileAccess.get_file_as_string(paths.main_scene())"), "while a suite that only reads the scene as text boots nothing")
	_expect(_mentions_any("var careful := SaveSupport.new_service(root_directory)", ISOLATION_MARKERS), "and one that uses the save support is not")
	finish()


func _boots_the_game(text: String) -> bool:
	return _mentions_any(text, BOOT_HELPERS) or (_mentions_all(text, BOOT_SCENE_MARKERS))


func _mentions_all(text: String, markers: Array[String]) -> bool:
	for marker in markers:
		if not text.contains(marker):
			return false
	return true


func _mentions_any(text: String, markers: Array[String]) -> bool:
	for marker in markers:
		if text.contains(marker):
			return true
	return false
