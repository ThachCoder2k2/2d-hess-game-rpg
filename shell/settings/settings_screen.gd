class_name SettingsScreen
extends Control

## The settings screen (docs/game-base-plan.md 9.2 "Settings"): a modal laid over the title or the pause menu, four pages
## (Sound, Screen, Comfort, Assists) with a row for every setting of the table (GameSettings.definitions()): a slider for a
## volume or the shake scale, a switch for a yes-or-no, a drop-down for a choice of a few values and for the language.
## Nothing here knows a setting: the rows are built from each SettingDefinition (its kind, range, options and the key of
## its name), so a new setting is a new row of the table and shows up on its page by itself.
##
## It EDITS a GameSettings object and does nothing else: a control writes its value with `settings.set_value()`, and the
## appliers (SettingsApplier for the app, SettingsBridge for the room) make the value true because they listen to the
## object. A change made elsewhere (F11, Restore defaults) reaches the controls the same way, through `changed`. So a
## slider moved on this screen is heard at once, and what the screen shows is always what the settings hold.
##
## Keyboard and pad: the tab bar takes focus first (left and right turn the pages), down goes into the page, the
## engine's ui_left and ui_right move a slider, ui_accept flips a switch or opens a drop-down, and Esc, Start or B close
## the screen (a drop-down that is open takes the key first). The mouse works as on any control. The Controls button
## asks for the Controls panel (AppRoot lays it over this screen), and Restore defaults puts every setting back.
## Down and up walk the rows of the page in the order they are drawn, from the tab bar to the three buttons below, and
## left and right walk the buttons: the neighbours are set here (_wire_focus) and not left to the engine's guess by
## position, which skipped rows and left buttons out of reach.
##
## A setting no system reads yet (SettingDefinition.coming_later) says "(coming later)" beside its row.
##
## The words are text keys: the rows are written again when the language changes, since a drop-down's items and a
## slider's percent are words a script put there.

## The screen was closed.
signal closed
## The Controls button was pressed: the owner of the screen opens the Controls panel over it.
signal controls_requested

## The text keys of the page tabs, by group.
const GROUP_TAB_KEYS := {
	SettingDefinition.Group.SOUND: "UI_SETTINGS_TAB_SOUND",
	SettingDefinition.Group.SCREEN: "UI_SETTINGS_TAB_SCREEN",
	SettingDefinition.Group.COMFORT: "UI_SETTINGS_TAB_COMFORT",
	SettingDefinition.Group.ASSISTS: "UI_SETTINGS_TAB_ASSISTS",
}
## The line at the top of the Assists page: the choice is the player's.
const ASSIST_NOTE_KEY := "UI_SETTINGS_ASSIST_NOTE"
## The note beside a row whose setting does nothing yet.
const COMING_LATER_KEY := "UI_SETTINGS_COMING_LATER"
## The width of the name column and of the control column of a row, so the rows line up.
const NAME_COLUMN_WIDTH := 210.0
const CONTROL_COLUMN_WIDTH := 150.0
const ROW_FONT_SIZE := 12

## The pages.
@export var tabs: TabContainer
## Closes the screen.
@export var back_button: Button
## Asks for the Controls panel.
@export var controls_button: Button
## Puts every setting back to its default.
@export var defaults_button: Button
## The container of the buttons and the pages; switched off while a panel is laid over the screen.
@export var content: Control

## The settings the screen edits (the object AppRoot owns).
var settings: GameSettings = null

## setting key -> the control that holds its value on screen.
var _control_by_key: Dictionary[StringName, Control] = {}
## setting key -> the label that shows a slider's percent.
var _percent_label_by_key: Dictionary[StringName, Label] = {}
## The control that had focus when the screen opened, to give it back.
var _focus_before_open: Control = null
## While the controls are being set from the settings (not by the player) they must not write back.
var _refreshing := false
## While the pages are being built again, the tab changes that come with it must not set the focus neighbours.
var _rebuilding := false
var _live_text := LiveText.new()


