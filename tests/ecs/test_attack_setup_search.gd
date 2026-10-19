extends UnboundTest

## The bounded attack-setup search (docs/game-base-plan.md 5.11, risk 15, 15 M3a). To plan an attack an
## enemy looks for the cell it should walk to so that the hero stands in its attack shape. It used to look at
## every cell of the board; now it looks only at the cells within the shape's reach of the hero, because no
## other cell can have the hero in its shape. The promise is that this changes HOW MANY cells are looked at
## and never WHICH cell is chosen. This suite holds the promise three ways:
##   1. the reach is measured from the data of every enemy and weapon (a table, checked against the data);
##   2. for every enemy and weapon shape, on random boards with walls and pieces, the bounded search and the
##      old whole-board search (tests/support/reference_pathing.gd) choose the same cell, thousands of times;
##   3. whole runs: the same room ticked side by side with the old code (the whole-board search and a
##      pathfinder built per question) and the new, a synthetic arena of eight enemies, the six Stage 1 rooms
##      and the 72x40 kingdom, with a hero that keeps changing place, must agree on every entity, timer,
##      goal and event after every tick. The comparison is shown to be able to fail.

const ReferencePathing := preload("res://tests/support/reference_pathing.gd")

const TICK_SECONDS := 1.0 / 60.0
const CARDINAL_DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]


## A grid that counts the cells the attack-setup search asks about.
class CountingGrid extends EcsGrid:
	var plannable_questions := 0

	func is_plannable_cell(entity_id: int, cell: Vector2i) -> bool:
		plannable_questions += 1
		return super(entity_id, cell)


## An enemy whose search is one cell too narrow, to show that the whole-run comparison can fail.
class TooNarrowEnemyAI extends EnemyAISystem:
	func _attack_reach(entity_id: int, ai: EcsComponents.EnemyAI) -> int:
		return super(entity_id, ai) - 1


func _init() -> void:
	suite_title = "ATTACK SETUP SEARCH TEST"
	watchdog_seconds = 55.0
	_check_the_reach_of_every_shape()
	_check_the_search_looks_at_a_handful_of_cells()
	_check_the_same_cell_is_chosen()
	_check_whole_runs_are_unchanged()
	finish()


# --------------------------------------------------------------------------- the reach
func _enemy_definitions() -> Dictionary:
	var definitions: Dictionary = {}
	for enemy_id in ContentDb.ids(&"enemies"):
		definitions[enemy_id] = ContentDb.fetch(&"enemies", enemy_id) as EnemyDefinition
	return definitions


## Weapons an enemy may hold: the shipped ones and one of each shape and a few lengths, so a shape the
## shipped data does not use yet (a fan, a long line) is covered too.
func _weapons() -> Dictionary:
	var weapons: Dictionary = {
		&"pencil_spear": EnemyWeapon.pencil_spear(),
		&"ruler_blade": EnemyWeapon.ruler_blade(),
	}
	for line_length in [1, 3, 4]:
		var line := EnemyWeapon.new()
		line.shape = EnemyWeapon.Shape.LINE
		line.range_cells = line_length
		weapons[StringName("line_%d" % line_length)] = line
	var fan := EnemyWeapon.new()
	fan.shape = EnemyWeapon.Shape.FAN
	weapons[&"fan"] = fan
	return weapons


## What the data says an attack reaches, worked out here from the offsets and the range and not through the
## system's own measurement.
func _reach_from_data(definition: EnemyDefinition, weapon: EnemyWeapon) -> int:
	if weapon != null:
		match weapon.shape:
			EnemyWeapon.Shape.LINE:
				return weapon.range_cells
			EnemyWeapon.Shape.FAN:
				return 1
	var pattern := definition.unarmed_attack
	if pattern == null or pattern.cell_offsets.is_empty():
		return -1
	var reach := 0
	for offset in pattern.cell_offsets:
		reach = maxi(reach, maxi(absi(offset.x), absi(offset.y)))
	return reach


