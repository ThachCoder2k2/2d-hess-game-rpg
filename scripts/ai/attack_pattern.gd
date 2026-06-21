class_name AttackPattern
extends Resource

@export var id: StringName = &"attack"
@export var uses_facing := true
@export_range(1, 10) var damage := 1
@export_range(0.05, 3.0, 0.01) var telegraph_duration := 0.58
@export_range(0.05, 3.0, 0.01) var recovery_duration := 0.48
@export var telegraph_style: StringName = &"cells"
@export var requires_attack_token := true
@export var locks_facing := true


func get_attack_cells(_world: GridWorld, _origin: Vector2i, _facing: Vector2i) -> Array[Vector2i]:
	return []
