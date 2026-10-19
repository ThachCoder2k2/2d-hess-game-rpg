extends Node

## SaveService autoload: the one owner of everything that is written to the disk about a playthrough
## (docs/game-base-plan.md 9.3, 14.1). It replaces the WorldState autoload. Three jobs:
##
##   1. The run in memory. `state` (SaveData) is what the shell reads at every room boot and writes
##      when it learns a fact (a pickup was taken, a gate opened, a skill unlocked). It survives a
##      scene reload because this node is an autoload.
##   2. The slots on disk. One slot exists today (SINGLE_SLOT) behind an API that takes a slot id, so a
##      slots screen is a UI-only change later. A slot is `<root>/saves/slot_<n>.cfg`, written
##      atomically with a .bak (SaveFile), read back through a fallback chain that never wipes anything
##      (read_slot: the file, then the save an interrupted write left as .tmp if it is newer than the .bak,
##      then the .bak, then the v2 WorldState save, then a clean new game, each step logged), and migrated
##      from older formats (SaveMigration).
##   3. The profile (`<root>/profile.cfg`): facts about the player that outlive a slot, today the
##      `completed` mark, which survives a New Game (docs/game-base-plan.md 8.8, 9.1).
##
## Rules this node enforces:
##   - Autosave only on success events (R17). The only way the shell asks for a save is
##     request_save(reason), and a reason that is not in AUTOSAVE_REASONS is refused. Dying is not a
##     success event: a death writes nothing (D-16). tests/save/test_request_save_callers.gd lists
##     the callers.
##   - Nothing outside shell/save/ writes a save file (tests/architecture/test_save_written_only_by_save_service.gd).
##   - A session must exist before anything is written: `has_session` becomes true when a slot is loaded
##     or a new game begins, so a stray request can never write an empty run over a real save.
##   - A save from a newer game is never read as damaged and never overwritten; new_game() sets it aside.
##   - It loads nothing by itself. GameFlow loads on Continue (M3b/M4); until it exists the in-game scene
##     calls ensure_session() when it starts, which is Continue.
##
## There is deliberately no class_name: an autoload's name is a global, and a class_name of the same name
## is an error. Tests make their own instance with `load("res://shell/save/save_service.gd").new()` and
## give it a throwaway folder with configure(), so they never read or write the player's real save.

## A save is about to be written for `reason`. The shell listens and copies the live facts the service
## cannot see (the ECS world's flags) into `state` first, so a request_save() call site never has to.
signal saving(reason: StringName)
## A slot was written. `reason` is the success event that asked (one of AUTOSAVE_REASONS); M4's autosave
## indicator listens.
signal autosaved(slot: int, reason: StringName)

## Where saves go unless configure() says otherwise: Godot's per-user data folder.
const DEFAULT_ROOT_DIRECTORY := "user://"
const SAVES_FOLDER := "saves"
const SLOT_FILE_FORMAT := "slot_%d.cfg"
const PROFILE_FILE := "profile.cfg"
const PROFILE_SECTION := "profile"
const PROFILE_FORMAT_VERSION := 1
## The file the WorldState autoload (save format 2) wrote, relative to the root.
const LEGACY_WORLD_STATE_FILE := "world_state.cfg"
## What the v2 file is renamed to once a v3 save has been written, so a New Game can never find it again.
const LEGACY_RETIRED_SUFFIX := ".migrated"
## What a file from a newer game is renamed to when the player starts a new game over its slot.
const NEWER_GAME_SUFFIX := ".newer_game"
## The slot the base ships with.
const SINGLE_SLOT := 0

## The success events a save may be requested for (R17). Every caller of request_save() names one of them,
## as a literal, which is what lets a test read the callers off the source.
##   room_cleared        a room's objective was met (ObjectiveSystem)
##   shortcut_opened     a one-way gate was unbarred for good
##   pickup_taken        a persistent pickup was taken (a floor weapon is room-local and never asks, D-16)
##   boss_defeated       a boss fell (M8b)
##   rescue_completed    a white piece was freed (M6)
##   checkpoint_reached  the pawn came into a hub or a boss room through a door (D-16, CheckpointSystem)
##   beat_save_after     a story beat flagged `save_after` ended (M6)
##   unlock_gained       a verb or skill was unlocked
##   rule_page_unlocked  a page of the Book of House Rules was written (first meeting with a piece)
## Not in the list on purpose: a death, a hit, a quit, a pause, a timer. Never mid-fight.
const AUTOSAVE_REASONS: Array[StringName] = [
	&"room_cleared",
	&"shortcut_opened",
	&"pickup_taken",
	&"boss_defeated",
	&"rescue_completed",
	&"checkpoint_reached",
	&"beat_save_after",
	&"unlock_gained",
	&"rule_page_unlocked",
]

