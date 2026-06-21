class_name AttackComponent
extends EnemyComponent


func get_attack_cells(origin: Vector2i, facing: Vector2i) -> Array[Vector2i]:
	return actor.get_attack_cells(origin, facing) if actor != null else []


func get_locked_cells() -> Array[Vector2i]:
	return actor.locked_attack_cells.duplicate() if actor != null else []


func is_telegraphing() -> bool:
	return actor != null and actor.state == FreeEnemy.State.TELEGRAPH
