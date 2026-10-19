extends UnboundTest

## A damaged or missing save never wipes the player's progress and never crashes the loader
## (docs/game-base-plan.md 9.2 "Corrupt or newer save", 9.3, risk 9). The chain read_slot() follows:
## the slot's file, then its .bak, then (first slot) the v2 WorldState save, then a clean new game, each
## step logged. A save from a NEWER game is never read as damaged and never overwritten.
##
## Every damaged file here is damaged for real (truncated, zeroed, flipped, garbage), and the suite runs
## under --strict: the loader must tell damage apart before the ConfigFile parser sees it, because the
## parser prints an engine ERROR line on text it cannot parse (SaveFile's integrity footer is what makes
## that possible).

const SaveSupport := preload("res://tests/support/save_test_support.gd")

var roots_to_remove: Array[String] = []


func _init() -> void:
	suite_title = "CORRUPT SAVE FALLS BACK TEST"
	_check_no_save_is_a_normal_first_run()
	_check_a_damaged_file_falls_back_to_the_backup()
	_check_a_missing_file_falls_back_to_the_backup()
	_check_nothing_usable_is_a_clean_new_game()
	_check_the_next_save_after_damage_keeps_the_good_backup()
	_check_a_newer_game_is_never_overwritten()
	_check_an_old_format_slot_file_is_kept()
	_check_nothing_is_written_without_a_run()
	_check_a_damaged_profile()
	for root_directory in roots_to_remove:
		SaveSupport.remove_root(root_directory)
	finish()


func _new_root(label: String) -> String:
	var root_directory := SaveSupport.make_root("corrupt_" + label)
	roots_to_remove.append(root_directory)
	return root_directory


## A root with two saves written: the older one is now the .bak, the newer one the file.
func _root_with_two_saves(label: String) -> Array:
	var root_directory := _new_root(label)
	var service := SaveSupport.new_service(root_directory)
	var older := SaveData.new()
	older.checkpoint_zone_id = &"t1_white_kings_fall"
	older.taken_pickup_ids["t1_white_kings_fall/Sword"] = true
	var newer := SaveData.new()
	newer.checkpoint_zone_id = &"t2_fallen_sword_tile"
	newer.taken_pickup_ids["t1_white_kings_fall/Sword"] = true
	newer.taken_pickup_ids["t2_fallen_sword_tile/Shield"] = true
	service.write_slot(0, older)
	service.write_slot(0, newer)
	return [root_directory, service]


func _check_no_save_is_a_normal_first_run() -> void:
	var service := SaveSupport.new_service(_new_root("none"))
	var result: SaveLoadResult = service.load_slot(0)
	_expect(result.outcome == SaveLoadResult.NEW_GAME_NO_SAVE and result.notice_key == &"" and not result.found_progress(), "no file at all is a first run: a clean new game and nothing to tell the player")
	_expect(service.has_session and service.state.to_text() == SaveData.new().to_text() and result.slot_is_writable(), "and the run can be saved")
	_expect(not service.has_save(0), "has_save says there is nothing on disk")


func _check_a_damaged_file_falls_back_to_the_backup() -> void:
	var damages := {
		"truncated": func(text: String) -> String: return text.substr(0, text.length() / 2),
		"emptied": func(_text: String) -> String: return "",
		"garbage": func(_text: String) -> String: return "this was a save\n[meta\nversion=== 3\nÿþ garbage",
		"one value flipped": func(text: String) -> String: return text.replace("t2_fallen_sword_tile/Shield", "t2_fallen_sword_tile/Shiele"),
		"footer removed": func(text: String) -> String: return text.substr(0, text.find(SaveFile.INTEGRITY_PREFIX)),
		"zeroed": func(text: String) -> String: return "0".repeat(text.length()),
	}
	for damage_name: String in damages:
		var made := _root_with_two_saves("damaged_" + damage_name.replace(" ", "_"))
		var root_directory: String = made[0]
		var writer: Node = made[1]
		var path: String = writer.slot_path(0)
		var damaged_text: String = (damages[damage_name] as Callable).call(SaveSupport.text_of(path))
		SaveSupport.plant(path, damaged_text)
		_expect(not SaveFile.read(path).is_readable(), "setup (%s): the file is damaged" % damage_name)

		var reader := SaveSupport.new_service(root_directory)
		var result: SaveLoadResult = reader.load_slot(0)
		_expect(result.outcome == SaveLoadResult.LOADED_FROM_BACKUP and result.notice_key == SaveLoadResult.NOTICE_BACKUP_USED, "%s: the previous save, the .bak, is loaded and the player is told" % damage_name)
		_expect(reader.state.checkpoint_zone_id == &"t1_white_kings_fall" and reader.state.taken_pickup_ids.size() == 1, "%s: it is the older save's content, not a half-read one" % damage_name)
		_expect(result.source_path == reader.backup_path(0) and result.log_lines.size() >= 2 and result.log_lines[0].contains("damaged"), "%s: the log says what was tried and why" % damage_name)
		_expect(reader.last_load == result and reader.has_session, "%s: the service keeps the result for the title screen" % damage_name)


