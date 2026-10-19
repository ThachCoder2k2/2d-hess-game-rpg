extends UnboundTest

## A save written by the game before M3b (format 2, the WorldState autoload's user://world_state.cfg) keeps
## loading (docs/game-base-plan.md 9.3, risk 9: "Save v3 migration wipes progress"). The fixture
## tests/fixtures/saves/world_state_v2.cfg is a REAL v2 file, written by the v2 code itself, not typed by
## hand. This suite holds:
##   - the migration step: every fact of the v2 file lands in the v3 data, nothing is dropped;
##   - the loader: the v2 file is found where WorldState left it, read without a side effect, and kept
##     (renamed, never deleted) once a v3 save has replaced it;
##   - a save too old to migrate (format 1, or no version at all) is not read and not wiped;
##   - a v2 file with keys missing still loads (defaults).

const SaveSupport := preload("res://tests/support/save_test_support.gd")

const FIXTURE_PATH := "res://tests/fixtures/saves/world_state_v2.cfg"

var roots_to_remove: Array[String] = []


func _init() -> void:
	suite_title = "SAVE MIGRATION V2 TEST"
	_check_the_fixture_is_a_real_v2_save()
	_check_the_migration_step()
	_check_the_loader_finds_and_migrates_the_v2_file()
	_check_loading_has_no_side_effect_and_the_first_save_retires_the_v2_file()
	_check_a_new_game_never_resurrects_the_v2_file()
	_check_too_old_saves_are_not_read_and_not_wiped()
	_check_a_sparse_v2_file_still_loads()
	for root_directory in roots_to_remove:
		SaveSupport.remove_root(root_directory)
	finish()


func _new_root(label: String) -> String:
	var root_directory := SaveSupport.make_root("migration_" + label)
	roots_to_remove.append(root_directory)
	return root_directory


## A root whose world_state.cfg is `text`.
func _root_with_legacy_file(label: String, text: String) -> String:
	var root_directory := _new_root(label)
	SaveSupport.plant(root_directory + "/world_state.cfg", text)
	return root_directory


func _fixture_text() -> String:
	return FileAccess.get_file_as_string(FIXTURE_PATH)


func _check_the_fixture_is_a_real_v2_save() -> void:
	var fixture := ConfigFile.new()
	_expect(fixture.load(FIXTURE_PATH) == OK, "the v2 fixture is there and parses")
	_expect(int(fixture.get_value("meta", "version", 0)) == 2, "it declares format 2")
	var expected_keys: Array[String] = ["current_zone_id", "last_entry_id", "taken_pickup_ids", "opened_gate_ids", "unlocked_rule_ids", "player_unlock_ids"]
	_expect(Array(fixture.get_section_keys("world")) == expected_keys, "and has exactly the six keys WorldState.save_state() wrote")
	_expect(not _fixture_text().contains("integrity"), "and no integrity footer: the v2 code never wrote one")


func _check_the_migration_step() -> void:
	var config := ConfigFile.new()
	config.load(FIXTURE_PATH)
	_expect(SaveMigration.upgrade_to_current(config, 2, 1750000000), "format 2 upgrades to the current format")
	_expect(int(config.get_value("meta", "version", 0)) == SaveData.FORMAT_VERSION, "and declares it")
	_expect(config.get_value("checkpoint", "zone_id", "") == "t4_broken_rule_yard" and config.get_value("checkpoint", "entry_id", "") == "west_entry", "the run's zone and entry became the checkpoint")
	_expect(config.get_value("meta", "room", "") == "t4_broken_rule_yard" and int(config.get_value("meta", "saved_at_unix", 0)) == 1750000000, "the room and a timestamp (the file's own) are in [meta]")
	_expect(config.get_value("player", "unlocked_skill_ids", []) == ["wooden_sword"], "player_unlock_ids became the unlocked skills")
	_expect(not config.has_section_key("world", "current_zone_id") and not config.has_section_key("world", "last_entry_id") and not config.has_section_key("world", "player_unlock_ids"), "the moved keys are gone from [world]")
	_expect(config.get_value("world", "taken_pickup_ids", []) == ["t4_broken_rule_yard/PencilSpearPickup"] and config.get_value("world", "opened_gate_ids", []) == ["pass_home_gate"], "taken pickups and opened gates stayed")
	var unknown := ConfigFile.new()
	unknown.set_value("meta", "version", 1)
	_expect(not SaveMigration.upgrade_to_current(unknown, 1), "a format with no step cannot be upgraded")
	_expect(SaveMigration.upgrade_to_current(ConfigFile.new(), SaveData.FORMAT_VERSION), "the current format needs no step")


