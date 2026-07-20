class_name RoomEncounter
extends Node2D

## Editor-authored room data + view container. The simulation boots through
## EcsBoot (docs/ecs-conversion-plan.md): parked ActorView children become
## entities, painted solid tiles become blocks, pickup markers become item
## entities. This script only carries the room's prose and objective.

@export var room_message := ""
@export var objective: Resource


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
