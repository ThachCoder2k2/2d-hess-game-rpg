extends UnboundTest

## Every door of every room can be walked to, and every door leads somewhere that exists (found in the
## review of M3b: the west return doors of Stage 1 sat on column 0, which the shared tilemap paints as the
## wall of the room, so the pawn could go forward through every room and never back).
##
## For each zone of content/world/world.tres the room is booted the way the game boots it (EcsBoot: the
## painted tiles become walls and the markers bake themselves) and the check is made on that grid, not on
## the scene file:
##   - every entry marker stands on a cell the pawn can stand on, and not on a door (arriving on a door
##     would leave nothing to step onto);
##   - every exit marker is baked as a door, its cell can be walked on, and from every entry of the room a
##     walk over walkable cells reaches it (a flood fill by cardinal steps, which is how the pawn moves);
##   - the exit's target zone is in the graph and has an entry marker with exactly the entry id the exit
##     names (the shell falls back to the target's first entry for a name it does not find, which would hide a
##     typo, so this check does not);
##   - a door that stays shut until the room is cleared says why (its own locked_message): the status line
##     used to answer every shut door with the boss's line, which T3 and T4, rooms with no captain, said too.
## The rooms are 16x9 with a ring of wall; the doors of Stage 1 sit one cell inside the ring. The last part of
## the suite proves the check can fail: a door put back on the ring, a typo in an entry name and a wall across
## the room, and a shut door with no line, each produce a sentence.

const MINIMUM_ZONES := 34
const MINIMUM_EXITS := 69
const MINIMUM_ENTRIES := 60
const MINIMUM_SHUT_DOORS := 3

## The zone whose west door was on the ring before the fix: the case the check exists for.
const ZONE_WITH_RETURN_DOOR := &"t2_fallen_sword_tile"
const RETURN_DOOR_NAME := "Exit_To_T1"
## A door that is shut until its room is cleared (T3's east door): the case the locked-door check exists for.
const ZONE_WITH_SHUT_DOOR := &"t3_first_pawn_clash"
const SHUT_DOOR_NAME := "Exit_To_T4"
## The hub's district doors: Toybox, Bookshelf, Block Tower, Dollhouse, Under-Bed.
const MINIMUM_FLAG_DOORS := 5
## Cell (0, 5) of the 16x9 board: the wall column, where the return doors used to be.
const RING_CELL := Vector2i(0, 5)

var exits_checked := 0
var shut_doors_checked := 0
var flag_doors_checked := 0
var entries_checked := 0
var zones_checked := 0


func _init() -> void:
	suite_title = "ROOM DOORS REACHABLE TEST"
	var graph := ContentDb.world()
	if not _expect(graph != null and not graph.rooms.is_empty(), "the world graph loads and lists zones"):
		finish()
		return
	for zone_id: StringName in graph.room_ids():
		_check_zone(graph, zone_id)
	_expect(zones_checked >= MINIMUM_ZONES, "%d zones were booted and checked (at least %d, so an empty walk cannot pass)" % [zones_checked, MINIMUM_ZONES])
	_expect(exits_checked >= MINIMUM_EXITS, "%d doors were checked (at least %d)" % [exits_checked, MINIMUM_EXITS])
	_expect(entries_checked >= MINIMUM_ENTRIES, "%d entries were checked (at least %d)" % [entries_checked, MINIMUM_ENTRIES])
	_expect(shut_doors_checked >= MINIMUM_SHUT_DOORS, "%d doors that wait for a clear were checked (at least %d: T3, T4 and B1)" % [shut_doors_checked, MINIMUM_SHUT_DOORS])
	_expect(flag_doors_checked >= MINIMUM_FLAG_DOORS, "%d doors that wait for a boss's flag were checked (at least %d: the hub's five district doors)" % [flag_doors_checked, MINIMUM_FLAG_DOORS])
	_check_the_scan_can_fail(graph)
	finish()


