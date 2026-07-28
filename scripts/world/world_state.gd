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


func reset() -> void:
	current_zone_id = &""
	last_entry_id = &"start"
	player_health_carry = -1
	taken_pickup_ids.clear()
	opened_gate_ids.clear()


func pickup_id(zone_id: StringName, marker_name: String) -> String:
	return "%s/%s" % [zone_id, marker_name]
