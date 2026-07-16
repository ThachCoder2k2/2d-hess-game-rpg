class_name AttackPattern
extends Resource

## Data-driven unarmed attack shape. Author new enemy attacks as .tres files:
## fill cell_offsets and choose whether they rotate with facing. No subclass needed.
##
## When uses_facing is true, each offset is read as (forward, right) relative to
## the enemy's facing, so the shape rotates as the enemy turns (e.g. a pawn's two
## forward diagonals). When uses_facing is false, each offset is an absolute board
## delta from the origin (e.g. a knight's fixed L-shape); set clip_to_board to drop
## offsets that fall outside the arena.

@export var id: StringName = &"attack"
@export var uses_facing := true
@export var cell_offsets: Array[Vector2i] = []
@export var clip_to_board := false
@export_range(1, 10) var damage := 1
@export_range(0.05, 3.0, 0.01) var telegraph_duration := 0.58
@export_range(0.05, 3.0, 0.01) var recovery_duration := 0.48
@export var requires_attack_token := true
@export var locks_facing := true


func get_attack_cells(world: GridWorld, origin: Vector2i, facing: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for offset in cell_offsets:
		var cell: Vector2i
		if uses_facing:
			var side := Vector2i(-facing.y, facing.x)
			cell = origin + facing * offset.x + side * offset.y
		else:
			cell = origin + offset
		if clip_to_board and world != null and not world.is_inside(cell):
			continue
		cells.append(cell)
	return cells
