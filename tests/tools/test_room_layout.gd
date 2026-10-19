extends UnboundTest

## The layout file of tools/build_room.gd (tools/room_layout.gd): what it reads, and every mistake it names. A layout is
## the only thing an agent writes to make a room, so a layout the reader accepts must build, and a layout that cannot
## be built must be refused with a sentence a person can act on. This suite reads every shipped layout, then breaks the
## proof layout (tests/fixtures/layouts/t4_broken_rule_yard.txt, the Stage 1 room t4 drawn as a layout) one way at a time
## and requires the exact complaint, so the reader is shown able to fail.

const RoomLayout := preload("res://tools/room_layout.gd")
const FIXTURE_LAYOUT := "res://tests/fixtures/layouts/t4_broken_rule_yard.txt"
const LAYOUTS_FOLDER := "res://tools/layouts"


func _init() -> void:
	suite_title = "TEST ROOM LAYOUT"
	var good_text := TestPaths.new(self).read_text(FIXTURE_LAYOUT)
	_check_the_shipped_layouts()
	_check_what_a_good_layout_means(good_text)
	_check_every_mistake_is_named(good_text)
	_check_the_legend()
	finish()


func _check_the_shipped_layouts() -> void:
	var paths := TestPaths.new(self)
	var layout_files := paths.list_files(LAYOUTS_FOLDER, "txt", 1)
	for path in layout_files:
		var room_id := path.get_file().get_basename()
		var layout: RefCounted = RoomLayout.parse(paths.read_text(path), room_id, path)
		for problem: String in layout.problems:
			printerr("  %s" % problem)
		_expect((layout.problems as PackedStringArray).is_empty(), "%s is a valid layout" % path)
	var fixture: RefCounted = RoomLayout.parse(paths.read_text(FIXTURE_LAYOUT), "t4_broken_rule_yard", FIXTURE_LAYOUT)
	_expect((fixture.problems as PackedStringArray).is_empty(), "the proof layout is valid")


func _check_what_a_good_layout_means(good_text: String) -> void:
	var layout: RefCounted = RoomLayout.parse(good_text, "t4_broken_rule_yard")
	_expect(layout.room_id == "t4_broken_rule_yard" and layout.size == Vector2i(16, 9) and layout.act == 1 and layout.district == &"chess_rug" and layout.archetype == &"yard", "[room] is read into the room's id, size, act, district and archetype")
	_expect(layout.recipe == RoomEncounter.Recipe.TWIST and layout.status == RoomEncounter.ContentStatus.GREYBOX and layout.time_of_night == RoomEncounter.TimeOfNight.DUSK and not layout.checkpoint_on_entry and layout.tileset_id == "kingdom", "...with its recipe, status, time of night, checkpoint flag and tileset as the enums and ids they are")
	_expect(layout.name_text == "Broken Rule Yard" and layout.start_text.begins_with("They broke the rules first."), "...and the English words of its name and its start line")
	_expect(layout.rows.size() == 9 and layout.rows[0] == "################" and layout.character_at(Vector2i(2, 5)) == "E" and layout.character_at(Vector2i(99, 5)) == "", "[grid] is read row by row, and a cell off the board answers nothing")
	_expect(layout.kind_at(Vector2i(0, 0)) == CellKinds.WALL and layout.kind_at(Vector2i(3, 3)) == CellKinds.FLOOR and layout.kind_at(Vector2i(2, 5)) == CellKinds.FLOOR, "a terrain character is its kind of cell and an object stands on floor")
	_expect(layout.cells_of("K") == [Vector2i(10, 6)], "the cells of a character are listed row by row")

	var placements: Array[Dictionary] = layout.placements()
	var names_in_order := PackedStringArray()
	for placement in placements:
		names_in_order.append("%s:%s" % [placement["kind"], placement["name"]])
	_expect(names_in_order == PackedStringArray(["entry:Entry_West", "entry:Entry_From_B1", "exit:Exit_To_T3", "exit:Exit_To_B1", "enemy:PawnArmed", "enemy:BackstepPawn", "enemy:PawnRecruit", "pickup:PencilSpearPickup"]),
		"the placements come in the writer's order (entries, exits, enemies, pickups; within a kind by object character) with node names derived from what they are (%s)" % ", ".join(names_in_order))
	var shut_door: Dictionary = placements[3]
	_expect(shut_door["flags"].has("clear") and layout.locked_key_of(shut_door) == "ROOM_T4_BROKEN_RULE_YARD_LOCKED" and layout.text_key("NAME") == "ROOM_T4_BROKEN_RULE_YARD_NAME", "a door that waits for a clear gets the line ROOM_<ID>_LOCKED")

	# A crossing is one object across several cells.
	var with_crossing := good_text.replace("#......#.......#", "#......#.GGG...#").replace("[objects]\n", "[objects]\nG = traversal verb=chalk_path\n")
	var crossing_layout: RefCounted = RoomLayout.parse(with_crossing, "t4_broken_rule_yard")
	var crossings: Array[Dictionary] = []
	for placement in crossing_layout.placements():
		if placement["kind"] == "traversal":
			crossings.append(placement)
	_expect((crossing_layout.problems as PackedStringArray).is_empty() and crossings.size() == 1 and crossings[0]["cells"] == [Vector2i(9, 3), Vector2i(10, 3), Vector2i(11, 3)] and crossings[0]["name"] == "TraversalGap", "three neighbouring crossing cells in a row are ONE crossing, from its first cell")
	_expect(crossing_layout.kind_at(Vector2i(10, 3)) == CellKinds.GAP, "...and the cell under a crossing is a gap")
	var with_two_crossings := good_text.replace("#......#.......#", "#......#.G.G...#").replace("[objects]\n", "[objects]\nG = traversal verb=rule_step\n")
	var two_layout: RefCounted = RoomLayout.parse(with_two_crossings, "t4_broken_rule_yard")
	var crossing_names := PackedStringArray()
	for placement in two_layout.placements():
		if placement["kind"] == "traversal":
			crossing_names.append(placement["name"])
	_expect(crossing_names == PackedStringArray(["TraversalGap", "TraversalGap_2"]) and (two_layout.problems as PackedStringArray).is_empty(), "cells of one character that do not touch are separate crossings (two Rule Step holes), numbered TraversalGap and TraversalGap_2")

	# An unlock has a line only when it has words.
	var with_unlock := good_text.replace("#......#.......#", "#......#...U...#").replace("[objects]\n", "[objects]\nU = unlock id=rule_step text=\"The pawn learns to leap.\"\n")
	var unlock_layout: RefCounted = RoomLayout.parse(with_unlock, "t4_broken_rule_yard")
	var unlock_placement: Dictionary = {}
	for placement in unlock_layout.placements():
		if placement["kind"] == "unlock":
			unlock_placement = placement
	_expect((unlock_layout.problems as PackedStringArray).is_empty() and unlock_layout.unlock_key_of(unlock_placement) == "ROOM_T4_BROKEN_RULE_YARD_UNLOCK_RULE_STEP" and unlock_placement["name"] == "RuleStepUnlock", "an unlock with `text` gets the line ROOM_<ID>_UNLOCK_<ID> and is named after its verb")


