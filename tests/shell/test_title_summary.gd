extends UnboundTest

## What the title shows about the saved run (shell/title/title_summary.gd, docs/game-base-plan.md 9.2): Continue
## exactly when the slot holds readable progress, the slot card, the one-line notice for a damaged, too-old or
## newer save, the completed mark and the version string. Read from a real SaveService on throwaway folders; the
## summary reads the slot without making it the run and writes nothing.

const SaveSupport := preload("res://tests/support/save_test_support.gd")

var roots_to_remove: Array[String] = []


func _init() -> void:
	suite_title = "TITLE SUMMARY TEST"
	_the_version_and_a_missing_service()
	_no_save_no_continue()
	_a_readable_save_is_offered_with_its_card()
	_a_damaged_newest_file_falls_back_to_the_backup_with_a_notice()
	_nothing_readable_offers_no_continue()
	_the_words_of_the_card()
	_the_completed_mark()
	for root_to_remove in roots_to_remove:
		SaveSupport.remove_root(root_to_remove)
	finish()


func _service(suite_name: String) -> Node:
	var root_directory := SaveSupport.make_root(suite_name)
	roots_to_remove.append(root_directory)
	return SaveSupport.new_service(root_directory)


func _the_version_and_a_missing_service() -> void:
	var without_service := TitleSummary.from_save(null, "0.4.0")
	_expect(without_service.version_text == "v0.4.0" and not without_service.can_continue and without_service.notice_text.is_empty() and without_service.card_text.is_empty() and not without_service.completed, "with no save service: the version only, no Continue, no notice")
	_expect(TitleSummary.from_save(null, "").version_text.is_empty(), "a project with no version shows none")
	_expect(String(ProjectSettings.get_setting("application/config/version", "")).count(".") == 2, "the project sets a major.minor.patch version (%s)" % ProjectSettings.get_setting("application/config/version", ""))


func _no_save_no_continue() -> void:
	var service := _service("title_none")
	var summary := TitleSummary.from_save(service, "1.0.0")
	_expect(not summary.can_continue and summary.card_text.is_empty() and summary.notice_text.is_empty() and summary.notice_key == &"", "a first launch: no Continue, no card, no notice")
	_expect(not service.has_session and not FileAccess.file_exists(service.slot_path(0)), "and reading it started no run and wrote nothing")


func _a_readable_save_is_offered_with_its_card() -> void:
	var service := _service("title_readable")
	var run := SaveSupport.full_data()
	run.play_time_seconds = 5400.0
	run.saved_at_unix = 0
	service.new_game(0)
	service.state = run
	service.request_save(&"room_cleared")
	var relaunch := SaveSupport.new_service(service.root_directory())
	var summary := TitleSummary.from_save(relaunch, "1.0.0")
	_expect(summary.can_continue and summary.notice_text.is_empty(), "a readable save is offered, with no notice")
	_expect(summary.card_text.begins_with("Broken Rule Yard  |  1h 30m played"), "the card names the room and the time played (%s)" % summary.card_text)
	_expect(not relaunch.has_session, "and reading the slot did not load it: Continue loads")


func _a_damaged_newest_file_falls_back_to_the_backup_with_a_notice() -> void:
	var service := _service("title_backup")
	service.new_game(0)
	service.state.room_id = &"t2_fallen_sword_tile"
	service.request_save(&"room_cleared")
	service.state.room_id = &"t3_first_pawn_clash"
	service.request_save(&"room_cleared")
	SaveSupport.plant(service.slot_path(0), "garbage\n")
	var summary := TitleSummary.from_save(SaveSupport.new_service(service.root_directory()), "1.0.0")
	_expect(summary.can_continue and summary.notice_key == SaveLoadResult.NOTICE_BACKUP_USED, "a damaged newest file with an intact .bak: Continue, and the backup notice")
	_expect(summary.notice_text == TitleSummary.NOTICE_TEXT_BY_KEY[SaveLoadResult.NOTICE_BACKUP_USED] and not summary.notice_text.is_empty(), "with its sentence")
	_expect(summary.card_text.begins_with("Fallen Sword Tile"), "and the card describes the save that will load (the previous one: %s)" % summary.card_text)


