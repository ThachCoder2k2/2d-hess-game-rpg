extends UnboundTest

## The settings are kept in the profile and come back as they were (docs/game-base-plan.md 9.2, M4 acceptance
## `test_settings_roundtrip`):
##   1. THE TABLE. Every setting has a definition whose default passes its own check, a name and a page; assists and
##      hold-or-toggle default to the standard game (D-22: opt-in, never on by themselves); the fullscreen default is the
##      one project.godot ships.
##   2. ROUND TRIP. Every setting changed to a value that is not its default, written, read back by a fresh store from a
##      fresh service on the same folder: every value equal. A New Game keeps them (the profile survives it) and the
##      `completed` mark beside them is untouched.
##   3. A FIRST RUN has nothing stored: every default, ONE line of reason.
##   4. GARBAGE or missing keys fall back to defaults WITH A LOGGED REASON each, and the usable keys around them are kept:
##      a wrong type, a number out of range, a value that is not an option, a language the game has no words for, a key a
##      newer game wrote; a profile that is not a file at all gives every default and no crash; a profile that cannot be
##      read says so (it is not "no settings stored yet"), also when it is bytes no text can hold, and prints no engine
##      error for them; a profile a NEWER game wrote is read and never replaced, and the store keeps the refusal.
##   5. set_value refuses what the definition refuses, and says `changed` once per real change.
## What each setting DRIVES is pinned by test_settings_drive_their_targets.

const SaveSupport := preload("res://tests/support/save_test_support.gd")

var folders_to_remove: Array[String] = []


func _init() -> void:
	suite_title = "SETTINGS ROUNDTRIP TEST"
	_the_table()
	_a_round_trip_keeps_every_value()
	_a_first_run_has_one_line_of_reason()
	_garbage_falls_back_with_reasons()
	_a_profile_that_is_not_a_file()
	_a_profile_that_cannot_be_read_says_so()
	_a_newer_games_profile_is_read_and_never_replaced()
	_set_value_refuses_what_the_definition_refuses()
	for folder in folders_to_remove:
		SaveSupport.remove_root(folder)
	finish()


# --------------------------------------------------------------------------- 1. the table

func _the_table() -> void:
	var seen := {}
	var problems := PackedStringArray()
	for definition in GameSettings.definitions():
		if seen.has(definition.key):
			problems.append("%s is defined twice" % definition.key)
		seen[definition.key] = true
		var default_problem := definition.problems_with(definition.default_value)
		if not default_problem.is_empty():
			problems.append("the default of %s fails its own check: %s" % [definition.key, default_problem])
		if not TextService.has_key(definition.label_key):
			problems.append("%s has no name row (%s)" % [definition.key, definition.label_key])
		for option in definition.choices:
			if not TextService.has_key(String(option["label_key"])):
				problems.append("%s has an option with no words (%s)" % [definition.key, option["label_key"]])
	_expect(problems.is_empty(), "every setting has a unique key, a default that passes its own check and words (%s)" % "; ".join(problems))
	_expect(GameSettings.definitions().size() == 17, "the table holds the 17 settings the plan lists (%d)" % GameSettings.definitions().size())
	var pages := {}
	for definition in GameSettings.definitions():
		pages[definition.group] = true
	_expect(pages.size() == SettingDefinition.Group.size(), "every page of the screen has at least one setting")

	var standard := GameSettings.new()
	for key in [GameSettings.REDUCE_FLASH, GameSettings.HIGH_CONTRAST_DANGER, GameSettings.UI_HIGH_CONTRAST, GameSettings.TOGGLE_GUARD, GameSettings.TOGGLE_FOCUS, GameSettings.TOGGLE_TURN_MODE, GameSettings.ASSIST_INPUT_FORGIVENESS]:
		_expect(standard.value(key) == false, "%s is off until the player turns it on" % key)
	_expect(standard.value(GameSettings.ASSIST_TELEGRAPH_TIME) == 100 and standard.value(GameSettings.ASSIST_ENEMY_PACE) == 100 and standard.value(GameSettings.ASSIST_EXTRA_COURAGE) == 0, "the assists are the standard game: 100 percent, 100 percent, +0 (D-22)")
	_expect(is_equal_approx(float(standard.value(GameSettings.SHAKE_SCALE)), 1.0), "the screen shake is at full strength")
	for key in [GameSettings.VOLUME_MASTER, GameSettings.VOLUME_SFX, GameSettings.VOLUME_MUSIC, GameSettings.VOLUME_UI]:
		_expect(is_equal_approx(float(standard.value(key)), 1.0), "%s starts at full" % key)
	_expect(standard.value(GameSettings.LANGUAGE) == GameSettings.DEFAULT_LANGUAGE and GameSettings.DEFAULT_LANGUAGE == String(TextService.SOURCE_LANGUAGE), "the language is the source language, English (D-25)")
	var shipped_mode := int(ProjectSettings.get_setting("display/window/size/mode", 0))
	_expect(standard.value(GameSettings.FULLSCREEN) == (shipped_mode == Window.MODE_FULLSCREEN or shipped_mode == Window.MODE_EXCLUSIVE_FULLSCREEN), "Fullscreen starts as the project's window mode says (project.godot is the one place it is written)")
	_expect(standard.to_values().size() == 17 and standard.to_values().has("volume_master"), "to_values() writes every key by name")


