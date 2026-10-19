class_name ControlsPanel
extends Control

## The Controls panel (docs/game-base-plan.md 9.2: "a panel built from the live InputMap, keyboard and pad glyphs; it
## replaces the static help line"). A modal laid over the pause menu or the settings screen: one page per kind of control
## (ControlsCatalog), one row per action, a keyboard column and a gamepad column. Every cell is read from the InputMap
## the moment the panel opens, never typed: rebind a key in project.godot and the panel says so. The pictures come from
## InputGlyphs (the owner's Kenney files) and the words stand in for any that are missing ("[Space]", "[A]").
##
## An action that does nothing yet carries "(coming later)" (ControlsCatalog.COMING_LATER_ACTIONS); the child's key, R,
## is the first (D-18).
##
## It decides nothing and is not an input handler of the game: Esc, Start or the pad's B close it (the `pause` action
## and the engine's ui_cancel), Back closes it, and `closed` says so. Focus goes back to whatever held it before.

## The panel was closed.
signal closed

## The pages.
@export var tabs: TabContainer
## Closes the panel.
@export var back_button: Button
## Where the "Back" prompt (the glyph of ui_cancel for the device in use) sits.
@export var prompt_holder: Control

## Finds the pictures. A screen that owns several prompts hands in a shared one (see configure()).
var glyphs := InputGlyphs.new()
## Which device the player used last. Null: the keyboard's glyphs for the prompt (both columns are always shown).
var last_input_device: LastInputDevice = null

## action -> { "name": Label, "keyboard": GlyphStrip, "gamepad": GlyphStrip } for the rows on show.
var _row_by_action: Dictionary[StringName, Dictionary] = {}
## The control that had focus when the panel opened, to give it back.
var _focus_before_open: Control = null
var _back_prompt := ActionPrompt.new()
var _live_text := LiveText.new()
## The page that was on show before a rebuild (a language change keeps the player where they were).
var _page_on_show := 0


func _ready() -> void:
	visible = false
	back_button.pressed.connect(close)
	prompt_holder.add_child(_back_prompt)
	add_child(_live_text)
	_live_text.on_language_change(_on_language_changed)


## Hands the panel what the app shares: the glyph finder and the last-device tracker.
func configure(glyph_source: InputGlyphs, last_device: LastInputDevice) -> void:
	glyphs = glyph_source
	last_input_device = last_device


## Reads the InputMap, builds the pages and shows the panel.
func open() -> void:
	_focus_before_open = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	_page_on_show = 0
	rebuild()
	visible = true
	tabs.get_tab_bar().grab_focus()


## Hides the panel and gives focus back.
func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()
	if is_instance_valid(_focus_before_open) and _focus_before_open.is_visible_in_tree():
		_focus_before_open.grab_focus()
	_focus_before_open = null


## Whether the panel is on screen.
func is_open() -> bool:
	return visible


## Builds the pages again from the InputMap: one grid per page, one row per listed action, plus a row for any action
## the catalog has no name for (listed on the last page under its own name).
func rebuild() -> void:
	if tabs.get_child_count() > 0:
		_page_on_show = maxi(tabs.current_tab, 0)
	for page in tabs.get_children():
		tabs.remove_child(page)
		page.queue_free()
	_row_by_action.clear()
	_back_prompt.bind(&"ui_cancel", "UI_CONTROLS_PROMPT_CLOSE", glyphs, last_input_device)
	for group: int in ControlsCatalog.TAB_KEY_BY_GROUP:
		var grid := _new_page(group)
		_add_header(grid)
		for row in ControlsCatalog.rows_of(group):
			_add_row(grid, row["action"], TextService.t(row["name_key"]))
		if group == ControlsCatalog.Group.GAME:
			for action in ControlsCatalog.unlisted_actions():
				_add_row(grid, action, String(action))
	tabs.current_tab = clampi(_page_on_show, 0, tabs.get_tab_count() - 1)


## The actions on show, in page order.
func actions_on_show() -> Array[StringName]:
	var actions: Array[StringName] = []
	for action in _row_by_action:
		actions.append(action)
	return actions


## The name the row of `action` shows ("" for an action not on show).
func name_text_of(action: StringName) -> String:
	return (_row_by_action[action]["name"] as Label).text if _row_by_action.has(action) else ""


## The strip of the keyboard column or the gamepad column of `action`'s row, null for an action not on show.
func strip_of(action: StringName, device: int) -> GlyphStrip:
	if not _row_by_action.has(action):
		return null
	return _row_by_action[action]["keyboard" if device == InputGlyphs.Device.KEYBOARD else "gamepad"]


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause")):
		get_viewport().set_input_as_handled()
		close()


func _on_language_changed() -> void:
	if visible:
		rebuild()


## A page of the tab container: a grid of three columns (the action, the keyboard, the gamepad).
func _new_page(group: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override(&"h_separation", 16)
	grid.add_theme_constant_override(&"v_separation", 4)
	grid.name = ControlsCatalog.Group.keys()[group].capitalize()
	tabs.add_child(grid)
	tabs.set_tab_title(tabs.get_tab_count() - 1, TextService.t(ControlsCatalog.TAB_KEY_BY_GROUP[group]))
	return grid


func _add_header(grid: GridContainer) -> void:
	grid.add_child(Control.new())
	grid.add_child(_text_cell("UI_CONTROLS_KEYBOARD"))
	grid.add_child(_text_cell("UI_CONTROLS_GAMEPAD"))


func _text_cell(text_key: String) -> Label:
	var cell := Label.new()
	cell.add_theme_font_size_override(&"font_size", 12)
	cell.text = TextService.t(text_key)
	return cell


func _add_row(grid: GridContainer, action: StringName, action_name: String) -> void:
	var name_label := Label.new()
	name_label.add_theme_font_size_override(&"font_size", 12)
	name_label.text = TextService.t(ControlsCatalog.COMING_LATER_KEY, {"name": action_name}) if ControlsCatalog.is_coming_later(action) else action_name
	name_label.custom_minimum_size.x = 190
	var keyboard_strip := GlyphStrip.new()
	keyboard_strip.show_glyphs(glyphs.glyphs_of_action(action, InputGlyphs.Device.KEYBOARD))
	var gamepad_strip := GlyphStrip.new()
	gamepad_strip.show_glyphs(glyphs.glyphs_of_action(action, InputGlyphs.Device.GAMEPAD))
	grid.add_child(name_label)
	grid.add_child(keyboard_strip)
	grid.add_child(gamepad_strip)
	_row_by_action[action] = {"name": name_label, "keyboard": keyboard_strip, "gamepad": gamepad_strip}
