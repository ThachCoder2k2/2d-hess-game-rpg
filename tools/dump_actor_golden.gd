extends SceneTree

## Prints (or records) the actor golden: what every actor scene looks like to the rest of the game
## (docs/game-base-plan.md 15 M2). It is the oracle of tests/architecture/test_actor_collapse_golden.gd.
##
##   godot --headless --path . -s tools/dump_actor_golden.gd                  print it
##   godot --headless --path . -s tools/dump_actor_golden.gd -- --write       record it, only if no golden exists yet
##   godot --headless --path . -s tools/dump_actor_golden.gd -- --write --force   overwrite the recorded golden
##
## The recorded file, tests/baselines/actor_collapse_golden.txt, was captured from the four
## hand-copied actor scenes BEFORE they were collapsed into actor_view_base.tscn, so it describes the
## old scenes and must not be re-recorded from the new ones: the test would then compare the new
## scenes with themselves. --write refuses to touch an existing file without --force, and the
## test asserts the file still names the commit it was captured at.

const ActorDumper := preload("res://tools/actor_dumper.gd")

## Where the golden is recorded.
const GOLDEN_PATH := "res://tests/baselines/actor_collapse_golden.txt"
const GOLDEN_FORMAT_VERSION := 1


func _init() -> void:
	var arguments := OS.get_cmdline_user_args()
	var dumper := ActorDumper.new()
	var header_lines := PackedStringArray([
		"# actor_collapse_golden v%d: how every actor scene looked BEFORE M2 collapsed them into presentation/views/actors/actor_view_base.tscn." % GOLDEN_FORMAT_VERSION,
		"# Captured from base/m2-1 (01f2283) by tools/dump_actor_golden.gd. The oracle of tests/architecture/test_actor_collapse_golden.gd; see tools/actor_dumper.gd for the line formats.",
		"# Never re-record it from the collapsed scenes: --write refuses an existing file unless --force is given.",
	])
	var text := dumper.golden_text(self, header_lines)
	if "--write" in arguments:
		if FileAccess.file_exists(GOLDEN_PATH) and not ("--force" in arguments):
			printerr("DUMP ACTOR GOLDEN: %s already exists; it is the record of the old scenes. Pass --force only if you mean to replace it." % GOLDEN_PATH)
			quit(1)
			return
		var file := FileAccess.open(GOLDEN_PATH, FileAccess.WRITE)
		if file == null:
			printerr("DUMP ACTOR GOLDEN: cannot write %s (error %d)" % [GOLDEN_PATH, FileAccess.get_open_error()])
			quit(1)
			return
		file.store_string(text)
		file.close()
		print("DUMP ACTOR GOLDEN: wrote %s (%d lines)" % [GOLDEN_PATH, text.count("\n")])
	else:
		print(text)
	quit(0)
