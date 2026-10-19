class_name ResultPanel
extends Control

## The panel in the middle of the screen when a room ends: the big line and the line under it ("ROOM CLEARED", "THE PAWN
## FALLS"). It is the one piece of the HUD that sits over the board, which the HUD safe zone allows for a reason: it is
## shown only when the room has ended (cleared, or the pawn fell), when no warning cell is live, and it is hidden again
## by the next room. The two lines are text keys the room named; the panel keeps them in the player's language.

@onready var text_label: Label = $Text

## Keeps the two lines in the player's language. Made on first use.
var _live_text: LiveText = null


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


## Shows the panel with the title and the line under it, both text keys.
func show_result(title_key: String, subtitle_key: String) -> void:
	visible = true
	if text_label != null:
		_live().set_text(text_label, "UI_RESULT_PANEL", {"title": TextKey.of(title_key), "subtitle": TextKey.of(subtitle_key)})


## Hides the panel and forgets its lines.
func hide_result() -> void:
	visible = false
	if text_label != null:
		_live().release(text_label)
		text_label.text = ""


func _live() -> LiveText:
	if _live_text == null:
		_live_text = LiveText.new()
		add_child(_live_text)
	return _live_text
