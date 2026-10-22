extends UnboundTest

## The two marker schemas M5 adds (docs/game-base-plan.md 5.7, 7.3, 8.5): TraversalGapMarker, a mandatory crossing, and
## StateVariantMarker, a prop that shows only in a state. Both are DATA at M5: the Inspector fields, the editor's
## configuration warnings, and for the crossing the one thing the baker does with it (EcsBoot copies it to each
## cell it covers in the grid's marker store); the behaviour (the verbs that cross a gap, the flag that shows a prop)
## arrives with M7, M10 and M6. This suite holds what the data says and that a mistake is told to the author. It also
## holds the fix that lets a marker of an 18x9 arena land on the cell it says (GridMarker follows its room's board).

const TRAVERSAL_GAP_KIND := &"traversal_gap"


func _init() -> void:
	suite_title = "TEST MARKER SCHEMAS"
	_check_the_crossing_data()
	_check_the_crossing_warnings()
	_check_the_baker()
	_check_the_variant_data()
	_check_the_variant_warnings()
	_check_markers_follow_the_rooms_board()
	finish()


# --------------------------------------------------------------------------- TraversalGapMarker
func _check_the_crossing_data() -> void:
	var gap := TraversalGapMarker.new()
	_expect(gap.verb == &"chalk_path" and gap.length == 1 and gap.direction == Vector2i.RIGHT and gap.free_when_calm, "a crossing starts as a free one-cell Chalk Path crossing running to the right")
	gap.grid_cell = Vector2i(5, 4)
	gap.length = 3
	gap.direction = Vector2i.DOWN
	_expect(gap.get_cells() == [Vector2i(5, 4), Vector2i(5, 5), Vector2i(5, 6)], "it covers `length` cells from grid_cell along `direction`")
	var baked := gap.get_baked_data()
	_expect(baked["verb"] == &"chalk_path" and baked["free_when_calm"] == true and baked["first_cell"] == Vector2i(5, 4) and baked["length"] == 3 and baked["direction"] == Vector2i.DOWN, "its baked data says the verb, whether the cast is free while calm, and where the whole crossing starts and runs")
	_expect(TraversalGapMarker.VERBS == [&"chalk_path", &"rule_step"] and TraversalGapMarker.MAX_LENGTH == 3 and TraversalGapMarker.KIND == TRAVERSAL_GAP_KIND, "the verbs that cross a gap, the longest crossing (3 cells, §6.3) and the grid key are the plan's")
	gap.free()


func _check_the_crossing_warnings() -> void:
	var gap := TraversalGapMarker.new()
	_expect(gap.configuration_problems().is_empty() and gap._get_configuration_warnings().is_empty(), "a default crossing has nothing to warn about, and the editor warnings are the same list")
	gap.verb = &"fly"
	_expect(_any_contains(gap.configuration_problems(), "verb 'fly' does not cross a gap"), "an unknown verb is reported")
	gap.verb = &"chalk_path"
	gap.length = 4
	_expect(_any_contains(gap.configuration_problems(), "length 4 is out of range"), "a crossing longer than Chalk Path reaches is reported")
	gap.length = 2
	gap.verb = &"rule_step"
	_expect(_any_contains(gap.configuration_problems(), "A Rule Step clears a one-cell hole"), "a Rule Step crossing wider than one cell is reported")
	gap.verb = &"chalk_path"
	gap.direction = Vector2i(1, 1)
	_expect(_any_contains(gap.configuration_problems(), "must be a straight cardinal step"), "a diagonal or zero direction is reported")
	gap.direction = Vector2i.RIGHT
	gap.grid_cell = Vector2i(15, 4)
	_expect(_any_contains(gap.configuration_problems(), "off the 16 x 9 board"), "a crossing that runs off the board is reported (the default board is 16x9)")
	gap.free()


## The baker copies the marker to every cell it covers; a cell off the board is refused by the grid; another kind of
## marker on the same cell does not collide.
func _check_the_baker() -> void:
	var room := _room(Vector2i(16, 9))
	var gap := TraversalGapMarker.new()
	gap.name = "TraversalGap"
	gap.grid_cell = Vector2i(5, 4)
	gap.length = 3
	gap.verb = &"chalk_path"
	room.add_child(gap)
	var world := EcsWorld.new()
	EcsBoot.boot(world, EcsBootOptions.for_scene(null, room))
	for cell in gap.get_cells():
		_expect(world.grid.has_marker(TRAVERSAL_GAP_KIND, cell), "the booted grid holds the crossing on %s" % cell)
	_expect(world.grid.marker_cells(TRAVERSAL_GAP_KIND) == [Vector2i(5, 4), Vector2i(6, 4), Vector2i(7, 4)], "and on those cells only")
	var data := world.grid.marker_at(TRAVERSAL_GAP_KIND, Vector2i(6, 4))
	_expect(data.get("verb") == &"chalk_path" and data.get("first_cell") == Vector2i(5, 4) and data.get("length") == 3 and data.get("marker_name") == "TraversalGap", "a middle cell knows the whole crossing it belongs to")
	_expect(not world.grid.has_marker(&"trigger", Vector2i(5, 4)), "a crossing is not another kind of marker")
	room.free()
	world.free()