## The slot the run is saved to.
var active_slot := SINGLE_SLOT
## The run in memory. Replaced (not edited) by new_game() and load_slot(), so read it through the service
## each time and never keep it.
var state := SaveData.new()
## True once a slot was loaded or a new game began. Nothing is written before.
var has_session := false
## The zone the pawn is in now. The shell sets it at every room boot through note_room(); request_save()
## writes it to [meta] once it names a room. A loaded run starts out in the room it was saved in (load_slot
## copies it from the file) and a new game in none, so a save asked for before the shell has noted any room
## carries the room of the run in memory and never blanks it.
var current_room_id: StringName = &""
## What the last load_slot() found, for the title screen's notice. Null before the first load.
var last_load: SaveLoadResult = null

var _root_directory := DEFAULT_ROOT_DIRECTORY
## slot id (int) -> true. Slots whose file is from a newer game: write_slot() refuses them.
var _write_locked_slots: Dictionary = {}


## Points the service at another folder (a test's throwaway one) and forgets the session: a different
## root is a different world. `<root>/saves/slot_<n>.cfg` and `<root>/profile.cfg` live under it. Accepts
## user:// paths and absolute ones.
func configure(root_directory: String) -> void:
	_root_directory = root_directory
	state = SaveData.new()
	has_session = false
	current_room_id = &""
	last_load = null
	active_slot = SINGLE_SLOT
	_write_locked_slots.clear()


func root_directory() -> String:
	return _root_directory


func slot_path(slot: int) -> String:
	return _root_directory.path_join(SAVES_FOLDER).path_join(SLOT_FILE_FORMAT % slot)


func backup_path(slot: int) -> String:
	return slot_path(slot) + SaveFile.BACKUP_SUFFIX


## The file a write builds the new save in before it replaces the slot's file (SaveFile.write).
func temp_path(slot: int) -> String:
	return slot_path(slot) + SaveFile.TEMP_SUFFIX


func profile_path() -> String:
	return _root_directory.path_join(PROFILE_FILE)


func legacy_world_state_path() -> String:
	return _root_directory.path_join(LEGACY_WORLD_STATE_FILE)


## Whether anything is on the disk for this slot (the file, its backup, a complete save an interrupted write
## left as .tmp, or for the first slot the v2 save).
func has_save(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot)) or FileAccess.file_exists(backup_path(slot)) \
		or SaveFile.read(temp_path(slot)).is_readable() \
		or (slot == SINGLE_SLOT and FileAccess.file_exists(legacy_world_state_path()))


# --------------------------------------------------------------------------- the session


## Begins a clean run in `slot`. Touches no save file, except that a file from a newer game in this slot
## is set aside (renamed, never deleted) so the new run can be saved without overwriting it.
func new_game(slot := SINGLE_SLOT) -> void:
	_set_newer_game_files_aside(slot)
	_write_locked_slots.erase(slot)
	active_slot = slot
	state = SaveData.new()
	current_room_id = &""
	has_session = true
	last_load = null


## Continue: loads `slot` (a missing or unusable slot starts a clean run, see read_slot) and makes it the
## run. Logs why when anything other than a normal load happened.
func load_slot(slot := SINGLE_SLOT) -> SaveLoadResult:
	var result := read_slot(slot)
	if result.outcome == SaveLoadResult.LOADED and result.source_path == temp_path(slot):
		_finish_the_interrupted_write(slot, result)
	active_slot = slot
	state = result.data
	current_room_id = state.room_id
	has_session = true
	last_load = result
	_write_locked_slots.erase(slot)
	if not result.slot_is_writable():
		_write_locked_slots[slot] = true
	if result.outcome != SaveLoadResult.LOADED and result.outcome != SaveLoadResult.NEW_GAME_NO_SAVE:
		push_warning("SaveService: slot %d: %s. %s" % [slot, result.outcome, "; ".join(result.log_lines)])
	return result


