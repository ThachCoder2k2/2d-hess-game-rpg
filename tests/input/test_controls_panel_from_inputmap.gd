extends UnboundTest

## The Controls panel is built from the live InputMap (docs/game-base-plan.md 9.2, M4 acceptance
## `test_controls_panel_from_inputmap`), not typed:
##   - every action the InputMap has is on a page (but the engine's ui_ ones and the hidden skill slots), with its keyboard
##     and its gamepad controls in two columns; the catalog is complete (no action falls to the "own name" row);
##   - a binding added to the InputMap shows up the next time the panel opens, and so does an action nobody listed;
##   - the child's key, R, says "(coming later)" (D-18 and the owner's rule) and Strike does not;
##   - Esc, Start, B or the Back button close it, and the pause menu is reachable-and-restored around it.

const Support := preload("res://tests/bridge/bridge_support.gd")
const ShellSupport := preload("res://tests/shell/shell_support.gd")
const SUITE_NAME := "controls_panel"
const PANEL_SCENE := "res://presentation/ui/controls/controls_panel.tscn"

var panel: ControlsPanel
var finder := InputGlyphs.new("user://glyphs_that_are_not_there")


func _init() -> void:
	suite_title = "CONTROLS PANEL FROM INPUTMAP TEST"
	watchdog_seconds = 40.0
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_the_catalog_is_complete()
	await _the_panel_lists_the_inputmap()
	await _a_changed_inputmap_changes_the_panel()
	_it_closes_the_ways_a_player_closes_it()
	panel.get_parent().queue_free()
	await _it_opens_from_the_pause_menu_and_gives_it_back()
	finish()


func _the_catalog_is_complete() -> void:
	_expect(ControlsCatalog.unlisted_actions().is_empty(), "the catalog has a row for every action of the InputMap (unlisted: %s)" % [ControlsCatalog.unlisted_actions()])
	var missing_names := PackedStringArray()
	for row in ControlsCatalog.ACTIONS:
		if not InputMap.has_action(row["action"]):
			missing_names.append("%s is not an InputMap action" % row["action"])
		if not TextService.has_key(row["name_key"]):
			missing_names.append("%s has no text" % row["name_key"])
	for action in ControlsCatalog.COMING_LATER_ACTIONS + ControlsCatalog.HIDDEN_ACTIONS:
		if not InputMap.has_action(action):
			missing_names.append("%s (coming later or hidden) is not an InputMap action" % action)
	_expect(missing_names.is_empty(), "every catalog row names a real action and has its words (%s)" % "; ".join(missing_names))
	_expect(&"call_child" in ControlsCatalog.COMING_LATER_ACTIONS, "the child's action is marked as coming later")
	_expect(&"attack" not in ControlsCatalog.COMING_LATER_ACTIONS and &"move_up" not in ControlsCatalog.COMING_LATER_ACTIONS, "and Strike and the steps are not")


func _the_panel_lists_the_inputmap() -> void:
	var holder := Control.new()
	root.add_child(holder)
	panel = (load(PANEL_SCENE) as PackedScene).instantiate() as ControlsPanel
	holder.add_child(panel)
	panel.configure(finder, null)
	_expect(not panel.is_open(), "setup: the panel starts closed")
	panel.open()
	_expect(panel.is_open() and panel.tabs.get_tab_count() == ControlsCatalog.Group.size(), "opening it shows %d pages" % ControlsCatalog.Group.size())
	var expected: Array[StringName] = []
	for action in InputMap.get_actions():
		if not String(action).begins_with("ui_") and action not in ControlsCatalog.HIDDEN_ACTIONS:
			expected.append(action)
	var shown := panel.actions_on_show()
	var absent := PackedStringArray()
	for action in expected:
		if action not in shown:
			absent.append(String(action))
	_expect(absent.is_empty(), "every InputMap action but the engine's and the hidden slots is on a page (absent: %s)" % ", ".join(absent))
	_expect(shown.size() == expected.size(), "and nothing else is (%d shown, %d expected)" % [shown.size(), expected.size()])
	_expect(&"ui_accept" not in shown and &"skill_slot_3" not in shown, "the engine's menu actions and the unused slots are not listed")

	_expect(panel.strip_of(&"attack", InputGlyphs.Device.KEYBOARD).words_on_show() == "[Space] [K]", "Strike's keyboard column reads the InputMap: Space and K (%s)" % panel.strip_of(&"attack", InputGlyphs.Device.KEYBOARD).words_on_show())
	_expect(panel.strip_of(&"attack", InputGlyphs.Device.GAMEPAD).words_on_show() == "[A]", "and its gamepad column A")
	_expect(panel.strip_of(&"move_up", InputGlyphs.Device.KEYBOARD).glyphs_on_show.size() == 2, "a step up has its two keys")
	_expect(panel.strip_of(&"move_up", InputGlyphs.Device.GAMEPAD).glyphs_on_show.size() == 2, "and its two pad controls (the stick and the d-pad)")
	_expect(panel.strip_of(&"call_child", InputGlyphs.Device.KEYBOARD).words_on_show() == "[R]" and panel.strip_of(&"call_child", InputGlyphs.Device.GAMEPAD).words_on_show() == "[RB]", "the child is R on the keyboard and RB on the pad (D-18)")
	_expect(panel.name_text_of(&"call_child") == "Call the child (coming later)", "and the panel says it is coming later (%s)" % panel.name_text_of(&"call_child"))
	_expect(panel.name_text_of(&"attack") == "Strike", "Strike is just Strike (%s)" % panel.name_text_of(&"attack"))
	_expect(panel.strip_of(&"free_step", InputGlyphs.Device.GAMEPAD).words_on_show() == "-", "an action with no pad control has the empty cell")
	_expect(panel.strip_of(&"no_such_action", InputGlyphs.Device.KEYBOARD) == null, "an action not on show has no strip")


