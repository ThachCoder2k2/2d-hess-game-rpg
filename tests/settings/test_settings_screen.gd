extends UnboundTest

## The settings screen (docs/game-base-plan.md 9.2, M4 acceptance: "reachable from the title AND the pause menu"):
##   1. BUILT FROM THE TABLE. A page per group and a row per setting, the right control for each kind (a slider, a switch,
##      a drop-down, the language list), each showing what the settings hold.
##   2. TWO WAYS, ONE OBJECT. A control the player moves writes the settings (and, through the real wiring, reaches its
##      target: a volume slider moves a bus); a change made elsewhere reaches the controls; Restore defaults puts it all back;
##      a language change writes the page again in the new language.
##   3. CLOSING: Esc, Back, the pad's B and Start close it, once, and the settings are written to the profile.
##   4. REACHABLE. From the title (Settings) and from the pause menu (Settings), with whatever is under it going quiet and
##      getting its focus back; the Controls panel opens from it and sits on top of it.

const SettingsSupport := preload("res://tests/settings/settings_support.gd")
const ShellSupport := preload("res://tests/shell/shell_support.gd")
const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "settings_screen"
const SCREEN_SCENE := "res://shell/settings/settings_screen.tscn"


func _init() -> void:
	suite_title = "SETTINGS SCREEN TEST"
	watchdog_seconds = 45.0
	call_deferred("_run")


func _run() -> void:
	await _built_from_the_table()
	await _reachable_from_the_title()
	await _reachable_from_the_pause_menu()
	finish()


# --------------------------------------------------------------------------- 1 and 2 and 3: the screen alone

