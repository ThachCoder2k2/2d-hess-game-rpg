extends UnboundTest

## The generated test language (presentation/text/pseudo_locale.gd, docs/game-base-plan.md 8.9): every row of the
## source language made 40 percent longer and accented, its {name} and %d placeholders untouched. It is what
## test_layout_pseudo_locale puts the screens through, so its promise is pinned here: if it stopped lengthening,
## that test would pass for nothing.

const MINIMUM_ROWS := 100


func _init() -> void:
	suite_title = "PSEUDO LOCALE TEST"
	_one_string_at_a_time()
	_every_row_of_the_game()
	_it_is_a_language_the_service_can_switch_to()
	finish()


func _one_string_at_a_time() -> void:
	var resume := PseudoLocale.pseudolocalize("Resume")
	_expect(PseudoLocale.visible_length(resume) == 9, "a six letter word grows to nine (%s)" % resume)
	_expect(resume != "Resume" and not _is_plain_ascii(resume), "and carries accented characters (%s)" % resume)
	_expect(PseudoLocale.pseudolocalize("Resume") == resume, "the same string always gives the same result")
	var filled := PseudoLocale.pseudolocalize("{room}  |  {time} played")
	_expect(PseudoLocale.placeholders_of(filled) == PackedStringArray(["{room}", "{time}"]), "{name} placeholders pass through untouched (%s)" % filled)
	_expect(PseudoLocale.placeholders_of(PseudoLocale.pseudolocalize("%d of %s at %02d and %.1f, 100%% sure")) == PackedStringArray(["%d", "%s", "%02d", "%.1f", "%%"]), "so do printf conversions")
	_expect(PseudoLocale.visible_length(filled) >= ceili(PseudoLocale.visible_length("{room}  |  {time} played") * 1.4), "the placeholders are not counted, the words around them grow by 40 percent")
	_expect(PseudoLocale.pseudolocalize("") == "" and PseudoLocale.pseudolocalize("12:30") == "12:30" + "·".repeat(2), "an empty string stays empty and a string with no letters is padded")
	_expect(PseudoLocale.pseudolocalize("a\nb").contains("\n"), "line breaks stay where they are")


func _every_row_of_the_game() -> void:
	var sources := TextService.source_translations()
	_expect(sources.size() == TextService.PREFIXES_BY_DOMAIN.size(), "the source language has one file per domain (%d)" % sources.size())
	var pseudo := PseudoLocale.build_translation(sources)
	_expect(pseudo.locale == String(TextService.PSEUDO_LANGUAGE), "the pseudo language is built under its own locale")
	var rows := 0
	var rows_that_did_not_grow := PackedStringArray()
	var rows_that_lost_a_placeholder := PackedStringArray()
	var rows_with_no_accent := PackedStringArray()
	for source in sources:
		for key in source.get_message_list():
			rows += 1
			var english := String(source.get_message(key))
			var pseudolocalized := String(pseudo.get_message(key))
			if PseudoLocale.visible_length(pseudolocalized) < ceili(PseudoLocale.visible_length(english) * 1.4):
				rows_that_did_not_grow.append(key)
			if PseudoLocale.placeholders_of(pseudolocalized) != PseudoLocale.placeholders_of(english):
				rows_that_lost_a_placeholder.append(key)
			if _has_letter_to_accent(english) and _is_plain_ascii(pseudolocalized):
				rows_with_no_accent.append(key)
	_expect(rows >= MINIMUM_ROWS, "the walk found %d rows (at least %d)" % [rows, MINIMUM_ROWS])
	_expect(pseudo.get_message_count() == rows, "the pseudo language has every row")
	_expect(rows_that_did_not_grow.is_empty(), "every row is at least 40 percent longer (short: %s)" % ", ".join(rows_that_did_not_grow))
	_expect(rows_that_lost_a_placeholder.is_empty(), "every row keeps its placeholders (changed: %s)" % ", ".join(rows_that_lost_a_placeholder))
	_expect(rows_with_no_accent.is_empty(), "every row with letters in it gains accented characters (plain: %s)" % ", ".join(rows_with_no_accent))


func _it_is_a_language_the_service_can_switch_to() -> void:
	_expect(&"qps" not in TextService.languages(), "the pseudo language is not there until it is asked for")
	TextService.install_pseudo_language()
	TextService.install_pseudo_language()
	_expect(&"qps" in TextService.languages() and TextService.languages().count(&"qps") == 1, "installing it makes it selectable, once however often it is asked")
	_expect(TextService.set_language(&"qps"), "the service switches to it")
	var enemies := TextService.t("UI_HUD_ENEMIES", {"remaining": 2, "total": 5})
	_expect(enemies.contains("2/5") and not enemies.contains("{") and enemies != "ENEMIES 2/5", "its placeholders are still filled, in longer and accented words (%s)" % enemies)
	_expect(TextService.t("UI_THIS_KEY_IS_NOT_IN_ANY_FILE") == "UI_THIS_KEY_IS_NOT_IN_ANY_FILE", "and a missing key still renders as itself")
	_expect(TextService.language_name(&"qps") != "qps", "the language list has a name for it")
	TextService.set_language(&"en")


func _is_plain_ascii(text: String) -> bool:
	for character in text:
		if character.unicode_at(0) > 127:
			return false
	return true


func _has_letter_to_accent(text: String) -> bool:
	var readable := PseudoLocale.without_placeholders(text)
	for character in PseudoLocale.ACCENTED_LETTER:
		if readable.contains(character):
			return true
	return false
