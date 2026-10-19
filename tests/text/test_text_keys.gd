extends UnboundTest

## No player-facing literal is left in a shipped script, scene or resource, and every key they name exists
## (docs/game-base-plan.md 8.9, 15 M4; R29, req #197). A word the player reads lives in a `.po` row and is named by a KEY
## (UI_PAUSE_RESUME); scenes, resources and scripts hold the key. Two halves:
##
## 1. USED KEYS EXIST. Every string in a shipped file that is shaped like a key (UPPER_SNAKE with a prefix of
##    TextService.PREFIXES_BY_DOMAIN) is a row of the English files. Keys built in code ("ROOM_%s_NAME") are checked
##    for the cases that exist (every room has a name row, every language has a name row).
##
## 2. NO LITERAL IS LEFT. How a literal is recognised, because a lint like this is only as good as its definition:
##    - Files looked at: every .gd, .tscn and .tres of the project except tests/, tools/, docs/ and the
##      gitignored assets/_generated/ (tests and tools are not shipped and may write words freely).
##    - In a SCENE or RESOURCE, a property line `name = "value"` (a value may continue over several lines; a
##      PackedStringArray holds several). A value counts as player-facing text when it is PROSE (two or more words:
##      letters, a space, letters) or when its property is one of TEXT_PROPERTIES (text, title, display_name,
##      heading, message...) whatever it says. A value that is a key, or empty, is fine. Names, paths, ids and
##      resource references never look like prose, and `[node name="..."]` header lines are not properties.
##    - In a SCRIPT, a string literal in code (comments, docstrings, &"StringName"s, ^"NodePath"s and preload paths
##      are not code text) counts the same way: PROSE anywhere, or ANY non-key text on a line that feeds a text
##      sink (`.text =`, `.tooltip_text`, `.add_item(`, `.say(`, `.set_status(`, `.show_result(`, `.ask(`).
##      A single lower_snake word on a text-sink line is a dictionary key or a method name (`{"known": 2}`,
##      `"get_start_message"`), not words, and is let through.
##    - Allowed without a note, because they are developer text and not game text: strings inside a function
##      called validate*, *problems* or *warnings* or _get_configuration_warnings (editor and test lint sentences),
##      on a line that calls push_error, push_warning, print, printerr, assert or _reject (a dropped request says
##      why), on a line that names a problem or warnings list, and the labels of an Inspector group
##      (@export_group, @export_subgroup, @export_category).
##    - Everything else that is allowed is in ALLOWED_LITERALS, one entry each with the reason: a whole file, or a
##      piece of one literal, or a property. The list is exact, like the dependency guard's: an entry that no longer
##      matches anything fails the suite, so it is deleted when its text is gone and cannot become a hiding place.
## The detector is run on samples below, so it is shown to be able to fail.

const ProjectFiles := preload("res://tests/architecture/project_files.gd")
const PoReader := preload("res://tests/support/po_file_reader.gd")

const KEY_PATTERN := "^[A-Z][A-Z0-9]*(_[A-Z0-9]+)+$"
const SKIPPED_PREFIXES: Array[String] = ["res://tests/", "res://tools/", "res://docs/", "res://assets/_generated/"]
## Fewer files than this means the walk is broken, not clean.
const MINIMUM_SCRIPTS := 60
const MINIMUM_SCENES_AND_RESOURCES := 40
const MINIMUM_KEYS_USED := 60

## Properties that hold words for the player. A value in one of them must be a key (or empty).
const TEXT_PROPERTIES: Array[String] = [
	"text", "title", "tooltip_text", "placeholder_text", "display_name", "piece_name", "heading", "lines", "game_title",
	"closing_line", "message", "locked_message", "room_message", "start_message", "clear_message", "clear_subtitle",
	"defeat_message", "defeat_subtitle", "original_rule", "amendment", "flavor", "description", "label",
]
## A script line that feeds one of these shows its literal to the player, so even a single word is a violation.
const TEXT_SINK_PATTERN := "\\.text\\s*\\+?=|tooltip_text|placeholder_text|\\.add_item\\(|\\.say\\(|\\.set_status\\(|\\.show_result\\(|\\.ask\\("
## A line that matches writes developer text: a log, a failed assertion, the reason a request was dropped, an
## entry of a list of problems or warnings, the label of an Inspector group.
const DEVELOPER_LINE_PATTERN := "(?<![A-Za-z0-9_])(?:push_error|push_warning|print|printerr|print_rich|assert|_reject)\\(|[A-Za-z_]*(?:problems?|warnings)\\b|^\\s*@export_(?:sub)?(?:group|category)\\("
## A function whose name starts or contains one of these holds developer sentences (a lint of the data, an editor
## warning).
const DEVELOPER_FUNCTION_PREFIXES: Array[String] = ["validate", "_validate", "_get_configuration_warnings"]
const DEVELOPER_FUNCTION_PARTS: Array[String] = ["problems", "warnings"]

