class_name WeaponPickup
extends Node2D

## A floor-weapon VIEW. The pickup itself is an entity (PickupItem component,
## spawned by EcsBoot); this node only shows the floating sprite and frees when
## the bridge hears pickup_taken. No grid registration — the EnemyAISystem
## collects the entity, never this node.

@export var visual_path: NodePath = ^"Visual"

var weapon: EnemyWeapon
var visual_time := 0.0
var visual: Node


func _ready() -> void:
	_resolve_visual()
	_sync_visual()


func _process(delta: float) -> void:
	visual_time += delta
	_sync_visual()


func _resolve_visual() -> void:
	if visual == null:
		visual = get_node_or_null(visual_path)


func _sync_visual() -> void:
	_resolve_visual()
	if visual != null and visual.has_method("sync_from_pickup"):
		visual.call("sync_from_pickup", self)
