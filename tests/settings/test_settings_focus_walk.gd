extends UnboundTest

## The settings screen is usable with the keyboard and the pad alone (docs/game-base-plan.md 9.2 "Settings", 9.4), proved with
## real key presses and not by calling the focus functions:
##   1. EVERY CONTROL IS REACHABLE, IN READING ORDER. On every page, Down from the tab bar visits the rows in the order the
##      page draws them, then the three buttons below (Controls, Restore defaults, Back); Left and Right walk the buttons;
##      Up walks all the way back to the tab bar. Nothing is skipped and nothing is out of reach (the engine's guess by
##      position skipped the language list, one switch and every button on some pages).
##   2. A LANGUAGE CHOICE KEEPS THE FOCUS. Picking another language writes the pages again in it; the drop-down that was
##      chosen from must still have focus afterwards, so Down and Up go on working (before, no key did anything until Esc).

const SettingsSupport := preload("res://tests/settings/settings_support.gd")
const ShellSupport := preload("res://tests/shell/shell_support.gd")
const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "settings_focus"


func _init() -> void:
	suite_title = "SETTINGS SCREEN FOCUS TEST"
	watchdog_seconds = 55.0
	call_deferred("_run")


func _run() -> void:
	var booted := await SettingsSupport.boot_title(self, SUITE_NAME)
	var app: AppRoot = booted["app"]
	var save_service: Node = booted["save_service"]
	var title := ShellSupport.title_of(app)
	if not _expect(title != null, "setup: the title is up"):
		finish()
		return
	title.settings_button.grab_focus()
	title.settings_button.pressed.emit()
	await process_frame
	var screen := app.settings_screen
	_expect(screen.is_open() and _focused() == screen.tabs.get_tab_bar(), "setup: the screen is open and the tab bar has the focus")

	for page: int in SettingDefinition.Group.values():
		await _walk_page(screen, page)
		if page < SettingDefinition.Group.size() - 1:
			# Back to the tab bar (Up from the first row), then Right turns the page.
			await _press_until_focused(screen.tabs.get_tab_bar(), KEY_UP)
			await ShellSupport.tap_key(self, KEY_RIGHT)

	await _language_choice_keeps_the_focus(screen, app)

	screen.close()
	Support.release_all_actions()
	Support.remove_isolated_save(save_service)
	app.queue_free()
	save_service.queue_free()
	await process_frame
	finish()


## The controls that have focus.
func _focused() -> Control:
	return root.gui_get_focus_owner()


## Presses `keycode` until `target` has the focus (at most ten presses): how a player gets back to a control.
func _press_until_focused(target: Control, keycode: Key) -> void:
	for _press in 10:
		if _focused() == target:
			return
		await ShellSupport.tap_key(self, keycode)


