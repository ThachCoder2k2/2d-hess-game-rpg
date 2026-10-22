extends UnboundTest

## tools/print_world_map.gd (docs/game-base-plan.md 7.1, 15 M5): the ASCII map of the world for QA. The plan's promise is
## that it "shows all the nodes"; this suite requires every room, every door and every lock of content/world/world.tres
## to be in the text, the connectors between neighbours to say how they join, and a broken world to show its problems.
## It also runs the tool as the command it is, in a child process, as the owner would.

const WorldMapPrinter := preload("res://tools/world_map_printer.gd")
const TOOL_PATH := "res://tools/print_world_map.gd"


func _init() -> void:
	suite_title = "TEST PRINT WORLD MAP"
	var graph := ContentDb.world()
	var text := WorldMapPrinter.map_text(graph, WorldMapPrinter.scans_of(graph))
	_check_every_node_edge_and_lock_is_there(graph, text)
	_check_the_map_grid(graph, text)
	_check_a_broken_world_shows_its_problems(graph)
	_check_the_command()
	finish()


func _check_every_node_edge_and_lock_is_there(graph: WorldGraph, text: String) -> void:
	_expect(text.contains("THE WORLD  %d rooms, %d doors, %d locks" % [graph.rooms.size(), graph.edges.size(), graph.locks.size()]), "the first line counts the rooms, doors and locks of the graph")
	var map_section := text.get_slice("\nROOMS", 0)
	var rooms_section := text.get_slice("\nROOMS", 1).get_slice("\nEDGES", 0)
	for room in graph.rooms:
		_expect(map_section.contains("[%s]" % WorldMapPrinter.short_code(room.room_id)), "the map holds a node for %s" % room.room_id)
		_expect(rooms_section.contains(String(room.room_id)) and rooms_section.contains("%d,%d" % [room.map_slot.x, room.map_slot.y]), "...and the room table holds its id and slot")
	var edges_section := text.get_slice("\nEDGES", 1).get_slice("\nLOCKS", 0)
	for edge in graph.edges:
		_expect(edges_section.contains("%s/%s" % [edge.from_room, edge.door]) and edges_section.contains("-> %s/%s" % [edge.to_room, edge.to_entry]), "the edge list holds the door %s/%s and where it lands" % [edge.from_room, edge.door])
	var locks_section := text.get_slice("\nLOCKS", 1)
	for lock in graph.locks:
		_expect(locks_section.contains(String(lock.lock_id)) and locks_section.contains(lock.message_key) and locks_section.contains(TextService.t(lock.message_key)), "the lock list holds %s, its key and its English words" % lock.lock_id)
	for edge in graph.edges:
		if edge.lock_id != &"":
			_expect(edges_section.contains("LOCK %s" % edge.lock_id), "...and the edge list marks the locked door %s/%s" % [edge.from_room, edge.door])
	_expect(text.contains("CHECKS  every door resolves, every room has an entry and can be reached, every lock says why, and the route can be walked to the ending: clean"), "the last line says the checks are clean")
	for edge in graph.edges:
		if edge.skill_lock_id != &"":
			_expect(edges_section.contains("SKILL %s (arrives in %s)" % [edge.skill_lock_id, graph.find_lock(edge.skill_lock_id).arrives_in]), "...and the edge list marks the door %s/%s that a skill will hold (M7c)" % [edge.from_room, edge.door])
	var route_section := text.get_slice("\nROUTE", 1).get_slice("\nCHECKS", 0)
	var every_room_on_the_route := true
	for room in graph.rooms:
		every_room_on_the_route = every_room_on_the_route and route_section.contains(String(room.room_id))
	_expect(every_room_on_the_route and not route_section.contains("NEVER REACHED"), "the route walks every one of the %d rooms, and none is marked never reached" % graph.rooms.size())
	_expect(route_section.contains("sets boss.black_pawn_captain") and route_section.contains("sets boss.black_king") and route_section.contains("the run ends here"), "...says which room sets each boss's flag, and where the run ends")


## The grid is 8 columns by 10 rows, a room sits on its own slot, an empty slot shows its district, and neighbours that
## share a door are joined.
func _check_the_map_grid(graph: WorldGraph, text: String) -> void:
	var map_lines := text.get_slice("\nMAP", 1).get_slice("\nROOMS", 0).split("\n")
	var row_lines := PackedStringArray()
	for line in map_lines:
		if RegEx.create_from_string("^[0-9] {3,}").search(line) != null:
			row_lines.append(line)
	_expect(row_lines.size() == WorldGraph.MAP_ROWS, "the map has one line for each of the %d rows of slots" % WorldGraph.MAP_ROWS)
	if row_lines.size() != WorldGraph.MAP_ROWS:
		return
	var rug_row: String = row_lines[6]
	_expect(rug_row.contains("[t1]") and rug_row.contains("[t2]") and rug_row.contains("[t3]") and rug_row.contains("[t4]") and rug_row.find("[t1]") < rug_row.find("[t2]") and rug_row.find("[t2]") < rug_row.find("[t3]"), "row 6 holds T1, T2, T3 and T4, left to right, as their slots say")
	_expect(rug_row.contains("[t1]") and rug_row.contains("-[t2]") and rug_row.contains("-[t3]"), "T1, T2 and T3 are joined by doors both ways (-)")
	_expect(rug_row.contains("x[t4]"), "T3 and T4 are joined by a locked way (x): T3's door waits for a clear")
	_expect((row_lines[0] as String).contains("w") and (row_lines[1] as String).contains("e") and (row_lines[2] as String).contains("k") and (row_lines[7] as String).contains("t"), "empty slots show the first letter of their district's region (window, desk, block tower, toybox)")
	var hub_row: String = row_lines[5]
	_expect(hub_row.contains("[h1]") and hub_row.contains("[b1]") and hub_row.contains("[tb1]") and hub_row.contains("[bt2]"), "row 5 holds the hub, the boss room, the Toybox gate and the second room of the Block Tower")


func _check_a_broken_world_shows_its_problems(graph: WorldGraph) -> void:
	var broken := WorldGraph.new()
	broken.start_room_id = graph.start_room_id
	broken.rooms.append_array(graph.rooms)
	broken.edges.append_array(graph.edges)
	broken.locks.append_array(graph.locks)
	broken.regions.append_array(graph.regions)
	var island := WorldRoom.new()
	island.room_id = &"island_room"
	island.scene = graph.get_zone_scene(&"tb1_toybox_gate")
	island.map_slot = Vector2i(7, 7)
	broken.rooms.append(island)
	var text := WorldMapPrinter.map_text(broken, WorldMapPrinter.scans_of(broken))
	_expect(text.contains("CHECKS  ") and not text.contains("clean") and text.contains("room 'island_room' cannot be reached from the start room"), "a world with an orphan prints its problem under CHECKS, and no 'clean'")
	_expect(text.contains("[island_room]") or text.contains("[island]"), "...and the orphan is on the map all the same, on its slot")


func _check_the_command() -> void:
	var paths := TestPaths.new(self)
	var arguments := PackedStringArray(["--headless", "--path", paths.project_directory_on_disk(), "-s", TOOL_PATH])
	var output: Array = []
	var exit_code := OS.execute(OS.get_executable_path(), arguments, output, true)
	var printed := "".join(PackedStringArray(output))
	_expect(exit_code == 0, "the command exits 0 when the checks are clean (got %d)" % exit_code)
	_expect(printed.contains("THE WORLD  ") and printed.contains("[tb1]") and printed.contains("t3_first_pawn_clash/Exit_To_T4") and printed.contains("b1_clear"), "the command prints the map, the doors and the locks")
