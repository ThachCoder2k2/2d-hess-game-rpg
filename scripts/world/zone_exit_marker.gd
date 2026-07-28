@tool
class_name ZoneExitMarker
extends Marker2D

## Editor-placed door cell: stand on this marker's cell and the world travels.
## Pure spawn data — EcsBoot bakes it into EcsGrid.exit_by_cell, MovementSystem
## emits the zone_exit event, the main.gd bridge performs the swap. Zero logic.

## Zone id in resources/world/world_graph.tres this door leads to.
@export var target_zone: StringName = &""
## ZoneEntryMarker id inside the target zone where the player appears.
@export var target_entry: StringName = &"start"


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if target_zone == &"":
		warnings.append("Set target_zone to a zone id from world_graph.tres.")
	return warnings
