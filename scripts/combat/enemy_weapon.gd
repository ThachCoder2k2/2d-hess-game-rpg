class_name EnemyWeapon
extends Resource

enum Shape { LINE, FAN }

@export var display_name := "Toy Weapon"
@export var shape := Shape.LINE
@export_range(1, 4) var range_cells := 1
@export_range(1, 5) var damage := 1
@export_range(0.1, 2.0) var telegraph_time := 0.55
@export_range(0.1, 2.0) var recovery_time := 0.55
@export var color := Color("#8ec8e8")


func get_attack_cells(origin: Vector2i, facing: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	match shape:
		Shape.LINE:
			for distance in range(1, range_cells + 1):
				cells.append(origin + facing * distance)
		Shape.FAN:
			var side := Vector2i(-facing.y, facing.x)
			cells.append(origin + facing)
			cells.append(origin + facing + side)
			cells.append(origin + facing - side)
	return cells


static func pencil_spear() -> EnemyWeapon:
	var weapon := EnemyWeapon.new()
	weapon.display_name = "Pencil Spear"
	weapon.shape = Shape.LINE
	weapon.range_cells = 2
	weapon.telegraph_time = 0.62
	weapon.recovery_time = 0.68
	weapon.color = Color("#8ec8e8")
	return weapon


static func ruler_blade() -> EnemyWeapon:
	var weapon := EnemyWeapon.new()
	weapon.display_name = "Ruler Blade"
	weapon.shape = Shape.FAN
	weapon.range_cells = 1
	weapon.telegraph_time = 0.56
	weapon.recovery_time = 0.62
	weapon.color = Color("#e8b83f")
	return weapon
