class_name MovementConfig
extends Resource

@export_range(0.05, 1.0, 0.01) var step_duration := 0.18
@export_range(0.0, 2.0, 0.01) var move_recovery := 0.18
@export_range(1, 8) var preferred_distance := 2
@export_range(1, 16) var path_memory_size := 6
@export_range(0, 10) var goal_commitment_decisions := 2
@export var allowed_directions: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT,
]


func validate() -> PackedStringArray:
	var warnings := PackedStringArray()
	if allowed_directions.is_empty():
		warnings.append("Movement requires at least one allowed direction.")
	return warnings
