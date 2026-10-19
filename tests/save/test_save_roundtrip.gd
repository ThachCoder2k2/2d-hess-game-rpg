extends UnboundTest

## Save v3 (docs/game-base-plan.md 9.3, 15 M3b): everything a slot remembers goes to the disk and comes
## back, through the real SaveService on a throwaway folder. This suite holds:
##   - the file: a plain ConfigFile at <root>/saves/slot_<n>.cfg with the sections the plan names, its
##     integrity footer as a comment, and nothing about current health;
##   - the round trip: a fresh service on the same folder reads back exactly what was written, every set,
##     the checkpoint, the PlayerSnapshot rows and the flags (names with dots and spaces, bools and counters);
##   - the slot-aware API: two slots do not see each other;
##   - the atomic write: the temp file is gone, the previous save is kept as the .bak;
##   - request_save(): it writes the run in memory with the room, the time and the autosaved signal;
##   - configure(): a new root is a new world.

const SaveSupport := preload("res://tests/support/save_test_support.gd")

var roots_to_remove: Array[String] = []
var autosaved_slots: Array[int] = []
var autosaved_reasons: Array[StringName] = []


func _init() -> void:
	suite_title = "SAVE ROUNDTRIP TEST"
	_check_the_file()
	_check_the_round_trip()
	_check_health_never_saves()
	_check_slots_do_not_see_each_other()
	_check_the_write_is_atomic_and_keeps_a_backup()
	_check_request_save_writes_the_run()
	_check_configure_is_a_new_world()
	_check_flags_of_a_world_round_trip()
	for root_directory in roots_to_remove:
		SaveSupport.remove_root(root_directory)
	finish()


func _new_root(label: String) -> String:
	var root_directory := SaveSupport.make_root("roundtrip_" + label)
	roots_to_remove.append(root_directory)
	return root_directory


func _check_the_file() -> void:
	var root_directory := _new_root("file")
	var service := SaveSupport.new_service(root_directory)
	var data := SaveSupport.full_data()
	_expect(service.write_slot(0, data) == OK, "a slot is written")
	var path: String = service.slot_path(0)
	_expect(path == root_directory + "/saves/slot_0.cfg", "the slot lives at <root>/saves/slot_0.cfg")

	var plain := ConfigFile.new()
	_expect(plain.load(path) == OK, "the file is a plain ConfigFile: the integrity footer is a comment any reader skips")
	_expect(int(plain.get_value("meta", "version", 0)) == SaveData.FORMAT_VERSION and SaveData.FORMAT_VERSION == 3, "[meta] declares version 3")
	_expect(is_equal_approx(float(plain.get_value("meta", "play_time_seconds", 0.0)), 1234.5), "[meta] holds the play time")
	_expect(plain.get_value("meta", "room", "") == "t4_broken_rule_yard" and int(plain.get_value("meta", "saved_at_unix", 0)) == 1760000000, "[meta] holds the room and the timestamp")
	_expect(plain.get_value("checkpoint", "zone_id", "") == "h1_chess_rug_hub" and plain.get_value("checkpoint", "entry_id", "") == "from_b1", "[checkpoint] holds the zone and the entry")
	_expect(plain.get_value("world", "cleared_room_ids", []) == ["t3_first_pawn_clash", "t4_broken_rule_yard"], "[world] holds cleared_room_ids, sorted")
	_expect(plain.get_value("world", "defeated_boss_ids", []) == ["b1_black_pawn_captain"], "[world] holds defeated_boss_ids")
	_expect(plain.get_value("world", "taken_pickup_ids", []) == ["h1_chess_rug_hub/Shard 1", "t4_broken_rule_yard/PencilSpearPickup"], "[world] holds taken_pickup_ids")
	var world_keys := plain.get_section_keys("world")
	var expected_world_keys: Array[String] = ["cleared_room_ids", "defeated_boss_ids", "taken_pickup_ids", "opened_gate_ids", "unlocked_rule_ids", "rescued_piece_ids", "collected_page_ids", "courage_shard_ids"]
	_expect(Array(world_keys) == expected_world_keys, "[world] has the eight sets the plan names: cleared rooms, bosses, pickups, gates, Book pages, rescues, Rule Pages, shards")
	_expect(plain.get_value("player", "courage_max", 0) == 4 and plain.get_value("player", "believe_current", 0) == 2 and plain.get_value("player", "margin", 0) == 3, "[player] holds the PlayerSnapshot rows")
	_expect(plain.get_value("player", "unlocked_skill_ids", []) == ["wooden_sword", "pencil_thrust", "rule_step"], "[player] holds the unlocked skills in order")
	_expect(plain.get_value("flags", "boss.b1_defeated", false) == true and plain.get_value("flags", "child.trust", 0) == 2 and plain.get_value("flags", "beat.intro seen", false) == true, "[flags] holds one key per flag, also for ids with a dot or a space")
	_expect(not plain.has_section_key("player", "flags") and not plain.has_section_key("player", "courage_current"), "[player] does not repeat the flags and does not store current Courage")

	var text := SaveSupport.text_of(path)
	var last_line := text.strip_edges().get_slice("\n", text.strip_edges().count("\n"))
	_expect(last_line.begins_with(SaveFile.INTEGRITY_PREFIX) and last_line.length() == SaveFile.INTEGRITY_PREFIX.length() + 64, "the last line is the integrity footer: a sha256 digest of everything above it")
	_expect(SaveFile.read(path).is_readable() and SaveFile.read(path).version == 3, "SaveFile reads the file back as a readable version 3")


