extends RefCounted

## The rules of docs/game-base-plan.md that the M5 lints hold (R4, R18, R27, R28, R37, D-02, 5.3), written once as functions over the
## plan's table (tests/fixtures/plan_encounter_table.gd, plan_room_table.gd) and over the world graph, and shared by the seven suites
## (`test_preview_before_lethal`, `test_threat_budget`, `test_room_data_audit`, `test_enemy_placement`, `test_layout_archetypes`,
## `test_district_loops`, `test_reward_cadence`). NOT a test (the runner only collects test_*.gd) and without a class_name: suites load it with
##   const PlanLints := preload("res://tests/support/plan_lints.gd")
##
## Every function answers with sentences, one for each thing wrong (empty = the rule holds), and takes the rows it judges as an argument.
## That is what lets a suite prove a lint CAN FAIL: it copies the table (PlanEncounterTable.copy_of_rows()), breaks one row on purpose and
## requires the sentence, then runs the lint over the table as it is and requires silence. The functions read the enemy definitions through
## ContentDb for the two facts the plan keeps in the content (an enemy's threat points, and its family), so a number changed in an `.tres` is
## judged here, and they read the room rules (the caps) from RoomEncounter, the same constants the Inspector's warnings use.

const PlanEncounterTable := preload("res://tests/fixtures/plan_encounter_table.gd")
const PlanRoomTable := preload("res://tests/fixtures/plan_room_table.gd")


# --------------------------------------------------------------------------- what the content says
## The threat points of an enemy id (EnemyDefinition.threat_points), or -1 when the id is no enemy of content/enemies/.
static func threat_points_of(enemy_id: StringName) -> int:
	var definition := ContentDb.fetch(&"enemies", enemy_id) as EnemyDefinition
	return definition.threat_points if definition != null else -1


## The family of an enemy id (its VisualDefinition.piece_type: pawn, knight, bishop, rook, queen, king), or &"" when it is no enemy.
static func family_of(enemy_id: StringName) -> StringName:
	var definition := ContentDb.fetch(&"enemies", enemy_id) as EnemyDefinition
	return definition.visual.piece_type if definition != null and definition.visual != null else &""


static func is_hazard(piece: StringName) -> bool:
	return PlanEncounterTable.HAZARD_POINTS.has(piece)


## The rows of a table by room id.
static func rows_by_id(rows: Array[Dictionary]) -> Dictionary:
	var by_id := {}
	for row in rows:
		by_id[row["id"]] = row
	return by_id


## The rooms of the critical path in the order a player first meets them (the hub once).
static func route_order(critical_path: Array[StringName]) -> Array[StringName]:
	var order: Array[StringName] = []
	for room_id in critical_path:
		if room_id not in order:
			order.append(room_id)
	return order


## Every piece and hazard of a row, in every wave when it has waves.
static func every_live_piece(row: Dictionary) -> Array:
	if row.has("waves"):
		var pieces: Array = []
		for wave: Array in row["waves"]:
			pieces.append_array(wave)
		return pieces
	return row["live"]


static func recipe_of(room_id: StringName) -> RoomEncounter.Recipe:
	var room_row := PlanRoomTable.row_of(room_id)
	return RoomEncounter.Recipe[String(room_row["recipe"]).to_upper()]


