extends UnboundTest

## The oracle for the actor collapse (docs/game-base-plan.md 15 M2 acceptance, risk 6).
##
## tests/baselines/actor_collapse_golden.txt records how the hand-copied actor scenes (player,
## black_pawn, knight_enemy, bishop_enemy, enemy_base) looked BEFORE they became thin scenes that
## inherit presentation/views/actors/actor_view_base.tscn: every node path with its class, script,
## transform and texture, the values on the ActorView, the clips and the animation graph, and every
## component field EcsBoot bakes into the entity. This suite describes the CURRENT scenes the same
## way (tools/actor_dumper.gd) and requires each recorded line to be still there.
##
## The collapse is allowed to make exactly the differences listed in the tables below, each with
## its reason. Anything else fails the suite, with the line that moved:
##   - a recorded line that is missing from the new description and is not in REPLACED_LINES;
##   - a node path that the new description has and the golden has not, unless ADDED_NODES lists it;
##   - any difference in the baked entity (the "entity" block): there is no allowance for those,
##     because "every baked component field equal the old scene's" is the whole point.
## The in-cell geometry (where the body, pips, arrow, weapon and aura sit) is changed on purpose by
## the owner's decision of 2026-10-12 and is therefore excluded from the comparison here; it is
## asserted by test_pieces_inside_cell instead.
##
## Per-room entity sets and cells: the golden also records a fingerprint of everything each world
## dump baseline says before its "[nodes]" section. Those heads must not change by a byte.

const ActorDumper := preload("res://tools/actor_dumper.gd")
const WorldDumper := preload("res://tools/world_dumper.gd")

const GOLDEN_PATH := "res://tests/baselines/actor_collapse_golden.txt"
## The commit the golden was captured at, named in its header. If it is not there the golden was re-recorded.
const GOLDEN_CAPTURED_AT := "base/m2-1 (01f2283)"
const EXPECTED_ACTOR_COUNT := 5
## A section with fewer lines than this is an empty read, not a description.
const MINIMUM_LINES_PER_ACTOR := 40

## Actors whose scene was removed on purpose: id -> why nothing is lost.
const REMOVED_ACTORS := {}
## actor id -> { recorded line -> the line that replaces it }, one entry per intended difference.
const REPLACED_LINES := {}
## actor id -> node paths the new scene has that the old one had not (path -> why).
const ADDED_NODES := {}
## Line prefixes whose differences belong to the in-cell geometry decision (not compared here).
const GEOMETRY_LINE_PREFIXES: Array[String] = []

var dumper := ActorDumper.new()


func _init() -> void:
	suite_title = "ACTOR COLLAPSE GOLDEN TEST"
	var paths := TestPaths.new(self)
	var golden_text := paths.read_text(GOLDEN_PATH)
	if golden_text.is_empty():
		finish()
		return
	_expect(golden_text.contains(GOLDEN_CAPTURED_AT), "the golden still says it was captured at %s (it was not re-recorded from the new scenes)" % GOLDEN_CAPTURED_AT)
	var golden_sections := ActorDumper.sections_of(golden_text)
	_expect(golden_sections.size() == EXPECTED_ACTOR_COUNT, "the golden records %d actors (found %d)" % [EXPECTED_ACTOR_COUNT, golden_sections.size()])

	for actor_id: String in golden_sections:
		var golden_lines: PackedStringArray = golden_sections[actor_id]
		_expect(golden_lines.size() >= MINIMUM_LINES_PER_ACTOR, "the golden section of %s has real content (%d lines)" % [actor_id, golden_lines.size()])
		if REMOVED_ACTORS.has(actor_id):
			_expect(not ResourceLoader.exists(String(ActorDumper.ACTOR_SCENES[actor_id]["path"])), "%s is removed on purpose (%s)" % [actor_id, REMOVED_ACTORS[actor_id]])
			continue
		var description := dumper.describe_actor(self, actor_id)
		_expect(not description.is_empty(), "%s: the scene still loads and boots headless" % actor_id)
		if description.is_empty():
			continue
		_compare_actor(actor_id, golden_lines, _lines_of(description))

	_check_room_heads(golden_text)
	finish()


