class_name DecisionConfig
extends Resource

@export_range(0.0, 2.0, 0.01) var observe_delay := 0.42
@export var attack_score := 100.0
@export var future_threat_score := 28.0
@export var distance_score := 10.0
@export var pickup_score := 60.0
@export var turn_threat_score := 44.0
@export var wait_score := 8.0
@export var repetition_penalty := 16.0
@export var recent_cell_penalty := 30.0
@export var path_step_bonus := 18.0
@export var role_policy: StringName = &"skirmisher"


func create_archetype(preferred_distance: int) -> EnemyArchetype:
	var result := EnemyArchetype.new()
	result.role = role_policy
	result.attack_score = attack_score
	result.future_threat_score = future_threat_score
	result.distance_score = distance_score
	result.pickup_score = pickup_score
	result.turn_threat_score = turn_threat_score
	result.wait_score = wait_score
	result.repetition_penalty = repetition_penalty
	result.preferred_distance = preferred_distance
	return result
