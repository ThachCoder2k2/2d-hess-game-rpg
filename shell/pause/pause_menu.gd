class_name PauseMenu
extends Control

## The pause menu (docs/game-base-plan.md 9.2 "Pause"): Resume, Book, Settings, Controls, Restart Room (confirm), Quit to
## Title (confirm, naming the last checkpoint). It lives in AppRoot's menu layer, which keeps processing while the tree is
## paused (PROCESS_MODE_ALWAYS), and it decides nothing: it shows what AppRoot hands it and says what the player chose
## through signals. AppRoot turns them into GameFlow requests; the menu never touches the flow or the room.
##
## Esc and Start (the `pause` action) and the engine's ui_cancel close the menu, from the top list only: a question
## on screen answers "no" first (ConfirmPanel), and a screen opened over the menu takes the key before this
## node does. The key that closes the menu is also read as a press of Pause by the game scene, which ticks again
## in the same engine frame; GameFlow refuses a pause in the frame one was lifted, so the menu stays closed.
##
## Restart Room is a menu command and not a bound action (D-18): R is Call child.

## Resume was chosen, or the pause key was pressed.
signal resume_requested
## The Book entry was chosen: the menu closes and the Book opens over the room.
signal book_requested
## The Settings entry was chosen: the settings screen opens over the menu, which stays where it is.
signal settings_requested
## The Controls entry was chosen: the Controls panel opens over the menu, which stays where it is.
signal controls_requested
## Restart Room was chosen and confirmed.
signal restart_confirmed
## Quit to Title was chosen and confirmed.
signal quit_confirmed

@export var resume_button: Button
@export var book_button: Button
@export var settings_button: Button
@export var controls_button: Button
@export var restart_button: Button
@export var quit_button: Button
## The container of the buttons; switched off while a question is up.
@export var menu: Control
@export var confirm_panel: ConfirmPanel

var _summary := PauseSummary.new()
## Which question the confirm panel is asking: &"restart", &"quit" or &"" for none.
var _question: StringName = &""


func _ready() -> void:
	visible = false
	resume_button.pressed.connect(func() -> void: resume_requested.emit())
	book_button.pressed.connect(func() -> void: book_requested.emit())
	settings_button.pressed.connect(func() -> void: settings_requested.emit())
	controls_button.pressed.connect(func() -> void: controls_requested.emit())
	restart_button.pressed.connect(_ask.bind(&"restart"))
	quit_button.pressed.connect(_ask.bind(&"quit"))
	confirm_panel.confirmed.connect(_on_confirmed)
	confirm_panel.cancelled.connect(_on_cancelled)


## Shows the menu with the first button focused. `summary` is what the questions say about the run.
func open(summary: PauseSummary) -> void:
	_summary = summary
	_question = &""
	menu.process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	resume_button.grab_focus()


## Hides the menu and drops a question that was still waiting.
func close() -> void:
	visible = false
	_question = &""
	menu.process_mode = Node.PROCESS_MODE_INHERIT
	confirm_panel.dismiss()


## Whether the menu is on screen.
func is_open() -> bool:
	return visible


## A panel opened over the menu (Controls, Settings): its buttons go quiet so a key or the mouse reaches only the panel,
## and come back when the panel is closed. The panel gives focus back to the button that opened it.
func set_covered(covered: bool) -> void:
	menu.process_mode = Node.PROCESS_MODE_DISABLED if covered else Node.PROCESS_MODE_INHERIT


## The question the confirm panel is asking now: &"restart", &"quit", or &"" for none.
func question_on_screen() -> StringName:
	return _question


func _unhandled_input(event: InputEvent) -> void:
	if not visible or confirm_panel.is_asking():
		return
	if event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		resume_requested.emit()


func _ask(question: StringName) -> void:
	_question = question
	menu.process_mode = Node.PROCESS_MODE_DISABLED
	if question == &"restart":
		confirm_panel.ask(PauseSummary.RESTART_QUESTION_KEY, PauseSummary.RESTART_YES_KEY, PauseSummary.RESTART_NO_KEY)
	else:
		confirm_panel.ask(PauseSummary.QUIT_QUESTION_KEY, PauseSummary.QUIT_YES_KEY, PauseSummary.QUIT_NO_KEY, _summary.quit_question_params())


func _on_confirmed() -> void:
	var answered := _question
	_question = &""
	menu.process_mode = Node.PROCESS_MODE_INHERIT
	if answered == &"restart":
		restart_confirmed.emit()
	elif answered == &"quit":
		quit_confirmed.emit()


func _on_cancelled() -> void:
	var asked := _question
	_question = &""
	menu.process_mode = Node.PROCESS_MODE_INHERIT
	(restart_button if asked == &"restart" else quit_button).grab_focus()