func _check_the_round_trip() -> void:
	var root_directory := _new_root("trip")
	var writer := SaveSupport.new_service(root_directory)
	var original := SaveSupport.full_data()
	writer.write_slot(0, original)

	var reader := SaveSupport.new_service(root_directory)
	var result: SaveLoadResult = reader.load_slot(0)
	_expect(result.outcome == SaveLoadResult.LOADED and result.migrated_from_version == 0 and result.notice_key == &"", "a fresh service on the same folder loads the slot with no migration and no notice")
	var loaded: SaveData = reader.state
	_expect(loaded.to_text() == original.to_text(), "the loaded slot writes the same text as the original (nothing dropped, nothing invented)")
	_expect(is_equal_approx(loaded.play_time_seconds, 1234.5) and loaded.room_id == &"t4_broken_rule_yard" and loaded.saved_at_unix == 1760000000, "meta comes back")
	_expect(loaded.checkpoint_zone_id == &"h1_chess_rug_hub" and loaded.checkpoint_entry_id == &"from_b1", "the checkpoint comes back")
	_expect(loaded.cleared_room_ids == original.cleared_room_ids and loaded.defeated_boss_ids == original.defeated_boss_ids, "cleared rooms and defeated bosses come back")
	_expect(loaded.taken_pickup_ids == original.taken_pickup_ids and loaded.opened_gate_ids == original.opened_gate_ids and loaded.unlocked_rule_ids == original.unlocked_rule_ids, "taken pickups, opened gates and read Book pages come back")
	_expect(loaded.rescued_piece_ids == original.rescued_piece_ids and loaded.collected_page_ids == original.collected_page_ids and loaded.courage_shard_ids == original.courage_shard_ids, "rescues, Rule Pages and Courage Shards come back")
	_expect(loaded.player.courage_max == 4 and loaded.player.believe_current == 2 and loaded.player.margin == 3 and loaded.player.facing == Vector2i.RIGHT, "Courage max, Believe, Margin and facing come back")
	_expect(loaded.player.unlocked_skill_ids == original.player.unlocked_skill_ids and loaded.player.applied_upgrade_ids == original.player.applied_upgrade_ids and loaded.player.equipped_page_ids == original.player.equipped_page_ids, "skills, upgrades and equipped pages come back")
	_expect(loaded.player.locked_directions == original.player.locked_directions, "locked directions come back")
	_expect(loaded.player.flags == original.player.flags, "the flags come back with their types: switches stay bools and counters stay ints")
	_expect(loaded.has_unlock(&"wooden_sword") and not loaded.has_unlock(&"free_step"), "has_unlock reads the unlocked skills")
	_expect(not loaded.add_unlock(&"wooden_sword") and loaded.add_unlock(&"free_step") and loaded.has_unlock(&"free_step"), "add_unlock records a new unlock once")

	_expect(SaveData.pickup_id(&"t4_broken_rule_yard", "PencilSpearPickup") == "t4_broken_rule_yard/PencilSpearPickup", "a pickup is remembered by zone and marker name")
	var empty_slot := SaveData.new()
	var empty_root := _new_root("empty")
	var empty_service := SaveSupport.new_service(empty_root)
	empty_service.write_slot(0, empty_slot)
	empty_service.load_slot(0)
	_expect(empty_service.state.to_text() == empty_slot.to_text() and empty_service.last_load.outcome == SaveLoadResult.LOADED, "a brand new run round-trips too")