# --------------------------------------------------------------------------- R27: preview before lethal
## "Preview before lethal for every enemy family: a fenced, telegraph-only instance appears earlier on the route" (R27, 7.5 Placement).
## Walking the critical path, a family is INTRODUCED by a room that shows it fenced, or by a room flagged `intro` whose lone live piece is
## the first of it (T3's Recruit: the first lesson cannot be fenced behind a lesson that does not exist). A live piece of a family that no
## EARLIER room introduced is a problem. A hazard has no family and is judged by the Teach ladder (R4), not here. The answer:
##   problems        the sentences
##   introduced_by   family -> the room that introduced it
##   first_live      family -> the first room on the route where a live piece of it stands
static func family_timeline(rows: Array[Dictionary], critical_path: Array[StringName]) -> Dictionary:
	var problems := PackedStringArray()
	var by_id := rows_by_id(rows)
	var introduced_by: Dictionary = {}
	var first_live: Dictionary = {}
	for room_id in route_order(critical_path):
		var row: Dictionary = by_id.get(room_id, {})
		if row.is_empty():
			problems.append("%s: the room is on the critical path but the table has no row for it." % room_id)
			continue
		var introduced_here: Array[StringName] = []
		for piece: StringName in every_live_piece(row):
			if is_hazard(piece):
				continue
			var family := family_of(piece)
			if family == &"":
				problems.append("%s: the piece '%s' is no enemy of content/enemies/." % [room_id, piece])
				continue
			if not first_live.has(family):
				first_live[family] = room_id
			if introduced_by.has(family):
				continue
			elif bool(row["intro"]):
				introduced_here.append(family)
			else:
				problems.append("%s: a %s ('%s') is live here and no fenced preview of the %s family appears earlier on the route (R27)." % [room_id, family, piece, family])
		for family: StringName in row["fenced"]:
			introduced_here.append(family)
		for family in introduced_here:
			if not introduced_by.has(family):
				introduced_by[family] = room_id
	return {"problems": problems, "introduced_by": introduced_by, "first_live": first_live}


static func preview_problems(rows: Array[Dictionary], critical_path: Array[StringName]) -> PackedStringArray:
	return family_timeline(rows, critical_path)["problems"]


# --------------------------------------------------------------------------- R18, R28: the threat budget
## The budget rules over a table: each row's live pieces add up (by threat_points, and the plan's points for a hazard) to the plan's number,
## the shapes it throws fit the plan's number, the plan's numbers obey RoomEncounter.threat_problems() (the rules the Inspector applies: Teach
## 3 or less, Test and Twist 3 to 6 unless `intro`, shapes by act, per wave in a gauntlet), and the room before a boss carries 6 or less and
## less than the boss's phase-1 budget (R18).
static func threat_budget_problems(rows: Array[Dictionary], critical_path: Array[StringName]) -> PackedStringArray:
	var problems := PackedStringArray()
	var by_id := rows_by_id(rows)
	var piece_threat: Callable = threat_points_of
	for row in rows:
		var room_id: StringName = row["id"]
		var room_row := PlanRoomTable.row_of(room_id)
		if room_row.is_empty():
			problems.append("%s: the table has a row for a room the plan's room table does not list." % room_id)
			continue
		var pieces: Array = PlanEncounterTable.live_of(row, piece_threat)
		for piece: StringName in every_live_piece(row):
			if not is_hazard(piece) and threat_points_of(piece) < 1:
				problems.append("%s: the piece '%s' has no threat_points (it is no enemy, or nobody rated it)." % [room_id, piece])
		var computed_threat: int = PlanEncounterTable.threat_of(pieces, piece_threat)
		if computed_threat != int(row["threat"]):
			problems.append("%s: its live pieces add up to %d threat but the plan's table says %d." % [room_id, computed_threat, row["threat"]])
		var is_boss: bool = String(room_row["recipe"]) == "boss"
		var computed_shapes := PlanEncounterTable.shapes_of(pieces).size()
		if computed_shapes > int(row["shapes"]) and not is_boss:
			problems.append("%s: its live pieces throw %d different shapes but the plan's table says %d." % [room_id, computed_shapes, row["shapes"]])
		elif computed_shapes < int(row["shapes"]) and not is_boss and not row.has("waves"):
			problems.append("%s: its live pieces throw only %d different shapes but the plan's table says %d." % [room_id, computed_shapes, row["shapes"]])
		var recipe := recipe_of(room_id)
		for sentence in RoomEncounter.threat_problems(recipe, int(room_row["act"]), int(row["threat"]), int(row["shapes"]), bool(row["intro"])):
			problems.append("%s: %s" % [room_id, sentence])
		if row.has("waves"):
			for wave_index in (row["waves"] as Array).size():
				var wave: Array = row["waves"][wave_index]
				var wave_threat: int = PlanEncounterTable.threat_of(wave, piece_threat)
				for sentence in RoomEncounter.threat_problems(recipe, int(room_row["act"]), wave_threat, PlanEncounterTable.shapes_of(wave).size(), false):
					problems.append("%s: wave %d: %s" % [room_id, wave_index + 1, sentence])
	for path_index in range(1, critical_path.size()):
		var boss_row: Dictionary = by_id.get(critical_path[path_index], {})
		if boss_row.is_empty() or String(PlanRoomTable.row_of(critical_path[path_index]).get("recipe", "")) != "boss":
			continue
		var before_row: Dictionary = by_id.get(critical_path[path_index - 1], {})
		if before_row.is_empty():
			continue
		if int(before_row["threat"]) > RoomEncounter.ROOM_BEFORE_BOSS_THREAT_LIMIT:
			problems.append("%s: the room before the boss of %s carries %d threat, at most %d allowed (R18)." % [before_row["id"], boss_row["id"], before_row["threat"], RoomEncounter.ROOM_BEFORE_BOSS_THREAT_LIMIT])
		if int(before_row["threat"]) >= int(boss_row["threat"]):
			problems.append("%s: the room before the boss of %s carries %d threat, which is not below the boss's phase-1 budget of %d (R18)." % [before_row["id"], boss_row["id"], before_row["threat"], boss_row["threat"]])
	return problems


