class_name EncounterDirector
extends Node

signal token_changed(owner: Node)

var attack_owner: Node
var paused := false


func can_request_attack(enemy: Node) -> bool:
	return not paused and (attack_owner == null or not is_instance_valid(attack_owner) or attack_owner == enemy)


func request_attack(enemy: Node) -> bool:
	if not can_request_attack(enemy):
		return false
	attack_owner = enemy
	emit_signal("token_changed", attack_owner)
	return true


func release_attack(enemy: Node) -> void:
	if attack_owner == enemy:
		attack_owner = null
		emit_signal("token_changed", attack_owner)


func set_paused(value: bool) -> void:
	paused = value
	if paused and attack_owner != null:
		attack_owner = null
		emit_signal("token_changed", attack_owner)
