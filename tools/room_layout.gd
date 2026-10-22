extends RefCounted

## Reads a room layout file (tools/layouts/<room_id>.txt) and says what is wrong with it (a helper, not a command;
## no class_name, preload it: `const RoomLayout := preload("res://tools/room_layout.gd")`). The builder
## (tools/build_room.gd, tools/room_scene_writer.gd) and the tests read layouts through this one class, so a
## layout means the same thing to all of them. It touches no scene and writes nothing; it only loads ContentDb
## to know which enemy and pickup ids exist.
##
## THE FORMAT. Three sections, in any order, each opened by a line of its own:
##
##   [room]      key = value lines: what the room is (the meta of its RoomEncounter) and its English words
##   [grid]      the board: one line per row, one character per cell, exactly `size` wide
##   [objects]   one line per object character: <char> = <kind> key=value ... flag ...
##
## A line that starts with `;` is a comment (in [room] and [objects] only: a [grid] line is the board). Blank lines
## are ignored. Values are plain text to the end of the line; wrap one in "double quotes" to keep its edges.
##
## [room] KEYS
##   id                   the room id: lowercase snake_case, EQUAL to the file name (tb1_toybox_gate.txt) [required]
##   size                 WxH in cells, 8..18 by 7..9: 16x9 by default, 18x9 for an arena [default 16x9]
##   act                  1..6, 7 for the Ending [required]
##   district             one of WorldGraph.DISTRICT_IDS [required]
##   archetype            the layout family: winding, yard, fence, arena, hub... lowercase snake_case [required]
##   recipe               rest teach test twist boss shortcut optional ending dev [required]
##   status               stub greybox dressed final [default stub]
##   time_of_night        dusk evening night small_hours dawn morning [default dusk]
##   checkpoint_on_entry  true or false: coming in through a door is a checkpoint (D-16) [default false]
##   objective            clear reach survive waves none: what the room asks of the pawn (7.4 Obj). Inert until M9 [default clear]
##   threat               0..12 points of threat live at once: the biggest wave in a gauntlet, a boss's phase-1 budget [default 0]
##   shapes               0..6 different threat shapes live at once (R28) [default 0]
##   intro                true or false: a first lesson of one piece (T3), exempt from the Test floor of the threat budget [default false]
##   intensity            0..10, the Int column of 7.4 (R32) [default 0]
##   tileset              the id of a content/tilesets/ kit [default greybox]
##   name                 the English words of ROOM_<ID>_NAME (the title card, the pause menu) [required]
##   start                the English words of ROOM_<ID>_START (the status line on arrival) [required]
##
## [grid] TERRAIN CHARACTERS (each is a kind of cell, CellKinds):
##   .  floor              #  wall                 o  gap (a hole in the floor)
##   +  leapable block     =  chalk (over a gap)   ~  corruption
## The ring of cells around the board must be walls: a door on the ring cannot be walked to.
##
## [grid] OBJECT CHARACTERS: a capital letter A-Z or a digit 0-9, defined in [objects]. The cell under an object is
## floor, except under a `traversal` (a gap). In [objects] each character is defined once:
##
##   A = entry id=<entry_id>                       where the pawn arrives (ZoneEntryMarker). At least one per room.
##   B = exit to=<room_id>:<entry_id> [clear] [needs_flag=<flag>] [locked="<English>"] [locked_key=<KEY>] [name=<Node>]
##                                                 a door (ZoneExitMarker). `clear` shuts it until the room is
##                                                 cleared; `needs_flag` shuts it until that world flag is set (a
##                                                 boss fallen: boss.knight_captain); `locked` is the English words
##                                                 of its line ROOM_<ID>_LOCKED (or `locked_key` for a second shut
##                                                 door). A shut door must say why; `clear` and `needs_flag` do not
##                                                 combine.
##   C = enemy def=<enemy_id> [name=<Node>]        a parked enemy (ActorView + the definition). May repeat.
##   D = pickup weapon=<pickup_id> [persistent] [name=<Node>]
##                                                 a floor weapon (PickupSpawnPoint); `persistent` = taken once
##                                                 for the whole run (a reward). A non-persistent one may repeat.
##   E = unlock id=<unlock_id> [text="<English>"] [name=<Node>]
##                                                 stepping here gains the verb (PlayerUnlockMarker); `text` is
##                                                 the English words of ROOM_<ID>_UNLOCK_<ID> (the status line)
##   F = gate id=<gate_id> [opens=left|right|up|down] [name=<Node>]
##                                                 a one-way shortcut gate (GateMarker); `opens` is the direction
##                                                 the pawn pushes to open it from the far side [default left]
##   G = traversal verb=chalk_path|rule_step [costly] [name=<Node>]
##                                                 a cell of a mandatory crossing (TraversalGapMarker) over a gap.
##                                                 Neighbouring cells of one character in a straight line (1 to 3)
##                                                 are ONE crossing. `costly` = the cast costs Believe even when calm.
##   H = variant id=<variant_id> [requires=a.b,c] [forbids=d] [name=<Node>]
##                                                 a prop that shows only in a state (StateVariantMarker)
##   Z = ending_exit [name=<Node>]                 the door that ENDS THE RUN (ZoneExitMarker.ends_run): it leads
##                                                 nowhere, stepping on it shows the ending cards and the credits.
##                                                 Only the Ending's room (e1) has one.
## The checkpoint flag is a room key, not a cell: `checkpoint_on_entry = true`.
##
## The legend above is what `tools/build_room.gd --legend` prints. A problem is a sentence; `problems` is empty
## when the layout can be built.