# --------------------------------------------------------------------------- R4 and the teach ladder
## The shapes a room throws or shows, in the order the route meets them: the shape of every live piece and hazard, and of every fenced family.
static func shapes_in_room(row: Dictionary) -> Array[StringName]:
	var shapes: Array[StringName] = PlanEncounterTable.shapes_of(every_live_piece(row))
	for family: StringName in row["fenced"]:
		var shape: StringName = PlanEncounterTable.SHAPE_OF_FAMILY.get(family, &"")
		if shape != &"" and shape not in shapes:
			shapes.append(shape)
	return shapes


## The shapes a room meets for the first time on the route, each judged against the rooms BEFORE it.
static func new_shapes_of_each_room(rows: Array[Dictionary], critical_path: Array[StringName]) -> Dictionary:
	var by_id := rows_by_id(rows)
	var seen: Array[StringName] = []
	var new_shapes_by_room := {}
	for room_id in route_order(critical_path):
		var row: Dictionary = by_id.get(room_id, {})
		if row.is_empty():
			continue
		var new_shapes: Array[StringName] = []
		for shape in shapes_in_room(row):
			if shape not in seen:
				new_shapes.append(shape)
		for shape in new_shapes:
			seen.append(shape)
		new_shapes_by_room[room_id] = new_shapes
	return new_shapes_by_room


## "Introduce one new geometry at a time" (req 88, R4): no room meets more than one new shape, fenced or live, for the first time.
static func one_new_shape_problems(rows: Array[Dictionary], critical_path: Array[StringName]) -> PackedStringArray:
	var problems := PackedStringArray()
	var new_shapes_by_room := new_shapes_of_each_room(rows, critical_path)
	for room_id: StringName in new_shapes_by_room:
		var new_shapes: Array = new_shapes_by_room[room_id]
		if new_shapes.size() > 1:
			problems.append("%s: introduces %d new shapes at once (%s): one new geometry at a time." % [room_id, new_shapes.size(), ", ".join(PackedStringArray(new_shapes))])
	return problems


## R4: a Teach room introduces at most one new verb or shape, and the new shape is shown fenced (telegraph-only) before any damaging
## instance in that room: a live piece or hazard of a shape no earlier room met is a problem there, whatever else the room does.
static func teach_ladder_problems(rows: Array[Dictionary], critical_path: Array[StringName]) -> PackedStringArray:
	var problems := PackedStringArray()
	var new_shapes_by_room := new_shapes_of_each_room(rows, critical_path)
	var by_id := rows_by_id(rows)
	for room_id: StringName in route_order(critical_path):
		if String(PlanRoomTable.row_of(room_id).get("recipe", "")) != "teach":
			continue
		var row: Dictionary = by_id.get(room_id, {})
		if row.is_empty():
			continue
		var new_shapes: Array = new_shapes_by_room.get(room_id, [])
		var introduced := (row["verbs"] as Array).size() + new_shapes.size()
		if introduced > 1:
			problems.append("%s: a Teach room introduces at most one new verb or shape (R4) and this one introduces %d (verbs %s, shapes %s)." % [room_id, introduced, row["verbs"], new_shapes])
		var live_shapes := PlanEncounterTable.shapes_of(every_live_piece(row))
		for shape in live_shapes:
			if shape in new_shapes:
				problems.append("%s: the new shape '%s' is live in a Teach room before it was shown fenced (R4)." % [room_id, shape])
	return problems


