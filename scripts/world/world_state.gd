extends Node

## WorldState autoload: the permanent memory of the world. Pure data — no
## gameplay decisions live here. The main.gd bridge writes travel/pickup
## facts; the bridge feeds them back into EcsBoot so the world reboots into
## the state the player left it in. Survives scene reloads because it is an
## autoload; save-to-disk arrives with the gates milestone.

## Zone the player is currently in ("" = the scene's authored default).
var current_zone_id: StringName = &""
## Entry marker the player last arrived through (death respawns here).
var last_entry_id: StringName = &"start"
## Health carried across a zone travel; -1 = no carry (fresh boot or death).
var player_health_carry := -1
## "zone_id/PickupNodeName" -> true. Taken pickups never respawn.
var taken_pickup_ids: Dictionary = {}
## "gate_id" -> true. Opened gates stay open forever (gates milestone).
var opened_gate_ids: Dictionary = {}
## "piece_id" -> true. Book of House Rules pages read (first meeting).
var unlocked_rule_ids: Dictionary = {}


const SAVE_PATH := "user://world_state.cfg"


func _ready() -> void:
	load_state()


func reset() -> void:
	current_zone_id = &""
	last_entry_id = &"start"
	player_health_carry = -1
	taken_pickup_ids.clear()
	opened_gate_ids.clear()
	unlocked_rule_ids.clear()


func pickup_id(zone_id: StringName, marker_name: String) -> String:
	return "%s/%s" % [zone_id, marker_name]


## The save file is the world's memory across launches: where the run is,
## what is taken, what is open. Health never saves — every launch starts
## the current zone fresh.
func save_state(path := SAVE_PATH) -> void:
	var file := ConfigFile.new()
	file.set_value("world", "current_zone_id", current_zone_id)
	file.set_value("world", "last_entry_id", last_entry_id)
	file.set_value("world", "taken_pickup_ids", taken_pickup_ids.keys())
	file.set_value("world", "opened_gate_ids", opened_gate_ids.keys())
	file.set_value("world", "unlocked_rule_ids", unlocked_rule_ids.keys())
	file.save(path)


func load_state(path := SAVE_PATH) -> void:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return
	current_zone_id = StringName(String(file.get_value("world", "current_zone_id", "")))
	last_entry_id = StringName(String(file.get_value("world", "last_entry_id", "start")))
	taken_pickup_ids.clear()
	for key: String in file.get_value("world", "taken_pickup_ids", []):
		taken_pickup_ids[key] = true
	opened_gate_ids.clear()
	for key in file.get_value("world", "opened_gate_ids", []):
		opened_gate_ids[String(key)] = true
	unlocked_rule_ids.clear()
	for key in file.get_value("world", "unlocked_rule_ids", []):
		unlocked_rule_ids[String(key)] = true
