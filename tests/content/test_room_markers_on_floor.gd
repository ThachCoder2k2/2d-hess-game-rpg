extends UnboundTest

## Everything an author parks on a board stands on ground the rules can use (found by an independent
## verifier of M3b: in T4 the Backstep Pawn and the Pencil Spear were both parked on (7,6), a cell of the
## shared tilemap's wall column. EcsGrid.register_entity refuses a wall cell and EcsBoot ignores the
## answer, so the pawn was counted as an enemy of the room, was never in the grid, could not be hit, never
## moved and struck anything beside it; the room could not be cleared, so its east door, which waits for a
## clear, never opened, and nobody could reach B1 or the hub. Nothing noticed, because the owner-guide test
## killed enemies with a damage request that needs no cell; the pawn had even "taken" the spear in the world
## dump, by standing on its cell).
##
## For each zone of content/world/world.tres the room is booted the way the game boots it (EcsBoot: the
## painted tiles become walls and the markers bake themselves) and the check is made on that grid, not on the
## scene file. Doors are closed as they are at boot: a closed gate is a wall, and a door cell is somewhere the
## pawn arrives, never somewhere it walks through (stepping on it leaves the room).
##   - every ENTRY stands on a cell the pawn can stand on, and no enemy is parked on it;
##   - every ENEMY (every parked ActorView with a definition) stands on a walkable cell, and the grid has it
##     there: entity_at(its cell) is that entity, so a second enemy parked on the same cell is found too, and
##     its cell can be walked to from every entry (a room is cleared by killing, and the sword needs a cell
##     beside the piece);
##   - every PICKUP (every PickupSpawnPoint that spawns a weapon) is on a walkable cell, the grid lists the
##     item there (a second item on one cell is silently dropped by EcsGrid.register_item), and the cell can
##     be walked to from every entry of the room;
##   - every UNLOCK marker (PlayerUnlockMarker, what a GrantMarker will be) is on a walkable cell that can be
##     walked to from every entry, and the grid baked it;
##   - every GATE stands on a cell the painted tiles leave as floor (a gate marker in a wall would turn the
##     wall into floor when it opened) and its approach cell, the one the pawn pushes in from, can be walked
##     to from every entry (a gate nobody can push is a gate that never opens).
## The last part of the suite proves the scan can fail: a pawn put on a wall, two pawns on one cell, a spear
## put on a wall, a spear walled in, a pawn walled in, the sword put on the ring of wall, an entry under a pawn, a gate in a
## wall and a gate nobody can push, each in a copy of a room that is right, produce a sentence, and the same
## kinds of marker put on floor produce none.

const MINIMUM_ZONES := 7
const MINIMUM_ENTRIES := 12
const MINIMUM_ENEMIES := 20
const MINIMUM_PICKUPS := 7
const MINIMUM_UNLOCKS := 1
const MINIMUM_GATES := 2

## The cell size and the board of a Stage 1 room, for placing a marker by cell in a copy of one.
const STAGE_ONE_BOARD := Vector2i(16, 9)
const CELL_SIZE := 32

var zones_checked := 0
var entries_checked := 0
var enemies_checked := 0
var pickups_checked := 0
var unlocks_checked := 0
var gates_checked := 0