func _compare_actor(actor_id: String, golden_lines: PackedStringArray, new_lines: PackedStringArray) -> void:
	var replaced: Dictionary = REPLACED_LINES.get(actor_id, {})
	var new_line_set := {}
	for line in new_lines:
		new_line_set[line] = true

	var missing: Array[String] = []
	var golden_line_set := {}
	var entity_lines_differ := false
	for golden_line in golden_lines:
		golden_line_set[golden_line] = true
		if _is_geometry_line(golden_line):
			continue
		if new_line_set.has(golden_line):
			continue
		if replaced.has(golden_line):
			if not new_line_set.has(replaced[golden_line]):
				missing.append("%s   (expected to become: %s)" % [golden_line, replaced[golden_line]])
			continue
		missing.append(golden_line)
		if not _is_description_line(golden_line):
			entity_lines_differ = true
	_expect(missing.is_empty(), "%s: every recorded line is still in the new description (%d are not)" % [actor_id, missing.size()])
	for line in missing.slice(0, 12):
		printerr("  %s: no longer present: %s" % [actor_id, line.left(200)])
	_expect(not entity_lines_differ, "%s: the baked entity equals the old scene's, field by field" % actor_id)

	var added_nodes: Array[String] = []
	var allowed_added: Dictionary = ADDED_NODES.get(actor_id, {})
	for line in new_lines:
		if not line.begins_with("node ") or golden_line_set.has(line) or _is_geometry_line(line):
			continue
		var node_path := line.get_slice(" ", 1)
		if allowed_added.has(node_path) or _golden_has_node_path(golden_lines, node_path):
			continue
		added_nodes.append(node_path)
	_expect(added_nodes.is_empty(), "%s: no node appeared that was not declared (%s)" % [actor_id, ", ".join(added_nodes)])
	for node_path: String in allowed_added:
		_expect(new_line_set.keys().any(func(line: String) -> bool: return line.begins_with("node %s " % node_path)), "%s: the declared new node %s exists (%s)" % [actor_id, node_path, allowed_added[node_path]])


func _golden_has_node_path(golden_lines: PackedStringArray, node_path: String) -> bool:
	for line in golden_lines:
		if line.begins_with("node %s " % node_path):
			return true
	return false


## "node", "view", "clip", "state", "transition" and "tree_condition" lines describe the scene; the
## rest (the indented component lines and the "entity <id> ..." header) are the baked entity.
func _is_description_line(line: String) -> bool:
	for prefix in ["node ", "view ", "clip ", "state ", "transition ", "tree_condition "]:
		if line.begins_with(prefix):
			return true
	return false


func _is_geometry_line(line: String) -> bool:
	for prefix in GEOMETRY_LINE_PREFIXES:
		if line.begins_with(prefix):
			return true
	return false


func _lines_of(text: String) -> PackedStringArray:
	var lines := PackedStringArray()
	for line in text.split("\n"):
		if not line.strip_edges().is_empty():
			lines.append(line)
	return lines


## The golden's "[rooms]" section fingerprints each baseline's head. The baselines were regenerated
## when the actors collapsed, so this is the check that only [nodes] and [textures] moved.
func _check_room_heads(golden_text: String) -> void:
	var recorded_by_room := {}
	for line in golden_text.split("\n"):
		if line.begins_with("room "):
			recorded_by_room[line.get_slice(" ", 1)] = line
	_expect(recorded_by_room.size() == WorldDumper.BASELINE_ROOM_IDS.size(), "the golden fingerprints all %d baseline rooms (found %d)" % [WorldDumper.BASELINE_ROOM_IDS.size(), recorded_by_room.size()])
	var current_lines := dumper.room_head_lines()
	for current_line in current_lines:
		var room_id := current_line.get_slice(" ", 1)
		_expect(recorded_by_room.get(room_id, "") == current_line,
			"room %s: the grid, the board and every entity (cells and component fields) at boot and after 120 ticks equal the pre-collapse dump" % room_id)