# --------------------------------------------------------------------------- 7.5 "every room answers", the format-breaker, R32
## "Every room answers: which part of the room, why adjacent, what fantasy, what rule it teaches" (req 127), as far as a table row can: it
## names what it teaches and the feeling it is after, a district and an act (the plan's room table), and the table lists exactly the rooms
## of the plan, once each, in the same route order.
static func every_room_answers_problems(rows: Array[Dictionary]) -> PackedStringArray:
	var problems := PackedStringArray()
	var seen_ids: Array[StringName] = []
	for row in rows:
		var room_id: StringName = row["id"]
		if room_id in seen_ids:
			problems.append("%s: the room has two rows." % room_id)
		seen_ids.append(room_id)
		if String(row.get("teaches", "")).strip_edges().is_empty():
			problems.append("%s: the room does not say what it teaches (the Gate, exam column)." % room_id)
		if String(row.get("emotion", "")).strip_edges().is_empty():
			problems.append("%s: the room does not say what feeling it is after (the Emotion column)." % room_id)
		var room_row := PlanRoomTable.row_of(room_id)
		if room_row.is_empty():
			problems.append("%s: no such room in the plan's room table." % room_id)
		elif StringName(room_row["district"]) == &"" or int(room_row["act"]) < 1:
			problems.append("%s: the room belongs to no district and no act." % room_id)
	var expected_ids: Array[StringName] = []
	for room_row in PlanRoomTable.ROWS:
		expected_ids.append(room_row["id"])
	if seen_ids != expected_ids:
		problems.append("the table lists the rooms %s but the plan's room table lists %s." % [seen_ids, expected_ids])
	return problems


## "Why adjacent": every door joins two rooms of one district, or goes to or from the hub, or leads into the Ending. `scan_by_room` is room id -> RoomScan.
static func adjacency_problems(graph: WorldGraph, scan_by_room: Dictionary[StringName, RoomScan]) -> PackedStringArray:
	var problems := PackedStringArray()
	for edge in graph.edges:
		var from_scan: RoomScan = scan_by_room.get(edge.from_room)
		var to_scan: RoomScan = scan_by_room.get(edge.to_room)
		if from_scan == null or to_scan == null:
			problems.append("%s/%s: a door of the graph joins a room whose scene is missing." % [edge.from_room, edge.door])
			continue
		var touches_hub := from_scan.layout_archetype == &"hub" or to_scan.layout_archetype == &"hub"
		var enters_ending := to_scan.recipe_name == "ending"
		if from_scan.district != to_scan.district and not touches_hub and not enters_ending:
			problems.append("%s/%s: the door joins the %s to the %s with no reason (a door stays inside a district, or goes to or from the hub, or enters the Ending)." % [edge.from_room, edge.door, from_scan.district, to_scan.district])
	return problems


