class_name GameSettings
extends Resource

## What the player chose in the settings screen (docs/game-base-plan.md 9.2 "Settings", D-22 assists, 10 accessibility):
## the volume of each bus, the screen-shake scale, reduce flashing, high-contrast danger, high-contrast menus,
## fullscreen, the language, the assists and hold-or-toggle for Guard, Focus and turn mode. ONE object holds them; AppRoot
## owns it, the settings screen edits it, `changed` tells everyone it moved, and what each value DRIVES is the job of
## the appliers that listen (shell/settings/settings_applier.gd for the app, shell/bridges/settings_bridge.gd for the
## room). It is not part of a run: it lives in the profile file next to the `completed` mark (SettingsStore), so a
## New Game keeps it. Assists are per profile here and not per save (the plan's 5.8 says per save; recorded in the plan's
## M4 entry), which keeps them one place and reachable from the title.
##
## Every setting is a SettingDefinition: the table below holds its key, kind, page, name, default and range. A value
## that does not fit its definition is refused by set_value() and replaced by the default when a profile is read
## (from_values), with the reason in `load_problems`. Assists are OPT-IN with neutral names (D-22): every default is
## the standard game, and nothing ever changes one for the player.
##
## Hold-or-toggle (5.8): `true` means a press of the key switches the action on and off, `false` means it is on
## while the key is held, as it always was.
##
## A volume is a number from 0.0 to 1.0 (the screen shows a percent); the appliers turn it into decibels.

## A value changed: its key. `changed` (the Resource signal) also fires, once per change.
signal value_changed(key: StringName)

# --------------------------------------------------------------------------- the keys
const VOLUME_MASTER := &"volume_master"
const VOLUME_SFX := &"volume_sfx"
const VOLUME_MUSIC := &"volume_music"
const VOLUME_UI := &"volume_ui"
const FULLSCREEN := &"fullscreen"
const LANGUAGE := &"language"
const UI_HIGH_CONTRAST := &"ui_high_contrast"
const SHAKE_SCALE := &"shake_scale"
const REDUCE_FLASH := &"reduce_flash"
const HIGH_CONTRAST_DANGER := &"high_contrast_danger"
const TOGGLE_TURN_MODE := &"toggle_turn_mode"
const TOGGLE_GUARD := &"toggle_guard"
const TOGGLE_FOCUS := &"toggle_focus"
const ASSIST_TELEGRAPH_TIME := &"assist_telegraph_time"
const ASSIST_ENEMY_PACE := &"assist_enemy_pace"
const ASSIST_EXTRA_COURAGE := &"assist_extra_courage"
const ASSIST_INPUT_FORGIVENESS := &"assist_input_forgiveness"

## The language every player starts in: the source language of the words (D-25).
const DEFAULT_LANGUAGE := "en"

## The definitions, in the order the screen lists them. Built on first use.
static var _definitions: Array[SettingDefinition] = []

## key -> the value now. Always holds every key of the table.
var _value_by_key: Dictionary[StringName, Variant] = {}

## Why each value that could not be read from the profile was replaced by its default (a sentence each); empty for a
## GameSettings that was not made by from_values().
var load_problems := PackedStringArray()


func _init() -> void:
	for definition in definitions():
		_value_by_key[definition.key] = definition.default_value


## The table of settings.
static func definitions() -> Array[SettingDefinition]:
	if _definitions.is_empty():
		_definitions = _build_definitions()
	return _definitions


## The definition of `key`, null for a key that is not a setting.
static func definition_of(key: StringName) -> SettingDefinition:
	for definition in definitions():
		if definition.key == key:
			return definition
	return null


## The definitions of one page, in order.
static func definitions_of_group(group: SettingDefinition.Group) -> Array[SettingDefinition]:
	var found: Array[SettingDefinition] = []
	for definition in definitions():
		if definition.group == group:
			found.append(definition)
	return found


## The value of `key` now (null for a key that is not a setting).
func value(key: StringName) -> Variant:
	return _value_by_key.get(key)


## Sets `key` to `new_value`. Refused (false, nothing changes) for a key that is not a setting and for a value its
## definition does not allow. True when the value was accepted, even if it was the one already there; `changed` and
## `value_changed` fire only when it differs.
func set_value(key: StringName, new_value: Variant) -> bool:
	var definition := definition_of(key)
	if definition == null:
		return false
	var coerced: Variant = definition.coerce(new_value)
	if not definition.problems_with(coerced).is_empty():
		return false
	if _value_by_key[key] == coerced and typeof(_value_by_key[key]) == typeof(coerced):
		return true
	_value_by_key[key] = coerced
	value_changed.emit(key)
	emit_changed()
	return true


## Puts every setting back to its default; `changed` fires once.
func reset_to_defaults() -> void:
	var any_changed := false
	for definition in definitions():
		if _value_by_key[definition.key] != definition.default_value:
			_value_by_key[definition.key] = definition.default_value
			value_changed.emit(definition.key)
			any_changed = true
	if any_changed:
		emit_changed()


## Whether `key` holds its default.
func is_default(key: StringName) -> bool:
	var definition := definition_of(key)
	return definition != null and _value_by_key[key] == definition.default_value


## Every setting as key (String) -> value, the form the profile stores.
func to_values() -> Dictionary:
	var values := {}
	for key: StringName in _value_by_key:
		values[String(key)] = _value_by_key[key]
	return values


