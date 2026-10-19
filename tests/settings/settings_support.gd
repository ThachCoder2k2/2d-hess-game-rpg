extends RefCounted

## Shared by the suites that prove each setting reaches its target (tests/settings/test_setting_*.gd). NOT a test (the
## runner only collects test_*.gd) and without a class_name, so it needs no import pass. Suites load it with
##   const SettingsSupport := preload("res://tests/settings/settings_support.gd")
##
## The suites boot the real AppRoot on an isolated save (so the profile is a throwaway one), and set a setting the way the
## settings screen does: `app.settings.set_value(key, value)`. What happens next is the real wiring: the app's applier
## and the game scene's SettingsBridge. The suite then looks at the target itself, never at the settings object.

const Support := preload("res://tests/bridge/bridge_support.gd")
const ShellSupport := preload("res://tests/shell/shell_support.gd")


## An AppRoot on its title screen, on an isolated save. Returns { "app": AppRoot, "save_service": Node }.
static func boot_title(suite: UnboundTest, suite_name: String) -> Dictionary:
	var save_service := Support.install_isolated_save_service(suite, suite_name)
	var app := await ShellSupport.boot_app(suite)
	app.transition.default_fade_seconds = 0.04
	return {"app": app, "save_service": save_service}


## An AppRoot with the game on screen in T4 (Continue on a planted run), the room held still so the suite drives it with
## Support.pump, and T4's pawns taken out of the way. Returns { "app", "game": GameRoot, "save_service" }.
static func boot_game(suite: UnboundTest, suite_name: String) -> Dictionary:
	var save_service := Support.install_isolated_save_service(suite, suite_name)
	var app := await ShellSupport.boot_into_t4(suite, save_service)
	var game := ShellSupport.game_of(app)
	if game != null:
		ShellSupport.hold_the_game_still(app)
		Support.remove_enemy_ai(game)
		Support.pump(game, 0.1)
	return {"app": app, "game": game, "save_service": save_service}


## Whether `a` and `b` differ by less than a hundredth.
static func near(a: float, b: float) -> bool:
	return absf(a - b) < 0.01
