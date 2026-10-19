extends UnboundTest

## The camera frames the room (requirement 118; docs/game-base-plan.md D-02, D-30, 15 M3a): a board that
## fits the picture is held still with every cell on screen, wherever the hero stands, so no threat is
## ever out of view; a board larger than the picture scrolls with the hero and stops at its edges.
## "On screen" is measured with a real Camera2D in a SubViewport of the game's own size, not computed
## from the same numbers the rig uses: get_screen_center_position() is where the engine put the view.

const VIEW_SIZE := Vector2(640, 360)


func _init() -> void:
	suite_title = "CAMERA FRAMES TEST"
	_check_the_limits_for_a_board()
	# A suite's _init() runs before the tree is up: a camera can only become current once it is in it.
	await process_frame
	await _check_rooms_that_fit_the_view()
	await _check_a_board_larger_than_the_view_scrolls()
	await _check_zoom_and_unclamped()
	await _check_a_room_change_and_another_view()
	finish()


class Stage:
	var viewport: SubViewport
	var hero: Node2D
	var rig: CameraRig


func _make_stage(view_size := VIEW_SIZE) -> Stage:
	var stage := Stage.new()
	stage.viewport = SubViewport.new()
	stage.viewport.size = Vector2i(view_size)
	stage.viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage.viewport)
	stage.hero = Node2D.new()
	stage.viewport.add_child(stage.hero)
	stage.rig = CameraRig.new()
	stage.rig.smoothing_speed = 0.0
	stage.hero.add_child(stage.rig)
	return stage


func _free_stage(stage: Stage) -> void:
	stage.viewport.queue_free()


## A grid shaped the way EcsBoot shapes it for a room of this many cells.
func _grid(columns: int, rows: int) -> EcsGrid:
	var grid := EcsGrid.new()
	grid.bounds = Rect2i(0, 0, columns, rows)
	grid.grid_origin = EcsGrid.centred_origin(Vector2i(columns, rows), grid.cell_size, VIEW_SIZE)
	return grid


func _board_rect(grid: EcsGrid) -> Rect2:
	return Rect2(grid.grid_origin, Vector2(grid.bounds.size * grid.cell_size))


## Stands the hero at `world_position`, lets two frames pass, and returns the rectangle of the world the
## view shows.
func _visible_rect_with_hero_at(stage: Stage, world_position: Vector2) -> Rect2:
	stage.hero.position = world_position
	await process_frame
	await process_frame
	var visible_size := stage.viewport.get_visible_rect().size / stage.rig.zoom.x
	return Rect2(stage.rig.get_screen_center_position() - visible_size * 0.5, visible_size)


func _check_the_limits_for_a_board() -> void:
	_expect(CameraRig.limits_for_board(Rect2(64, 36, 512, 288), VIEW_SIZE) == Rect2i(0, 0, 640, 360), "a 16x9 board centred in the view is framed by limits as large as the view: the camera is pinned")
	_expect(CameraRig.limits_for_board(Rect2(32, 36, 576, 288), VIEW_SIZE) == Rect2i(0, 0, 640, 360), "so is an 18x9 arena, though its origin differs")
	_expect(CameraRig.limits_for_board(Rect2(64, 36, 576, 288), VIEW_SIZE) == Rect2i(32, 0, 640, 360), "a board that is not centred (the old fixed origin on an 18-wide arena) is still framed whole: the camera is pinned on its centre")
	_expect(CameraRig.limits_for_board(Rect2(64, 36, 2304, 1280), VIEW_SIZE) == Rect2i(64, 36, 2304, 1280), "a board larger than the view is limited by its own edges")
	_expect(CameraRig.limits_for_board(Rect2(64, 36, 2304, 288), VIEW_SIZE) == Rect2i(64, 0, 2304, 360), "a wide, short board scrolls in x and is pinned in y")
	_expect(CameraRig.limits_for_board(Rect2(64, 36, 512, 288), VIEW_SIZE * 0.5) == Rect2i(64, 36, 512, 288), "seen through a zoomed-in view that shows less than the board, the board's edges are the limits")
	_expect(CameraRig.limits_for_board(Rect2(64.5, 36.5, 512, 288), VIEW_SIZE) == Rect2i(0, 0, 640, 360), "limits are whole pixels")


func _check_rooms_that_fit_the_view() -> void:
	for room_size in [Vector2i(16, 9), Vector2i(18, 9), Vector2i(15, 8), Vector2i(10, 6)]:
		var stage := _make_stage()
		var grid := _grid(room_size.x, room_size.y)
		stage.rig.setup(grid)
		var board := _board_rect(grid)
		var description := "%dx%d" % [room_size.x, room_size.y]
		var every_position_frames_the_room := true
		var every_cell_on_screen := true
		var the_view_never_moves := true
		var first_view := Rect2()
		var hero_positions: Array[Vector2] = [board.get_center(), board.position, board.end, Vector2(board.position.x, board.end.y), grid.cell_to_world(Vector2i(0, 0)), grid.cell_to_world(room_size - Vector2i.ONE)]
		for hero_position in hero_positions:
			var shown := await _visible_rect_with_hero_at(stage, hero_position)
			if first_view == Rect2():
				first_view = shown
			the_view_never_moves = the_view_never_moves and shown.is_equal_approx(first_view)
			every_cell_on_screen = every_cell_on_screen and shown.encloses(board)
			every_position_frames_the_room = every_position_frames_the_room and shown.get_center().is_equal_approx(board.get_center())
		_expect(the_view_never_moves, "%s room: the view is held still wherever the hero stands (%d positions, corners included)" % [description, hero_positions.size()])
		_expect(every_cell_on_screen, "%s room: every cell of the board is on screen, so no telegraph can be out of view" % description)
		_expect(every_position_frames_the_room, "%s room: the view is centred on the board" % description)
		_expect(first_view.is_equal_approx(Rect2(Vector2.ZERO, VIEW_SIZE)), "%s room: with the room's centred origin the view is exactly the picture, (0, 0) to (640, 360), so a background drawn for the picture lines up" % description)
		_free_stage(stage)