func _check_the_reach_of_every_shape() -> void:
	var world := ReferencePathing.make_world(false)
	var brain := ReferencePathing.enemy_ai_of(world)
	var definitions := _enemy_definitions()
	_expect(definitions.size() >= 6, "setup: the content lists at least six enemies (%d)" % definitions.size())
	var table: Array[String] = []
	var every_reach_matches := true
	for enemy_id: StringName in definitions:
		var definition: EnemyDefinition = definitions[enemy_id]
		var entity := EcsActorFactory.spawn_enemy(world, definition, Vector2i(5, 4))
		var ai: EcsComponents.EnemyAI = world.get_component(entity, EcsComponents.ENEMY_AI)
		var slot: EcsComponents.WeaponSlot = world.get_component(entity, EcsComponents.WEAPON_SLOT)
		slot.weapon = null
		var measured := brain._attack_reach(entity, ai)
		var expected := _reach_from_data(definition, null)
		table.append("%s %d" % [enemy_id, measured])
		if measured != expected:
			every_reach_matches = false
			printerr("  %s: measured %d, data says %d" % [enemy_id, measured, expected])
		var weapons := _weapons()
		for weapon_id: StringName in weapons:
			slot.weapon = weapons[weapon_id]
			var armed_measured := brain._attack_reach(entity, ai)
			var armed_expected := _reach_from_data(definition, weapons[weapon_id])
			if armed_measured != armed_expected:
				every_reach_matches = false
				printerr("  %s holding %s: measured %d, data says %d" % [enemy_id, weapon_id, armed_measured, armed_expected])
		world.grid.unregister_entity(entity)
	_expect(every_reach_matches, "the reach the system measures is the reach the data has, for every enemy unarmed and holding every weapon shape (%s)" % ", ".join(PackedStringArray(table)))
	var shapeless := EcsActorFactory.spawn_enemy(world, null, Vector2i(5, 4))
	_expect(brain._attack_reach(shapeless, world.get_component(shapeless, EcsComponents.ENEMY_AI)) == -1, "an enemy with no attack shape at all reaches nothing (-1), and then has no cell to attack from")
	world.free()


# --------------------------------------------------------------------------- a handful of cells
func _check_the_search_looks_at_a_handful_of_cells() -> void:
	var definitions := _enemy_definitions()
	var rows: Array[String] = []
	var never_more_than_the_box := true
	var big_board_stays_small := true
	for enemy_id: StringName in [&"pawn_recruit", &"knight_tracker", &"bishop_zoner"]:
		var counted := ReferencePathing.make_world(false)
		var counting_grid := CountingGrid.new()
		counted.grid = counting_grid
		counting_grid.bounds = Rect2i(0, 0, 72, 40)
		var brain := ReferencePathing.enemy_ai_of(counted)
		var entity := EcsActorFactory.spawn_enemy(counted, definitions[enemy_id], Vector2i(10, 10))
		var ai: EcsComponents.EnemyAI = counted.get_component(entity, EcsComponents.ENEMY_AI)
		var reach: int = brain._attack_reach(entity, ai)
		var box_cells := (reach * 2 + 1) * (reach * 2 + 1)
		counting_grid.plannable_questions = 0
		var goal: Vector2i = brain._find_attack_setup_goal(entity, ai, Vector2i(10, 10), Vector2i(40, 20))
		rows.append("%s reach %d: %d cells looked at (the box is %d, the board 2880)" % [enemy_id, reach, counting_grid.plannable_questions, box_cells])
		if counting_grid.plannable_questions > box_cells:
			never_more_than_the_box = false
		if counting_grid.plannable_questions >= 72 * 40 / 10:
			big_board_stays_small = false
		_expect(goal != Vector2i(40, 20), "setup: %s finds a cell to attack from, not the hero's own (%s)" % [enemy_id, goal])
		counted.free()
	_expect(never_more_than_the_box, "on the 72x40 world the search looks at no more cells than the box around the hero that the attack reaches: %s" % " | ".join(PackedStringArray(rows)))
	_expect(big_board_stays_small, "which is under a tenth of the 2880 cells of the board")

	var reference_world := ReferencePathing.make_world(true)
	reference_world.grid.bounds = Rect2i(0, 0, 72, 40)
	var reference_brain := ReferencePathing.enemy_ai_of(reference_world) as ReferencePathing.ReferenceEnemyAI
	var reference_entity := EcsActorFactory.spawn_enemy(reference_world, definitions[&"pawn_recruit"], Vector2i(10, 10))
	reference_brain._find_attack_setup_goal(reference_entity, reference_world.get_component(reference_entity, EcsComponents.ENEMY_AI), Vector2i(10, 10), Vector2i(40, 20))
	_expect(reference_brain.cells_looked_at == 2880, "(the old search looked at all 2880)")
	reference_world.free()


