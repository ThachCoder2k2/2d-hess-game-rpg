class_name DifficultyProfile
extends Resource

@export var id: StringName = &"standard"
@export_range(0.25, 2.0, 0.05) var observe_time_multiplier := 1.0
@export_range(0.25, 2.0, 0.05) var telegraph_time_multiplier := 1.0
@export_range(0.25, 2.0, 0.05) var recovery_time_multiplier := 1.0
@export_range(0.25, 2.0, 0.05) var movement_time_multiplier := 1.0


## Problems that would make this profile freeze or break timings, as readable sentences (empty = fine).
func validate() -> PackedStringArray:
	var warnings := PackedStringArray()
	if id.is_empty():
		warnings.append("Difficulty profile requires an id.")
	if observe_time_multiplier <= 0.0 or telegraph_time_multiplier <= 0.0 \
			or recovery_time_multiplier <= 0.0 or movement_time_multiplier <= 0.0:
		warnings.append("Difficulty profile '%s' needs every time multiplier above 0." % id)
	return warnings