## The pawn is in zone `zone_id` and came in through its `entry_id` marker: the run now names this room and
## entry, which is where a death returns the pawn and where a Continue resumes. In memory only; the next
## success event writes it to the file. (The latest CHECKPOINT is another fact, `state.checkpoint_zone_id`.)
func note_room(zone_id: StringName, entry_id: StringName) -> void:
	current_room_id = zone_id
	state.room_id = zone_id
	state.room_entry_id = entry_id


## Makes sure a run exists: when none has begun, Continues the active slot. The in-game scene calls it when
## it starts, so it can also run on its own (and in a test) without GameFlow.
func ensure_session() -> void:
	if not has_session:
		load_slot(active_slot)


## What is on the disk for `slot`, read without making it the run (a slot card reads this). The chain:
## the slot's file; if it is missing or damaged, its .bak; for the first slot with neither, the v2
## WorldState save; and when nothing can be read, a clean new game. A file from a newer game, or from a
## version too old to migrate, is not read. `data` is never null. Prints nothing and writes nothing.
func read_slot(slot: int) -> SaveLoadResult:
	var result := SaveLoadResult.new()
	var main_path := slot_path(slot)
	var main := SaveFile.read(main_path)
	var main_verdict := _verdict_of(main)
	result.log_lines.append(_describe(main_path, main, main_verdict))
	match main_verdict:
		&"readable":
			if _take_data_from(result, main, main_path, SaveLoadResult.LOADED):
				return result
			return _newer_game(result, main_path, main)
		&"newer":
			return _newer_game(result, main_path, main)
		&"obsolete":
			return _obsolete(result, main_path, main)

	# The file is missing or damaged. A write that died between its two renames (SaveFile.write) left the new,
	# complete save as <file>.tmp and the previous one as <file>.bak: the .tmp is the latest progress, so it is
	# read before the .bak when it is not older than it.
	var unfinished_path := temp_path(slot)
	var unfinished := SaveFile.read_unfinished_write(main_path)
	var unfinished_verdict := _verdict_of(unfinished)
	if unfinished_verdict != &"missing":
		result.log_lines.append(_describe(unfinished_path, unfinished, unfinished_verdict))
	match unfinished_verdict:
		&"readable":
			if _take_data_from(result, unfinished, unfinished_path, SaveLoadResult.LOADED):
				result.log_lines.append("%s is the newest save: the write that made it was interrupted before it replaced the file, so it is loaded" % unfinished_path)
				return result
			return _newer_game(result, unfinished_path, unfinished)
		&"newer":
			return _newer_game(result, unfinished_path, unfinished)

	var backup_path_of_slot := backup_path(slot)
	var backup := SaveFile.read(backup_path_of_slot)
	var backup_verdict := _verdict_of(backup)
	if backup_verdict != &"missing":
		result.log_lines.append(_describe(backup_path_of_slot, backup, backup_verdict))
	match backup_verdict:
		&"readable":
			if _take_data_from(result, backup, backup_path_of_slot, SaveLoadResult.LOADED_FROM_BACKUP):
				result.notice_key = SaveLoadResult.NOTICE_BACKUP_USED
				return result
			return _newer_game(result, backup_path_of_slot, backup)
		&"newer":
			return _newer_game(result, backup_path_of_slot, backup)

	var anything_damaged := main_verdict == &"damaged" or backup_verdict == &"damaged" or backup_verdict == &"obsolete" \
		or unfinished_verdict == &"damaged"
	if main_verdict == &"missing" and backup_verdict == &"missing" and slot == SINGLE_SLOT:
		var legacy_result := _read_legacy_world_state(result)
		if legacy_result != null:
			return legacy_result
	if anything_damaged:
		result.outcome = SaveLoadResult.NEW_GAME_AFTER_DAMAGE
		result.notice_key = SaveLoadResult.NOTICE_NEW_GAME_AFTER_DAMAGE
		result.log_lines.append("no usable save: starting a clean new game")
		return result
	result.outcome = SaveLoadResult.NEW_GAME_NO_SAVE
	return result