## D-02, 7.5: each district has a format-breaker, a room of an objective kind other than `clear` among the rooms that are neither a shortcut
## nor an optional nook (those are never `clear`, so they break nothing), and the four the plan names (tb3, bs3, bt2, dh1) are exactly that.
static func format_breaker_problems(rows: Array[Dictionary]) -> PackedStringArray:
	var problems := PackedStringArray()
	var districts: Array[StringName] = []
	var breaker_in_district := {}
	for row in rows:
		var room_row := PlanRoomTable.row_of(row["id"])
		if room_row.is_empty():
			continue
		var district: StringName = room_row["district"]
		if district not in districts:
			districts.append(district)
		var recipe := String(room_row["recipe"])
		if recipe not in ["shortcut", "optional"] and StringName(row["objective"]) != &"clear":
			breaker_in_district[district] = true
	for district in districts:
		if district == &"desk":
			continue
		if not breaker_in_district.get(district, false):
			problems.append("%s: no room of this district has an objective kind other than clear: no format-breaker (D-02)." % district)
	for named_id: StringName in [&"tb3_toy_track_ambush", &"bs3_torn_page_bridge", &"bt2_ruler_bridge", &"dh1_foyer"]:
		var named_row: Dictionary = rows_by_id(rows).get(named_id, {})
		if named_row.is_empty() or StringName(named_row["objective"]) == &"clear":
			problems.append("%s: the plan names it the format-breaker of its district (7.5) and its objective kind is not different from clear." % named_id)
	return problems


## R32 on the table: the critical-path intensities in route order, the hub's first visit in Act 1 and its returns left out, equal the plan's check (7.4); no three in a row are
## equal (hub visits counted, as the pawn walks them); the boss intensities never fall and no three are equal; no two boss-grade rooms
## (8 or more) follow each other.
static func arc_problems(rows: Array[Dictionary], critical_path: Array[StringName]) -> PackedStringArray:
	var problems := PackedStringArray()
	var by_id := rows_by_id(rows)
	var walked: Array[int] = []
	var bosses: Array[int] = []
	var by_act := {}
	var hub_seen := false
	for room_id in critical_path:
		var row: Dictionary = by_id.get(room_id, {})
		if row.is_empty():
			problems.append("%s: on the critical path but not in the table." % room_id)
			continue
		walked.append(int(row["intensity"]))
		var room_row := PlanRoomTable.row_of(room_id)
		if String(room_row.get("recipe", "")) == "boss":
			bosses.append(int(row["intensity"]))
		# The hub's first visit stands in Act 1, as the plan's check lists it; a return to the hub is not listed again.
		var is_hub := StringName(room_row.get("archetype", &"")) == &"hub"
		if not is_hub or not hub_seen:
			hub_seen = hub_seen or is_hub
			var act := int(room_row.get("act", 0))
			if not by_act.has(act):
				by_act[act] = []
			(by_act[act] as Array).append(int(row["intensity"]))
	if by_act != PlanEncounterTable.INTENSITY_BY_ACT:
		problems.append("the intensities by act are %s but the plan's check (7.4) says %s." % [by_act, PlanEncounterTable.INTENSITY_BY_ACT])
	for index in range(2, walked.size()):
		if walked[index] == walked[index - 1] and walked[index] == walked[index - 2]:
			problems.append("three rooms in a row share the intensity %d, ending at step %d of the route (R32)." % [walked[index], index + 1])
	for index in range(1, bosses.size()):
		if bosses[index] < bosses[index - 1]:
			problems.append("the boss intensities fall from %d to %d (R32: non-decreasing)." % [bosses[index - 1], bosses[index]])
		if index >= 2 and bosses[index] == bosses[index - 1] and bosses[index] == bosses[index - 2]:
			problems.append("three bosses in a row share the intensity %d (R32)." % bosses[index])
	for index in range(1, walked.size()):
		if walked[index] >= 8 and walked[index - 1] >= 8:
			problems.append("two boss-grade rooms (8 or more) follow each other at steps %d and %d of the route (R32)." % [index, index + 1])
	return problems