# --------------------------------------------------------------------------- the same cell
## Random boards (a fixed seed): walls, gaps, blocks, chalk, a few pieces; for each, an enemy of every kind,
## unarmed and holding each weapon, a random place for the enemy and the hero, a new and an old search from
## the same world state. The cell chosen must be the same, including the answer "none: go for the hero".
func _check_the_same_cell_is_chosen() -> void:
	var generator := RandomNumberGenerator.new()
	generator.seed = 20261019
	var definitions := _enemy_definitions()
	var weapons := _weapons()
	var variants: Array[Dictionary] = []
	for enemy_id: StringName in definitions:
		variants.append({"label": str(enemy_id), "definition": definitions[enemy_id], "weapon": null})
	for weapon_id: StringName in weapons:
		variants.append({"label": "pawn_recruit holding %s" % weapon_id, "definition": definitions[&"pawn_recruit"], "weapon": weapons[weapon_id]})
	var kinds: Array = CellKinds.RULES_BY_KIND.keys()
	var comparisons := 0
	var found_a_cell := 0
	var fell_back_to_the_hero := 0
	var differences := PackedStringArray()
	for board_index in range(10):
		var world := ReferencePathing.make_world(false)
		var board_widths: Array[int] = [16, 18, 12, 20]
		var board_heights: Array[int] = [9, 9, 7, 11]
		var columns: int = board_widths[board_index % 4]
		var rows: int = board_heights[board_index % 4]
		world.grid.bounds = Rect2i(0, 0, columns, rows)
		for _wall in range(generator.randi_range(0, columns * rows / 4)):
			world.grid.set_cell_kind(Vector2i(generator.randi_range(0, columns - 1), generator.randi_range(0, rows - 1)), kinds[generator.randi_range(0, kinds.size() - 1)])
		var new_brain := ReferencePathing.enemy_ai_of(world)
		var old_brain := ReferencePathing.ReferenceEnemyAI.new()
		old_brain.setup(world)
		for _piece in range(generator.randi_range(0, 4)):
			var piece_cell := Vector2i(generator.randi_range(0, columns - 1), generator.randi_range(0, rows - 1))
			var piece := EcsActorFactory.spawn_enemy(world, definitions[&"pawn_recruit"], piece_cell)
			if world.grid.cell_by_entity.get(piece, EcsGrid.NO_CELL) != piece_cell:
				world.destroy_entity(piece)
		for variant in variants:
			for _attempt in range(20):
				var self_cell := Vector2i(generator.randi_range(0, columns - 1), generator.randi_range(0, rows - 1))
				var hero_cell := Vector2i(generator.randi_range(0, columns - 1), generator.randi_range(0, rows - 1))
				if self_cell == hero_cell:
					continue
				var hero := world.create_entity()
				var enemy := EcsActorFactory.spawn_enemy(world, variant["definition"], self_cell)
				if not world.grid.register_entity(hero, hero_cell) or world.grid.cell_by_entity.get(enemy, EcsGrid.NO_CELL) != self_cell:
					world.destroy_entity(enemy)
					world.destroy_entity(hero)
					continue
				var ai: EcsComponents.EnemyAI = world.get_component(enemy, EcsComponents.ENEMY_AI)
				var slot: EcsComponents.WeaponSlot = world.get_component(enemy, EcsComponents.WEAPON_SLOT)
				slot.weapon = variant["weapon"]
				var new_goal: Vector2i = new_brain._find_attack_setup_goal(enemy, ai, self_cell, hero_cell)
				var old_goal: Vector2i = old_brain._find_attack_setup_goal(enemy, ai, self_cell, hero_cell)
				comparisons += 1
				if new_goal == hero_cell:
					fell_back_to_the_hero += 1
				else:
					found_a_cell += 1
				if new_goal != old_goal:
					differences.append("board %d, %s, self %s, hero %s: new %s, old %s" % [board_index, variant["label"], self_cell, hero_cell, new_goal, old_goal])
				world.destroy_entity(enemy)
				world.destroy_entity(hero)
		world.free()
	_expect(differences.is_empty(), "%d searches on 10 random boards, for every enemy unarmed and every weapon shape, choose the same cell as the whole-board search (%s)" % [comparisons, "; ".join(differences.slice(0, 3))])
	_expect(comparisons > 1500 and found_a_cell > 1000 and fell_back_to_the_hero >= 5, "setup: the comparison was not trivial: %d searches, %d found a cell to attack from and %d fell back to the hero's own cell" % [comparisons, found_a_cell, fell_back_to_the_hero])


