@tool
class_name ZoneExitMarker
extends Marker2D

## Editor-placed door cell: stand on this marker's cell and the world travels.
## Pure spawn data — EcsBoot bakes it into EcsGrid.exit_by_cell, MovementSystem
## emits the zone_exit event, the game_root.gd bridge performs the swap. Zero logic.

## Zone id in content/world/world.tres this door leads to.
@export var target_zone: StringName = &""
## ZoneEntryMarker id inside the target zone where the player appears.
@export var target_entry: StringName = &"start"
## If true, this exit only works after every enemy in the current room falls.
## Use this for boss exits and mastery gates, not ordinary backtracking doors.
@export var requires_room_clear := false
## The line the status bar says when the hero steps on this door while it is shut (requires_room_clear and
## the room not cleared yet). Say what holds THIS door: a room with no captain must not blame one. Empty
## uses MessageBridge's own generic line. Like PlayerUnlockMarker.message, the words travel with the
## marker; M4 moves them to a text key.
@export_multiline var locked_message := ""


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if target_zone == &"":
		warnings.append("Set target_zone to a zone id from content/world/world.tres.")
	return warnings