# --------------------------------------------------------------------------- 5.3: where each enemy is placed
## "Every enemy in this table is placed in at least one room" (5.3, 7.5): each enemy of the Placed in column is live (or fenced, where the
## plan says so) in every room the column names, and a live ordinary piece of any row is named by the column for that room. Bosses other than
## the Queen and the King are 5.4's, not 5.3's, and are not judged in reverse.
static func placement_problems(rows: Array[Dictionary]) -> PackedStringArray:
	var problems := PackedStringArray()
	var by_code := {}
	for row in rows:
		by_code[PlanEncounterTable.code_of(row["id"])] = row
	for enemy_id: StringName in PlanEncounterTable.PLACED_IN:
		var placed_rooms := 0
		for code: StringName in PlanEncounterTable.PLACED_IN[enemy_id]:
			if code in [&"boss_guards", &"boss_summons"]:
				continue
			var row: Dictionary = by_code.get(code, {})
			if row.is_empty():
				problems.append("%s: the plan places it in '%s', which is no room of the table." % [enemy_id, code])
				continue
			var fenced_here: bool = code in PlanEncounterTable.FENCED_PLACEMENTS.get(enemy_id, [])
			var is_there: bool = enemy_id in every_live_piece(row) or (fenced_here and family_of(enemy_id) in row["fenced"])
			if not is_there:
				problems.append("%s: the plan places it in %s (%s) but that room's row does not hold it%s." % [enemy_id, code, row["id"], " fenced" if fenced_here else ""])
			else:
				placed_rooms += 1
		if placed_rooms < 1:
			problems.append("%s: it is placed in no room at all." % enemy_id)
	for row in rows:
		var code := PlanEncounterTable.code_of(row["id"])
		for piece: StringName in every_live_piece(row):
			if is_hazard(piece):
				continue
			var definition := ContentDb.fetch(&"enemies", piece) as EnemyDefinition
			if definition != null and definition.defeat_flag != &"" and not PlanEncounterTable.PLACED_IN.has(piece):
				continue
			if not PlanEncounterTable.PLACED_IN.has(piece) or code not in PlanEncounterTable.PLACED_IN[piece]:
				problems.append("%s: the row holds '%s' but the plan's Placed in column does not name this room for it." % [row["id"], piece])
	return problems


# --------------------------------------------------------------------------- D-02: no two rooms in a row share an archetype
## "No two consecutive critical-path rooms share a layout_archetype" (D-02). `archetype_by_room` is room id -> archetype.
static func archetype_problems(archetype_by_room: Dictionary, critical_path: Array[StringName]) -> PackedStringArray:
	var problems := PackedStringArray()
	for index in range(1, critical_path.size()):
		var before: StringName = critical_path[index - 1]
		var after: StringName = critical_path[index]
		if not archetype_by_room.has(before) or not archetype_by_room.has(after):
			problems.append("%s, %s: a room of the critical path has no archetype." % [before, after])
		elif before != after and archetype_by_room[before] == archetype_by_room[after]:
			problems.append("%s and %s follow each other on the critical path and share the layout archetype '%s' (D-02)." % [before, after, archetype_by_room[after]])
	return problems


# --------------------------------------------------------------------------- D-02: every district has a loop or a shortcut
## True when `room_id` stands on a loop of the doors: a way out and a different way back, through at least three rooms. A door that can be
## walked both ways is two edges and a back-and-forth is not a loop. A one-way shortcut home closes one.
static func is_on_a_loop(graph: WorldGraph, room_id: StringName) -> bool:
	for out_edge in graph.edges_from(room_id):
		var first_step: StringName = out_edge.to_room
		if first_step == room_id or not graph.has_zone(first_step):
			continue
		var reached: Dictionary = {first_step: true}
		var frontier: Array[StringName] = [first_step]
		while not frontier.is_empty():
			var current: StringName = frontier.pop_front()
			for next_edge in graph.edges_from(current):
				if next_edge.to_room == room_id and current != first_step:
					return true
				if next_edge.to_room != room_id and graph.has_zone(next_edge.to_room) and not reached.has(next_edge.to_room):
					reached[next_edge.to_room] = true
					frontier.append(next_edge.to_room)
	return false


