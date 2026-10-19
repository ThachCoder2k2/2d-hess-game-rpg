extends UnboundTest

## A piece sliding between two cells is drawn on whole pixels (requirement 10, "pixel-snapped motion and camera, no subpixel
## blur"; docs/game-base-plan.md D-30, 15 M4). All art is drawn at 1x1 pixels, so a piece between two pixels is blurred
## across both. test_camera_snap holds the camera half; this holds the piece half: ViewSyncSystem works the slide out in
## floats (the eased interpolation between the two cells) and draws the view on the nearest whole pixel, every frame, and
## the piece ends exactly on its cell. The simulation never sees the rounded position: the cell, the progress and the
## reserve-to-commit window are the same numbers as before.
##
## Driven on the real game scene with the hero's own MoveIntent, frame by frame. The measuring is shown to be able to fail:
## the unrounded position of the same frames is NOT whole on most of them.

const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "piece_slide_snap"
## How far from a whole number a coordinate may be: floating-point noise, nothing more.
const WHOLE_TOLERANCE := 0.0005
const FRAME_SECONDS := 0.01
const FRAMES_TO_WATCH := 120


func _init() -> void:
	suite_title = "PIECE SLIDE SNAP TEST"
	call_deferred("_run")


func _run() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	var main := await Support.boot_main(self)
	var world := Support.ecs_of(main)
	Support.remove_enemy_ai(main)
	var direction := _a_direction_the_hero_can_step(main)
	if not _expect(direction != Vector2i.ZERO, "setup: the hero has a free cell beside it"):
		Support.end_suite(self, save_service)
		return
	var start_cell := Support.player_cell(main)
	var move := Support.player_move_state(main)
	var intent: EcsComponents.MoveIntent = world.get_component(Support.player_id_of(main), EcsComponents.MOVE_INTENT)
	intent.direction = direction

	var sliding_frames := 0
	var off_pixel_frames := 0
	var unrounded_off_pixel_frames := 0
	var distinct_positions := {}
	var went_backwards := false
	var previous_distance := 0.0
	for _frame in FRAMES_TO_WATCH:
		main._process(FRAME_SECONDS)
		if not move.moving:
			continue
		sliding_frames += 1
		var view_position := Support.player_view_position(main)
		if not _is_whole(view_position):
			off_pixel_frames += 1
		var eased := 1.0 - (1.0 - move.progress) * (1.0 - move.progress)
		var unrounded := world.grid.cell_to_world(move.from_cell).lerp(world.grid.cell_to_world(move.to_cell), eased)
		if not _is_whole(unrounded):
			unrounded_off_pixel_frames += 1
		distinct_positions[view_position] = true
		var distance := view_position.distance_to(world.grid.cell_to_world(start_cell))
		if distance < previous_distance - WHOLE_TOLERANCE:
			went_backwards = true
		previous_distance = distance
	_expect(sliding_frames >= 4, "the hero slid for several frames (%d)" % sliding_frames)
	_expect(off_pixel_frames == 0, "on every frame of the slide the hero's picture is on a whole pixel (%d of %d frames were not)" % [off_pixel_frames, sliding_frames])
	_expect(unrounded_off_pixel_frames > 0, "the check can fail: the eased position, before rounding, is between pixels on %d of those frames" % unrounded_off_pixel_frames)
	_expect(distinct_positions.size() >= 3 and not went_backwards, "and it still moves, forward, in steps of whole pixels (%d positions)" % distinct_positions.size())
	_expect(not move.moving and Support.player_cell(main) == start_cell + direction, "the step landed on the next cell")
	_expect(Support.player_view_position(main) == world.grid.cell_to_world(start_cell + direction), "and the picture sits exactly on that cell's centre")
	Support.end_suite(self, save_service)


## A direction in which the hero's neighbour cell is free (the hero is at rest and the room is quiet).
func _a_direction_the_hero_can_step(main: Node) -> Vector2i:
	var world := Support.ecs_of(main)
	var cell := Support.player_cell(main)
	for direction in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		if world.grid.is_walkable(cell + direction) and not world.grid.entity_by_cell.has(cell + direction):
			return direction
	return Vector2i.ZERO


func _is_whole(point: Vector2) -> bool:
	return absf(point.x - roundf(point.x)) < WHOLE_TOLERANCE and absf(point.y - roundf(point.y)) < WHOLE_TOLERANCE
