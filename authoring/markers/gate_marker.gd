@tool
class_name GateMarker
extends Marker2D

## Editor-placed one-way shortcut gate: its cell is solid until the player
## pushes into it moving in opens_from's direction (the far side), then it
## opens forever (WorldState). Pure spawn data — EcsBoot bakes the block,
## MovementSystem decides the opening, the bridge hides the visual. The
## child Polygon2Ds are the closed-gate look.

## Globally unique id — WorldState remembers opened gates by it.
@export var gate_id: StringName = &""
## The movement direction that opens the gate: a player stepping onto the
## gate cell while moving this way unbars it. Every other approach is a wall.
@export var opens_from := Vector2i.LEFT


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if gate_id == &"":
		warnings.append("Set a globally unique gate_id (WorldState keys on it).")
	if opens_from == Vector2i.ZERO:
		warnings.append("opens_from must be a direction, not zero.")
	return warnings
