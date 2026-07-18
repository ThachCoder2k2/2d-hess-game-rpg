class_name PlayerComponent
extends Node

## The hosting player actor. Set by PawnHero via configure(); components never
## reach up the tree themselves (same dependency-injection rule as EnemyComponent).
var player: PawnHero


func configure(host: PawnHero) -> void:
	player = host
