extends UnboundTest

## Continue (docs/game-base-plan.md 9.1, 9.3, 15 M4 acceptance `test_continue_loads_checkpoint`): the title offers
## Continue exactly when the slot holds a readable save, and Continue resumes the AS-BUILT resume point (M3b, 5.2 of
## the plan): the room and the entry of the LAST SAVE, with the latest checkpoint recorded beside it. The two
## differ on purpose here: the run was saved in T4 on the `from_b1` entry and its checkpoint is B1, and the pawn
## comes up in T4, not in B1, because nothing in the game sends the pawn back to a checkpoint (a checkpoint is where
## Courage refills). Everything the save held comes back: the cleared room, the sword, the play time. A save whose
## newest file was damaged and whose previous one is intact resumes from the previous one and says so, on the title
## and on the status line of the room. The name is the plan's; the assertion is the resume point the code has.

const Support := preload("res://tests/bridge/bridge_support.gd")
const ShellSupport := preload("res://tests/shell/shell_support.gd")
const SaveSupport := preload("res://tests/support/save_test_support.gd")
const SUITE_NAME := "continue"

const T3 := &"t3_first_pawn_clash"


func _init() -> void:
	suite_title = "CONTINUE LOADS CHECKPOINT TEST"
	watchdog_seconds = 40.0
	call_deferred("_run")


func _run() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	ShellSupport.plant_run(save_service, ShellSupport.run_in_t4_with_b1_checkpoint())
	var app := await ShellSupport.boot_app(self)
	app.transition.default_fade_seconds = 0.04
	var title := ShellSupport.title_of(app)

	# --- The title offers Continue, with the slot card ---
	_expect(title != null and title.continue_button.visible and title.card_label.visible, "the title offers Continue for a readable save")
	if title == null:
		Support.end_suite(self, save_service)
		return
	_expect(title.continue_button.has_focus(), "and Continue has the focus")
	_expect(title.card_label.text.contains("Broken Rule Yard") and title.card_label.text.contains("1h 02m played") and title.card_label.text.contains("2025-"), "the card names the room, the time played and the day saved (%s)" % title.card_label.text)
	_expect(title.notice_label.text.is_empty() and not title.notice_label.visible, "with no notice")
	_expect(not bool(save_service.get("has_session")), "nothing is loaded until Continue is chosen (no auto-load)")

	# --- Continue: the room and entry of the last save, not the checkpoint ---
	title.continue_button.pressed.emit()
	await app.until_settled()
	var game := ShellSupport.game_of(app)
	_expect(game != null and app.game_flow.state == GameFlow.State.PLAYING and app.game_flow.start_mode == GameFlow.StartMode.CONTINUE, "Continue starts the game, as a continue")
	if game == null:
		Support.end_suite(self, save_service)
		return
	_expect(game.current_zone_id == ShellSupport.T4, "the pawn is in the room of the last save (T4), not in the checkpoint's")
	var run: SaveData = Support.run_of(save_service)
	_expect(run.room_id == ShellSupport.T4 and run.room_entry_id == &"from_b1", "the run names that room and its entry")
	_expect(Support.player_cell(game) == Support.entry_cell(game, game.current_room, &"from_b1"), "and the hero stands on the entry it was saved on")
	_expect(run.checkpoint_zone_id == ShellSupport.B1 and run.checkpoint_entry_id == &"west_entry", "the checkpoint of the save (B1) is recorded and is a different place")
	_expect(game.current_zone_id != run.checkpoint_zone_id, "nothing returned the pawn to the checkpoint")
	_expect(Support.player_combat(game).sword_unlocked and run.has_unlock(&"wooden_sword"), "the sword the save held is in the hero's hand")
	_expect(run.cleared_room_ids.has(String(T3)) and float(run.play_time_seconds) >= 3725.0, "the cleared room and the play time come back")
	_expect(Support.player_health(game).current == Support.player_health(game).max_value, "Courage is full (health never saves)")
	_expect(not game.hud.objective_line.text_label.text.contains("damaged"), "no notice on the status line for a clean save")

	# --- Quitting writes nothing; Continue again is the same place ---
	var file_before := SaveSupport.text_of(String(save_service.call("slot_path", 0)))
	app.game_flow.quit_to_title()
	await app.until_settled()
	_expect(SaveSupport.text_of(String(save_service.call("slot_path", 0))) == file_before, "Quit to Title wrote nothing (a quit is not a success event)")
	var title_again := ShellSupport.title_of(app)
	if title_again != null:
		title_again.continue_button.pressed.emit()
		await app.until_settled()
		var game_again := ShellSupport.game_of(app)
		_expect(game_again != null and game_again.current_zone_id == ShellSupport.T4 and Support.player_cell(game_again) == Support.entry_cell(game_again, game_again.current_room, &"from_b1"), "a second Continue lands in the same place")
		app.game_flow.quit_to_title()
		await app.until_settled()

	# --- A damaged newest file: the previous save is loaded and the player is told ---
	# The disk holds the T4 run. A newer save (B1) is written over it, which keeps the T4 run as the .bak, and then
	# the newest file is damaged: the .bak (T4) is what loads, and B1 must not.
	var slot_path := String(save_service.call("slot_path", 0))
	var newer_run := ShellSupport.run_in_t4_with_b1_checkpoint()
	newer_run.room_id = ShellSupport.B1
	newer_run.room_entry_id = &"west_entry"
	save_service.call("configure", save_service.call("root_directory"))
	save_service.set("state", newer_run)
	save_service.call("write_slot", 0, newer_run)
	_expect(FileAccess.file_exists(slot_path + SaveFile.BACKUP_SUFFIX), "setup: the newer save left the T4 run as the .bak")
	SaveSupport.plant(slot_path, "garbage, not a save\n")
	save_service.call("configure", save_service.call("root_directory"))
	var title_with_notice := ShellSupport.title_of(app)
	if title_with_notice != null:
		title_with_notice.configure(TitleSummary.from_save(save_service, "", 0), false)
		_expect(title_with_notice.continue_button.visible and title_with_notice.notice_label.visible and title_with_notice.notice_label.text == TextService.t(TitleSummary.NOTICE_TEXT_KEY_BY_KEY[SaveLoadResult.NOTICE_BACKUP_USED]), "the title still offers Continue and shows the one-line notice")
		_expect(title_with_notice.card_label.text.contains("Broken Rule Yard") and not title_with_notice.card_label.text.contains("Black Pawn Captain"), "the card describes the save that will load (the .bak, T4)")
		title_with_notice.continue_button.pressed.emit()
		await app.until_settled()
		var game_from_backup := ShellSupport.game_of(app)
		_expect(game_from_backup != null and game_from_backup.current_zone_id == ShellSupport.T4, "Continue loaded the previous save, not the damaged newer one")
		_expect(game_from_backup != null and game_from_backup.hud.objective_line.text_label.text == TextService.t(TitleSummary.NOTICE_TEXT_KEY_BY_KEY[SaveLoadResult.NOTICE_BACKUP_USED]), "and the status line of the room says so")
		_expect(app.game_flow.load_notice_key == SaveLoadResult.NOTICE_BACKUP_USED, "the flow remembers the notice")

	Support.end_suite(self, save_service)
