class_name EnemyComponent
extends Node

var actor: FreeEnemy


func configure(host: FreeEnemy) -> void:
	actor = host
