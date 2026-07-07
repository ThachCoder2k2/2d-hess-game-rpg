class_name EnemyBrainComponent
extends EnemyComponent

## Optional per-enemy AI profile. Leave empty to use the shared
## EnemyDefinition.decision; assign one here to give this enemy its own tuning
## (scores, penalties, preferred distance, flank/axis bonuses) from the editor.
@export var decision: DecisionConfig


func get_state() -> FreeEnemy.State:
	return actor.state if actor != null else FreeEnemy.State.OBSERVE


func get_current_intent() -> EnemyIntent:
	return actor.current_intent if actor != null else null


func request_decision() -> void:
	if actor != null and actor.target != null:
		actor._choose_action()