func _init() -> void:
	suite_title = "ROOM MARKERS ON FLOOR TEST"
	var graph := ContentDb.world()
	if not _expect(graph != null and not graph.rooms.is_empty(), "the world graph loads and lists zones"):
		finish()
		return
	# The rooms of the graph and the 72x40 kingdom fixture (the only board with gates, which left the graph at M5).
	var scene_by_zone := TestPaths.new(self).shipped_rooms_and_kingdom()
	var zone_ids: Array = scene_by_zone.keys()
	zone_ids.sort()
	for zone_id: StringName in zone_ids:
		_check_zone(scene_by_zone[zone_id], zone_id)
	_expect(zones_checked >= MINIMUM_ZONES, "%d zones were booted and checked (at least %d, so an empty walk cannot pass)" % [zones_checked, MINIMUM_ZONES])
	_expect(entries_checked >= MINIMUM_ENTRIES, "%d entries were checked (at least %d)" % [entries_checked, MINIMUM_ENTRIES])
	_expect(enemies_checked >= MINIMUM_ENEMIES, "%d enemies were checked (at least %d)" % [enemies_checked, MINIMUM_ENEMIES])
	_expect(pickups_checked >= MINIMUM_PICKUPS, "%d pickups were checked (at least %d)" % [pickups_checked, MINIMUM_PICKUPS])
	_expect(unlocks_checked >= MINIMUM_UNLOCKS, "%d unlock markers were checked (at least %d)" % [unlocks_checked, MINIMUM_UNLOCKS])
	_expect(gates_checked >= MINIMUM_GATES, "%d gates were checked (at least %d)" % [gates_checked, MINIMUM_GATES])
	_check_the_scan_can_fail(graph)
	finish()


func _check_zone(scene: PackedScene, zone_id: StringName) -> void:
	var booted := _boot(scene)
	var problems := _problems_in(booted)
	for problem in problems:
		printerr("  %s: %s: %s" % [zone_id, problem["node"], problem["text"]])
	_expect(problems.is_empty(), "%s: every entry, enemy, pickup, unlock and gate stands on floor the pawn can use (%d problem(s))" % [zone_id, problems.size()])
	zones_checked += 1
	_free(booted)


## Boots the room on a fresh world, with no hero: the grid is what a played room has. `edit_room` (optional)
## changes the instanced scene before it boots, which is how the last part of the suite breaks a room on
## purpose. Returns the room, the booted world, the cast EcsBoot made, and `terrain`, a second world holding
## only the painted tiles (no gates, no markers), which is what a gate must be standing on.
func _boot(scene: PackedScene, edit_room := Callable()) -> Dictionary:
	var room := scene.instantiate()
	if edit_room.is_valid():
		edit_room.call(room)
	var terrain := EcsWorld.new()
	EcsBoot.shape_grid(terrain, room)
	EcsBoot.apply_tile_kinds(terrain, room)
	var world := EcsWorld.new()
	var cast := EcsBoot.boot(world, EcsBootOptions.for_scene(null, room))
	return {"room": room, "world": world, "cast": cast, "terrain": terrain}


func _free(booted: Dictionary) -> void:
	(booted["room"] as Node).free()
	(booted["world"] as Node).free()
	(booted["terrain"] as Node).free()


## Everything wrong with one booted room: [{"node": the name of the node at fault, "text": one sentence}].
func _problems_in(booted: Dictionary) -> Array[Dictionary]:
	var room: Node = booted["room"]
	var world: EcsWorld = booted["world"]
	var cast: Dictionary = booted["cast"]
	var terrain: EcsWorld = booted["terrain"]
	var grid := world.grid
	var problems: Array[Dictionary] = []

	var entry_cell_by_id: Dictionary = {}
	for child in room.get_children():
		if child is ZoneEntryMarker:
			entry_cell_by_id[(child as ZoneEntryMarker).entry_id] = grid.world_to_cell((child as ZoneEntryMarker).position)
	var reached_by_entry: Dictionary = {}
	for entry_id: StringName in entry_cell_by_id:
		reached_by_entry[entry_id] = _walkable_cells_reached_from(grid, entry_cell_by_id[entry_id])

	var enemy_cells: Dictionary = _check_enemies(room, world, cast, entry_cell_by_id, reached_by_entry, problems)
	_check_entries(room, grid, entry_cell_by_id, enemy_cells, problems)
	_check_pickups(room, world, cast, entry_cell_by_id, reached_by_entry, problems)
	_check_unlocks(room, grid, entry_cell_by_id, reached_by_entry, problems)
	_check_gates(room, grid, terrain.grid, entry_cell_by_id, reached_by_entry, problems)
	return problems


