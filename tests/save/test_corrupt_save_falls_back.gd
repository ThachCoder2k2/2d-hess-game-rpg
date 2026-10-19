extends UnboundTest

## A damaged or missing save never wipes the player's progress and never crashes the loader
## (docs/game-base-plan.md 9.2 "Corrupt or newer save", 9.3, risk 9). The chain read_slot() follows:
## the slot's file, then the save an interrupted write left as .tmp (when it is not older than the .bak),
## then its .bak, then (first slot) the v2 WorldState save, then a clean new game, each step logged. A
## save from a NEWER game is never read as damaged and never overwritten.
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
	_check_a_write_that_died_between_its_renames_is_finished()
	_check_a_temp_file_that_is_not_the_latest_save_is_left_alone()
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
	# The file is simply gone (and no .tmp is beside it): the previous save is all there is.
	var made := _root_with_two_saves("missing_main")
	var service: Node = made[1]
	DirAccess.remove_absolute(service.slot_path(0))
	var reader := SaveSupport.new_service(made[0])
	var result: SaveLoadResult = reader.load_slot(0)
	_expect(result.outcome == SaveLoadResult.LOADED_FROM_BACKUP and reader.state.checkpoint_zone_id == &"t1_white_kings_fall", "a missing file with a good .bak loads the .bak")
	_expect(reader.has_save(0), "has_save counts a lone .bak")


## The disk a crash leaves when SaveFile.write dies after its second step and before its third: it built and
## verified <file>.tmp from the new save, and renamed the old file to <file>.bak; <file> does not exist. The two
## steps are done here with the calls write() makes. Returns [root, service, the newer SaveData].
func _root_after_a_crash_between_the_renames(label: String) -> Array:
	var root_directory := _new_root(label)
	var service := SaveSupport.new_service(root_directory)
	var older := SaveData.new()
	older.checkpoint_zone_id = &"t1_white_kings_fall"
	var newer := SaveData.new()
	newer.checkpoint_zone_id = &"t2_fallen_sword_tile"
	newer.taken_pickup_ids["t2_fallen_sword_tile/Shield"] = true
	service.write_slot(0, older)
	var path: String = service.slot_path(0)
	SaveSupport.plant(path + SaveFile.TEMP_SUFFIX, SaveFile.encode(newer.to_config()))
	DirAccess.rename_absolute(path, path + SaveFile.BACKUP_SUFFIX)
	return [root_directory, service, newer]