func _check_every_mistake_is_named(good_text: String) -> void:
	var control: RefCounted = RoomLayout.parse(good_text, "t4_broken_rule_yard")
	_expect((control.problems as PackedStringArray).is_empty(), "control: the proof layout has no problem, so each change below is the only difference")

	# [room]
	_expect_problem(good_text.replace("id = t4_broken_rule_yard", "id = t5_other"), "the id is 't5_other' but the file is called t4_broken_rule_yard.txt", "an id that differs from the file name")
	_expect_problem(good_text.replace("id = t4_broken_rule_yard\n", ""), "[room] needs `id = ...`", "a missing required key")
	_expect_problem(good_text.replace("size = 16x9", "size = 20x9"), "size 20x9 must be between 8x7 and 18x9", "a board larger than an arena")
	_expect_problem(good_text.replace("size = 16x9", "size = wide"), "size reads WxH", "a size that is not WxH")
	_expect_problem(good_text.replace("act = 1", "act = 9"), "act 9 is not an act", "an act that does not exist")
	_expect_problem(good_text.replace("district = chess_rug", "district = attic"), "district 'attic' is not a district", "a district that does not exist")
	_expect_problem(good_text.replace("recipe = twist", "recipe = dance"), "recipe 'dance' is not one of: rest, teach, test, twist, boss", "a recipe that does not exist")
	_expect_problem(good_text.replace("status = greybox", "status = shiny"), "status 'shiny' is not one of: stub, greybox, dressed, final", "a status that does not exist")
	_expect_problem(good_text.replace("tileset = kingdom", "tileset = marble"), "tileset 'marble' is not a kit under content/tilesets/", "a tileset that does not exist")
	_expect_problem(good_text.replace("recipe = twist", "recipe = boss"), "a boss room is a checkpoint", "a boss room that is not a checkpoint")
	_expect_problem(good_text.replace("act = 1", "act = 1\nbanana = 3"), "[room] has no key 'banana'", "a key [room] does not have")
	_expect_problem(good_text.replace("act = 1", "act = 1\nact = 2"), "[room] sets 'act' twice", "a key set twice")
	_expect_problem(good_text.replace("[grid]", "[griddle]"), "the section [griddle] does not exist", "a section that does not exist")

	# [grid]
	_expect_problem(good_text.replace("#TE....#.......#", "#TE....#......#"), "row 5 is 15 characters wide, size is 16", "a row of the wrong width")
	_expect_problem(good_text.replace("#..............#\n################\n\n[objects]", "################\n\n[objects]"), "[grid] has 8 rows but size is 16x9", "a grid of the wrong height")
	_expect_problem(good_text.replace("#......#.......#", "#......#.Z.....#"), "cell (9, 3) holds 'Z', which is neither a terrain character nor defined in [objects]", "a character that is neither terrain nor an object")
	_expect_problem(good_text.replace("#TE....#.......#", ".TE....#.......#"), "the ring of the board must be wall", "a floor cell on the ring")
	_expect_problem(good_text.replace("#TE....#.......#", "ETE....#.......#"), "the object 'E' stands on the ring", "an object on the ring")
	_expect_problem(good_text.replace("P = pickup weapon=pencil_spear", "P = pickup weapon=pencil_spear\nQ = enemy def=pawn_recruit"), "'Q' is defined in [objects] (line", "an object that stands nowhere")

	# [objects]
	_expect_problem(good_text.replace("E = entry id=west_entry", "E = entry id=west_entry\nE = entry id=other"), "'E' is defined twice", "a character defined twice")
	_expect_problem(good_text.replace("R = enemy def=pawn_recruit", "r = enemy def=pawn_recruit"), "'r' cannot stand for an object: use a capital letter or a digit", "a lowercase object character")
	_expect_problem(good_text.replace("R = enemy def=pawn_recruit", "R = dragon def=pawn_recruit"), "'dragon' is not a kind of object", "an object of a kind that does not exist")
	_expect_problem(good_text.replace("R = enemy def=pawn_recruit", "R = enemy def=pawn_recruit speed=9"), "an object of kind enemy has no parameter 'speed'", "a parameter the kind does not take")
	_expect_problem(good_text.replace("R = enemy def=pawn_recruit", "R = enemy def=pawn_recruit stuck"), "an object of kind enemy has no flag 'stuck'", "a flag the kind does not take")
	_expect_problem(good_text.replace("R = enemy def=pawn_recruit", "R = enemy"), "an object of kind enemy needs def=...", "a required parameter that is missing")
	_expect_problem(good_text.replace("R = enemy def=pawn_recruit", "R = enemy def=dragon_king"), "def=dragon_king is not an enemy (content/enemies/ has:", "an enemy that is not in content/enemies/")
	_expect_problem(good_text.replace("P = pickup weapon=pencil_spear", "P = pickup weapon=banana_gun"), "weapon=banana_gun is not a pickup (content/pickups/ has:", "a pickup that is not in content/pickups/")
	_expect_problem(good_text.replace("T = exit to=t3_first_pawn_clash:from_t4", "T = exit to=t3_first_pawn_clash"), "to=t3_first_pawn_clash must read <room_id>:<entry_id>", "an exit target that is not room:entry")
	_expect_problem(good_text.replace("T = exit to=t3_first_pawn_clash:from_t4", "T = exit to=t4_broken_rule_yard:west_entry"), "leads to its own room", "a door to its own room")
	_expect_problem(good_text.replace(" clear locked=\"The black pawns still hold the yard. Break the black line first.\"", " clear"), "waits for a clear but gives no reason", "a shut door that does not say why")
	_expect_problem(good_text.replace("name=Exit_To_T3", "name=Exit_To_T3 locked=\"words\""), "only a door that waits for a clear can say why it is shut", "a locked line on a door that is not shut")
	_expect_problem(good_text.replace("name=Exit_To_T3", "name=Exit_To_T3 clear locked=\"Not yet.\""), "both use the line ROOM_T4_BROKEN_RULE_YARD_LOCKED: give the second its own locked_key=KEY", "two doors that both wait for a clear and say the same line")
	_expect_problem(good_text.replace("F = entry id=from_b1", "F = entry id=west_entry"), "repeats the entry id 'west_entry'", "two entries with one id")
	_expect_problem(good_text.replace("#TE....#.......#", "#TEE...#.......#"), "stands on 2 cells, but an object of kind entry may stand on one only", "an entry on two cells")
	_expect_problem(good_text.replace("[objects]\n", "[objects]\nD = pickup weapon=pencil_spear persistent\n").replace("#..............#\n################\n\n", "#.D..........D.#\n################\n\n"), "is a persistent pickup on 2 cells: the save keys it by its node name", "a persistent pickup on two cells")
	_expect_problem(good_text.replace("#TE....#.......#", "#T.....#.......#").replace("#............FX#", "#.............X#"), "the room has no entry", "a room with no entry on the grid")
	_expect_problem(good_text.replace("name=Exit_To_B1", "name=Exit_To_T3"), "two objects would be called Exit_To_T3: give one of them another name=", "two objects that are given one node name")

	# Reaching: a wall across the room cuts the far side off from the entry.
	_expect_problem(_with_wall_column(good_text, 11), "cannot be reached on foot from the entry Entry_West", "a wall across the room that cuts doors, enemies or the pickup off from an entry")

	# Crossings.
	var chalk := "[objects]\nG = traversal verb=chalk_path\n"
	_expect_problem(good_text.replace("#......#.R...P.#", "#......#.GGGG.P#").replace("[objects]\n", chalk), "covers 4 neighbouring cells in a line at (9, 2): a crossing is at most 3", "a crossing longer than Chalk Path reaches")
	_expect_problem(good_text.replace("#......#.R...P.#", "#......#.GG..P.#").replace("[objects]\n", "[objects]\nG = traversal verb=rule_step\n"), "is a Rule Step crossing 2 cells wide", "a Rule Step crossing wider than one cell")
	_expect_problem(good_text.replace("#......#.R...P.#", "#......#.GR..P.#").replace("[objects]\n", "[objects]\nG = traversal verb=fly\n"), "verb=fly does not cross a gap", "a crossing with a verb that does not cross a gap")

	# Gates and variants.
	_expect_problem(good_text.replace("#......#.......#", "#......#...W...#").replace("[objects]\n", "[objects]\nW = gate id=pass_gate opens=sideways\n"), "opens=sideways is not one of: left, right, up, down", "a gate that opens in a direction there is not")
	var with_variant := good_text.replace("#......#.......#", "#......#...V...#").replace("[objects]\n", "[objects]\nV = variant id=hub_state_1\n")
	_expect_problem(with_variant, "has no condition: give requires=... or forbids=...", "a variant with no condition")
	_expect_problem(with_variant.replace("variant id=hub_state_1", "variant id=hub_state_1 requires=Boss.Knight"), "requires holds 'Boss.Knight', which is not a flag id", "a variant that requires something that is not a flag id")
	var good_variant := RoomLayout.parse(with_variant.replace("variant id=hub_state_1", "variant id=hub_state_1 requires=boss.black_pawn_captain forbids=ending.boxed"), "t4_broken_rule_yard")
	_expect((good_variant.problems as PackedStringArray).is_empty(), "control: a variant with a valid condition is accepted")


