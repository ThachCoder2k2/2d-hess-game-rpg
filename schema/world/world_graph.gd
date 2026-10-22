class_name WorldGraph
extends Resource

## The world as one editor-authored resource (docs/game-base-plan.md 7.1, 7.2): the rooms and the slot of the map
## each one sits in, the doors between them, the locks that hold some of those doors shut, and the part of the map
## each district may use. `content/world/world.tres` is the only instance. Adding a room to the game = author the
## scene (tools/build_room.gd), add a WorldRoom, add the WorldEdges of its doors.
##
## Exits inside room scenes name their destination by room id (ZoneExitMarker.target_zone); the runtime asks
## `has_zone()` and `get_zone_scene()` ("zone" is the runtime's word for a room). Everything else here is data for
## the map, the tools and the tests: `tests/content/test_world_graph.gd` holds the scenes and this file together.
##
## The 72x40 kingdom is NOT here: it is a test fixture (D-02), loaded by tests from tests/fixtures/.

## The map is a grid of room slots: 8 columns by 10 rows (a slot holds one 16x9 room, §7.1).
const MAP_COLUMNS := 8
const MAP_ROWS := 10
## The districts of the bedroom (docs/game-base-plan.md 7.1, D-21 order): the ids RoomEncounter.district and
## WorldRegion.district use. `chess_rug` holds Act 1 and the hub, `desk` the Ending, `window` is the view only.
const DISTRICT_IDS: Array[StringName] = [&"chess_rug", &"toybox", &"bookshelf", &"block_tower", &"dollhouse", &"under_bed", &"desk", &"window"]
## A room id: lowercase snake_case, the same spelling ContentDb.ID_PATTERN asks of a folder.
const ROOM_ID_PATTERN := "^[a-z][a-z0-9_]*$"

## The room the game starts in (T1).
@export var start_room_id: StringName = &""
## Every room of the game. Listed in route order so a diff reads as a story.
@export var rooms: Array[WorldRoom] = []
## Every door between two rooms (see WorldEdge).
@export var edges: Array[WorldEdge] = []
## Every lock that holds a door shut (see WorldLock).
@export var locks: Array[WorldLock] = []
## The part of the map each district may use.
@export var regions: Array[WorldRegion] = []


## The district ids as one sentence-ready list: "chess_rug, toybox, ...".
static func district_ids_text() -> String:
	var names := PackedStringArray()
	for district_id in DISTRICT_IDS:
		names.append(String(district_id))
	return ", ".join(names)


## The ids of the rooms, in the order the file lists them.
func room_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for room in rooms:
		ids.append(room.room_id)
	return ids


## The WorldRoom called `room_id`, or null.
func find_room(room_id: StringName) -> WorldRoom:
	for room in rooms:
		if room.room_id == room_id:
			return room
	return null


## True when the graph has a room with this id. ("Zone" is the word the runtime uses for a room.)
func has_zone(zone_id: StringName) -> bool:
	return find_room(zone_id) != null


## The scene of the room `zone_id`, or null when the graph has no such room.
func get_zone_scene(zone_id: StringName) -> PackedScene:
	var room := find_room(zone_id)
	return room.scene if room != null else null


## The room that sits on map slot `slot`, or null.
func room_at_slot(slot: Vector2i) -> WorldRoom:
	for room in rooms:
		if room.map_slot == slot:
			return room
	return null


## Every edge whose door is in `room_id`, in file order.
func edges_from(room_id: StringName) -> Array[WorldEdge]:
	var found: Array[WorldEdge] = []
	for edge in edges:
		if edge.from_room == room_id:
			found.append(edge)
	return found


## The edge of door `door` in room `room_id`, or null.
func find_edge(room_id: StringName, door: StringName) -> WorldEdge:
	for edge in edges:
		if edge.from_room == room_id and edge.door == door:
			return edge
	return null


func find_lock(lock_id: StringName) -> WorldLock:
	for lock in locks:
		if lock.lock_id == lock_id:
			return lock
	return null


## The region of the map `district` may use, or null.
func region_of(district: StringName) -> WorldRegion:
	for region in regions:
		if region.district == district:
			return region
	return null


## Every room id the pawn can reach from the start room by walking through doors, the start room included:
## room id -> number of doors on the shortest way. A room missing from it is an orphan.
func reachable_room_ids() -> Dictionary[StringName, int]:
	var doors_to_room: Dictionary[StringName, int] = {}
	if not has_zone(start_room_id):
		return doors_to_room
	doors_to_room[start_room_id] = 0
	var frontier: Array[StringName] = [start_room_id]
	while not frontier.is_empty():
		var room_id: StringName = frontier.pop_front()
		for edge in edges_from(room_id):
			if has_zone(edge.to_room) and not doors_to_room.has(edge.to_room):
				doors_to_room[edge.to_room] = doors_to_room[room_id] + 1
				frontier.append(edge.to_room)
	return doors_to_room


