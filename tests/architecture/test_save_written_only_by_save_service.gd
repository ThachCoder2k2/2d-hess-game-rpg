extends UnboundTest

## Architecture guard (docs/game-base-plan.md 14.1, 15 M3b "no direct save_state() outside SaveService"):
## the files that remember a playthrough are written by ONE owner. The shell asks for a save with
## SaveService.request_save(reason) (R17 holds who may, tests/save/test_request_save_callers.gd), and
## the service alone decides when and how a slot or the profile reaches the disk. Nothing else writes,
## renames or deletes a save file, and nothing else knows what the files are called.
##
## Inside shell/save/ the work is split so that the rule is checkable:
##   save_service.gd      decides when and what (the only caller of SaveFile)
##   save_file.gd         the bytes: the only file in the game that opens a file for writing
##   save_data.gd, save_migration.gd, save_load_result.gd   pure data and conversion, no file access at all
## Tests and tools are not sources: a test plants and reads files on purpose.

const ProjectFiles := preload("res://tests/architecture/project_files.gd")

const SAVE_FOLDER := "res://shell/save/"
const SAVE_SERVICE_PATH := "res://shell/save/save_service.gd"
const SAVE_FILE_PATH := "res://shell/save/save_file.gd"
const PURE_SAVE_FILES: Array[String] = [
	"res://shell/save/save_data.gd",
	"res://shell/save/save_migration.gd",
	"res://shell/save/save_load_result.gd",
]

## Code tokens that only the save folder may use (comments and string literals removed).
const SAVE_ONLY_CODE_PATTERNS: Array[String] = [
	"(?<![A-Za-z0-9_])save_state\\s*\\(",
	"(?<![A-Za-z0-9_])write_slot\\s*\\(",
	"(?<![A-Za-z0-9_])SaveFile(?![A-Za-z0-9_])",
	"(?<![A-Za-z0-9_])SaveMigration(?![A-Za-z0-9_])",
	"(?<![A-Za-z0-9_])WorldState(?![A-Za-z0-9_])",
]
## String literals that name the save's files; only the save folder may.
const SAVE_ONLY_STRING_PATTERNS: Array[String] = [
	"slot_", "profile\\.cfg", "world_state\\.cfg", "\\.bak", "\\.corrupt", "user://saves",
]
## Raw file primitives that write, move or delete: save_file.gd alone may use them.
const WRITE_PRIMITIVE_PATTERNS: Array[String] = [
	"FileAccess\\.open\\s*\\(",
	"DirAccess\\.(rename|remove|copy|make_dir)\\w*\\s*\\(",
	"\\.save\\s*\\(",
	"\\.store_\\w+\\s*\\(",
]
## Fewer source files than this means the walk is broken, not clean.
const MINIMUM_SOURCE_FILES := 20

var string_literal_regex := RegEx.create_from_string("\"(?:[^\"\\\\\\n]|\\\\.)*\"|'(?:[^'\\\\\\n]|\\\\.)*'")
var comment_regex := RegEx.create_from_string("#[^\\n]*")
var triple_quoted_regex := RegEx.create_from_string("\"\"\"[\\s\\S]*?\"\"\"")


