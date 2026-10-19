class_name SettingDefinition
extends RefCounted

## One setting of the settings screen, as data (docs/game-base-plan.md 9.2 "Settings"): its key, what kind of control
## sets it, which page it is on, the key of its name, its default and what values it may hold. GameSettings keeps the
## table; the settings screen builds a row from each entry, the profile file stores each one under its key, and a stored
## value that does not fit its definition is replaced by the default. Nothing else knows a setting's range, so a new
## setting is one entry here, one row in ui.po and the line that makes it do something.

## How the player sets it.
enum Kind {
	## A number from `minimum` to `maximum` (a volume, the shake scale): a slider.
	SLIDER,
	## On or off: a check box.
	TOGGLE,
	## One of a short list (`choices`): a drop-down.
	CHOICE,
	## One of the languages the game has words for (the list is the game's, not this table's): a drop-down.
	LANGUAGE,
}

## The pages of the settings screen, in tab order.
enum Group {
	SOUND,
	SCREEN,
	COMFORT,
	ASSISTS,
}

## The key the value is stored under (and the name tests and bridges use).
var key: StringName = &""
var kind := Kind.TOGGLE
var group := Group.COMFORT
## The text key of the setting's name on its row.
var label_key := ""
## The value a player who never opened the screen has.
var default_value: Variant = false
## A SLIDER's limits and the step the slider moves by.
var minimum := 0.0
var maximum := 1.0
var step := 0.05
## A CHOICE's options, each { "value": the stored value, "label_key": the text key of what the player reads }.
var choices: Array[Dictionary] = []
## The setting is stored and shown, but no system of the game reads its value yet, so choosing it changes nothing the
## player can feel. The screen says "(coming later)" beside it (the way the Controls panel does for an action that does
## nothing yet, ControlsCatalog.COMING_LATER_ACTIONS). It is set where the table is built and leaves with the milestone
## that gives the setting its job; `test_settings_coming_later` fails when the mark and the code disagree.
var coming_later := false


static func slider(setting_key: StringName, setting_group: Group, name_key: String, default_amount: float, lowest := 0.0, highest := 1.0, slider_step := 0.05) -> SettingDefinition:
	var definition := SettingDefinition.new()
	definition.key = setting_key
	definition.kind = Kind.SLIDER
	definition.group = setting_group
	definition.label_key = name_key
	definition.default_value = default_amount
	definition.minimum = lowest
	definition.maximum = highest
	definition.step = slider_step
	return definition


static func toggle(setting_key: StringName, setting_group: Group, name_key: String, default_on: bool, does_nothing_yet := false) -> SettingDefinition:
	var definition := SettingDefinition.new()
	definition.key = setting_key
	definition.kind = Kind.TOGGLE
	definition.group = setting_group
	definition.label_key = name_key
	definition.default_value = default_on
	definition.coming_later = does_nothing_yet
	return definition


static func choice(setting_key: StringName, setting_group: Group, name_key: String, default_choice: Variant, options: Array[Dictionary], does_nothing_yet := false) -> SettingDefinition:
	var definition := SettingDefinition.new()
	definition.key = setting_key
	definition.kind = Kind.CHOICE
	definition.group = setting_group
	definition.label_key = name_key
	definition.default_value = default_choice
	definition.choices = options
	definition.coming_later = does_nothing_yet
	return definition


static func language(setting_key: StringName, setting_group: Group, name_key: String, default_code: String) -> SettingDefinition:
	var definition := SettingDefinition.new()
	definition.key = setting_key
	definition.kind = Kind.LANGUAGE
	definition.group = setting_group
	definition.label_key = name_key
	definition.default_value = default_code
	return definition


## The value in the form this definition stores it (a slider holds a float, even when an int was handed in), or the
## value unchanged when it does not fit (problems_with says so).
func coerce(value: Variant) -> Variant:
	if kind == Kind.SLIDER and (value is int or value is float):
		return float(value)
	return value


## Why `value` cannot be this setting's value, "" when it can. A reason is a sentence for the log.
func problems_with(value: Variant) -> String:
	match kind:
		Kind.SLIDER:
			if not (value is float or value is int):
				return "expected a number, found %s" % _describe(value)
			var amount := float(value)
			if is_nan(amount) or amount < minimum or amount > maximum:
				return "%s is outside %s to %s" % [amount, minimum, maximum]
		Kind.TOGGLE:
			if not value is bool:
				return "expected true or false, found %s" % _describe(value)
		Kind.CHOICE:
			for option in choices:
				if typeof(option["value"]) == typeof(value) and option["value"] == value:
					return ""
			return "%s is not one of %s" % [_describe(value), _describe_choices()]
		Kind.LANGUAGE:
			if not (value is String and not String(value).is_empty()):
				return "expected a language code, found %s" % _describe(value)
	return ""


## The text key of the option holding `value`, "" for a value that is not an option.
func label_key_of_choice(value: Variant) -> String:
	for option in choices:
		if typeof(option["value"]) == typeof(value) and option["value"] == value:
			return String(option["label_key"])
	return ""


func _describe(value: Variant) -> String:
	return "%s (%s)" % [str(value), type_string(typeof(value))]


func _describe_choices() -> String:
	var values: Array[String] = []
	for option in choices:
		values.append(str(option["value"]))
	return "[%s]" % ", ".join(PackedStringArray(values))
