extends UnboundTest

## The board overlay (telegraph cells, hit flashes, the F3 debug view) used to hold the EcsWorld and
## read each enemy's EnemyAI and GridPos components while drawing. Presentation may not touch
## ecs/components (docs/game-base-plan.md 13.1), so it draws from the world's HudSnapshot now. This
## suite runs the overlay's real draw code on a snapshot with no world behind it, which also proves
## the board needs nothing else: telegraph progress comes from a brief, a stale intent is dropped
## when its enemy has no brief, and every kind of F3 intent path draws without a script error (the
## runner fails a suite on any SCRIPT ERROR line).


func _init() -> void:
	suite_title = "BOARD DRAWS FROM SNAPSHOT TEST"
	await _run()
	finish()


func _run() -> void:
	await process_frame
	var grid := EcsGrid.new()
	grid.add_block(Vector2i(6, 3))
	var snapshot := HudSnapshot.new()
	var hunter := 41
	var waiter := 42
	var gone := 43
	snapshot.enemy_brief_by_entity[hunter] = _brief(Vector2i(4, 3), Vector2i(8, 3), 0.25)
	snapshot.enemy_brief_by_entity[waiter] = _brief(Vector2i(2, 5), Vector2i(-999, -999), 0.0)

	var board := PrototypeBoard.new()
	root.add_child(board)
	board.setup(grid, snapshot)
	_expect(board.grid_world == grid and board.hud_snapshot == snapshot, "the board is set up with a grid and a snapshot, and holds no world")
	_expect(is_equal_approx(board._telegraph_progress(hunter), 0.25), "telegraph progress is the brief's progress")
	_expect(is_zero_approx(board._telegraph_progress(gone)), "an enemy with no brief telegraphs at progress 0.0")
	snapshot.enemy_brief_by_entity[hunter].telegraph_progress = 0.9
	_expect(is_equal_approx(board._telegraph_progress(hunter), 0.9), "the board sees the snapshot change without being told: it holds the reference")

	var unwired := PrototypeBoard.new()
	root.add_child(unwired)
	unwired.setup(grid)
	_expect(is_zero_approx(unwired._telegraph_progress(hunter)), "a board set up without a snapshot draws every telegraph at progress 0.0")

	var attack_cells: Array[Vector2i] = [Vector2i(5, 3), Vector2i(4, 4)]
	board.set_telegraph(hunter, attack_cells)
	board.set_enemy_intent(hunter, EnemyIntent.move(Vector2i(5, 3), Vector2i.RIGHT, 1.0))
	board.set_enemy_intent(waiter, EnemyIntent.wait(0.5))
	board.set_enemy_intent(gone, EnemyIntent.turn(Vector2i.LEFT, 0.5))
	board.set_debug_enabled(true)
	unwired.set_enemy_intent(hunter, EnemyIntent.wait(0.1))
	unwired.set_debug_enabled(true)
	await process_frame
	await process_frame
	_expect(not board.enemy_intents.has(gone) and board.enemy_intents.has(hunter) and board.enemy_intents.has(waiter), "in the F3 view an intent whose enemy has no brief is dropped as stale, the others stay (the draw ran)")
	_expect(unwired.enemy_intents.has(hunter), "a board with no snapshot draws no intent paths and drops nothing")

	# Every kind of intent draws its path from a brief.
	var path_cells: Array[Vector2i] = [Vector2i(5, 3), Vector2i(4, 4)]
	for intent in [EnemyIntent.move(Vector2i(5, 3), Vector2i.RIGHT, 1.0), EnemyIntent.attack(path_cells, 1.0), EnemyIntent.turn(Vector2i.DOWN, 1.0), EnemyIntent.pickup(1.0), EnemyIntent.wait(1.0)]:
		board.set_enemy_intent(hunter, intent)
		board.queue_redraw()
		await process_frame
	_expect(board.enemy_intents.has(hunter), "move, attack, turn, pickup and wait intents all draw from a brief without a script error")

	# An enemy that leaves the snapshot has its intent dropped on the next draw.
	snapshot.enemy_brief_by_entity.erase(hunter)
	board.queue_redraw()
	await process_frame
	_expect(not board.enemy_intents.has(hunter), "an enemy that leaves the snapshot loses its intent path")

	await _check_the_doors_are_drawn_and_follow_the_snapshot(board, grid, snapshot)

	for node: Node in [board, unwired]:
		node.queue_free()


## The door marks (M5 fix: doors were plain floor): the board draws one mark per door brief, in both states and for
## the door that ends the run, and notices a door that opens without being told.
func _check_the_doors_are_drawn_and_follow_the_snapshot(board: PrototypeBoard, grid: EcsGrid, snapshot: HudSnapshot) -> void:
	var shut_cell := Vector2i(2, 1)
	var open_cell := Vector2i(8, 7)
	var ending_cell := Vector2i(14, 4)
	var shut_brief := _door_brief(true, false)
	snapshot.door_brief_by_cell[shut_cell] = shut_brief
	snapshot.door_brief_by_cell[open_cell] = _door_brief(false, false)
	snapshot.door_brief_by_cell[ending_cell] = _door_brief(false, true)
	_expect(board._doors_changed_since_drawn(), "doors the board has not drawn yet are a change it will redraw for")
	board.queue_redraw()
	await process_frame
	await process_frame
	_expect(board.drawn_door_shut_by_cell.size() == 3 and board.drawn_door_shut_by_cell[shut_cell] and not board.drawn_door_shut_by_cell[open_cell], "all three door marks were drawn: one shut, two open (the draw ran, in every style, without a script error)")
	_expect(not board._doors_changed_since_drawn(), "and nothing is pending once they are drawn")

	shut_brief.is_shut = false
	_expect(board._doors_changed_since_drawn(), "a door that opens in the snapshot is noticed without the board being told")
	await process_frame
	await process_frame
	_expect(not board.drawn_door_shut_by_cell[shut_cell] and not board._doors_changed_since_drawn(), "the board redrew it open")

	snapshot.door_brief_by_cell.erase(shut_cell)
	snapshot.door_brief_by_cell.erase(open_cell)
	snapshot.door_brief_by_cell.erase(ending_cell)
	await process_frame
	await process_frame
	_expect(board.drawn_door_shut_by_cell.is_empty(), "doors that leave the snapshot leave the board")
	var no_snapshot_board := PrototypeBoard.new()
	root.add_child(no_snapshot_board)
	no_snapshot_board.setup(grid)
	await process_frame
	_expect(no_snapshot_board.drawn_door_shut_by_cell.is_empty() and not no_snapshot_board._doors_changed_since_drawn(), "a board with no snapshot draws no door marks")
	no_snapshot_board.queue_free()


func _door_brief(is_shut: bool, ends_run: bool) -> HudSnapshot.DoorBrief:
	var brief := HudSnapshot.DoorBrief.new()
	brief.is_shut = is_shut
	brief.ends_run = ends_run
	return brief


func _brief(cell: Vector2i, committed_goal: Vector2i, telegraph_progress: float) -> HudSnapshot.EnemyBrief:
	var brief := HudSnapshot.EnemyBrief.new()
	brief.cell = cell
	brief.committed_goal = committed_goal
	brief.telegraph_progress = telegraph_progress
	return brief