## Every district that holds a room has a room on a loop. `district_of` is room id -> district; `exemptions` is district -> the reason it has
## none by design: an exemption for a district that DOES have a loop is a problem too (it must be deleted), so exemptions cannot rot.
static func district_loop_problems(graph: WorldGraph, district_of: Dictionary, exemptions: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	var districts: Array[StringName] = []
	for room_id: StringName in graph.room_ids():
		var district: StringName = district_of.get(room_id, &"")
		if district != &"" and district not in districts:
			districts.append(district)
	for district in districts:
		var has_loop := false
		for room_id: StringName in graph.room_ids():
			if district_of.get(room_id, &"") == district and is_on_a_loop(graph, room_id):
				has_loop = true
				break
		if not has_loop and not exemptions.has(district):
			problems.append("%s: no room of this district stands on a loop or a shortcut of the doors (D-02)." % district)
		elif has_loop and exemptions.has(district):
			problems.append("%s: it has a loop now, so its exemption ('%s') is stale and must be deleted." % [district, exemptions[district]])
	for district: StringName in exemptions:
		if district not in districts:
			problems.append("%s: exempted from the loop rule but no room belongs to it." % district)
	return problems


# --------------------------------------------------------------------------- R37: micro-rewards
## The critical path as a timeline of persistent rewards: each entry is {"minute": when it lands, "what": what}, in the order met. A room's
## rewards land when its minutes are over; `mid_rewards` land at their fraction of them; the hub's first visit is its own row's minutes and
## each return is HUB_PASS_THROUGH_MINUTES with nothing handed over; a room whose recipe is `ending` is the end of the timeline.
static func reward_timeline(rows: Array[Dictionary], critical_path: Array[StringName]) -> Dictionary:
	var by_id := rows_by_id(rows)
	var events: Array[Dictionary] = []
	var clock := 0.0
	var visited: Array[StringName] = []
	for room_id in critical_path:
		var row: Dictionary = by_id.get(room_id, {})
		if row.is_empty() or String(PlanRoomTable.row_of(room_id).get("recipe", "")) == "ending":
			continue
		var minutes := PlanEncounterTable.HUB_PASS_THROUGH_MINUTES if room_id in visited else float(row["minutes"])
		if room_id not in visited:
			for mid_reward: Array in row.get("mid_rewards", []):
				events.append({"minute": clock + minutes * float(mid_reward[2]), "what": "%s: %s" % [room_id, mid_reward[1]], "kind": mid_reward[0]})
			for reward: Array in row["rewards"]:
				events.append({"minute": clock + minutes, "what": "%s: %s" % [room_id, reward[1]], "kind": reward[0]})
		visited.append(room_id)
		clock += minutes
	events.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return float(left["minute"]) < float(right["minute"]))
	return {"events": events, "minutes": clock}


## R37: no stretch of the critical path between two persistent rewards (or the start and the first, or the last and the end of the fights) is
## longer than REWARD_WINDOW_MINUTES. Every reward must also be of a kind R37 counts.
static func reward_cadence_problems(rows: Array[Dictionary], critical_path: Array[StringName]) -> PackedStringArray:
	var problems := PackedStringArray()
	for row in rows:
		for reward: Array in row["rewards"] + row.get("mid_rewards", []):
			if StringName(reward[0]) not in PlanEncounterTable.REWARD_KINDS:
				problems.append("%s: the reward '%s' is of the kind '%s', which R37 does not count." % [row["id"], reward[1], reward[0]])
	var timeline := reward_timeline(rows, critical_path)
	var events: Array = timeline["events"]
	var last_minute := 0.0
	var last_what := "the start"
	for event: Dictionary in events:
		var gap := float(event["minute"]) - last_minute
		if gap > PlanEncounterTable.REWARD_WINDOW_MINUTES + 0.0001:
			problems.append("%.1f minutes pass between %s and %s (R37: at most %.0f)." % [gap, last_what, event["what"], PlanEncounterTable.REWARD_WINDOW_MINUTES])
		last_minute = float(event["minute"])
		last_what = String(event["what"])
	var tail := float(timeline["minutes"]) - last_minute
	if tail > PlanEncounterTable.REWARD_WINDOW_MINUTES + 0.0001:
		problems.append("%.1f minutes pass between %s and the end of the last fight (R37: at most %.0f)." % [tail, last_what, PlanEncounterTable.REWARD_WINDOW_MINUTES])
	return problems


## The longest stretch without a reward, in minutes (for the REPORT line).
static func longest_reward_gap(rows: Array[Dictionary], critical_path: Array[StringName]) -> float:
	var timeline := reward_timeline(rows, critical_path)
	var longest := 0.0
	var last_minute := 0.0
	for event: Dictionary in timeline["events"]:
		longest = maxf(longest, float(event["minute"]) - last_minute)
		last_minute = float(event["minute"])
	return maxf(longest, float(timeline["minutes"]) - last_minute)


