class_name EnemyWeapon
extends Resource

enum Shape { LINE, FAN }

@export var id: StringName = &"toy_weapon"
@export var display_name := "Toy Weapon"
@export var tags: Array[StringName] = []
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
	return (load("res://resources/weapons/pencil_spear.tres") as EnemyWeapon).duplicate(true)


static func ruler_blade() -> EnemyWeapon:
	return (load("res://resources/weapons/ruler_blade.tres") as EnemyWeapon).duplicate(true)