func _ready() -> void:
	visible = false
	back_button.pressed.connect(close)
	controls_button.pressed.connect(func() -> void: controls_requested.emit())
	defaults_button.pressed.connect(_on_defaults_pressed)
	tabs.tab_changed.connect(_on_tab_changed)
	add_child(_live_text)
	_live_text.on_language_change(_on_language_changed)


## Hands the screen the settings it edits.
func configure(edited_settings: GameSettings) -> void:
	if settings != null and settings.changed.is_connected(_on_settings_changed):
		settings.changed.disconnect(_on_settings_changed)
	settings = edited_settings
	settings.changed.connect(_on_settings_changed)


## Builds the pages from the table and shows the screen on `group`'s page.
func open(group := SettingDefinition.Group.SOUND) -> void:
	_focus_before_open = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	rebuild()
	tabs.current_tab = group
	visible = true
	tabs.get_tab_bar().grab_focus()


## Hides the screen and gives focus back.
func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()
	if is_instance_valid(_focus_before_open) and _focus_before_open.is_visible_in_tree():
		_focus_before_open.grab_focus()
	_focus_before_open = null


## Whether the screen is on screen.
func is_open() -> bool:
	return visible


## A panel is laid over the screen (Controls): its controls go quiet so a key or the mouse reaches only the panel.
func set_covered(covered: bool) -> void:
	content.process_mode = Node.PROCESS_MODE_DISABLED if covered else Node.PROCESS_MODE_INHERIT


## The control that sets `key` (a HSlider, CheckButton or OptionButton), null for a key that is not on show.
func control_of(key: StringName) -> Control:
	return _control_by_key.get(key)


## The label that shows the percent of a slider setting, null for a setting that is not a slider.
func percent_label_of(key: StringName) -> Label:
	return _percent_label_by_key.get(key)


## The page (tab index) `key` is on, -1 for a key that is not on show.
func page_of(key: StringName) -> int:
	var control := control_of(key)
	if control == null:
		return -1
	var node: Node = control
	while node != null and node.get_parent() != tabs:
		node = node.get_parent()
	return node.get_index() if node != null else -1


## Builds the pages again from the table: one page per group, one row per setting, the controls set to the settings'
## values. Keeps the page the player was on and the control that had focus (the language drop-down, whose choice is what
## calls for the rebuild: the old control goes away with the page, and without this the keys would find no focus).
func rebuild() -> void:
	var page_on_show := maxi(tabs.current_tab, 0)
	var key_in_focus := _key_in_focus()
	_rebuilding = true
	for page in tabs.get_children():
		tabs.remove_child(page)
		page.queue_free()
	_control_by_key.clear()
	_percent_label_by_key.clear()
	for group: int in SettingDefinition.Group.values():
		var page := VBoxContainer.new()
		page.add_theme_constant_override(&"separation", 6)
		page.name = SettingDefinition.Group.keys()[group].capitalize()
		tabs.add_child(page)
		tabs.set_tab_title(tabs.get_tab_count() - 1, TextService.t(GROUP_TAB_KEYS[group]))
		if group == SettingDefinition.Group.ASSISTS:
			page.add_child(_note_label(ASSIST_NOTE_KEY))
		for definition in GameSettings.definitions_of_group(group):
			page.add_child(_row_of(definition))
	tabs.current_tab = clampi(page_on_show, 0, tabs.get_tab_count() - 1)
	_rebuilding = false
	_refresh_controls()
	_wire_focus()
	if key_in_focus != &"":
		_restore_focus.call_deferred(key_in_focus)


## Gives focus back to the control of `key` once the new page is on show (the tab container shows a page after the
## frame's changes), unless the player or the screen has put the focus somewhere in the meantime.
func _restore_focus(key: StringName) -> void:
	var control_to_focus := control_of(key)
	if control_to_focus == null or not control_to_focus.is_visible_in_tree() or get_viewport().gui_get_focus_owner() != null:
		return
	control_to_focus.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause")):
		get_viewport().set_input_as_handled()
		close()


