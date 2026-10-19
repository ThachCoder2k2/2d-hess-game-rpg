extends UnboundTest

## The Language setting switches the words of the game, live (docs/game-base-plan.md 8.9, 9.2; the owner's rule: a vi.po
## exists and is empty, so Vietnamese falls back to English per key). On the real AppRoot, on its title screen:
##   - `vi` is a language the game can be switched to, and until its rows are written every line still reads in English;
##   - the generated test language (`qps`: accented, 40 percent longer) changes the words of the screen that is up, both the
##     labels the scene authored and the ones a script put there (they redraw at once, nothing is rebuilt);
##   - a language the game has no words for leaves the language as it is;
##   - the choice is written to the profile and read by the next start.

const SettingsSupport := preload("res://tests/settings/settings_support.gd")
const ShellSupport := preload("res://tests/shell/shell_support.gd")
const SUITE_NAME := "setting_language"


func _init() -> void:
	suite_title = "SETTING LANGUAGE TEST"
	call_deferred("_run")


func _run() -> void:
	var booted := await SettingsSupport.boot_title(self, SUITE_NAME)
	var app: AppRoot = booted["app"]
	var title := ShellSupport.title_of(app)
	_expect(title != null and TextService.language() == &"en", "setup: the title is up and the game speaks English")
	_expect(&"vi" in TextService.languages() and &"en" in TextService.languages(), "setup: English and Vietnamese are languages the game has")
	_expect(TextService.PSEUDO_LANGUAGE in TextService.languages(), "and the app installed the generated test language, so the player can pick it")
	var language_list := app.settings_screen
	language_list.open()
	var language_names: Array[String] = []
	var language_options := language_list.control_of(GameSettings.LANGUAGE) as OptionButton
	for index in language_options.item_count:
		language_names.append(language_options.get_item_text(index))
	_expect(language_names == ["English", "Pseudo-language (test)"], "the Settings screen lists English first, then the others by their code, each by its own name, and only languages that have words: Vietnamese waits for its first row (%s)" % [language_names])
	language_list.close()
	var english_new_game := title.new_game_button.atr(title.new_game_button.text)
	var english_version := title.version_label.text
	_expect(english_new_game == "New Game", "setup: the New Game button reads 'New Game'")

	app.settings.set_value(GameSettings.LANGUAGE, "vi")
	_expect(TextService.language() == &"vi", "the setting switches the game to Vietnamese")
	_expect(title.new_game_button.atr(title.new_game_button.text) == "New Game", "and an empty vi file falls back to English per key: the button still reads 'New Game'")
	_expect(TextService.t("UI_TITLE_QUIT") == "Quit", "so does every other line")

	app.settings.set_value(GameSettings.LANGUAGE, "qps")
	_expect(TextService.language() == TextService.PSEUDO_LANGUAGE, "the generated test language is switched to the same way")
	await process_frame
	var pseudo_new_game := title.new_game_button.atr(title.new_game_button.text)
	_expect(pseudo_new_game != english_new_game and pseudo_new_game.length() > english_new_game.length(), "a label the scene authored is redrawn in it at once and is longer ('%s')" % pseudo_new_game)
	_expect(title.version_label.text != english_version, "and so is one a script set (the version line: '%s')" % title.version_label.text)

	app.settings.set_value(GameSettings.LANGUAGE, "zz")
	_expect(TextService.language() == TextService.PSEUDO_LANGUAGE, "a language with no words in this game leaves the language as it was")

	app.settings.set_value(GameSettings.LANGUAGE, "en")
	await process_frame
	_expect(TextService.language() == &"en" and title.new_game_button.atr(title.new_game_button.text) == "New Game", "English is back, on the same screen")
	_expect(title.version_label.text == english_version, "and the version line is as it was")

	app.settings.set_value(GameSettings.LANGUAGE, "vi")
	app.flush_settings()
	var next_start := SettingsStore.new(booted["save_service"]).load_settings()
	_expect(next_start.value(GameSettings.LANGUAGE) == "vi", "the language is in the profile for the next start")
	app.settings.set_value(GameSettings.LANGUAGE, "en")
	SettingsSupport.Support.end_suite(self, booted["save_service"])