func _nothing_readable_offers_no_continue() -> void:
	var damaged := _service("title_damaged")
	SaveSupport.plant(damaged.slot_path(0), "garbage\n")
	var damaged_summary := TitleSummary.from_save(damaged, "1.0.0")
	_expect(not damaged_summary.can_continue and damaged_summary.card_text.is_empty() and damaged_summary.notice_key == SaveLoadResult.NOTICE_NEW_GAME_AFTER_DAMAGE and not damaged_summary.notice_text.is_empty(), "a damaged file with no backup: no Continue, and the notice says New Game starts over")

	var newer := _service("title_newer")
	var newer_file := ConfigFile.new()
	newer_file.set_value("meta", "version", SaveData.FORMAT_VERSION + 1)
	SaveSupport.plant(newer.slot_path(0), SaveFile.encode(newer_file))
	var newer_summary := TitleSummary.from_save(newer, "1.0.0")
	_expect(not newer_summary.can_continue and newer_summary.notice_text == "This save needs a newer game.", "a save from a newer game: no Continue, and the plan's sentence")

	var obsolete := _service("title_obsolete")
	var old_file := ConfigFile.new()
	old_file.set_value("meta", "version", 1)
	SaveSupport.plant(obsolete.slot_path(0), SaveFile.encode(old_file))
	var obsolete_summary := TitleSummary.from_save(obsolete, "1.0.0")
	_expect(not obsolete_summary.can_continue and obsolete_summary.notice_key == SaveLoadResult.NOTICE_OBSOLETE_SAVE and not obsolete_summary.notice_text.is_empty(), "a save too old to migrate: no Continue, and a notice")

	var every_key_has_a_sentence := true
	for notice_key: StringName in [SaveLoadResult.NOTICE_BACKUP_USED, SaveLoadResult.NOTICE_NEW_GAME_AFTER_DAMAGE, SaveLoadResult.NOTICE_OBSOLETE_SAVE, SaveLoadResult.NOTICE_NEWER_GAME]:
		every_key_has_a_sentence = every_key_has_a_sentence and not String(TitleSummary.NOTICE_TEXT_BY_KEY.get(notice_key, "")).is_empty()
	_expect(every_key_has_a_sentence, "every notice key the loader can raise has a sentence")


func _the_words_of_the_card() -> void:
	_expect(TitleSummary.room_title(&"t4_broken_rule_yard") == "Broken Rule Yard", "a room id is a title without its act-and-number prefix")
	_expect(TitleSummary.room_title(&"h1_chess_rug_hub") == "Chess Rug Hub" and TitleSummary.room_title(&"b1_black_pawn_captain") == "Black Pawn Captain", "for the hub and a boss room too")
	_expect(TitleSummary.room_title(&"tb3_toy_chest") == "Toy Chest", "a two-letter act prefix is dropped as well")
	_expect(TitleSummary.room_title(&"kingdom") == "Kingdom", "an id with no prefix keeps all its words")
	_expect(TitleSummary.room_title(&"") == TitleSummary.FIRST_ROOM_NAME, "a run that has not entered a room is the beginning")
	_expect(TitleSummary.play_time_text(0.0) == "0m" and TitleSummary.play_time_text(59.0) == "0m" and TitleSummary.play_time_text(125.0) == "2m" and TitleSummary.play_time_text(3599.0) == "59m", "play time under an hour is minutes")
	_expect(TitleSummary.play_time_text(3600.0) == "1h 00m" and TitleSummary.play_time_text(3725.0) == "1h 02m" and TitleSummary.play_time_text(36000.0) == "10h 00m", "from an hour on it is hours and minutes")
	var day := TitleSummary.day_text(1760000000)
	_expect(day.length() == 10 and day.begins_with("2025-10-"), "a Unix time is a calendar day (%s)" % day)
	var undated := SaveData.new()
	undated.room_id = &"t1_white_kings_fall"
	_expect(TitleSummary.card_for(undated) == "White Kings Fall  |  0m played", "a run that was never written has no date on its card")


func _the_completed_mark() -> void:
	var service := _service("title_completed")
	_expect(not TitleSummary.from_save(service, "1.0.0").completed, "before the ending the title has all its squares")
	service.mark_completed()
	_expect(TitleSummary.from_save(service, "1.0.0").completed, "after the ending the summary says completed, even with no save in the slot")
	service.new_game(0)
	service.request_save(&"room_cleared")
	_expect(TitleSummary.from_save(service, "1.0.0").completed, "and a new run keeps it")