func _built_from_the_table() -> void:
	var settings := GameSettings.new()
	var screen := (load(SCREEN_SCENE) as PackedScene).instantiate() as SettingsScreen
	root.add_child(screen)
	screen.configure(settings)
	var closed_count := [0]
	screen.closed.connect(func() -> void: closed_count[0] += 1)
	_expect(not screen.is_open(), "setup: the screen starts closed")
	screen.open(SettingDefinition.Group.COMFORT)
	await process_frame
	_expect(screen.is_open() and screen.tabs.current_tab == SettingDefinition.Group.COMFORT, "opening it on a page shows that page")
	_expect(screen.tabs.get_tab_count() == SettingDefinition.Group.size(), "there is a page per group (%d)" % screen.tabs.get_tab_count())

	var wrong_control := PackedStringArray()
	for definition in GameSettings.definitions():
		var control := screen.control_of(definition.key)
		if control == null:
			wrong_control.append("%s has no control" % definition.key)
			continue
		var expected_type: String = {SettingDefinition.Kind.SLIDER: "HSlider", SettingDefinition.Kind.TOGGLE: "CheckButton", SettingDefinition.Kind.CHOICE: "OptionButton", SettingDefinition.Kind.LANGUAGE: "OptionButton"}[definition.kind]
		if control.get_class() != expected_type:
			wrong_control.append("%s is a %s, not a %s" % [definition.key, control.get_class(), expected_type])
		if screen.page_of(definition.key) != definition.group:
			wrong_control.append("%s is on page %d, not %d" % [definition.key, screen.page_of(definition.key), definition.group])
	_expect(wrong_control.is_empty(), "every setting has the control its kind calls for, on its page (%s)" % "; ".join(wrong_control))
	_expect((screen.control_of(GameSettings.VOLUME_MASTER) as HSlider).value == 1.0 and (screen.control_of(GameSettings.REDUCE_FLASH) as CheckButton).button_pressed == false, "the controls show the settings' values")
	_expect(screen.percent_label_of(GameSettings.VOLUME_MASTER).text == "100%", "a slider says its percent (%s)" % screen.percent_label_of(GameSettings.VOLUME_MASTER).text)
	var language_options := screen.control_of(GameSettings.LANGUAGE) as OptionButton
	_expect(language_options.item_count == TextService.languages().size() and language_options.get_item_text(language_options.selected) == "English", "the language list holds the game's languages and shows English (%s)" % language_options.get_item_text(language_options.selected))

	# The player moves a control: the settings take it.
	(screen.control_of(GameSettings.SHAKE_SCALE) as HSlider).value = 0.4
	_expect(is_equal_approx(float(settings.value(GameSettings.SHAKE_SCALE)), 0.4) and screen.percent_label_of(GameSettings.SHAKE_SCALE).text == "40%", "a slider the player moves writes the settings, and says 40%")
	(screen.control_of(GameSettings.REDUCE_FLASH) as CheckButton).button_pressed = true
	_expect(settings.value(GameSettings.REDUCE_FLASH) == true, "a switch the player turns writes the settings")
	var pace := screen.control_of(GameSettings.ASSIST_ENEMY_PACE) as OptionButton
	pace.select(2)
	pace.item_selected.emit(2)
	_expect(settings.value(GameSettings.ASSIST_ENEMY_PACE) == 70, "a drop-down the player uses writes the settings (the third option, 70)")
	var courage := screen.control_of(GameSettings.ASSIST_EXTRA_COURAGE) as OptionButton
	_expect(courage.get_item_text(0) == "Standard" and courage.get_item_text(2) == "+2 Courage", "and its options are words (%s, %s)" % [courage.get_item_text(0), courage.get_item_text(2)])
	language_options.select(language_options.item_count - 1)
	language_options.item_selected.emit(language_options.item_count - 1)
	_expect(settings.value(GameSettings.LANGUAGE) == String(TextService.languages()[language_options.item_count - 1]), "the language drop-down writes the language the player picked")
	settings.set_value(GameSettings.LANGUAGE, "en")

	# A change made elsewhere reaches the controls.
	settings.set_value(GameSettings.VOLUME_UI, 0.2)
	settings.set_value(GameSettings.HIGH_CONTRAST_DANGER, true)
	settings.set_value(GameSettings.ASSIST_TELEGRAPH_TIME, 150)
	_expect(is_equal_approx((screen.control_of(GameSettings.VOLUME_UI) as HSlider).value, 0.2) and screen.percent_label_of(GameSettings.VOLUME_UI).text == "20%", "a volume changed elsewhere moves its slider")
	_expect((screen.control_of(GameSettings.HIGH_CONTRAST_DANGER) as CheckButton).button_pressed, "a switch changed elsewhere turns on")
	_expect((screen.control_of(GameSettings.ASSIST_TELEGRAPH_TIME) as OptionButton).selected == 2, "a choice changed elsewhere is selected")

	# Restore defaults.
	screen.defaults_button.pressed.emit()
	_expect(settings.to_values() == GameSettings.new().to_values(), "Restore defaults puts every setting back")
	_expect((screen.control_of(GameSettings.SHAKE_SCALE) as HSlider).value == 1.0 and not (screen.control_of(GameSettings.REDUCE_FLASH) as CheckButton).button_pressed and (screen.control_of(GameSettings.ASSIST_ENEMY_PACE) as OptionButton).selected == 0, "and the controls show it")

	# A language change writes the page again.
	var english_title := screen.tabs.get_tab_title(0)
	TextService.install_pseudo_language()
	TextService.set_language(TextService.PSEUDO_LANGUAGE)
	await process_frame
	_expect(screen.tabs.get_tab_title(0) != english_title and (screen.control_of(GameSettings.REDUCE_FLASH) as CheckButton).text != "Reduce flashing", "a language change writes the page again in the new language (%s)" % screen.tabs.get_tab_title(0))
	_expect(screen.tabs.current_tab == SettingDefinition.Group.COMFORT, "on the page the player was on")
	TextService.set_language(TextService.SOURCE_LANGUAGE)
	await process_frame
	_expect(screen.tabs.get_tab_title(0) == english_title, "and back")

	# Closing.
	for closing_action in [&"ui_cancel", &"pause"]:
		screen.open()
		var press := InputEventAction.new()
		press.action = closing_action
		press.pressed = true
		screen._unhandled_input(press)
		_expect(not screen.is_open(), "%s closes the screen" % closing_action)
	screen.open()
	screen.back_button.pressed.emit()
	_expect(not screen.is_open() and closed_count[0] == 3, "so does Back; each close says so once (%d)" % closed_count[0])
	screen.close()
	_expect(closed_count[0] == 3, "closing a closed screen says nothing")
	screen.queue_free()


# --------------------------------------------------------------------------- 4: reachable

