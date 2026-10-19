class_name SaveLoadResult
extends RefCounted

## What reading a save slot found, and what the game should do about it (docs/game-base-plan.md 9.2 "Corrupt
## or newer save"). The loader never throws and never wipes: whatever the disk holds, `data` is a slot the
## game can start from, and `outcome` says how it got there so the title screen (M4) can tell the player.

## The slot's own file was read (and migrated, when it was older).
const LOADED := &"loaded"
## The slot's file was missing or damaged and the previous save, the .bak, was read instead.
const LOADED_FROM_BACKUP := &"loaded_from_backup"
## Nothing is on the disk for this slot: a clean new game. Not a problem, no notice.
const NEW_GAME_NO_SAVE := &"new_game_no_save"
## The file (and its .bak) is damaged: a clean new game, the damaged file kept next to it as .corrupt
## once the new game saves.
const NEW_GAME_AFTER_DAMAGE := &"new_game_after_damage"
## The file is from a version older than SaveMigration can read: a clean new game, the old file kept as
## the .bak once the new game saves.
const NEW_GAME_OBSOLETE_SAVE := &"new_game_obsolete_save"
## The file was written by a NEWER game. It is not read and not overwritten: the slot starts a clean
## in-memory game that cannot be saved over it (SaveService.new_game() sets the old file aside).
const NEWER_GAME_REQUIRED := &"newer_game_required"

## The text keys of the notices (the words are a M4 text-pipeline row, see notice_key).
const NOTICE_BACKUP_USED := &"save_notice_backup_used"
const NOTICE_NEW_GAME_AFTER_DAMAGE := &"save_notice_new_game_after_damage"
const NOTICE_OBSOLETE_SAVE := &"save_notice_obsolete_save"
const NOTICE_NEWER_GAME := &"save_notice_newer_game"

## One of the constants above.
var outcome: StringName = NEW_GAME_NO_SAVE
## The slot to play: what was read, or a fresh one. Never null.
var data: SaveData = SaveData.new()
## The format version the file declared, 0 when no file was read.
var file_version := 0
## The format version the data was migrated from; 0 when it needed no migration.
var migrated_from_version := 0
## The path of the file the data came from, "" for a new game.
var source_path := ""
## The text key of the one-line notice the title screen shows (docs/game-base-plan.md 9.2), "" for none.
## The words are a M4 text-pipeline row; until then a key is all the loader knows.
var notice_key: StringName = &""
## Everything the loader tried and found, in order, in words for the log.
var log_lines: PackedStringArray = []


## Whether the slot's progress was read from disk (as opposed to a clean new game).
func found_progress() -> bool:
	return outcome == LOADED or outcome == LOADED_FROM_BACKUP


## Whether the slot may be written over: false only for a file from a newer game.
func slot_is_writable() -> bool:
	return outcome != NEWER_GAME_REQUIRED