## Writes `data` as the slot's save, the safe way (SaveFile.write). Returns OK, ERR_LOCKED for a slot whose
## file is from a newer game, or the file error. The shell does not call this; it calls request_save().
func write_slot(slot: int, data: SaveData) -> Error:
	if _write_locked_slots.has(slot):
		return ERR_LOCKED
	var error := SaveFile.write(slot_path(slot), data.to_config())
	if error == OK and slot == SINGLE_SLOT:
		SaveFile.set_aside(legacy_world_state_path(), LEGACY_RETIRED_SUFFIX)
	return error


## The one way the shell asks for a save: a success event happened (`reason`, one of AUTOSAVE_REASONS), so
## the run is written to the active slot now. Returns whether a save was written. Refused, with a warning,
## for a reason that is not a success event, before a session exists, and for a slot whose file is from a
## newer game. A failed write is a warning too; the run goes on and the next success event tries again.
func request_save(reason: StringName) -> bool:
	if reason not in AUTOSAVE_REASONS:
		push_warning("SaveService: a save was requested for '%s', which is not a success event (R17); refused" % reason)
		return false
	if not has_session:
		push_warning("SaveService: a save was requested for '%s' before any run began; refused" % reason)
		return false
	saving.emit(reason)
	if current_room_id != &"":
		state.room_id = current_room_id
	state.saved_at_unix = int(Time.get_unix_time_from_system())
	var error := write_slot(active_slot, state)
	if error != OK:
		push_warning("SaveService: the save for '%s' could not be written to slot %d (error %d: %s)" % [reason, active_slot, error, error_string(error)])
		return false
	autosaved.emit(active_slot, reason)
	return true


## Counts play time. The shell calls it once a frame with the frame's delta while the game runs, so a
## paused game (a paused tree does not process the shell) does not count.
func add_play_time(seconds: float) -> void:
	if has_session and seconds > 0.0:
		state.play_time_seconds += seconds


# --------------------------------------------------------------------------- the profile


## The profile's values (key String -> value), or an empty dictionary when there is none or it is unreadable.
## The profile is never reset by a New Game.
func read_profile() -> Dictionary:
	var reading := SaveFile.read(profile_path())
	if not reading.is_readable():
		reading = SaveFile.read(profile_path() + SaveFile.BACKUP_SUFFIX)
	var values: Dictionary = {}
	if reading.is_readable() and reading.config.has_section(PROFILE_SECTION):
		for key in reading.config.get_section_keys(PROFILE_SECTION):
			values[key] = reading.config.get_value(PROFILE_SECTION, key)
	return values


## Writes one profile value now (the whole file, safely). Returns OK or the file error.
func set_profile_value(key: StringName, value: Variant) -> Error:
	var values := read_profile()
	values[String(key)] = value
	var config := ConfigFile.new()
	config.set_value(SaveFile.META_SECTION, SaveFile.VERSION_KEY, PROFILE_FORMAT_VERSION)
	var keys: Array = values.keys()
	keys.sort()
	for profile_key: String in keys:
		config.set_value(PROFILE_SECTION, profile_key, values[profile_key])
	return SaveFile.write(profile_path(), config)


## Whether the player has seen the ending. Survives a New Game, so the title can keep showing the post-game board.
func is_completed() -> bool:
	return read_profile().get("completed", false) == true


## The ending was reached (the Ending, M13). Written to the profile, not to the slot.
func mark_completed() -> Error:
	return set_profile_value(&"completed", true)


# --------------------------------------------------------------------------- reading helpers


## What a reading means for the loader: &"readable", &"missing", &"damaged", &"newer" (declares a version
## this build does not know, whether or not it passes the integrity check) or &"obsolete" (older than
## SaveMigration can read).
func _verdict_of(reading: SaveFile.Reading) -> StringName:
	if reading.status == SaveFile.STATUS_MISSING:
		return &"missing"
	if reading.version > SaveData.FORMAT_VERSION:
		return &"newer"
	if reading.status == SaveFile.STATUS_DAMAGED:
		return &"damaged"
	if reading.version < SaveMigration.OLDEST_READABLE_VERSION:
		return &"obsolete"
	return &"readable"


func _describe(path: String, reading: SaveFile.Reading, verdict: StringName) -> String:
	match verdict:
		&"readable":
			return "%s: read (format %d)" % [path, reading.version]
		&"missing":
			return "%s: not there" % path
		&"newer":
			return "%s: written by a newer game (format %d, this game reads up to %d)" % [path, reading.version, SaveData.FORMAT_VERSION]
		&"obsolete":
			return "%s: format %d is older than this game can migrate (oldest %d)" % [path, reading.version, SaveMigration.OLDEST_READABLE_VERSION]
	return "%s: damaged (%s)" % [path, reading.reason]


