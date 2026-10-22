extends RefCounted

## The rooms of docs/game-base-plan.md 7.4 as data, the fixture the room suites check the shipped rooms against (M5 step 2; the
## lints of step 3 read the same table). NOT a test (the runner only collects test_*.gd) and without a class_name: suites load it with
##   const PlanRoomTable := preload("res://tests/fixtures/plan_room_table.gd")
##
## One row per shipping room, in route order. `enemies` is the pieces the room parks, by enemy id, in no order (null = not
## asserted: the six Stage 1 rooms are hand-made and held by their dump baselines); `clear_doors` is how many of its doors wait for
## the room to be cleared. The sandbox of M6 (dev_sandbox) is not a shipping room and is not here.

const ROWS: Array[Dictionary] = [
	{"id": &"t1_white_kings_fall", "size": Vector2i(16, 9), "archetype": &"winding", "recipe": "rest", "act": 1, "district": &"chess_rug", "enemies": null, "clear_doors": 0},
	{"id": &"t2_fallen_sword_tile", "size": Vector2i(16, 9), "archetype": &"open", "recipe": "teach", "act": 1, "district": &"chess_rug", "enemies": null, "clear_doors": 0},
	{"id": &"t3_first_pawn_clash", "size": Vector2i(16, 9), "archetype": &"split", "recipe": "test", "act": 1, "district": &"chess_rug", "enemies": null, "clear_doors": 1},
	{"id": &"t4_broken_rule_yard", "size": Vector2i(16, 9), "archetype": &"yard", "recipe": "twist", "act": 1, "district": &"chess_rug", "enemies": null, "clear_doors": 1},
	{"id": &"b1_black_pawn_captain", "size": Vector2i(16, 9), "archetype": &"arena", "recipe": "boss", "act": 1, "district": &"chess_rug", "enemies": null, "clear_doors": 1},
	{"id": &"h1_chess_rug_hub", "size": Vector2i(16, 9), "archetype": &"hub", "recipe": "rest", "act": 1, "district": &"chess_rug", "enemies": [], "clear_doors": 0},

	{"id": &"tb1_toybox_gate", "size": Vector2i(16, 9), "archetype": &"fence", "recipe": "teach", "act": 2, "district": &"toybox", "enemies": [&"knight_tracker", &"pawn_recruit"], "clear_doors": 0},
	{"id": &"tb2_l_jump_lanes", "size": Vector2i(16, 9), "archetype": &"lanes", "recipe": "test", "act": 2, "district": &"toybox", "enemies": [&"knight_tracker", &"charging_pawn"], "clear_doors": 0},
	{"id": &"tb3_toy_track_ambush", "size": Vector2i(16, 9), "archetype": &"track", "recipe": "twist", "act": 2, "district": &"toybox", "enemies": [&"knight_tracker"], "clear_doors": 0},
	{"id": &"tbb_knight_captain", "size": Vector2i(18, 9), "archetype": &"arena", "recipe": "boss", "act": 2, "district": &"toybox", "enemies": [&"knight_captain", &"pawn_recruit"], "clear_doors": 1},
	{"id": &"tb4_lid_path", "size": Vector2i(16, 9), "archetype": &"path", "recipe": "shortcut", "act": 2, "district": &"toybox", "enemies": [], "clear_doors": 0},
	{"id": &"tbo_crayon_cache", "size": Vector2i(16, 9), "archetype": &"nook", "recipe": "optional", "act": 2, "district": &"toybox", "enemies": [], "clear_doors": 0},

	{"id": &"bs1_book_spine_steps", "size": Vector2i(16, 9), "archetype": &"stairs", "recipe": "teach", "act": 3, "district": &"bookshelf", "enemies": [&"bishop_zoner", &"pawn_recruit", &"backstep_pawn"], "clear_doors": 0},
	{"id": &"bs2_diagonal_chapel", "size": Vector2i(16, 9), "archetype": &"chapel", "recipe": "test", "act": 3, "district": &"bookshelf", "enemies": [&"bishop_zoner", &"bishop_zoner"], "clear_doors": 0},
	{"id": &"bs3_torn_page_bridge", "size": Vector2i(16, 9), "archetype": &"bridge", "recipe": "twist", "act": 3, "district": &"bookshelf", "enemies": [&"bishop_zoner", &"charging_pawn"], "clear_doors": 0},
	{"id": &"bsb_bishop_oracle", "size": Vector2i(18, 9), "archetype": &"islands", "recipe": "boss", "act": 3, "district": &"bookshelf", "enemies": [&"bishop_oracle", &"pawn_recruit"], "clear_doors": 1},
	{"id": &"bs4_page_tear_shortcut", "size": Vector2i(16, 9), "archetype": &"tear", "recipe": "shortcut", "act": 3, "district": &"bookshelf", "enemies": [], "clear_doors": 0},
	{"id": &"bso_margin_nook", "size": Vector2i(16, 9), "archetype": &"nook", "recipe": "optional", "act": 3, "district": &"bookshelf", "enemies": [], "clear_doors": 0},

	{"id": &"bt1_block_yard", "size": Vector2i(16, 9), "archetype": &"yard", "recipe": "teach", "act": 4, "district": &"block_tower", "enemies": [&"wooden_rook", &"pawn_recruit", &"pawn_recruit"], "clear_doors": 0},
	{"id": &"bt2_ruler_bridge", "size": Vector2i(16, 9), "archetype": &"bridge", "recipe": "twist", "act": 4, "district": &"block_tower", "enemies": [&"wooden_rook", &"pawn_recruit"], "clear_doors": 0},
	{"id": &"bt3_breakable_wall_test", "size": Vector2i(16, 9), "archetype": &"wall", "recipe": "test", "act": 4, "district": &"block_tower", "enemies": [&"iron_rook", &"pawn_recruit"], "clear_doors": 0},
	{"id": &"btb_rook_warden", "size": Vector2i(18, 9), "archetype": &"arena", "recipe": "boss", "act": 4, "district": &"block_tower", "enemies": [&"rook_warden", &"pawn_recruit"], "clear_doors": 1},
	{"id": &"bt4_ruler_gate_shortcut", "size": Vector2i(16, 9), "archetype": &"gate", "recipe": "shortcut", "act": 4, "district": &"block_tower", "enemies": [], "clear_doors": 0},
	{"id": &"bto_rubble_nook", "size": Vector2i(16, 9), "archetype": &"nook", "recipe": "optional", "act": 4, "district": &"block_tower", "enemies": [], "clear_doors": 0},

	{"id": &"dh1_foyer", "size": Vector2i(16, 9), "archetype": &"foyer", "recipe": "rest", "act": 5, "district": &"dollhouse", "enemies": [], "clear_doors": 0},
	{"id": &"dh2_mixed_court", "size": Vector2i(16, 9), "archetype": &"court", "recipe": "test", "act": 5, "district": &"dollhouse", "enemies": [&"knight_tracker", &"bishop_zoner"], "clear_doors": 0},
	{"id": &"dh3_royal_stage", "size": Vector2i(16, 9), "archetype": &"stage", "recipe": "twist", "act": 5, "district": &"dollhouse", "enemies": [&"wooden_rook", &"pawn_recruit"], "clear_doors": 0},
	{"id": &"dhb_queen_of_tricks", "size": Vector2i(18, 9), "archetype": &"arena", "recipe": "boss", "act": 5, "district": &"dollhouse", "enemies": [&"queen_of_tricks", &"pawn_recruit"], "clear_doors": 1},
	{"id": &"dh4_seal_stair", "size": Vector2i(16, 9), "archetype": &"stair", "recipe": "shortcut", "act": 5, "district": &"dollhouse", "enemies": [], "clear_doors": 0},

	{"id": &"ub1_castle_gate", "size": Vector2i(16, 9), "archetype": &"gate", "recipe": "rest", "act": 6, "district": &"under_bed", "enemies": [], "clear_doors": 0},
	{"id": &"ub2_last_board", "size": Vector2i(18, 9), "archetype": &"waves", "recipe": "test", "act": 6, "district": &"under_bed", "enemies": [&"pawn_recruit", &"knight_tracker", &"pawn_armed", &"bishop_zoner"], "clear_doors": 1},
	{"id": &"ub3_rule_engine", "size": Vector2i(16, 9), "archetype": &"engine", "recipe": "twist", "act": 6, "district": &"under_bed", "enemies": [&"pawn_recruit"], "clear_doors": 0},
	{"id": &"ubb_black_king", "size": Vector2i(18, 9), "archetype": &"arena", "recipe": "boss", "act": 6, "district": &"under_bed", "enemies": [&"black_king", &"pawn_recruit"], "clear_doors": 1},

	{"id": &"e1_morning_desk", "size": Vector2i(16, 9), "archetype": &"desk", "recipe": "ending", "act": 7, "district": &"desk", "enemies": [], "clear_doors": 0},
]