# --------------------------------------------------------------------------- whole runs
func _check_whole_runs_are_unchanged() -> void:
	var total_ticks := 0
	var total_decisions := 0
	var total_searches := 0
	var arena := _replay_the_arena(1500)
	print("REPLAY: arena %d ticks, %d decisions, %d attack-setup searches" % [arena["ticks"], arena["decisions"], arena["searches"]])
	total_ticks += arena["ticks"]
	total_decisions += arena["decisions"]
	total_searches += arena["searches"]
	_expect(arena["first_difference"] == "", "an 18x9 arena with eight enemies and a hero that keeps changing place: the new code and the old agree on every entity, timer, goal and event after each of %d ticks (%s)" % [arena["ticks"], arena["first_difference"]])

	var terrain := _replay_the_arena(1200, false, true)
	print("REPLAY: arena with terrain %d ticks, %d decisions, %d attack-setup searches" % [terrain["ticks"], terrain["decisions"], terrain["searches"]])
	total_ticks += terrain["ticks"]
	total_decisions += terrain["decisions"]
	total_searches += terrain["searches"]
	_expect(terrain["first_difference"] == "", "the same arena strewn with walls, gaps, blocks and chalk, so paths bend and shapes are cut short: the new code and the old agree after each of %d ticks (%s)" % [terrain["ticks"], terrain["first_difference"]])

	var paths := TestPaths.new(self)
	var world_graph := ContentDb.world()
	var rooms_replayed := 0
	for zone_id: StringName in world_graph.zone_scene_by_id:
		var replay := _replay_a_room(world_graph.get_zone_scene(zone_id), paths, 600)
		print("REPLAY: room %s %d ticks, %d decisions, %d attack-setup searches" % [zone_id, replay["ticks"], replay["decisions"], replay["searches"]])
		total_ticks += replay["ticks"]
		total_decisions += replay["decisions"]
		total_searches += replay["searches"]
		rooms_replayed += 1
		_expect(replay["first_difference"] == "", "room %s: the new code and the old agree after each of %d ticks (%s)" % [zone_id, replay["ticks"], replay["first_difference"]])
	_expect(rooms_replayed >= 6, "setup: %d rooms were replayed (the six Stage 1 rooms and the kingdom fixture)" % rooms_replayed)
	_expect(total_decisions >= 400 and total_searches >= 300, "setup: the runs were not trivial: %d ticks, %d enemy decisions, %d attack-setup searches by the old code" % [total_ticks, total_decisions, total_searches])

	# The comparison can fail: an enemy whose search is one cell too narrow is found out in the arena.
	var narrow := _replay_the_arena(1500, true)
	_expect(narrow["first_difference"] != "", "an enemy whose search is one cell too narrow is caught by the same comparison: %s" % narrow["first_difference"])