func _problem(problems: Array[Dictionary], node_name: Variant, text: String) -> void:
	problems.append({"node": String(node_name), "text": text})


## The enemies: each parked ActorView that EcsBoot made an enemy of. Returns the set of cells they were
## parked on (cell -> true), for the entry check.
func _check_enemies(room: Node, world: EcsWorld, cast: Dictionary, entry_cell_by_id: Dictionary, reached_by_entry: Dictionary, problems: Array[Dictionary]) -> Dictionary:
	var grid := world.grid
	var parked_cells: Dictionary = {}
	var parked_views := 0
	for child in room.get_children():
		var view := child as ActorView
		if view != null and view.definition != null:
			parked_views += 1
	var enemy_ids: Array = cast["enemies"]
	if enemy_ids.size() != parked_views:
		_problem(problems, room.name, "has %d parked enemies and the boot made %d of them" % [parked_views, enemy_ids.size()])
	for enemy_id: int in enemy_ids:
		enemies_checked += 1
		var view := cast["view_by_entity"][enemy_id] as Node2D
		var cell := grid.world_to_cell(view.position)
		parked_cells[cell] = true
		if not grid.is_inside(cell):
			_problem(problems, view.name, "is parked at %s, off the board" % [cell])
		elif not grid.is_walkable(cell):
			_problem(problems, view.name, "is parked at %s, a %s cell nothing can stand on: it is not in the grid, cannot be hit and cannot move" % [cell, grid.kind_at(cell)])
		elif grid.entity_at(cell) != enemy_id:
			_problem(problems, view.name, "is parked at %s, which entity %d already holds: it is not in the grid" % [cell, grid.entity_at(cell)])
		elif grid.cell_by_entity.get(enemy_id, EcsGrid.NO_CELL) != cell:
			_problem(problems, view.name, "is parked at %s and the grid places it at %s" % [cell, grid.cell_by_entity.get(enemy_id, EcsGrid.NO_CELL)])
		else:
			_check_reachable(String(view.name), "its cell", cell, grid, entry_cell_by_id, reached_by_entry, problems)
	return parked_cells


func _check_entries(room: Node, grid: EcsGrid, entry_cell_by_id: Dictionary, enemy_cells: Dictionary, problems: Array[Dictionary]) -> void:
	for child in room.get_children():
		var entry := child as ZoneEntryMarker
		if entry == null:
			continue
		entries_checked += 1
		var cell: Vector2i = entry_cell_by_id[entry.entry_id]
		if not grid.is_walkable(cell):
			_problem(problems, entry.name, "entry '%s' is on %s, a cell the pawn cannot stand on" % [entry.entry_id, cell])
		elif enemy_cells.has(cell):
			_problem(problems, entry.name, "entry '%s' is on %s, where an enemy is parked: the pawn would arrive on top of it" % [entry.entry_id, cell])


func _check_pickups(room: Node, world: EcsWorld, cast: Dictionary, entry_cell_by_id: Dictionary, reached_by_entry: Dictionary, problems: Array[Dictionary]) -> void:
	var grid := world.grid
	var item_id_by_name: Dictionary = {}
	for item_id: int in cast["pickup_name_by_entity"]:
		item_id_by_name[cast["pickup_name_by_entity"][item_id]] = item_id
	for child in room.get_children():
		var spawn_point := child as PickupSpawnPoint
		if spawn_point == null or not spawn_point.active:
			continue
		var node_name := String(spawn_point.name)
		if not item_id_by_name.has(node_name):
			_problem(problems, node_name, "is an active pickup spawn point that spawned nothing (it has no weapon)")
			continue
		pickups_checked += 1
		var item_id: int = item_id_by_name[node_name]
		var cell := spawn_point.grid_cell
		if not grid.is_inside(cell):
			_problem(problems, node_name, "is at %s, off the board" % [cell])
			continue
		if not grid.is_walkable(cell):
			_problem(problems, node_name, "is at %s, a %s cell: nothing can stand there to pick it up" % [cell, grid.kind_at(cell)])
		if grid.item_at(cell) != item_id:
			_problem(problems, node_name, "is at %s, where the grid lists item %d instead: this one is not on the floor" % [cell, grid.item_at(cell)])
		_check_reachable(node_name, "its cell", cell, grid, entry_cell_by_id, reached_by_entry, problems)