func _a_changed_inputmap_changes_the_panel() -> void:
	var extra_key := InputEventKey.new()
	extra_key.physical_keycode = KEY_T
	InputMap.action_add_event(&"attack", extra_key)
	InputMap.add_action(&"test_only_new_action")
	var new_key := InputEventKey.new()
	new_key.physical_keycode = KEY_Y
	InputMap.action_add_event(&"test_only_new_action", new_key)
	panel.open()
	_expect(panel.strip_of(&"attack", InputGlyphs.Device.KEYBOARD).words_on_show() == "[Space] [K] [T]", "a key added to Strike in the InputMap shows the next time the panel opens (%s)" % panel.strip_of(&"attack", InputGlyphs.Device.KEYBOARD).words_on_show())
	_expect(&"test_only_new_action" in panel.actions_on_show(), "an action nobody listed still appears")
	_expect(panel.name_text_of(&"test_only_new_action") == "test_only_new_action", "under its own name")
	_expect(ControlsCatalog.unlisted_actions() == [&"test_only_new_action"], "and the catalog's check names it, so a row gets written")
	InputMap.erase_action(&"test_only_new_action")
	InputMap.action_erase_event(&"attack", extra_key)
	panel.open()
	_expect(panel.strip_of(&"attack", InputGlyphs.Device.KEYBOARD).words_on_show() == "[Space] [K]" and &"test_only_new_action" not in panel.actions_on_show(), "take them away and the panel is as it was")
	panel.tabs.current_tab = 1
	panel.rebuild()
	_expect(panel.tabs.current_tab == 1, "a rebuild keeps the page the player was on")


func _it_closes_the_ways_a_player_closes_it() -> void:
	var closed_count := [0]
	panel.closed.connect(func() -> void: closed_count[0] += 1)
	for closing_action in [&"ui_cancel", &"pause"]:
		panel.open()
		var press := InputEventAction.new()
		press.action = closing_action
		press.pressed = true
		panel._unhandled_input(press)
		_expect(not panel.is_open(), "%s closes the panel" % closing_action)
	panel.open()
	panel.back_button.pressed.emit()
	_expect(not panel.is_open() and closed_count[0] == 3, "and so does Back; each close says so once (%d)" % closed_count[0])
	var ignored := InputEventAction.new()
	ignored.action = &"attack"
	ignored.pressed = true
	panel.open()
	panel._unhandled_input(ignored)
	_expect(panel.is_open(), "another key does not")
	panel.close()


func _it_opens_from_the_pause_menu_and_gives_it_back() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	var app := await ShellSupport.boot_into_t4(self, save_service)
	var flow := app.game_flow
	Support.player_health(ShellSupport.game_of(app)).invulnerable_left = 100000.0
	_expect(flow.request_pause() and app.pause_menu.is_open(), "setup: the pause menu is up")
	_expect(app.pause_menu.controls_button.visible and not app.controls_panel.is_open(), "it has a Controls entry, and the panel is closed")
	app.pause_menu.controls_button.grab_focus()
	app.pause_menu.controls_button.pressed.emit()
	_expect(app.controls_panel.is_open(), "Controls opens the panel over the menu")
	_expect(app.pause_menu.menu.process_mode == Node.PROCESS_MODE_DISABLED, "and the menu's buttons go quiet under it")
	_expect(app.controls_panel.glyphs == app.input_glyphs and app.controls_panel.last_input_device == app.last_input_device, "the panel shares the app's glyph finder and device tracker")
	await ShellSupport.tap_key(self, KEY_ESCAPE)
	_expect(not app.controls_panel.is_open() and flow.state == GameFlow.State.PAUSED and app.pause_menu.is_open(), "Esc closes the panel only: the pause menu is still up and the game still paused")
	_expect(app.pause_menu.menu.process_mode == Node.PROCESS_MODE_INHERIT and app.pause_menu.controls_button.has_focus(), "the menu's buttons are live again and focus is back on Controls")
	await ShellSupport.tap_key(self, KEY_ESCAPE)
	_expect(flow.state == GameFlow.State.PLAYING and not app.pause_menu.is_open(), "the next Esc resumes")
	Support.end_suite(self, save_service)