## Every literal that stays, with the reason it is not game text. Each entry: "path", "why", and how much of the file
## it covers: "property" (a property of a scene or resource), "contains" (a piece of one literal), or neither (the
## whole file).
const ALLOWED_LITERALS: Array[Dictionary] = [
	{"path": "res://ecs/events/events.gd", "why": "the event table: every sentence documents a payload key or says what an event is, for the developer; no event carries a sentence to the player (the lines the player reads travel as text keys)"},
	{"path": "res://ecs/events/commands.gd", "why": "the command table: documentation of payload keys and the sentences of a request that is refused, for the developer and the log"},
	{"path": "res://ecs/core/cell_kinds.gd", "why": "the `about` note of each kind of cell in the rules table: developer documentation, never drawn"},
	{"path": "res://ecs/systems/command/command_system.gd", "why": "the reasons a request is refused: returned to the request_dropped event, for the developer and the log"},
	{"path": "res://ecs/systems/view/view_sync_system.gd", "contains": "has no state", "why": "the reason a view command is refused (an animation state the graph lacks): for the request_dropped event, the developer and the log"},
	{"path": "res://shell/save/save_file.gd", "why": "the reasons a save file is rejected, read by the loader's report and the log; the player's notice is a text key (TitleSummary)"},
	{"path": "res://shell/save/save_service.gd", "why": "the log and report lines of the save service; the player's notice is a text key (TitleSummary)"},
	{"path": "res://authoring/markers/blocker_marker.tscn", "property": "text", "why": "the label the editor draws on a blocker; the marker hides it at run time (BlockerMarker._sync_editor_label)"},
	{"path": "res://content/story/credits_licenses.tres", "property": "lines", "why": "the licence texts: legal text, generated from THIRD_PARTY_NOTICES.md, drawn as fine print and shown as written in every language"},
]

var key_regex := RegEx.create_from_string(KEY_PATTERN)
var prose_regex := RegEx.create_from_string("[A-Za-z]{2,}[ ]+[A-Za-z]{2,}")
var sink_regex := RegEx.create_from_string(TEXT_SINK_PATTERN)
var developer_line_regex := RegEx.create_from_string(DEVELOPER_LINE_PATTERN)
var identifier_regex := RegEx.create_from_string("^[a-z][a-z0-9_]*$")
var string_regex := RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\[\\s\\S])*)\"")
var reference_regex := RegEx.create_from_string("(?:ExtResource|SubResource|NodePath|Object|Resource)\\(\\s*\"[^\"]*\"[^)]*\\)|&\"[^\"]*\"|\\^\"[^\"]*\"|(?:preload|load)\\(\\s*\"[^\"]*\"\\s*\\)")

var source_keys: Dictionary = {}
var keys_used: Dictionary = {}
var violations: Array[String] = []
var allowance_used: Dictionary = {}


func _init() -> void:
	suite_title = "TEXT KEYS TEST"
	_the_detector_can_tell()
	source_keys = _source_keys()
	_expect(source_keys.size() >= MINIMUM_KEYS_USED, "the English files have %d rows (at least %d)" % [source_keys.size(), MINIMUM_KEYS_USED])
	_scan_the_project()
	_keys_built_in_code_exist()
	_every_used_key_exists()
	_no_literal_is_left()
	_the_allowances_are_all_needed()
	finish()


# --------------------------------------------------------------------------- the files

func _source_keys() -> Dictionary:
	var rows := {}
	for domain: StringName in TextService.PREFIXES_BY_DOMAIN:
		var path := "%s/%s/%s.po" % [TextService.TEXT_FOLDER, TextService.SOURCE_LANGUAGE, domain]
		for entry in PoReader.parse(FileAccess.get_file_as_string(path))["entries"]:
			rows[String(entry["key"])] = String(entry["text"])
	return rows


func _scan_the_project() -> void:
	var script_count := 0
	var scene_count := 0
	for path in ProjectFiles.collect_files(["gd", "tscn", "tres"]):
		if _is_skipped(path):
			continue
		var file_text := ProjectFiles.read_text(path)
		if path.ends_with(".gd"):
			script_count += 1
			_scan_script(path, file_text)
		else:
			scene_count += 1
			_scan_resource(path, file_text)
	_expect(script_count >= MINIMUM_SCRIPTS, "the walk found %d scripts (at least %d)" % [script_count, MINIMUM_SCRIPTS])
	_expect(scene_count >= MINIMUM_SCENES_AND_RESOURCES, "and %d scenes and resources (at least %d)" % [scene_count, MINIMUM_SCENES_AND_RESOURCES])


