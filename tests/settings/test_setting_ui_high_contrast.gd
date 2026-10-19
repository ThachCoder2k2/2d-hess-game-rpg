extends UnboundTest

## High-contrast menus give menus and dialogue an opaque background (docs/game-base-plan.md 9.2, 10). On the real AppRoot and
## the project theme every Control in the game inherits:
##   - off, a menu panel is the engine's own look, which is see-through (the game ships it that way);
##   - on, the panels, tabs and buttons get an OPAQUE box with an ivory outline, the focus ring is thick and yellow, the
##     text is white: asked of a real panel of the pause menu, not of the theme's table;
##   - off again, every entry is back exactly as it was (the owner's own theme entries included: a stylebox the theme had
##     before is restored, not removed);
##   - turning it on twice or off when it was never on changes nothing;
##   - the choice is kept in the profile.

const SettingsSupport := preload("res://tests/settings/settings_support.gd")
const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "setting_ui_high_contrast"


func _init() -> void:
	suite_title = "SETTING UI HIGH CONTRAST TEST"
	call_deferred("_run")


func _run() -> void:
	_the_owners_own_entries_come_back()
	var booted := await SettingsSupport.boot_title(self, SUITE_NAME)
	var app: AppRoot = booted["app"]
	var theme := ThemeDB.get_project_theme()
	var panel := app.pause_menu.get_node("Center/Panel") as PanelContainer
	var button := app.pause_menu.resume_button
	_expect(theme != null and not UiContrast.is_on(theme), "setup: the project theme is in its ordinary look")
	var ordinary_panel_box := panel.get_theme_stylebox(&"panel") as StyleBoxFlat
	_expect(ordinary_panel_box == null or ordinary_panel_box.bg_color.a < 1.0, "off: a menu panel is see-through (alpha %s)" % [ordinary_panel_box.bg_color.a if ordinary_panel_box != null else "n/a"])
	var ordinary_text_color := button.get_theme_color(&"font_color")

	app.settings.set_value(GameSettings.UI_HIGH_CONTRAST, true)
	_expect(UiContrast.is_on(theme), "the setting reaches the theme")
	var panel_box := panel.get_theme_stylebox(&"panel") as StyleBoxFlat
	_expect(panel_box != null and is_equal_approx(panel_box.bg_color.a, 1.0), "on: the pause menu's panel is opaque (as the panel itself resolves it)")
	_expect(panel_box.border_color == UiContrast.BORDER_COLOR and panel_box.border_width_left == UiContrast.BORDER_WIDTH, "with an outline")
	var button_box := button.get_theme_stylebox(&"normal") as StyleBoxFlat
	_expect(button_box != null and is_equal_approx(button_box.bg_color.a, 1.0), "a button is opaque too")
	var focus_box := button.get_theme_stylebox(&"focus") as StyleBoxFlat
	_expect(focus_box != null and focus_box.border_width_left == UiContrast.FOCUS_BORDER_WIDTH and focus_box.border_color == UiContrast.FOCUS_COLOR, "the focus ring is thick and yellow")
	_expect(button.get_theme_color(&"font_color") == UiContrast.TEXT_COLOR and app.pause_menu.get_node("Center/Panel/Margin/Rows/TitleLabel").get_theme_color(&"font_color") == UiContrast.TEXT_COLOR, "the text is white")
	var tab_box := app.controls_panel.tabs.get_theme_stylebox(&"panel") as StyleBoxFlat
	_expect(tab_box != null and is_equal_approx(tab_box.bg_color.a, 1.0), "the Controls panel's pages are opaque")

	app.settings.set_value(GameSettings.UI_HIGH_CONTRAST, true)
	_expect(UiContrast.is_on(theme), "setting it on again changes nothing")
	app.settings.set_value(GameSettings.UI_HIGH_CONTRAST, false)
	_expect(not UiContrast.is_on(theme), "off again: the theme is in its ordinary look")
	var back_box := panel.get_theme_stylebox(&"panel") as StyleBoxFlat
	_expect(back_box == null or back_box.bg_color.a < 1.0, "the panel is see-through again")
	_expect(button.get_theme_color(&"font_color") == ordinary_text_color, "and the text colour is as it was")
	_expect(not theme.has_stylebox(&"panel", &"PanelContainer") and not theme.has_color(&"font_color", &"Label"), "and the theme holds none of the entries it set")

	app.settings.set_value(GameSettings.UI_HIGH_CONTRAST, true)
	app.flush_settings()
	_expect(SettingsStore.new(booted["save_service"]).load_settings().value(GameSettings.UI_HIGH_CONTRAST) == true, "the choice is in the profile for the next start")
	app.settings.set_value(GameSettings.UI_HIGH_CONTRAST, false)
	Support.end_suite(self, booted["save_service"])


## A theme the owner made has its own entries: turning the setting on and off must give them back, not delete them.
func _the_owners_own_entries_come_back() -> void:
	var theme := Theme.new()
	var owners_panel := StyleBoxFlat.new()
	owners_panel.bg_color = Color(0.2, 0.3, 0.4, 0.5)
	theme.set_stylebox(&"panel", &"PanelContainer", owners_panel)
	theme.set_color(&"font_color", &"Label", Color(0.9, 0.1, 0.1))
	UiContrast.apply(theme, true)
	_expect(theme.get_stylebox(&"panel", &"PanelContainer") != owners_panel and (theme.get_stylebox(&"panel", &"PanelContainer") as StyleBoxFlat).bg_color.a == 1.0, "setup: on replaces the owner's panel with the opaque one")
	UiContrast.apply(theme, false)
	_expect(theme.get_stylebox(&"panel", &"PanelContainer") == owners_panel, "the owner's own panel is back, the same resource")
	_expect(theme.get_color(&"font_color", &"Label") == Color(0.9, 0.1, 0.1), "and the owner's text colour")
	UiContrast.apply(theme, false)
	_expect(theme.get_stylebox(&"panel", &"PanelContainer") == owners_panel, "off when it was never on changes nothing")
	_expect(not UiContrast.is_on(null) and not UiContrast.is_on(theme), "a missing theme and a theme in its ordinary look are not 'on'")
	UiContrast.apply(null, true)