# --------------------------------------------------------------------------- 2. the round trip

func _a_round_trip_keeps_every_value() -> void:
	var root_directory := SaveSupport.make_root("settings_roundtrip")
	folders_to_remove.append(root_directory)
	var service := SaveSupport.new_service(root_directory)
	var store := SettingsStore.new(service)
	var settings := store.load_settings()
	var changed_keys: Array[StringName] = []
	for definition in GameSettings.definitions():
		var other: Variant = _a_value_that_is_not_the_default(definition)
		_expect(settings.set_value(definition.key, other), "setup: %s accepts %s" % [definition.key, str(other)])
		changed_keys.append(definition.key)
	_expect(store.save_settings(settings) == OK, "the settings are written to the profile")
	_expect(FileAccess.file_exists(service.profile_path()), "in the profile file the SaveService owns")

	var fresh_service := SaveSupport.new_service(root_directory)
	var fresh_store := SettingsStore.new(fresh_service)
	var read_back := fresh_store.load_settings()
	var differing := PackedStringArray()
	for key in changed_keys:
		if read_back.value(key) != settings.value(key) or typeof(read_back.value(key)) != typeof(settings.value(key)):
			differing.append("%s: wrote %s, read %s" % [key, str(settings.value(key)), str(read_back.value(key))])
	_expect(differing.is_empty(), "a fresh service on the same folder reads back every one of the %d values, with its type (%s)" % [changed_keys.size(), "; ".join(differing)])
	_expect(fresh_store.last_problems.is_empty(), "and finds nothing to complain about (%s)" % [fresh_store.last_problems])
	for definition in GameSettings.definitions():
		_expect(not read_back.is_default(definition.key), "%s really was changed from its default" % definition.key)

	fresh_service.mark_completed()
	fresh_service.new_game(0)
	fresh_service.start_new_run(0)
	var after_new_game := SettingsStore.new(SaveSupport.new_service(root_directory)).load_settings()
	_expect(after_new_game.to_values() == settings.to_values(), "a New Game keeps the settings")
	_expect(fresh_service.is_completed(), "and keeps the `completed` mark beside them")
	var profile_text := SaveSupport.text_of(service.profile_path())
	_expect(profile_text.contains("setting_volume_master") and profile_text.contains("completed"), "the profile holds both, the settings under the setting_ prefix")


func _a_value_that_is_not_the_default(definition: SettingDefinition) -> Variant:
	match definition.kind:
		SettingDefinition.Kind.SLIDER:
			return 0.35
		SettingDefinition.Kind.TOGGLE:
			return not bool(definition.default_value)
		SettingDefinition.Kind.CHOICE:
			for option in definition.choices:
				if option["value"] != definition.default_value:
					return option["value"]
		SettingDefinition.Kind.LANGUAGE:
			return "vi"
	return definition.default_value


# --------------------------------------------------------------------------- 3. a first run

func _a_first_run_has_one_line_of_reason() -> void:
	var service := SaveSupport.new_service(_new_folder("settings_first_run"))
	var store := SettingsStore.new(service)
	var settings := store.load_settings()
	_expect(settings.to_values() == GameSettings.new().to_values(), "with no profile every setting is its default")
	_expect(store.last_problems.size() == 1 and store.last_problems[0].contains("no settings are stored"), "and the reason is one line, not one per setting (%s)" % [store.last_problems])
	_expect(SettingsStore.new(null).load_settings().to_values() == GameSettings.new().to_values(), "a scene run alone, with no save service, has the defaults too")


# --------------------------------------------------------------------------- 4. garbage

