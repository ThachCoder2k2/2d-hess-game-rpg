class_name SaveData
extends RefCounted

## Everything one save slot remembers, in memory (schema v3, docs/game-base-plan.md 9.3), and the
## conversion to and from the ConfigFile that holds it on disk. Pure data, no decisions: the shell writes
## the facts it learns from events (a pickup was taken, a gate opened, a skill unlocked) and the
## SaveService decides when the slot is written. It replaces the WorldState autoload's fields.
##
## The file, section by section (docs/game-base-plan.md 9.3; a key that is absent reads as its default,
## so a save written by an older game, or damaged in one key, still loads):
##
##   [meta]        version, play_time_seconds, room, saved_at_unix. What a save-slot card shows.
##   [checkpoint]  zone_id, entry_id. Where a death returns to and where Continue resumes.
##   [world]       the sets below: cleared rooms, defeated bosses, taken pickups, opened gates, read
##                 Book pages, rescued pieces, found Rule Pages, found Courage Shards.
##   [player]      the PlayerSnapshot: Courage max, Believe, unlocked skills, upgrades, equipped pages,
##                 Margin, locked directions, facing. Courage CURRENT is deliberately not written: health
##                 never saves, every launch starts the room with full Courage (a checkpoint refills it).
##   [flags]       the WorldFlags of the run, one key per flag: flag id -> bool or int.
##
## Every set below is a dictionary of id (String) -> true, written as a sorted array so the file is the
## same every time the same data is saved.

## The format this build writes. Bump it when a key changes meaning, and add the step that reads the old
## format to SaveMigration.
const FORMAT_VERSION := 3

const META := "meta"
const CHECKPOINT := "checkpoint"
const WORLD := "world"
const PLAYER := "player"
const FLAGS := "flags"

## PlayerSnapshot keys the file does not store as part of [player]: the flags have their own section
## and the current Courage is not saved (see the class comment).
const PLAYER_KEYS_STORED_ELSEWHERE: Array[String] = ["flags", "courage_current"]

## The names of the id sets of [world], in the order they are written.
const WORLD_SET_NAMES: Array[String] = [
	"cleared_room_ids", "defeated_boss_ids", "taken_pickup_ids", "opened_gate_ids",
	"unlocked_rule_ids", "rescued_piece_ids", "collected_page_ids", "courage_shard_ids",
]

# --- [meta]
## Seconds of play, summed by SaveService.add_play_time().
var play_time_seconds := 0.0
## The zone the player was in at the last save: the room the slot card names.
var room_id: StringName = &""
## When the slot was last written (Unix seconds); 0 for a save that has never been written.
var saved_at_unix := 0

# --- [checkpoint]
## The zone a death returns to and Continue resumes in ("" = the scene's authored default zone).
## Until the checkpoint rules (D-16: hub entry and every boss-room entry) land in M3b step 3, the shell
## moves it on every zone travel, which is exactly where WorldState.current_zone_id and last_entry_id moved.
var checkpoint_zone_id: StringName = &""
## The entry marker of that zone the pawn appears on.
var checkpoint_entry_id: StringName = &"start"

# --- [world]
## zone id -> true. Rooms whose objective was met; they stay cleared (D-17): their enemies are not spawned
## again. Written by SaveBridge when ObjectiveSystem says `room_cleared`.
var cleared_room_ids: Dictionary = {}
## boss id -> true. Bosses never come back (M8b).
var defeated_boss_ids: Dictionary = {}
## "zone_id/PickupMarkerName" -> true. Persistent pickups (PickupSpawnPoint.persistent) that were taken and
## never respawn. A floor weapon is room-local (D-16) and is never written here.
var taken_pickup_ids: Dictionary = {}
## gate id -> true. Shortcut gates that were unbarred for good.
var opened_gate_ids: Dictionary = {}
## piece id -> true. Pages of the Book of House Rules read (first meeting with the piece).
var unlocked_rule_ids: Dictionary = {}
## piece id -> true. White pieces the pawn freed (M6).
var rescued_piece_ids: Dictionary = {}
## Rule Page id -> true. Pages found, equipped or not (M7c; which are equipped is in `player`).
var collected_page_ids: Dictionary = {}
## shard id -> true. Courage Shards found; three give one more Courage (M7c).
var courage_shard_ids: Dictionary = {}

# --- the pawn
## What the pawn takes with it: Courage max, Believe, unlocked skill ids, applied upgrades, equipped Rule
## Pages and Margin, locked directions, facing and the flags of the run (player.flags). Today the unlocked
## skill ids hold "wooden_sword" (the old WorldState.player_unlock_ids).
var player := PlayerSnapshot.new()


