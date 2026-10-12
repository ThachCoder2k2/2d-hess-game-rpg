class_name DifficultyProfile
extends Resource

@export var id: StringName = &"standard"
@export_range(0.25, 2.0, 0.05) var observe_time_multiplier := 1.0
@export_range(0.25, 2.0, 0.05) var telegraph_time_multiplier := 1.0
@export_range(0.25, 2.0, 0.05) var recovery_time_multiplier := 1.0
@export_range(0.25, 2.0, 0.05) var movement_time_multiplier := 1.0
