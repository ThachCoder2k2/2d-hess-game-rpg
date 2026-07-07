class_name EnemyBrainComponent
extends EnemyComponent

## Optional per-enemy AI profile. Leave empty to use the shared
## EnemyDefinition.decision; assign one here to give this enemy its own tuning
## (scores, penalties, preferred distance, flank/axis bonuses) from the editor.
@export var decision: DecisionConfig
