class_name PawnPattern
extends AttackPattern


func _init() -> void:
	uses_facing = true


func get_attack_cells(_world: GridWorld, origin: Vector2i, facing: Vector2i) -> Array[Vector2i]:
	var side := Vector2i(-facing.y, facing.x)
	return [origin + facing + side, origin + facing - side]
