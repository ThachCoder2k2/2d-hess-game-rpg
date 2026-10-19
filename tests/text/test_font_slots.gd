extends UnboundTest

## The font slots of the Theme (schema/ui/ui_theme.gd, presentation/ui/theme/ui_fonts.gd; owner rule of M4: the
## owner supplies the font files, nothing is downloaded):
##   - the project theme is the game's UiTheme, and each slot names the file the asset list gives (docs/assets/spec/
##     ui_story.json, group fonts_ui), so the owner's file lands by dropping it at the path;
##   - with no file the slot leaves the engine's default font and the screens use it;
##   - with a file the slot is used: as the Theme's default font (body) and as the font of the Labels whose theme type
##     variation is HudNumeral, MenuTitle or ChildLine (the other slots); taking the file away clears it again;
##   - AppRoot applies the fonts when the game starts;
##   - THIRD_PARTY_NOTICES.md says the fonts are owner-supplied.
## A "file" in the cases below is the default font's own bytes written to a throwaway folder: no font is added to the project.

const Support := preload("res://tests/bridge/bridge_support.gd")
const ShellSupport := preload("res://tests/shell/shell_support.gd")
const SUITE_NAME := "font_slots"
const THROWAWAY_FOLDER := "user://font_slots_test"
const ASSET_LIST_PATH := "res://docs/assets/spec/ui_story.json"


func _init() -> void:
	suite_title = "FONT SLOTS TEST"
	watchdog_seconds = 40.0
	call_deferred("_run")


func _run() -> void:
	var paths := TestPaths.new(self)
	_the_theme_names_the_files_of_the_asset_list(paths)
	_with_no_file_the_engine_font_is_used()
	_with_a_file_the_slot_is_used()
	var save_service := await _app_root_applies_the_fonts()
	_the_notices_say_owner_supplied()
	DirAccess.remove_absolute(THROWAWAY_FOLDER)
	Support.end_suite(self, save_service)


func _the_theme_names_the_files_of_the_asset_list(paths: TestPaths) -> void:
	var theme := ThemeDB.get_project_theme() as UiTheme
	_expect(theme != null and theme.resource_path == "res://content/ui/theme/theme.tres", "the project theme is content/ui/theme/theme.tres, a UiTheme")
	if theme == null:
		return
	_expect(theme.validate().is_empty(), "its slots are healthy (%s)" % "; ".join(theme.validate()))
	var listed_names: Array[String] = []
	var asset_list: Dictionary = paths.read_json(ASSET_LIST_PATH)
	for group: Dictionary in asset_list["groups"]:
		if group["group_id"] == "fonts_ui":
			for file_entry: Dictionary in group["files"]:
				listed_names.append(String(file_entry["name"]))
	_expect(listed_names.size() == UiTheme.SLOTS.size(), "the asset list gives %d font files and the theme has %d slots" % [listed_names.size(), UiTheme.SLOTS.size()])
	var theme_names: Array[String] = []
	for slot in UiTheme.SLOTS:
		theme_names.append(theme.path_of(slot).get_file())
		_expect(theme.path_of(slot) == "res://assets/fonts/" + theme.path_of(slot).get_file(), "slot %s names a file in assets/fonts/ (%s)" % [slot, theme.path_of(slot)])
	listed_names.sort()
	theme_names.sort()
	_expect(listed_names == theme_names, "and the names are the asset list's (%s)" % ", ".join(PackedStringArray(theme_names)))
	_expect(UiFonts.TYPE_VARIATION_BY_SLOT.size() == UiTheme.SLOTS.size() - 1, "every slot but the body has a theme type variation of Label")