## What is wrong with the graph as a piece of data, one sentence each (empty = healthy). It reads only this
## resource: that the scenes agree with it (doors, entries, folders, districts) is `test_world_graph.gd`'s
## and `ContentDb.validate_cross_refs()`'s job, because only they open the scenes.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if rooms.is_empty():
		problems.append("World graph has no rooms.")
	var id_pattern := RegEx.create_from_string(ROOM_ID_PATTERN)
	var slot_owner: Dictionary[Vector2i, StringName] = {}
	var seen_room_ids: Dictionary[StringName, bool] = {}
	for room in rooms:
		if room == null:
			problems.append("The room list holds an empty entry.")
			continue
		if id_pattern.search(String(room.room_id)) == null:
			problems.append("Room '%s' needs a room_id in lowercase snake_case." % room.room_id)
		if seen_room_ids.has(room.room_id):
			problems.append("Room '%s' is listed twice." % room.room_id)
		seen_room_ids[room.room_id] = true
		if room.scene == null:
			problems.append("Room '%s' has no scene." % room.room_id)
		if room.map_slot.x < 0 or room.map_slot.y < 0 or room.map_slot.x >= MAP_COLUMNS or room.map_slot.y >= MAP_ROWS:
			problems.append("Room '%s' sits on map slot %s, outside the %d x %d map." % [room.room_id, room.map_slot, MAP_COLUMNS, MAP_ROWS])
		elif slot_owner.has(room.map_slot):
			problems.append("Rooms '%s' and '%s' both sit on map slot %s." % [slot_owner[room.map_slot], room.room_id, room.map_slot])
		else:
			slot_owner[room.map_slot] = room.room_id
	if not rooms.is_empty() and not has_zone(start_room_id):
		problems.append("The start room '%s' is not one of the rooms." % start_room_id)

	var seen_districts: Dictionary[StringName, Rect2i] = {}
	for region in regions:
		if region == null:
			problems.append("The region list holds an empty entry.")
			continue
		if region.district not in DISTRICT_IDS:
			problems.append("Region '%s' is not a district (the districts are %s)." % [region.district, district_ids_text()])
		if seen_districts.has(region.district):
			problems.append("District '%s' has two regions." % region.district)
		if region.slots.size.x <= 0 or region.slots.size.y <= 0 or not Rect2i(0, 0, MAP_COLUMNS, MAP_ROWS).encloses(region.slots):
			problems.append("The region of '%s' (%s) is empty or leaves the %d x %d map." % [region.district, region.slots, MAP_COLUMNS, MAP_ROWS])
		for other_district: StringName in seen_districts:
			if seen_districts[other_district].intersects(region.slots):
				problems.append("The regions of '%s' and '%s' overlap." % [other_district, region.district])
		seen_districts[region.district] = region.slots

	var seen_lock_ids: Dictionary[StringName, bool] = {}
	for lock in locks:
		if lock == null:
			problems.append("The lock list holds an empty entry.")
			continue
		if seen_lock_ids.has(lock.lock_id):
			problems.append("Lock '%s' is listed twice." % lock.lock_id)
		seen_lock_ids[lock.lock_id] = true
		problems.append_array(lock.validate())

	var lock_id_used: Dictionary[StringName, bool] = {}
	var seen_doors: Dictionary[String, bool] = {}
	for edge in edges:
		if edge == null:
			problems.append("The edge list holds an empty entry.")
			continue
		var edge_label := "The door %s/%s" % [edge.from_room, edge.door]
		if edge.door == &"":
			problems.append("An edge out of room '%s' names no door." % edge.from_room)
		if seen_doors.has("%s/%s" % [edge.from_room, edge.door]):
			problems.append("%s has two edges." % edge_label)
		seen_doors["%s/%s" % [edge.from_room, edge.door]] = true
		if not has_zone(edge.from_room):
			problems.append("%s is in a room the graph does not list." % edge_label)
		if not has_zone(edge.to_room):
			problems.append("%s leads to room '%s', which the graph does not list." % [edge_label, edge.to_room])
		if edge.to_entry == &"":
			problems.append("%s names no entry to arrive on." % edge_label)
		if edge.lock_id != &"":
			lock_id_used[edge.lock_id] = true
			var held_by := find_lock(edge.lock_id)
			if held_by == null:
				problems.append("%s is held by lock '%s', which the graph does not list." % [edge_label, edge.lock_id])
			elif not held_by.is_enforced():
				problems.append("%s is held by lock '%s' of kind %s, which the runtime does not hold yet: name it as the door's skill_lock_id until its milestone lands." % [edge_label, edge.lock_id, held_by.kind])
		if edge.skill_lock_id != &"":
			lock_id_used[edge.skill_lock_id] = true
			var skill_lock := find_lock(edge.skill_lock_id)
			if skill_lock == null:
				problems.append("%s names the skill lock '%s', which the graph does not list." % [edge_label, edge.skill_lock_id])
			elif skill_lock.kind != WorldLock.KIND_UNLOCK:
				problems.append("%s names '%s' as its skill lock, but that lock is of kind %s (a skill lock is an `unlock`)." % [edge_label, edge.skill_lock_id, skill_lock.kind])
	for lock in locks:
		if lock != null and not lock_id_used.has(lock.lock_id):
			problems.append("Lock '%s' holds no door." % lock.lock_id)
	return problems