func _check_unlocks(room: Node, grid: EcsGrid, entry_cell_by_id: Dictionary, reached_by_entry: Dictionary, problems: Array[Dictionary]) -> void:
	for child in room.get_children():
		var marker := child as PlayerUnlockMarker
		if marker == null:
			continue
		unlocks_checked += 1
		var cell := grid.world_to_cell(marker.position)
		if not grid.player_unlock_by_cell.has(cell):
			_problem(problems, marker.name, "is at %s and the grid has no unlock baked there" % [cell])
		if not grid.is_walkable(cell):
			_problem(problems, marker.name, "is at %s, a cell the pawn cannot stand on: the unlock can never be taken" % [cell])
		_check_reachable(String(marker.name), "its cell", cell, grid, entry_cell_by_id, reached_by_entry, problems)


## A gate is a wall at boot (the pawn pushes it open from `opens_from`). Two things must hold: the tiles under
## it are floor, so that opening it does not cut a hole in a wall, and the cell the pawn pushes in from is a
## cell it can walk to with every gate closed.
func _check_gates(room: Node, grid: EcsGrid, terrain: EcsGrid, entry_cell_by_id: Dictionary, reached_by_entry: Dictionary, problems: Array[Dictionary]) -> void:
	for child in room.get_children():
		var gate := child as GateMarker
		if gate == null:
			continue
		gates_checked += 1
		var cell := grid.world_to_cell(gate.position)
		if not grid.gate_by_cell.has(cell):
			_problem(problems, gate.name, "gate '%s' at %s was not baked into the grid (it is off the board, or opened by the save)" % [gate.gate_id, cell])
		if not terrain.is_walkable(cell):
			_problem(problems, gate.name, "gate '%s' at %s stands in a %s cell of the painted tiles: opening it would turn a wall into floor" % [gate.gate_id, cell, terrain.kind_at(cell) if terrain.is_inside(cell) else &"off the board"])
		var approach_cell := cell - gate.opens_from
		if not grid.is_walkable(approach_cell):
			_problem(problems, gate.name, "gate '%s' opens from %s, a cell the pawn cannot stand on: nobody can push it" % [gate.gate_id, approach_cell])
		else:
			_check_reachable(String(gate.name), "the approach cell of gate '%s'" % gate.gate_id, approach_cell, grid, entry_cell_by_id, reached_by_entry, problems)


## `cell` is walkable (the caller says it is not when it is not) and is reached on foot from every entry.
func _check_reachable(node_name: String, what: String, cell: Vector2i, grid: EcsGrid, entry_cell_by_id: Dictionary, reached_by_entry: Dictionary, problems: Array[Dictionary]) -> void:
	if not grid.is_walkable(cell):
		return
	if entry_cell_by_id.is_empty():
		_problem(problems, node_name, "the room has no entry, so nothing in it can be reached")
		return
	for entry_id: StringName in entry_cell_by_id:
		if not (reached_by_entry[entry_id] as Dictionary).has(cell):
			_problem(problems, node_name, "%s %s cannot be reached on foot from entry '%s' (%s), with the gates closed" % [what, cell, entry_id, entry_cell_by_id[entry_id]])


## Every cell the pawn can reach on foot from `start`: cardinal steps over cells the grid says are walkable
## (walls, gaps and closed gates are not). Pieces do not count: they move. A door cell is reached but never
## walked through: stepping on it leaves the room.
func _walkable_cells_reached_from(grid: EcsGrid, start: Vector2i) -> Dictionary:
	var reached: Dictionary = {}
	if not grid.is_walkable(start):
		return reached
	var frontier: Array[Vector2i] = [start]
	reached[start] = true
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for step in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next_cell: Vector2i = cell + step
			if reached.has(next_cell) or not grid.is_walkable(next_cell):
				continue
			reached[next_cell] = true
			if not grid.exit_by_cell.has(next_cell):
				frontier.append(next_cell)
	return reached


