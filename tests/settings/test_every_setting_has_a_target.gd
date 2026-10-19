extends UnboundTest

## Every setting is proved to reach its target (docs/game-base-plan.md 15 M4: "each setting must actually drive its target").
## A setting that is stored and shown on the screen but drives nothing is the failure this suite exists for: it reads the
## suites of tests/settings/test_setting_*.gd and fails when a setting of the table is never SET there
## (`set_value(GameSettings.KEY, ...)`), so a new setting cannot be added without a suite that moves it and looks at what
## it is supposed to move. The suites themselves say what they look at; this is the guard that none is missing.
## Also held: every suite of the folder is about a setting that exists, so a renamed or removed setting cannot leave a
## suite that sets a key by a name nobody checks.

const SUITE_FOLDER := "res://tests/settings"
const SUITE_PREFIX := "test_setting_"


func _init() -> void:
	suite_title = "EVERY SETTING HAS A TARGET TEST"
	var constant_name_by_key := {}
	var settings_script: GDScript = GameSettings
	var constants := settings_script.get_script_constant_map()
	for constant_name: String in constants:
		var constant_value: Variant = constants[constant_name]
		if constant_value is StringName and GameSettings.definition_of(constant_value) != null:
			constant_name_by_key[constant_value] = constant_name
	_expect(constant_name_by_key.size() == GameSettings.definitions().size(), "setup: every definition has a constant to name it by (%d of %d)" % [constant_name_by_key.size(), GameSettings.definitions().size()])

	var sources := {}
	var directory := DirAccess.open(SUITE_FOLDER)
	for file_name in directory.get_files():
		if file_name.begins_with(SUITE_PREFIX) and file_name.ends_with(".gd"):
			sources[file_name] = FileAccess.get_file_as_string(SUITE_FOLDER.path_join(file_name))
	_expect(sources.size() >= 8, "setup: the folder holds the suites of the settings (%d)" % sources.size())

	var untested := PackedStringArray()
	for definition in GameSettings.definitions():
		var constant_name: String = constant_name_by_key.get(definition.key, "")
		var needle := "GameSettings.%s" % constant_name
		var found_in := ""
		for file_name: String in sources:
			var source := String(sources[file_name])
			if source.contains("set_value(") and _names_the_setting(source, needle):
				found_in = file_name
				break
		if found_in.is_empty():
			untested.append(String(definition.key))
		else:
			_expect(true, "%s is set, and its target looked at, in %s" % [definition.key, found_in])
	_expect(untested.is_empty(), "every setting has a suite that moves it (without one: %s)" % ", ".join(untested))

	var unknown_keys := PackedStringArray()
	var reference := RegEx.create_from_string("GameSettings\\.([A-Z_]+)")
	for file_name: String in sources:
		for match in reference.search_all(String(sources[file_name])):
			var name := match.get_string(1)
			if name in ["DEFAULT_LANGUAGE", "PROFILE_KEY_PREFIX"] or constants.has(name):
				continue
			unknown_keys.append("%s names GameSettings.%s" % [file_name, name])
	_expect(unknown_keys.is_empty(), "no suite names a setting that does not exist (%s)" % "; ".join(unknown_keys))
	finish()


## Whether `source` writes `needle` as a whole name (GameSettings.TOGGLE_GUARD is not found in GameSettings.TOGGLE_GUARD_X).
func _names_the_setting(source: String, needle: String) -> bool:
	return RegEx.create_from_string(needle + "(?![A-Z_0-9])").search(source) != null
