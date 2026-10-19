extends UnboundTest

## The shared yes-or-no question (presentation/ui/menu/confirm_panel.tscn, docs/game-base-plan.md 9.1, 9.2): hidden
## until asked, focus on the safe answer, ui_cancel answers no from anywhere, the mouse cannot reach what is behind
## it, focus cannot leave it by arrow keys, and focus goes back where it was. The title's New Game and the pause
## menu's Restart Room and Quit to Title use it.

var answers: Array[String] = []


func _init() -> void:
	suite_title = "CONFIRM PANEL TEST"
	call_deferred("_run")


func _run() -> void:
	var scene := load("res://presentation/ui/menu/confirm_panel.tscn") as PackedScene
	var host := Control.new()
	var opener := Button.new()
	opener.text = "opens the question"
	host.add_child(opener)
	var panel := scene.instantiate() as ConfirmPanel
	panel.confirmed.connect(func() -> void: answers.append("yes"))
	panel.cancelled.connect(func() -> void: answers.append("no"))
	host.add_child(panel)
	root.add_child(host)
	await process_frame

	_expect(not panel.visible and not panel.is_asking(), "the question is hidden until asked")
	_expect((panel.get_node("Dim") as Control).mouse_filter == Control.MOUSE_FILTER_STOP, "its backdrop swallows the mouse, so nothing behind it can be pressed")

	# --- Asking: the texts, and the focus on the safe answer ---
	opener.grab_focus()
	panel.ask("Leave the room?", "Leave", "Stay")
	_expect(panel.visible and panel.is_asking(), "ask() shows it")
	_expect(panel.message_label.text == "Leave the room?" and panel.confirm_button.text == "Leave" and panel.cancel_button.text == "Stay", "with the question and both answers")
	_expect(panel.cancel_button.has_focus(), "focus starts on the safe answer")

	# --- Arrow keys cannot leave the panel ---
	_expect(panel.confirm_button.focus_neighbor_top == NodePath(".") and panel.confirm_button.focus_neighbor_bottom == NodePath(".") and panel.cancel_button.focus_neighbor_top == NodePath("."), "up and down stay on the button they are on")
	_expect(panel.confirm_button.get_node(panel.confirm_button.focus_neighbor_left) == panel.cancel_button and panel.cancel_button.get_node(panel.cancel_button.focus_neighbor_right) == panel.confirm_button, "left and right swap between the two answers")

	# --- Pressing a button answers once and gives the focus back ---
	panel.confirm_button.pressed.emit()
	_expect(answers == ["yes"] and not panel.visible, "pressing yes answers yes and hides the question")
	_expect(opener.has_focus(), "and focus goes back to the control that opened it")
	panel.confirm_button.pressed.emit()
	_expect(answers == ["yes"], "a button pressed after the answer says nothing")

	# --- ui_cancel is a no, from any focus ---
	answers.clear()
	panel.ask("Leave the room?", "Leave", "Stay")
	panel.confirm_button.grab_focus()
	var cancel_event := InputEventAction.new()
	cancel_event.action = &"ui_cancel"
	cancel_event.pressed = true
	panel._unhandled_input(cancel_event)
	_expect(answers == ["no"] and not panel.visible, "ui_cancel answers no and hides the question")
	var cancel_when_hidden := InputEventAction.new()
	cancel_when_hidden.action = &"ui_cancel"
	cancel_when_hidden.pressed = true
	panel._unhandled_input(cancel_when_hidden)
	_expect(answers == ["no"], "and a ui_cancel while it is hidden is not an answer")

	# --- A harmless question may start on yes ---
	panel.cancel_is_default = false
	panel.ask("Continue?", "Yes", "No")
	_expect(panel.confirm_button.has_focus(), "with cancel_is_default off, focus starts on yes")
	panel.cancel_button.pressed.emit()
	_expect(answers == ["no", "no"], "pressing no answers no")

	host.queue_free()
	finish()