func _garbage_falls_back_with_reasons() -> void:
	var service := SaveSupport.new_service(_new_folder("settings_garbage"))
	var prefix := SettingsStore.PROFILE_KEY_PREFIX
	service.set_profile_values({
		prefix + "volume_master": "loud",
		prefix + "fullscreen": 3,
		prefix + "language": "zz",
		prefix + "shake_scale": 7.5,
		prefix + "assist_enemy_pace": 55,
		prefix + "assist_telegraph_time": 125,
		prefix + "reduce_flash": true,
		prefix + "volume_music": 0.25,
		prefix + "assist_extra_courage": 1.0,
		prefix + "a_setting_of_the_future": 1,
	})
	var store := SettingsStore.new(service)
	var settings := store.load_settings()
	var standard := GameSettings.new()
	for key in [GameSettings.VOLUME_MASTER, GameSettings.FULLSCREEN, GameSettings.LANGUAGE, GameSettings.SHAKE_SCALE, GameSettings.ASSIST_ENEMY_PACE, GameSettings.ASSIST_EXTRA_COURAGE]:
		_expect(settings.value(key) == standard.value(key), "garbage in %s falls back to its default" % key)
	_expect(settings.value(GameSettings.ASSIST_TELEGRAPH_TIME) == 125 and settings.value(GameSettings.REDUCE_FLASH) == true and is_equal_approx(float(settings.value(GameSettings.VOLUME_MUSIC)), 0.25), "the usable values around it are kept")
	var reasons := " | ".join(store.last_problems)
	for fragment in ["'volume_master' is unusable", "'fullscreen' is unusable", "'language' names 'zz'", "'shake_scale' is unusable", "'assist_enemy_pace' is unusable", "'assist_extra_courage' is unusable", "'a_setting_of_the_future' is not one this game knows"]:
		_expect(reasons.contains(fragment), "the log says why: %s" % fragment)
	_expect(reasons.contains("'volume_sfx' is not stored"), "and a key that is simply missing is named too, with its default")
	_expect(not reasons.contains("'volume_music'") and not reasons.contains("'reduce_flash'"), "while a usable key is not complained about")

	var partial := GameSettings.from_values({"volume_master": 0.5})
	_expect(is_equal_approx(float(partial.value(GameSettings.VOLUME_MASTER)), 0.5) and partial.load_problems.size() == 16, "from_values keeps what it can and reports each of the 16 missing keys (%d)" % partial.load_problems.size())


func _a_profile_that_is_not_a_file() -> void:
	var folder := _new_folder("settings_not_a_file")
	var service := SaveSupport.new_service(folder)
	SaveSupport.plant(service.profile_path(), "this is not a config file \u0000\u0001 ][ = =\n[[[")
	var settings := SettingsStore.new(service).load_settings()
	_expect(settings.to_values() == GameSettings.new().to_values(), "a profile that is not a file gives every default and no crash")
	SaveSupport.plant(service.profile_path(), "[profile]\nsetting_volume_master=\nsetting_fullscreen=oops\n")
	var half_written := SettingsStore.new(service).load_settings()
	_expect(half_written.to_values() == GameSettings.new().to_values(), "and so does one whose values are cut off")


func _a_profile_that_cannot_be_read_says_so() -> void:
	var service := SaveSupport.new_service(_new_folder("settings_unreadable"))
	var store := SettingsStore.new(service)
	# Written by hand, so it has no integrity footer: the game cannot use it.
	SaveSupport.plant(service.profile_path(), "[profile]\nsetting_volume_master=0.5\n")
	var settings := store.load_settings()
	_expect(settings.to_values() == GameSettings.new().to_values(), "a profile with no footer gives every default")
	_expect(store.last_problems.size() == 1 and store.last_problems[0].contains("cannot be read") and store.last_problems[0].contains("integrity footer") and not store.last_problems[0].contains("no settings are stored"), "and the log says the file cannot be read and why, not that nothing is stored yet (%s)" % [store.last_problems])
	# Bytes that are not text at all: decoding them as text would print a line of engine error for every bad byte, and
	# this suite runs under --strict, so a noisy read fails it.
	var noise := PackedByteArray()
	for index in 300:
		noise.append(0x80 + (index * 7) % 128)
	noise.append_array(PackedByteArray([0xFF, 0xFE, 0xC0, 0xAF, 0xED, 0xA0, 0x80, 0xF5]))
	SaveSupport.plant_bytes(service.profile_path(), noise)
	var from_noise := store.load_settings()
	_expect(from_noise.to_values() == GameSettings.new().to_values() and store.last_problems.size() == 1 and store.last_problems[0].contains("is not text"), "bytes that are not text give every default and one sentence (%s)" % [store.last_problems])
	_expect(not SaveFile.is_valid_utf8(PackedByteArray([0xC0, 0xAF])) and not SaveFile.is_valid_utf8(PackedByteArray([0xED, 0xA0, 0x80])) and not SaveFile.is_valid_utf8(PackedByteArray([0xE2, 0x82])) and SaveFile.is_valid_utf8("Tiếng Việt, 日本語, 🙂".to_utf8_buffer()) and SaveFile.is_valid_utf8(PackedByteArray()), "the byte check refuses an overlong form, a surrogate and a cut-off letter, and accepts real text in any script")
	_expect(service.set_profile_value(&"setting_volume_master", 0.4) == OK and is_equal_approx(float(store.load_settings().value(GameSettings.VOLUME_MASTER)), 0.4), "and the next write replaces the unreadable file")


