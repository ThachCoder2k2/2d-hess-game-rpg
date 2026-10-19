extends UnboundTest

## The meta every room carries on its RoomEncounter root (docs/game-base-plan.md 7.5, 15 M5): id, act, district,
## layout archetype, recipe, board size, content status, time of night, checkpoint flag. Each field has a doc and an
## editor configuration warning, and `configuration_problems()` is the list the warnings show. This suite holds that
## a mistake in each field is told to the author, that the rooms of the game carry a complete and honest meta, and that
## the Inspector's dropdowns and the names the layout files use for the enums are one list.

const SHIPPED_ROOM_PATH := "res://content/rooms/some_room/room.tscn"


func _init() -> void:
	suite_title = "TEST ROOM META"
	_check_a_fresh_room()
	_check_every_field_can_complain()
	_check_a_shipped_room_is_held_to_more()
	_check_the_enums()
	_check_the_rooms_of_the_game()
	finish()


func _check_a_fresh_room() -> void:
	var room := RoomEncounter.new()
	_expect(room.act == 0 and room.district == &"" and room.layout_archetype == &"" and room.recipe == RoomEncounter.Recipe.REST \
		and room.content_status == RoomEncounter.ContentStatus.STUB and room.time_of_night == RoomEncounter.TimeOfNight.DUSK and not room.checkpoint_on_entry,
		"a room starts as a STUB of no act and no district, at dusk, that is not a checkpoint")
	_expect(room.configuration_problems().is_empty() and room._get_configuration_warnings().is_empty(), "a scene that is not in content/rooms/ (a fixture, a sketch) is only held to the rules that never change, and the editor warnings are the same list")
	room.free()


func _check_every_field_can_complain() -> void:
	var room := RoomEncounter.new()
	room.board_size = Vector2i(19, 9)
	_expect(_any_contains(room.configuration_problems(), "board_size (19, 9) must be between (8, 7) and (18, 9)"), "a board wider than an arena is reported")
	room.board_size = Vector2i(16, 10)
	_expect(_any_contains(room.configuration_problems(), "board_size (16, 10)"), "a board taller than the screen is reported")
	room.board_size = Vector2i(7, 7)
	_expect(_any_contains(room.configuration_problems(), "board_size (7, 7)"), "a board smaller than an arena is reported")
	room.board_size = Vector2i(18, 9)
	_expect(room.configuration_problems().is_empty(), "an 18x9 arena is fine")
	room.act = 8
	_expect(_any_contains(room.configuration_problems(), "act 8 is not an act"), "an act beyond the Ending is reported")
	room.act = 7
	room.district = &"attic"
	var district_problems := room.configuration_problems()
	_expect(_any_contains(district_problems, "district 'attic' is not a district") and _any_contains(district_problems, "chess_rug") and _any_contains(district_problems, "under_bed"), "an unknown district is reported with the districts there are")
	room.district = &"desk"
	room.layout_archetype = &"Winding Path"
	_expect(_any_contains(room.configuration_problems(), "layout_archetype 'Winding Path' must be lowercase snake_case"), "an archetype with a capital or a space is reported")
	room.layout_archetype = &"winding"
	room.room_message = "A fence of toy blocks."
	_expect(_any_contains(room.configuration_problems(), "room_message must be a text key"), "words in place of a text key are reported (every player-facing word is a key, 8.9)")
	room.room_message = "ROOM_X_START"
	room.recipe = RoomEncounter.Recipe.BOSS
	_expect(_any_contains(room.configuration_problems(), "A boss room is a checkpoint"), "a boss room that is not a checkpoint is reported (D-16)")
	room.checkpoint_on_entry = true
	room.recipe = RoomEncounter.Recipe.REST
	room.layout_archetype = &"hub"
	room.checkpoint_on_entry = false
	_expect(_any_contains(room.configuration_problems(), "A hub is a checkpoint"), "a hub that is not a checkpoint is reported (D-16)")
	room.checkpoint_on_entry = true
	_expect(room.configuration_problems().is_empty(), "and a boss room or a hub that is a checkpoint, with the rest in order, is clean")
	room.free()


func _check_a_shipped_room_is_held_to_more() -> void:
	var room := RoomEncounter.new()
	room.scene_file_path = SHIPPED_ROOM_PATH
	var problems := room.configuration_problems()
	_expect(_any_contains(problems, "zone_id is '' but the room lives in content/rooms/some_room/") and _any_contains(problems, "needs a room_message") and _any_contains(problems, "belongs to an act") \
		and _any_contains(problems, "belongs to a district") and _any_contains(problems, "has a layout archetype"), "a room under content/rooms/ needs an id equal to its folder, a start line, an act, a district and an archetype")
	room.zone_id = &"some_room"
	room.room_message = "ROOM_SOME_ROOM_START"
	room.act = 2
	room.district = &"toybox"
	room.layout_archetype = &"fence"
	_expect(room.configuration_problems().is_empty(), "with those five set, the shipped room is clean")
	room.zone_id = &"another_room"
	_expect(_any_contains(room.configuration_problems(), "zone_id is 'another_room' but the room lives in content/rooms/some_room/"), "an id that differs from the folder is reported")
	room.free()