## --- The scan has to be able to fail ------------------------------------------------------------------


func _check_the_scan_can_fail(graph: WorldGraph) -> void:
	var t3 := graph.get_zone_scene(&"t3_first_pawn_clash")
	var t4 := graph.get_zone_scene(&"t4_broken_rule_yard")
	var t2 := graph.get_zone_scene(&"t2_fallen_sword_tile")
	var wall_cell := Vector2i(7, 2)
	var ring_cell := Vector2i(0, 5)
	var floor_cell := Vector2i(3, 2)
	var floor_cell_far := Vector2i(5, 6)

	# Positive control first: the rooms as they are, with a gate that is right added to one, have no problem.
	var with_a_good_gate := _boot(t3, func(room: Node) -> void:
		_add_gate(room, floor_cell, Vector2i.LEFT))
	var good_problems := _problems_in(with_a_good_gate)
	_expect(good_problems.is_empty(), "the scan's control: T3 with a gate on floor, pushed in from a floor cell, has no problem (%s)" % [_describe(good_problems)])
	_free(with_a_good_gate)

	var pawn_in_a_wall := _boot(t3, func(room: Node) -> void:
		_place(room, "PawnRecruit", wall_cell))
	var wall_problems := _problems_in(pawn_in_a_wall)
	_expect(_any_about(wall_problems, "PawnRecruit", "nothing can stand on"), "the scan can fail: a pawn parked on a wall cell is reported (%s)" % [_describe(wall_problems)])
	_free(pawn_in_a_wall)

	var two_pawns := _boot(t4, func(room: Node) -> void:
		_place(room, "PawnRecruit", _cell_of(room, "ArmedPawn")))
	var shared_problems := _problems_in(two_pawns)
	_expect(_any_about(shared_problems, "PawnRecruit", "not in the grid") or _any_about(shared_problems, "ArmedPawn", "not in the grid"), "the scan can fail: two pawns parked on one cell are reported (%s)" % [_describe(shared_problems)])
	_free(two_pawns)

	var spear_in_a_wall := _boot(t4, func(room: Node) -> void:
		(room.get_node("PencilSpearPickup") as PickupSpawnPoint).grid_cell = wall_cell)
	var spear_problems := _problems_in(spear_in_a_wall)
	_expect(_any_about(spear_problems, "PencilSpearPickup", "nothing can stand there"), "the scan can fail: a spear on a wall cell is reported (%s)" % [_describe(spear_problems)])
	_free(spear_in_a_wall)

	var spear_walled_in := _boot(t4, func(room: Node) -> void:
		(room.get_node("PencilSpearPickup") as PickupSpawnPoint).grid_cell = floor_cell_far)
	var walled_grid := (spear_walled_in["world"] as EcsWorld).grid
	for step in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		walled_grid.add_block(floor_cell_far + step)
	var walled_problems := _problems_in(spear_walled_in)
	_expect(_any_about(walled_problems, "PencilSpearPickup", "cannot be reached on foot"), "the scan can fail: a spear walled in on all four sides is reported (%s)" % [_describe(walled_problems)])
	_free(spear_walled_in)

	var pawn_walled_in := _boot(t3)
	var pawn_walls_grid := (pawn_walled_in["world"] as EcsWorld).grid
	var walled_pawn_cell := _cell_of(pawn_walled_in["room"], "PawnRecruit")
	for step in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		pawn_walls_grid.add_block(walled_pawn_cell + step)
	var walled_pawn_problems := _problems_in(pawn_walled_in)
	_expect(_any_about(walled_pawn_problems, "PawnRecruit", "cannot be reached on foot"), "the scan can fail: a pawn walled in on all four sides is reported (%s)" % [_describe(walled_pawn_problems)])
	_free(pawn_walled_in)

	var sword_on_the_ring := _boot(t2, func(room: Node) -> void:
		_place(room, "FallenSwordUnlock", ring_cell))
	var sword_problems := _problems_in(sword_on_the_ring)
	_expect(_any_about(sword_problems, "FallenSwordUnlock", "cannot stand on"), "the scan can fail: the sword put on the ring of wall is reported (%s)" % [_describe(sword_problems)])
	_free(sword_on_the_ring)

	var entry_under_a_pawn := _boot(t3, func(room: Node) -> void:
		_place(room, "PawnRecruit", _cell_of(room, "Entry_West")))
	var entry_problems := _problems_in(entry_under_a_pawn)
	_expect(_any_about(entry_problems, "Entry_West", "where an enemy is parked"), "the scan can fail: an entry under a parked pawn is reported (%s)" % [_describe(entry_problems)])
	_free(entry_under_a_pawn)

	var gate_in_a_wall := _boot(t3, func(room: Node) -> void:
		_add_gate(room, wall_cell, Vector2i.LEFT))
	var buried_problems := _problems_in(gate_in_a_wall)
	_expect(_any_about(buried_problems, "TestGate", "turn a wall into floor"), "the scan can fail: a gate marker in a wall cell is reported (%s)" % [_describe(buried_problems)])
	_free(gate_in_a_wall)

	var gate_nobody_can_push := _boot(t3, func(room: Node) -> void:
		_add_gate(room, wall_cell + Vector2i.LEFT, Vector2i.LEFT))
	var unpushable_problems := _problems_in(gate_nobody_can_push)
	_expect(_any_about(unpushable_problems, "TestGate", "nobody can push it"), "the scan can fail: a gate whose approach cell is a wall is reported (%s)" % [_describe(unpushable_problems)])
	_free(gate_nobody_can_push)