func _a_newer_games_profile_is_read_and_never_replaced() -> void:
	var service := SaveSupport.new_service(_new_folder("settings_newer"))
	var newer_text := SaveSupport.profile_text_of_version(99, {"setting_volume_master": 0.3, "a_value_of_the_future": 1})
	SaveSupport.plant(service.profile_path(), newer_text)
	var store := SettingsStore.new(service)
	var settings := store.load_settings()
	_expect(is_equal_approx(float(settings.value(GameSettings.VOLUME_MASTER)), 0.3), "a profile of a newer game is read: the values this game knows are used")
	settings.set_value(GameSettings.VOLUME_MASTER, 0.6)
	_expect(store.save_settings(settings) == ERR_LOCKED and store.last_save_error == ERR_LOCKED, "writing the settings is refused, and the store keeps the refusal")
	_expect(SaveSupport.text_of(service.profile_path()) == newer_text, "the newer game's file is byte for byte what it was")
	_expect(is_equal_approx(float(settings.value(GameSettings.VOLUME_MASTER)), 0.6), "while the settings in memory keep the change")
	DirAccess.remove_absolute(service.profile_path())
	_expect(store.save_settings(settings) == OK and store.last_save_error == OK, "with the file gone a write succeeds and the refusal is forgotten")


# --------------------------------------------------------------------------- 5. set_value

func _set_value_refuses_what_the_definition_refuses() -> void:
	var settings := GameSettings.new()
	var heard: Array[StringName] = []
	settings.value_changed.connect(func(key: StringName) -> void: heard.append(key))
	var changed_count := [0]
	settings.changed.connect(func() -> void: changed_count[0] += 1)
	_expect(not settings.set_value(&"not_a_setting", true), "a key that is not a setting is refused")
	_expect(not settings.set_value(GameSettings.FULLSCREEN, "yes"), "a text for a switch is refused")
	_expect(not settings.set_value(GameSettings.VOLUME_SFX, 1.5) and not settings.set_value(GameSettings.VOLUME_SFX, -0.1), "a volume outside 0 to 1 is refused")
	_expect(not settings.set_value(GameSettings.ASSIST_ENEMY_PACE, 90), "a value that is not one of the options is refused")
	_expect(not settings.set_value(GameSettings.VOLUME_SFX, NAN), "not a number is refused")
	_expect(heard.is_empty() and changed_count[0] == 0, "a refusal changes nothing and says nothing")
	_expect(settings.set_value(GameSettings.VOLUME_SFX, 0), "a whole number is accepted for a slider")
	_expect(typeof(settings.value(GameSettings.VOLUME_SFX)) == TYPE_FLOAT and settings.value(GameSettings.VOLUME_SFX) == 0.0, "and held as the float it is")
	_expect(heard == [GameSettings.VOLUME_SFX] and changed_count[0] == 1, "a real change says value_changed and changed once")
	settings.set_value(GameSettings.VOLUME_SFX, 0.0)
	_expect(heard.size() == 1 and changed_count[0] == 1, "setting the value it already has says nothing")
	settings.set_value(GameSettings.REDUCE_FLASH, true)
	settings.reset_to_defaults()
	_expect(settings.to_values() == GameSettings.new().to_values() and changed_count[0] == 3, "reset_to_defaults puts everything back and says `changed` once (%d)" % changed_count[0])
	_expect(settings.value(&"not_a_setting") == null, "an unknown key reads as null")


func _new_folder(suite_name: String) -> String:
	var folder := SaveSupport.make_root(suite_name)
	folders_to_remove.append(folder)
	return folder