## The id a pickup is remembered by: its zone and its marker's node name.
static func pickup_id(zone_id: StringName, marker_name: String) -> String:
	return "%s/%s" % [zone_id, marker_name]


## Whether the pawn has unlocked this skill (or verb) id.
func has_unlock(unlock_id: StringName) -> bool:
	return unlock_id in player.unlocked_skill_ids


## Records an unlock. True when it was new.
func add_unlock(unlock_id: StringName) -> bool:
	if has_unlock(unlock_id):
		return false
	player.unlocked_skill_ids.append(unlock_id)
	return true


## The set named `set_name` (one of WORLD_SET_NAMES), for code that handles them all alike.
func world_set(set_name: String) -> Dictionary:
	return get(set_name)


## The slot as a ConfigFile, ready for SaveFile.write().
func to_config() -> ConfigFile:
	var config := ConfigFile.new()
	config.set_value(META, SaveFile.VERSION_KEY, FORMAT_VERSION)
	config.set_value(META, "play_time_seconds", play_time_seconds)
	config.set_value(META, "room", String(room_id))
	config.set_value(META, "saved_at_unix", saved_at_unix)
	config.set_value(CHECKPOINT, "zone_id", String(checkpoint_zone_id))
	config.set_value(CHECKPOINT, "entry_id", String(checkpoint_entry_id))
	for set_name in WORLD_SET_NAMES:
		config.set_value(WORLD, set_name, _sorted_ids(world_set(set_name)))
	var player_dictionary := player.to_dictionary()
	for key: String in player_dictionary:
		if key not in PLAYER_KEYS_STORED_ELSEWHERE:
			config.set_value(PLAYER, key, player_dictionary[key])
	var flag_names: Array = player.flags.keys()
	flag_names.sort()
	for flag_name: String in flag_names:
		config.set_value(FLAGS, flag_name, player.flags[flag_name])
	return config


## The slot as the text SaveFile writes (without the integrity footer): equal data gives equal text, so
## tests compare two slots with it.
func to_text() -> String:
	return to_config().encode_to_text()


## The slot a ConfigFile of the CURRENT format holds. A key that is missing or has the wrong type keeps
## its default, so damage to one key never costs the rest. Returns null for a [player] section written by
## a newer snapshot format (only a newer game can read it).
static func from_config(config: ConfigFile) -> SaveData:
	var data := SaveData.new()
	data.play_time_seconds = _number(_value(config, META, "play_time_seconds"), data.play_time_seconds)
	data.room_id = StringName(_text(_value(config, META, "room"), String(data.room_id)))
	data.saved_at_unix = int(_number(_value(config, META, "saved_at_unix"), data.saved_at_unix))
	data.checkpoint_zone_id = StringName(_text(_value(config, CHECKPOINT, "zone_id"), String(data.checkpoint_zone_id)))
	data.checkpoint_entry_id = StringName(_text(_value(config, CHECKPOINT, "entry_id"), String(data.checkpoint_entry_id)))
	for set_name in WORLD_SET_NAMES:
		data.world_set(set_name).assign(_set_from(_value(config, WORLD, set_name)))
	var player_dictionary: Dictionary = {}
	if config.has_section(PLAYER):
		for key in config.get_section_keys(PLAYER):
			player_dictionary[key] = config.get_value(PLAYER, key)
	var flag_dictionary: Dictionary = {}
	if config.has_section(FLAGS):
		for flag_name in config.get_section_keys(FLAGS):
			flag_dictionary[flag_name] = config.get_value(FLAGS, flag_name)
	player_dictionary["flags"] = flag_dictionary
	var saved_player := PlayerSnapshot.from_dictionary(player_dictionary)
	if saved_player == null:
		return null
	# Health never saves: the pawn resumes with the Courage it can have at most.
	saved_player.courage_current = saved_player.courage_max
	data.player = saved_player
	return data


## The value at section/key, or null when the file has none. (ConfigFile.get_value() with a null default
## prints an engine error for a missing key, so a key is asked for first.)
static func _value(config: ConfigFile, section: String, key: String) -> Variant:
	return config.get_value(section, key) if config.has_section_key(section, key) else null


static func _sorted_ids(id_set: Dictionary) -> Array:
	var ids: Array = id_set.keys()
	ids.sort()
	return ids


## A set (id -> true) from a saved array of ids; anything else gives an empty set.
static func _set_from(value: Variant) -> Dictionary:
	var id_set: Dictionary = {}
	if value is Array:
		for entry: Variant in value:
			if entry is String or entry is StringName:
				id_set[String(entry)] = true
	return id_set


static func _number(value: Variant, fallback: float) -> float:
	return float(value) if (value is int or value is float) else fallback


static func _text(value: Variant, fallback: String) -> String:
	return String(value) if (value is String or value is StringName) else fallback
