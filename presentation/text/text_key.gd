class_name TextKey
extends RefCounted

## A key waiting to be read: the words of a piece's name, a weapon, a room or a compass point, put into the
## {name} of ANOTHER line ("{piece} picked up {weapon}"). It is not turned into words when it is made but when the
## line is shown, and again every time the language changes, so the enemy in that line is renamed along with the
## sentence (TextService.t resolves a TextKey found among its params; LiveText keeps the params).
##
##     live_text.set_text(label, "MSG_ENEMY_PICKED_UP", {"piece": TextKey.of(piece_key), "weapon": TextKey.of(weapon_key)})
##
## A text that is not a key passes through as it is (the engine renders a key with no row as itself), which is what
## lets a test or a fixture hand in plain words.

## The key.
var key := ""
## The {name} values of the key's own line; they may be TextKeys too.
var params: Dictionary = {}
## Whether the words are shown in capitals (the HUD's strike line).
var is_uppercase := false


static func of(key_name: String, key_params: Dictionary = {}) -> TextKey:
	var text_key := TextKey.new()
	text_key.key = key_name
	text_key.params = key_params
	return text_key


## The same key, shown in capitals. Returns itself so a call can be chained: TextKey.of(key).uppercased().
func uppercased() -> TextKey:
	is_uppercase = true
	return self


## The words, in the current language.
func resolve() -> String:
	var text := TextService.t(key, params)
	return text.to_upper() if is_uppercase else text