func _check_a_board_larger_than_the_view_scrolls() -> void:
	var stage := _make_stage()
	var grid := _grid(72, 40)
	stage.rig.setup(grid)
	var board := _board_rect(grid)
	var in_the_middle := await _visible_rect_with_hero_at(stage, board.get_center())
	_expect(in_the_middle.get_center().is_equal_approx(board.get_center()), "in the middle of a large world the view follows the hero")
	var other_spot := board.get_center() + Vector2(300, -170)
	var after_a_walk := await _visible_rect_with_hero_at(stage, other_spot)
	_expect(after_a_walk.get_center().is_equal_approx(other_spot), "and keeps following (the hero moved to %s, the view centre is %s)" % [other_spot, after_a_walk.get_center()])

	var in_the_corner := await _visible_rect_with_hero_at(stage, grid.cell_to_world(Vector2i(0, 0)))
	_expect(is_equal_approx(in_the_corner.position.x, board.position.x) and is_equal_approx(in_the_corner.position.y, board.position.y), "in the top-left corner the view stops at the board's top-left edge: nothing outside the world shows")
	var in_the_far_corner := await _visible_rect_with_hero_at(stage, grid.cell_to_world(Vector2i(71, 39)))
	_expect(is_equal_approx(in_the_far_corner.end.x, board.end.x) and is_equal_approx(in_the_far_corner.end.y, board.end.y), "in the far corner it stops at the bottom-right edge")
	var always_inside := true
	for cell in [Vector2i(0, 39), Vector2i(71, 0), Vector2i(35, 20), Vector2i(10, 10), Vector2i(60, 30)]:
		always_inside = always_inside and board.encloses(await _visible_rect_with_hero_at(stage, grid.cell_to_world(cell)))
	_expect(always_inside, "wherever the hero stands in a large world, the view lies inside the world")
	_free_stage(stage)


func _check_zoom_and_unclamped() -> void:
	var stage := _make_stage()
	var grid := _grid(16, 9)
	stage.rig.setup(grid)
	var board := _board_rect(grid)
	var framed := await _visible_rect_with_hero_at(stage, board.position)
	_expect(framed.encloses(board), "setup: at zoom 1.0 the 16x9 board is framed whole")
	stage.rig.set_zoom_level(2.0)
	var zoomed_in_corner := await _visible_rect_with_hero_at(stage, grid.cell_to_world(Vector2i(0, 0)))
	_expect(zoomed_in_corner.size.is_equal_approx(VIEW_SIZE * 0.5) and board.encloses(zoomed_in_corner) and is_equal_approx(zoomed_in_corner.position.x, board.position.x), "zoomed in, the board no longer fits the view, so it scrolls and the view stops at the board's edge (the zoom re-applied the limits)")
	var zoomed_in_middle := await _visible_rect_with_hero_at(stage, board.get_center())
	_expect(zoomed_in_middle.get_center().is_equal_approx(board.get_center()), "zoomed in, the view follows the hero in the middle of the board")
	stage.rig.set_zoom_level(1.0)
	var back := await _visible_rect_with_hero_at(stage, board.position)
	_expect(back.encloses(board), "zooming back out frames the whole board again")
	stage.rig.clamp_to_board_bounds = false
	var past_the_edge := await _visible_rect_with_hero_at(stage, board.position - Vector2(200, 200))
	_expect(past_the_edge.get_center().is_equal_approx(board.position - Vector2(200, 200)), "with the clamp off the view follows the hero past the board's edge")
	_free_stage(stage)


func _check_a_room_change_and_another_view() -> void:
	var stage := _make_stage()
	var first_room := _grid(16, 9)
	stage.rig.setup(first_room)
	var first_view := await _visible_rect_with_hero_at(stage, Vector2(100, 100))
	_expect(first_view.encloses(_board_rect(first_room)), "setup: the first room is framed")
	# The shell calls setup() again after booting the next room; the limits move to the new board.
	var second_room := _grid(72, 40)
	stage.rig.setup(second_room)
	var second_board := _board_rect(second_room)
	var second_view := await _visible_rect_with_hero_at(stage, second_room.cell_to_world(Vector2i(40, 20)))
	_expect(second_board.encloses(second_view) and second_view.get_center().is_equal_approx(second_room.cell_to_world(Vector2i(40, 20))), "after a room change the camera is clamped to the new room: a scrolling view inside the new board")
	var third_room := _grid(18, 9)
	stage.rig.setup(third_room)
	var third_view := await _visible_rect_with_hero_at(stage, Vector2(5000, 5000))
	_expect(third_view.encloses(_board_rect(third_room)) and third_view.get_center().is_equal_approx(_board_rect(third_room).get_center()), "and back in a single-screen room the view is pinned on it again, even with the hero far away")
	_free_stage(stage)

	# A picture of another size: the limits come from the viewport, not from a repeated 640 x 360.
	var wide_stage := _make_stage(Vector2(800, 450))
	var room := _grid(16, 9)
	wide_stage.rig.setup(room)
	var wide_view := await _visible_rect_with_hero_at(wide_stage, Vector2(0, 0))
	_expect(wide_view.size.is_equal_approx(Vector2(800, 450)) and wide_view.encloses(_board_rect(room)) and wide_view.get_center().is_equal_approx(_board_rect(room).get_center()), "in a view of 800x450 the same room is framed whole and centred on the board")
	_free_stage(wide_stage)