const SECTION_ROOM := "room"
const SECTION_GRID := "grid"
const SECTION_OBJECTS := "objects"
const DEFAULT_SIZE := Vector2i(16, 9)
const SMALLEST_SIZE := Vector2i(8, 7)
const LARGEST_SIZE := Vector2i(18, 9)

## The terrain characters of the grid: character -> cell kind (CellKinds).
const TERRAIN_KIND_BY_CHARACTER := {
	".": CellKinds.FLOOR,
	"#": CellKinds.WALL,
	"o": CellKinds.GAP,
	"+": CellKinds.LEAPABLE_BLOCK,
	"=": CellKinds.CHALK,
	"~": CellKinds.CORRUPTION,
}
const OBJECT_CHARACTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
## The kind of object -> its keys. `required`/`optional` are key=value parameters, `flags` are bare words,
## `repeatable` = the character may stand on several cells, `terrain` = the kind of the cell under it.
const OBJECT_KINDS := {
	"entry": {"required": ["id"], "optional": ["name"], "flags": [], "repeatable": false, "terrain": CellKinds.FLOOR},
	"exit": {"required": ["to"], "optional": ["name", "locked", "locked_key", "needs_flag"], "flags": ["clear"], "repeatable": false, "terrain": CellKinds.FLOOR},
	"enemy": {"required": ["def"], "optional": ["name"], "flags": [], "repeatable": true, "terrain": CellKinds.FLOOR},
	"pickup": {"required": ["weapon"], "optional": ["name"], "flags": ["persistent"], "repeatable": true, "terrain": CellKinds.FLOOR},
	"unlock": {"required": ["id"], "optional": ["name", "text"], "flags": [], "repeatable": false, "terrain": CellKinds.FLOOR},
	"gate": {"required": ["id"], "optional": ["name", "opens"], "flags": [], "repeatable": false, "terrain": CellKinds.FLOOR},
	"traversal": {"required": ["verb"], "optional": ["name"], "flags": ["costly"], "repeatable": true, "terrain": CellKinds.GAP},
	"variant": {"required": ["id"], "optional": ["name", "requires", "forbids"], "flags": [], "repeatable": false, "terrain": CellKinds.FLOOR},
	"ending_exit": {"required": [], "optional": ["name"], "flags": [], "repeatable": false, "terrain": CellKinds.FLOOR},
}
const OPENS_DIRECTIONS := {"left": Vector2i.LEFT, "right": Vector2i.RIGHT, "up": Vector2i.UP, "down": Vector2i.DOWN}
## The keys of [room] and whether each is required.
const ROOM_KEYS := {
	"id": true, "size": false, "act": true, "district": true, "archetype": true, "recipe": true, "status": false,
	"time_of_night": false, "checkpoint_on_entry": false, "tileset": false, "name": true, "start": true,
	"objective": false, "threat": false, "shapes": false, "intro": false, "intensity": false,
}

## What was read. Filled by parse().
var room_id := ""
var size := DEFAULT_SIZE
var act := 0
var district: StringName = &""
var archetype: StringName = &""
var recipe: RoomEncounter.Recipe = RoomEncounter.Recipe.REST
var status: RoomEncounter.ContentStatus = RoomEncounter.ContentStatus.STUB
var time_of_night: RoomEncounter.TimeOfNight = RoomEncounter.TimeOfNight.DUSK
var checkpoint_on_entry := false
## The encounter meta (the [room] keys objective, threat, shapes, intro and intensity).
var objective_kind: RoomEncounter.ObjectiveKind = RoomEncounter.ObjectiveKind.CLEAR
var threat_budget := 0
var threat_shapes := 0
var intro := false
var intensity := 0
var tileset_id := "greybox"
## The English words of ROOM_<ID>_NAME and ROOM_<ID>_START.
var name_text := ""
var start_text := ""
## The rows of the [grid] section, top to bottom.
var rows := PackedStringArray()
## Object character -> { "kind": String, "params": Dictionary (key -> value), "flags": Array[String], "line": int }.
var object_by_character: Dictionary = {}
## One sentence for each thing wrong with the file; empty = it can be built.
var problems := PackedStringArray()
## Where the text came from (a res:// path or a label), for the sentences.
var source_label := ""