## The plan's minutes of the critical path by act (7.4 Totals), from the rows: each room once, in the act of the room (the hub's first visit is
## Act 1's), and apart from them the hub's pass-throughs, one for each return to the hub, under the key `&"hub_passes"`.
static func minutes_by_act(rows: Array[Dictionary], critical_path: Array[StringName]) -> Dictionary:
	var by_id := rows_by_id(rows)
	var minutes_by_key := {}
	var visited: Array[StringName] = []
	for room_id in critical_path:
		var row: Dictionary = by_id.get(room_id, {})
		if row.is_empty():
			continue
		if room_id in visited:
			minutes_by_key[&"hub_passes"] = float(minutes_by_key.get(&"hub_passes", 0.0)) + PlanEncounterTable.HUB_PASS_THROUGH_MINUTES
		else:
			var act := int(PlanRoomTable.row_of(room_id)["act"])
			minutes_by_key[act] = float(minutes_by_key.get(act, 0.0)) + float(row["minutes"])
		visited.append(room_id)
	return minutes_by_key


# --------------------------------------------------------------------------- the shipped scenes
## Room id -> RoomScan of its scene, for every room of the graph (a room whose scene cannot be read is left out).
static func scans_of(graph: WorldGraph) -> Dictionary[StringName, RoomScan]:
	var scan_by_room: Dictionary[StringName, RoomScan] = {}
	for room_id in graph.room_ids():
		var scan := RoomScan.of(graph.get_zone_scene(room_id))
		if scan != null:
			scan_by_room[room_id] = scan
	return scan_by_room


## The room id of a code of the Placed in column (tb1 -> tb1_toybox_gate), or &"" when no room of the plan has it.
static func room_id_of_code(code: StringName) -> StringName:
	for room_row in PlanRoomTable.ROWS:
		if PlanEncounterTable.code_of(room_row["id"]) == code:
			return room_row["id"]
	return &""


## The ids of the enemies a scan parks, in the order of the scene.
static func parked_enemy_ids(scan: RoomScan) -> Array[StringName]:
	var ids: Array[StringName] = []
	for definition in scan.enemy_definitions:
		ids.append(definition.id)
	return ids


## The enemies of content/enemies/ that no scan parks (5.3: every enemy is placed in at least one room).
static func unplaced_enemy_ids(scan_by_room: Dictionary[StringName, RoomScan]) -> Array[StringName]:
	var parked := {}
	for scan: RoomScan in scan_by_room.values():
		for enemy_id in parked_enemy_ids(scan):
			parked[enemy_id] = true
	var unplaced: Array[StringName] = []
	for enemy_id: StringName in ContentDb.ids(&"enemies"):
		if not parked.has(enemy_id):
			unplaced.append(enemy_id)
	return unplaced


## The threat points of the pieces a scan parks, all of them (a stub parks every piece live).
static func parked_threat_of(scan: RoomScan) -> int:
	var total := 0
	for definition in scan.enemy_definitions:
		total += definition.threat_points
	return total


## A copy of the rooms and doors of a graph that a lint may break on purpose (locks and regions are not copied: the lints of M5 read neither).
static func copy_of_graph(graph: WorldGraph) -> WorldGraph:
	var copy := WorldGraph.new()
	copy.start_room_id = graph.start_room_id
	for room in graph.rooms:
		var room_copy := WorldRoom.new()
		room_copy.room_id = room.room_id
		room_copy.scene = room.scene
		room_copy.map_slot = room.map_slot
		copy.rooms.append(room_copy)
	for edge in graph.edges:
		var edge_copy := WorldEdge.new()
		edge_copy.from_room = edge.from_room
		edge_copy.door = edge.door
		edge_copy.to_room = edge.to_room
		edge_copy.to_entry = edge.to_entry
		edge_copy.one_way = edge.one_way
		copy.edges.append(edge_copy)
	return copy
