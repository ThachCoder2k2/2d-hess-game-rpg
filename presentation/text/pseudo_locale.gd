class_name PseudoLocale
extends RefCounted

## The generated test language (docs/game-base-plan.md 8.9): every string the game can show, made 40 percent longer
## and accented, so a box that only just holds the English words shows it. It is what a translation into a
## wordier language does to a layout, found before a translator has to find it. `test_layout_pseudo_locale` puts the
## HUD, the title, the pause menu and the settings screen through it at 640 x 360.
##
## Godot has a pseudolocalization of its own (`TranslationServer.pseudolocalization_enabled`). It is not used
## because it corrupts the `{name}` placeholders TextService fills (it accents the name inside the braces:
## "{pawn}" becomes "{ṕáŵή}" and String.format then fills nothing), and because it is a switch and not a language:
## it cannot be picked in the language list or asserted on by a test. Placeholders here pass through untouched.
##
## Lengthening: the extra characters are the letters of the string repeated, evenly spread, so the line grows as a
## real longer word would and not by a run of narrow padding. The rule is deterministic (the same string always
## gives the same result), so a test can pin it.

## How much longer than the source the visible text becomes (the visible text is what is left when the
## placeholders are taken out).
const EXPANSION_RATIO := 0.4
## The padding used for a string that has no letter to repeat (a lone placeholder, a number).
const PADDING := "·"

## letter -> its accented look. A letter missing here is left as it is.
const ACCENTED_LETTER := {
	"a": "á", "c": "ç", "d": "đ", "e": "é", "g": "ğ", "i": "í", "l": "ł", "n": "ñ", "o": "ö", "r": "ř",
	"s": "š", "t": "ŧ", "u": "ü", "y": "ý", "z": "ž",
	"A": "Å", "C": "Ç", "D": "Đ", "E": "É", "G": "Ğ", "I": "Í", "L": "Ł", "N": "Ñ", "O": "Ö", "R": "Ř",
	"S": "Š", "T": "Ŧ", "U": "Ü", "Y": "Ý", "Z": "Ž",
}

## What is a placeholder and so must come through unchanged: a `{name}` and a printf conversion (`%s`, `%d`, `%02d`,
## `%.1f`, `%%`).
static var _placeholder_regex: RegEx = RegEx.create_from_string("\\{[^{}]*\\}|%[-+ 0#]*[0-9]*(?:\\.[0-9]+)?[sdifxXc%]")


## `text` in the pseudo-language.
static func pseudolocalize(text: String) -> String:
	var pieces := _split_into_pieces(text)
	var letter_count := 0
	var visible_length := 0
	for piece in pieces:
		if not piece["is_placeholder"]:
			var piece_text: String = piece["text"]
			visible_length += piece_text.length()
			for character in piece_text:
				if _is_letter(character):
					letter_count += 1
	var extra_count := ceili(visible_length * EXPANSION_RATIO)
	var result := ""
	var letters_seen := 0
	for piece in pieces:
		var piece_text: String = piece["text"]
		if piece["is_placeholder"]:
			result += piece_text
			continue
		for character in piece_text:
			if not _is_letter(character):
				result += character
				continue
			var accented: String = ACCENTED_LETTER.get(character, character)
			var repeats := 1 + _extra_up_to(letters_seen + 1, extra_count, letter_count) - _extra_up_to(letters_seen, extra_count, letter_count)
			result += accented.repeat(repeats)
			letters_seen += 1
	if letter_count == 0:
		result += PADDING.repeat(extra_count)
	return result


## `text` with its placeholders taken out: the part a player reads and a layout has to hold.
static func without_placeholders(text: String) -> String:
	var readable := ""
	for piece in _split_into_pieces(text):
		if not piece["is_placeholder"]:
			readable += piece["text"]
	return readable


## The length of `text` without its placeholders.
static func visible_length(text: String) -> int:
	return without_placeholders(text).length()


## The placeholders of `text`, in order (`{pawn}`, `%d`).
static func placeholders_of(text: String) -> PackedStringArray:
	var found := PackedStringArray()
	for placeholder_match in _placeholder_regex.search_all(text):
		found.append(placeholder_match.get_string())
	return found


## A Translation in the pseudo-language holding every row of `sources` (the source language's files), each
## row run through pseudolocalize().
static func build_translation(sources: Array[Translation]) -> Translation:
	var pseudo := Translation.new()
	pseudo.locale = String(TextService.PSEUDO_LANGUAGE)
	for source in sources:
		for key in source.get_message_list():
			pseudo.add_message(key, pseudolocalize(String(source.get_message(key))))
	return pseudo


## `text` cut into runs: { "text": String, "is_placeholder": bool }.
static func _split_into_pieces(text: String) -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	var cursor := 0
	for placeholder_match in _placeholder_regex.search_all(text):
		if placeholder_match.get_start() > cursor:
			pieces.append({"text": text.substr(cursor, placeholder_match.get_start() - cursor), "is_placeholder": false})
		pieces.append({"text": placeholder_match.get_string(), "is_placeholder": true})
		cursor = placeholder_match.get_end()
	if cursor < text.length():
		pieces.append({"text": text.substr(cursor), "is_placeholder": false})
	return pieces


## How many of the `extra_count` added characters belong to the first `letters_done` of `letter_count` letters, so
## the additions are spread evenly and add up to exactly `extra_count` after the last letter.
static func _extra_up_to(letters_done: int, extra_count: int, letter_count: int) -> int:
	return floori(float(letters_done) * extra_count / letter_count)


static func _is_letter(character: String) -> bool:
	return (character >= "a" and character <= "z") or (character >= "A" and character <= "Z")