func _on_tab_changed(_tab: int) -> void:
	if not _rebuilding:
		_wire_focus()


## The setting whose control has focus, &"" when focus is elsewhere (the tab bar, a button) or nowhere.
func _key_in_focus() -> StringName:
	if not is_inside_tree():
		return &""
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null:
		return &""
	for key: StringName in _control_by_key:
		if _control_by_key[key] == focused:
			return key
	return &""


## Sets the focus neighbours of the page on show: the tab bar -> the rows in order -> Controls, and left and right along
## the three buttons. A switch and a drop-down keep left and right to themselves (a slider uses them to move), so a key
## never jumps to another row. Done again whenever the page changes or is built, since only the rows of the page on
## show can take focus.
func _wire_focus() -> void:
	if tabs.current_tab < 0:
		return
	var tab_bar := tabs.get_tab_bar()
	var rows: Array[Control] = []
	for definition in GameSettings.definitions_of_group(tabs.current_tab as SettingDefinition.Group):
		var control := control_of(definition.key)
		if control != null:
			rows.append(control)
	var buttons: Array[Control] = [controls_button, defaults_button, back_button]
	_link(tab_bar, SIDE_TOP, tab_bar)
	_link(tab_bar, SIDE_LEFT, tab_bar)
	_link(tab_bar, SIDE_RIGHT, tab_bar)
	_link(tab_bar, SIDE_BOTTOM, rows[0] if not rows.is_empty() else controls_button)
	for index in rows.size():
		_link(rows[index], SIDE_TOP, rows[index - 1] if index > 0 else tab_bar)
		_link(rows[index], SIDE_BOTTOM, rows[index + 1] if index < rows.size() - 1 else controls_button)
		_link(rows[index], SIDE_LEFT, rows[index])
		_link(rows[index], SIDE_RIGHT, rows[index])
	for index in buttons.size():
		_link(buttons[index], SIDE_TOP, rows[rows.size() - 1] if not rows.is_empty() else tab_bar)
		_link(buttons[index], SIDE_BOTTOM, buttons[index])
		_link(buttons[index], SIDE_LEFT, buttons[maxi(index - 1, 0)])
		_link(buttons[index], SIDE_RIGHT, buttons[mini(index + 1, buttons.size() - 1)])


func _link(from: Control, side: Side, to: Control) -> void:
	from.set_focus_neighbor(side, from.get_path_to(to))


func _on_language_changed() -> void:
	if visible:
		rebuild()


func _on_settings_changed() -> void:
	if visible:
		_refresh_controls()


func _on_defaults_pressed() -> void:
	settings.reset_to_defaults()


## One row: the name and its control (a switch carries its own name).
func _row_of(definition: SettingDefinition) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	match definition.kind:
		SettingDefinition.Kind.TOGGLE:
			var check := CheckButton.new()
			check.text = TextService.t(definition.label_key)
			check.add_theme_font_size_override(&"font_size", ROW_FONT_SIZE)
			check.toggled.connect(func(on: bool) -> void: _write(definition.key, on))
			row.add_child(check)
			_control_by_key[definition.key] = check
			_add_coming_later_note(row, definition)
		SettingDefinition.Kind.SLIDER:
			row.add_child(_name_label(definition))
			var slider := HSlider.new()
			slider.min_value = definition.minimum
			slider.max_value = definition.maximum
			slider.step = definition.step
			slider.custom_minimum_size = Vector2(CONTROL_COLUMN_WIDTH, 16.0)
			slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			slider.scrollable = false
			slider.value_changed.connect(func(amount: float) -> void: _write(definition.key, amount))
			row.add_child(slider)
			var percent_label := Label.new()
			percent_label.add_theme_font_size_override(&"font_size", ROW_FONT_SIZE)
			percent_label.custom_minimum_size.x = 40.0
			row.add_child(percent_label)
			_control_by_key[definition.key] = slider
			_percent_label_by_key[definition.key] = percent_label
		SettingDefinition.Kind.CHOICE:
			row.add_child(_name_label(definition))
			var options := _option_button()
			for option in definition.choices:
				options.add_item(TextService.t(String(option["label_key"])))
			options.item_selected.connect(func(index: int) -> void: _write(definition.key, definition.choices[index]["value"]))
			row.add_child(options)
			_control_by_key[definition.key] = options
			_add_coming_later_note(row, definition)
		SettingDefinition.Kind.LANGUAGE:
			row.add_child(_name_label(definition))
			var languages := _option_button()
			for code in TextService.languages():
				languages.add_item(TextService.language_name(code))
				languages.set_item_metadata(languages.item_count - 1, String(code))
			languages.item_selected.connect(func(index: int) -> void: _write(definition.key, String(languages.get_item_metadata(index))))
			row.add_child(languages)
			_control_by_key[definition.key] = languages
	return row


