@tool
class_name ZoneEntryMarker
extends Marker2D

## Editor-placed arrival cell: a ZoneExitMarker in another zone names this
## marker's entry_id and the player appears on this cell after the fade.
## Pure spawn data — the main.gd bridge reads it before booting. Zero logic.

@export var entry_id: StringName = &"start"