## Settings read from stored values (key String -> value, as to_values() wrote them). A key that is missing, or whose
## value does not fit its definition, takes the default, and `load_problems` says why, one sentence each. A key that is
## not a setting (a newer game's) is ignored and said.
static func from_values(stored: Dictionary) -> GameSettings:
	var settings := GameSettings.new()
	for definition in definitions():
		var stored_key := String(definition.key)
		if not stored.has(stored_key):
			settings.load_problems.append("setting '%s' is not stored; using its default (%s)" % [stored_key, str(definition.default_value)])
			continue
		var stored_value: Variant = definition.coerce(stored[stored_key])
		var problem := definition.problems_with(stored_value)
		if not problem.is_empty():
			settings.load_problems.append("setting '%s' is unusable (%s); using its default (%s)" % [stored_key, problem, str(definition.default_value)])
			continue
		settings._value_by_key[definition.key] = stored_value
	for stored_key: Variant in stored:
		if definition_of(StringName(String(stored_key))) == null:
			settings.load_problems.append("setting '%s' is not one this game knows; ignored" % String(stored_key))
	return settings


## The loudness of a volume setting in decibels: -80 (silence) at 0.0, 0 at 1.0.
static func volume_in_decibels(amount: float) -> float:
	return linear_to_db(amount) if amount > 0.0 else -80.0


static func _build_definitions() -> Array[SettingDefinition]:
	var table: Array[SettingDefinition] = []
	table.append(SettingDefinition.slider(VOLUME_MASTER, SettingDefinition.Group.SOUND, "UI_SETTINGS_VOLUME_MASTER", 1.0))
	table.append(SettingDefinition.slider(VOLUME_MUSIC, SettingDefinition.Group.SOUND, "UI_SETTINGS_VOLUME_MUSIC", 1.0))
	table.append(SettingDefinition.slider(VOLUME_SFX, SettingDefinition.Group.SOUND, "UI_SETTINGS_VOLUME_SFX", 1.0))
	table.append(SettingDefinition.slider(VOLUME_UI, SettingDefinition.Group.SOUND, "UI_SETTINGS_VOLUME_UI", 1.0))
	table.append(SettingDefinition.toggle(FULLSCREEN, SettingDefinition.Group.SCREEN, "UI_SETTINGS_FULLSCREEN", _ships_fullscreen()))
	table.append(SettingDefinition.language(LANGUAGE, SettingDefinition.Group.SCREEN, "UI_SETTINGS_LANGUAGE", DEFAULT_LANGUAGE))
	table.append(SettingDefinition.toggle(UI_HIGH_CONTRAST, SettingDefinition.Group.SCREEN, "UI_SETTINGS_UI_HIGH_CONTRAST", false))
	table.append(SettingDefinition.slider(SHAKE_SCALE, SettingDefinition.Group.COMFORT, "UI_SETTINGS_SHAKE_SCALE", 1.0))
	table.append(SettingDefinition.toggle(REDUCE_FLASH, SettingDefinition.Group.COMFORT, "UI_SETTINGS_REDUCE_FLASH", false))
	table.append(SettingDefinition.toggle(HIGH_CONTRAST_DANGER, SettingDefinition.Group.COMFORT, "UI_SETTINGS_HIGH_CONTRAST_DANGER", false))
	table.append(SettingDefinition.toggle(TOGGLE_TURN_MODE, SettingDefinition.Group.COMFORT, "UI_SETTINGS_TOGGLE_TURN_MODE", false))
	table.append(SettingDefinition.toggle(TOGGLE_GUARD, SettingDefinition.Group.COMFORT, "UI_SETTINGS_TOGGLE_GUARD", false))
	table.append(SettingDefinition.toggle(TOGGLE_FOCUS, SettingDefinition.Group.COMFORT, "UI_SETTINGS_TOGGLE_FOCUS", false))
	table.append(SettingDefinition.choice(ASSIST_TELEGRAPH_TIME, SettingDefinition.Group.ASSISTS, "UI_SETTINGS_ASSIST_TELEGRAPH_TIME", 100, [
		{"value": 100, "label_key": "UI_SETTINGS_OPTION_100"},
		{"value": 125, "label_key": "UI_SETTINGS_OPTION_125"},
		{"value": 150, "label_key": "UI_SETTINGS_OPTION_150"},
	]))
	table.append(SettingDefinition.choice(ASSIST_ENEMY_PACE, SettingDefinition.Group.ASSISTS, "UI_SETTINGS_ASSIST_ENEMY_PACE", 100, [
		{"value": 100, "label_key": "UI_SETTINGS_OPTION_100"},
		{"value": 85, "label_key": "UI_SETTINGS_OPTION_85"},
		{"value": 70, "label_key": "UI_SETTINGS_OPTION_70"},
	]))
	table.append(SettingDefinition.choice(ASSIST_EXTRA_COURAGE, SettingDefinition.Group.ASSISTS, "UI_SETTINGS_ASSIST_EXTRA_COURAGE", 0, [
		{"value": 0, "label_key": "UI_SETTINGS_OPTION_COURAGE_0"},
		{"value": 1, "label_key": "UI_SETTINGS_OPTION_COURAGE_1"},
		{"value": 2, "label_key": "UI_SETTINGS_OPTION_COURAGE_2"},
	]))
	table.append(SettingDefinition.toggle(ASSIST_INPUT_FORGIVENESS, SettingDefinition.Group.ASSISTS, "UI_SETTINGS_ASSIST_INPUT_FORGIVENESS", false))
	return table


## Whether the project's window starts fullscreen: the default of the Fullscreen setting is whatever the project ships,
## so the value lives in project.godot and nowhere else.
static func _ships_fullscreen() -> bool:
	var mode := int(ProjectSettings.get_setting("display/window/size/mode", Window.MODE_WINDOWED))
	return mode == Window.MODE_FULLSCREEN or mode == Window.MODE_EXCLUSIVE_FULLSCREEN
