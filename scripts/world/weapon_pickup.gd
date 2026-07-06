class_name WeaponPickup
extends Node2D

signal collected(pickup: WeaponPickup, collector: Node)

var grid_world: GridWorld
var current_cell := Vector2i.ZERO
var weapon: EnemyWeapon
var visual_time := 0.0
@export var visual_path: NodePath = ^"Visual"

var visual: Node


func _ready() -> void:
	_resolve_visual()
	_sync_visual()


func setup(world: GridWorld, cell: Vector2i, item: EnemyWeapon) -> bool:
	grid_world = world
	current_cell = cell
	weapon = item
	if not grid_world.register_item(self, current_cell):
		return false
	position = grid_world.cell_to_world(current_cell)
	_sync_visual()
	return true


func take(collector: Node) -> EnemyWeapon:
	if weapon == null:
		return null
	var taken := weapon
	weapon = null
	grid_world.unregister_item(self)
	emit_signal("collected", self, collector)
	queue_free()
	return taken


func _exit_tree() -> void:
	if grid_world != null:
		grid_world.unregister_item(self)


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