## The Inspector's dropdowns come from the enums; the layout files and the tools spell them in lowercase.
func _check_the_enums() -> void:
	_expect(RoomEncounter.ContentStatus.keys() == ["STUB", "GREYBOX", "DRESSED", "FINAL"], "the content status ladder is the plan's (1.3): STUB, GREYBOX, DRESSED, FINAL, in that order")
	_expect(RoomEncounter.status_name(RoomEncounter.ContentStatus.GREYBOX) == "greybox" and RoomEncounter.recipe_name(RoomEncounter.Recipe.SHORTCUT) == "shortcut" and RoomEncounter.time_of_night_name(RoomEncounter.TimeOfNight.SMALL_HOURS) == "small_hours", "the tools spell a status, a recipe and a time of night in lowercase")
	_expect(RoomEncounter.Recipe.keys().slice(0, 6) == ["REST", "TEACH", "TEST", "TWIST", "BOSS", "SHORTCUT"] and RoomEncounter.Recipe.has("OPTIONAL") and RoomEncounter.Recipe.has("ENDING"), "the recipes start with the formula of 7.5: Rest, Teach, Test, Twist, Boss, Shortcut")
	_expect(RoomEncounter.TimeOfNight.keys()[0] == "DUSK" and RoomEncounter.TimeOfNight.keys()[-1] == "MORNING" and RoomEncounter.LAST_ACT == 7, "the night runs from dusk to morning, and the Ending is act 7 (D-06, D-31)")
	var room := RoomEncounter.new()
	var hint_of := {}
	for property in room.get_property_list():
		hint_of[property["name"]] = String(property["hint_string"])
	_expect(hint_of.get("content_status", "") == "Stub:0,Greybox:1,Dressed:2,Final:3", "the Inspector offers the status as a dropdown of the ladder (%s)" % hint_of.get("content_status", ""))
	_expect(hint_of.get("time_of_night", "") == "Dusk:0,Evening:1,Night:2,Small Hours:3,Dawn:4,Morning:5" and String(hint_of.get("recipe", "")).begins_with("Rest:0,Teach:1,Test:2,Twist:3,Boss:4,Shortcut:5"), "...and the time of night and the recipe as dropdowns in the order of their enums (%s | %s)" % [hint_of.get("time_of_night", ""), hint_of.get("recipe", "")])
	room.free()


## The rooms the game ships carry a complete meta, and it is the honest one.
func _check_the_rooms_of_the_game() -> void:
	var graph := ContentDb.world()
	var meta_by_room: Dictionary[StringName, RoomScan] = {}
	for room_id in graph.room_ids():
		var scan := RoomScan.of(graph.get_zone_scene(room_id))
		meta_by_room[room_id] = scan
		_expect(scan.configuration_problems.is_empty(), "%s: no configuration warning (%s)" % [room_id, "; ".join(scan.configuration_problems)])
		_expect(scan.act >= 1 and scan.district in WorldGraph.DISTRICT_IDS and not scan.layout_archetype.is_empty() and not scan.start_message_key.is_empty(), "%s: carries an act, a district, an archetype and a start line" % room_id)
	for stage_one in [&"t1_white_kings_fall", &"t2_fallen_sword_tile", &"t3_first_pawn_clash", &"t4_broken_rule_yard", &"b1_black_pawn_captain", &"h1_chess_rug_hub"]:
		var scan: RoomScan = meta_by_room[stage_one]
		_expect(scan.act == 1 and scan.district == &"chess_rug" and scan.status_name == "greybox", "%s: Act 1, the chess rug, GREYBOX (playable, real enemies, placeholder look)" % stage_one)
	var recipe_by_room := {
		&"t1_white_kings_fall": "rest", &"t2_fallen_sword_tile": "teach", &"t3_first_pawn_clash": "test",
		&"t4_broken_rule_yard": "twist", &"b1_black_pawn_captain": "boss", &"h1_chess_rug_hub": "rest",
	}
	for room_id: StringName in recipe_by_room:
		_expect(meta_by_room[room_id].recipe_name == recipe_by_room[room_id], "%s: its recipe is %s, as 7.4 has it" % [room_id, recipe_by_room[room_id]])
	_expect(meta_by_room[&"b1_black_pawn_captain"].checkpoint_on_entry and meta_by_room[&"h1_chess_rug_hub"].checkpoint_on_entry and meta_by_room[&"h1_chess_rug_hub"].layout_archetype == &"hub", "the boss room and the hub are checkpoints (D-16)")
	_expect(meta_by_room[&"tb1_toybox_gate"].status_name == "stub" and meta_by_room[&"tb1_toybox_gate"].act == 2 and meta_by_room[&"tb1_toybox_gate"].district == &"toybox", "tb1 is the Act 2 stub the builder made")


func _any_contains(sentences: PackedStringArray, fragment: String) -> bool:
	for sentence in sentences:
		if sentence.contains(fragment):
			return true
	return false
