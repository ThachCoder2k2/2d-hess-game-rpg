extends UnboundTest

## The camera starts the picture on a whole pixel (requirement 10; docs/game-base-plan.md D-30, 15 M4). All art is drawn
## at 1x1 pixels, so a view whose top-left corner lies between two pixels draws every sprite and tile across a pixel
## boundary: the picture shimmers while the follow point eases, while the hero slides between cells in a world that
## scrolls, and while the screen shakes. The rig keeps the follow, the ease, the board's limits and the shake, and moves
## the finished view by less than half a pixel to the nearest whole one.
##
## What is measured is what the engine draws with, not what the rig computes: the SubViewport's own canvas transform
## (its origin is minus the view's top-left corner, times the zoom). A pixel of play is not allowed anywhere: a corner
## that is 0.001 off a whole pixel fails. The measuring is shown to be able to fail with the snap switched off.

const VIEW_SIZE := Vector2(640, 360)
## How far from a whole number a corner may be: floating-point noise, nothing more.
const WHOLE_TOLERANCE := 0.0005
## One frame of the rig's own clock, for the suites that step it by hand.
const STEP := 1.0 / 60.0


func _init() -> void:
	suite_title = "CAMERA SNAP TEST"
	# A suite's _init() runs before the tree is up: a camera can only become current once it is in it.
	await process_frame
	await _check_the_follow_lands_on_whole_pixels()
	await _check_the_measuring_can_fail()
	await _check_the_ease_is_kept_and_lands_on_whole_pixels()
	await _check_a_room_that_fits_is_pinned_on_whole_pixels()
	await _check_the_zoom_and_the_limits()
	await _check_the_shake_moves_the_view_by_whole_pixels()
	await _check_the_shake_is_scaled_by_the_setting()
	await _check_the_shipped_hero_view_snaps()
	finish()


class Stage:
	var viewport: SubViewport
	var hero: Node2D
	var rig: CameraRig


## A SubViewport of the game's size with a hero and a rig on it. The rig is stepped by hand (`step`), so a run does not
## depend on how long a frame took.
func _make_stage(smoothing_speed: float, view_size := VIEW_SIZE) -> Stage:
	var stage := Stage.new()
	stage.viewport = SubViewport.new()
	stage.viewport.size = Vector2i(view_size)
	stage.viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage.viewport)
	stage.hero = Node2D.new()
	stage.viewport.add_child(stage.hero)
	stage.rig = CameraRig.new()
	stage.rig.smoothing_speed = smoothing_speed
	stage.hero.add_child(stage.rig)
	return stage


func _free_stage(stage: Stage) -> void:
	stage.viewport.queue_free()


func _grid(columns: int, rows: int) -> EcsGrid:
	var grid := EcsGrid.new()
	grid.bounds = Rect2i(0, 0, columns, rows)
	grid.grid_origin = EcsGrid.centred_origin(Vector2i(columns, rows), grid.cell_size, VIEW_SIZE)
	return grid


## Puts the hero at `world_position` and runs one frame of the rig's _process by hand.
func _step(stage: Stage, world_position: Vector2, delta := STEP) -> void:
	stage.hero.position = world_position
	stage.rig._process(delta)


## The corner of the view the engine draws from: minus the canvas transform's origin, over the zoom.
func _drawn_top_left(stage: Stage) -> Vector2:
	return -stage.viewport.canvas_transform.origin / stage.rig.zoom.x


func _is_whole(point: Vector2) -> bool:
	return absf(point.x - roundf(point.x)) < WHOLE_TOLERANCE and absf(point.y - roundf(point.y)) < WHOLE_TOLERANCE


## The larger of the two axes' distances between two points.
func _largest_move(from: Vector2, to: Vector2) -> float:
	return maxf(absf(to.x - from.x), absf(to.y - from.y))


func _check_the_follow_lands_on_whole_pixels() -> void:
	var stage := _make_stage(0.0)
	stage.rig.setup(_grid(72, 40))
	await process_frame
	var every_frame_whole := true
	var never_far_from_the_hero := true
	var hero_position := Vector2(1000.37, 600.81)
	for frame in 60:
		hero_position += Vector2(0.37, 0.23)
		_step(stage, hero_position)
		every_frame_whole = every_frame_whole and _is_whole(_drawn_top_left(stage))
		var follow_point := hero_position - VIEW_SIZE * 0.5
		never_far_from_the_hero = never_far_from_the_hero and _largest_move(_drawn_top_left(stage), follow_point) <= 0.5 + WHOLE_TOLERANCE
	_expect(every_frame_whole, "a hero sliding 0.37 px a frame through a scrolling world: the view's corner is a whole pixel on all 60 frames")
	_expect(never_far_from_the_hero, "and it is never more than half a pixel from where the hero's follow point is: the snap moves the picture by less than a pixel, it does not lag")
	_free_stage(stage)


