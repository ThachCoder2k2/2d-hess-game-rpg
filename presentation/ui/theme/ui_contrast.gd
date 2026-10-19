class_name UiContrast
extends RefCounted

## The High-contrast menus setting (docs/game-base-plan.md 10: "UI high contrast gives dialogue and menus an opaque
## background"). It works on the project Theme and nowhere else: when it is on, the panels and tabs that hold menus and
## dialogue get an OPAQUE near-black background with an ivory outline, the buttons get the same with a thick yellow
## outline on the one that has focus, and the text is white; when it is off every one of those entries is put back
## exactly as it was before (the engine's own look, or whatever the owner's theme set). Every Control in the game
## inherits the project theme, so nothing else changes and no scene knows about the setting.
##
## What it replaces is remembered in the theme itself (a meta entry), so turning it on twice, or off when it was never
## on, is harmless.

const BACKGROUND_COLOR := Color("#0b0a0e")
const HOVER_BACKGROUND_COLOR := Color("#2a2433")
const BORDER_COLOR := Color("#f1e8d2")
const FOCUS_COLOR := Color("#ffd34e")
const TEXT_COLOR := Color("#ffffff")
const BORDER_WIDTH := 2
const FOCUS_BORDER_WIDTH := 3
const CONTENT_MARGIN := 6.0

## theme type -> the stylebox names this class sets while it is on.
const BOX_NAMES_BY_TYPE := {
	&"PanelContainer": [&"panel"],
	&"OverMenuPanel": [&"panel"],
	&"Panel": [&"panel"],
	&"PopupMenu": [&"panel", &"hover"],
	&"TabContainer": [&"panel", &"tab_selected", &"tab_unselected", &"tab_hovered", &"tab_focus"],
	&"Button": [&"normal", &"hover", &"pressed", &"hover_pressed", &"focus", &"disabled"],
	&"OptionButton": [&"normal", &"hover", &"pressed", &"hover_pressed", &"focus", &"disabled"],
}

## theme type -> the colour names this class sets to white while it is on.
const COLOR_NAMES_BY_TYPE := {
	&"Label": [&"font_color"],
	&"Button": [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_hover_pressed_color", &"font_focus_color", &"font_disabled_color"],
	&"OptionButton": [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_hover_pressed_color", &"font_focus_color", &"font_disabled_color"],
	&"CheckButton": [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_hover_pressed_color", &"font_focus_color"],
	&"TabContainer": [&"font_selected_color", &"font_unselected_color", &"font_hovered_color"],
	&"PopupMenu": [&"font_color", &"font_hover_color"],
}

## The meta entry of the theme that holds what was there before: "<kind>:<type>:<name>" -> the old resource or colour
## (null when there was nothing). Its presence is what "on" means.
const ORIGINALS_META := &"ui_contrast_originals"


## Turns the setting on or off for `theme`. Idempotent.
static func apply(theme: Theme, enabled: bool) -> void:
	if theme == null or enabled == is_on(theme):
		return
	if enabled:
		_turn_on(theme)
	else:
		_turn_off(theme)


## Whether `theme` is in the high-contrast look.
static func is_on(theme: Theme) -> bool:
	return theme != null and theme.has_meta(ORIGINALS_META)


static func _turn_on(theme: Theme) -> void:
	var originals := {}
	for theme_type: StringName in BOX_NAMES_BY_TYPE:
		for box_name: StringName in BOX_NAMES_BY_TYPE[theme_type]:
			originals["box:%s:%s" % [theme_type, box_name]] = theme.get_stylebox(box_name, theme_type) if theme.has_stylebox(box_name, theme_type) else null
			theme.set_stylebox(box_name, theme_type, _box_for(box_name))
	for theme_type: StringName in COLOR_NAMES_BY_TYPE:
		for color_name: StringName in COLOR_NAMES_BY_TYPE[theme_type]:
			originals["color:%s:%s" % [theme_type, color_name]] = theme.get_color(color_name, theme_type) if theme.has_color(color_name, theme_type) else null
			theme.set_color(color_name, theme_type, TEXT_COLOR)
	theme.set_meta(ORIGINALS_META, originals)


static func _turn_off(theme: Theme) -> void:
	var originals: Dictionary = theme.get_meta(ORIGINALS_META)
	theme.remove_meta(ORIGINALS_META)
	for theme_type: StringName in BOX_NAMES_BY_TYPE:
		for box_name: StringName in BOX_NAMES_BY_TYPE[theme_type]:
			var before: Variant = originals.get("box:%s:%s" % [theme_type, box_name])
			if before != null:
				theme.set_stylebox(box_name, theme_type, before)
			elif theme.has_stylebox(box_name, theme_type):
				theme.clear_stylebox(box_name, theme_type)
	for theme_type: StringName in COLOR_NAMES_BY_TYPE:
		for color_name: StringName in COLOR_NAMES_BY_TYPE[theme_type]:
			var before: Variant = originals.get("color:%s:%s" % [theme_type, color_name])
			if before != null:
				theme.set_color(color_name, theme_type, before)
			elif theme.has_color(color_name, theme_type):
				theme.clear_color(color_name, theme_type)


## The high-contrast stylebox of one entry: an opaque box with an ivory outline; the focus ring is a thick yellow
## outline over nothing, so it sits on whatever the button looks like; hover is a lighter box.
static func _box_for(box_name: StringName) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.set_content_margin_all(CONTENT_MARGIN)
	if box_name == &"focus" or box_name == &"tab_focus":
		box.draw_center = false
		box.set_border_width_all(FOCUS_BORDER_WIDTH)
		box.border_color = FOCUS_COLOR
		return box
	box.bg_color = HOVER_BACKGROUND_COLOR if box_name in [&"hover", &"pressed", &"hover_pressed", &"tab_hovered"] else BACKGROUND_COLOR
	box.set_border_width_all(BORDER_WIDTH)
	box.border_color = BORDER_COLOR
	return box