func _is_skipped(path: String) -> bool:
	for prefix in SKIPPED_PREFIXES:
		if path.begins_with(prefix):
			return true
	return false


# --------------------------------------------------------------------------- scenes and resources

## Every property value of a .tscn or .tres: { "property", "strings": Array[String], "line" }.
func _property_values(file_text: String) -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	var lines := file_text.split("\n")
	var index := 0
	while index < lines.size():
		var line := lines[index]
		index += 1
		if line.begins_with("[") or line.begins_with(";") or not line.contains(" = "):
			continue
		var property := line.get_slice(" = ", 0)
		var value_text := line.substr(property.length() + 3)
		var start_line := index
		while _unbalanced_quotes(value_text) and index < lines.size():
			value_text += "\n" + lines[index]
			index += 1
		var strings: Array[String] = []
		for string_match in string_regex.search_all(reference_regex.sub(value_text, "", true)):
			strings.append(_unescape(string_match.get_string(1)))
		if not strings.is_empty():
			values.append({"property": property, "strings": strings, "line": start_line})
	return values


func _scan_resource(path: String, file_text: String) -> void:
	for value in _property_values(file_text):
		var property: String = value["property"]
		for text: String in value["strings"]:
			if key_regex.search(text) != null and not TextService.domain_of(text).is_empty():
				keys_used[text] = "%s:%d" % [path, value["line"]]
				continue
			if text.strip_edges().is_empty():
				continue
			if _is_player_text(text, property, false):
				_report(path, property, text, int(value["line"]))


# --------------------------------------------------------------------------- scripts

func _scan_script(path: String, script_text: String) -> void:
	var without_docstrings := RegEx.create_from_string("\"\"\"[\\s\\S]*?\"\"\"").sub(script_text, "", true)
	var function_name := ""
	var line_number := 0
	for raw_line in without_docstrings.split("\n"):
		line_number += 1
		if raw_line.begins_with("func ") or raw_line.begins_with("static func "):
			function_name = raw_line.get_slice("func ", 1).get_slice("(", 0).strip_edges()
		var code := _without_comment(raw_line)
		if not code.contains("\""):
			continue
		var developer_line := developer_line_regex.search(code) != null or _in_developer_function(function_name)
		var sink_line := sink_regex.search(code) != null
		for string_match in string_regex.search_all(reference_regex.sub(code, "", true)):
			var text := _unescape(string_match.get_string(1))
			if key_regex.search(text) != null and not TextService.domain_of(text).is_empty():
				keys_used[text] = "%s:%d" % [path, line_number]
				continue
			if text.strip_edges().is_empty() or developer_line:
				continue
			if _is_player_text(text, "", sink_line):
				_report(path, "", text, line_number)


func _in_developer_function(function_name: String) -> bool:
	for prefix in DEVELOPER_FUNCTION_PREFIXES:
		if function_name.begins_with(prefix):
			return true
	for part in DEVELOPER_FUNCTION_PARTS:
		if function_name.contains(part):
			return true
	return false


# --------------------------------------------------------------------------- the definition

## Whether `text`, found in `property` (a scene or resource) or on a text-sink line (a script), is words for the player.
func _is_player_text(text: String, property: String, on_text_sink_line: bool) -> bool:
	if prose_regex.search(text) != null:
		return true
	if property in TEXT_PROPERTIES or on_text_sink_line:
		if on_text_sink_line and property.is_empty() and identifier_regex.search(text) != null:
			return false
		return RegEx.create_from_string("[A-Za-z]{2,}").search(text) != null
	return false


func _report(path: String, property: String, text: String, line: int) -> void:
	if _is_allowed(path, property, text):
		return
	violations.append("%s:%d %s%s" % [path.trim_prefix("res://"), line, "" if property.is_empty() else property + " = ", text.left(70).replace("\n", "\\n")])


func _is_allowed(path: String, property: String, text: String) -> bool:
	for allowance in ALLOWED_LITERALS:
		if allowance["path"] != path:
			continue
		var allowed_property := String(allowance.get("property", ""))
		var allowed_piece := String(allowance.get("contains", ""))
		var covers := (allowed_property.is_empty() and allowed_piece.is_empty()) or (not allowed_property.is_empty() and allowed_property == property) or (not allowed_piece.is_empty() and text.contains(allowed_piece))
		if covers:
			allowance_used[_allowance_id(allowance)] = true
			return true
	return false


func _allowance_id(allowance: Dictionary) -> String:
	return "%s|%s|%s" % [allowance["path"], allowance.get("property", ""), allowance.get("contains", "")]


