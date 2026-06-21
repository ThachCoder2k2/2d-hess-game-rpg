class_name EnemyBrainComponent
extends EnemyComponent


func get_state() -> FreeEnemy.State:
	return actor.state if actor != null else FreeEnemy.State.OBSERVE


func get_current_intent() -> EnemyIntent:
	return actor.current_intent if actor != null else null


func request_decision() -> void:
	if actor != null and actor.target != null:
		actor._choose_action()
