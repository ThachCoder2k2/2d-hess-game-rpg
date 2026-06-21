class_name KnightPattern
extends AttackPattern

const OFFSETS: Array[Vector2i] = [
	Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(2, -1), Vector2i(2, 1),
	Vector2i(-1, -2), Vector2i(1, -2), Vector2i(-1, 2), Vector2i(1, 2),
]


func _init() -> void:
	uses_facing = false


func get_attack_cells(world: GridWorld, origin: Vector2i, _facing: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for offset in OFFSETS:
		var cell := origin + offset
		if world == null or world.is_inside(cell):
			cells.append(cell)
	return cells
