extends UnboundTest

## The UI font can write Vietnamese (docs/game-base-plan.md 8.9, 1.2; owner rule of M4: no font is downloaded, the owner
## supplies the files). Every font in use is checked for all 134 precomposed Vietnamese letters, both cases, the stacked
## marks (ệ ẫ ờ ữ ặ) included, and the result is REPORTED either way:
##   - a font file the owner put in assets/fonts/ that lacks a letter FAILS this suite (the owner chose a font that
##     cannot write the language the game ships);
##   - the engine's default font (the stand-in while there is no file) that lacks a letter is a WARN, which the strict
##     runner turns red too, so a stand-in that cannot write Vietnamese is noticed and not shipped by accident.
## Which font is active is UiFonts.active_fonts (the slots of schema/ui/ui_theme.gd). Seeing the line height and the
## clearance of the stacked marks at the real size is the one step no check can do; the owner does it (OWNER_GUIDE).
## The check is run on a font with no glyphs and on a font file that is written into a throwaway folder, so it is shown
## to be able to fail and the "owner's file is present" path is exercised without any font being added to the project.

const Glyphs := preload("res://tests/support/vietnamese_glyphs.gd")

const THROWAWAY_FOLDER := "user://font_coverage_test"


func _init() -> void:
	suite_title = "FONT VIETNAMESE COVERAGE TEST"
	_the_set_of_letters()
	_the_check_can_fail()
	_the_verdict()
	_an_owners_file_is_checked()
	_the_fonts_in_use_now()
	finish()


func _the_set_of_letters() -> void:
	var letters := Glyphs.all_letters()
	var distinct := {}
	var all_beyond_ascii := true
	for letter in letters:
		distinct[letter] = true
		all_beyond_ascii = all_beyond_ascii and letter.unicode_at(0) > 127
	_expect(letters.size() == Glyphs.EXPECTED_LETTER_COUNT and distinct.size() == Glyphs.EXPECTED_LETTER_COUNT, "the set holds %d distinct letters, both cases (found %d, %d distinct)" % [Glyphs.EXPECTED_LETTER_COUNT, letters.size(), distinct.size()])
	_expect(all_beyond_ascii, "and none is plain ASCII")
	for stacked in ["ệ", "ẫ", "ờ", "ữ", "ặ", "Ệ", "Ẫ", "Ờ", "Ữ", "Ặ", "đ", "Đ"]:
		_expect(stacked in letters, "it has the stacked or stroked letter %s" % stacked)


func _the_check_can_fail() -> void:
	var no_glyphs := FontFile.new()
	_expect(Glyphs.missing_in(no_glyphs).size() == Glyphs.EXPECTED_LETTER_COUNT, "a font with no glyphs misses all %d letters" % Glyphs.EXPECTED_LETTER_COUNT)
	_expect(Glyphs.missing_in(ThemeDB.fallback_font).size() <= Glyphs.EXPECTED_LETTER_COUNT, "and the check returns the letters, not a count, for a real font")


func _the_verdict() -> void:
	_expect(Glyphs.verdict(true, 0) == "ok" and Glyphs.verdict(false, 0) == "ok", "a font that covers everything is fine, whoever supplied it")
	_expect(Glyphs.verdict(true, 3) == "fail", "a font the owner supplied that lacks letters FAILS")
	_expect(Glyphs.verdict(false, 3) == "warn", "the engine's default font that lacks letters WARNS")


## An owner's font file, simulated: the default font's own bytes written to a throwaway folder and named by a theme.
## It is loaded through the same path as a file in assets/fonts/ and checked like one.
func _an_owners_file_is_checked() -> void:
	DirAccess.make_dir_recursive_absolute(THROWAWAY_FOLDER)
	var font_path := THROWAWAY_FOLDER.path_join("ui_body_pixel.ttf")
	var written := FileAccess.open(font_path, FileAccess.WRITE)
	written.store_buffer((ThemeDB.fallback_font as FontFile).data)
	written.close()
	var theme := UiTheme.new()
	theme.body_font_path = font_path
	var fonts := UiFonts.active_fonts(theme)
	var body: Dictionary = fonts[&"body"]
	_expect(body["source"] == UiFonts.Source.OWNER_FILE and body["font"] != ThemeDB.fallback_font, "a font file at the body slot's path is the font in use, and it came from a file")
	var missing := Glyphs.missing_in(body["font"])
	_expect(missing.is_empty(), "and it covers Vietnamese (a copy of the default font does; missing: %s)" % ", ".join(missing))
	DirAccess.remove_absolute(font_path)
	_expect(UiFonts.active_fonts(theme)[&"body"]["source"] == UiFonts.Source.ENGINE_DEFAULT, "with the file gone the engine's default is in use again")
	DirAccess.remove_absolute(THROWAWAY_FOLDER)


## The check that matters: every font in use now, whatever it is.
func _the_fonts_in_use_now() -> void:
	var theme := ThemeDB.get_project_theme() as UiTheme
	_expect(theme != null, "the project theme is the game's UiTheme")
	if theme == null:
		return
	var fonts := UiFonts.active_fonts(theme)
	for slot: StringName in fonts:
		var entry: Dictionary = fonts[slot]
		var font: Font = entry["font"]
		var is_owner_file: bool = entry["source"] == UiFonts.Source.OWNER_FILE
		var missing := Glyphs.missing_in(font)
		var source_text := "the owner's file %s" % theme.path_of(slot) if is_owner_file else "the engine's default font (%s), no owner file yet at %s" % [font.get_font_name(), theme.path_of(slot)]
		print("INFO: font slot %s is %s; Vietnamese coverage %d of %d letters" % [slot, source_text, Glyphs.EXPECTED_LETTER_COUNT - missing.size(), Glyphs.EXPECTED_LETTER_COUNT])
		match Glyphs.verdict(is_owner_file, missing.size()):
			"ok":
				_expect(true, "font slot %s (%s) covers all %d Vietnamese letters" % [slot, "owner's file" if is_owner_file else "engine default", Glyphs.EXPECTED_LETTER_COUNT])
			"fail":
				_expect(false, "font slot %s, the owner's file %s, lacks Vietnamese letters: %s" % [slot, theme.path_of(slot), ", ".join(missing)])
			"warn":
				soft_expect(false, "font slot %s, the engine's default font, lacks Vietnamese letters: %s" % [slot, ", ".join(missing)])
