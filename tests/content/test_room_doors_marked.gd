extends UnboundTest

## Every door of every room is DRAWN (M5 review, major: door cells were plain floor in all 34 rooms, so the guide could
## not say where the way on was and the player could only find a shut door by stepping on it). The board overlay draws
## one mark per door brief of the HudSnapshot; this suite boots each room of content/world/world.tres the way the game
## does and checks, on the booted grid and the real overlay:
##   - the snapshot has exactly one brief at every door cell of the grid, no more and no less;
##   - the brief says the door is shut exactly when its marker asks for something the world does not have yet (a
##     clear while a piece stands, a boss's flag while the flag is unset), and open for every other door;
##   - the overlay's draw ran over those briefs, one mark per door, without a script error;
##   - the shut state follows the world: the room's last piece falls and the clear doors open; the flag is set and the
##     flag doors open.
## And that it can fail: a door the snapshot does not brief, and a brief that says open for a door that is shut.

const MINIMUM_ROOMS := 34
const MINIMUM_DOORS := 69
const MINIMUM_SHUT_AT_THE_START := 14

var rooms_checked := 0
var doors_checked := 0
var doors_shut_at_the_start := 0
var clear_doors_opened := 0
var flag_doors_opened := 0


func _init() -> void:
	suite_title = "ROOM DOORS MARKED TEST"
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var graph := ContentDb.world()
	if not _expect(graph != null and not graph.rooms.is_empty(), "the world graph loads and lists zones"):
		finish()
		return
	for zone_id: StringName in graph.room_ids():
		await _check_zone(graph, zone_id)
	_expect(rooms_checked >= MINIMUM_ROOMS, "%d rooms were booted and checked (at least %d)" % [rooms_checked, MINIMUM_ROOMS])
	_expect(doors_checked >= MINIMUM_DOORS, "%d doors were marked (at least %d, every door of the world)" % [doors_checked, MINIMUM_DOORS])
	_expect(doors_shut_at_the_start >= MINIMUM_SHUT_AT_THE_START, "%d doors start shut (at least %d: the clear doors of the fights and the hub's five district doors)" % [doors_shut_at_the_start, MINIMUM_SHUT_AT_THE_START])
	_expect(clear_doors_opened >= 9 and flag_doors_opened >= 5, "the clear doors (%d) and the hub's flag doors (%d) were seen to open" % [clear_doors_opened, flag_doors_opened])
	await _check_the_check_can_fail(graph)
	finish()


func _check_zone(graph: WorldGraph, zone_id: StringName) -> void:
	var room := graph.get_zone_scene(zone_id).instantiate()
	var world := EcsWorld.new()
	EcsBoot.boot(world, EcsBootOptions.for_scene(null, room))
	HudSnapshotSystem.build(world)
	var briefs := world.hud_snapshot.door_brief_by_cell
	var door_by_cell: Dictionary = world.grid.exit_by_cell
	var problems := _problems_in(world, door_by_cell, briefs)

	# The overlay draws a mark for each brief.
	var board := PrototypeBoard.new()
	root.add_child(board)
	board.setup(world.grid, world.hud_snapshot)
	await process_frame
	await process_frame
	if board.drawn_door_shut_by_cell.size() != door_by_cell.size():
		problems.append("the board drew %d door mark(s) for %d door(s)" % [board.drawn_door_shut_by_cell.size(), door_by_cell.size()])

	# The shut state follows the world.
	var clear_doors_here := 0
	var flag_doors_here := 0
	for cell: Vector2i in door_by_cell:
		var door: Dictionary = door_by_cell[cell]
		clear_doors_here += 1 if bool(door.get("requires_room_clear", false)) else 0
		flag_doors_here += 1 if StringName(door.get("requires_flag", &"")) != &"" else 0
	_let_the_room_be_cleared(world)
	_set_every_door_flag(world, door_by_cell)
	HudSnapshotSystem.build(world)
	for cell: Vector2i in door_by_cell:
		if briefs[cell].is_shut:
			problems.append("%s: the door is still drawn shut with every piece fallen and every flag set" % cell)
	clear_doors_opened += clear_doors_here
	flag_doors_opened += flag_doors_here

	for problem in problems:
		printerr("  %s: %s" % [zone_id, problem])
	_expect(problems.is_empty(), "%s: all %d door(s) are marked, shut or open as their marker asks, and open once the room is cleared and the flags set (%d problem(s))" % [zone_id, door_by_cell.size(), problems.size()])
	rooms_checked += 1
	doors_checked += door_by_cell.size()
	board.queue_free()
	room.free()
	world.free()


