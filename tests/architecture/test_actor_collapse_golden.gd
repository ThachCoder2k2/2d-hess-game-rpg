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
## Geometry is the one thing the owner's decision of 2026-10-12 (a piece is smaller than its cell)
## moves on purpose: where the body, pips, facing arrow, weapon and aura sit and how big they are.
## For those nodes the position, scale and centring are not compared (GEOMETRY_NODE_PATHS,
## GEOMETRY_TOKENS), nor are the two ActorView values that place the weapon
## (GEOMETRY_LINE_PREFIXES); test_pieces_inside_cell asserts the new geometry instead. What the nodes
## ARE (class, script, visibility, which picture) is still compared, and so is everything else.
##
## Per-room entity sets and cells: the golden also records a fingerprint of everything each world
## dump baseline says before its "[nodes]" section. Those heads must not change by a byte, except for the
## rooms ROOM_HEADS_CHANGED_ON_PURPOSE lists (a room edit made after the golden was captured, with its reason).

const ActorDumper := preload("res://tools/actor_dumper.gd")
const WorldDumper := preload("res://tools/world_dumper.gd")

const GOLDEN_PATH := "res://tests/baselines/actor_collapse_golden.txt"
## The commit the golden was captured at, named in its header. If it is not there the golden was re-recorded.
const GOLDEN_CAPTURED_AT := "base/m2-1 (01f2283)"
const EXPECTED_ACTOR_COUNT := 5
## A section with fewer lines than this is an empty read, not a description.
const MINIMUM_LINES_PER_ACTOR := 40

## Actors whose scene was removed on purpose: id -> why nothing is lost.
const REMOVED_ACTORS := {
	"enemy_base": "it was black_pawn.tscn byte for byte under another node name; no room, fixture or test instanced it, and a new enemy now starts from actor_view_base.tscn",
}

const BISHOP_BODY_BEFORE := "node MotionRoot/SpriteRoot/BodySprite Sprite2D z=0 texture=res://content/enemies/knight_tracker/body.png"
const BISHOP_BODY_NOW := "node MotionRoot/SpriteRoot/BodySprite Sprite2D z=0 texture=res://content/enemies/bishop_zoner/body.png"
const START_TO_IDLE := "transition Start -> idle switch=0 advance=2 condition= xfade=0.0000"
const START_TO_IDLE_NOW := "transition Start -> idle switch=0 advance=2 condition=boots_awake xfade=0.0000"

