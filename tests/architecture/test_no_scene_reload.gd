extends UnboundTest

## Architecture guard (docs/game-base-plan.md 9.1 and 15 M3b): nothing in the game reloads the scene.
## A death and the R key used to call `get_tree().reload_current_scene()`; once AppRoot is the main
## scene (M4) that would reload the title, and it threw away the music, the hero's view and every node
## with it. GameFlow now rebuilds the room inside the scene (`GameFlow.request_respawn`, served by
## `GameRoot.respawn`). A source script that calls the reload fails here.
##
## Tests and tools are not sources (a test may call it to prove a thing). A call counts when the name
## appears in code with comments and string literals removed.

const ProjectFiles := preload("res://tests/architecture/project_files.gd")

## Fewer source files than this means the walk is broken, not clean.
const MINIMUM_SOURCE_FILES := 20
const FORBIDDEN_CALL := "reload_current_scene"
## The two ways the game asks GameFlow to start the room again, as they are written at the call sites.
const REQUESTS: Array[String] = ["request_respawn(GameFlow.REASON_DEFEATED)", "request_respawn(GameFlow.REASON_RESTART_MENU)"]
const GAME_FLOW_PATH := "res://shell/game_flow.gd"


func _init() -> void:
	suite_title = "NO SCENE RELOAD TEST"
	var string_literal_regex := RegEx.create_from_string("\"(?:[^\"\\\\\\n]|\\\\.)*\"|'(?:[^'\\\\\\n]|\\\\.)*'")
	var comment_regex := RegEx.create_from_string("#[^\\n]*")
	var triple_quoted_regex := RegEx.create_from_string("\"\"\"[\\s\\S]*?\"\"\"")
	var source_count := 0
	var callers: Array[String] = []
	var requesters := {}
	for script_path in ProjectFiles.collect_files(["gd"]):
		if script_path.begins_with("res://tests/") or script_path.begins_with("res://tools/"):
			continue
		source_count += 1
		var code := ProjectFiles.read_text(script_path)
		code = triple_quoted_regex.sub(code, "", true)
		code = string_literal_regex.sub(code, "\"\"", true)
		code = comment_regex.sub(code, "", true)
		if code.contains(FORBIDDEN_CALL):
			callers.append(script_path)
		for request in REQUESTS:
			if code.contains(request) and script_path != GAME_FLOW_PATH:
				requesters[request] = true
	_expect(source_count >= MINIMUM_SOURCE_FILES, "the walk found %d source scripts (at least %d)" % [source_count, MINIMUM_SOURCE_FILES])
	_expect(callers.is_empty(), "no source script reloads the scene (found: %s)" % ", ".join(PackedStringArray(callers)))

	# The replacement exists and is wired: GameFlow serves a respawn request through GameRoot.respawn(),
	# and the game asks it for a death and for the pause menu's Restart Room.
	var paths := TestPaths.new(self)
	var flow_source := paths.read_text(paths.game_flow_script())
	_expect(flow_source.contains("signal respawn_requested") and flow_source.contains("func request_respawn(") and flow_source.contains("_root.respawn()"), "GameFlow raises respawn_requested and serves it through GameRoot.respawn()")
	_expect(requesters.has("request_respawn(GameFlow.REASON_DEFEATED)"), "a death asks GameFlow to start the room again")
	_expect(requesters.has("request_respawn(GameFlow.REASON_RESTART_MENU)"), "and so does the pause menu's Restart Room")

	# The lint must be able to fail.
	var sample := "func f():\n\tget_tree().reload_current_scene()\n"
	_expect(triple_quoted_regex.sub(sample, "", true).contains(FORBIDDEN_CALL), "the check finds a reload in code")
	finish()