func _check_the_loader_finds_and_migrates_the_v2_file() -> void:
	var root_directory := _root_with_legacy_file("loader", _fixture_text())
	var service := SaveSupport.new_service(root_directory)
	_expect(service.has_save(0), "has_save counts the v2 file")
	var result: SaveLoadResult = service.read_slot(0)
	_expect(result.outcome == SaveLoadResult.LOADED and result.migrated_from_version == 2 and result.file_version == 2, "the slot loads, migrated from format 2")
	_expect(result.source_path == root_directory + "/world_state.cfg" and result.notice_key == &"", "from the v2 file, and with nothing to tell the player")
	var data := result.data
	_expect(data.checkpoint_zone_id == &"t4_broken_rule_yard" and data.checkpoint_entry_id == &"west_entry", "the zone and entry the run was in")
	_expect(data.taken_pickup_ids == {"t4_broken_rule_yard/PencilSpearPickup": true}, "the taken pickup")
	_expect(data.opened_gate_ids == {"pass_home_gate": true}, "the opened gate")
	_expect(data.unlocked_rule_ids == {"pawn_recruit": true, "pawn_armed": true}, "the read Book pages")
	_expect(data.has_unlock(&"wooden_sword") and data.player.unlocked_skill_ids.size() == 1, "the sword unlock")
	_expect(data.room_id == &"t4_broken_rule_yard" and data.saved_at_unix > 1700000000, "the room, and a timestamp taken from the file")
	_expect(data.cleared_room_ids.is_empty() and data.defeated_boss_ids.is_empty() and data.player.flags.is_empty() and data.play_time_seconds == 0.0, "everything v2 never knew starts empty")
	_expect(data.player.courage_current == data.player.courage_max, "and the pawn is at full Courage")


func _check_loading_has_no_side_effect_and_the_first_save_retires_the_v2_file() -> void:
	var root_directory := _root_with_legacy_file("retire", _fixture_text())
	var service := SaveSupport.new_service(root_directory)
	service.load_slot(0)
	_expect(_fixture_text() == SaveSupport.text_of(root_directory + "/world_state.cfg") and not FileAccess.file_exists(service.slot_path(0)), "loading changes nothing on disk: the v2 file is the same bytes and no v3 file exists yet")
	_expect(service.request_save(&"checkpoint_reached"), "the first success event writes the v3 save")
	_expect(FileAccess.file_exists(service.slot_path(0)) and SaveFile.read(service.slot_path(0)).version == 3, "which is a readable version 3 file")
	_expect(not FileAccess.file_exists(root_directory + "/world_state.cfg") and SaveSupport.text_of(root_directory + "/world_state.cfg.migrated") == _fixture_text(), "and the v2 file is kept as world_state.cfg.migrated, byte for byte")
	var reloaded := SaveSupport.new_service(root_directory)
	var result: SaveLoadResult = reloaded.load_slot(0)
	_expect(result.outcome == SaveLoadResult.LOADED and result.migrated_from_version == 0 and result.source_path == reloaded.slot_path(0), "the next launch reads the v3 file, with no migration")
	_expect(reloaded.state.taken_pickup_ids.has("t4_broken_rule_yard/PencilSpearPickup") and reloaded.state.has_unlock(&"wooden_sword") and reloaded.state.checkpoint_entry_id == &"west_entry", "and every v2 fact is still there")


