class_name TextService
extends RefCounted

## The one door every player-facing word of the game goes through (docs/game-base-plan.md 8.9, D-24, D-25).
##
## Scenes, resources and scripts hold KEYS ("UI_PAUSE_RESUME"), never the words. The words are msgstr rows in
## the gettext files `content/story/text/<language>/{story,ui,skills,rooms}.po`, four files per language that
## project.godot registers as several translations of the same locale (Godot merges them: `test_po_domains_merge`).
## This class is the ONLY code that asks the engine to translate: no other script calls tr(), atr() or
## TranslationServer.translate() (`test_tr_only_in_text_service`). Text that a scene shows as it is authored
## (a Label whose `text` is a key) is translated by the engine itself and redraws by itself when the language
## changes; text a script sets goes through t(), and goes on a LiveText when it must follow a language change.
##
## A key the files do not hold renders as the key itself (the engine's behaviour), so a missing row is visible on
## screen, and `test_text_keys` fails on it. A row may hold `{name}` placeholders; t() fills them from `params`.
##
## The source language is English (D-25): `en` is complete, `vi` is empty and falls back to `en` per key
## (`internationalization/locale/fallback`). Tests run in `en` (UnboundTest sets it), because the machine's own
## locale can be anything (here it is `en_VN`).

## The language the words are written in; every key has a row here.
const SOURCE_LANGUAGE := &"en"
## The generated test language: every string longer by 40 percent and accented (PseudoLocale). Not a file: it is
## built from the source rows when install_pseudo_language() is called.
const PSEUDO_LANGUAGE := &"qps"
## The project setting that lists the .po files the engine loads. The files themselves are content/story/text/
## <language>/<domain>.po; this class never names that folder (presentation does not load content/ by path): the
## engine loads them from the project settings and the tests read them with PoFileReader.
const TRANSLATIONS_SETTING := "internationalization/locale/translations"

## domain (the .po file name) -> the key prefixes that belong in it. A key goes in the file of its prefix, so
## two lanes adding keys rarely touch the same file (plan 14.5). `test_po_domains_merge` enforces the table.
const PREFIXES_BY_DOMAIN := {
	&"ui": ["UI_", "MSG_", "PROMPT_"],
	&"rooms": ["ROOM_"],
	&"skills": ["SKILL_", "ITEM_"],
	&"story": ["DLG_", "AMB_", "BOOK_", "PAGE_", "CHAR_", "ENEMY_", "BOSS_", "CREDIT_", "END_", "CLUE_"],
}

## The text of `key` in the current language, with every `{name}` filled from `params` (name -> value, shown as
## its string; a TextKey value is turned into its own words first). A key with no row is returned as it is.
static func t(key: String, params: Dictionary = {}) -> String:
	var text := String(TranslationServer.translate(key))
	if params.is_empty():
		return text
	var filled := {}
	for placeholder: Variant in params:
		var value: Variant = params[placeholder]
		filled[placeholder] = value.resolve() if value is TextKey else value
	return text.format(filled)


## Whether a row exists for `key` (in the current language or, failing that, the fallback one).
static func has_key(key: String) -> bool:
	return not key.is_empty() and String(TranslationServer.translate(key)) != key


## The language the game shows, as a bare code: `en`, `vi`, `qps`. The machine's own `en_VN` is `en`.
static func language() -> StringName:
	return StringName(TranslationServer.get_locale().split("_")[0])


## Every language that has words loaded, the source language first and the rest in alphabetical order.
static func languages() -> Array[StringName]:
	var codes: Array[StringName] = []
	for locale in TranslationServer.get_loaded_locales():
		var code := StringName(String(locale).split("_")[0])
		if code != SOURCE_LANGUAGE and code not in codes:
			codes.append(code)
	codes.sort_custom(func(first: StringName, second: StringName) -> bool: return String(first) < String(second))
	codes.push_front(SOURCE_LANGUAGE)
	return codes


## Switches the game to `code`. Every node in the tree is told (NOTIFICATION_TRANSLATION_CHANGED), so what a scene
## authored with keys redraws at once and every LiveText re-resolves its texts. Returns false, changing nothing,
## for a language that has no words loaded.
static func set_language(code: StringName) -> bool:
	if code not in languages():
		return false
	TranslationServer.set_locale(String(code))
	return true


## How a language is written in its own language ("English", "Tiếng Việt"): the row `UI_LANGUAGE_NAME_<CODE>`.
## Always the same whatever the current language is, so a player who cannot read the current one can still
## find theirs in the list; a translator may spell a name differently in their own language file.
static func language_name(code: StringName) -> String:
	var key := "UI_LANGUAGE_NAME_%s" % String(code).to_upper()
	return t(key) if has_key(key) else String(code)


## Builds the pseudo-language from the source rows and makes it selectable (once; a second call does nothing).
## Used by the layout test and by anyone who wants to see how the screens take longer words.
static func install_pseudo_language() -> void:
	if PSEUDO_LANGUAGE in languages():
		return
	TranslationServer.add_translation(PseudoLocale.build_translation(source_translations()))


## The .po files of one language as the engine lists them in project.godot, loaded.
static func translations_of(code: StringName) -> Array[Translation]:
	var found: Array[Translation] = []
	for path in ProjectSettings.get_setting(TRANSLATIONS_SETTING, PackedStringArray()):
		var translation := load(String(path)) as Translation
		if translation != null and translation.locale == String(code):
			found.append(translation)
	return found


## The source language's files, loaded.
static func source_translations() -> Array[Translation]:
	return translations_of(SOURCE_LANGUAGE)


## The domain (`ui`, `rooms`, `skills`, `story`) whose file a key belongs in, by its prefix; &"" for a key with
## no known prefix.
static func domain_of(key: String) -> StringName:
	for domain: StringName in PREFIXES_BY_DOMAIN:
		for prefix: String in PREFIXES_BY_DOMAIN[domain]:
			if key.begins_with(prefix):
				return domain
	return &""