var _seen_room_keys: Dictionary = {}


## Reads layout `text`. `expected_id` is the file name without `.txt` (the room's id must equal it); pass "" to skip.
static func parse(layout_text: String, expected_id: String, label: String = "") -> RefCounted:
	var layout: RefCounted = (load("res://tools/room_layout.gd") as GDScript).new()
	layout.source_label = label if not label.is_empty() else expected_id
	layout._read(layout_text)
	layout._check(expected_id)
	return layout


## The legend as plain text (printed by `tools/build_room.gd --legend`, and the source of the table in tools/README.md).
static func legend_text() -> String:
	var source := FileAccess.get_file_as_string("res://tools/room_layout.gd")
	var lines := PackedStringArray()
	for line in source.split("\n"):
		if line.begins_with("##"):
			lines.append(line.trim_prefix("## ").trim_prefix("##"))
		elif not lines.is_empty():
			break
	return "\n".join(lines)


## The kind of cell at `cell`: the terrain character's kind, or the terrain under the object standing there.
func kind_at(cell: Vector2i) -> StringName:
	var character := character_at(cell)
	if TERRAIN_KIND_BY_CHARACTER.has(character):
		return TERRAIN_KIND_BY_CHARACTER[character]
	if object_by_character.has(character):
		return OBJECT_KINDS[object_by_character[character]["kind"]]["terrain"]
	return CellKinds.FLOOR


## The kind the cell boots as: what kind_at() says, except that a closed gate is a wall until the pawn opens it (the
## tile under it is floor, so it is floor once opened and the save remembers it).
func booted_kind_at(cell: Vector2i) -> StringName:
	var object: Dictionary = object_by_character.get(character_at(cell), {})
	if object.get("kind", "") == "gate":
		return CellKinds.WALL
	return kind_at(cell)


func character_at(cell: Vector2i) -> String:
	if cell.y < 0 or cell.y >= rows.size() or cell.x < 0 or cell.x >= rows[cell.y].length():
		return ""
	return rows[cell.y][cell.x]