## The proof layout with a column of wall at `column` from row 1 to row 7.
func _with_wall_column(layout_text: String, column: int) -> String:
	var grid_start := layout_text.find("[grid]\n") + 7
	var grid_end := layout_text.find("\n\n[objects]")
	var rows := layout_text.substr(grid_start, grid_end - grid_start).split("\n")
	for row_index in range(1, rows.size() - 1):
		rows[row_index] = rows[row_index].substr(0, column) + "#" + rows[row_index].substr(column + 1)
	return layout_text.substr(0, grid_start) + "\n".join(rows) + layout_text.substr(grid_end)


func _check_the_legend() -> void:
	var legend: String = RoomLayout.legend_text()
	for must_say in ["THE FORMAT", "[room] KEYS", "TERRAIN CHARACTERS", "OBJECT CHARACTERS", "floor", "wall", "gap", "leapable block", "chalk", "corruption", \
		"entry id=", "exit to=", "enemy def=", "pickup weapon=", "unlock id=", "gate id=", "traversal verb=", "variant id=", "checkpoint_on_entry"]:
		_expect(legend.contains(must_say), "the legend (printed by build_room.gd --legend) documents: %s" % must_say)
	for kind: String in RoomLayout.OBJECT_KINDS:
		_expect(legend.contains("= %s " % kind), "...every kind of object in the table, here '%s', has its line in the legend" % kind)
	for terrain_character: String in RoomLayout.TERRAIN_KIND_BY_CHARACTER:
		_expect(CellKinds.is_known(RoomLayout.TERRAIN_KIND_BY_CHARACTER[terrain_character]), "the terrain character '%s' stands for a cell kind CellKinds knows" % terrain_character)


func _expect_problem(layout_text: String, fragment: String, label: String) -> void:
	var layout: RefCounted = RoomLayout.parse(layout_text, "t4_broken_rule_yard")
	for problem: String in layout.problems:
		if problem.contains(fragment):
			_expect(true, "the reader can fail: %s" % label)
			return
	_expect(false, "the reader can fail: %s (no problem contains: %s; it said: %s)" % [label, fragment, " || ".join(layout.problems as PackedStringArray)])