## The arena of the room-tick budget: 18x9, eight enemies (every shipped kind), a hero with endless courage
## put on a new cell every 30 ticks. With `with_terrain` it is strewn with walls, gaps, blocks and chalk
## (a fixed pattern of 30 cells, none on a place a piece or the hero stands) so that paths bend and shapes
## are cut short.
func _replay_the_arena(tick_count: int, with_a_flawed_search := false, with_terrain := false) -> Dictionary:
	var roster: Array[Dictionary] = [
		{"id": &"pawn_recruit", "cell": Vector2i(2, 1)}, {"id": &"pawn_recruit", "cell": Vector2i(15, 1)},
		{"id": &"pawn_armed", "cell": Vector2i(2, 7)}, {"id": &"pawn_armed", "cell": Vector2i(15, 7)},
		{"id": &"knight_tracker", "cell": Vector2i(9, 1)}, {"id": &"knight_tracker", "cell": Vector2i(9, 7)},
		{"id": &"bishop_zoner", "cell": Vector2i(1, 4)}, {"id": &"charging_pawn", "cell": Vector2i(16, 4)},
	]
	var round_of_cells: Array[Vector2i] = [Vector2i(9, 4), Vector2i(5, 3), Vector2i(12, 5), Vector2i(8, 6), Vector2i(10, 2), Vector2i(4, 5)]
	var worlds: Array[EcsWorld] = []
	var heroes: Array[int] = []
	for reference in [false, true]:
		var world := ReferencePathing.make_world(reference)
		if with_a_flawed_search and not reference:
			var narrow_brain := TooNarrowEnemyAI.new()
			narrow_brain.setup(world)
			for index in range(world.systems.size()):
				if world.systems[index] is EnemyAISystem:
					world.systems[index] = narrow_brain
		world.grid.bounds = Rect2i(0, 0, 18, 9)
		if with_terrain:
			_strew_terrain(world.grid, roster, round_of_cells)
		root.add_child(world)
		var hero := EcsActorFactory.spawn_player_from_definition(world, ContentDb.player(), round_of_cells[0])
		var hero_health: EcsComponents.Health = world.get_component(hero, EcsComponents.HEALTH)
		hero_health.max_value = 100000
		hero_health.current = 100000
		for entry in roster:
			EcsActorFactory.spawn_enemy(world, ContentDb.fetch(&"enemies", entry["id"]) as EnemyDefinition, entry["cell"])
		worlds.append(world)
		heroes.append(hero)
	var result := _run_side_by_side(worlds, heroes, round_of_cells, tick_count)
	for world in worlds:
		world.queue_free()
	return result


## 30 cells of walls, gaps, blocks and chalk in a pattern fixed by a seed, never on a cell a piece starts on or
## the hero visits.
func _strew_terrain(grid: EcsGrid, roster: Array[Dictionary], hero_cells: Array[Vector2i]) -> void:
	var kept_clear: Dictionary = {}
	for entry in roster:
		kept_clear[entry["cell"]] = true
	for cell in hero_cells:
		kept_clear[cell] = true
	var generator := RandomNumberGenerator.new()
	generator.seed = 77
	var kinds: Array[StringName] = [CellKinds.WALL, CellKinds.WALL, CellKinds.GAP, CellKinds.LEAPABLE_BLOCK, CellKinds.CHALK]
	var placed := 0
	while placed < 30:
		var cell := Vector2i(generator.randi_range(0, 17), generator.randi_range(0, 8))
		if kept_clear.has(cell) or grid.kind_at(cell) != CellKinds.FLOOR:
			continue
		grid.set_cell_kind(cell, kinds[generator.randi_range(0, kinds.size() - 1)])
		placed += 1


