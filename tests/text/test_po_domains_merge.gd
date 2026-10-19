extends UnboundTest

## The words live in four gettext files per language (docs/game-base-plan.md 8.9, D-24: one file per domain so two
## lanes adding keys rarely touch the same file) and the engine must see them as ONE table. This suite proves it
## and checks the files as a translator edits them:
##   - the files exist for every language and are exactly the ones project.godot registers;
##   - each file is well formed: the header names its language, every key is UPPER_SNAKE with a prefix that belongs
##     in that file (TextService.PREFIXES_BY_DOMAIN), no key is written twice (not in a file, not across files:
##     the engine would let one silently shadow the other), every English row has a translator comment and words;
##   - a {placeholder} of a Vietnamese row is one the English row has;
##   - the engine resolves every English row of every file, and a language with no row for a key reads the English
##     one (Vietnamese is empty on purpose, D-25) while a row it has wins.
## The lint runs on the real files and on a bad sample, so it is shown to be able to fail.

const PoReader := preload("res://tests/support/po_file_reader.gd")

const LANGUAGES: Array[String] = ["en", "vi"]
const KEY_PATTERN := "^[A-Z][A-Z0-9]*(_[A-Z0-9]+)+$"
const PLACEHOLDER_PATTERN := "^\\{[a-z][a-z0-9_]*\\}$"
## Fewer English rows than this means the walk is broken, not clean.
const MINIMUM_SOURCE_ROWS := 100

const BAD_SAMPLE := """msgid ""
msgstr ""
"Language: xx\\n"

#. fine
msgid "UI_SAME"
msgstr "one"

msgid "UI_SAME"
msgstr "two"

#. wrong file
msgid "ROOM_X"
msgstr ""

#. lower
msgid "ui_lower"
msgstr "{Bad Name}"
"""


func _init() -> void:
	suite_title = "PO DOMAINS MERGE TEST"
	_the_files_are_the_registered_ones()
	var rows_by_language := _every_file_is_well_formed()
	_the_lint_can_fail()
	_the_engine_sees_one_table(rows_by_language)
	finish()


func _path_of(language: String, domain: String) -> String:
	return "%s/%s/%s.po" % [TextService.TEXT_FOLDER, language, domain]


func _the_files_are_the_registered_ones() -> void:
	var expected: Array[String] = []
	for language in LANGUAGES:
		for domain: StringName in TextService.PREFIXES_BY_DOMAIN:
			expected.append(_path_of(language, String(domain)))
			_expect(FileAccess.file_exists(_path_of(language, String(domain))), "%s exists" % _path_of(language, String(domain)))
	var registered: Array[String] = []
	for path in ProjectSettings.get_setting(TextService.TRANSLATIONS_SETTING, PackedStringArray()):
		registered.append(String(path))
	var missing := expected.filter(func(path: String) -> bool: return path not in registered)
	var stray := registered.filter(func(path: String) -> bool: return path not in expected)
	_expect(missing.is_empty(), "project.godot registers every file (missing: %s)" % ", ".join(PackedStringArray(missing)))
	_expect(stray.is_empty(), "and registers no other file (stray: %s)" % ", ".join(PackedStringArray(stray)))
	_expect(String(ProjectSettings.get_setting("internationalization/locale/fallback", "")) == String(TextService.SOURCE_LANGUAGE), "and a language with no row falls back to the source language")
	_expect(TextService.translations_of(TextService.SOURCE_LANGUAGE).size() == TextService.PREFIXES_BY_DOMAIN.size(), "the engine loads one translation per domain for the source language")


## language -> { key -> text } for every row of every file, after the lint of each file.
func _every_file_is_well_formed() -> Dictionary:
	var rows_by_language := {}
	var domains_by_key := {}
	for language in LANGUAGES:
		var rows := {}
		for domain: StringName in TextService.PREFIXES_BY_DOMAIN:
			var path := _path_of(language, String(domain))
			var problems := _problems_of_file(FileAccess.get_file_as_string(path), language, String(domain), language == String(TextService.SOURCE_LANGUAGE))
			_expect(problems.is_empty(), "%s is well formed%s" % [path, "" if problems.is_empty() else ": " + " | ".join(problems.slice(0, 6))])
			for entry in PoReader.parse(FileAccess.get_file_as_string(path))["entries"]:
				var key: String = entry["key"]
				if language == String(TextService.SOURCE_LANGUAGE):
					if domains_by_key.has(key):
						_expect(false, "%s is in two files (%s and %s): one would shadow the other" % [key, domains_by_key[key], domain])
					domains_by_key[key] = domain
				rows[key] = String(entry["text"])
		rows_by_language[language] = rows
	_expect(rows_by_language["en"].size() >= MINIMUM_SOURCE_ROWS, "the walk found %d English rows (at least %d)" % [rows_by_language["en"].size(), MINIMUM_SOURCE_ROWS])
	var vietnamese_keys_unknown := PackedStringArray()
	for key: String in rows_by_language["vi"]:
		if not rows_by_language["en"].has(key):
			vietnamese_keys_unknown.append(key)
	_expect(vietnamese_keys_unknown.is_empty(), "every Vietnamese row translates a key the English files have (not: %s)" % ", ".join(vietnamese_keys_unknown))
	var placeholder_mismatches := PackedStringArray()
	for key: String in rows_by_language["vi"]:
		if rows_by_language["en"].has(key) and _sorted(PoReader.placeholders_of(rows_by_language["vi"][key])) != _sorted(PoReader.placeholders_of(rows_by_language["en"][key])):
			placeholder_mismatches.append(key)
	_expect(placeholder_mismatches.is_empty(), "and keeps its {placeholders} (changed in: %s)" % ", ".join(placeholder_mismatches))
	return rows_by_language


