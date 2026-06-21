class_name EnemyContext
extends RefCounted

var self_cell := Vector2i.ZERO
var facing := Vector2i.DOWN
var hero_cell := Vector2i.ZERO
var legal_moves: Array[Vector2i] = []
var item_cells: Array[Vector2i] = []
var attack_available := false


static func capture(enemy: FreeEnemy) -> EnemyContext:
	var context := EnemyContext.new()
	context.self_cell = enemy.current_cell
	context.facing = enemy.facing
	context.hero_cell = enemy.target.current_cell
	if enemy.grid_world != null:
		var reserved := enemy.grid_world.get_reserved_cell(enemy.target)
		if reserved != enemy.target.current_cell:
			context.hero_cell = reserved
		context.legal_moves = enemy.get_cardinal_move_options()
		context.item_cells = enemy.grid_world.get_item_cells()
	context.attack_available = enemy.director == null or enemy.director.can_request_attack(enemy)
	return context
