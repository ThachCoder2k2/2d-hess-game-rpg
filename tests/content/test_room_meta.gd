extends UnboundTest

## The meta every room carries on its RoomEncounter root (docs/game-base-plan.md 7.5, 15 M5): id, act, district,
## layout archetype, recipe, board size, content status, time of night, checkpoint flag, and (M5 step 3) the encounter meta: the
## objective kind, the threat in points and shapes at once, the intro flag and the intensity. Each field has a doc and an
## editor configuration warning, and `configuration_problems()` is the list the warnings show. This suite holds that
## a mistake in each field is told to the author, that the rooms of the game carry a complete and honest meta, and that
## the Inspector's dropdowns and the names the layout files use for the enums are one list.

const SHIPPED_ROOM_PATH := "res://content/rooms/some_room/room.tscn"


func _init() -> void:
	suite_title = "TEST ROOM META"
	_check_a_fresh_room()
	_check_every_field_can_complain()
	_check_the_threat_rules_the_inspector_applies()
	_check_a_shipped_room_is_held_to_more()
	_check_the_enums()
	_check_the_rooms_of_the_game()
	finish()


func _check_a_fresh_room() -> void:
	var room := RoomEncounter.new()
	_expect(room.act == 0 and room.district == &"" and room.layout_archetype == &"" and room.recipe == RoomEncounter.Recipe.REST \
		and room.content_status == RoomEncounter.ContentStatus.STUB and room.time_of_night == RoomEncounter.TimeOfNight.DUSK and not room.checkpoint_on_entry,
		"a room starts as a STUB of no act and no district, at dusk, that is not a checkpoint")
	_expect(room.objective_kind == RoomEncounter.ObjectiveKind.CLEAR and room.threat_budget == 0 and room.threat_shapes == 0 and not room.intro and room.intensity == 0,
		"...whose objective is clear, with no threat, no shapes, no intro flag and intensity 0")
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