## A room scene as the game boots it (EcsBoot, a hero where the entry marker is), twice, one world on the
## new code and one on the old.
func _replay_a_room(room_scene: PackedScene, paths: TestPaths, tick_count: int) -> Dictionary:
	var player_scene := paths.load_scene(paths.actor_scene(&"player"))
	var worlds: Array[EcsWorld] = []
	var heroes: Array[int] = []
	var rooms: Array[Node] = []
	var round_of_cells: Array[Vector2i] = []
	for reference in [false, true]:
		var world := ReferencePathing.make_world(reference)
		root.add_child(world)
		var room := room_scene.instantiate()
		root.add_child(room)
		EcsBoot.shape_grid(world, room)
		var hero_view := player_scene.instantiate() as ActorView
		hero_view.position = world.grid.cell_to_world(Vector2i(2, 2))
		root.add_child(hero_view)
		var cast := EcsBoot.boot(world, EcsBootOptions.for_scene(hero_view, room))
		var hero: int = cast["player"]
		var hero_health: EcsComponents.Health = world.get_component(hero, EcsComponents.HEALTH)
		hero_health.max_value = 100000
		hero_health.current = 100000
		if round_of_cells.is_empty():
			round_of_cells = _cells_to_visit(world, cast["enemies"])
		worlds.append(world)
		heroes.append(hero)
		rooms.append(room)
		rooms.append(hero_view)
	var result := _run_side_by_side(worlds, heroes, round_of_cells, tick_count)
	for node in rooms:
		node.queue_free()
	for world in worlds:
		world.queue_free()
	return result


