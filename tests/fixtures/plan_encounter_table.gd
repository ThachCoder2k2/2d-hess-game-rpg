extends RefCounted

## The encounter columns of docs/game-base-plan.md 7.4 as data: the fixture the lints of M5 step 3 run against (`test_preview_before_lethal`,
## `test_threat_budget`, `test_room_data_audit`, `test_enemy_placement`, `test_district_loops`, `test_reward_cadence`; plan 7.4 says the
## Threat/shapes column "is the lint fixture of R4, R18 and R28 ... run against this table in M5, before any room is built"). NOT a test
## (the runner only collects test_*.gd) and without a class_name: suites load it with
##   const PlanEncounterTable := preload("res://tests/fixtures/plan_encounter_table.gd")
##
## tests/fixtures/plan_room_table.gd is the other half: what the shipped stubs ARE (size, archetype, the pieces they park). This one is what
## the plan DESIGNS: the pieces that are live together, the fenced previews, the objective, the intensity, the rewards, the minutes. Rooms are
## keyed by the same ids, in the same route order, and the two files must agree on the ids (test_room_data_audit says so).
##
## A row, by key:
##   id          the room id.
##   objective   the Obj column: clear, reach, survive, waves, none.
##   live        the pieces that are live together, by enemy id, plus the hazards named in HAZARD_POINTS. A boss room lists its boss only: the
##               boss's threat_points IS its phase-1 budget. A waves room leaves it empty and lists `waves`.
##   waves       a gauntlet's waves, each a list like `live` (ub2 only).
##   fenced      the shape families shown FENCED (telegraph-only, harmless) in the room: knight, bishop, rook, queen, king.
##   intro       the room is a first lesson of one piece (T3): exempt from the Test floor of the threat budget.
##   verbs       the verbs the room gives (an unlock); a Teach room may introduce at most one verb or shape (R4).
##   threat      the plan's Threat number (the table's `5/2` is threat 5, shapes 2); a boss row says nothing, so it carries its phase-1 budget.
##   shapes      the plan's shapes number; 0 where the plan states none (a boss: M8b).
##   teaches     what the room teaches or examines (the Gate, exam column), in a few words.
##   emotion     the room's feeling (the Emotion column).
##   intensity   the Int column (R32).
##   minutes     the Min column: the first-play estimate the route bot's measurements are set beside (D-03).
##   rewards     the persistent rewards the room hands over at its end: [kind, what]. The kinds R37 counts are in REWARD_KINDS.
##   mid_rewards earned story beats INSIDE a long fight: [kind, what, fraction of the room's minutes at which it lands].

## The shape each piece throws (plan 5.3 Tell column, R28: "each shape has a pattern as well as a colour"). Two pieces that throw the same
## shape count once when they are live together; the Backstep Pawn bends how a pawn MOVES, not what it throws; the Iron Rook's armor is a
## defence. Becomes `AttackPattern.shape_id` data with M8a, when the encounter audit reads the definitions instead of this map.
const SHAPE_OF_PIECE := {
	&"pawn_recruit": &"diagonal_slash", &"backstep_pawn": &"diagonal_slash", &"pawn_armed": &"straight_bar", &"charging_pawn": &"charge_line",
	&"knight_tracker": &"knight_landing", &"bishop_zoner": &"diagonal_lane", &"wooden_rook": &"rook_line", &"iron_rook": &"rook_line",
	&"black_pawn_captain": &"diagonal_slash", &"knight_captain": &"knight_landing", &"bishop_oracle": &"diagonal_lane", &"rook_warden": &"rook_line",
	&"queen_of_tricks": &"union_lines", &"black_king": &"tile_rewrite",
}
## The shape each family throws when it is shown fenced (a family is a piece type: pawn, knight, bishop, rook, queen, king).
const SHAPE_OF_FAMILY := {&"knight": &"knight_landing", &"bishop": &"diagonal_lane", &"rook": &"rook_line", &"queen": &"union_lines", &"king": &"tile_rewrite"}

