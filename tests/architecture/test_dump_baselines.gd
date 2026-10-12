extends UnboundTest

## Architecture guard (ENFORCING): the deterministic world dump of every baseline
## room must equal tests/baselines/dump_<room>.txt byte for byte. The dump covers
## the node tree, sprite and tile-set texture paths, board cells and every entity's
## components after boot and after 120 ticks (docs/game-base-plan.md 13.7), so a
## folder move, an actor-scene collapse or a system reorder that changes what a room
## contains shows up here as a line-level diff. It is the cross-milestone regression
## check; screenshots are not.
##
## A deliberate change to a room or an entity is accepted by regenerating:
##   godot --headless --path . -s tools/dump_world.gd -- --write-baselines
## and reviewing the baseline diff in the same commit.
##
## Needs the generated art (tools/bootstrap_worktree.sh): rooms name textures under
## assets/sprites/generated/.

const WorldDumper := preload("res://tools/world_dumper.gd")

## A baseline with fewer lines is an empty/stale read, not a real dump (a wrong path reads "").
const MINIMUM_BASELINE_LINES := 30
const MAX_DIFF_LINES_PRINTED := 12

func _init() -> void:
	suite_title = "DUMP BASELINES TEST"
	var dumper := WorldDumper.new()
	_expect(WorldDumper.BASELINE_ROOM_IDS.size() == 6, "six baseline rooms are listed (t1-t4, b1, h1)")
	for room_id in WorldDumper.BASELINE_ROOM_IDS:
		var baseline_path := dumper.baseline_path(room_id)
		_expect(FileAccess.file_exists(baseline_path), "baseline file exists: %s" % baseline_path)
		var baseline_text := FileAccess.get_file_as_string(baseline_path)
		_expect(baseline_text.count("\n") >= MINIMUM_BASELINE_LINES, "baseline %s has real content (%d lines)" % [room_id, baseline_text.count("\n")])

		var current_text := dumper.dump_room(self, room_id)
		_expect(not current_text.is_empty(), "room '%s' boots headless%s" % [room_id, "" if dumper.last_error.is_empty() else " (" + dumper.last_error + ")"])
		if current_text.is_empty():
			continue
		var matches_baseline := current_text == baseline_text
		_expect(matches_baseline, "dump of '%s' equals its baseline" % room_id)
		if not matches_baseline:
			_print_first_differences(room_id, baseline_text, current_text)

		var second_text := dumper.dump_room(self, room_id)
		_expect(second_text == current_text, "dump of '%s' is deterministic (two runs in one process are identical)" % room_id)

	finish()


## Prints the first differing lines as "line N: baseline | current", enough to see what moved.
func _print_first_differences(room_id: String, baseline_text: String, current_text: String) -> void:
	var baseline_lines := baseline_text.split("\n")
	var current_lines := current_text.split("\n")
	printerr("  dump '%s' differs: baseline %d lines, current %d lines" % [room_id, baseline_lines.size(), current_lines.size()])
	var printed := 0
	for index in range(maxi(baseline_lines.size(), current_lines.size())):
		var baseline_line := baseline_lines[index] if index < baseline_lines.size() else "<missing>"
		var current_line := current_lines[index] if index < current_lines.size() else "<missing>"
		if baseline_line == current_line:
			continue
		printerr("  line %d: baseline | %s" % [index + 1, baseline_line.left(160)])
		printerr("  line %d: current  | %s" % [index + 1, current_line.left(160)])
		printed += 1
		if printed >= MAX_DIFF_LINES_PRINTED:
			printerr("  ... (more differences not shown)")
			return