## Walks one page with Down, Left, Right and Up and checks every control was met in the order of the page.
func _walk_page(screen: SettingsScreen, page: int) -> void:
	var tab_bar := screen.tabs.get_tab_bar()
	var page_name := screen.tabs.get_tab_title(page)
	_expect(screen.tabs.current_tab == page and _focused() == tab_bar, "page %s: the tab bar has the focus on the page" % page_name)
	var expected_rows: Array[Control] = []
	var names: PackedStringArray = []
	for definition in GameSettings.definitions_of_group(page as SettingDefinition.Group):
		expected_rows.append(screen.control_of(definition.key))
		names.append(String(definition.key))

	var visited: Array[Control] = []
	for _step in expected_rows.size():
		await ShellSupport.tap_key(self, KEY_DOWN)
		visited.append(_focused())
	_expect(visited == expected_rows, "page %s: Down visits every row, in the order of the page (%s)" % [page_name, ", ".join(names)])
	await ShellSupport.tap_key(self, KEY_DOWN)
	_expect(_focused() == screen.controls_button, "page %s: Down after the last row reaches the Controls button" % page_name)
	await ShellSupport.tap_key(self, KEY_DOWN)
	_expect(_focused() == screen.controls_button, "page %s: and stops there" % page_name)
	await ShellSupport.tap_key(self, KEY_RIGHT)
	_expect(_focused() == screen.defaults_button, "page %s: Right reaches Restore defaults" % page_name)
	await ShellSupport.tap_key(self, KEY_RIGHT)
	_expect(_focused() == screen.back_button, "page %s: and Back" % page_name)
	await ShellSupport.tap_key(self, KEY_RIGHT)
	_expect(_focused() == screen.back_button, "page %s: Right stops at Back" % page_name)
	await ShellSupport.tap_key(self, KEY_LEFT)
	await ShellSupport.tap_key(self, KEY_LEFT)
	await ShellSupport.tap_key(self, KEY_LEFT)
	_expect(_focused() == screen.controls_button, "page %s: Left walks back to Controls and stops there" % page_name)

	await ShellSupport.tap_key(self, KEY_UP)
	_expect(_focused() == expected_rows[expected_rows.size() - 1], "page %s: Up from the buttons returns to the last row" % page_name)
	var returned: Array[Control] = []
	for _step in expected_rows.size() - 1:
		await ShellSupport.tap_key(self, KEY_UP)
		returned.append(_focused())
	returned.reverse()
	_expect(returned == expected_rows.slice(0, expected_rows.size() - 1), "page %s: Up visits the rows in reverse" % page_name)
	await ShellSupport.tap_key(self, KEY_UP)
	_expect(_focused() == tab_bar, "page %s: and then the tab bar" % page_name)
	await ShellSupport.tap_key(self, KEY_UP)
	_expect(_focused() == tab_bar, "page %s: Up stops at the tab bar" % page_name)
	# Down from the tab bar for the next walk's start is not needed: every walk starts on the tab bar.


## Chooses another language with the keys, in the drop-down, and checks the focus is still on the language row.
func _language_choice_keeps_the_focus(screen: SettingsScreen, app: AppRoot) -> void:
	screen.close()
	screen.open(SettingDefinition.Group.SCREEN)
	await process_frame
	var language_key := GameSettings.LANGUAGE
	var languages := screen.control_of(language_key) as OptionButton
	await _press_until_focused(languages, KEY_DOWN)
	_expect(_focused() == languages, "language: Down from the tab bar reaches the language drop-down")
	_expect(TextService.language() == TextService.SOURCE_LANGUAGE, "setup: the game speaks English")

	# Opens the list, moves to the next language and takes it, the way a player does.
	await ShellSupport.tap_key(self, KEY_ENTER)
	await ShellSupport.tap_key(self, KEY_DOWN)
	await ShellSupport.tap_key(self, KEY_ENTER)
	await process_frame
	var chosen := String(app.settings.value(language_key))
	_expect(chosen != "en" and TextService.language() == StringName(chosen), "language: the keys chose another language (%s)" % chosen)
	var languages_now := screen.control_of(language_key) as OptionButton
	_expect(languages_now != null and languages_now.is_visible_in_tree(), "language: the page was written again in it and has its language row")
	_expect(_focused() == languages_now, "language: and the language row has the focus (%s)" % [_focused()])

	var next_control := screen.control_of(GameSettings.UI_HIGH_CONTRAST)
	await ShellSupport.tap_key(self, KEY_DOWN)
	_expect(_focused() == next_control, "language: Down still moves on to the next row")
	await ShellSupport.tap_key(self, KEY_UP)
	_expect(_focused() == languages_now, "language: and Up comes back")

	# A language chosen with the mouse or from elsewhere keeps the focus of whatever had it too: the tab bar.
	await _press_until_focused(screen.tabs.get_tab_bar(), KEY_UP)
	app.settings.set_value(language_key, "en")
	await process_frame
	_expect(TextService.language() == TextService.SOURCE_LANGUAGE and _focused() == screen.tabs.get_tab_bar(), "a language changed from elsewhere leaves the focus on the tab bar")