func _check_the_measuring_can_fail() -> void:
	var stage := _make_stage(0.0)
	stage.rig.snap_to_whole_pixels = false
	stage.rig.setup(_grid(72, 40))
	stage.hero.position = Vector2(1000.37, 600.81)
	await process_frame
	await process_frame
	_expect(not _is_whole(_drawn_top_left(stage)), "control: with the snap off the same hero leaves the view's corner between pixels (%s), so the check above can fail" % _drawn_top_left(stage))
	_free_stage(stage)


func _check_the_ease_is_kept_and_lands_on_whole_pixels() -> void:
	var stage := _make_stage(8.0)
	var start := Vector2(1000.5, 600.5)
	stage.hero.position = start
	stage.rig.setup(_grid(72, 40))
	await process_frame
	stage.rig.set_process(false)
	_step(stage, start)
	var settled_corner := _drawn_top_left(stage)
	_expect(_is_whole(settled_corner) and absf(settled_corner.x - (start.x - 320.0)) <= 0.5 + WHOLE_TOLERANCE, "setup: with the ease on, the view starts on the hero (no glide in from the last room) and on a whole pixel")
	var jumped_to := start + Vector2(120.3, 0.0)
	var every_frame_whole := true
	var lag_after_one_frame := 0.0
	var lags: Array[float] = []
	for frame in 90:
		_step(stage, jumped_to)
		var corner := _drawn_top_left(stage)
		every_frame_whole = every_frame_whole and _is_whole(corner)
		var lag := (jumped_to.x - 320.0) - corner.x
		lags.append(lag)
		if frame == 0:
			lag_after_one_frame = lag
	_expect(every_frame_whole, "the hero jumps 120 px: the view eases toward it and lands on a whole pixel on every one of 90 frames")
	_expect(lag_after_one_frame > 5.0 and lag_after_one_frame < 119.0, "the ease is kept: a frame after the jump the view is still behind the hero (%.1f px of 120.3)" % lag_after_one_frame)
	var only_ever_closer := true
	for index in range(1, lags.size()):
		only_ever_closer = only_ever_closer and lags[index] <= lags[index - 1] + WHOLE_TOLERANCE
	_expect(only_ever_closer and absf(lags[lags.size() - 1]) <= 0.5 + WHOLE_TOLERANCE, "and it catches up, never stepping back, until it is on the hero (%.2f px left after 90 frames)" % lags[lags.size() - 1])
	_free_stage(stage)


## The rooms of the game all fit the picture: the view is pinned on the board and must be whole there too, wherever the
## hero stands, with the ease on (the engine's ease had no effect on a pinned view, so this must still hold).
func _check_a_room_that_fits_is_pinned_on_whole_pixels() -> void:
	var every_room_whole := true
	var every_room_still := true
	for room_size in [Vector2i(16, 9), Vector2i(18, 9), Vector2i(15, 8), Vector2i(10, 6)]:
		var stage := _make_stage(8.0)
		stage.rig.setup(_grid(room_size.x, room_size.y))
		await process_frame
		stage.rig.set_process(false)
		var first_corner := Vector2.ZERO
		var seen_first := false
		for hero_position in [Vector2(100.37, 90.61), Vector2(500.5, 300.25), Vector2(0.1, 0.1), Vector2(9999.9, 9999.9)]:
			for _frame in 3:
				_step(stage, hero_position)
			var corner := _drawn_top_left(stage)
			every_room_whole = every_room_whole and _is_whole(corner)
			if not seen_first:
				first_corner = corner
				seen_first = true
			every_room_still = every_room_still and corner.is_equal_approx(first_corner)
		_free_stage(stage)
	_expect(every_room_whole, "the four room sizes the game has: the pinned view starts on a whole pixel wherever the hero is (with the ease on)")
	_expect(every_room_still, "and it does not move: the snap does not unpin a room that fits the picture")


func _check_the_zoom_and_the_limits() -> void:
	var stage := _make_stage(0.0)
	var grid := _grid(72, 40)
	stage.rig.setup(grid)
	stage.rig.set_zoom_level(2.0)
	await process_frame
	stage.rig.set_process(false)
	_step(stage, Vector2(1000.37, 600.81))
	_expect(_is_whole(_drawn_top_left(stage)) and absf(_drawn_top_left(stage).x - (1000.37 - 160.0)) <= 0.5 + WHOLE_TOLERANCE, "zoomed in twice, the view's corner (in world pixels) is still whole")
	var board := Rect2(grid.grid_origin, Vector2(grid.bounds.size * grid.cell_size))
	_step(stage, board.position)
	_expect(_is_whole(_drawn_top_left(stage)) and _drawn_top_left(stage).is_equal_approx(board.position), "in the world's corner the snap does not push the view past the board's edge (%s)" % _drawn_top_left(stage))
	_step(stage, board.end)
	_expect(_is_whole(_drawn_top_left(stage)) and (_drawn_top_left(stage) + VIEW_SIZE * 0.5).is_equal_approx(board.end), "and in the far corner it stops on the far edge")
	stage.rig.set_zoom_level(1.0)
	stage.rig.clamp_to_board_bounds = false
	_step(stage, board.position - Vector2(200.4, 200.6))
	_expect(_is_whole(_drawn_top_left(stage)), "with the clamp off, past the board's edge, the view is whole too")
	_free_stage(stage)


