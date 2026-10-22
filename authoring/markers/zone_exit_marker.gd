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
## Text key (ROOM_<ID>_LOCKED in rooms.po): the line the status bar says when the hero steps on this door while it
## is shut (requires_room_clear and the room not cleared yet). The row says what holds THIS door: a room with no
## captain must not blame one. Empty uses MessageBridge's own generic line (MSG_DOOR_IS_LOCKED).
@export var locked_message := ""
## A world flag this door waits for (docs/game-base-plan.md 5.7, 7.3): the door stays shut, and says `locked_message`,
## until the flag is set. A hub door waits for the boss before it (`boss.knight_captain`, set by BossDefeatSystem when
## that boss falls). Empty = the door asks for no flag. The same fact is a flag lock on the door's edge in
## content/world/world.tres (WorldCheck holds the two together).
@export var requires_flag: StringName = &""
## True when stepping on this cell ends the run instead of travelling (the ending, docs/game-base-plan.md 8.8): the
## MovementSystem says `ending_reached` and the shell shows the ending cards, then the credits. Such a door leads
## nowhere, so it names no target_zone. M13 turns the one cell into the exit beyond the board's edge.
@export var ends_run := false


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if ends_run:
		if target_zone != &"":
			warnings.append("A door that ends the run leads nowhere: clear target_zone (it is '%s')." % target_zone)
	elif target_zone == &"":
		warnings.append("Set target_zone to a zone id from content/world/world.tres.")
	if requires_flag != &"":
		if not FlagId.is_valid(requires_flag):
			warnings.append("requires_flag '%s' is not a flag id (lowercase words, groups joined by a dot: boss.knight_captain)." % requires_flag)
		if locked_message.is_empty():
			warnings.append("A door that waits for a flag must say why: set locked_message (a text key).")
	return warnings