func _check_a_missing_file_falls_back_to_the_backup() -> void:
	# A crash between "the old file becomes the .bak" and "the new file takes its place" leaves exactly this.
	var made := _root_with_two_saves("missing_main")
	var service: Node = made[1]
	DirAccess.remove_absolute(service.slot_path(0))
	var reader := SaveSupport.new_service(made[0])
	var result: SaveLoadResult = reader.load_slot(0)
	_expect(result.outcome == SaveLoadResult.LOADED_FROM_BACKUP and reader.state.checkpoint_zone_id == &"t1_white_kings_fall", "a missing file with a good .bak loads the .bak")
	_expect(reader.has_save(0), "has_save counts a lone .bak")


func _check_nothing_usable_is_a_clean_new_game() -> void:
	var made := _root_with_two_saves("both_damaged")
	var service: Node = made[1]
	SaveSupport.plant(service.slot_path(0), "garbage")
	SaveSupport.plant(service.backup_path(0), "")
	var reader := SaveSupport.new_service(made[0])
	var result: SaveLoadResult = reader.load_slot(0)
	_expect(result.outcome == SaveLoadResult.NEW_GAME_AFTER_DAMAGE and result.notice_key == SaveLoadResult.NOTICE_NEW_GAME_AFTER_DAMAGE, "a damaged file and a damaged .bak give a clean new game and a notice")
	_expect(reader.state.to_text() == SaveData.new().to_text() and result.slot_is_writable(), "which is a real clean run that can be saved")
	_expect(result.log_lines.size() == 3 and result.log_lines[2].contains("clean new game"), "the log names both files and the decision")

	var only_main := _new_root("damaged_alone")
	SaveSupport.plant(only_main + "/saves/slot_0.cfg", "[meta]\nversion=3\n")
	var alone_service := SaveSupport.new_service(only_main)
	_expect(alone_service.load_slot(0).outcome == SaveLoadResult.NEW_GAME_AFTER_DAMAGE, "a file with no integrity footer and no .bak is damage, not a save")


func _check_the_next_save_after_damage_keeps_the_good_backup() -> void:
	var made := _root_with_two_saves("keep_backup")
	var writer: Node = made[1]
	var path: String = writer.slot_path(0)
	var damaged_text := SaveSupport.text_of(path).substr(0, 40)
	SaveSupport.plant(path, damaged_text)
	var service := SaveSupport.new_service(made[0])
	service.load_slot(0)
	service.state.checkpoint_zone_id = &"t3_first_pawn_clash"
	_expect(service.request_save(&"checkpoint_reached"), "the run that fell back to the .bak saves normally")
	_expect(SaveFile.read(path).is_readable() and SaveData.from_config(SaveFile.read(path).config).checkpoint_zone_id == &"t3_first_pawn_clash", "the file is the new save")
	_expect(SaveData.from_config(SaveFile.read(path + ".bak").config).checkpoint_zone_id == &"t1_white_kings_fall", "the good .bak was NOT replaced by the damaged file")
	_expect(SaveSupport.text_of(path + ".corrupt") == damaged_text, "the damaged file is kept as .corrupt, not deleted")


