extends RefCounted

## The letters a font must have to write Vietnamese (docs/game-base-plan.md 8.9, 1.2; docs/assets/spec/ui_story.json,
## group fonts_ui): every precomposed Vietnamese letter that is not plain ASCII, in both cases. The vowels a, e, i, o, u, y
## take five tone marks (grave, acute, hook above, tilde, dot below); the vowels with their own mark (a with breve, a, e
## and o with circumflex, o and u with horn) take them stacked on top, which is what a font most often misses; and the
## stroked d. 12 vowels x 5 tones + 6 marked vowels + d = 67 lowercase letters, 134 in both cases. The plain ASCII
## letters are not listed: no font lacks them.
## No class_name on purpose: suites preload() it. It is a test helper, not a game script.

## The lowercase letters, grouped by vowel: tones of a, of a with breve, of a with circumflex, of e, of e with circumflex,
## of i, of o, of o with circumflex, of o with horn, of u, of u with horn, of y; then the six marked vowels and d.
const LOWERCASE_LETTERS := "àáảãạ" + "ằắẳẵặ" + "ầấẩẫậ" + "èéẻẽẹ" + "ềếểễệ" + "ìíỉĩị" + "òóỏõọ" + "ồốổỗộ" + "ờớởỡợ" + "ùúủũụ" + "ừứửữự" + "ỳýỷỹỵ" + "ăâêôơưđ"
## What a font may still be missing before it fails: nothing.
const EXPECTED_LETTER_COUNT := 134


## Every letter, lowercase then uppercase, as characters.
static func all_letters() -> PackedStringArray:
	var letters := PackedStringArray()
	for character in LOWERCASE_LETTERS:
		letters.append(character)
	for character in LOWERCASE_LETTERS.to_upper():
		letters.append(character)
	return letters


## The letters `font` has no glyph for (empty = it covers Vietnamese).
static func missing_in(font: Font) -> PackedStringArray:
	var missing := PackedStringArray()
	for letter in all_letters():
		if not font.has_char(letter.unicode_at(0)):
			missing.append(letter)
	return missing


## What a missing letter means: "ok" when none is missing; for a font the owner supplied, "fail" (the owner picked a
## font that cannot write Vietnamese, and the check says so); for the engine's default font, "warn" (it is a stand-in,
## and a Vietnamese player would see boxes in its place).
static func verdict(is_owner_supplied: bool, missing_count: int) -> String:
	if missing_count == 0:
		return "ok"
	return "fail" if is_owner_supplied else "warn"
