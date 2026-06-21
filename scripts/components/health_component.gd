class_name HealthComponent
extends EnemyComponent


func get_health() -> int:
	return actor.health if actor != null else 0


func get_max_health() -> int:
	if actor != null and actor.definition != null:
		return actor.definition.max_health
	return get_health()


func apply_damage(amount: int, direction := Vector2i.ZERO) -> void:
	if actor != null:
		actor.take_damage(amount, direction)
