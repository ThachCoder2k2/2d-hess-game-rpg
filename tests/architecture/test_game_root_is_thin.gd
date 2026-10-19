extends UnboundTest

## Architecture guard (docs/game-base-plan.md 13.2 and 15 M3b): shell/game_root.gd is the in-game scene
## that builds the world and ticks it; it holds NO game rule. Before M3b it was 637 lines that held the
## travel, the death, the save writes, the Book and the HUD wiring together, so that a change to any of
## them meant reading all of them. The rules went to one bridge per responsibility
## (presentation/bridges and shell/bridges); this guard keeps them from drifting back.
##
##   - the script is at most MAX_LINES long (the plan's target is about 150; the limit leaves room for
##     the scene's own docs and a new bridge's attach line, and a script over it is doing a bridge's work);
##   - in its code (comments and string literals removed) it reacts to no event: it never registers
##     for an event type itself (`.on(`), never names an `Events.` constant, never matches on an event's
##     type, never asks for a save (`request_save(`) and never reloads the scene.
## A "rule" is a decision about the game; the lint cannot read intent, so it checks the places a rule
## has always entered through: the event handlers, the save and the scene reload.

const ProjectFiles := preload("res://tests/architecture/project_files.gd")

## The most lines game_root.gd may have.
const MAX_LINES := 200
## Patterns that mean the scene reacts to the game itself, each with what it would be doing.
const FORBIDDEN_PATTERNS := {
	"\\.on\\(": "registering a handler for an event type (a bridge does that in its register())",
	"(?<![A-Za-z0-9_])Events\\.": "naming an event (a bridge reacts to events)",
	"request_save\\(": "asking for a save (the SaveBridge is the only asker)",
	"reload_current_scene": "reloading the scene (GameFlow rebuilds the room)",
	"match\\s+event": "matching on an event",
}


func _init() -> void:
	suite_title = "GAME ROOT IS THIN TEST"
	var paths := TestPaths.new(self)
	var source := paths.read_text(paths.main_script())
	var line_count := source.count("\n") + (0 if source.ends_with("\n") else 1)
	_expect(line_count <= MAX_LINES, "game_root.gd is %d lines (at most %d): a longer one is doing a bridge's work" % [line_count, MAX_LINES])

	var code := _code_of(source)
	for pattern: String in FORBIDDEN_PATTERNS:
		_expect(RegEx.create_from_string(pattern).search(code) == null, "game_root.gd does no %s" % FORBIDDEN_PATTERNS[pattern])

	# The lint must be able to fail: the same checks on a sample that does what the scene must not.
	var heavy_scene := "extends Node2D\nfunc _ready():\n\trouter.on(Events.DAMAGED, _on_damaged)\n\tsave.request_save(&\"x\")\n\tget_tree().reload_current_scene()\n"
	var caught: Array[String] = []
	for pattern: String in FORBIDDEN_PATTERNS:
		if RegEx.create_from_string(pattern).search(_code_of(heavy_scene)) != null:
			caught.append(pattern)
	_expect(caught.size() == 4, "the patterns catch a scene that registers for events, names them, saves and reloads (%d of 4 caught)" % caught.size())
	_expect(_code_of("# router.on(Events.X)\nvar note := \"request_save(\"\n") == "\nvar note := \"\"\n", "and comments and string literals are not mistaken for code")
	finish()


## The script's code with docstrings, string literals and comments removed.
func _code_of(source: String) -> String:
	var without_docstrings := RegEx.create_from_string("\"\"\"[\\s\\S]*?\"\"\"").sub(source, "", true)
	var without_strings := RegEx.create_from_string("\"(?:[^\"\\\\\\n]|\\\\.)*\"|'(?:[^'\\\\\\n]|\\\\.)*'").sub(without_docstrings, "\"\"", true)
	return RegEx.create_from_string("#[^\\n]*").sub(without_strings, "", true)
