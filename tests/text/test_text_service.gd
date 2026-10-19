extends UnboundTest

## TextService (presentation/text/text_service.gd, docs/game-base-plan.md 8.9, D-24, D-25): the one door the
## game's words go through. English is the source language and is complete, Vietnamese is empty and falls back to it
## key by key, a placeholder is filled from the params, a missing key renders as itself, and a language switch is
## refused for a language nobody wrote. LiveText keeps what a script put on screen in the chosen language.

const SOURCE_KEY := "UI_PAUSE_RESUME"
const PLACEHOLDER_KEY := "UI_HUD_ENEMIES"
const MISSING_KEY := "UI_THIS_KEY_IS_NOT_IN_ANY_FILE"


func _init() -> void:
	suite_title = "TEXT SERVICE TEST"
	_the_source_language_answers_every_key()
	_placeholders_are_filled()
	_a_missing_key_renders_as_itself()
	_an_empty_language_falls_back_key_by_key()
	_a_language_that_was_not_written_is_refused()
	_only_languages_with_words_are_offered()
	_the_machines_own_locale_does_not_matter()
	_language_names_are_written_in_their_own_language()
	await _live_text_follows_the_language()
	finish()


func _the_source_language_answers_every_key() -> void:
	_expect(TextService.language() == &"en" and TextService.SOURCE_LANGUAGE == &"en", "the suite runs in the source language (UnboundTest sets it)")
	_expect(TextService.t(SOURCE_KEY) == "Resume", "a key gives the English row")
	_expect(TextService.has_key(SOURCE_KEY) and not TextService.has_key(MISSING_KEY) and not TextService.has_key(""), "has_key tells a row from none")
	_expect(TextService.domain_of("UI_X") == &"ui" and TextService.domain_of("MSG_X") == &"ui" and TextService.domain_of("ROOM_X") == &"rooms" and TextService.domain_of("SKILL_X") == &"skills" and TextService.domain_of("ITEM_X") == &"skills" and TextService.domain_of("PAGE_X") == &"story" and TextService.domain_of("NOPE_X") == &"", "a key belongs to the file of its prefix")


func _placeholders_are_filled() -> void:
	_expect(TextService.t(PLACEHOLDER_KEY, {"remaining": 2, "total": 5}) == "ENEMIES 2/5", "a {name} is filled from the params, whatever its type")
	_expect(TextService.t(PLACEHOLDER_KEY) == "ENEMIES {remaining}/{total}", "and left as it is when the caller gives none, so a forgotten param is visible")
	_expect(TextService.t("a line with {braces} that is no key", {}) == "a line with {braces} that is no key", "a text with braces and no params is left alone")


func _a_missing_key_renders_as_itself() -> void:
	_expect(TextService.t(MISSING_KEY) == MISSING_KEY, "a key with no row renders as the key, so the gap is visible on screen")
	_expect(TextService.t("Some words that were never a key") == "Some words that were never a key", "and so does text that is not a key at all (fixtures and tests pass words through)")


func _an_empty_language_falls_back_key_by_key() -> void:
	_expect(TextService.set_language(&"vi") and TextService.language() == &"vi", "Vietnamese can be chosen")
	_expect(TextService.t(SOURCE_KEY) == "Resume", "its files are empty, so every key still reads in English")
	var vietnamese := Translation.new()
	vietnamese.locale = "vi"
	vietnamese.add_message(SOURCE_KEY, "Tiếp tục")
	TranslationServer.add_translation(vietnamese)
	_expect(TextService.t(SOURCE_KEY) == "Tiếp tục" and TextService.t("UI_PAUSE_TITLE") == "Paused", "a row written in Vietnamese wins, and a key it does not have still reads in English")
	TranslationServer.remove_translation(vietnamese)
	TextService.set_language(&"en")
	_expect(TextService.language() == &"en" and TextService.t(SOURCE_KEY) == "Resume", "and back to English")


func _a_language_that_was_not_written_is_refused() -> void:
	_expect(not TextService.set_language(&"fr") and TextService.language() == &"en", "a language with no words loaded is refused and nothing changes")
	var languages := TextService.languages()
	_expect(languages[0] == &"en" and &"vi" in languages and &"fr" not in languages, "the list has the source language first, then the others (%s)" % [languages])