## The hazards of 5.3 ("tile-rewrite or train hazard 1"): not pieces, no definition yet (M9 builds the train, M13 the Rule Engine), so the plan's
## points and shapes live here until they become a field of the hazard's own resource.
const HAZARD_POINTS := {&"train_hazard": 1, &"tile_rewrite_pulse": 1}
const SHAPE_OF_HAZARD := {&"train_hazard": &"train_lane", &"tile_rewrite_pulse": &"tile_rewrite"}

## What R37 counts as a persistent reward (plan R37: Page, shard, keepsake drawing, hub change, rescue or earned story beat; lore and a clue
## count as story). `unlock` is a verb or a tool the pawn keeps (Sword, Pencil, Rule Step, Chalk Path, Chalk Block, Eraser Guard, Free Step):
## the plan lists them in the Gate, exam and Reward columns and nothing is more persistent, so they count.
const REWARD_KINDS: Array[StringName] = [&"story", &"page", &"shard", &"drawing", &"hub", &"rescue", &"unlock"]

## One H1 pass-through between two districts is a minute (7.4 Totals: "plus 4 H1 pass-throughs"); the first visit is the h1 row's own 4 minutes.
const HUB_PASS_THROUGH_MINUTES := 1.0

## The window of R37: a persistent reward at least every this many minutes of critical path.
const REWARD_WINDOW_MINUTES := 6.0

## The plan's totals of 7.4 per act, in minutes, critical path only (the optional nooks and the 2-minute Midpoint scene of Act 4 are not rooms).
const ACT_MINUTES := {1: 22.0, 2: 18.5, 3: 21.0, 4: 20.0, 5: 18.5, 6: 22.0, 7: 8.0}
## ... and the plan's intensity check (7.4): the critical-path intensities in route order, one list per act (the hub's first visit ends Act 1; its returns are not listed).
const INTENSITY_BY_ACT := {
	1: [3, 2, 5, 6, 7, 2], 2: [3, 5, 6, 8, 3], 3: [4, 5, 6, 8, 3], 4: [3, 5, 6, 9, 4], 5: [3, 6, 5, 9, 3], 6: [3, 7, 6, 10], 7: [6],
}

## Plan 5.3, the Placed in column: enemy id -> the rooms (by the first word of the id) that hold it, "(fenced)" ones flagged by `fenced`. A
## pseudo-room names a place that is not a room: `boss_guards` (the stand-in Recruit beside a boss) and `boss_summons` (M8b).
const PLACED_IN := {
	&"pawn_recruit": [&"t3", &"t4", &"tb1", &"bs1", &"bt1", &"bt2", &"bt3", &"dh3", &"ub2", &"ub3", &"boss_guards"],
	&"pawn_armed": [&"t4", &"ub2", &"boss_summons"],
	&"backstep_pawn": [&"t4", &"bs1"],
	&"charging_pawn": [&"tb2", &"bs3", &"ub2"],
	&"knight_tracker": [&"tb1", &"tb2", &"tb3", &"dh2", &"ub2"],
	&"bishop_zoner": [&"bs1", &"bs2", &"bs3", &"dh2", &"ub2"],
	&"wooden_rook": [&"bt1", &"bt2", &"dh3", &"ub2"],
	&"iron_rook": [&"bt3"],
	&"queen_of_tricks": [&"dhb"],
	&"black_king": [&"ubb"],
}
## Of those, the placements that are FENCED in the plan (7.4): enemy id -> the room codes.
const FENCED_PLACEMENTS := {&"knight_tracker": [&"tb1"], &"bishop_zoner": [&"bs1"], &"wooden_rook": [&"bt1"]}