## Every cell the character stands on, row by row, left to right.
func cells_of(character: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for row_index in rows.size():
		for column_index in rows[row_index].length():
			if rows[row_index][column_index] == character:
				cells.append(Vector2i(column_index, row_index))
	return cells


## Every placement the scene gets, in the order the writer emits the nodes: entries, exits, enemies, pickups,
## unlocks, gates, traversal crossings, variants, the ending exit; within a kind by object character (A before B), then row by row. Each is
## { "kind", "name" (the node name), "cell" (the first cell), "cells" (all cells of one crossing), "params", "flags", "character" }.
## A crossing is merged from neighbouring cells of one traversal character. Valid only when `problems` is empty.
func placements() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var used_names: Dictionary = {}
	for kind: String in OBJECT_KINDS:
		for cell_character in _characters_of_kind(kind):
			var object: Dictionary = object_by_character[cell_character]
			var groups: Array = []
			if kind == "traversal":
				groups = _crossings_of(cells_of(cell_character))
			else:
				for cell in cells_of(cell_character):
					groups.append([cell])
			for group_index in groups.size():
				var cells: Array[Vector2i] = []
				cells.assign(groups[group_index])
				var node_name := _unique_node_name(kind, object, used_names)
				found.append({
					"kind": kind, "name": node_name, "cell": cells[0], "cells": cells,
					"params": object["params"], "flags": object["flags"], "character": cell_character,
				})
	return found


## The text key ROOM_<ID>_<SUFFIX>, for the room's name, start line and the like.
func text_key(suffix: String) -> String:
	return "ROOM_%s_%s" % [room_id.to_upper(), suffix]


## The key of the line of an exit that waits for a clear or a flag: its `locked_key`, else ROOM_<ID>_LOCKED.
func locked_key_of(placement: Dictionary) -> String:
	var explicit_key := String(placement["params"].get("locked_key", ""))
	return explicit_key if not explicit_key.is_empty() else text_key("LOCKED")


## The key of an unlock's line: ROOM_<ID>_UNLOCK_<ID>, or "" when the object gives no `text`.
func unlock_key_of(placement: Dictionary) -> String:
	if String(placement["params"].get("text", "")).is_empty():
		return ""
	return text_key("UNLOCK_%s" % String(placement["params"]["id"]).to_upper())


# --------------------------------------------------------------------------- reading
func _read(layout_text: String) -> void:
	var section := ""
	var line_number := 0
	for raw_line in layout_text.split("\n"):
		line_number += 1
		var line := raw_line.trim_suffix("\r")
		if section == SECTION_GRID and not line.strip_edges().is_empty() and not line.strip_edges().begins_with("["):
			rows.append(line)
			continue
		var trimmed := line.strip_edges()
		if trimmed.is_empty() or trimmed.begins_with(";"):
			continue
		if trimmed.begins_with("[") and trimmed.ends_with("]"):
			section = trimmed.substr(1, trimmed.length() - 2).strip_edges().to_lower()
			if section not in [SECTION_ROOM, SECTION_GRID, SECTION_OBJECTS]:
				_problem(line_number, "the section [%s] does not exist (the sections are [room], [grid], [objects])." % section)
			continue
		match section:
			SECTION_ROOM:
				_read_room_line(trimmed, line_number)
			SECTION_OBJECTS:
				_read_object_line(trimmed, line_number)
			_:
				_problem(line_number, "this line is outside any section: start with [room], [grid] or [objects].")


func _read_room_line(trimmed: String, line_number: int) -> void:
	if not trimmed.contains("="):
		_problem(line_number, "a [room] line reads `key = value`: '%s'." % trimmed)
		return
	var key := trimmed.get_slice("=", 0).strip_edges()
	var value := _unquote(trimmed.substr(trimmed.find("=") + 1).strip_edges())
	if not ROOM_KEYS.has(key):
		_problem(line_number, "[room] has no key '%s' (the keys are %s)." % [key, ", ".join(PackedStringArray(ROOM_KEYS.keys()))])
		return
	if _seen_room_keys.has(key):
		_problem(line_number, "[room] sets '%s' twice." % key)
	_seen_room_keys[key] = true
	match key:
		"id":
			room_id = value
		"size":
			var parts := value.to_lower().split("x")
			if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
				_problem(line_number, "size reads WxH, for example 16x9 (it is '%s')." % value)
			else:
				size = Vector2i(int(parts[0]), int(parts[1]))
		"act":
			if not value.is_valid_int():
				_problem(line_number, "act is a number, 1 to 7 (it is '%s')." % value)
			else:
				act = int(value)
		"district":
			district = StringName(value)
		"archetype":
			archetype = StringName(value)
		"recipe":
			recipe = _enum_value(RoomEncounter.Recipe, value, "recipe", line_number, recipe)
		"status":
			status = _enum_value(RoomEncounter.ContentStatus, value, "status", line_number, status)
		"time_of_night":
			time_of_night = _enum_value(RoomEncounter.TimeOfNight, value, "time_of_night", line_number, time_of_night)
		"checkpoint_on_entry":
			if value not in ["true", "false"]:
				_problem(line_number, "checkpoint_on_entry is true or false (it is '%s')." % value)
			else:
				checkpoint_on_entry = value == "true"
		"objective":
			objective_kind = _enum_value(RoomEncounter.ObjectiveKind, value, "objective", line_number, objective_kind)
		"threat":
			threat_budget = _whole_number_value(value, "threat", line_number, threat_budget)
		"shapes":
			threat_shapes = _whole_number_value(value, "shapes", line_number, threat_shapes)
		"intensity":
			intensity = _whole_number_value(value, "intensity", line_number, intensity)
		"intro":
			if value not in ["true", "false"]:
				_problem(line_number, "intro is true or false (it is '%s')." % value)
			else:
				intro = value == "true"
		"tileset":
			tileset_id = value
		"name":
			name_text = value
		"start":
			start_text = value


func _whole_number_value(value: String, key: String, line_number: int, fallback: int) -> int:
	if not value.is_valid_int():
		_problem(line_number, "%s is a whole number (it is '%s')." % [key, value])
		return fallback
	return int(value)


func _enum_value(enum_dictionary: Dictionary, value: String, key: String, line_number: int, fallback: int) -> int:
	var wanted := value.to_upper()
	if enum_dictionary.has(wanted):
		return enum_dictionary[wanted]
	_problem(line_number, "%s '%s' is not one of: %s." % [key, value, ", ".join(PackedStringArray(enum_dictionary.keys().map(func(entry: String) -> String: return entry.to_lower())))])
	return fallback


func _read_object_line(trimmed: String, line_number: int) -> void:
	if not trimmed.contains("="):
		_problem(line_number, "an [objects] line reads `<char> = <kind> key=value ...`: '%s'." % trimmed)
		return
	var character := trimmed.get_slice("=", 0).strip_edges()
	var rest := trimmed.substr(trimmed.find("=") + 1).strip_edges()
	if character.length() != 1 or OBJECT_CHARACTERS.find(character) < 0:
		_problem(line_number, "'%s' cannot stand for an object: use a capital letter or a digit (terrain characters are fixed: %s)." % [character, "".join(PackedStringArray(TERRAIN_KIND_BY_CHARACTER.keys()))])
		return
	if object_by_character.has(character):
		_problem(line_number, "'%s' is defined twice." % character)
		return
	var tokens := _tokens_of(rest)
	if tokens.is_empty():
		_problem(line_number, "'%s' names no kind of object (the kinds are %s)." % [character, ", ".join(PackedStringArray(OBJECT_KINDS.keys()))])
		return
	var kind: String = tokens[0]["word"]
	if not OBJECT_KINDS.has(kind):
		_problem(line_number, "'%s' is not a kind of object (the kinds are %s)." % [kind, ", ".join(PackedStringArray(OBJECT_KINDS.keys()))])
		return
	var spec: Dictionary = OBJECT_KINDS[kind]
	var params: Dictionary = {}
	var flags: Array[String] = []
	for token_index in range(1, tokens.size()):
		var token: Dictionary = tokens[token_index]
		var word: String = token["word"]
		if token["has_value"]:
			if word not in spec["required"] and word not in spec["optional"]:
				_problem(line_number, "an object of kind %s has no parameter '%s'." % [kind, word])
			params[word] = token["value"]
		else:
			if word not in spec["flags"]:
				_problem(line_number, "an object of kind %s has no flag '%s'." % [kind, word])
			flags.append(word)
	for required_key: String in spec["required"]:
		if not params.has(required_key) or String(params[required_key]).is_empty():
			_problem(line_number, "an object of kind %s needs %s=..." % [kind, required_key])
	object_by_character[character] = {"kind": kind, "params": params, "flags": flags, "line": line_number}


## Splits an [objects] line into words, `key=value` pairs and "quoted values". Returns
## [{ "word": String, "has_value": bool, "value": String }].
func _tokens_of(text: String) -> Array[Dictionary]:
	var tokens: Array[Dictionary] = []
	var current := ""
	var in_quotes := false
	for character in text + " ":
		if character == "\"":
			in_quotes = not in_quotes
			continue
		if character == " " and not in_quotes:
			if not current.is_empty():
				var equals_at := current.find("=")
				if equals_at > 0:
					tokens.append({"word": current.substr(0, equals_at), "has_value": true, "value": current.substr(equals_at + 1)})
				else:
					tokens.append({"word": current, "has_value": false, "value": ""})
				current = ""
			continue
		current += character
	return tokens


func _unquote(value: String) -> String:
	if value.length() >= 2 and value.begins_with("\"") and value.ends_with("\""):
		return value.substr(1, value.length() - 2)
	return value


func _problem(line_number: int, sentence: String) -> void:
	problems.append("%s:%d: %s" % [source_label, line_number, sentence])


func _whole_file_problem(sentence: String) -> void:
	problems.append("%s: %s" % [source_label, sentence])


# --------------------------------------------------------------------------- checking
func _check(expected_id: String) -> void:
	for key: String in ROOM_KEYS:
		if ROOM_KEYS[key] and not _seen_room_keys.has(key):
			_whole_file_problem("[room] needs `%s = ...`." % key)
	var id_pattern := RegEx.create_from_string("^[a-z][a-z0-9_]*$")
	if _seen_room_keys.has("id"):
		if id_pattern.search(room_id) == null:
			_whole_file_problem("the id '%s' must be lowercase snake_case." % room_id)
		if not expected_id.is_empty() and room_id != expected_id:
			_whole_file_problem("the id is '%s' but the file is called %s.txt: they must be equal." % [room_id, expected_id])
	if size.x < SMALLEST_SIZE.x or size.y < SMALLEST_SIZE.y or size.x > LARGEST_SIZE.x or size.y > LARGEST_SIZE.y:
		_whole_file_problem("size %dx%d must be between %dx%d and %dx%d (16x9 by default, arenas up to 18x9)." % [size.x, size.y, SMALLEST_SIZE.x, SMALLEST_SIZE.y, LARGEST_SIZE.x, LARGEST_SIZE.y])
	if _seen_room_keys.has("act") and (act < 1 or act > RoomEncounter.LAST_ACT):
		_whole_file_problem("act %d is not an act: use 1 to 6, 7 for the Ending." % act)
	if _seen_room_keys.has("district") and district not in WorldGraph.DISTRICT_IDS:
		_whole_file_problem("district '%s' is not a district (use one of: %s)." % [district, WorldGraph.district_ids_text()])
	if _seen_room_keys.has("archetype") and id_pattern.search(String(archetype)) == null:
		_whole_file_problem("archetype '%s' must be lowercase snake_case." % archetype)
	if not ContentDb.has_id(&"tilesets", StringName(tileset_id)):
		_whole_file_problem("tileset '%s' is not a kit under content/tilesets/ (kits: %s)." % [tileset_id, ", ".join(PackedStringArray(ContentDb.ids(&"tilesets")))])
	for sentence in RoomEncounter.threat_problems(recipe, act, threat_budget, threat_shapes, intro):
		_whole_file_problem(sentence)
	if intensity < 0 or intensity > RoomEncounter.LARGEST_INTENSITY:
		_whole_file_problem("intensity %d must be between 0 and %d." % [intensity, RoomEncounter.LARGEST_INTENSITY])
	if recipe == RoomEncounter.Recipe.BOSS and not checkpoint_on_entry:
		_whole_file_problem("a boss room is a checkpoint (D-16): set `checkpoint_on_entry = true`.")
	if archetype == &"hub" and not checkpoint_on_entry:
		_whole_file_problem("a hub is a checkpoint (D-16): set `checkpoint_on_entry = true`.")

	_check_grid()
	_check_objects()


func _check_grid() -> void:
	if rows.size() != size.y:
		_whole_file_problem("[grid] has %d rows but size is %dx%d." % [rows.size(), size.x, size.y])
		return
	for row_index in rows.size():
		if rows[row_index].length() != size.x:
			_whole_file_problem("[grid] row %d is %d characters wide, size is %d." % [row_index, rows[row_index].length(), size.x])
			return
	var seen_object_characters: Dictionary = {}
	for row_index in rows.size():
		for column_index in rows[row_index].length():
			var character: String = rows[row_index][column_index]
			var cell := Vector2i(column_index, row_index)
			var on_ring := row_index == 0 or row_index == rows.size() - 1 or column_index == 0 or column_index == rows[row_index].length() - 1
			if TERRAIN_KIND_BY_CHARACTER.has(character):
				if on_ring and character != "#":
					_whole_file_problem("cell %s is '%s' but the ring of the board must be wall (#): a door or a piece on the ring cannot be walked to." % [cell, character])
				continue
			if not object_by_character.has(character):
				_whole_file_problem("cell %s holds '%s', which is neither a terrain character nor defined in [objects]." % [cell, character])
				continue
			seen_object_characters[character] = true
			if on_ring:
				_whole_file_problem("the object '%s' stands on the ring at %s: the ring of the board must be wall (#)." % [character, cell])
	for character: String in object_by_character:
		if not seen_object_characters.has(character):
			_whole_file_problem("'%s' is defined in [objects] (line %d) but stands nowhere in the grid." % [character, object_by_character[character]["line"]])


func _check_objects() -> void:
	var entry_ids: Dictionary = {}
	var shut_exit_count := 0
	for character: String in object_by_character:
		var object: Dictionary = object_by_character[character]
		var kind: String = object["kind"]
		var params: Dictionary = object["params"]
		var cells := cells_of(character)
		var label := "'%s' (%s, line %d)" % [character, kind, object["line"]]
		if cells.size() > 1 and not OBJECT_KINDS[kind]["repeatable"]:
			_whole_file_problem("%s stands on %d cells, but an object of kind %s may stand on one only." % [label, cells.size(), kind])
		if cells.size() > 1 and kind == "pickup" and object["flags"].has("persistent"):
			_whole_file_problem("%s is a persistent pickup on %d cells: the save keys it by its node name, so it must stand once." % [label, cells.size()])
		match kind:
			"entry":
				var entry_id := String(params.get("id", ""))
				if entry_ids.has(entry_id):
					_whole_file_problem("%s repeats the entry id '%s'." % [label, entry_id])
				entry_ids[entry_id] = true
			"exit":
				var target := String(params.get("to", ""))
				var target_parts := target.split(":")
				if target_parts.size() != 2 or target_parts[0].is_empty() or target_parts[1].is_empty():
					_whole_file_problem("%s: to=%s must read <room_id>:<entry_id>." % [label, target])
				elif target_parts[0] == room_id:
					_whole_file_problem("%s leads to its own room." % label)
				var waits_for_flag := params.has("needs_flag")
				if waits_for_flag:
					if not FlagId.is_valid(StringName(String(params["needs_flag"]))):
						_whole_file_problem("%s: needs_flag=%s is not a flag id (boss.knight_captain)." % [label, params["needs_flag"]])
					if object["flags"].has("clear"):
						_whole_file_problem("%s waits for a clear AND a flag: a door has one lock, give it `clear` or needs_flag=..., not both." % label)
				if object["flags"].has("clear") or waits_for_flag:
					shut_exit_count += 1
					if String(params.get("locked", "")).is_empty() and String(params.get("locked_key", "")).is_empty():
						_whole_file_problem("%s waits for a %s but gives no reason: add locked=\"...\" (the English words) or locked_key=KEY." % [label, "flag" if waits_for_flag else "clear"])
				elif params.has("locked") or params.has("locked_key"):
					_whole_file_problem("%s has a locked line but is not shut: only a door that waits for a clear (`clear`) or a flag (needs_flag=...) can say why it is shut." % label)
			"enemy":
				if not ContentDb.has_id(&"enemies", StringName(String(params.get("def", "")))):
					_whole_file_problem("%s: def=%s is not an enemy (content/enemies/ has: %s)." % [label, params.get("def", ""), ", ".join(PackedStringArray(ContentDb.ids(&"enemies")))])
			"pickup":
				if not ContentDb.has_id(&"pickups", StringName(String(params.get("weapon", "")))):
					_whole_file_problem("%s: weapon=%s is not a pickup (content/pickups/ has: %s)." % [label, params.get("weapon", ""), ", ".join(PackedStringArray(ContentDb.ids(&"pickups")))])
			"unlock":
				if RegEx.create_from_string("^[a-z][a-z0-9_]*$").search(String(params.get("id", ""))) == null:
					_whole_file_problem("%s: id=%s must be lowercase snake_case." % [label, params.get("id", "")])
			"gate":
				if params.has("opens") and not OPENS_DIRECTIONS.has(String(params["opens"])):
					_whole_file_problem("%s: opens=%s is not one of: left, right, up, down." % [label, params["opens"]])
			"traversal":
				if StringName(String(params.get("verb", ""))) not in TraversalGapMarker.VERBS:
					_whole_file_problem("%s: verb=%s does not cross a gap (use chalk_path or rule_step)." % [label, params.get("verb", "")])
				for crossing in _crossings_of(cells):
					if crossing.size() > TraversalGapMarker.MAX_LENGTH:
						_whole_file_problem("%s covers %d neighbouring cells in a line at %s: a crossing is at most %d." % [label, crossing.size(), crossing[0], TraversalGapMarker.MAX_LENGTH])
					if StringName(String(params.get("verb", ""))) == &"rule_step" and crossing.size() > 1:
						_whole_file_problem("%s is a Rule Step crossing %d cells wide: a Rule Step clears a one-cell hole." % [label, crossing.size()])
			"variant":
				for key in ["requires", "forbids"]:
					for flag_text in String(params.get(key, "")).split(",", false):
						if not FlagId.is_valid(StringName(flag_text.strip_edges())):
							_whole_file_problem("%s: %s holds '%s', which is not a flag id (boss.knight_captain)." % [label, key, flag_text])
				if String(params.get("requires", "")).is_empty() and String(params.get("forbids", "")).is_empty():
					_whole_file_problem("%s has no condition: give requires=... or forbids=..." % label)
	if not _has_kind("entry"):
		_whole_file_problem("the room has no entry: add an `entry` object, or the pawn can never arrive in it.")
	if recipe != RoomEncounter.Recipe.ENDING and _has_kind("ending_exit"):
		_whole_file_problem("only a room whose recipe is `ending` may hold the door that ends the run (an `ending_exit` object).")
	if shut_exit_count > 1:
		var keys: Dictionary = {}
		for character: String in object_by_character:
			var object: Dictionary = object_by_character[character]
			if object["kind"] == "exit" and (object["flags"].has("clear") or object["params"].has("needs_flag")):
				var key := String(object["params"].get("locked_key", text_key("LOCKED")))
				if keys.has(key):
					_whole_file_problem("two doors that wait for a clear both use the line %s: give the second its own locked_key=KEY." % key)
				keys[key] = true
	if problems.is_empty():
		_check_reachability()
		_check_node_names()


## Every door, floor pickup and unlock cell is reachable on foot from every entry (a crossing counts as walkable: the
## verb that crosses it is the player's, and the room is built so it is the only way). An enemy is left out on
## purpose: a Knight or a Bishop previewed from behind a fence is meant to be out of the pawn's reach.
func _check_reachability() -> void:
	var reachable_from_each_entry: Array[Dictionary] = []
	for placement in placements():
		if placement["kind"] != "entry":
			continue
		var reached: Dictionary = {}
		var frontier: Array[Vector2i] = [placement["cell"]]
		reached[placement["cell"]] = true
		while not frontier.is_empty():
			var cell: Vector2i = frontier.pop_back()
			for step in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var next_cell: Vector2i = cell + step
				if reached.has(next_cell) or character_at(next_cell).is_empty():
					continue
				var next_object: Dictionary = object_by_character.get(character_at(next_cell), {})
				var is_crossing: bool = next_object.get("kind", "") == "traversal"
				if CellKinds.is_walkable(kind_at(next_cell)) or is_crossing:
					reached[next_cell] = true
					frontier.append(next_cell)
		reachable_from_each_entry.append({"entry": placement["name"], "reached": reached})
	for placement in placements():
		if placement["kind"] not in ["exit", "pickup", "unlock", "ending_exit"]:
			continue
		for reach in reachable_from_each_entry:
			if not (reach["reached"] as Dictionary).has(placement["cell"]):
				_whole_file_problem("the %s %s at %s cannot be reached on foot from the entry %s (walls, gaps or blocks cut it off)." % [placement["kind"], placement["name"], placement["cell"], reach["entry"]])


## A `name=` the layout gives is the node's name, so two objects may not give the same one (a name the tool derives is
## numbered when it repeats, which is how three PawnRecruits become PawnRecruit, PawnRecruit_2 and PawnRecruit_3).
func _check_node_names() -> void:
	var seen: Dictionary = {"RoomArt": true}
	for character: String in OBJECT_CHARACTERS:
		if not object_by_character.has(character):
			continue
		var given_name := String(object_by_character[character]["params"].get("name", ""))
		if given_name.is_empty():
			continue
		if seen.has(given_name):
			_whole_file_problem("two objects would be called %s: give one of them another name=..." % given_name)
		seen[given_name] = true


# --------------------------------------------------------------------------- helpers
## True when an object of this kind stands on at least one cell of the grid.
func _has_kind(kind: String) -> bool:
	for character: String in object_by_character:
		if object_by_character[character]["kind"] == kind and not cells_of(character).is_empty():
			return true
	return false


func _characters_of_kind(kind: String) -> Array[String]:
	var characters: Array[String] = []
	for character: String in OBJECT_CHARACTERS:
		if object_by_character.has(character) and object_by_character[character]["kind"] == kind:
			characters.append(character)
	return characters


## Groups cells into straight crossings: neighbouring cells in one row (left to right) or one column (top to bottom).
func _crossings_of(cells: Array[Vector2i]) -> Array:
	var remaining: Array[Vector2i] = cells.duplicate()
	var groups: Array = []
	while not remaining.is_empty():
		var first: Vector2i = remaining[0]
		var run: Array[Vector2i] = [first]
		for direction in [Vector2i.RIGHT, Vector2i.DOWN]:
			var candidate: Vector2i = first + direction
			var line: Array[Vector2i] = [first]
			while candidate in remaining:
				line.append(candidate)
				candidate += direction
			if line.size() > run.size():
				run = line
		for cell in run:
			remaining.erase(cell)
		groups.append(run)
	return groups


## The node name of a placement: the `name=` given, else one derived from the object (Entry_From_T4, Exit_To_T3,
## PawnRecruit, PencilSpearPickup...), numbered when the same name is taken.
func _unique_node_name(kind: String, object: Dictionary, used_names: Dictionary) -> String:
	var params: Dictionary = object["params"]
	var base := String(params.get("name", ""))
	if base.is_empty():
		match kind:
			"entry":
				base = "Entry_" + _pascal_case(String(params["id"]).trim_suffix("_entry"), "_")
			"exit":
				base = "Exit_To_" + _pascal_case(String(params["to"]).get_slice(":", 0).get_slice("_", 0), "_")
			"enemy":
				base = _pascal_case(String(params["def"]), "")
			"pickup":
				base = _pascal_case(String(params["weapon"]), "") + "Pickup"
			"unlock":
				base = _pascal_case(String(params["id"]), "") + "Unlock"
			"gate":
				base = "Gate_" + _pascal_case(String(params["id"]), "")
			"traversal":
				base = "TraversalGap"
			"variant":
				base = "Variant_" + _pascal_case(String(params["id"]), "")
			"ending_exit":
				base = "Exit_Beyond_Board"
	var candidate := base
	var number := 2
	while used_names.has(candidate):
		candidate = "%s_%d" % [base, number]
		number += 1
	used_names[candidate] = true
	return candidate


## snake_case to PascalCase; a short code such as t4 or tb1 becomes capitals (T4, TB1). `joiner` goes between words.
func _pascal_case(snake: String, joiner: String) -> String:
	var words := PackedStringArray()
	for word in snake.split("_", false):
		if RegEx.create_from_string("^[a-z]+[0-9]+$").search(word) != null:
			words.append(word.to_upper())
		else:
			words.append(word.capitalize())
	return joiner.join(words)
