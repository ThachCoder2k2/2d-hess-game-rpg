extends UnboundTest

## How finished the rooms are (docs/game-base-plan.md 1.3, 7.5, M5 acceptance): every room carries a content status of the ladder
## STUB, GREYBOX, DRESSED, FINAL on its RoomEncounter root, no room is FINAL (only the owner marks one), and tools/list_placeholders.gd
## reports the count at each status, which this suite reads from the same helper (tools/room_status_report.gd) and from the command.

const RoomStatusReport := preload("res://tools/room_status_report.gd")
const WorldMapPrinter := preload("res://tools/world_map_printer.gd")
const LIST_SCRIPT_PATH := "res://tools/list_placeholders.gd"


func _init() -> void:
	suite_title = "TEST ROOM STATUS"
	var graph := ContentDb.world()
	var scans := WorldMapPrinter.scans_of(graph)
	var report := RoomStatusReport.of(graph, scans)
	_check_every_room_has_a_status_of_the_ladder(graph, scans, report)
	_check_the_counts(report)
	_check_the_report_text(report)
	_check_the_command_prints_the_counts(report)
	_check_the_enum_is_the_ladder()
	finish()


func _check_every_room_has_a_status_of_the_ladder(graph: WorldGraph, scans: Dictionary[StringName, RoomScan], report: Dictionary) -> void:
	_expect(scans.size() == graph.rooms.size() and graph.rooms.size() == 34, "every one of the 34 rooms of the graph reads (%d of %d)" % [scans.size(), graph.rooms.size()])
	var not_on_the_ladder: Array[String] = []
	for room_id in scans:
		if (scans[room_id] as RoomScan).status_name not in RoomStatusReport.STATUS_ORDER:
			not_on_the_ladder.append(String(room_id))
	_expect(not_on_the_ladder.is_empty(), "every room's content_status is a rung of the ladder (not on it: %s)" % ", ".join(PackedStringArray(not_on_the_ladder)))
	_expect(RoomStatusReport.total(report) == 34 and RoomStatusReport.count(report, "unreadable") == 0, "the report holds all 34 rooms and none is unreadable")


func _check_the_counts(report: Dictionary) -> void:
	_expect(RoomStatusReport.count(report, "stub") == 28 and RoomStatusReport.count(report, "greybox") == 6, "28 rooms are STUB (the ones M5 made) and 6 GREYBOX (Stage 1)")
	_expect(RoomStatusReport.count(report, "dressed") == 0 and RoomStatusReport.count(report, "final") == 0, "none is DRESSED yet, and none is FINAL: only the owner marks a room FINAL")
	var greybox_rooms: Array = report["greybox"]
	_expect(greybox_rooms == [&"t1_white_kings_fall", &"t2_fallen_sword_tile", &"t3_first_pawn_clash", &"t4_broken_rule_yard", &"b1_black_pawn_captain", &"h1_chess_rug_hub"], "the GREYBOX rooms are the six of Stage 1, in route order (%s)" % [greybox_rooms])
	var stub_rooms: Array = report["stub"]
	_expect(&"tb1_toybox_gate" in stub_rooms and &"e1_morning_desk" in stub_rooms and &"ubb_black_king" in stub_rooms and not (&"h1_chess_rug_hub" in stub_rooms), "the STUB rooms run from tb1 to the Desk")


func _check_the_report_text(report: Dictionary) -> void:
	var lines := RoomStatusReport.lines(report)
	_expect(lines[0].begins_with("ROOMS: 34 rooms, 28 STUB, 6 GREYBOX, 0 DRESSED, 0 FINAL"), "the first line counts the rooms at each status: %s" % lines[0])
	var listed_statuses := PackedStringArray()
	for line in lines.slice(1):
		listed_statuses.append(line.strip_edges().get_slice(" ", 0))
	_expect(listed_statuses == PackedStringArray(["STUB", "GREYBOX"]), "...and a line per status that holds rooms follows, in ladder order (%s)" % [listed_statuses])
	# The report can tell a ladder with a rung reached and an unreadable room.
	var made_up := {"stub": [&"a"] as Array[StringName], "greybox": [] as Array[StringName], "dressed": [&"b"] as Array[StringName], "final": [] as Array[StringName], "unreadable": [&"c"] as Array[StringName]}
	var made_up_lines := RoomStatusReport.lines(made_up)
	_expect(made_up_lines[0].begins_with("ROOMS: 3 rooms, 1 STUB, 0 GREYBOX, 1 DRESSED, 0 FINAL, 1 UNREADABLE") and made_up_lines.size() == 4, "a report with a DRESSED room and an unreadable one says so (%s)" % made_up_lines[0])


func _check_the_command_prints_the_counts(report: Dictionary) -> void:
	var paths := TestPaths.new(self)
	var output: Array = []
	var arguments := PackedStringArray(["--headless", "--path", paths.project_directory_on_disk(), "-s", LIST_SCRIPT_PATH])
	var exit_code := OS.execute(OS.get_executable_path(), arguments, output, true)
	var printed := "".join(PackedStringArray(output))
	_expect(exit_code == 0, "tools/list_placeholders.gd exits 0 (got %d)" % exit_code)
	_expect(printed.contains(RoomStatusReport.lines(report)[0]), "the command prints the same count line as the helper: the owner sees how much of the base is still a stub")


## The ladder the tools spell is the enum of the room scene (lowercase), in the same order: a rung added to one and not the other fails.
func _check_the_enum_is_the_ladder() -> void:
	var enum_names: Array[String] = []
	for status_name: String in RoomEncounter.ContentStatus.keys():
		enum_names.append(status_name.to_lower())
	_expect(enum_names == RoomStatusReport.STATUS_ORDER, "RoomEncounter.ContentStatus is the ladder the report counts: %s" % [enum_names])
