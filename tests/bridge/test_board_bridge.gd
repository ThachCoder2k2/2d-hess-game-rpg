extends UnboundTest

## BoardBridge (presentation/bridges/board_bridge.gd, M3b step 2): what the combat events draw on the
## board overlay. Before the split these reactions lived inside game_root.gd and no suite pinned them;
## this one drives the bridge through a real router and a real PrototypeBoard, with a snapshot and no
## world behind it (the bridge may read nothing else).

const HERO := 1
const PAWN := 7
const KNIGHT := 8


func _init() -> void:
	suite_title = "BOARD BRIDGE TEST"
	_check_telegraphs_follow_their_events()
	_check_a_strike_flashes_the_board()
	_check_the_hero_strike_flashes_only_with_a_profile()
	_check_intent_paths_follow_their_event()
	_check_a_fallen_enemy_leaves_no_marks_and_the_hero_keeps_them()
	_check_show_room_binds_the_overlay()
	_check_a_bridge_without_a_board_is_silent()
	finish()


func _make_bridge() -> Array:
	var board := PrototypeBoard.new()
	var snapshot := HudSnapshot.new()
	snapshot.player_entity = HERO
	var bridge := BoardBridge.new()
	bridge.attach(board)
	bridge.bind_world(snapshot, {})
	var router := EventRouter.new()
	bridge.register(router)
	return [bridge, board, router]


func _check_telegraphs_follow_their_events() -> void:
	var parts := _make_bridge()
	var board: PrototypeBoard = parts[1]
	var router: EventRouter = parts[2]
	var cells: Array[Vector2i] = [Vector2i(4, 4), Vector2i(5, 4)]
	router.route([{"type": Events.TELEGRAPH_STARTED, "entity": PAWN, "cells": cells}])
	_expect(board.telegraphs.get(PAWN) == cells, "telegraph_started puts the enemy's locked cells on the board")
	router.route([{"type": Events.TELEGRAPH_FINISHED, "entity": PAWN}])
	_expect(not board.telegraphs.has(PAWN), "telegraph_finished takes them off")


func _check_a_strike_flashes_the_board() -> void:
	var parts := _make_bridge()
	var board: PrototypeBoard = parts[1]
	var router: EventRouter = parts[2]
	var cells: Array[Vector2i] = [Vector2i(2, 2)]
	router.route([{"type": Events.ATTACK_RESOLVED, "entity": PAWN, "cells": cells}])
	_expect(board.impact_cells == cells and board.impact_color == board.enemy_impact_color and board.impact_time > 0.0, "attack_resolved flashes the struck cells in the enemy colour")


func _check_the_hero_strike_flashes_only_with_a_profile() -> void:
	var parts := _make_bridge()
	var board: PrototypeBoard = parts[1]
	var router: EventRouter = parts[2]
	var cells: Array[Vector2i] = [Vector2i(3, 3), Vector2i(4, 3)]
	var profile := AttackProfile.new()
	profile.color = Color.GREEN
	router.route([{"type": Events.ATTACK_LANDED, "entity": HERO, "cells": cells, "hit_count": 1, "profile": profile}])
	_expect(board.impact_cells == cells and board.impact_color == Color.GREEN, "attack_landed with a hit flashes the cells in the attack's colour")
	router.route([{"type": Events.ATTACK_LANDED, "entity": HERO, "cells": cells, "hit_count": 0, "profile": profile}])
	_expect(board.impact_color == board.player_miss_color, "a swing that hit nothing flashes the miss colour")
	var untouched := _make_bridge()
	var untouched_board: PrototypeBoard = untouched[1]
	var untouched_router: EventRouter = untouched[2]
	untouched_router.route([{"type": Events.ATTACK_LANDED, "entity": HERO, "cells": cells, "hit_count": 1, "profile": null}])
	_expect(untouched_board.impact_cells.is_empty(), "an attack_landed with no profile draws nothing")


func _check_intent_paths_follow_their_event() -> void:
	var parts := _make_bridge()
	var board: PrototypeBoard = parts[1]
	var router: EventRouter = parts[2]
	var intent := EnemyIntent.wait(0.5)
	router.route([{"type": Events.INTENT_CHANGED, "entity": KNIGHT, "intent": intent}])
	_expect(board.enemy_intents.get(KNIGHT) == intent, "intent_changed hands the enemy's choice to the F3 layer")
	router.route([{"type": Events.INTENT_CHANGED, "entity": PAWN, "intent": "not an intent"}])
	_expect(not board.enemy_intents.has(PAWN), "an event whose intent is not an EnemyIntent is ignored")


func _check_a_fallen_enemy_leaves_no_marks_and_the_hero_keeps_them() -> void:
	var parts := _make_bridge()
	var board: PrototypeBoard = parts[1]
	var router: EventRouter = parts[2]
	var cells: Array[Vector2i] = [Vector2i(1, 1)]
	board.set_telegraph(PAWN, cells)
	board.set_enemy_intent(PAWN, EnemyIntent.wait(0.1))
	board.set_telegraph(HERO, cells)
	router.route([{"type": Events.DEFEATED, "entity": PAWN, "source": HERO, "tags": []}])
	_expect(not board.telegraphs.has(PAWN) and not board.enemy_intents.has(PAWN), "a defeated enemy's warning cells and debug path come off the board")
	router.route([{"type": Events.DEFEATED, "entity": HERO, "source": KNIGHT, "tags": []}])
	_expect(board.telegraphs.has(HERO), "the hero's own defeat is not the board's business: nothing is cleared")


func _check_show_room_binds_the_overlay() -> void:
	var parts := _make_bridge()
	var bridge: BoardBridge = parts[0]
	var board: PrototypeBoard = parts[1]
	var grid := EcsGrid.new()
	bridge.show_room(grid, false)
	_expect(board.grid_world == grid and board.hud_snapshot == bridge.snapshot, "show_room binds the overlay to the room's grid and the bridge's snapshot")
	_expect(board.z_index == -5 and not board.debug_enabled, "the overlay sits below the zone and starts with the debug layer as the scene says")
	bridge.set_debug_view(true)
	_expect(board.debug_enabled, "set_debug_view switches the F3 layer")


func _check_a_bridge_without_a_board_is_silent() -> void:
	var bridge := BoardBridge.new()
	bridge.bind_world(HudSnapshot.new(), {})
	var router := EventRouter.new()
	bridge.register(router)
	var cells: Array[Vector2i] = [Vector2i(1, 1)]
	router.route([
		{"type": Events.TELEGRAPH_STARTED, "entity": PAWN, "cells": cells},
		{"type": Events.DEFEATED, "entity": PAWN, "source": 0, "tags": []},
	])
	bridge.show_room(EcsGrid.new(), true)
	bridge.set_debug_view(false)
	_expect(true, "a scene with no board overlay runs the same events without a word")