## The shake is real frames of real time: its phase comes from the clock, so the run is stepped by the engine itself.
func _check_the_shake_moves_the_view_by_whole_pixels() -> void:
	var stage := _make_stage(0.0)
	stage.rig.setup(_grid(72, 40))
	stage.hero.position = Vector2(1000, 600)
	await process_frame
	await process_frame
	var rest_corner := _drawn_top_left(stage)
	_expect(_is_whole(rest_corner), "setup: at rest the view is whole")
	stage.rig.start_shake(0.4, 6.0)
	var every_frame_whole := true
	var most_displaced := 0.0
	var frames := 0
	while stage.rig.shake_time_left > 0.0 and frames < 2000:
		await process_frame
		frames += 1
		var corner := _drawn_top_left(stage)
		every_frame_whole = every_frame_whole and _is_whole(corner)
		most_displaced = maxf(most_displaced, _largest_move(corner, rest_corner))
	_expect(frames > 3, "setup: the shake lasted %d frames" % frames)
	_expect(every_frame_whole, "through the whole shake the view's corner is a whole pixel on every frame: the shake moves it by whole pixels")
	_expect(most_displaced >= 2.0, "and the shake still shakes: it moved the view %d px at most from where it rests (strength 6)" % int(most_displaced))
	await process_frame
	await process_frame
	_expect(_drawn_top_left(stage).is_equal_approx(rest_corner), "when it is over the view is back exactly where it rested")
	_free_stage(stage)


## The setting is the CameraBridge's shake_scale: it multiplies what a hit asks for before the rig hears of it.
func _check_the_shake_is_scaled_by_the_setting() -> void:
	var stage := _make_stage(0.0)
	stage.rig.setup(_grid(72, 40))
	stage.hero.position = Vector2(1000, 600)
	await process_frame
	await process_frame
	var rest_corner := _drawn_top_left(stage)
	var bridge := CameraBridge.new()
	bridge.attach(stage.rig)
	# Scale 0: no shake at all.
	bridge.shake_scale = 0.0
	bridge.shake(0.3, 8.0)
	var moved_at_scale_zero := 0.0
	for _frame in 40:
		await process_frame
		moved_at_scale_zero = maxf(moved_at_scale_zero, _largest_move(_drawn_top_left(stage), rest_corner))
	_expect(moved_at_scale_zero == 0.0 and stage.rig.shake_time_left == 0.0, "Screen shake 0: a hit that asks for 8 px moves the view not at all")
	# Scale 0.25: a quarter of the strength, so the view never leaves a 2 px box (8 x 0.25 x 1.42, rounded).
	bridge.shake_scale = 0.25
	bridge.shake(0.3, 8.0)
	_expect(is_equal_approx(stage.rig.shake_strength, 2.0), "Screen shake 25 percent: the rig is asked for a quarter of the strength")
	var moved_at_quarter := 0.0
	var frames := 0
	while stage.rig.shake_time_left > 0.0 and frames < 2000:
		await process_frame
		frames += 1
		moved_at_quarter = maxf(moved_at_quarter, _largest_move(_drawn_top_left(stage), rest_corner))
	_expect(moved_at_quarter <= 2.0, "and the whole-pixel shake stays inside that quarter (%d px at most)" % int(moved_at_quarter))
	await process_frame
	await process_frame
	bridge.shake_scale = 1.0
	bridge.shake(0.3, 8.0)
	var moved_at_full := 0.0
	frames = 0
	while stage.rig.shake_time_left > 0.0 and frames < 2000:
		await process_frame
		frames += 1
		moved_at_full = maxf(moved_at_full, _largest_move(_drawn_top_left(stage), rest_corner))
	_expect(moved_at_full > moved_at_quarter, "Screen shake 100 percent: the same hit moves the view further (%d px against %d)" % [int(moved_at_full), int(moved_at_quarter)])
	_free_stage(stage)


func _check_the_shipped_hero_view_snaps() -> void:
	var paths := TestPaths.new(self)
	var hero_view := paths.load_scene(paths.actor_scene(&"player")).instantiate()
	var rig := hero_view.get_node_or_null("Camera2D") as CameraRig
	_expect(rig != null and rig.snap_to_whole_pixels, "the hero's own camera rig snaps to whole pixels (no scene turns it off)")
	_expect(rig != null and not rig.position_smoothing_enabled, "and the engine's smoothing, which would move the view after the snap, is off on it")
	hero_view.free()