## Cells for the hero to be put on, one after the other: for each enemy a free cell three steps away from it
## (else the nearest free cell), so every enemy wakes, chases and attacks in turn.
func _cells_to_visit(world: EcsWorld, enemies: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for enemy in enemies:
		var enemy_cell: Vector2i = world.grid.cell_by_entity.get(enemy, EcsGrid.NO_CELL)
		var best := Vector2i.ZERO
		var best_gap := 99
		for dy in range(-4, 5):
			for dx in range(-4, 5):
				var cell := enemy_cell + Vector2i(dx, dy)
				if cell == enemy_cell or not world.grid.is_plannable_cell(0, cell):
					continue
				var gap := absi(absi(dx) + absi(dy) - 3)
				if gap < best_gap:
					best_gap = gap
					best = cell
		if best_gap < 99:
			cells.append(best)
	if cells.is_empty():
		cells.append(Vector2i(2, 2))
	return cells


## Ticks the worlds in step (worlds[0] runs the new code, worlds[1] the old). Every 30 ticks the hero is put
## on the next cell of the round in both. After every tick the full state of both is written as text and
## compared; returns { "ticks", "decisions", "searches", "first_difference" }.
func _run_side_by_side(worlds: Array[EcsWorld], heroes: Array[int], round_of_cells: Array[Vector2i], tick_count: int) -> Dictionary:
	var first_difference := ""
	var decisions := 0
	var ticks_run := 0
	var round_index := 0
	for tick_index in range(tick_count):
		if tick_index % 30 == 0:
			for which in range(2):
				_put_hero_on(worlds[which], heroes[which], round_of_cells[round_index % round_of_cells.size()])
			round_index += 1
		var digests: Array[String] = []
		for which in range(2):
			worlds[which].tick(TICK_SECONDS)
			var events := worlds[which].drain_events()
			if which == 0:
				for event in events:
					if event["type"] == Events.INTENT_CHANGED:
						decisions += 1
			digests.append(_digest(worlds[which], events))
		ticks_run += 1
		if digests[0] != digests[1]:
			first_difference = "tick %d: %s" % [tick_index, _first_line_that_differs(digests[0], digests[1])]
			break
	var old_brain := ReferencePathing.enemy_ai_of(worlds[1]) as ReferencePathing.ReferenceEnemyAI
	return {
		"ticks": ticks_run,
		"decisions": decisions,
		"searches": old_brain.cells_looked_at / maxi(1, worlds[1].grid.bounds.size.x * worlds[1].grid.bounds.size.y),
		"first_difference": first_difference,
	}


func _put_hero_on(world: EcsWorld, hero: int, cell: Vector2i) -> void:
	var hero_position: EcsComponents.GridPos = world.get_component(hero, EcsComponents.GRID_POS)
	var hero_move: EcsComponents.MoveState = world.get_component(hero, EcsComponents.MOVE_STATE)
	if hero_move.moving or not world.grid.is_plannable_cell(hero, cell):
		return
	world.grid.unregister_entity(hero)
	hero_position.cell = cell
	world.grid.register_entity(hero, cell)


## Everything the enemies decided and the world did this tick, as text: where every entity stands and
## faces, its timers, its goal, its memory, its health, the attack token, and every event with its payload.
func _digest(world: EcsWorld, events: Array[Dictionary]) -> String:
	var lines := PackedStringArray()
	var entity_ids: Array = world.query([EcsComponents.GRID_POS])
	entity_ids.sort()
	for entity_id: int in entity_ids:
		var grid_pos: EcsComponents.GridPos = world.get_component(entity_id, EcsComponents.GRID_POS)
		var facing: EcsComponents.Facing = world.get_component(entity_id, EcsComponents.FACING)
		var move: EcsComponents.MoveState = world.get_component(entity_id, EcsComponents.MOVE_STATE)
		var health: EcsComponents.Health = world.get_component(entity_id, EcsComponents.HEALTH)
		var line := "e%d cell=%s grid=%s facing=%s hp=%d" % [
			entity_id, grid_pos.cell, world.grid.cell_by_entity.get(entity_id, EcsGrid.NO_CELL), facing.direction if facing != null else "-",
			health.current if health != null else -1]
		if move != null:
			line += " moving=%s %s->%s p=%.4f" % [move.moving, move.from_cell, move.to_cell, move.progress]
		var ai: EcsComponents.EnemyAI = world.get_component(entity_id, EcsComponents.ENEMY_AI)
		if ai != null:
			line += " ai=%s t=%.4f goal=%s/%s left=%d snap=%s locked=%s recent=%s memory=%s tdur=%.3f" % [
				ai.state, ai.state_time_left, ai.committed_goal, ai.committed_goal_kind, ai.goal_decisions_left,
				ai.committed_target_snapshot, ai.locked_attack_cells, ai.recent_cells, ai.action_memory, ai.telegraph_duration]
		lines.append(line)
	lines.append("token=%d reservations=%s" % [world.attack_token_owner, world.grid.move_reservations])
	for event in events:
		var parts := PackedStringArray()
		var keys: Array = event.keys()
		keys.sort()
		for key in keys:
			var value: Variant = event[key]
			if value is EnemyIntent:
				value = "intent %s %s %s %.3f %s" % [value.action_id, value.destination, value.direction, value.score, value.target_cells]
			elif value is Object:
				value = "object"
			parts.append("%s=%s" % [key, value])
		lines.append("event " + " ".join(parts))
	return "\n".join(lines)


func _first_line_that_differs(first: String, second: String) -> String:
	var first_lines := first.split("\n")
	var second_lines := second.split("\n")
	for index in range(mini(first_lines.size(), second_lines.size())):
		if first_lines[index] != second_lines[index]:
			return "new: %s | old: %s" % [first_lines[index], second_lines[index]]
	return "different numbers of lines (%d against %d)" % [first_lines.size(), second_lines.size()]
