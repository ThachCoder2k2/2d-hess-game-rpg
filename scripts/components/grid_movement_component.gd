class_name GridMovementComponent
extends EnemyComponent


func get_current_cell() -> Vector2i:
	return actor.current_cell if actor != null else Vector2i.ZERO


func get_facing() -> Vector2i:
	return actor.facing if actor != null else Vector2i.DOWN


func get_legal_moves() -> Array[Vector2i]:
	return actor.get_cardinal_move_options() if actor != null else []


func request_step(direction: Vector2i) -> bool:
	return actor != null and actor.try_step(direction)