## actor id -> { recorded line -> the line that replaces it }, one entry per intended difference.
const REPLACED_LINES := {
	# Every actor boots through the graph's Start edges; the one graph serves both kinds of boot, so
	# each edge now waits for a condition that the scene sets (base: awake; the hero's scene: asleep).
	# The entity header names the piece by its text key and not by its English name (M4 step 3: a dump must not change
	# when a line is rewritten in a .po file).
	"black_pawn": {START_TO_IDLE: START_TO_IDLE_NOW, "entity 1 enemy:Pawn cell=(1,5)": "entity 1 enemy:ENEMY_PAWN_RECRUIT_PIECE cell=(1,5)"},
	"knight_enemy": {START_TO_IDLE: START_TO_IDLE_NOW, "entity 1 enemy:Knight cell=(1,5)": "entity 1 enemy:ENEMY_KNIGHT_TRACKER_PIECE cell=(1,5)"},
	# The bishop borrowed the knight's picture; it has its own body now (content/enemies/bishop_zoner/body.png).
	"bishop_enemy": {START_TO_IDLE: START_TO_IDLE_NOW, BISHOP_BODY_BEFORE: BISHOP_BODY_NOW, "entity 1 enemy:Bishop cell=(1,5)": "entity 1 enemy:ENEMY_BISHOP_ZONER_PIECE cell=(1,5)"},
	"player": {
		"transition Start -> wake switch=0 advance=2 condition= xfade=0.0000": "transition Start -> wake switch=0 advance=2 condition=boots_asleep xfade=0.0000",
		# The hero inherits the pips and the facing arrow, so it names their pictures and switches them
		# off here (it never showed a facing arrow or pips, and still does not).
		"view pip_empty_texture=null": "view pip_empty_texture=res://assets/ui/actor_view/health_pip_empty.png",
		"view pip_full_texture=null": "view pip_full_texture=res://assets/ui/actor_view/health_pip_full.png",
		"view show_facing_mark=true": "view show_facing_mark=false",
		"view show_health=true": "view show_health=false",
	},
}
## actor id -> node paths the new scene has that the old one had not (path -> why).
const ADDED_NODES := {
	"player": {
		"TelegraphAura": "inherited from the base, hidden: the hero never telegraphs",
		"MotionRoot/SpriteRoot/FacingArrow": "inherited from the base, hidden: show_facing_mark is off on the hero",
		"MotionRoot/SpriteRoot/HealthPips": "inherited from the base, hidden: show_health is off on the hero",
		"MotionRoot/SpriteRoot/HealthPips/Pip0": "inherited from the base, hidden with its parent",
		"MotionRoot/SpriteRoot/HealthPips/Pip1": "inherited from the base, hidden with its parent",
		"MotionRoot/SpriteRoot/HealthPips/Pip2": "inherited from the base, hidden with its parent",
	},
}
## Line prefixes whose differences belong to the in-cell geometry decision (not compared here): the
## hand and the length of the held weapon, now the same for every piece and measured in pixels
## inside the cell.
const GEOMETRY_LINE_PREFIXES: Array[String] = ["view weapon_anchor=", "view weapon_rest_length="]
## The nodes the in-cell geometry places. Their "position=", "scale=" and "centered=" are dropped
## from a node line before it is compared.
const GEOMETRY_NODE_PATHS: Array[String] = [
	"TelegraphAura",
	"MotionRoot/SpriteRoot/BodySprite",
	"MotionRoot/SpriteRoot/FacingArrow",
	"MotionRoot/SpriteRoot/WeaponPivot",
	"MotionRoot/SpriteRoot/WeaponPivot/WeaponSprite",
	"MotionRoot/SpriteRoot/HealthPips",
	"MotionRoot/SpriteRoot/HealthPips/Pip0",
	"MotionRoot/SpriteRoot/HealthPips/Pip1",
	"MotionRoot/SpriteRoot/HealthPips/Pip2",
]
const GEOMETRY_TOKENS: Array[String] = ["position", "scale", "centered"]