func _check_a_newer_game_is_never_overwritten() -> void:
	var root_directory := _new_root("newer")
	var path := root_directory + "/saves/slot_0.cfg"
	var future := ConfigFile.new()
	future.set_value("meta", "version", 99)
	future.set_value("future", "shiny_new_thing", "very important progress")
	var future_text := SaveFile.encode(future)
	SaveSupport.plant(path, future_text)
	var service := SaveSupport.new_service(root_directory)
	var result: SaveLoadResult = service.load_slot(0)
	_expect(result.outcome == SaveLoadResult.NEWER_GAME_REQUIRED and result.notice_key == SaveLoadResult.NOTICE_NEWER_GAME and result.file_version == 99, "a save from a newer game is recognised, with its version")
	_expect(not result.slot_is_writable() and service.has_session, "the slot cannot be written, the game can still start in memory")
	service.state.checkpoint_zone_id = &"t2_fallen_sword_tile"
	_expect(not service.request_save(&"checkpoint_reached"), "a success event cannot save over it")
	_expect(service.write_slot(0, service.state) == ERR_LOCKED, "and neither can a direct write")
	_expect(SaveSupport.text_of(path) == future_text and not FileAccess.file_exists(path + ".bak"), "the newer game's file is byte for byte what it was, and no .bak was made from it")
	_expect(SaveFile.write(path, SaveData.new().to_config()) == ERR_LOCKED and SaveSupport.text_of(path) == future_text, "SaveFile refuses on its own too")

	service.new_game(0)
	_expect(FileAccess.file_exists(path + ".newer_game") and not FileAccess.file_exists(path), "starting a new game sets the newer game's file aside (renamed, not deleted)")
	_expect(SaveSupport.text_of(path + ".newer_game") == future_text, "byte for byte")
	service.state.checkpoint_zone_id = &"t1_white_kings_fall"
	_expect(service.request_save(&"checkpoint_reached") and SaveFile.read(path).is_readable(), "and the new game saves")

	# A newer file that does not even pass this build's integrity check is still "newer", not "damaged".
	var alien_root := _new_root("newer_alien")
	var alien_text := "[meta]\n\nversion=99\n\n[future]\n\nthing=1\n; some other footer 123\n"
	SaveSupport.plant(alien_root + "/saves/slot_0.cfg", alien_text)
	var alien_service := SaveSupport.new_service(alien_root)
	_expect(alien_service.load_slot(0).outcome == SaveLoadResult.NEWER_GAME_REQUIRED, "a newer file is recognised before its footer is checked")
	_expect(not alien_service.request_save(&"checkpoint_reached") and SaveSupport.text_of(alien_root + "/saves/slot_0.cfg") == alien_text, "and is not overwritten either")

	# A newer .bak next to a damaged file: do not fall back to something an older game's save would replace.
	var backup_root := _new_root("newer_backup")
	SaveSupport.plant(backup_root + "/saves/slot_0.cfg", "garbage")
	SaveSupport.plant(backup_root + "/saves/slot_0.cfg.bak", future_text)
	var backup_service := SaveSupport.new_service(backup_root)
	_expect(backup_service.load_slot(0).outcome == SaveLoadResult.NEWER_GAME_REQUIRED, "a newer .bak behind a damaged file also asks for a newer game")


func _check_an_old_format_slot_file_is_kept() -> void:
	var root_directory := _new_root("old_format")
	var old := ConfigFile.new()
	old.set_value("meta", "version", 1)
	old.set_value("world", "current_zone_id", "kingdom")
	var old_text := SaveFile.encode(old)
	SaveSupport.plant(root_directory + "/saves/slot_0.cfg", old_text)
	var service := SaveSupport.new_service(root_directory)
	var result: SaveLoadResult = service.load_slot(0)
	_expect(result.outcome == SaveLoadResult.NEW_GAME_OBSOLETE_SAVE and service.state.checkpoint_zone_id == &"", "a slot file from a format too old to migrate gives a clean run")
	_expect(service.request_save(&"checkpoint_reached") and SaveSupport.text_of(root_directory + "/saves/slot_0.cfg.bak") == old_text, "and the first save keeps the old file as the .bak")


func _check_nothing_is_written_without_a_run() -> void:
	var made := _root_with_two_saves("no_run")
	var on_disk_before := SaveSupport.text_of(made[1].slot_path(0))
	var service := SaveSupport.new_service(made[0])
	_expect(not service.has_session and not service.request_save(&"checkpoint_reached"), "a service that has no run refuses a save: an empty run can never overwrite a real save")
	_expect(SaveSupport.text_of(service.slot_path(0)) == on_disk_before, "and the file is untouched")


func _check_a_damaged_profile() -> void:
	var root_directory := _new_root("profile")
	var service := SaveSupport.new_service(root_directory)
	_expect(service.mark_completed() == OK and service.is_completed(), "the completed mark is written to the profile")
	SaveSupport.plant(service.profile_path(), "damaged")
	_expect(not service.is_completed() and service.read_profile().is_empty(), "a damaged profile with no backup reads as empty, not as a crash")
	_expect(service.set_profile_value(&"completed", true) == OK and service.is_completed(), "and is replaced by the next write")
	_expect(SaveSupport.text_of(service.profile_path() + ".corrupt") == "damaged", "the damaged one is kept as .corrupt")