## The critical path in the order a player walks it (plan 7.2): the rooms of each stretch, the hub between the districts. The optional
## nooks are off it.
const CRITICAL_PATH: Array[StringName] = [
	&"t1_white_kings_fall", &"t2_fallen_sword_tile", &"t3_first_pawn_clash", &"t4_broken_rule_yard", &"b1_black_pawn_captain", &"h1_chess_rug_hub",
	&"tb1_toybox_gate", &"tb2_l_jump_lanes", &"tb3_toy_track_ambush", &"tbb_knight_captain", &"tb4_lid_path", &"h1_chess_rug_hub",
	&"bs1_book_spine_steps", &"bs2_diagonal_chapel", &"bs3_torn_page_bridge", &"bsb_bishop_oracle", &"bs4_page_tear_shortcut", &"h1_chess_rug_hub",
	&"bt1_block_yard", &"bt2_ruler_bridge", &"bt3_breakable_wall_test", &"btb_rook_warden", &"bt4_ruler_gate_shortcut", &"h1_chess_rug_hub",
	&"dh1_foyer", &"dh2_mixed_court", &"dh3_royal_stage", &"dhb_queen_of_tricks", &"dh4_seal_stair", &"h1_chess_rug_hub",
	&"ub1_castle_gate", &"ub2_last_board", &"ub3_rule_engine", &"ubb_black_king", &"e1_morning_desk",
]

## The boss of each arena: the room -> the enemy id whose fall sets `boss.<id>`.
const BOSS_OF_ROOM := {
	&"b1_black_pawn_captain": &"black_pawn_captain",
	&"tbb_knight_captain": &"knight_captain",
	&"bsb_bishop_oracle": &"bishop_oracle",
	&"btb_rook_warden": &"rook_warden",
	&"dhb_queen_of_tricks": &"queen_of_tricks",
	&"ubb_black_king": &"black_king",
}


static func row_of(room_id: StringName) -> Dictionary:
	for row in ROWS:
		if row["id"] == room_id:
			return row
	return {}
