extends UnboundTest

## The Fullscreen setting puts the game's window in fullscreen or in a window (docs/game-base-plan.md 9.2), and F11 and the
## setting agree:
##   - the applier sets the mode of the window it is given (a headless run cannot show a mode on the real window, which
##     always reads windowed, so a Window that is not in the tree stands in: it keeps the mode it is given);
##   - on the real AppRoot, changing the setting reaches the applier's window, and the applier is made for the game's own;
##   - a window already in the wanted mode is left alone, and a window that is fullscreen another way stays so.
## (F11 sets the window and then writes what the window really does into the setting, in ShellKeys; a headless run cannot
## show a mode on the real window, so that one line is not driven here.)

const SettingsSupport := preload("res://tests/settings/settings_support.gd")
const SUITE_NAME := "setting_fullscreen"


func _init() -> void:
	suite_title = "SETTING FULLSCREEN TEST"
	call_deferred("_run")


func _run() -> void:
	_the_applier_sets_the_window()
	var booted := await SettingsSupport.boot_title(self, SUITE_NAME)
	var app: AppRoot = booted["app"]
	_expect(app.settings_applier.window == app.get_window(), "the app's applier is made for the game's own window")
	var stand_in := Window.new()
	app.settings_applier.window = stand_in
	stand_in.mode = Window.MODE_FULLSCREEN
	_expect(app.settings.value(GameSettings.FULLSCREEN) == true, "setup: the game ships fullscreen, so the setting starts on (project.godot)")
	app.settings.set_value(GameSettings.FULLSCREEN, false)
	_expect(stand_in.mode == Window.MODE_WINDOWED, "switching Fullscreen off on the app reaches the window: it becomes a window")
	app.settings.set_value(GameSettings.FULLSCREEN, true)
	_expect(stand_in.mode == Window.MODE_FULLSCREEN, "and switching it on makes it fullscreen")
	stand_in.free()
	app.settings_applier.window = app.get_window()
	SettingsSupport.Support.end_suite(self, booted["save_service"])


func _the_applier_sets_the_window() -> void:
	var window := Window.new()
	var applier := SettingsApplier.new(window, null)
	var settings := GameSettings.new()
	settings.set_value(GameSettings.FULLSCREEN, true)
	applier.apply_fullscreen(settings)
	_expect(window.mode == Window.MODE_FULLSCREEN and SettingsApplier.is_fullscreen(window), "Fullscreen on: the window is fullscreen")
	settings.set_value(GameSettings.FULLSCREEN, false)
	applier.apply_fullscreen(settings)
	_expect(window.mode == Window.MODE_WINDOWED and not SettingsApplier.is_fullscreen(window), "Fullscreen off: the window is a window")
	window.mode = Window.MODE_MAXIMIZED
	applier.apply_fullscreen(settings)
	_expect(window.mode == Window.MODE_MAXIMIZED, "a window already out of fullscreen is left as it is (maximised stays maximised)")
	window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	settings.set_value(GameSettings.FULLSCREEN, true)
	applier.apply_fullscreen(settings)
	_expect(window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN, "and exclusive fullscreen counts as fullscreen: it is not replaced")
	window.free()
	SettingsApplier.new(null, null).apply_fullscreen(settings)
	_expect(true, "an applier with no window does nothing and does not fail")
