extends UnboundTest

## Architecture guard (docs/game-base-plan.md 9.4, 13.1, 15 M3a): the Input singleton is read in
## ONE place, shell/input/input_poller.gd, which copies the controls into world.input_snapshot once
## per frame. Everything else (PlayerInputSystem, game_root.gd, the views, the HUD) reads the
## snapshot. That is what lets a headless test drive the controls (test_input_snapshot), and what
## M4's rebinding, hold-or-toggle and pad support need: one reader to change.
##
## Tests and tools are not sources: a test may press a key with Input.action_press() to prove the
## poller sees it. A call counts when `Input.` appears in code, with comments and string literals
## removed (InputMap, InputEvent and InputSnapshot are other names and do not match).

const ProjectFiles := preload("res://tests/architecture/project_files.gd")

const POLLER_PATH := "res://shell/input/input_poller.gd"
## Fewer source files than this means the walk is broken, not clean.
const MINIMUM_SOURCE_FILES := 20


func _init() -> void:
	suite_title = "INPUT ONLY IN POLLER TEST"
	var string_literal_regex := RegEx.new()
	string_literal_regex.compile("\"(?:[^\"\\\\\\n]|\\\\.)*\"|'(?:[^'\\\\\\n]|\\\\.)*'")
	var comment_regex := RegEx.new()
	comment_regex.compile("#[^\\n]*")
	var triple_quoted_regex := RegEx.new()
	triple_quoted_regex.compile("\"\"\"[\\s\\S]*?\"\"\"")
	var singleton_call_regex := RegEx.new()
	singleton_call_regex.compile("(?<![A-Za-z0-9_])Input\\.")

	var source_count := 0
	var callers: Array[String] = []
	for script_path in ProjectFiles.collect_files(["gd"]):
		if script_path.begins_with("res://tests/") or script_path.begins_with("res://tools/"):
			continue
		source_count += 1
		var code := ProjectFiles.read_text(script_path)
		code = triple_quoted_regex.sub(code, "", true)
		code = string_literal_regex.sub(code, "\"\"", true)
		code = comment_regex.sub(code, "", true)
		if singleton_call_regex.search(code) != null:
			callers.append(script_path)

	_expect(source_count >= MINIMUM_SOURCE_FILES, "the walk found %d source scripts (at least %d)" % [source_count, MINIMUM_SOURCE_FILES])
	_expect(callers == [POLLER_PATH], "the Input singleton is called in %s and nowhere else (found: %s)" % [POLLER_PATH, ", ".join(PackedStringArray(callers))])

	# The check must be able to fail: the same pattern on code that does call Input from elsewhere.
	_expect(singleton_call_regex.search("if Input.is_action_pressed(&\"x\"):") != null, "the lint's pattern catches a call to the singleton")
	_expect(singleton_call_regex.search("InputMap.get_actions()") == null and singleton_call_regex.search("var snapshot: InputSnapshot") == null and singleton_call_regex.search("var raw_input := 1") == null, "and does not mistake InputMap, InputSnapshot or a name ending in input for it")
	finish()