func _check_health_never_saves() -> void:
	var root_directory := _new_root("health")
	var service := SaveSupport.new_service(root_directory)
	var wounded := SaveSupport.full_data()
	_expect(wounded.player.courage_current == 1 and wounded.player.courage_max == 4, "setup: the pawn is wounded (1 of 4)")
	service.write_slot(0, wounded)
	var plain := ConfigFile.new()
	plain.load(service.slot_path(0))
	var mentions_current_health := false
	for section in plain.get_sections():
		for key in plain.get_section_keys(section):
			if key.contains("health") or key.contains("carry") or key == "courage_current":
				mentions_current_health = true
	_expect(not mentions_current_health, "the file stores no health and no carry: every launch starts the room fresh")
	service.load_slot(0)
	_expect(service.state.player.courage_current == 4 and service.state.player.courage_max == 4, "a loaded pawn resumes at full Courage (a checkpoint refills it)")


func _check_slots_do_not_see_each_other() -> void:
	var root_directory := _new_root("slots")
	var service := SaveSupport.new_service(root_directory)
	var first := SaveSupport.full_data()
	var second := SaveData.new()
	second.checkpoint_zone_id = &"t1_white_kings_fall"
	second.taken_pickup_ids["t1_white_kings_fall/Sword"] = true
	service.write_slot(0, first)
	service.write_slot(2, second)
	_expect(service.slot_path(2).ends_with("/saves/slot_2.cfg") and FileAccess.file_exists(service.slot_path(2)), "slot 2 has its own file")
	_expect(service.has_save(0) and service.has_save(2) and not service.has_save(1), "has_save tells the slots with something on disk")
	service.load_slot(2)
	_expect(service.active_slot == 2 and service.state.checkpoint_zone_id == &"t1_white_kings_fall" and service.state.taken_pickup_ids.size() == 1, "loading slot 2 gives slot 2")
	service.load_slot(0)
	_expect(service.active_slot == 0 and service.state.to_text() == first.to_text(), "and slot 0 is untouched by it")
	var card: SaveLoadResult = service.read_slot(2)
	_expect(card.data.checkpoint_zone_id == &"t1_white_kings_fall" and service.active_slot == 0 and service.state.checkpoint_zone_id == &"h1_chess_rug_hub", "read_slot reads a card without making it the run")


func _check_the_write_is_atomic_and_keeps_a_backup() -> void:
	var root_directory := _new_root("atomic")
	var service := SaveSupport.new_service(root_directory)
	var older := SaveData.new()
	older.checkpoint_zone_id = &"t1_white_kings_fall"
	var newer := SaveData.new()
	newer.checkpoint_zone_id = &"t2_fallen_sword_tile"
	service.write_slot(0, older)
	var path: String = service.slot_path(0)
	_expect(FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".tmp") and not FileAccess.file_exists(path + ".bak"), "the first write leaves the file, no temp file and no backup yet")
	service.write_slot(0, newer)
	_expect(FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".tmp"), "the second write leaves no temp file")
	var current := SaveFile.read(path)
	var backup := SaveFile.read(path + ".bak")
	_expect(current.is_readable() and SaveData.from_config(current.config).checkpoint_zone_id == &"t2_fallen_sword_tile", "the file is the new save")
	_expect(backup.is_readable() and SaveData.from_config(backup.config).checkpoint_zone_id == &"t1_white_kings_fall", "the .bak is the save before it")
	service.write_slot(0, older)
	_expect(SaveData.from_config(SaveFile.read(path + ".bak").config).checkpoint_zone_id == &"t2_fallen_sword_tile", "every write moves the .bak one save forward")

	# A write that cannot finish leaves the old save alone: its folder cannot be created under a file.
	var blocked_root := _new_root("atomic_blocked")
	SaveSupport.plant(blocked_root + "/saves", "this is a file, not a folder")
	var blocked_service := SaveSupport.new_service(blocked_root)
	_expect(blocked_service.write_slot(0, older) != OK and not FileAccess.file_exists(blocked_service.slot_path(0)), "a write that cannot start reports the error and writes nothing")