# --------------------------------------------------------------------------- StateVariantMarker
func _check_the_variant_data() -> void:
	var variant := StateVariantMarker.new()
	variant.variant_id = &"hub_state_1"
	variant.requires_flags = [&"boss.black_pawn_captain"]
	variant.forbids_flags = [&"ending.boxed"]
	_expect(variant.is_shown_with([&"boss.black_pawn_captain"]), "a variant is shown when every required flag is set and no forbidden one is")
	_expect(not variant.is_shown_with([]), "...not when a required flag is missing")
	_expect(not variant.is_shown_with([&"boss.black_pawn_captain", &"ending.boxed"]), "...and not when a forbidden flag is set")
	var only_forbids := StateVariantMarker.new()
	only_forbids.variant_id = &"before_the_lid"
	only_forbids.forbids_flags = [&"under_bed.entered"]
	_expect(only_forbids.is_shown_with([]) and not only_forbids.is_shown_with([&"under_bed.entered"]), "a variant with only a forbidden flag shows until that flag is set")
	variant.free()
	only_forbids.free()


func _check_the_variant_warnings() -> void:
	var variant := StateVariantMarker.new()
	_expect(_any_contains(variant.configuration_problems(), "variant_id '' must be lowercase snake_case") and _any_contains(variant.configuration_problems(), "has no condition"), "a variant with no id and no condition is reported twice")
	variant.variant_id = &"Hub State"
	_expect(_any_contains(variant.configuration_problems(), "variant_id 'Hub State' must be lowercase snake_case"), "an id with a capital or a space is reported")
	variant.variant_id = &"clue_2"
	variant.requires_flags = [&"clue.second_mug", &"Bad Flag"]
	variant.forbids_flags = [&"clue.second_mug", &"also bad"]
	var problems := variant.configuration_problems()
	_expect(_any_contains(problems, "requires_flags holds 'Bad Flag'") and _any_contains(problems, "forbids_flags holds 'also bad'"), "a flag that is not a flag id is reported in either list")
	_expect(_any_contains(problems, "The flag 'clue.second_mug' is both required and forbidden"), "a flag in both lists is reported: the prop could never show")
	variant.requires_flags = [&"clue.second_mug"]
	variant.forbids_flags = []
	_expect(variant.configuration_problems().is_empty() and variant._get_configuration_warnings().is_empty(), "a variant with an id and a valid condition is clean, and the editor warnings are the same list")
	variant.free()


# --------------------------------------------------------------------------- GridMarker and the 18x9 arena
## A marker of a room follows the room's board: in an 18x9 arena the board starts at x 32, not 64, so a unlock marker
## on cell (17, 8) must stand on (17, 8). Before M5 it stood one cell too far to the right.
func _check_markers_follow_the_rooms_board() -> void:
	var arena := _room(Vector2i(18, 9))
	root.add_child(arena)
	var unlock := (load("res://authoring/markers/player_unlock_marker.tscn") as PackedScene).instantiate() as PlayerUnlockMarker
	arena.add_child(unlock)
	unlock.grid_cell = Vector2i(17, 8)
	var world := EcsWorld.new()
	EcsBoot.shape_grid(world, arena)
	_expect(world.grid.grid_origin == Vector2(32, 36), "setup: an 18x9 arena starts at (32, 36)")
	_expect(world.grid.world_to_cell(unlock.position) == Vector2i(17, 8), "a marker set to cell (17, 8) of an 18x9 arena stands on it (it stood on (18, 8) when it assumed the 16x9 origin)")
	_expect(unlock.board_cells() == Vector2i(18, 9) and unlock.board_origin() == Vector2(32, 36), "it asks its room for the board and the origin")
	unlock.position = world.grid.cell_to_world(Vector2i(3, 2))
	_expect(unlock._position_to_grid_cell(unlock.position) == Vector2i(3, 2) and unlock._position_to_grid_cell(Vector2(5000, 5000)) == Vector2i(17, 8), "dragging it in the editor snaps it to a cell of the arena and clamps it to the arena's last cell")
	arena.queue_free()
	world.free()

	var loose := (load("res://authoring/markers/player_unlock_marker.tscn") as PackedScene).instantiate() as PlayerUnlockMarker
	loose.grid_cell = Vector2i(2, 3)
	_expect(loose.board_cells() == Vector2i(16, 9) and loose.position == Vector2(64 + 2 * 32 + 16, 36 + 3 * 32 + 16), "a marker with no room above it keeps the 16x9 default and the (64, 36) origin it always used")
	loose.free()


# --------------------------------------------------------------------------- helpers
func _room(board: Vector2i) -> RoomEncounter:
	var room := RoomEncounter.new()
	room.board_size = board
	return room


func _any_contains(sentences: PackedStringArray, fragment: String) -> bool:
	for sentence in sentences:
		if sentence.contains(fragment):
			return true
	return false