## What is wrong with the briefs of a booted room: a missing or an extra brief, and a shut state that is not the marker's ask.
func _problems_in(world: EcsWorld, door_by_cell: Dictionary, briefs: Dictionary) -> Array[String]:
	var problems: Array[String] = []
	for cell: Vector2i in door_by_cell:
		if not briefs.has(cell):
			problems.append("%s: a door the snapshot does not brief, so the board draws nothing there" % cell)
			continue
		var door: Dictionary = door_by_cell[cell]
		var required_flag := StringName(door.get("requires_flag", &""))
		var asks_for_a_clear: bool = bool(door.get("requires_room_clear", false)) and not DoorRules.room_is_clear(world)
		var asks_for_a_flag: bool = required_flag != &"" and not bool(world.flags.get_flag(required_flag, false))
		var should_be_shut: bool = asks_for_a_clear or asks_for_a_flag
		if briefs[cell].is_shut != should_be_shut:
			problems.append("%s: the brief says %s but the door asks for %s" % [cell, "shut" if briefs[cell].is_shut else "open", "something the world has not got" if should_be_shut else "nothing"])
		if briefs[cell].ends_run != bool(door.get("ends_run", false)):
			problems.append("%s: the brief's ends_run is wrong" % cell)
		doors_shut_at_the_start += 1 if briefs[cell].is_shut else 0
	for cell: Vector2i in briefs:
		if not door_by_cell.has(cell):
			problems.append("%s: a brief for a cell that is no door" % cell)
	return problems


func _let_the_room_be_cleared(world: EcsWorld) -> void:
	for enemy_id in world.query([EcsComponents.ENEMY_AI]):
		var ai: EcsComponents.EnemyAI = world.get_component(enemy_id, EcsComponents.ENEMY_AI)
		ai.state = EcsComponents.EnemyAI.STATE_DEFEATED


func _set_every_door_flag(world: EcsWorld, door_by_cell: Dictionary) -> void:
	for cell: Vector2i in door_by_cell:
		var required_flag := StringName(door_by_cell[cell].get("requires_flag", &""))
		if required_flag != &"":
			world.flags.set_flag(required_flag, true)


## The checks name a door that is not marked and a door marked open that is shut.
func _check_the_check_can_fail(graph: WorldGraph) -> void:
	var room := graph.get_zone_scene(&"t3_first_pawn_clash").instantiate()
	var world := EcsWorld.new()
	EcsBoot.boot(world, EcsBootOptions.for_scene(null, room))
	HudSnapshotSystem.build(world)
	var briefs := world.hud_snapshot.door_brief_by_cell
	var door_by_cell: Dictionary = world.grid.exit_by_cell
	_expect(_problems_in(world, door_by_cell, briefs).is_empty(), "setup: T3, booted, is marked cleanly")
	var shut_cell: Vector2i = door_by_cell.keys()[0]
	for cell: Vector2i in door_by_cell:
		if briefs[cell].is_shut:
			shut_cell = cell
	var removed: HudSnapshot.DoorBrief = briefs[shut_cell]
	briefs.erase(shut_cell)
	_expect(not _problems_in(world, door_by_cell, briefs).is_empty(), "a door with no brief is named")
	removed.is_shut = false
	briefs[shut_cell] = removed
	_expect(removed.is_shut == false and DoorRules.is_shut(world, door_by_cell[shut_cell]), "setup: T3's east door is shut while the pieces stand")
	_expect(not _problems_in(world, door_by_cell, briefs).is_empty(), "a shut door marked open is named")
	briefs[Vector2i(7, 7)] = HudSnapshot.DoorBrief.new()
	_expect(not _problems_in(world, door_by_cell, briefs).is_empty(), "a brief for a cell that is no door is named")
	room.free()
	world.free()
