class_name RoomEncounter
extends Node2D

## Editor-authored room data + view container. The simulation boots through
## EcsBoot (docs/ecs-conversion-plan.md): parked ActorView children become
## entities, painted solid tiles become blocks, pickup markers become item
## entities. This script only carries the room's prose and objective.

@export var room_message := ""
@export var objective: Resource
## World-map identity (empty = standalone room outside the world graph).
@export var zone_id: StringName = &""
## True when stepping into this room through a door is a checkpoint (D-16): a hub, and every boss room.
## The pawn's Courage is refilled and the run remembers the entry it came by (the checkpoint). Death does not
## move the pawn to the checkpoint; it starts the room it fell in again from its own entry (docs/game-base-plan.md 5.2).
@export var checkpoint_on_entry := false
## Board cells this room spans; EcsBoot sizes the grid from it.
@export var board_size := Vector2i(16, 9)


func get_start_message() -> String:
	if objective != null and not String(objective.get("start_message")).is_empty():
		return String(objective.get("start_message"))
	return room_message


func get_clear_message() -> String:
	return _objective_text("clear_message", "ROOM CLEARED")


func get_clear_subtitle() -> String:
	return _objective_text("clear_subtitle", "PRESS R TO RESET")


func get_defeat_message() -> String:
	return _objective_text("defeat_message", "THE PAWN FALLS")


func get_defeat_subtitle() -> String:
	return _objective_text("defeat_subtitle", "THE CHILD RESETS THE BOARD")


func _objective_text(property: StringName, fallback: String) -> String:
	if objective == null:
		return fallback
	var value := String(objective.get(property))
	return value if not value.is_empty() else fallback
