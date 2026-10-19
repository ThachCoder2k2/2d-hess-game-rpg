class_name ObjectiveLine
extends HudWidget

## The line of the bottom strip that tells the player what the room asks and what just happened: the room's opening
## line, the objective, and every sentence the game says when something happens (docs/game-base-plan.md D-29, 9.2). The
## words come from the MessageBridge (which events say what), and the HUD hands them here as a text key and its
## {name}s; the line keeps them in the player's language, so a language switch redraws the sentence with the names
## inside it. This widget decides nothing: it shows one line, or none.

@onready var text_label: Label = $Line

## Keeps the line in the player's language. Made on first use.
var _live_text: LiveText = null


## Puts the words of `key` on the line, `params` filling its {name}s. An empty key empties the line.
func say(key: String, params: Dictionary = {}) -> void:
	if text_label == null:
		return
	if key.is_empty():
		clear()
	else:
		_live().set_text(text_label, key, params)


## Empties the line.
func clear() -> void:
	if text_label == null:
		return
	_live().release(text_label)
	text_label.text = ""


func _live() -> LiveText:
	if _live_text == null:
		_live_text = LiveText.new()
		add_child(_live_text)
	return _live_text
