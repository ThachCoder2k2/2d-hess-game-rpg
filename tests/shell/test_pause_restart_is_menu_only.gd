extends UnboundTest

## D-18 (docs/game-base-plan.md 2.1, 2.3 T-1, 9.2, ledger req 15): R is Call child, and restarting a room is a command of
## the pause menu, behind a confirm. There is no restart action and no restart key.
##   - the InputMap has no restart_room, and R is the Call child action and nothing else; GameFlow has no restart-key reason;
##   - pressing R in a room does nothing visible: nobody rebuilds the room, the flow does not move, nothing is saved;
##   - Restart Room in the pause menu asks first; "keep playing" (or Esc) leaves everything as it was and the menu up; "restart
##     room" resumes the tree and rebuilds the room through GameFlow with the menu's reason, saving nothing, with the hero
##     on the entry it came by and full Courage.

const Support := preload("res://tests/bridge/bridge_support.gd")
const ShellSupport := preload("res://tests/shell/shell_support.gd")
const SaveSupport := preload("res://tests/support/save_test_support.gd")
const SUITE_NAME := "pause_restart"


func _init() -> void:
	suite_title = "PAUSE RESTART IS MENU ONLY TEST"
	watchdog_seconds = 40.0
	call_deferred("_run")


func _run() -> void:
	_expect(not InputMap.has_action(&"restart_room"), "the InputMap has no restart_room action")
	_expect(InputMap.has_action(&"call_child"), "R is the Call child action")
	var constants: Dictionary = GameFlow.new().get_script().get_script_constant_map()
	_expect(constants.has("REASON_RESTART_MENU") and not constants.has("REASON_RESTART_KEY"), "and GameFlow knows a restart from the menu and no restart from a key")

	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	var app := await ShellSupport.boot_into_t4(self, save_service)
	var game := ShellSupport.game_of(app)
	if game == null:
		_expect(false, "setup: Continue brought the game up in T4")
		Support.end_suite(self, save_service)
		return
	Support.remove_enemy_ai(game)
	var flow := app.game_flow
	var respawns: Array[StringName] = []
	flow.respawned.connect(func(reason: StringName) -> void: respawns.append(reason))
	var slot_path := String(save_service.call("slot_path", 0))
	var file_before := SaveSupport.text_of(slot_path)
	var world_before := Support.ecs_of(game)
	var entry_cell := Support.player_cell(game)

	# --- R does nothing visible ---
	await ShellSupport.tap_key(self, KEY_R, 4)
	for _frame in 3:
		await process_frame
	_expect(respawns.is_empty() and Support.ecs_of(game) == world_before and flow.state == GameFlow.State.PLAYING and not flow.respawn_is_pending(), "pressing R in the room rebuilds nothing and moves nothing")
	_expect(not paused and not app.pause_menu.is_open(), "and opens nothing")
	_expect(SaveSupport.text_of(slot_path) == file_before, "and saves nothing")

	# --- Pause, Restart Room, and say no ---
	Support.damage_player(game, 1)
	Support.wait_out_invulnerability(game)
	var wounded_courage: int = Support.player_health(game).current
	_expect(wounded_courage < Support.player_health(game).max_value, "setup: the hero is wounded")
	flow.request_pause()
	var menu := app.pause_menu
	_expect(menu.is_open() and menu.question_on_screen() == &"", "setup: the pause menu is up, with no question")
	menu.restart_button.pressed.emit()
	_expect(menu.question_on_screen() == &"restart" and menu.confirm_panel.is_asking(), "Restart Room asks first")
	_expect(menu.confirm_panel.message_label.text == TextService.t(PauseSummary.RESTART_QUESTION_KEY) and menu.confirm_panel.confirm_button.text == TextService.t(PauseSummary.RESTART_YES_KEY), "with its question and its two answers")
	_expect(menu.confirm_panel.cancel_button.has_focus(), "and focus on the safe answer")
	_expect(flow.state == GameFlow.State.PAUSED and respawns.is_empty(), "nothing happens while the question is up")
	await ShellSupport.tap_key(self, KEY_ESCAPE, 1)
	await process_frame
	_expect(not menu.confirm_panel.is_asking() and menu.is_open() and flow.state == GameFlow.State.PAUSED, "Esc answers no: the question closes and the menu stays up")
	_expect(menu.restart_button.has_focus(), "with focus back on Restart Room")
	_expect(respawns.is_empty() and Support.ecs_of(game) == world_before, "nothing was rebuilt")
	menu.restart_button.pressed.emit()
	menu.confirm_panel.cancel_button.pressed.emit()
	_expect(menu.is_open() and flow.state == GameFlow.State.PAUSED and respawns.is_empty(), "the 'keep playing' button answers no too")

	# --- Say yes ---
	menu.restart_button.pressed.emit()
	menu.confirm_panel.confirm_button.pressed.emit()
	_expect(not paused and not menu.is_open(), "yes resumes the tree and closes the menu")
	_expect(await Support.wait_for_respawn(self, game), "and the room is rebuilt")
	await ShellSupport.wait_until(self, func() -> bool: return app.transition.is_clear())
	_expect(respawns == [GameFlow.REASON_RESTART_MENU] and flow.last_respawn_reason == GameFlow.REASON_RESTART_MENU, "through GameFlow, with the menu's reason")
	_expect(flow.state == GameFlow.State.PLAYING and game.current_zone_id == ShellSupport.T4, "the game is playing in the same room")
	_expect(Support.player_cell(game) == entry_cell, "the hero stands on the entry it came by")
	_expect(Support.player_health(game).current == Support.player_health(game).max_value, "with full Courage (it was %d)" % wounded_courage)
	_expect(SaveSupport.text_of(slot_path) == file_before, "and nothing was saved: a restart is not a success event")

	Support.end_suite(self, save_service)
