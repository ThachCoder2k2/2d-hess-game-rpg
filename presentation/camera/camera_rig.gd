class_name CameraRig
extends Camera2D

## A Camera2D that frames the grid board and can be tuned two ways:
##   - Per scene: set the @export knobs below in the editor (each room can differ).
##   - Per situation: call the runtime setters mid-game (combat vs explore, cutscene,
##     focus on a spot). Follow uses the scene tree — the rig is a child of the actor
##     it follows — so turning follow off detaches it (top_level) and holds a fixed
##     point instead.
##
## The picture it shows always starts on a whole pixel of the world (docs/game-base-plan.md D-30, requirement 10: "integer
## pixel snap"), see snap_to_whole_pixels. All art is drawn 1x1 pixels at 640x360, so a view that starts between two
## pixels would draw every sprite and tile across a pixel boundary and shimmer as the follow point eases or the screen
## shakes. A room that fits the screen is pinned on whole pixels already (limits_for_board); the snap is what keeps a
## scrolling world, the follow ease and the shake on them too.

## When true, the camera tracks its parent actor (tree-parented follow). When false,
## it detaches via top_level and holds focus_world_position.
@export var follow_enabled := true:
	set(value):
		follow_enabled = value
		_apply_follow_mode()

## When true, limit_* clamp the view to the current room's board rect so nothing past
## the edges shows. A board that fits the screen is statically framed: the camera is pinned
## so the board sits centred in the view (limits_for_board), whatever the target does, and every
## cell of it, so every threat, is on screen. A board larger than the screen scrolls as the target
## moves and stops at the board's edges. When false, limits are removed and the camera can always
## keep the target centered.
@export var clamp_to_board_bounds := true:
	set(value):
		clamp_to_board_bounds = value
		_apply_bounds()

## Camera zoom. >1 zooms in (the view shows fewer cells, so follow visibly scrolls even
## on a board that would otherwise fit the screen). 1.0 = whole board fits the viewport.
@export var zoom_level := 1.0:
	set(value):
		zoom_level = maxf(0.05, value)
		zoom = Vector2(zoom_level, zoom_level)
		_apply_bounds()

## Follow smoothing speed. 0 snaps the camera to the target; >0 eases toward it. While the view snaps to whole pixels
## the rig does the easing itself (the engine's smoothing would move the view after the snap), with the same
## exponential catch-up; the engine's own smoothing is used only when the snap is off.
@export var smoothing_speed := 8.0:
	set(value):
		smoothing_speed = maxf(0.0, value)
		_apply_engine_smoothing()

## When true (the default), every frame ends with the view starting on a whole pixel of the world: the follow, the ease
## and the board's limits happen first, then the picture is moved by less than half a pixel to the nearest whole one,
## and the shake moves it by whole pixels. Turn it off only for a view that is meant to move between pixels (a
## cutscene pan drawn at a higher resolution); the engine's smoothing then eases the view, as before M4.
@export var snap_to_whole_pixels := true:
	set(value):
		snap_to_whole_pixels = value
		_apply_engine_smoothing()
		if not value:
			offset = shake_offset

## The board this rig frames (EcsGrid — duck-typed: grid_origin, bounds,
## cell_size, cell_to_world). Set by setup(); used to read board bounds for
## clamping and to convert a cell into a world point for focus_cell.
var grid_world

## World point the camera holds while follow_enabled is false.
var focus_world_position := Vector2.ZERO

## Screen-shake state. start_shake() arms it; _process decays it and drives the
## built-in Camera2D offset, so shake never touches any gameplay node's position.
var shake_time_left := 0.0
var shake_duration := 0.0
var shake_strength := 0.0
## How far the shake has moved the picture this frame, in pixels (not yet whole: the snap rounds it).
var shake_offset := Vector2.ZERO

## Where the view is easing: the follow point the rig has reached on its way to the actor, in world pixels. Used only
## while the view snaps and smoothing_speed is above 0; the engine never sees it except as the rig's own position.
var _eased_follow_point := Vector2.ZERO
## Whether _eased_follow_point holds a real position. False after setup() and while follow is off, so the next frame
## starts on the actor instead of easing in from wherever the last room left the view.
var _has_eased_follow_point := false


## Binds the rig to a board and applies every current knob, then makes it the active
## camera. Call again after a room changes grid_world.bounds or grid_origin (the shell does, after
## every boot) so the clamp stays on the new room.
func setup(world) -> void:
	grid_world = world
	zoom = Vector2(zoom_level, zoom_level)
	_apply_engine_smoothing()
	_has_eased_follow_point = false
	_apply_bounds()
	_apply_follow_mode()
	make_current()
	if is_inside_tree() and not get_viewport().size_changed.is_connected(_apply_bounds):
		get_viewport().size_changed.connect(_apply_bounds)


## The limits that frame a board seen through a view that shows `visible_size` world pixels
## (docs/game-base-plan.md D-02, D-30). On an axis where the board fits the view, the limits are exactly
## one view wide around the board's centre, so the camera cannot move and the board stays centred
## (with a centred grid origin that is the centre of the picture). On an axis where it does not fit,
## the limits are the board's own edges: the camera scrolls and stops there. Whole pixels, floored.
static func limits_for_board(board_rect: Rect2, visible_size: Vector2) -> Rect2i:
	var from := board_rect.position
	var to := board_rect.end
	if board_rect.size.x <= visible_size.x:
		from.x = board_rect.get_center().x - visible_size.x * 0.5
		to.x = from.x + visible_size.x
	if board_rect.size.y <= visible_size.y:
		from.y = board_rect.get_center().y - visible_size.y * 0.5
		to.y = from.y + visible_size.y
	var whole_from := Vector2i(floori(from.x), floori(from.y))
	var whole_to := Vector2i(floori(to.x), floori(to.y))
	return Rect2i(whole_from, whole_to - whole_from)


