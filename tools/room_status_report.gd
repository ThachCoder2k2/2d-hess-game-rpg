extends RefCounted

## How finished the rooms are (docs/game-base-plan.md 1.3: STUB -> GREYBOX -> DRESSED -> FINAL; a helper, not a command;
## no class_name, preload it). The status is `RoomEncounter.content_status` on each room scene; this counts the rooms of
## the world graph by status and says which rooms stand at each, so the owner sees how much of the base is still a stub.
## tools/list_placeholders.gd prints it beside the list of stand-in pictures, and tests/content/test_room_status.gd reads
## the same numbers. Only the owner marks a room FINAL.
##
##   var report := RoomStatusReport.of(ContentDb.world(), scans)        # status name -> [room ids]
##   RoomStatusReport.lines(report)                                    # the text list_placeholders prints

## The statuses in ladder order, as the layout files and the scans spell them (lowercase).
const STATUS_ORDER: Array[String] = ["stub", "greybox", "dressed", "final"]


## status name -> the ids of the graph's rooms at that status, in the graph's order. Every status of the ladder is a key,
## so a status nobody has reached reads as an empty list. A room whose scene could not be read counts under "unreadable".
static func of(graph: WorldGraph, scan_by_room: Dictionary[StringName, RoomScan]) -> Dictionary:
	var rooms_by_status := {}
	for status in STATUS_ORDER:
		rooms_by_status[status] = [] as Array[StringName]
	rooms_by_status["unreadable"] = [] as Array[StringName]
	for room_id in graph.room_ids():
		var scan: RoomScan = scan_by_room.get(room_id)
		var status := scan.status_name if scan != null else "unreadable"
		if not rooms_by_status.has(status):
			rooms_by_status[status] = [] as Array[StringName]
		(rooms_by_status[status] as Array).append(room_id)
	return rooms_by_status


## How many rooms are at `status` in a report made by of().
static func count(rooms_by_status: Dictionary, status: String) -> int:
	return (rooms_by_status.get(status, []) as Array).size()


## The total number of rooms a report holds.
static func total(rooms_by_status: Dictionary) -> int:
	var rooms := 0
	for status: String in rooms_by_status:
		rooms += (rooms_by_status[status] as Array).size()
	return rooms


## The report as lines of text: one summary line with a count per status, then a line per status that holds rooms, listing
## them.
static func lines(rooms_by_status: Dictionary) -> PackedStringArray:
	var text := PackedStringArray()
	var counts := PackedStringArray()
	for status in STATUS_ORDER:
		counts.append("%d %s" % [count(rooms_by_status, status), status.to_upper()])
	if count(rooms_by_status, "unreadable") > 0:
		counts.append("%d UNREADABLE" % count(rooms_by_status, "unreadable"))
	text.append("ROOMS: %d rooms, %s (STUB -> GREYBOX -> DRESSED -> FINAL; only the owner marks a room FINAL)" % [total(rooms_by_status), ", ".join(counts)])
	for status in STATUS_ORDER + ["unreadable"]:
		var ids: Array = rooms_by_status.get(status, [])
		if ids.is_empty():
			continue
		var names := PackedStringArray()
		for room_id: StringName in ids:
			names.append(String(room_id))
		text.append("  %-9s %s" % [status.to_upper(), ", ".join(names)])
	return text