## The sentences that say what is wrong with one .po file ("" list = healthy). `is_source` adds the rules of the
## source language: every row has words and a translator comment.
func _problems_of_file(po_text: String, language: String, domain: String, is_source: bool) -> PackedStringArray:
	var problems := PackedStringArray()
	var parsed := PoReader.parse(po_text)
	problems.append_array(parsed["problems"])
	if PoReader.header_field(parsed["header"], "Language") != language:
		problems.append("the header does not say Language: %s" % language)
	if not String(parsed["header"]).contains("charset=UTF-8"):
		problems.append("the header does not say charset=UTF-8")
	var key_regex := RegEx.create_from_string(KEY_PATTERN)
	var placeholder_regex := RegEx.create_from_string(PLACEHOLDER_PATTERN)
	var seen := {}
	for entry in parsed["entries"]:
		var key: String = entry["key"]
		if seen.has(key):
			problems.append("line %d: %s is written twice (first at line %d)" % [entry["line"], key, seen[key]])
		seen[key] = entry["line"]
		if key_regex.search(key) == null:
			problems.append("line %d: %s is not an UPPER_SNAKE key" % [entry["line"], key])
		elif String(TextService.domain_of(key)) != domain:
			problems.append("line %d: %s belongs in the %s file, not %s" % [entry["line"], key, TextService.domain_of(key), domain])
		for placeholder in PoReader.placeholders_of(entry["text"]):
			if placeholder_regex.search(placeholder) == null:
				problems.append("line %d: %s has the odd placeholder %s (use {lower_snake})" % [entry["line"], key, placeholder])
		if is_source:
			if String(entry["text"]).strip_edges().is_empty():
				problems.append("line %d: %s has no words" % [entry["line"], key])
			if entry["comments"].is_empty():
				problems.append("line %d: %s has no #. comment for the translator" % [entry["line"], key])
	return problems


func _the_lint_can_fail() -> void:
	var problems := "\n".join(_problems_of_file(BAD_SAMPLE, "en", "ui", true))
	_expect(problems.contains("Language: en") and problems.contains("UI_SAME is written twice") and problems.contains("belongs in the rooms file") and problems.contains("has no words") and problems.contains("not an UPPER_SNAKE key") and problems.contains("odd placeholder") and problems.contains("no #. comment"), "the lint names a wrong language, a repeated key, a key in the wrong file, an empty row, a lower-case key, an odd placeholder and a missing comment")
	_expect(_problems_of_file(BAD_SAMPLE.replace("xx", "en"), "en", "ui", false).size() > 0, "and a bad sample is still bad in a translation file")


func _the_engine_sees_one_table(rows_by_language: Dictionary) -> void:
	TextService.set_language(&"en")
	var unresolved := PackedStringArray()
	for key: String in rows_by_language["en"]:
		if TextService.t(key) != rows_by_language["en"][key]:
			unresolved.append(key)
	_expect(unresolved.is_empty(), "the engine resolves every row of all four English files (wrong: %s)" % ", ".join(unresolved.slice(0, 8)))
	TextService.set_language(&"vi")
	var not_falling_back := PackedStringArray()
	for key: String in rows_by_language["en"]:
		var expected: String = rows_by_language["vi"].get(key, "")
		if expected.strip_edges().is_empty():
			expected = rows_by_language["en"][key]
		if TextService.t(key) != expected:
			not_falling_back.append(key)
	_expect(not_falling_back.is_empty(), "Vietnamese answers its own row where it has one and the English row where it has none (wrong: %s)" % ", ".join(not_falling_back.slice(0, 8)))
	TextService.set_language(&"en")


func _sorted(values: PackedStringArray) -> PackedStringArray:
	var copy := values.duplicate()
	copy.sort()
	return copy