## "(coming later)" at the end of the row of a setting no system reads yet (nothing for a setting that works).
func _add_coming_later_note(row: Control, definition: SettingDefinition) -> void:
	if not definition.coming_later:
		return
	var note := Label.new()
	note.text = TextService.t(COMING_LATER_KEY)
	note.add_theme_font_size_override(&"font_size", ROW_FONT_SIZE)
	row.add_child(note)


func _name_label(definition: SettingDefinition) -> Label:
	var name_label := Label.new()
	name_label.text = TextService.t(definition.label_key)
	name_label.custom_minimum_size.x = NAME_COLUMN_WIDTH
	name_label.add_theme_font_size_override(&"font_size", ROW_FONT_SIZE)
	return name_label


func _note_label(text_key: String) -> Label:
	var note := Label.new()
	note.text = TextService.t(text_key)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = NAME_COLUMN_WIDTH + CONTROL_COLUMN_WIDTH + 50.0
	note.add_theme_font_size_override(&"font_size", ROW_FONT_SIZE)
	return note


func _option_button() -> OptionButton:
	var options := OptionButton.new()
	options.custom_minimum_size.x = CONTROL_COLUMN_WIDTH
	options.add_theme_font_size_override(&"font_size", ROW_FONT_SIZE)
	options.fit_to_longest_item = false
	return options


## A control was changed by the player: the settings take the value.
func _write(key: StringName, new_value: Variant) -> void:
	if not _refreshing and settings != null:
		settings.set_value(key, new_value)
	_show_percent_of(key)


## Sets every control to what the settings hold, without writing it back.
func _refresh_controls() -> void:
	if settings == null:
		return
	_refreshing = true
	for key: StringName in _control_by_key:
		var control := _control_by_key[key]
		var value: Variant = settings.value(key)
		if control is HSlider:
			(control as HSlider).value = float(value)
		elif control is CheckButton:
			(control as CheckButton).button_pressed = bool(value)
		elif control is OptionButton:
			_select_in(control as OptionButton, key, value)
		_show_percent_of(key)
	_refreshing = false


func _select_in(options: OptionButton, key: StringName, value: Variant) -> void:
	var definition := GameSettings.definition_of(key)
	if definition.kind == SettingDefinition.Kind.LANGUAGE:
		for index in options.item_count:
			if String(options.get_item_metadata(index)) == String(value):
				options.select(index)
				return
		return
	for index in definition.choices.size():
		if typeof(definition.choices[index]["value"]) == typeof(value) and definition.choices[index]["value"] == value:
			options.select(index)
			return


func _show_percent_of(key: StringName) -> void:
	if not _percent_label_by_key.has(key) or settings == null:
		return
	var amount := roundi(float(settings.value(key)) * 100.0)
	_percent_label_by_key[key].text = TextService.t("UI_SETTINGS_PERCENT", {"value": amount})
