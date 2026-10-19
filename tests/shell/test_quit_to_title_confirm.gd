extends UnboundTest

## Quit to Title in the pause menu (docs/game-base-plan.md 9.2, ledger req 192): it asks first, the question NAMES THE LAST
## CHECKPOINT and says that progress since the last save is lost, "keep playing" and Esc leave the game exactly as it was,
## and "quit to title" lets the room go and writes nothing (a quit is not a success event, R17). A run that has reached no
## checkpoint says so.

const Support := preload("res://tests/bridge/bridge_support.gd")
const ShellSupport := preload("res://tests/shell/shell_support.gd")
const SaveSupport := preload("res://tests/support/save_test_support.gd")
const SUITE_NAME := "quit_confirm"


func _init() -> void:
	suite_title = "QUIT TO TITLE CONFIRM TEST"
	watchdog_seconds = 40.0
	call_deferred("_run")


func _run() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	var app := await ShellSupport.boot_into_t4(self, save_service)
	var game := ShellSupport.game_of(app)
	if game == null:
		_expect(false, "setup: Continue brought the game up in T4")
		Support.end_suite(self, save_service)
		return
	var flow := app.game_flow
	var menu := app.pause_menu
	var slot_path := String(save_service.call("slot_path", 0))
	var file_before := SaveSupport.text_of(slot_path)

	# --- The question names the checkpoint ---
	flow.request_pause()
	menu.quit_button.pressed.emit()
	_expect(menu.question_on_screen() == &"quit" and menu.confirm_panel.is_asking(), "Quit to Title asks first")
	var question := menu.confirm_panel.message_label.text
	_expect(question.contains("Black Pawn Captain"), "the question names the last checkpoint, the boss room B1 (%s)" % question.replace("\n", " / "))
	_expect(question.contains("Progress since your last save is lost"), "and says what is lost")
	_expect(menu.confirm_panel.confirm_button.text == TextService.t(PauseSummary.QUIT_YES_KEY) and menu.confirm_panel.cancel_button.has_focus(), "with the safe answer focused")

	# --- No: everything stays ---
	menu.confirm_panel.cancel_button.pressed.emit()
	_expect(menu.is_open() and flow.state == GameFlow.State.PAUSED and is_instance_valid(game) and menu.quit_button.has_focus(), "'keep playing' leaves the menu up with focus on Quit to Title, and the room alive")
	menu.quit_button.pressed.emit()
	await ShellSupport.tap_key(self, KEY_ESCAPE, 1)
	_expect(menu.is_open() and flow.state == GameFlow.State.PAUSED and not menu.confirm_panel.is_asking(), "Esc answers no as well")

	# --- Yes: the title, the room gone, nothing written ---
	menu.quit_button.pressed.emit()
	menu.confirm_panel.confirm_button.pressed.emit()
	_expect(flow.state == GameFlow.State.TITLE and not paused and not menu.is_open(), "yes goes to the title, lifts the pause and closes the menu")
	await app.until_settled()
	await process_frame
	var title := ShellSupport.title_of(app)
	_expect(title != null and not is_instance_valid(game), "the title is on screen and the room was freed")
	_expect(SaveSupport.text_of(slot_path) == file_before, "nothing was written: a quit is not a success event")
	_expect(title != null and title.continue_button.visible, "and Continue brings the saved run back")

	# --- A run that has reached no checkpoint says so ---
	Support.forget_the_run(save_service)
	if title != null:
		title.new_game_button.pressed.emit()
		title.confirm_panel.confirm_button.pressed.emit()
		await app.until_settled()
		flow.request_pause()
		menu.quit_button.pressed.emit()
		var fresh_question := menu.confirm_panel.message_label.text
		_expect(fresh_question.contains(TextService.t(PauseSummary.NO_CHECKPOINT_NAME_KEY)), "before any checkpoint the question says so (%s)" % fresh_question.replace("\n", " / "))
		menu.confirm_panel.cancel_button.pressed.emit()
		flow.quit_to_title()
		await app.until_settled()

	Support.end_suite(self, save_service)
