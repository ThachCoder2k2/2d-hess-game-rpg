extends UnboundTest

## The pause menu's Assist options entry (docs/game-base-plan.md 9.2, D-22: "a persistent 'Assist options' entry exists in
## the Pause menu from the first run"; 5.8: opt-in, neutral names, never silent):
##   - a brand-new run, started with New Game on a profile that has never held a setting, already has the entry when it
##     is paused (it is not something the game offers after trouble: it is always there);
##   - it opens the settings screen on its ASSISTS page, over the menu, whose buttons go quiet;
##   - the page holds exactly the four assists, all at the standard game, with the note that the choice is the player's;
##   - choosing one on that page reaches the world that is waiting behind the menu, and Esc comes back to the menu.

const SettingsSupport := preload("res://tests/settings/settings_support.gd")
const ShellSupport := preload("res://tests/shell/shell_support.gd")
const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "pause_assist_options"

const ASSIST_KEYS: Array[StringName] = [GameSettings.ASSIST_TELEGRAPH_TIME, GameSettings.ASSIST_ENEMY_PACE, GameSettings.ASSIST_EXTRA_COURAGE, GameSettings.ASSIST_INPUT_FORGIVENESS]


func _init() -> void:
	suite_title = "PAUSE ASSIST OPTIONS TEST"
	watchdog_seconds = 45.0
	call_deferred("_run")


func _run() -> void:
	var booted := await SettingsSupport.boot_title(self, SUITE_NAME)
	var app: AppRoot = booted["app"]
	var save_service: Node = booted["save_service"]
	var title := ShellSupport.title_of(app)
	title.new_game_button.pressed.emit()
	await app.until_settled()
	var game := ShellSupport.game_of(app)
	if not _expect(game != null and app.game_flow.start_mode == GameFlow.StartMode.NEW_GAME, "setup: New Game brought the first room up on a clean profile"):
		Support.end_suite(self, save_service)
		return
	_expect(app.settings.to_values() == GameSettings.new().to_values(), "setup: the settings are all at their defaults, the assists included")
	ShellSupport.hold_the_game_still(app)
	Support.pump(game, 0.1)

	_expect(app.game_flow.request_pause() and app.pause_menu.is_open(), "setup: the first run is paused")
	_expect(app.pause_menu.assists_button.visible and not app.pause_menu.assists_button.disabled, "the pause menu already has Assist options, in the first run")
	app.pause_menu.assists_button.grab_focus()
	app.pause_menu.assists_button.pressed.emit()
	await process_frame
	var screen := app.settings_screen
	_expect(screen.is_open() and screen.tabs.current_tab == SettingDefinition.Group.ASSISTS, "it opens the settings screen on its Assists page")
	_expect(app.pause_menu.menu.process_mode == Node.PROCESS_MODE_DISABLED, "over the menu, whose buttons go quiet")
	var keys_on_the_page: Array[StringName] = []
	for key in ASSIST_KEYS:
		if screen.page_of(key) == SettingDefinition.Group.ASSISTS:
			keys_on_the_page.append(key)
	_expect(keys_on_the_page == ASSIST_KEYS and GameSettings.definitions_of_group(SettingDefinition.Group.ASSISTS).size() == 4, "the page holds the four assists and nothing else")
	_expect((screen.control_of(GameSettings.ASSIST_TELEGRAPH_TIME) as OptionButton).selected == 0 and not (screen.control_of(GameSettings.ASSIST_INPUT_FORGIVENESS) as CheckButton).button_pressed, "all at the standard game: nothing was switched on for the player")
	var page := screen.tabs.get_child(SettingDefinition.Group.ASSISTS)
	var note := page.get_child(0) as Label
	_expect(note != null and note.text.begins_with("Assists are never switched on for you"), "with the note that the choice is theirs (%s)" % [note.text if note != null else "none"])

	var courage := screen.control_of(GameSettings.ASSIST_EXTRA_COURAGE) as OptionButton
	courage.select(1)
	courage.item_selected.emit(1)
	Support.pump(game, 0.1)
	_expect(Support.ecs_of(game).tuning.extra_courage == 1, "choosing +1 Courage on the page reaches the world behind the menu (tuning.extra_courage is %d)" % Support.ecs_of(game).tuning.extra_courage)
	var forgiveness := screen.control_of(GameSettings.ASSIST_INPUT_FORGIVENESS) as CheckButton
	forgiveness.button_pressed = true
	Support.pump(game, 0.1)
	_expect(is_equal_approx(Support.ecs_of(game).tuning.input_buffer_window, 0.20), "and so does Input forgiveness")

	await ShellSupport.tap_key(self, KEY_ESCAPE)
	_expect(not screen.is_open() and app.pause_menu.is_open() and app.pause_menu.menu.process_mode == Node.PROCESS_MODE_INHERIT, "Esc comes back to the pause menu, live again")
	_expect(app.pause_menu.assists_button.has_focus(), "with the Assist options entry focused")
	var stored := SettingsStore.new(save_service).load_settings()
	_expect(stored.value(GameSettings.ASSIST_EXTRA_COURAGE) == 1 and stored.value(GameSettings.ASSIST_INPUT_FORGIVENESS) == true, "what was chosen is in the profile")
	Support.end_suite(self, save_service)