const ROWS: Array[Dictionary] = [
	{"id": &"t1_white_kings_fall", "objective": &"reach", "live": [], "fenced": [], "intro": false, "verbs": [], "threat": 0, "shapes": 0,
		"teaches": "walking; the exit is open", "emotion": "grief", "intensity": 3, "minutes": 2.0, "rewards": [[&"story", "clue 1"]]},
	{"id": &"t2_fallen_sword_tile", "objective": &"clear", "live": [], "fenced": [], "intro": false, "verbs": [&"wooden_sword"], "threat": 0, "shapes": 0,
		"teaches": "the Wooden Sword, on a crayon target that never strikes back", "emotion": "agency", "intensity": 2, "minutes": 3.0, "rewards": [[&"unlock", "Wooden Sword"], [&"page", "Book page 1"]]},
	{"id": &"t3_first_pawn_clash", "objective": &"clear", "live": [&"pawn_recruit"], "fenced": [], "intro": true, "verbs": [], "threat": 1, "shapes": 1,
		"teaches": "a pawn's diagonal; the exit is locked until the room is cleared", "emotion": "suspense, fiero", "intensity": 5, "minutes": 3.0, "rewards": [[&"story", "Recruit lore"]]},
	{"id": &"t4_broken_rule_yard", "objective": &"clear", "live": [&"pawn_recruit", &"pawn_armed", &"backstep_pawn"], "fenced": [], "intro": false, "verbs": [&"pencil"], "threat": 5, "shapes": 2,
		"teaches": "an Armed Pawn reaches farther than chess allows; the Pencil lies on the exit path", "emotion": "defiance", "intensity": 6, "minutes": 4.0, "rewards": [[&"unlock", "Pencil"], [&"page", "Armed and Backstep pages"]]},
	{"id": &"b1_black_pawn_captain", "objective": &"clear", "live": [&"black_pawn_captain"], "fenced": [], "intro": false, "verbs": [], "threat": 6, "shapes": 0,
		"teaches": "three phases of the pawn's rule: read the slash, the ruler blade, the summons", "emotion": "dread, fiero", "intensity": 7, "minutes": 6.0, "rewards": [[&"drawing", "keepsake drawing, the B1 notice"]]},
	{"id": &"h1_chess_rug_hub", "objective": &"none", "live": [], "fenced": [], "intro": false, "verbs": [], "threat": 0, "shapes": 0,
		"teaches": "nothing: a rest where the doors say why they are shut", "emotion": "relief, awe", "intensity": 2, "minutes": 4.0, "rewards": [[&"rescue", "Pebble"], [&"hub", "hub gift"]]},

	{"id": &"tb1_toybox_gate", "objective": &"clear", "live": [&"pawn_recruit"], "fenced": [&"knight"], "intro": false, "verbs": [], "threat": 1, "shapes": 1,
		"teaches": "the Knight's L, shown fenced before it can strike", "emotion": "curiosity", "intensity": 3, "minutes": 3.0, "rewards": [[&"story", "Knight lore"]]},
	{"id": &"tb2_l_jump_lanes", "objective": &"clear", "live": [&"knight_tracker", &"charging_pawn"], "fenced": [], "intro": false, "verbs": [], "threat": 5, "shapes": 2,
		"teaches": "the straight lane is also the Pencil lane (exam: Pencil)", "emotion": "suspense", "intensity": 5, "minutes": 4.0, "rewards": [[&"drawing", "keepsake drawing"], [&"page", "Charging and Knight Errant pages"]]},
	{"id": &"tb3_toy_track_ambush", "objective": &"reach", "live": [&"knight_tracker", &"train_hazard"], "fenced": [], "intro": false, "verbs": [&"rule_step"], "threat": 4, "shapes": 2,
		"teaches": "a train chase (the format-breaker); the Rule Step alcove", "emotion": "surprise", "intensity": 6, "minutes": 4.0, "rewards": [[&"unlock", "Rule Step"]]},
	{"id": &"tbb_knight_captain", "objective": &"clear", "live": [&"knight_captain"], "fenced": [], "intro": false, "verbs": [], "threat": 7, "shapes": 0,
		"teaches": "exam: Rule Step", "emotion": "surprise, lightness", "intensity": 8, "minutes": 6.0, "rewards": [[&"page", "Knight Errant page flips"]]},
	{"id": &"tb4_lid_path", "objective": &"reach", "live": [], "fenced": [], "intro": false, "verbs": [], "threat": 0, "shapes": 0,
		"teaches": "the first forced use of Rule Step (a one-cell gap)", "emotion": "flight", "intensity": 3, "minutes": 1.5, "rewards": [[&"hub", "hub shelter"]]},
	{"id": &"tbo_crayon_cache", "objective": &"none", "live": [], "fenced": [], "intro": false, "verbs": [], "threat": 0, "shapes": 0,
		"teaches": "optional: a Rule Step gap", "emotion": "discovery", "intensity": 2, "minutes": 1.5, "rewards": [[&"shard", "shard 2"], [&"unlock", "Lead Tip"]]},

	{"id": &"bs1_book_spine_steps", "objective": &"clear", "live": [&"pawn_recruit", &"backstep_pawn"], "fenced": [&"bishop"], "intro": false, "verbs": [], "threat": 3, "shapes": 1,
		"teaches": "the Bishop's diagonal lane, shown fenced before it can strike", "emotion": "wonder, dread", "intensity": 4, "minutes": 4.0, "rewards": [[&"story", "Bishop lore"]]},
	{"id": &"bs2_diagonal_chapel", "objective": &"clear", "live": [&"bishop_zoner", &"bishop_zoner"], "fenced": [], "intro": false, "verbs": [], "threat": 6, "shapes": 1,
		"teaches": "exam: Rule Step (the exit lies beyond an island gap)", "emotion": "tension", "intensity": 5, "minutes": 4.0, "rewards": [[&"drawing", "keepsake drawing"]]},
	{"id": &"bs3_torn_page_bridge", "objective": &"reach", "live": [&"bishop_zoner", &"charging_pawn"], "fenced": [], "intro": false, "verbs": [], "threat": 5, "shapes": 2,
		"teaches": "a page slide (the format-breaker); a scripted chalk demo; the Slant rescue", "emotion": "trust", "intensity": 6, "minutes": 5.5, "rewards": [[&"rescue", "Slant"]]},
	{"id": &"bsb_bishop_oracle", "objective": &"clear", "live": [&"bishop_oracle"], "fenced": [], "intro": false, "verbs": [&"chalk_path"], "threat": 7, "shapes": 0,
		"teaches": "the puzzle-form fight; Chalk Path, Believe appears", "emotion": "wonder, trust", "intensity": 8, "minutes": 6.0, "rewards": [[&"unlock", "Chalk Path"]]},
	{"id": &"bs4_page_tear_shortcut", "objective": &"reach", "live": [], "fenced": [], "intro": false, "verbs": [], "threat": 0, "shapes": 0,
		"teaches": "the forced first Chalk Path (a free 3-cell tear)", "emotion": "relief", "intensity": 3, "minutes": 1.5, "rewards": [[&"hub", "hub banners"]]},
	{"id": &"bso_margin_nook", "objective": &"none", "live": [], "fenced": [], "intro": false, "verbs": [], "threat": 0, "shapes": 0,
		"teaches": "optional: a Chalk Path gap, free", "emotion": "care", "intensity": 2, "minutes": 1.0, "rewards": [[&"shard", "shard 3"]]},

	{"id": &"bt1_block_yard", "objective": &"clear", "live": [&"pawn_recruit", &"pawn_recruit"], "fenced": [&"rook"], "intro": false, "verbs": [], "threat": 2, "shapes": 1,
		"teaches": "the Rook's line, shown fenced before it can charge; the Guard antepiece", "emotion": "patience", "intensity": 3, "minutes": 3.5, "rewards": [[&"story", "Rook lore"]]},
	{"id": &"bt2_ruler_bridge", "objective": &"survive", "live": [&"wooden_rook", &"pawn_recruit"], "fenced": [], "intro": false, "verbs": [], "threat": 5, "shapes": 2,
		"teaches": "hold the line for 30 s (the format-breaker); the Stout rescue", "emotion": "trust", "intensity": 5, "minutes": 5.0, "rewards": [[&"rescue", "Stout"], [&"drawing", "keepsake drawing"]]},
	{"id": &"bt3_breakable_wall_test", "objective": &"clear", "live": [&"iron_rook", &"pawn_recruit"], "fenced": [], "intro": false, "verbs": [], "threat": 5, "shapes": 2,
		"teaches": "exam: Chalk Path (a Rook line fires across a gap)", "emotion": "resolve", "intensity": 6, "minutes": 4.0, "rewards": [[&"story", "Iron armor margin note"]]},
	{"id": &"btb_rook_warden", "objective": &"clear", "live": [&"rook_warden"], "fenced": [], "intro": false, "verbs": [&"eraser_guard"], "threat": 8, "shapes": 0,
		"teaches": "the endurance-hold fight; Eraser Guard", "emotion": "resolve", "intensity": 9, "minutes": 6.0, "rewards": [[&"hub", "hub train"]]},
	{"id": &"bt4_ruler_gate_shortcut", "objective": &"reach", "live": [], "fenced": [], "intro": false, "verbs": [&"chalk_block"], "threat": 0, "shapes": 0,
		"teaches": "the forced first Eraser Guard (rub a Rule Mark)", "emotion": "confession", "intensity": 4, "minutes": 1.5, "rewards": [[&"unlock", "Chalk Block"]]},
	{"id": &"bto_rubble_nook", "objective": &"none", "live": [], "fenced": [], "intro": false, "verbs": [], "threat": 0, "shapes": 0,
		"teaches": "optional: Eraser Guard rubs a Rule Mark", "emotion": "care", "intensity": 2, "minutes": 1.5, "rewards": [[&"shard", "shard 4"]]},

	{"id": &"dh1_foyer", "objective": &"none", "live": [], "fenced": [], "intro": false, "verbs": [], "threat": 0, "shapes": 0,
		"teaches": "a tea party where the pawn obeys table rules (the format-breaker); the Queen's voice offstage", "emotion": "unease", "intensity": 3, "minutes": 3.0, "rewards": [[&"story", "the Queen's voice beat"]]},
	{"id": &"dh2_mixed_court", "objective": &"clear", "live": [&"knight_tracker", &"bishop_zoner"], "fenced": [], "intro": false, "verbs": [], "threat": 6, "shapes": 2,
		"teaches": "diagonals and leaps ignore the guard", "emotion": "tension", "intensity": 6, "minutes": 5.0, "rewards": [[&"drawing", "keepsake drawing"]]},
	{"id": &"dh3_royal_stage", "objective": &"clear", "live": [&"wooden_rook", &"pawn_recruit"], "fenced": [&"queen"], "intro": false, "verbs": [], "threat": 5, "shapes": 2,
		"teaches": "exam: Eraser Guard; the Queen's lane, shown fenced", "emotion": "dread", "intensity": 5, "minutes": 3.0, "rewards": [[&"story", "Queen lore"]]},
	{"id": &"dhb_queen_of_tricks", "objective": &"clear", "live": [&"queen_of_tricks"], "fenced": [], "intro": false, "verbs": [], "threat": 8, "shapes": 0,
		"teaches": "lanes one at a time, commanded pawns, the promotion offer; the latch lifts", "emotion": "betrayal, compassion", "intensity": 9, "minutes": 6.5, "rewards": [[&"hub", "hub gather"]],
		"mid_rewards": [[&"story", "the Queen's address (S20)", 0.6]]},
	{"id": &"dh4_seal_stair", "objective": &"reach", "live": [], "fenced": [], "intro": false, "verbs": [], "threat": 0, "shapes": 0,
		"teaches": "a relief sequence with the H1 gather beat", "emotion": "relief", "intensity": 3, "minutes": 1.0, "rewards": [[&"hub", "hub gather"]]},

	{"id": &"ub1_castle_gate", "objective": &"none", "live": [], "fenced": [], "intro": false, "verbs": [], "threat": 0, "shapes": 0,
		"teaches": "the memories wall: the rescued pieces remembered", "emotion": "memory", "intensity": 3, "minutes": 3.0, "rewards": [[&"story", "memory beat"]]},
	{"id": &"ub2_last_board", "objective": &"waves", "live": [], "fenced": [], "intro": false, "verbs": [], "threat": 6, "shapes": 4,
		"waves": [[&"knight_tracker", &"pawn_recruit"], [&"bishop_zoner", &"charging_pawn", &"pawn_recruit"], [&"wooden_rook", &"pawn_armed"]],
		"teaches": "every earlier verb re-tested, three waves", "emotion": "mastery", "intensity": 7, "minutes": 6.0, "rewards": [[&"story", "Black King lore"]]},
	{"id": &"ub3_rule_engine", "objective": &"clear", "live": [&"pawn_recruit", &"tile_rewrite_pulse", &"tile_rewrite_pulse", &"tile_rewrite_pulse"], "fenced": [&"king"], "intro": false, "verbs": [], "threat": 4, "shapes": 2,
		"teaches": "tiles rewrite themselves; the pulse is shown fenced first", "emotion": "dread", "intensity": 6, "minutes": 4.0, "rewards": [[&"story", "Rule Engine margin note"]]},
	{"id": &"ubb_black_king", "objective": &"clear", "live": [&"black_king"], "fenced": [], "intro": false, "verbs": [&"free_step"], "threat": 9, "shapes": 0,
		"teaches": "everything you learned; Free Step", "emotion": "catharsis", "intensity": 10, "minutes": 9.0, "rewards": [[&"unlock", "Free Step"]],
		"mid_rewards": [[&"story", "the first memory alcove (S24)", 0.4], [&"story", "the second memory alcove (S24)", 0.55], [&"story", "the third memory alcove (S24)", 0.7]]},

	{"id": &"e1_morning_desk", "objective": &"none", "live": [], "fenced": [], "intro": false, "verbs": [], "threat": 0, "shapes": 0,
		"teaches": "the free step outside the square, and the hold", "emotion": "bittersweet", "intensity": 6, "minutes": 8.0, "rewards": []},
]