func _only_languages_with_words_are_offered() -> void:
	var source_files := TextService.source_translations()
	var every_source_file_has_rows := not source_files.is_empty()
	for file in source_files:
		every_source_file_has_rows = every_source_file_has_rows and file.get_message_count() > 0
	_expect(every_source_file_has_rows, "setup: a loaded .po file knows how many rows it holds, and the English ones hold rows (%d files)" % source_files.size())
	_expect(TextService.has_own_words(&"en") and not TextService.has_own_words(&"vi"), "English has words of its own and the empty Vietnamese files do not")
	_expect(TextService.offered_languages() == [&"en"] and &"vi" in TextService.languages(), "so the player is offered English only, while Vietnamese stays a language the game can switch to")
	TextService.install_pseudo_language()
	_expect(TextService.has_own_words(TextService.PSEUDO_LANGUAGE) and TextService.offered_languages() == [&"en", TextService.PSEUDO_LANGUAGE], "the generated language is built from rows, so it is offered once it is installed (a debug build does)")


func _the_machines_own_locale_does_not_matter() -> void:
	TranslationServer.set_locale("en_VN")
	_expect(TextService.language() == &"en" and TextService.t(SOURCE_KEY) == "Resume", "a regional locale such as the en_VN of this machine reads as its language")
	TranslationServer.set_locale("vi_VN")
	_expect(TextService.language() == &"vi" and TextService.t(SOURCE_KEY) == "Resume", "and vi_VN as vi, which falls back to English")
	TextService.set_language(&"en")


func _language_names_are_written_in_their_own_language() -> void:
	_expect(TextService.language_name(&"en") == "English" and TextService.language_name(&"vi") == "Tiếng Việt", "a language is named in itself, whatever language is on")
	TextService.set_language(&"vi")
	_expect(TextService.language_name(&"en") == "English", "also while the other one is on")
	TextService.set_language(&"en")
	_expect(TextService.language_name(&"xx") == "xx", "a language with no name row is shown by its code")


## A bound text is resolved again by the engine's own notification when the language changes (a node in the tree
## is told); a node outside the tree is refreshed by hand.
func _live_text_follows_the_language() -> void:
	var host := Control.new()
	var label := Label.new()
	var live_text := LiveText.new()
	host.add_child(label)
	host.add_child(live_text)
	root.add_child(host)
	var redraw_count := [0]
	live_text.on_language_change(func() -> void: redraw_count[0] += 1)
	live_text.set_text(label, PLACEHOLDER_KEY, {"remaining": 1, "total": 4})
	_expect(label.text == "ENEMIES 1/4" and live_text.key_of(label) == PLACEHOLDER_KEY, "a LiveText puts the words of its key on the control")

	var vietnamese := Translation.new()
	vietnamese.locale = "vi"
	vietnamese.add_message(PLACEHOLDER_KEY, "QUÂN ĐỊCH {remaining}/{total}")
	TranslationServer.add_translation(vietnamese)
	TextService.set_language(&"vi")
	await wait_frames(1)
	_expect(label.text == "QUÂN ĐỊCH 1/4", "a language switch changes it at once, params kept (%s)" % label.text)
	_expect(redraw_count[0] >= 1, "and runs the redraw the screen asked for")
	TextService.set_language(&"en")
	await wait_frames(1)
	_expect(label.text == "ENEMIES 1/4", "and back")

	live_text.set_text(label, "UI_PAUSE_TITLE")
	_expect(label.text == "Paused" and live_text.key_of(label) == "UI_PAUSE_TITLE", "setting the control again replaces what it was bound to")
	live_text.release(label)
	TextService.set_language(&"vi")
	await wait_frames(1)
	_expect(label.text == "Paused" and live_text.key_of(label) == "", "a released control is left as it is")
	TextService.set_language(&"en")
	TranslationServer.remove_translation(vietnamese)

	var gone := Label.new()
	live_text.set_text(gone, "UI_PAUSE_TITLE")
	gone.free()
	live_text.refresh()
	_expect(true, "a control that was freed is dropped without an error")
	host.queue_free()
