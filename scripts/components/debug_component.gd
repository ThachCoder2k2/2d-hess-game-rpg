class_name EnemyDebugComponent
extends EnemyComponent


func set_enabled(value: bool) -> void:
	if actor != null:
		actor.set_debug_enabled(value)


func is_enabled() -> bool:
	return actor != null and actor.debug_enabled