func _check_a_write_that_died_between_its_renames_is_finished() -> void:
	var made := _root_after_a_crash_between_the_renames("crash_window")
	var writer: Node = made[1]
	var path: String = writer.slot_path(0)
	_expect(not FileAccess.file_exists(path) and SaveFile.read(path + ".bak").is_readable() and SaveFile.read(path + ".tmp").is_readable(), "setup: the disk is what the crash leaves: no file, the old save as .bak, the new save complete as .tmp")
	_expect(SaveData.from_config(SaveFile.read(path + ".bak").config).checkpoint_zone_id == &"t1_white_kings_fall" and SaveData.from_config(SaveFile.read(path + ".tmp").config).checkpoint_zone_id == &"t2_fallen_sword_tile", "setup: the .tmp is the newer of the two")

	# Reading it (a slot card) takes the .tmp and changes nothing on the disk.
	var peeker := SaveSupport.new_service(made[0])
	_expect(peeker.has_save(0), "has_save sees the slot")
	var peeked: SaveLoadResult = peeker.read_slot(0)
	_expect(peeked.outcome == SaveLoadResult.LOADED and peeked.notice_key == &"" and peeked.data.checkpoint_zone_id == &"t2_fallen_sword_tile" and peeked.data.taken_pickup_ids.has("t2_fallen_sword_tile/Shield"), "read_slot takes the newer save from the .tmp, as a normal load: the player lost nothing and is told nothing")
	_expect(peeked.source_path == peeker.temp_path(0) and peeked.log_lines.size() >= 2 and peeked.log_lines[0].contains("not there"), "and says where it came from and what it tried first")
	_expect(not FileAccess.file_exists(path) and FileAccess.file_exists(path + ".tmp") and FileAccess.file_exists(path + ".bak"), "read_slot writes and renames nothing")

	# Loading it makes it the run and finishes the write by rename.
	var reader := SaveSupport.new_service(made[0])
	var result: SaveLoadResult = reader.load_slot(0)
	_expect(result.outcome == SaveLoadResult.LOADED and reader.state.checkpoint_zone_id == &"t2_fallen_sword_tile" and reader.state.taken_pickup_ids.size() == 1 and result.slot_is_writable(), "load_slot makes the .tmp's save the run, not the .bak's")
	_expect(result.source_path == reader.slot_path(0) and result.log_lines[result.log_lines.size() - 1].contains("finished the interrupted write"), "and finishes the write, and the log says so")
	_expect(SaveFile.read(path).is_readable() and SaveData.from_config(SaveFile.read(path).config).checkpoint_zone_id == &"t2_fallen_sword_tile" and not FileAccess.file_exists(path + ".tmp"), "the file is the newer save again and the .tmp is gone")
	_expect(SaveData.from_config(SaveFile.read(path + ".bak").config).checkpoint_zone_id == &"t1_white_kings_fall", "the .bak is still the save before it")
	reader.state.checkpoint_zone_id = &"t3_first_pawn_clash"
	_expect(reader.request_save(&"checkpoint_reached") and SaveData.from_config(SaveFile.read(path + ".bak").config).checkpoint_zone_id == &"t2_fallen_sword_tile", "the next save moves the recovered one to the .bak, as after any ordinary write")

	# The player's progress is in the .tmp even when the file in the way is damaged rather than missing.
	var damaged_made := _root_after_a_crash_between_the_renames("crash_window_damaged_file")
	var damaged_path: String = damaged_made[1].slot_path(0)
	SaveSupport.plant(damaged_path, "[meta]\nversion=3\n")
	var damaged_reader := SaveSupport.new_service(damaged_made[0])
	var damaged_result: SaveLoadResult = damaged_reader.load_slot(0)
	_expect(damaged_result.outcome == SaveLoadResult.LOADED and damaged_reader.state.checkpoint_zone_id == &"t2_fallen_sword_tile", "a damaged file with a newer .tmp loads the .tmp")
	_expect(SaveSupport.text_of(damaged_path + ".corrupt") == "[meta]\nversion=3\n" and SaveFile.read(damaged_path).is_readable(), "and the damaged file is set aside as .corrupt, not deleted")

	# A .tmp alone (the very first save died before its rename) is the save.
	var first_root := _new_root("crash_first_save")
	var first_path := first_root + "/saves/slot_0.cfg"
	SaveSupport.plant(first_path + ".tmp", SaveFile.encode((made[2] as SaveData).to_config()))
	var first_service := SaveSupport.new_service(first_root)
	_expect(first_service.has_save(0) and first_service.load_slot(0).outcome == SaveLoadResult.LOADED and first_service.state.checkpoint_zone_id == &"t2_fallen_sword_tile", "a complete .tmp with nothing else is a save: Continue offers it and loads it")


