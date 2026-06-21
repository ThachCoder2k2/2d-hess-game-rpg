class_name EnemyArchetype
extends Resource

@export var role: StringName = &"skirmisher"
@export var attack_score := 100.0
@export var future_threat_score := 28.0
@export var distance_score := 10.0
@export var pickup_score := 60.0
@export var turn_threat_score := 44.0
@export var wait_score := 8.0
@export var repetition_penalty := 16.0
@export var preferred_distance := 2
