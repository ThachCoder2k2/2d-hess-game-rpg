extends UnboundTest

## New Game resets the slot (docs/game-base-plan.md 9.1, 15 M4 acceptance `test_new_game_resets_slot`): choosing
## New Game over a used slot begins a clean run AND writes that clean run over the slot's file at once, so a
## relaunch and a Continue cannot bring the old run back; the old save is not wiped (the .bak keeps it), a file
## from a newer game is set aside and never overwritten, a damaged one is kept as .corrupt, and the profile's
## `completed` mark, which outlives a slot, is kept. It is the player's command and not a success event: no
## autosave tick. Driven through GameFlow with a real SaveService on a throwaway folder (no scene).

const SaveSupport := preload("res://tests/support/save_test_support.gd")
## What the service renames a newer game's file to (SaveService.NEWER_GAME_SUFFIX).
const NEWER_GAME_SUFFIX := ".newer_game"

var roots_to_remove: Array[String] = []
var autosaved_count := 0


func _init() -> void:
	suite_title = "NEW GAME RESETS SLOT TEST"
	_new_game_over_a_used_slot()
	_new_game_over_a_file_from_a_newer_game()
	_new_game_over_a_damaged_file()
	_new_game_with_no_save()
	for root_to_remove in roots_to_remove:
		SaveSupport.remove_root(root_to_remove)
	finish()


func _new_flow_at_title(save_service: Node) -> GameFlow:
	var flow := GameFlow.new()
	flow.save_service = save_service
	flow.finish_boot()
	return flow


func _new_game_over_a_used_slot() -> void:
	var root_directory := SaveSupport.make_root("new_game_used")
	roots_to_remove.append(root_directory)
	var first_launch := SaveSupport.new_service(root_directory)
	first_launch.new_game(0)
	first_launch.state = SaveSupport.full_data()
	first_launch.state.room_id = &"t4_broken_rule_yard"
	_expect(first_launch.request_save(&"room_cleared"), "setup: a used slot is on the disk (T4, cleared rooms, unlocks, flags, a checkpoint)")
	_expect(first_launch.mark_completed() == OK, "setup: the ending was seen once (the profile's mark)")

	# A relaunch: nothing in memory, the title is up.
	var service := SaveSupport.new_service(root_directory)
	service.autosaved.connect(func(_slot: int, _reason: StringName) -> void: autosaved_count += 1)
	var flow := _new_flow_at_title(service)
	var before: SaveLoadResult = service.read_slot(0)
	_expect(before.found_progress() and before.data.room_id == &"t4_broken_rule_yard" and before.data.cleared_room_ids.size() == 2, "before: the slot holds the old run")
	_expect(not service.has_session, "before: the relaunched service has not begun a run")

	var states: Array[GameFlow.State] = []
	flow.state_changed.connect(func(_previous: GameFlow.State, current: GameFlow.State) -> void: states.append(current))
	_expect(flow.start_new_game() and flow.state == GameFlow.State.PLAYING and flow.start_mode == GameFlow.StartMode.NEW_GAME, "New Game from the title starts playing, as a new game")
	_expect(states == [GameFlow.State.PLAYING], "and says so once")

	var run: SaveData = service.state
	_expect(service.has_session and service.active_slot == 0, "the service has a session in the slot")
	_expect(run.cleared_room_ids.is_empty() and run.defeated_boss_ids.is_empty() and run.taken_pickup_ids.is_empty() and run.opened_gate_ids.is_empty() and run.unlocked_rule_ids.is_empty() and run.rescued_piece_ids.is_empty() and run.collected_page_ids.is_empty() and run.courage_shard_ids.is_empty(), "the run in memory has none of the old world facts")
	_expect(run.room_id == &"" and run.room_entry_id == &"start" and not run.has_checkpoint() and run.play_time_seconds == 0.0, "no room, no checkpoint, no play time")
	_expect(run.player.unlocked_skill_ids.is_empty() and run.player.flags.is_empty() and run.player.margin == 0, "the pawn has no unlock, no flag and no Margin")

	var after: SaveLoadResult = service.read_slot(0)
	_expect(after.found_progress() and after.data.cleared_room_ids.is_empty() and after.data.room_id == &"" and not after.data.has_checkpoint() and after.data.player.unlocked_skill_ids.is_empty(), "the slot's FILE is the clean run now, so a relaunch and a Continue cannot bring the old one back")
	var relaunch := SaveSupport.new_service(root_directory)
	var relaunch_flow := _new_flow_at_title(relaunch)
	_expect(relaunch_flow.continue_game() and relaunch.state.cleared_room_ids.is_empty() and relaunch.state.room_id == &"", "after a relaunch, Continue resumes the clean run")

	var kept := SaveFile.read(service.backup_path(0))
	_expect(kept.is_readable(), "the old save is not wiped: it is the .bak")
	if kept.is_readable():
		var kept_run := SaveData.from_config(kept.config)
		_expect(kept_run.cleared_room_ids.size() == 2 and kept_run.room_id == &"t4_broken_rule_yard", "and it still holds the old run")

	_expect(service.is_completed() and service.read_profile().get("completed") == true, "the profile's `completed` mark is kept by a New Game")
	_expect(autosaved_count == 0, "a New Game is not an autosave: no tick")
	_expect(flow.load_notice_key == &"", "and it has no load notice")