func _check_zone(graph: WorldGraph, zone_id: StringName) -> void:
	var booted := _boot(graph.get_zone_scene(zone_id))
	var room: Node = booted["room"]
	var world: EcsWorld = booted["world"]
	var problems := _problems_in(graph, zone_id, room, world)
	for problem in problems:
		printerr("  %s: %s" % [zone_id, problem])
	_expect(problems.is_empty(), "%s: every entry stands on floor and every door can be walked to and leads to a real entry (%d problem(s))" % [zone_id, problems.size()])
	zones_checked += 1
	_free(booted)


## Boots the room on a fresh world, with no hero: the grid is what a played room has. `edit_room` (optional)
## changes the instanced scene before it boots, which is how the last part of the suite breaks a room on purpose.
func _boot(scene: PackedScene, edit_room := Callable()) -> Dictionary:
	var room := scene.instantiate()
	if edit_room.is_valid():
		edit_room.call(room)
	var world := EcsWorld.new()
	EcsBoot.boot(world, EcsBootOptions.for_scene(null, room))
	return {"room": room, "world": world}


func _free(booted: Dictionary) -> void:
	(booted["room"] as Node).free()
	(booted["world"] as Node).free()


## Everything wrong with the doors of one booted room, one sentence each.
func _problems_in(graph: WorldGraph, zone_id: StringName, room: Node, world: EcsWorld) -> PackedStringArray:
	var problems := PackedStringArray()
	var grid := world.grid
	var entry_cell_by_id: Dictionary = {}
	var exit_markers: Array[ZoneExitMarker] = []
	for child in room.get_children():
		if child is ZoneEntryMarker:
			var entry := child as ZoneEntryMarker
			entry_cell_by_id[entry.entry_id] = grid.world_to_cell(entry.position)
		elif child is ZoneExitMarker:
			exit_markers.append(child as ZoneExitMarker)
	if entry_cell_by_id.is_empty():
		problems.append("the room has no entry marker, so the pawn can never arrive in it")

	for entry_id: StringName in entry_cell_by_id:
		var entry_cell: Vector2i = entry_cell_by_id[entry_id]
		entries_checked += 1
		if not grid.is_walkable(entry_cell):
			problems.append("entry '%s' is on %s, a cell the pawn cannot stand on (%s)" % [entry_id, entry_cell, grid.kind_at(entry_cell)])
		elif grid.exit_by_cell.has(entry_cell):
			problems.append("entry '%s' is on %s, which is also a door: the pawn would arrive standing on it" % [entry_id, entry_cell])

	for exit_marker in exit_markers:
		exits_checked += 1
		var door_name := String(exit_marker.name)
		var door_cell := grid.world_to_cell(exit_marker.position)
		if not grid.exit_by_cell.has(door_cell):
			problems.append("door %s at %s was not baked into the grid" % [door_name, door_cell])
		if not grid.is_walkable(door_cell):
			problems.append("door %s at %s is on a cell the pawn cannot stand on (%s): it can never be used" % [door_name, door_cell, grid.kind_at(door_cell) if grid.is_inside(door_cell) else &"off the board"])
		else:
			for entry_id: StringName in entry_cell_by_id:
				if not _walkable_cells_reached_from(grid, entry_cell_by_id[entry_id]).has(door_cell):
					problems.append("door %s at %s cannot be reached on foot from entry '%s'" % [door_name, door_cell, entry_id])
		if exit_marker.ends_run:
			if exit_marker.target_zone != &"":
				problems.append("door %s ends the run, so it must lead to no zone (it names '%s')" % [door_name, exit_marker.target_zone])
		else:
			problems.append_array(_problems_with_target(graph, door_name, exit_marker))
		if exit_marker.requires_flag != &"":
			flag_doors_checked += 1
			if exit_marker.locked_message.strip_edges().is_empty():
				problems.append("door %s waits for the flag %s but gives no reason: its locked_message is empty" % [door_name, exit_marker.requires_flag])
		if exit_marker.requires_room_clear:
			shut_doors_checked += 1
			if exit_marker.locked_message.strip_edges().is_empty():
				problems.append("door %s stays shut until the room is cleared but gives no reason: its locked_message is empty" % door_name)
	return problems