func _the_detector_can_tell() -> void:
	var prose_samples := ["ROOM CLEARED", "Quit to title", "The pawn is hit. Move out.", "Hold Confirm to skip", "Q THRUST READY"]
	for sample in prose_samples:
		_expect(_is_player_text(sample, "", false), "words are recognised: %s" % sample)
	for sample in ["res://shell/title/title_screen.tscn", "MotionRoot/SpriteRoot/BodySprite", "wooden_sword", "ui_cancel", "%d", "v0.4.0", "Camera2D", "Pawn", "UI_PAUSE_RESUME"]:
		_expect(not _is_player_text(sample, "", false), "a name, path or key is not: %s" % sample)
	_expect(_is_player_text("Quit", "text", false) and _is_player_text("Quit", "", true), "a single word in a text property, or on a text-sink line, is")
	_expect(not _is_player_text("Quit", "script_class", false) and not _is_player_text("···", "text", false), "and a single word anywhere else, or marks with no letter, is not")
	var sample_scene := "[node name=\"Some Node Name\" type=\"Label\"]\ntext = \"Resume\"\nautowrap_mode = 3\ntitle = \"UI_PAUSE_TITLE\"\nlines = PackedStringArray(\"A\", \"B words\")\nscript = ExtResource(\"1_ab\")\n"
	var values := _property_values(sample_scene)
	_expect(values.size() == 3 and values[0]["property"] == "text" and values[1]["strings"] == ["UI_PAUSE_TITLE"] and values[2]["strings"] == ["A", "B words"], "properties are read from a scene, not its header lines or its references")
	var multi_line := _property_values("text = \"first\nsecond line\"\nnext = 1\n")
	_expect(multi_line.size() == 1 and multi_line[0]["strings"] == ["first\nsecond line"], "and a value that continues over lines is read whole")


func _unbalanced_quotes(value_text: String) -> bool:
	var count := 0
	var index := 0
	while index < value_text.length():
		if value_text[index] == "\\":
			index += 2
			continue
		if value_text[index] == "\"":
			count += 1
		index += 1
	return count % 2 == 1


func _without_comment(line: String) -> String:
	var in_string := false
	var index := 0
	while index < line.length():
		var character := line[index]
		if character == "\\" and in_string:
			index += 2
			continue
		if character == "\"":
			in_string = not in_string
		elif character == "#" and not in_string:
			return line.left(index)
		index += 1
	return line


func _unescape(text: String) -> String:
	return text.replace("\\n", "\n").replace("\\\"", "\"").replace("\\\\", "\\")


# --------------------------------------------------------------------------- the verdicts

func _keys_built_in_code_exist() -> void:
	var missing_room_rows := PackedStringArray()
	for room_id in DirAccess.get_directories_at("res://content/rooms"):
		if room_id.begins_with("_"):
			continue
		var key: String = TitleSummary.ROOM_NAME_KEY_FORMAT % room_id.to_upper()
		keys_used[key] = "content/rooms/%s" % room_id
		if not source_keys.has(key):
			missing_room_rows.append(key)
	_expect(missing_room_rows.is_empty(), "every room has a name row (missing: %s)" % ", ".join(missing_room_rows))
	for language in TextService.languages():
		keys_used["UI_LANGUAGE_NAME_%s" % String(language).to_upper()] = "TextService.language_name"
	for compass in ["NORTH", "SOUTH", "EAST", "WEST"]:
		keys_used["UI_COMPASS_%s" % compass] = "HudBridge.facing_key"


func _every_used_key_exists() -> void:
	var missing := PackedStringArray()
	for key: String in keys_used:
		if not source_keys.has(key):
			missing.append("%s (%s)" % [key, keys_used[key]])
	_expect(missing.is_empty(), "every key a script, scene or resource names has an English row (missing: %s)" % "; ".join(missing.slice(0, 10)))


func _no_literal_is_left() -> void:
	for violation in violations:
		print("LITERAL: %s" % violation)
	_expect(violations.is_empty(), "no player-facing literal is left in a script, scene or resource (%d found: %s)" % [violations.size(), " || ".join(PackedStringArray(violations.slice(0, 40)))])


func _the_allowances_are_all_needed() -> void:
	var unused := PackedStringArray()
	for allowance in ALLOWED_LITERALS:
		if not allowance_used.has(_allowance_id(allowance)):
			unused.append(_allowance_id(allowance))
		_expect(not String(allowance.get("why", "")).is_empty(), "the allowance for %s says why" % allowance["path"])
	_expect(unused.is_empty(), "every allowed literal still exists, so none hides behind a stale entry (unused: %s)" % ", ".join(unused))