## The threat rules of 5.3 the Inspector shows as warnings (R4, R18, R28): the same rule the lints of tests/ run over the plan's table.
func _check_the_threat_rules_the_inspector_applies() -> void:
	var room := RoomEncounter.new()
	room.act = 2
	room.recipe = RoomEncounter.Recipe.TEACH
	room.threat_budget = 4
	_expect(_any_contains(room.configuration_problems(), "A Teach room carries at most 3 threat (R4): threat_budget is 4"), "a Teach room above 3 threat is reported (R4)")
	room.threat_budget = 3
	_expect(room.configuration_problems().is_empty(), "...and a Teach room at 3 is clean")
	room.recipe = RoomEncounter.Recipe.TEST
	room.threat_budget = 2
	_expect(_any_contains(room.configuration_problems(), "A test room carries at least 3 threat (R18) unless it is flagged `intro`"), "a Test room under the floor of 3 is reported (R18)")
	room.intro = true
	_expect(room.configuration_problems().is_empty(), "...unless it is flagged intro (T3's single Recruit)")
	room.intro = false
	room.threat_budget = 7
	_expect(_any_contains(room.configuration_problems(), "A test room carries at most 6 threat (R18): threat_budget is 7"), "a Test room above 6 is reported, and the intro flag does not lift the ceiling")
	room.intro = true
	_expect(_any_contains(room.configuration_problems(), "at most 6 threat"), "...even for an intro room")
	room.intro = false
	room.threat_budget = 5
	room.recipe = RoomEncounter.Recipe.TWIST
	room.threat_shapes = 3
	_expect(_any_contains(room.configuration_problems(), "act 2 allows 2 threat shapes at once in a normal room (R28): threat_shapes is 3"), "three shapes at once in Act 2 are reported (R28: 2/2/2/2/3/4)")
	room.act = 5
	_expect(room.configuration_problems().is_empty(), "...and are fine in Act 5, where the cap is 3")
	room.recipe = RoomEncounter.Recipe.BOSS
	room.checkpoint_on_entry = true
	room.act = 2
	room.threat_shapes = 3
	room.threat_budget = 8
	_expect(room.configuration_problems().is_empty(), "a Boss room may carry 3 shapes in Act 2 (bosses 2/3/3/3/4/4) and a phase-1 budget above 6")
	room.threat_shapes = 4
	_expect(_any_contains(room.configuration_problems(), "act 2 allows 3 threat shapes at once in a boss room"), "...but not 4")
	room.threat_shapes = 0
	room.recipe = RoomEncounter.Recipe.SHORTCUT
	room.checkpoint_on_entry = false
	_expect(_any_contains(room.configuration_problems(), "A shortcut room holds no threat"), "a Shortcut room with threat is reported (a room of nothing to fear holds none)")
	room.threat_budget = 0
	room.intensity = 11
	_expect(_any_contains(room.configuration_problems(), "intensity 11 must be between 0 and 10"), "an intensity beyond 10 is reported")
	room.intensity = 10
	room.threat_budget = 13
	room.recipe = RoomEncounter.Recipe.BOSS
	room.checkpoint_on_entry = true
	_expect(_any_contains(room.configuration_problems(), "threat_budget 13 must be between 0 and 12"), "a budget beyond 12 is reported")
	room.free()
	# The caps are the plan's numbers: a constant edited by accident fails here and not silently in every lint.
	_expect(RoomEncounter.TEACH_THREAT_LIMIT == 3 and RoomEncounter.TEST_TWIST_THREAT_RANGE == Vector2i(3, 6) and RoomEncounter.ROOM_BEFORE_BOSS_THREAT_LIMIT == 6, "the budget caps are the plan's (5.3): Teach 3, Test and Twist 3 to 6, the room before a boss 6")
	_expect(RoomEncounter.SHAPES_AT_ONCE_BY_ACT == [2, 2, 2, 2, 3, 4] and RoomEncounter.BOSS_SHAPES_AT_ONCE_BY_ACT == [2, 3, 3, 3, 4, 4], "the shape caps are the plan's (R28): 2/2/2/2/3/4, bosses 2/3/3/3/4/4")


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
	_expect(RoomEncounter.ObjectiveKind.keys() == ["CLEAR", "REACH", "SURVIVE", "WAVES", "NONE"] and RoomEncounter.objective_kind_name(RoomEncounter.ObjectiveKind.SURVIVE) == "survive", "the objective kinds are the plan's (7.4 Obj): clear (the default, value 0), reach, survive, waves, none")
	_expect(RoomEncounter.TimeOfNight.keys()[0] == "DUSK" and RoomEncounter.TimeOfNight.keys()[-1] == "MORNING" and RoomEncounter.LAST_ACT == 7, "the night runs from dusk to morning, and the Ending is act 7 (D-06, D-31)")
	var room := RoomEncounter.new()
	var hint_of := {}
	for property in room.get_property_list():
		hint_of[property["name"]] = String(property["hint_string"])
	_expect(hint_of.get("content_status", "") == "Stub:0,Greybox:1,Dressed:2,Final:3", "the Inspector offers the status as a dropdown of the ladder (%s)" % hint_of.get("content_status", ""))
	_expect(hint_of.get("time_of_night", "") == "Dusk:0,Evening:1,Night:2,Small Hours:3,Dawn:4,Morning:5" and String(hint_of.get("recipe", "")).begins_with("Rest:0,Teach:1,Test:2,Twist:3,Boss:4,Shortcut:5"), "...and the time of night and the recipe as dropdowns in the order of their enums (%s | %s)" % [hint_of.get("time_of_night", ""), hint_of.get("recipe", "")])
	_expect(hint_of.get("objective_kind", "") == "Clear:0,Reach:1,Survive:2,Waves:3,None:4", "...and the objective kind as a dropdown (%s)" % hint_of.get("objective_kind", ""))
	var group_of_threat := false
	for property in room.get_property_list():
		if property["name"] == "Encounter meta" and property["usage"] & PROPERTY_USAGE_GROUP != 0:
			group_of_threat = true
	_expect(group_of_threat, "the five encounter fields sit together under an Encounter meta group in the Inspector")
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