func _with_no_file_the_engine_font_is_used() -> void:
	var theme := UiTheme.new()
	UiFonts.apply(theme)
	_expect(theme.default_font == null, "with no file the Theme sets no default font, so the engine's is used")
	var label := Label.new()
	label.theme = theme
	root.add_child(label)
	_expect(label.get_theme_font(&"font") == ThemeDB.fallback_font, "and a Label shows the engine's default font")
	for variation: StringName in UiFonts.TYPE_VARIATION_BY_SLOT.values():
		_expect(theme.get_type_variation_base(variation) == &"Label" and &"font" not in theme.get_font_list(variation), "%s is a variation of Label with no font of its own" % variation)
	label.free()
	_expect(UiFonts.load_font_file("") == null and UiFonts.load_font_file("res://assets/fonts/not_there.ttf") == null, "a path with no file loads nothing")


func _with_a_file_the_slot_is_used() -> void:
	DirAccess.make_dir_recursive_absolute(THROWAWAY_FOLDER)
	var theme := UiTheme.new()
	var written_paths := {}
	for slot in UiTheme.SLOTS:
		var path := THROWAWAY_FOLDER.path_join("%s.ttf" % slot)
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_buffer((ThemeDB.fallback_font as FontFile).data)
		file.close()
		written_paths[slot] = path
	theme.body_font_path = written_paths[&"body"]
	theme.small_font_path = written_paths[&"small"]
	theme.title_font_path = written_paths[&"title"]
	theme.child_hand_font_path = written_paths[&"child_hand"]
	UiFonts.apply(theme)
	_expect(theme.default_font != null and theme.default_font != ThemeDB.fallback_font, "with a body file the Theme's default font is that file")
	var label := Label.new()
	label.theme = theme
	root.add_child(label)
	_expect(label.get_theme_font(&"font") == theme.default_font, "and a Label shows it")
	for slot: StringName in UiFonts.TYPE_VARIATION_BY_SLOT:
		var variation: StringName = UiFonts.TYPE_VARIATION_BY_SLOT[slot]
		var variant_label := Label.new()
		variant_label.theme = theme
		variant_label.theme_type_variation = variation
		root.add_child(variant_label)
		_expect(&"font" in theme.get_font_list(variation) and variant_label.get_theme_font(&"font") == theme.get_font(&"font", variation), "%s: a Label of the %s variation shows the %s file" % [slot, variation, slot])
		variant_label.free()
	DirAccess.remove_absolute(written_paths[&"small"])
	UiFonts.apply(theme)
	_expect(&"font" not in theme.get_font_list(&"HudNumeral") and theme.default_font != null, "taking the small file away clears that slot and leaves the others")
	DirAccess.remove_absolute(written_paths[&"body"])
	UiFonts.apply(theme)
	_expect(theme.default_font == null, "and taking the body file away gives the engine's font back")
	for slot in UiTheme.SLOTS:
		DirAccess.remove_absolute(written_paths[slot])
	label.free()


## AppRoot sets the fonts on the project theme when the game starts: the body slot is pointed at a file, the app is
## booted, and the theme has the file as its default font.
func _app_root_applies_the_fonts() -> Node:
	var theme := ThemeDB.get_project_theme() as UiTheme
	var original_body_path := theme.body_font_path
	DirAccess.make_dir_recursive_absolute(THROWAWAY_FOLDER)
	var body_path := THROWAWAY_FOLDER.path_join("app_root_body.ttf")
	var file := FileAccess.open(body_path, FileAccess.WRITE)
	file.store_buffer((ThemeDB.fallback_font as FontFile).data)
	file.close()
	theme.body_font_path = body_path
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	var app := await ShellSupport.boot_app(self)
	_expect(theme.default_font != null and app.screen is TitleScreen, "AppRoot applied the fonts at start: the project theme's default font is the body file")
	theme.body_font_path = original_body_path
	UiFonts.apply(theme)
	DirAccess.remove_absolute(body_path)
	_expect(theme.default_font == null, "and with the path put back there is no owner font again")
	return save_service


func _the_notices_say_owner_supplied() -> void:
	var notices := FileAccess.get_file_as_string("res://THIRD_PARTY_NOTICES.md")
	_expect(notices.contains("owner-supplied") and notices.contains("assets/fonts/"), "THIRD_PARTY_NOTICES.md records the font slots as owner-supplied, with their folder")