func _init() -> void:
	suite_title = "SAVE WRITTEN ONLY BY SAVE SERVICE TEST"
	var outside_violations: Array[String] = []
	var primitive_violations: Array[String] = []
	var source_count := 0
	for script_path in ProjectFiles.collect_files(["gd"]):
		if script_path.begins_with("res://tests/") or script_path.begins_with("res://tools/"):
			continue
		source_count += 1
		var raw := ProjectFiles.read_text(script_path)
		var without_docs := comment_regex.sub(triple_quoted_regex.sub(raw, "", true), "", true)
		var code := string_literal_regex.sub(without_docs, "\"\"", true)
		var in_save_folder := script_path.begins_with(SAVE_FOLDER)
		if not in_save_folder:
			outside_violations.append_array(_matches(script_path, code, SAVE_ONLY_CODE_PATTERNS))
			outside_violations.append_array(_matches(script_path, _string_literals_of(without_docs), SAVE_ONLY_STRING_PATTERNS))
		if script_path != SAVE_FILE_PATH:
			primitive_violations.append_array(_matches(script_path, code, WRITE_PRIMITIVE_PATTERNS) if in_save_folder else [])

	_expect(source_count >= MINIMUM_SOURCE_FILES, "the walk found %d source scripts (at least %d)" % [source_count, MINIMUM_SOURCE_FILES])
	_expect(outside_violations.is_empty(), "nothing outside shell/save/ writes, names or migrates a save file, and WorldState is gone (found: %s)" % "; ".join(outside_violations))
	_expect(primitive_violations.is_empty(), "inside shell/save/ only save_file.gd opens a file for writing, renames, deletes or ConfigFile-saves (found: %s)" % "; ".join(primitive_violations))

	var save_service_code := _code_of(SAVE_SERVICE_PATH)
	_expect(save_service_code.contains("SaveFile.write(") and save_service_code.contains("SaveFile.read("), "the service reaches the disk through SaveFile and nowhere else")
	for pure_path in PURE_SAVE_FILES:
		var pure_code := _code_of(pure_path)
		_expect(not pure_code.is_empty() and not pure_code.contains("FileAccess") and not pure_code.contains("DirAccess"), "%s touches no file (pure data or conversion)" % pure_path.get_file())

	var save_file_users: Array[String] = []
	for script_path in ProjectFiles.collect_files(["gd"]):
		if script_path.begins_with("res://tests/") or script_path.begins_with("res://tools/") or script_path == SAVE_FILE_PATH:
			continue
		if _code_of(script_path).contains("SaveFile.write(") or _code_of(script_path).contains("SaveFile.set_aside("):
			save_file_users.append(script_path)
	_expect(save_file_users == [SAVE_SERVICE_PATH], "save_service.gd is the one caller of SaveFile.write() and set_aside() (found: %s)" % ", ".join(PackedStringArray(save_file_users)))

	var project_text := ProjectFiles.read_text("res://project.godot")
	_expect(project_text.contains("SaveService=\"*res://shell/save/save_service.gd\"") and not project_text.contains("WorldState="), "project.godot registers SaveService as the autoload and no WorldState")
	_expect(not FileAccess.file_exists("res://shell/save/world_state.gd"), "the WorldState script is gone")

	# The guard must be able to fail: the same patterns on code that breaks the rule.
	_expect(not _matches("sample.gd", "world_state.save_state()", SAVE_ONLY_CODE_PATTERNS).is_empty(), "the pattern for a direct save_state() call catches one")
	_expect(not _matches("sample.gd", "service.write_slot(0, data)", SAVE_ONLY_CODE_PATTERNS).is_empty(), "and one for write_slot()")
	_expect(not _matches("sample.gd", "var file := FileAccess.open(path, FileAccess.WRITE)", WRITE_PRIMITIVE_PATTERNS).is_empty(), "and one for opening a file to write")
	_expect(_matches("sample.gd", "var snapshot_saved := true # the room saved", SAVE_ONLY_CODE_PATTERNS).is_empty(), "but not a variable that merely has save in its name")
	finish()


## "<file>: <pattern>" for every pattern that matches `text`.
func _matches(script_path: String, text: String, patterns: Array[String]) -> Array[String]:
	var found: Array[String] = []
	for pattern in patterns:
		if RegEx.create_from_string(pattern).search(text) != null:
			found.append("%s: %s" % [script_path.get_file(), pattern])
	return found


## Only the string literals of a script, one per line, so a path written in a string can be looked for.
func _string_literals_of(code_without_comments: String) -> String:
	var literals := PackedStringArray()
	for literal_match in string_literal_regex.search_all(code_without_comments):
		literals.append(literal_match.get_string())
	return "\n".join(literals)


## The code of a script with comments and string literals removed.
func _code_of(script_path: String) -> String:
	var raw := ProjectFiles.read_text(script_path)
	var without_docs := comment_regex.sub(triple_quoted_regex.sub(raw, "", true), "", true)
	return string_literal_regex.sub(without_docs, "\"\"", true)
