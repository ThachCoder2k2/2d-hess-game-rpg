class_name SettingsStore
extends RefCounted

## Where the player's settings live on disk (docs/game-base-plan.md 9.2: "stored separately from saves"). They are
## values of the PROFILE file the SaveService owns (`<root>/profile.cfg`, the file the `completed` mark is in), each under
## the key of its setting with a `setting_` prefix, so a New Game, which replaces the slot and keeps the profile, keeps the
## settings, and a damaged slot cannot take them. Only the SaveService writes a file (the test that holds that line):
## this class asks it, and never touches a path.
##
## Reading never fails and never stops the game: a profile that is missing, damaged, half written or hand edited gives
## a setting that cannot be used its DEFAULT, and the reason is logged (`push_warning`) and kept in `last_problems`.
## A first run has no settings stored at all, and that is one line, not seventeen.

## The SaveService autoload has no class_name (an autoload's name is a global), so its script is the type.
const SaveServiceScript := preload("res://shell/save/save_service.gd")

## What a setting's key is stored under in the profile: `setting_<key>`.
const PROFILE_KEY_PREFIX := "setting_"

## The service the profile is read from and written to. Null: nothing is stored (a scene run alone) and every setting is
## at its default.
var save_service: SaveServiceScript = null
## Why the last load_settings() replaced values by defaults, one sentence each (empty when every value was read).
var last_problems := PackedStringArray()
## What the last save_settings() returned: OK, or the file error. ERR_LOCKED is a profile a NEWER game wrote, which this
## game never replaces: the settings then last until the game is closed, and the Settings screen says so.
var last_save_error: Error = OK


func _init(service: SaveServiceScript = null) -> void:
	save_service = service


## The settings stored in the profile, with a default for every one that cannot be used. A language the game has no
## words for is such a value (a profile from a build that had one more language).
func load_settings() -> GameSettings:
	last_problems = PackedStringArray()
	var stored := {}
	if save_service != null:
		var profile := save_service.read_profile()
		for profile_key: String in profile:
			if profile_key.begins_with(PROFILE_KEY_PREFIX):
				stored[profile_key.trim_prefix(PROFILE_KEY_PREFIX)] = profile[profile_key]
	if stored.is_empty():
		var unreadable := save_service.profile_problem() if save_service != null else ""
		if unreadable.is_empty():
			last_problems.append("no settings are stored yet; every setting is at its default")
		else:
			last_problems.append("the profile that holds the settings cannot be read (%s); every setting is at its default and the next change replaces the file" % unreadable)
		_log()
		return GameSettings.new()
	var settings := GameSettings.from_values(stored)
	last_problems = settings.load_problems
	var language := String(settings.value(GameSettings.LANGUAGE))
	if StringName(language) not in TextService.languages():
		last_problems.append("setting 'language' names '%s', which has no words in this game; using the default (%s)" % [language, GameSettings.DEFAULT_LANGUAGE])
		settings.set_value(GameSettings.LANGUAGE, GameSettings.DEFAULT_LANGUAGE)
	_log()
	return settings


## Writes every setting to the profile in one write. Returns OK, or the file error (the game goes on: the settings
## still hold in memory, and the next change tries again); last_save_error keeps it for whoever tells the player.
func save_settings(settings: GameSettings) -> Error:
	if save_service == null:
		return ERR_UNAVAILABLE
	var values := {}
	var settings_values := settings.to_values()
	for key: String in settings_values:
		values[PROFILE_KEY_PREFIX + key] = settings_values[key]
	var error := save_service.set_profile_values(values)
	last_save_error = error
	if error == ERR_LOCKED:
		push_warning("Settings: the profile was written by a newer version of the game, which this version never replaces; the settings last until the game is closed")
	elif error != OK:
		push_warning("Settings: the profile could not be written (error %d: %s); they stay as they are until the next change" % [error, error_string(error)])
	return error


func _log() -> void:
	for problem in last_problems:
		push_warning("Settings: %s" % problem)