func _reachable_from_the_title() -> void:
	var booted := await SettingsSupport.boot_title(self, SUITE_NAME + "_title")
	var app: AppRoot = booted["app"]
	var save_service: Node = booted["save_service"]
	var title := ShellSupport.title_of(app)
	_expect(not title.settings_button.disabled, "the title offers Settings")
	title.settings_button.grab_focus()
	title.settings_button.pressed.emit()
	await process_frame
	_expect(app.settings_screen.is_open() and app.settings_screen.settings == app.settings, "Settings opens the screen, editing the app's own settings")
	_expect(title.menu.process_mode == Node.PROCESS_MODE_DISABLED, "and the title's buttons go quiet under it")

	# A real slider on the real screen moves a real bus, and the choice is written when the screen closes.
	(app.settings_screen.control_of(GameSettings.VOLUME_MASTER) as HSlider).value = 0.5
	_expect(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Master")), linear_to_db(0.5)), "a volume slider moved on the screen moves its bus")
	await ShellSupport.tap_key(self, KEY_ESCAPE)
	_expect(not app.settings_screen.is_open(), "Esc closes the screen")
	_expect(title.menu.process_mode == Node.PROCESS_MODE_INHERIT and title.settings_button.has_focus(), "the title works again and Settings has its focus back")
	var stored := SettingsStore.new(save_service).load_settings()
	_expect(is_equal_approx(float(stored.value(GameSettings.VOLUME_MASTER)), 0.5), "closing the screen wrote the settings to the profile")
	app.settings.set_value(GameSettings.VOLUME_MASTER, 1.0)
	# The next section boots its own app on its own isolated save: this one goes away first.
	Support.release_all_actions()
	Support.remove_isolated_save(save_service)
	app.queue_free()
	save_service.queue_free()
	await process_frame
	await process_frame


func _reachable_from_the_pause_menu() -> void:
	var booted := await SettingsSupport.boot_game(self, SUITE_NAME + "_pause")
	var app: AppRoot = booted["app"]
	var game: GameRoot = booted["game"]
	var save_service: Node = booted["save_service"]
	if not _expect(game != null and app.game_flow.request_pause(), "setup: the game is up and paused"):
		return
	_expect(app.pause_menu.settings_button.visible, "the pause menu offers Settings")
	app.pause_menu.settings_button.grab_focus()
	app.pause_menu.settings_button.pressed.emit()
	await process_frame
	_expect(app.settings_screen.is_open() and app.pause_menu.menu.process_mode == Node.PROCESS_MODE_DISABLED, "Settings opens the screen over the pause menu, whose buttons go quiet")
	_expect(app.game_flow.state == GameFlow.State.PAUSED and paused, "the game is still paused")

	# A setting changed here reaches the room that is waiting behind the menu.
	(app.settings_screen.control_of(GameSettings.SHAKE_SCALE) as HSlider).value = 0.5
	_expect(is_equal_approx(game.camera_bridge.shake_scale, 0.5), "a setting changed from the pause menu reaches the room behind it")

	# The Controls panel opens from the screen and sits on top of it.
	app.settings_screen.controls_button.pressed.emit()
	await process_frame
	_expect(app.controls_panel.is_open() and app.settings_screen.content.process_mode == Node.PROCESS_MODE_DISABLED, "the Controls button opens the panel over the screen, whose controls go quiet")
	await ShellSupport.tap_key(self, KEY_ESCAPE)
	_expect(not app.controls_panel.is_open() and app.settings_screen.is_open() and app.settings_screen.content.process_mode == Node.PROCESS_MODE_INHERIT, "Esc closes only the Controls panel: the settings screen is still up and live again")
	await ShellSupport.tap_key(self, KEY_ESCAPE)
	_expect(not app.settings_screen.is_open() and app.pause_menu.is_open() and app.game_flow.state == GameFlow.State.PAUSED, "the next Esc closes only the settings screen: the pause menu is still up")
	_expect(app.pause_menu.menu.process_mode == Node.PROCESS_MODE_INHERIT and app.pause_menu.settings_button.has_focus(), "its buttons are live and Settings has its focus back")
	await ShellSupport.tap_key(self, KEY_ESCAPE)
	_expect(app.game_flow.state == GameFlow.State.PLAYING, "and the next Esc resumes the game")
	Support.end_suite(self, save_service)