## The target of one door: the zone is in the graph and has an entry marker of exactly that name.
func _problems_with_target(graph: WorldGraph, door_name: String, exit_marker: ZoneExitMarker) -> PackedStringArray:
	var problems := PackedStringArray()
	if not graph.has_zone(exit_marker.target_zone):
		problems.append("door %s leads to zone '%s', which is not in the world graph" % [door_name, exit_marker.target_zone])
		return problems
	var target_room := graph.get_zone_scene(exit_marker.target_zone).instantiate()
	var target_entry_ids: Array[StringName] = []
	for child in target_room.get_children():
		if child is ZoneEntryMarker:
			target_entry_ids.append((child as ZoneEntryMarker).entry_id)
	target_room.free()
	if exit_marker.target_entry not in target_entry_ids:
		problems.append("door %s leads to entry '%s' of zone '%s', which has only %s" % [door_name, exit_marker.target_entry, exit_marker.target_zone, target_entry_ids])
	return problems


## Every cell the pawn can reach on foot from `start`: cardinal steps over cells the grid says are walkable
## (walls, gaps and closed gates are not). Pieces do not count: they move.
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
			if not reached.has(next_cell) and grid.is_walkable(next_cell):
				reached[next_cell] = true
				frontier.append(next_cell)
	return reached


## The check is worth nothing if it cannot fail, so four broken rooms are built on purpose.
func _check_the_scan_can_fail(graph: WorldGraph) -> void:
	var scene := graph.get_zone_scene(ZONE_WITH_RETURN_DOOR)

	var on_the_wall_column := _boot(scene, func(room: Node) -> void:
		var door := room.get_node(RETURN_DOOR_NAME) as ZoneExitMarker
		var board_origin := EcsGrid.centred_origin(Vector2i(16, 9), 32, EcsBoot.project_view_size())
		door.position = board_origin + Vector2(RING_CELL * 32) + Vector2.ONE * 16.0)
	var ring_problems := _problems_in(graph, ZONE_WITH_RETURN_DOOR, on_the_wall_column["room"], on_the_wall_column["world"])
	_expect(_any_contains(ring_problems, "cannot stand on"), "the scan can fail: a door put back on the wall column is reported (%s)" % [ring_problems])
	_free(on_the_wall_column)

	var misspelt := _boot(scene, func(room: Node) -> void:
		(room.get_node(RETURN_DOOR_NAME) as ZoneExitMarker).target_entry = &"from_t_two")
	var typo_problems := _problems_in(graph, ZONE_WITH_RETURN_DOOR, misspelt["room"], misspelt["world"])
	_expect(_any_contains(typo_problems, "from_t_two"), "the scan can fail: an entry name that does not exist is reported, not quietly replaced by the first entry (%s)" % [typo_problems])
	_free(misspelt)

	var cut_in_two := _boot(scene)
	var cut_grid := (cut_in_two["world"] as EcsWorld).grid
	for row in [1, 4, 7]:
		cut_grid.add_block(Vector2i(7, row))
	var cut_problems := _problems_in(graph, ZONE_WITH_RETURN_DOOR, cut_in_two["room"], cut_in_two["world"])
	_expect(_any_contains(cut_problems, "cannot be reached on foot"), "the scan can fail: a wall across the room that cuts a door off from an entry is reported (%s)" % [cut_problems])
	_free(cut_in_two)

	var silent_door := _boot(graph.get_zone_scene(ZONE_WITH_SHUT_DOOR), func(room: Node) -> void:
		(room.get_node(SHUT_DOOR_NAME) as ZoneExitMarker).locked_message = "")
	var silent_problems := _problems_in(graph, ZONE_WITH_SHUT_DOOR, silent_door["room"], silent_door["world"])
	_expect(_any_contains(silent_problems, "gives no reason"), "the scan can fail: a door that waits for a clear and says nothing about why is reported (%s)" % [silent_problems])
	_free(silent_door)


func _any_contains(sentences: PackedStringArray, text: String) -> bool:
	for sentence in sentences:
		if sentence.contains(text):
			return true
	return false
