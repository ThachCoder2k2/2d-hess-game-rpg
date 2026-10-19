extends RefCounted

## Shared by the save suites and the bridge suites. NOT a test (the runner only collects test_*.gd) and
## deliberately without a class_name, so it needs no import pass. Suites load it with
##   const SaveSupport := preload("res://tests/support/save_test_support.gd")
##
## A suite never touches the player's save: it makes its own SaveService (the autoload's script, a fresh
## instance) and points it at a throwaway folder with configure(), `user://test_saves/<suite>_<process>/`
## (docs/game-base-plan.md 9.3; the runner already gives every process its own HOME, so even that folder
## is outside the real user data). tests/architecture/test_suites_isolate_the_save.gd fails a suite that
## boots the game without doing so.

const SaveServiceScript := preload("res://shell/save/save_service.gd")
const TEST_SAVES_FOLDER := "user://test_saves"


## A new folder name for one suite's saves, unique to this process. Nothing is created yet.
static func make_root(suite_name: String) -> String:
	return TEST_SAVES_FOLDER.path_join("%s_%d_%d" % [suite_name, OS.get_process_id(), Time.get_ticks_usec()])


## A SaveService (not in the tree) pointed at `root_directory`.
static func new_service(root_directory: String) -> Node:
	var service: Node = SaveServiceScript.new()
	service.configure(root_directory)
	return service


## Deletes the folder and everything below it.
static func remove_root(root_directory: String) -> void:
	var directory := DirAccess.open(root_directory)
	if directory == null:
		return
	for file_name in directory.get_files():
		DirAccess.remove_absolute(root_directory.path_join(file_name))
	for sub_directory in directory.get_directories():
		remove_root(root_directory.path_join(sub_directory))
	DirAccess.remove_absolute(root_directory)


## The bytes of a file, "" when it is not there.
static func text_of(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""


## Writes `text` to `path` exactly (creating the folder): for planting a damaged or foreign file.
static func plant(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


## A SaveData with every field set to something other than its default, so a round trip that drops a
## field is seen. `courage_current` is below max on purpose: health never saves.
static func full_data() -> SaveData:
	var data := SaveData.new()
	data.play_time_seconds = 1234.5
	data.room_id = &"t4_broken_rule_yard"
	data.room_entry_id = &"from_t3"
	data.saved_at_unix = 1760000000
	data.checkpoint_zone_id = &"h1_chess_rug_hub"
	data.checkpoint_entry_id = &"from_b1"
	data.cleared_room_ids = {"t3_first_pawn_clash": true, "t4_broken_rule_yard": true}
	data.defeated_boss_ids = {"b1_black_pawn_captain": true}
	data.taken_pickup_ids = {"t4_broken_rule_yard/PencilSpearPickup": true, "h1_chess_rug_hub/Shard 1": true}
	data.opened_gate_ids = {"pass_home_gate": true}
	data.unlocked_rule_ids = {"pawn_recruit": true, "pawn_armed": true}
	data.rescued_piece_ids = {"pebble": true}
	data.collected_page_ids = {"first_law": true, "armed_pawn": true}
	data.courage_shard_ids = {"shard_a": true, "shard_b": true, "shard_c": true}
	data.player.courage_max = 4
	data.player.courage_current = 1
	data.player.believe_current = 2
	data.player.unlocked_skill_ids = [&"wooden_sword", &"pencil_thrust", &"rule_step"]
	data.player.applied_upgrade_ids = [&"lead_tip"]
	data.player.equipped_page_ids = [&"first_law", &"armed_pawn"]
	data.player.margin = 3
	data.player.locked_directions = [Vector2i.LEFT, Vector2i.DOWN]
	data.player.facing = Vector2i.RIGHT
	data.player.flags = {"boss.b1_defeated": true, "child.trust": 2, "deaths": 7, "beat.intro seen": true}
	return data