func _check_a_new_game_never_resurrects_the_v2_file() -> void:
	var root_directory := _root_with_legacy_file("new_game", _fixture_text())
	var service := SaveSupport.new_service(root_directory)
	service.new_game(0)
	service.state.checkpoint_zone_id = &"t1_white_kings_fall"
	service.request_save(&"checkpoint_reached")
	var reloaded := SaveSupport.new_service(root_directory)
	reloaded.load_slot(0)
	_expect(reloaded.state.checkpoint_zone_id == &"t1_white_kings_fall" and reloaded.state.taken_pickup_ids.is_empty() and not reloaded.state.has_unlock(&"wooden_sword"), "a New Game that has saved is the save, not the old v2 progress")
	_expect(FileAccess.file_exists(root_directory + "/world_state.cfg.migrated"), "and the old v2 file is still kept")


func _check_too_old_saves_are_not_read_and_not_wiped() -> void:
	# What WorldState wrote before it had a version: no [meta] at all, a zone the game no longer has.
	var unversioned_text := "[world]\n\ncurrent_zone_id=&\"kingdom\"\nlast_entry_id=&\"start\"\n"
	var unversioned_root := _root_with_legacy_file("unversioned", unversioned_text)
	var unversioned_service := SaveSupport.new_service(unversioned_root)
	var result: SaveLoadResult = unversioned_service.load_slot(0)
	_expect(result.outcome == SaveLoadResult.NEW_GAME_OBSOLETE_SAVE and result.notice_key == SaveLoadResult.NOTICE_OBSOLETE_SAVE, "a save with no version is not read: a clean new game and a notice")
	_expect(unversioned_service.state.checkpoint_zone_id == &"" and unversioned_service.state.taken_pickup_ids.is_empty(), "the run starts clean, not in the retired kingdom")
	_expect(SaveSupport.text_of(unversioned_root + "/world_state.cfg") == unversioned_text, "and the old file is exactly where it was")
	_expect("\n".join(result.log_lines).contains("older than this game can migrate"), "the reason is logged")
	unversioned_service.request_save(&"checkpoint_reached")
	_expect(SaveSupport.text_of(unversioned_root + "/world_state.cfg.migrated") == unversioned_text, "the first save of the new run keeps the old file as world_state.cfg.migrated")

	var version_one := "[meta]\n\nversion=1\n\n[world]\n\ncurrent_zone_id=&\"kingdom\"\n"
	var version_one_service := SaveSupport.new_service(_root_with_legacy_file("version_one", version_one))
	_expect(version_one_service.read_slot(0).outcome == SaveLoadResult.NEW_GAME_OBSOLETE_SAVE, "a format 1 save is obsolete too")

	var newer_text := "[meta]\n\nversion=9\n\n[world]\n\ncurrent_zone_id=&\"future_zone\"\n"
	var newer_root := _root_with_legacy_file("newer_legacy", newer_text)
	var newer_service := SaveSupport.new_service(newer_root)
	_expect(newer_service.read_slot(0).outcome == SaveLoadResult.NEWER_GAME_REQUIRED, "an old-location file that claims a newer format asks for a newer game")


func _check_a_sparse_v2_file_still_loads() -> void:
	var sparse_text := "[meta]\n\nversion=2\n\n[world]\n\ntaken_pickup_ids=[\"t4_broken_rule_yard/PencilSpearPickup\"]\nopened_gate_ids=\"not an array\"\n"
	var service := SaveSupport.new_service(_root_with_legacy_file("sparse", sparse_text))
	var result: SaveLoadResult = service.read_slot(0)
	_expect(result.outcome == SaveLoadResult.LOADED and result.migrated_from_version == 2, "a v2 file with keys missing still loads")
	_expect(result.data.taken_pickup_ids.has("t4_broken_rule_yard/PencilSpearPickup") and result.data.opened_gate_ids.is_empty(), "what is there is kept, a wrong type is dropped")
	_expect(result.data.checkpoint_zone_id == &"" and result.data.checkpoint_entry_id == &"start", "a missing zone and entry are the defaults (the scene's own zone, the start entry)")
