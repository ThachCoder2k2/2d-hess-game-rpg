class_name UiTheme
extends Theme

## The game's Theme (docs/game-base-plan.md 8.9, 9.2, 10; docs/owner-decisions.md 2026-10-12). It is the PROJECT theme
## (project.godot `gui/theme/custom`), so every Control inherits it, the ones under a CanvasLayer such as the HUD
## included (a Window's theme does not reach those). `content/ui/theme/theme.tres` is its one instance.
##
## It NAMES the font files of the UI. The files are the owner's: nobody downloads a font into the project
## (assets are the owner's, one file per thing at an exact path, docs/assets/README.md). Each slot is a path the asset
## list gives (docs/assets/spec/ui_story.json, group `fonts_ui`). While no file is there the game uses the engine's
## own default font; when the owner drops a file at the path, it is used, with no other change. UiFonts (presentation/
## ui/theme/ui_fonts.gd) loads the files and sets them on this Theme when the game starts.
##
## A font that is present must cover every Vietnamese letter (tests/text/test_font_vietnamese_coverage.gd fails when it
## does not): the source language is English (D-25) but the game ships Vietnamese when the owner fills `vi`.

## The slots, in the order the asset list gives them.
const SLOTS: Array[StringName] = [&"body", &"small", &"title", &"child_hand"]

@export_group("Font files (owner-supplied)")
## The main font: menus, dialogue, the Book, the HUD's words. 16 px (or 32 px) for a pixel font like VT323.
@export_file("*.ttf", "*.otf", "*.woff", "*.woff2") var body_font_path := "res://assets/fonts/ui_body_pixel.ttf"
## HUD numerals, cooldown digits and timers. Used by Labels whose theme type variation is `HudNumeral`.
@export_file("*.ttf", "*.otf", "*.woff", "*.woff2") var small_font_path := "res://assets/fonts/ui_small_pixel.ttf"
## Chapter cards and menu headings. Used by Labels whose theme type variation is `MenuTitle`.
@export_file("*.ttf", "*.otf", "*.woff", "*.woff2") var title_font_path := "res://assets/fonts/ui_title_pixel.ttf"
## The child's lines (M6). Used by Labels whose theme type variation is `ChildLine`.
@export_file("*.ttf", "*.otf", "*.woff", "*.woff2") var child_hand_font_path := "res://assets/fonts/child_hand.ttf"


## The font file named for `slot` (one of SLOTS), "" for a slot that does not exist.
func path_of(slot: StringName) -> String:
	match slot:
		&"body":
			return body_font_path
		&"small":
			return small_font_path
		&"title":
			return title_font_path
		&"child_hand":
			return child_hand_font_path
	return ""


## Problems with the slots, one sentence each (empty = healthy): every slot names a font file under assets/fonts/.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	for slot in SLOTS:
		var path := path_of(slot)
		if not path.begins_with("res://assets/fonts/") or path.get_extension().to_lower() not in ["ttf", "otf", "woff", "woff2"]:
			problems.append("The %s font slot names '%s', which is not a font file under res://assets/fonts/." % [slot, path])
	return problems