func _check_request_save_writes_the_run() -> void:
	var root_directory := _new_root("request")
	var service := SaveSupport.new_service(root_directory)
	service.autosaved.connect(_on_autosaved)
	_expect(not service.has_session, "a service that loaded nothing has no session")
	service.new_game(0)
	_expect(service.has_session and service.state.to_text() == SaveData.new().to_text(), "new_game begins a clean run")
	service.state.taken_pickup_ids["t4_broken_rule_yard/PencilSpearPickup"] = true
	service.state.add_unlock(&"wooden_sword")
	service.current_room_id = &"t4_broken_rule_yard"
	service.add_play_time(2.5)
	service.add_play_time(-1.0)
	service.add_play_time(0.5)
	_expect(is_equal_approx(service.state.play_time_seconds, 3.0), "play time adds up and ignores a negative step")
	_expect(service.request_save(&"pickup_taken"), "a success event writes the run")
	_expect(autosaved_slots == [0] and autosaved_reasons == [&"pickup_taken"], "and says so through the autosaved signal, with the slot and the reason")
	var reader := SaveSupport.new_service(root_directory)
	reader.load_slot(0)
	_expect(reader.state.taken_pickup_ids.has("t4_broken_rule_yard/PencilSpearPickup") and reader.state.has_unlock(&"wooden_sword"), "the saved run holds what was learned")
	_expect(reader.state.room_id == &"t4_broken_rule_yard" and reader.state.saved_at_unix > 1700000000 and is_equal_approx(reader.state.play_time_seconds, 3.0), "and the room, a real timestamp and the play time")


func _on_autosaved(slot: int, reason: StringName) -> void:
	autosaved_slots.append(slot)
	autosaved_reasons.append(reason)


func _check_configure_is_a_new_world() -> void:
	var first_root := _new_root("world_a")
	var second_root := _new_root("world_b")
	var service := SaveSupport.new_service(first_root)
	service.new_game(0)
	service.state.checkpoint_zone_id = &"t3_first_pawn_clash"
	service.request_save(&"checkpoint_reached")
	service.configure(second_root)
	_expect(service.root_directory() == second_root and not service.has_session and service.state.checkpoint_zone_id == &"", "configure points the service at another folder and forgets the run")
	_expect(not service.has_save(0) and service.slot_path(0).begins_with(second_root), "the other folder has no save of the first one")
	service.configure(first_root)
	service.ensure_session()
	_expect(service.has_session and service.state.checkpoint_zone_id == &"t3_first_pawn_clash", "ensure_session continues the active slot when no run has begun")
	service.state.checkpoint_zone_id = &"in_memory_only"
	service.ensure_session()
	_expect(service.state.checkpoint_zone_id == &"in_memory_only", "and leaves a run that has begun alone (a scene reload does not reread the disk)")


func _check_flags_of_a_world_round_trip() -> void:
	var world := EcsWorld.new()
	world.flags.set_flag(&"boss.b1_defeated", true)
	world.flags.set_flag(&"child.trust", 3)
	world.flags.add_to_counter(&"deaths", 2)
	var data := SaveData.new()
	data.player.flags = world.flags.to_dictionary()
	var root_directory := _new_root("flags")
	var service := SaveSupport.new_service(root_directory)
	service.write_slot(0, data)
	service.load_slot(0)
	var next_world := EcsWorld.new()
	next_world.flags.load_dictionary(service.state.player.flags)
	_expect(next_world.flags.get_flag(&"boss.b1_defeated") == true and next_world.flags.get_flag(&"child.trust") == 3 and next_world.flags.get_flag(&"deaths") == 2, "the WorldFlags of a world come back into the next world")
	_expect(typeof(next_world.flags.get_flag(&"deaths")) == TYPE_INT and typeof(next_world.flags.get_flag(&"boss.b1_defeated")) == TYPE_BOOL, "with their types")
	world.free()
	next_world.free()
