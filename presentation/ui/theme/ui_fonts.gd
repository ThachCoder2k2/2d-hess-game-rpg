class_name UiFonts
extends RefCounted

## Puts the owner's fonts on the game's Theme (docs/game-base-plan.md 8.9, 10; schema/ui/ui_theme.gd names the files).
## The files are optional: a slot whose file is not there leaves the engine's default font in place, and a slot whose
## file is there is used, so the owner only has to put the file at the path.
##
##   body        the Theme's default font: every Control without its own font
##   small       Labels with the theme type variation HudNumeral
##   title       Labels with the theme type variation MenuTitle
##   child_hand  Labels with the theme type variation ChildLine
##
## A file the editor has imported is loaded as a resource (its import settings, such as "antialiasing none", apply);
## a file that is there but not imported yet (dropped in while the editor was closed) is read directly with the engine's
## defaults, so the game still shows it. Open the project in the editor once and set the import options of a pixel
## font (docs/OWNER_GUIDE.md).

## slot -> the theme type variation of Label that uses that slot's font. The body font is the default, not a variation.
const TYPE_VARIATION_BY_SLOT := {
	&"small": &"HudNumeral",
	&"title": &"MenuTitle",
	&"child_hand": &"ChildLine",
}

## Where a font came from, for a report.
enum Source { OWNER_FILE, ENGINE_DEFAULT }


## The font file at `path`, or null when there is none (or it is not a font). `path` may be a res:// path, or a user://
## path (the tests put a font there).
static func load_font_file(path: String) -> Font:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		return load(path) as Font
	if FileAccess.file_exists(path):
		var font := FontFile.new()
		if font.load_dynamic_font(path) == OK:
			return font
	return null


## Sets the fonts of `theme` from the files its slots name. A slot with no file clears its font, so calling this
## again after the owner added or removed a file is correct.
static func apply(theme: UiTheme) -> void:
	if theme == null:
		return
	theme.default_font = load_font_file(theme.body_font_path)
	for slot: StringName in TYPE_VARIATION_BY_SLOT:
		var variation: StringName = TYPE_VARIATION_BY_SLOT[slot]
		theme.set_type_variation(variation, &"Label")
		var slot_font := load_font_file(theme.path_of(slot))
		if slot_font != null:
			theme.set_font(&"font", variation, slot_font)
		elif &"font" in theme.get_font_list(variation):
			theme.clear_font(&"font", variation)


## The fonts the UI shows right now: slot -> { "font": Font, "source": Source }. The body slot is always there (the
## engine's default font when there is no file); another slot is there only when its file is.
static func active_fonts(theme: UiTheme) -> Dictionary:
	var fonts := {}
	var body := load_font_file(theme.body_font_path)
	fonts[&"body"] = {"font": body if body != null else ThemeDB.fallback_font, "source": Source.OWNER_FILE if body != null else Source.ENGINE_DEFAULT}
	for slot: StringName in TYPE_VARIATION_BY_SLOT:
		var slot_font := load_font_file(theme.path_of(slot))
		if slot_font != null:
			fonts[slot] = {"font": slot_font, "source": Source.OWNER_FILE}
	return fonts