func _new_game_over_a_file_from_a_newer_game() -> void:
	var root_directory := SaveSupport.make_root("new_game_newer")
	roots_to_remove.append(root_directory)
	var newer := ConfigFile.new()
	newer.set_value("meta", "version", SaveData.FORMAT_VERSION + 3)
	newer.set_value("meta", "room", "from_the_future")
	var newer_text := SaveFile.encode(newer)
	var service := SaveSupport.new_service(root_directory)
	SaveSupport.plant(service.slot_path(0), newer_text)
	var flow := _new_flow_at_title(service)
	_expect(service.has_save(0) and not service.read_slot(0).found_progress(), "setup: the slot holds a save from a newer game, which is not progress")
	_expect(not flow.continue_game(), "Continue is refused for a save from a newer game")
	_expect(flow.state == GameFlow.State.TITLE, "and the flow stays on the title")
	_expect(flow.start_new_game(), "New Game is allowed")
	_expect(SaveSupport.text_of(service.slot_path(0) + NEWER_GAME_SUFFIX) == newer_text, "the newer game's file is set aside, byte for byte, never overwritten")
	_expect(service.read_slot(0).found_progress() and service.read_slot(0).data.room_id == &"", "and the slot holds the clean run")


func _new_game_over_a_damaged_file() -> void:
	var root_directory := SaveSupport.make_root("new_game_damaged")
	roots_to_remove.append(root_directory)
	var service := SaveSupport.new_service(root_directory)
	SaveSupport.plant(service.slot_path(0), "this is not a save file\n")
	var flow := _new_flow_at_title(service)
	_expect(service.has_save(0) and not service.read_slot(0).found_progress(), "setup: the slot holds a damaged file and no backup")
	_expect(not flow.continue_game(), "Continue is refused for a damaged file with no backup")
	_expect(flow.start_new_game(), "New Game is allowed")
	_expect(FileAccess.file_exists(service.slot_path(0) + SaveFile.DAMAGED_SUFFIX), "the damaged file is kept as .corrupt")
	_expect(service.read_slot(0).found_progress(), "and the slot holds the clean run")


func _new_game_with_no_save() -> void:
	var root_directory := SaveSupport.make_root("new_game_none")
	roots_to_remove.append(root_directory)
	var service := SaveSupport.new_service(root_directory)
	var flow := _new_flow_at_title(service)
	_expect(not service.has_save(0), "setup: a first launch has no save")
	_expect(not flow.continue_game() and flow.state == GameFlow.State.TITLE, "Continue is refused when there is nothing to continue")
	_expect(flow.start_new_game() and service.has_save(0), "New Game writes the first save")
	_expect(not service.is_completed(), "and a player who never finished has no completed mark")
