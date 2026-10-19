class_name SettingsApplier
extends RefCounted

## Makes the settings of the APP true (docs/game-base-plan.md 9.2): the volume of each bus, fullscreen, the language and the
## high-contrast menus. These are things of the whole program, so AppRoot owns the one applier and calls apply_all() when
## the game starts and again whenever a setting moves. The settings of the ROOM (the shake scale, reduce flashing, high-
## contrast danger, the assists and hold-or-toggle) are applied by the SettingsBridge of the game scene, which is where
## the camera, the HUD, the board, the controls and the world are.
##
## Every apply is idempotent and cheap, so applying everything on every change is correct and there is no list of which
## setting needs which call. Where the player's value and the machine's already agree the machine is left alone (a
## window already fullscreen is not set fullscreen again, the language already in use is not switched).
##
## The volumes are linear numbers from 0.0 to 1.0 (what the sliders move) and become decibels on the bus: 0.0 is the bus
## muted, 1.0 is the level the mix was made at (0 dB).

## setting key -> the audio bus it sets (default_bus_layout.tres; tests/audio holds that the buses exist).
const BUS_NAME_BY_VOLUME_KEY := {
	GameSettings.VOLUME_MASTER: &"Master",
	GameSettings.VOLUME_SFX: &"SFX",
	GameSettings.VOLUME_MUSIC: &"Music",
	GameSettings.VOLUME_UI: &"UI",
}

## The window fullscreen is applied to: the game's own. Another Window in a test (a window that is not in the tree keeps
## the mode it is given, which a headless run cannot show on the real one).
var window: Window = null
## The theme the high-contrast menus change: the project theme. Another Theme in a test.
var theme: Theme = null


func _init(game_window: Window = null, ui_theme: Theme = null) -> void:
	window = game_window
	theme = ui_theme


## Applies every app-level setting.
func apply_all(settings: GameSettings) -> void:
	apply_volumes(settings)
	apply_fullscreen(settings)
	apply_language(settings)
	apply_ui_contrast(settings)


## Sets each bus to its volume: the level in decibels, and muted at zero. A bus the project does not have is skipped.
func apply_volumes(settings: GameSettings) -> void:
	for key: StringName in BUS_NAME_BY_VOLUME_KEY:
		var bus_index := AudioServer.get_bus_index(BUS_NAME_BY_VOLUME_KEY[key])
		if bus_index < 0:
			continue
		var amount := float(settings.value(key))
		AudioServer.set_bus_volume_db(bus_index, GameSettings.volume_in_decibels(amount))
		AudioServer.set_bus_mute(bus_index, amount <= 0.0)


## Puts the window in fullscreen or in a window, unless it already is.
func apply_fullscreen(settings: GameSettings) -> void:
	if window == null:
		return
	var wants_fullscreen := bool(settings.value(GameSettings.FULLSCREEN))
	if is_fullscreen(window) != wants_fullscreen:
		window.mode = Window.MODE_FULLSCREEN if wants_fullscreen else Window.MODE_WINDOWED


## Switches the words of the game to the chosen language, unless it is the one in use. A language the game has no words
## for leaves the language as it is.
func apply_language(settings: GameSettings) -> void:
	var code := StringName(String(settings.value(GameSettings.LANGUAGE)))
	if TextService.language() != code and not TextService.set_language(code):
		push_warning("Settings: the language '%s' has no words in this game; the language stays '%s'" % [code, TextService.language()])


## Turns the high-contrast look of the menus on or off on the theme.
func apply_ui_contrast(settings: GameSettings) -> void:
	UiContrast.apply(theme, bool(settings.value(GameSettings.UI_HIGH_CONTRAST)))


## Whether `a_window` is fullscreen (either kind).
static func is_fullscreen(a_window: Window) -> bool:
	return a_window.mode == Window.MODE_FULLSCREEN or a_window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN
