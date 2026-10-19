extends RefCounted

## The pathing and the attack-setup search exactly as they were before M3a made them cheap, kept as the
## yardstick the new code is measured against (a helper for tests, not a suite; no class_name: a suite
## preloads it with `const ReferencePathing := preload("res://tests/support/reference_pathing.gd")`).
##
## M3a changed HOW two answers are found and promised not to change WHAT they are:
##   - EcsGrid.get_grid_path builds one AStarGrid2D per layout instead of one per question;
##   - EnemyAISystem._find_attack_setup_goal looks at the cells an attack can reach the hero from instead of
##     at every cell of the board.
## ReferenceGrid and ReferenceEnemyAI are the old bodies, copied unchanged from the commit before. A test
## that gives a world a ReferenceGrid (`world.grid = ReferenceGrid.new()`) and swaps the EnemyAISystem for a
## ReferenceEnemyAI gets the old code running on the same world; if the two worlds ever disagree, M3a
## changed behaviour.


## The grid with the pathfinder built from scratch for every question: one AStarGrid2D, every wall, piece
## and reservation set solid, one search.
class ReferenceGrid extends EcsGrid:
	func get_grid_path(entity_id: int, origin: Vector2i, goal: Vector2i) -> Array[Vector2i]:
		if not is_inside(origin) or not is_inside(goal):
			return []
		var pathfinder := AStarGrid2D.new()
		pathfinder.region = bounds
		pathfinder.cell_size = Vector2.ONE
		pathfinder.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
		pathfinder.update()
		for cell: Vector2i in blocked_cells:
			pathfinder.set_point_solid(cell)
		for cell: Vector2i in entity_by_cell:
			if entity_by_cell[cell] != entity_id and cell != goal:
				pathfinder.set_point_solid(cell)
		for cell: Vector2i in move_reservations:
			if move_reservations[cell] != entity_id and cell != goal:
				pathfinder.set_point_solid(cell)
		var packed_path := pathfinder.get_id_path(origin, goal)
		var path: Array[Vector2i] = []
		for cell in packed_path:
			path.append(cell)
		return path


## The enemy brain with the attack-setup search over the whole board, cell by cell, row by row.
class ReferenceEnemyAI extends EnemyAISystem:
	## How many cells this search looked at (asked is_plannable_cell about), over its life.
	var cells_looked_at := 0

	func _find_attack_setup_goal(entity_id: int, ai: EcsComponents.EnemyAI, self_cell: Vector2i, hero_cell: Vector2i) -> Vector2i:
		var best_cell := hero_cell
		var best_distance := 999999
		var bounds := world.grid.bounds
		for y in range(bounds.position.y, bounds.end.y):
			for x in range(bounds.position.x, bounds.end.x):
				var candidate := Vector2i(x, y)
				cells_looked_at += 1
				if not world.grid.is_plannable_cell(entity_id, candidate):
					continue
				var can_attack_from_cell := false
				for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
					if hero_cell in _get_attack_cells(entity_id, ai, candidate, direction):
						can_attack_from_cell = true
						break
				if not can_attack_from_cell:
					continue
				var distance := world.grid.get_path_distance(entity_id, self_cell, candidate)
				if distance < best_distance:
					best_distance = distance
					best_cell = candidate
		return best_cell if best_distance < 999999 else hero_cell


## A world with every system of the schedule except the one that needs nodes (ViewSyncSystem), ticked by
## hand. With `reference` true it runs the code of before M3a: a ReferenceGrid, and a ReferenceEnemyAI in
## the place of the EnemyAISystem. Add it to the tree (`root.add_child`) before use if a system needs it.
static func make_world(reference: bool) -> EcsWorld:
	var world := EcsWorld.new()
	world.manual_tick = true
	if reference:
		world.grid = ReferenceGrid.new()
	for system in Schedule.build_systems():
		if system is ViewSyncSystem:
			continue
		if reference and system is EnemyAISystem:
			system = ReferenceEnemyAI.new()
		world.add_system(system)
	return world


## The EnemyAISystem of a world made by make_world.
static func enemy_ai_of(world: EcsWorld) -> EnemyAISystem:
	for system in world.systems:
		if system is EnemyAISystem:
			return system
	return null
