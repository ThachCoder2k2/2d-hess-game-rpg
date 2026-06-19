class_name AttackProfile
extends Resource

@export var display_name := "Attack"
@export_range(1, 8) var range_cells := 1
@export_range(1, 10) var damage := 1
@export_range(0.01, 2.0) var impact_delay := 0.07
@export_range(0.01, 3.0) var recovery := 0.30
@export var color := Color("#fff2a8")


func get_target_cells(origin: Vector2i, facing: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for distance in range(1, range_cells + 1):
		cells.append(origin + facing * distance)
	return cells