func _process(delta: float) -> void:
	_advance_shake(delta)
	if snap_to_whole_pixels:
		_place_view_on_a_whole_pixel(delta)
	elif offset != shake_offset:
		offset = shake_offset


## The view's top-left corner, in world pixels, as the engine has it now. Whole after every frame while the view
## snaps (and the zoom is a whole number: a zoomed-out or fractionally zoomed view has no whole-pixel grid to land on).
func view_top_left() -> Vector2:
	return get_screen_center_position() - _visible_world_size(Vector2.ZERO) * 0.5


## Decays the shake and works out where it has moved the picture this frame.
func _advance_shake(delta: float) -> void:
	if shake_time_left <= 0.0:
		if shake_offset != Vector2.ZERO:
			shake_offset = Vector2.ZERO
			shake_strength = 0.0
		return
	shake_time_left = maxf(0.0, shake_time_left - delta)
	var progress := shake_time_left / maxf(shake_duration, 0.001)
	var amount := shake_strength * progress
	var tick := Time.get_ticks_msec() / 1000.0
	shake_offset = Vector2(sin(tick * 91.0), cos(tick * 77.0)) * amount


## Ends the frame with the view on a whole pixel. The engine has already followed the actor, but this frame's
## position is not known to it until it is asked again, and the shake and the snap are applied through the camera's
## offset, which the engine adds AFTER the board's limits (so the shake can show a few pixels past the board's edge,
## as it always did). Three steps: ease the follow point, ask the engine where the view lands without any offset, move
## it by the little that makes its top-left corner whole, plus the shake rounded to whole pixels.
func _place_view_on_a_whole_pixel(delta: float) -> void:
	if not is_inside_tree() or not is_current():
		offset = shake_offset
		return
	_ease_follow_point(delta)
	offset = Vector2.ZERO
	force_update_scroll()
	var unsnapped_top_left := view_top_left()
	offset = unsnapped_top_left.round() - unsnapped_top_left + shake_offset.round()
	force_update_scroll()


## Puts the rig where the actor is, or, with smoothing_speed above 0, a little behind it on its way (the exponential
## catch-up the engine's smoothing makes, done here because the engine's version cannot be snapped afterwards).
## The rig is the actor's child, so the lag is the rig's own position. Does nothing while follow is off: the rig is
## detached and holds focus_world_position.
func _ease_follow_point(delta: float) -> void:
	var actor := get_parent() as Node2D
	if not follow_enabled or actor == null or smoothing_speed <= 0.0:
		_has_eased_follow_point = false
		if follow_enabled:
			position = Vector2.ZERO
		return
	if not _has_eased_follow_point:
		_eased_follow_point = actor.global_position
		_has_eased_follow_point = true
	_eased_follow_point = _eased_follow_point.lerp(actor.global_position, 1.0 - exp(-smoothing_speed * delta))
	position = actor.to_local(_eased_follow_point)


## Situational: kick a decaying screen shake (e.g. on hits). Repeated calls keep
## the strongest/longest of the current and new shake.
func start_shake(duration: float, strength: float) -> void:
	shake_duration = maxf(shake_duration, duration)
	shake_time_left = maxf(shake_time_left, duration)
	shake_strength = maxf(shake_strength, strength)


## Situational: turn hero-follow on or off (off holds the last focus point).
func set_follow_enabled(value: bool) -> void:
	follow_enabled = value


## Situational: zoom in/out at runtime (e.g. tighter frame during combat).
func set_zoom_level(value: float) -> void:
	zoom_level = value


## Situational: point the camera at a specific cell. Takes effect immediately when
## follow is off; when follow is on it just records the fallback point.
func focus_cell(cell: Vector2i) -> void:
	if grid_world != null:
		focus_world_position = grid_world.cell_to_world(cell)
	if not follow_enabled:
		global_position = focus_world_position


func _apply_bounds() -> void:
	if grid_world == null:
		return
	if clamp_to_board_bounds:
		var origin: Vector2 = grid_world.grid_origin
		var board_pixel_size: Vector2i = grid_world.bounds.size * grid_world.cell_size
		var limits := limits_for_board(Rect2(origin, Vector2(board_pixel_size)), _visible_world_size(Vector2(board_pixel_size)))
		limit_left = limits.position.x
		limit_top = limits.position.y
		limit_right = limits.end.x
		limit_bottom = limits.end.y
	else:
		# Godot's effectively-unlimited sentinels.
		limit_left = -10000000
		limit_top = -10000000
		limit_right = 10000000
		limit_bottom = 10000000


## How many world pixels the view shows at the current zoom: the viewport divided by the zoom. Before the
## rig is in a tree it has no viewport, so `fallback_size` (the board itself, which pins nothing) stands in.
func _visible_world_size(fallback_size: Vector2) -> Vector2:
	if not is_inside_tree():
		return fallback_size
	return get_viewport_rect().size / maxf(zoom.x, 0.0001)


## The engine's own smoothing is on only when the rig is not snapping: the snap has to be the last thing that moves
## the view, and the engine's ease would move it after.
func _apply_engine_smoothing() -> void:
	position_smoothing_enabled = smoothing_speed > 0.0 and not snap_to_whole_pixels
	position_smoothing_speed = maxf(0.001, smoothing_speed)


func _apply_follow_mode() -> void:
	# Follow = inherit the parent actor's transform (tree-parented). Static = detach
	# with top_level and hold focus_world_position.
	top_level = not follow_enabled
	_has_eased_follow_point = false
	if follow_enabled:
		position = Vector2.ZERO
	elif is_inside_tree():
		global_position = focus_world_position