## room id -> { "line": the head line the room has now, "why": the reason }, for a room whose head was
## changed on purpose AFTER the golden was captured. The golden file keeps the M2 fingerprint (it is the
## record of the old scenes and is never re-recorded); a room listed here may equal either that or this line,
## so the table is the one place that says which rooms moved since and why. Nothing else may.
const ROOM_HEADS_CHANGED_ON_PURPOSE := {
	"t1": {"line": "room t1 head_sha256=b36a8c61289b9e04c24b0b8046e20e7381f2f3f9528957ff5daefd25793ad955 lines=47", "why": "every door line of the grid now carries the door's locked_message (empty on a door that is never shut): the shut doors say why in their own words (M3b review, base/m3b-fix3). Nothing else in the head moved"},
	"t2": {"line": "room t2 head_sha256=b0147a6a378f7f9ed2e1111dc69c761a932893bd0a938b148c51c87e5d418f55 lines=49", "why": "the west return door moved from the wall column (0, 5) to (1, 5) and the west entry from (1, 5) to (2, 5): the door stood on a solid cell and could not be walked to (M3b review, base/m3b-fix); and the locked_message key on every door line (base/m3b-fix3, as in t1); and the words of the door line (t3, t4, b1) or of the sword's unlock marker (t2) are text keys now, not sentences (M4 step 3: ROOM_..._LOCKED, ROOM_..._UNLOCK_SWORD)"},
	"t3": {"line": "room t3 head_sha256=85d339b506e9f589774e2464db91086512ae4641adecd0957625e71f94a6cdaa lines=58", "why": "the same door fix: return door (0, 5) -> (1, 5), west entry (1, 5) -> (2, 5); and the locked_message key on every door line, with the east door's own line (base/m3b-fix3); and the words of the door line (t3, t4, b1) or of the sword's unlock marker (t2) are text keys now, not sentences (M4 step 3: ROOM_..._LOCKED, ROOM_..._UNLOCK_SWORD)"},
	"t4": {"line": "room t4 head_sha256=28a1b3b0f33ca2140e5071e1abc352b05ec066ae0f46904a75db144c0ef9c52d lines=83", "why": "the same door fix: return door (0, 5) -> (1, 5), west entry (1, 5) -> (2, 5); and the pieces that stood on the wall cell (7, 6) (base/m3b-fix2): the Backstep Pawn moved to (10, 6) and the Pencil Spear to (13, 2). The pawn used to be outside the grid and took the spear by standing on it, so the spear was gone after the 120 ticks; now nobody is within reach of the idle hero, the spear is still on the floor and its entity is listed (82 -> 83 lines); and the locked_message key on every door line, with the east door's own line (base/m3b-fix3); and the words of the door line (t3, t4, b1) or of the sword's unlock marker (t2) are text keys now, not sentences (M4 step 3: ROOM_..._LOCKED, ROOM_..._UNLOCK_SWORD)"},
	"b1": {"line": "room b1 head_sha256=588b6459e59e1b281b0745151703fdc722c5a6e90a68148315b7c0fd020a5f6c lines=82", "why": "the same door fix; the hero now starts one cell further east, at (2, 5), and the guard beside the Ruler Blade takes the blade inside the 120 idle ticks: it steps onto the blade's cell (8, 6), picks it up and is back on (8, 5), so the blade is gone from the list after the ticks and 9 events are drained instead of 3. Before the move it had only reached (8, 6) and not yet taken the blade. The guard takes the blade either way: that is the rule of the owner guide's step 4, which test_owner_guide_steps waits for (about a second in); and the locked_message key on every door line, with the hub door's own line (base/m3b-fix3); and the words of the door line (t3, t4, b1) or of the sword's unlock marker (t2) are text keys now, not sentences (M4 step 3: ROOM_..._LOCKED, ROOM_..._UNLOCK_SWORD)"},
	"h1": {"line": "room h1 head_sha256=cfc29e1fb483d68648ce34424bca34c741de10c62ff9a6fcbc58bb2d7dec408e lines=52", "why": "the same door fix, and the top door to the Toybox moved from the wall row (2, 0) to (2, 1) with its entry from (2, 1) to (2, 2); and the locked_message key on every door line (base/m3b-fix3); and, at M5 step 1, that door no longer leads into the 72x40 kingdom fixture (which left the world graph) but into the Act 2 room tb1_toybox_gate by its entry from_h1: only the zone and entry in its exits line changed; and, at M5 step 2, the hub gets its five district doors: the Toybox door and four new ones (Bookshelf, Block Tower, Dollhouse, Under-Bed) each wait for the boss before them (a requires_flag key and the door's own locked_message on their exits lines), with four new entries for the shortcuts home (lines 48 -> 52: the exits count and the four new door cells; the board gains four X marks)"},
}

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


func _compare_actor(actor_id: String, recorded_lines: PackedStringArray, current_lines: PackedStringArray) -> void:
	var golden_lines := _without_geometry(recorded_lines)
	var new_lines := _without_geometry(current_lines)
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


## The lines with the in-cell geometry taken out: for a node in GEOMETRY_NODE_PATHS, its position,
## scale and centring. Both the recorded and the current lines go through this, so what is left is
## compared exactly.
func _without_geometry(lines: PackedStringArray) -> PackedStringArray:
	var kept := PackedStringArray()
	for line in lines:
		var parts := line.split(" ")
		if parts.size() > 2 and parts[0] == "node" and parts[1] in GEOMETRY_NODE_PATHS:
			var remaining: Array[String] = []
			for part in parts:
				var token_name := part.get_slice("=", 0)
				if not (part.contains("=") and token_name in GEOMETRY_TOKENS):
					remaining.append(part)
			kept.append(" ".join(remaining))
		else:
			kept.append(line)
	return kept


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
		var allowed_now: String = ROOM_HEADS_CHANGED_ON_PURPOSE.get(room_id, {}).get("line", "")
		var equals_recorded: bool = recorded_by_room.get(room_id, "") == current_line
		_expect(equals_recorded or (not allowed_now.is_empty() and allowed_now == current_line),
			"room %s: the grid, the board and every entity (cells and component fields) at boot and after 120 ticks equal the pre-collapse dump" % room_id)
	for room_id: String in ROOM_HEADS_CHANGED_ON_PURPOSE:
		_expect(room_id in WorldDumper.BASELINE_ROOM_IDS and not String(ROOM_HEADS_CHANGED_ON_PURPOSE[room_id]["why"]).is_empty(), "the room head change listed for %s names a baseline room and says why" % room_id)