func _check_a_temp_file_that_is_not_the_latest_save_is_left_alone() -> void:
	var newer_data := SaveData.new()
	newer_data.checkpoint_zone_id = &"t2_fallen_sword_tile"
	var older_data := SaveData.new()
	older_data.checkpoint_zone_id = &"t1_white_kings_fall"

	# A write that died BEFORE its second step leaves the old file in place and a .tmp nobody needs: the file wins.
	var before_rename := _root_with_two_saves("crash_before_renames")
	var before_path: String = before_rename[1].slot_path(0)
	SaveSupport.plant(before_path + ".tmp", SaveFile.encode(older_data.to_config()))
	var before_reader := SaveSupport.new_service(before_rename[0])
	var before_result: SaveLoadResult = before_reader.load_slot(0)
	_expect(before_result.outcome == SaveLoadResult.LOADED and before_reader.state.checkpoint_zone_id == &"t2_fallen_sword_tile" and before_result.source_path == before_path, "a readable file is the save: a stray .tmp is not looked at")
	_expect(FileAccess.file_exists(before_path + ".tmp"), "and the .tmp is left where it is for the next write to overwrite")

	# A .tmp OLDER than the .bak is not the latest progress (it cannot come from the write that made the .bak).
	var stale_root := _new_root("stale_temp")
	var stale_path := stale_root + "/saves/slot_0.cfg"
	SaveSupport.plant(stale_path + ".tmp", SaveFile.encode(older_data.to_config()))
	OS.delay_msec(1100)
	SaveSupport.plant(stale_path + ".bak", SaveFile.encode(newer_data.to_config()))
	_expect(FileAccess.get_modified_time(stale_path + ".tmp") < FileAccess.get_modified_time(stale_path + ".bak"), "setup: the .tmp is older than the .bak")
	var stale_reader := SaveSupport.new_service(stale_root)
	var stale_result: SaveLoadResult = stale_reader.load_slot(0)
	_expect(stale_result.outcome == SaveLoadResult.LOADED_FROM_BACKUP and stale_reader.state.checkpoint_zone_id == &"t2_fallen_sword_tile", "an older .tmp is passed over: the .bak is loaded")
	_expect(FileAccess.file_exists(stale_path + ".tmp") and not FileAccess.file_exists(stale_path), "and nothing is renamed")

	# A .tmp that is damaged (a write that died while writing it) is not a save; the .bak is.
	var torn := _root_after_a_crash_between_the_renames("torn_temp")
	var torn_path: String = torn[1].slot_path(0)
	SaveSupport.plant(torn_path + ".tmp", SaveSupport.text_of(torn_path + ".tmp").substr(0, 60))
	var torn_reader := SaveSupport.new_service(torn[0])
	var torn_result: SaveLoadResult = torn_reader.load_slot(0)
	_expect(torn_result.outcome == SaveLoadResult.LOADED_FROM_BACKUP and torn_reader.state.checkpoint_zone_id == &"t1_white_kings_fall" and torn_result.notice_key == SaveLoadResult.NOTICE_BACKUP_USED, "a damaged .tmp falls back to the .bak and the player is told")
	_expect(torn_result.log_lines.size() >= 3 and String(torn_result.log_lines[1]).contains(".tmp: ") and String(torn_result.log_lines[1]).contains("damaged"), "the log names the damaged .tmp")

	# A .tmp from a NEWER game is never overwritten or read as ours: the same rule as the file and the .bak.
	var future := ConfigFile.new()
	future.set_value("meta", "version", 99)
	future.set_value("future", "shiny_new_thing", "very important progress")
	var future_text := SaveFile.encode(future)
	var future_made := _root_after_a_crash_between_the_renames("newer_temp")
	var future_path: String = future_made[1].slot_path(0)
	SaveSupport.plant(future_path + ".tmp", future_text)
	var future_service := SaveSupport.new_service(future_made[0])
	var future_result: SaveLoadResult = future_service.load_slot(0)
	_expect(future_result.outcome == SaveLoadResult.NEWER_GAME_REQUIRED and not future_result.slot_is_writable(), "a .tmp from a newer game asks for a newer game, even with a good .bak beside it")
	future_service.state.checkpoint_zone_id = &"t3_first_pawn_clash"
	_expect(not future_service.request_save(&"checkpoint_reached") and SaveSupport.text_of(future_path + ".tmp") == future_text and not FileAccess.file_exists(future_path), "and no save is written over it, and the .tmp was not renamed into the file")
	future_service.new_game(0)
	_expect(SaveSupport.text_of(future_path + ".tmp.newer_game") == future_text and not FileAccess.file_exists(future_path + ".tmp"), "a New Game sets it aside, byte for byte, before anything is written")


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

	# A file of the current format whose PlayerSnapshot section was written by a newer snapshot format also
	# needs a newer game: it is not read with rows dropped, and not overwritten.
	var snapshot_root := _new_root("newer_snapshot")
	var snapshot_config := SaveData.new().to_config()
	snapshot_config.set_value("player", "format_version", PlayerSnapshot.FORMAT_VERSION + 1)
	var snapshot_text := SaveFile.encode(snapshot_config)
	SaveSupport.plant(snapshot_root + "/saves/slot_0.cfg", snapshot_text)
	var snapshot_service := SaveSupport.new_service(snapshot_root)
	_expect(snapshot_service.load_slot(0).outcome == SaveLoadResult.NEWER_GAME_REQUIRED, "a slot whose pawn section is from a newer snapshot format asks for a newer game")
	_expect(not snapshot_service.request_save(&"checkpoint_reached") and SaveSupport.text_of(snapshot_root + "/saves/slot_0.cfg") == snapshot_text, "and is not overwritten")

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