static func row_of(room_id: StringName) -> Dictionary:
	for row in ROWS:
		if row["id"] == room_id:
			return row
	return {}


## The code of a room id: its first word (tb1_toybox_gate -> tb1), as the Placed in column writes it.
static func code_of(room_id: StringName) -> StringName:
	return StringName(String(room_id).get_slice("_", 0))


## A deep copy of the table a lint may break on purpose: rows are copied, so the real table stays untouched.
static func copy_of_rows() -> Array[Dictionary]:
	var copy: Array[Dictionary] = []
	for row in ROWS:
		copy.append(row.duplicate(true))
	return copy


## The pieces (and hazards) of a row that are live together in its biggest moment: `live` for an ordinary room, the wave with the most
## threat for a gauntlet. Each is an enemy id or a hazard id.
static func live_of(row: Dictionary, threat_of_piece: Callable) -> Array:
	if row.has("waves"):
		var best: Array = []
		var best_threat := -1
		for wave: Array in row["waves"]:
			var wave_threat := _threat_sum(wave, threat_of_piece)
			if wave_threat > best_threat:
				best_threat = wave_threat
				best = wave
		return best
	return row["live"]


## The threat points of a list of pieces and hazards: `threat_of_piece` answers an enemy id (the definition's threat_points), HAZARD_POINTS the rest.
static func threat_of(pieces: Array, threat_of_piece: Callable) -> int:
	return _threat_sum(pieces, threat_of_piece)


static func _threat_sum(pieces: Array, threat_of_piece: Callable) -> int:
	var total := 0
	for piece: StringName in pieces:
		total += int(HAZARD_POINTS[piece]) if HAZARD_POINTS.has(piece) else int(threat_of_piece.call(piece))
	return total


## How many different shapes a list of pieces and hazards throws at once.
static func shapes_of(pieces: Array) -> Array[StringName]:
	var shapes: Array[StringName] = []
	for piece: StringName in pieces:
		var shape: StringName = SHAPE_OF_HAZARD[piece] if SHAPE_OF_HAZARD.has(piece) else SHAPE_OF_PIECE.get(piece, &"")
		if shape != &"" and shape not in shapes:
			shapes.append(shape)
	return shapes
