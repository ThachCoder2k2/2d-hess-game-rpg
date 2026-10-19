class_name SaveMigration
extends RefCounted

## The chain that turns an older save into the current format (docs/game-base-plan.md 9.3), replacing the
## silent wipe the WorldState autoload did on a version mismatch. Each step reads a ConfigFile of version N
## and rewrites it, in place, as version N+1; upgrade_to_current() runs the steps one after the other, so a
## new format adds ONE step and every older save keeps loading.
##
## Versions:
##   2  the WorldState save (user://world_state.cfg): [meta] version, [world] current_zone_id,
##      last_entry_id, taken_pickup_ids, opened_gate_ids, unlocked_rule_ids, player_unlock_ids.
##      The fixture tests/fixtures/saves/world_state_v2.cfg is a real one, written by the v2 code.
##   3  SaveData: [meta] gains play time, room and a timestamp, the position moves to [checkpoint], the
##      unlocks move to [player], the new sets and the flags start empty.
##
## A save older than OLDEST_READABLE_VERSION is not migrated. Version 1 and the unversioned files before
## it booted the player into the retired kingdom start, which is why the v2 format was introduced; they
## are reported as obsolete and left on the disk untouched.

## The oldest format a step exists for.
const OLDEST_READABLE_VERSION := 2


## Rewrites `config` (of format `from_version`) as the current format, in place. `file_modified_unix` is
## the file's own modification time, the best guess of when a save without a timestamp was written.
## False, with `config` unchanged or partly changed, when no step exists for a version on the way: the
## caller treats that save as unreadable.
static func upgrade_to_current(config: ConfigFile, from_version: int, file_modified_unix := 0) -> bool:
	var version := from_version
	while version < SaveData.FORMAT_VERSION:
		match version:
			2:
				_upgrade_2_to_3(config, file_modified_unix)
			_:
				return false
		version += 1
	return version == SaveData.FORMAT_VERSION


## v2 -> v3. Only moves and renames: no fact of the v2 save is dropped.
static func _upgrade_2_to_3(config: ConfigFile, file_modified_unix: int) -> void:
	var zone_id := String(config.get_value("world", "current_zone_id", ""))
	var entry_id := String(config.get_value("world", "last_entry_id", "start"))
	var unlocked_skills := _strings_from(config.get_value("world", "player_unlock_ids", []))
	for moved_key in ["current_zone_id", "last_entry_id", "player_unlock_ids"]:
		if config.has_section_key("world", moved_key):
			config.erase_section_key("world", moved_key)
	config.set_value(SaveData.META, SaveFile.VERSION_KEY, 3)
	config.set_value(SaveData.META, "play_time_seconds", 0.0)
	config.set_value(SaveData.META, "room", zone_id)
	config.set_value(SaveData.META, "saved_at_unix", file_modified_unix)
	config.set_value(SaveData.CHECKPOINT, "zone_id", zone_id)
	config.set_value(SaveData.CHECKPOINT, "entry_id", entry_id)
	config.set_value(SaveData.PLAYER, "unlocked_skill_ids", unlocked_skills)


## An array of Strings from a saved array whose entries may be Strings or StringNames.
static func _strings_from(value: Variant) -> Array:
	var strings: Array = []
	if value is Array:
		for entry: Variant in value:
			if entry is String or entry is StringName:
				strings.append(String(entry))
	return strings
