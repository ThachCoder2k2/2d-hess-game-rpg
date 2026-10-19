extends UnboundTest

## Architecture guard (docs/game-base-plan.md 9.1, D-26): AppRoot is the project's main scene and owns what must
## outlive a screen. The autoplaying music player (it sat in scenes/main.tscn, then in the game scene) lives there,
## so a death, a room change or a trip to the title never restarts the music; the transition layer and the overlay
## it keeps run while the tree is paused; the screens are swapped as children of one host, never with change_scene;
## and the in-game scene still knows nothing of AppRoot, so it stays testable alone.

const ProjectFiles := preload("res://tests/architecture/project_files.gd")

const MINIMUM_SOURCE_FILES := 20


func _init() -> void:
	suite_title = "APP ROOT IS MAIN SCENE TEST"
	var paths := TestPaths.new(self)

	_expect(String(ProjectSettings.get_setting("application/run/main_scene", "")) == paths.main_scene(), "project.godot's main scene is AppRoot (%s)" % paths.main_scene())
	_expect(paths.main_scene().ends_with("shell/app_root.tscn") and paths.game_scene().ends_with("shell/game_root.tscn"), "and the in-game scene is another file")

	var app_scene := paths.load_scene(paths.main_scene())
	var game_scene := paths.load_scene(paths.game_scene())
	if app_scene == null or game_scene == null:
		finish()
		return
	var app := app_scene.instantiate()
	var music := app.get_node_or_null("MusicPlayer") as AudioStreamPlayer
	_expect(music != null and music.autoplay and music.bus == &"Music", "AppRoot carries the autoplaying MusicPlayer on the Music bus")
	_expect(music != null and music.process_mode == Node.PROCESS_MODE_ALWAYS, "and it keeps playing while the tree is paused")
	var stream := music.stream as AudioStreamWAV if music != null else null
	_expect(stream != null and stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "the march still loops from its embedded loop points")
	for always_node_path in ["OverlayLayer", "TransitionLayer"]:
		var always_node := app.get_node_or_null(always_node_path)
		_expect(always_node != null and always_node.process_mode == Node.PROCESS_MODE_ALWAYS, "%s keeps running while the tree is paused" % always_node_path)
	var transition := app.get_node_or_null("TransitionLayer") as CanvasLayer
	var overlay := app.get_node_or_null("OverlayLayer") as CanvasLayer
	_expect(transition != null and overlay != null and transition.layer > overlay.layer, "the fade covers the overlay")
	_expect(app.get("title_scene") != null and app.get("game_scene") != null and app.get("credits_scene") != null, "the three screens are wired in the editor")
	_expect(app.get("game_scene") == game_scene, "and the game screen is the in-game scene")
	app.free()

	var game := game_scene.instantiate()
	_expect(game.get_node_or_null("MusicPlayer") == null, "the in-game scene carries no music player")
	_expect(game.get_node_or_null("FadeLayer/FadeRect") is ColorRect, "but keeps its own zone-trip fade, which test_bridge_travel pins")
	game.free()

	var game_code := _code_of(FileAccess.get_file_as_string(paths.main_script()))
	_expect(not game_code.contains("AppRoot") and not game_code.contains("app_root"), "the in-game script's code names no AppRoot: it runs alone")

	var source_count := 0
	var changers: Array[String] = []
	for script_path in ProjectFiles.collect_files(["gd"]):
		if script_path.begins_with("res://tests/") or script_path.begins_with("res://tools/"):
			continue
		source_count += 1
		if _code_of(ProjectFiles.read_text(script_path)).contains("change_scene"):
			changers.append(script_path)
	_expect(source_count >= MINIMUM_SOURCE_FILES, "the walk found %d source scripts (at least %d)" % [source_count, MINIMUM_SOURCE_FILES])
	_expect(changers.is_empty(), "no source script calls change_scene: screens are swapped under AppRoot's host (found: %s)" % ", ".join(PackedStringArray(changers)))
	finish()


## The script's code with docstrings, string literals and comments removed.
func _code_of(source: String) -> String:
	var without_docstrings := RegEx.create_from_string("\"\"\"[\\s\\S]*?\"\"\"").sub(source, "", true)
	var without_strings := RegEx.create_from_string("\"(?:[^\"\\\\\\n]|\\\\.)*\"|'(?:[^'\\\\\\n]|\\\\.)*'").sub(without_docstrings, "\"\"", true)
	return RegEx.create_from_string("#[^\\n]*").sub(without_strings, "", true)