## Fills `result` from a readable file: migrates it when it is older and builds the SaveData. False when
## the file turns out to need a newer game after all (its [player] section is from a newer format).
func _take_data_from(result: SaveLoadResult, reading: SaveFile.Reading, path: String, outcome: StringName) -> bool:
	var config := reading.config
	var migrated_from := 0
	if reading.version < SaveData.FORMAT_VERSION:
		migrated_from = reading.version
		var modified := int(FileAccess.get_modified_time(path))
		if not SaveMigration.upgrade_to_current(config, reading.version, modified):
			return false
	var data := SaveData.from_config(config)
	if data == null:
		return false
	result.data = data
	result.outcome = outcome
	result.file_version = reading.version
	result.migrated_from_version = migrated_from
	result.source_path = path
	if migrated_from > 0:
		result.log_lines.append("migrated from format %d to %d" % [migrated_from, SaveData.FORMAT_VERSION])
	return true


func _newer_game(result: SaveLoadResult, path: String, reading: SaveFile.Reading) -> SaveLoadResult:
	result.outcome = SaveLoadResult.NEWER_GAME_REQUIRED
	result.notice_key = SaveLoadResult.NOTICE_NEWER_GAME
	result.file_version = reading.version
	result.source_path = path
	return result


func _obsolete(result: SaveLoadResult, path: String, reading: SaveFile.Reading) -> SaveLoadResult:
	result.outcome = SaveLoadResult.NEW_GAME_OBSOLETE_SAVE
	result.notice_key = SaveLoadResult.NOTICE_OBSOLETE_SAVE
	result.file_version = reading.version
	result.source_path = path
	result.log_lines.append("not read; a clean new game starts and the old file is kept")
	return result


## The v2 WorldState save, migrated; or null when there is none (the caller goes on). A v2 file that is
## unreadable or too old gives a clean new game with its reason, and is left where it is.
func _read_legacy_world_state(result: SaveLoadResult) -> SaveLoadResult:
	var legacy_path := legacy_world_state_path()
	var legacy := SaveFile.read_unchecked(legacy_path)
	if legacy.status == SaveFile.STATUS_MISSING:
		return null
	var verdict := _verdict_of(legacy)
	result.log_lines.append(_describe(legacy_path, legacy, verdict))
	match verdict:
		&"readable":
			if _take_data_from(result, legacy, legacy_path, SaveLoadResult.LOADED):
				return result
			return _newer_game(result, legacy_path, legacy)
		&"newer":
			return _newer_game(result, legacy_path, legacy)
		&"obsolete":
			return _obsolete(result, legacy_path, legacy)
	result.outcome = SaveLoadResult.NEW_GAME_AFTER_DAMAGE
	result.notice_key = SaveLoadResult.NOTICE_NEW_GAME_AFTER_DAMAGE
	return result


## The load took the save from <file>.tmp: finish the write that was interrupted (the rename it never got to), so
## the disk is back to the ordinary layout (file, .bak). The data is already in `result`, so a rename that
## fails only costs a log line: the next write starts from the same place.
func _finish_the_interrupted_write(slot: int, result: SaveLoadResult) -> void:
	var error := SaveFile.finish_unfinished_write(slot_path(slot))
	if error == OK:
		result.source_path = slot_path(slot)
		result.log_lines.append("finished the interrupted write: %s is the slot's file again" % temp_path(slot))
	else:
		result.log_lines.append("could not finish the interrupted write (error %d: %s); the save is loaded from %s as it is" % [error, error_string(error), temp_path(slot)])
		push_warning("SaveService: slot %d: %s" % [slot, result.log_lines[result.log_lines.size() - 1]])


## A file from a newer game in `slot` (its save, its .bak or its .tmp) is renamed out of the way, so the new run can be
## saved without ever overwriting it. Anything else is left alone.
func _set_newer_game_files_aside(slot: int) -> void:
	for path in [slot_path(slot), backup_path(slot), temp_path(slot)]:
		if _verdict_of(SaveFile.read(path)) == &"newer":
			SaveFile.set_aside(path, NEWER_GAME_SUFFIX)