## The problems as one line of text each, for a check's label.
func _describe(problems: Array[Dictionary]) -> String:
	var sentences: PackedStringArray = []
	for problem in problems:
		sentences.append("%s: %s" % [problem["node"], problem["text"]])
	return " | ".join(sentences)


func _any_about(problems: Array[Dictionary], node_name: String, text: String) -> bool:
	for problem in problems:
		if String(problem["node"]) == node_name and String(problem["text"]).contains(text):
			return true
	return false


## The world position of the middle of `cell` on a Stage 1 board (16x9, centred in the project's view).
func _position_of_cell(cell: Vector2i) -> Vector2:
	var board_origin := EcsGrid.centred_origin(STAGE_ONE_BOARD, CELL_SIZE, EcsBoot.project_view_size())
	return board_origin + Vector2(cell * CELL_SIZE) + Vector2.ONE * CELL_SIZE * 0.5


## The cell a node of a Stage 1 room is parked on.
func _cell_of(room: Node, node_name: String) -> Vector2i:
	var position: Vector2 = (room.get_node(node_name) as Node2D).position
	var board_origin := EcsGrid.centred_origin(STAGE_ONE_BOARD, CELL_SIZE, EcsBoot.project_view_size())
	return Vector2i(floor((position.x - board_origin.x) / CELL_SIZE), floor((position.y - board_origin.y) / CELL_SIZE))


## Parks a node of the room on `cell`. A PickupSpawnPoint places itself by grid_cell (and a GridMarker keeps
## its position in step), so those are moved through it.
func _place(room: Node, node_name: String, cell: Vector2i) -> void:
	var node := room.get_node(node_name) as Node2D
	if node is GridMarker:
		(node as GridMarker).grid_cell = cell
	node.position = _position_of_cell(cell)


func _add_gate(room: Node, cell: Vector2i, pushed_from_direction: Vector2i) -> void:
	var gate := GateMarker.new()
	gate.name = "TestGate"
	gate.gate_id = &"test_gate"
	gate.opens_from = pushed_from_direction
	gate.position = _position_of_cell(cell)
	room.add_child(gate)
