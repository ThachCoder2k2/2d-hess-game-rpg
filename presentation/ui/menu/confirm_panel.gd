class_name ConfirmPanel
extends Control

## A modal yes-or-no question laid over a screen: a dimmed backdrop that swallows the mouse, a panel with the
## question and two buttons (docs/game-base-plan.md 9.1, 9.2: New Game over a used slot asks to confirm; the
## pause menu's Restart Room and Quit to Title do the same). It decides nothing: it asks, and says which answer
## the player gave. The screen that owns it acts on `confirmed` and ignores `cancelled`.
##
## Keyboard and pad: focus starts on the SAFE answer (cancel) unless `cancel_is_default` is off, the engine's
## ui_left/ui_right/ui_accept move and press, and ui_cancel answers "no" from anywhere. The mouse works as on
## any button. Focus goes back to whatever held it when the question was asked. Hidden until ask().

## The player pressed the confirm button.
signal confirmed
## The player pressed the cancel button or ui_cancel.
signal cancelled

## The question.
@export var message_label: Label
## The button that says yes.
@export var confirm_button: Button
## The button that says no.
@export var cancel_button: Button
## The first button to take focus is cancel (the safe answer). Turn it off for a harmless question.
@export var cancel_is_default := true

## The control that had focus when the question was asked, to give it back afterwards.
var _focus_before_ask: Control = null
## Keeps the question and both answers in the player's language. Made on first use.
var _live_text: LiveText = null


func _ready() -> void:
	visible = false
	confirm_button.pressed.connect(_answer.bind(true))
	cancel_button.pressed.connect(_answer.bind(false))


## Shows the question and puts focus on the default button. The three arguments are text keys (their words come
## from TextService and follow a language change while the question is up); `message_params` fill the {name}s of
## the question.
func ask(message_key: String, confirm_key: String, cancel_key: String, message_params: Dictionary = {}) -> void:
	_live().set_text(message_label, message_key, message_params)
	_live().set_text(confirm_button, confirm_key)
	_live().set_text(cancel_button, cancel_key)
	_focus_before_ask = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	visible = true
	(cancel_button if cancel_is_default else confirm_button).grab_focus()


## Whether the question is on screen.
func is_asking() -> bool:
	return visible


## Takes the question off the screen WITHOUT answering it: the screen it was asked over went away. Neither signal is
## emitted and the focus is not given back.
func dismiss() -> void:
	visible = false
	_focus_before_ask = null


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause")):
		get_viewport().set_input_as_handled()
		_answer(false)


func _answer(yes: bool) -> void:
	if not visible:
		return
	visible = false
	if is_instance_valid(_focus_before_ask) and _focus_before_ask.is_visible_in_tree():
		_focus_before_ask.grab_focus()
	_focus_before_ask = null
	if yes:
		confirmed.emit()
	else:
		cancelled.emit()


func _live() -> LiveText:
	if _live_text == null:
		_live_text = LiveText.new()
		add_child(_live_text)
	return _live_text
