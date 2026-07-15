class_name CameraRig
extends Camera2D

## A Camera2D that frames the grid board and can be tuned two ways:
##   - Per scene: set the @export knobs below in the editor (each room can differ).
##   - Per situation: call the runtime setters mid-game (combat vs explore, cutscene,
##     focus on a spot). Follow uses the scene tree — the rig is a child of the actor
##     it follows — so turning follow off detaches it (top_level) and holds a fixed
##     point instead.

## When true, the camera tracks its parent actor (tree-parented follow). When false,
## it detaches via top_level and holds focus_world_position.
@export var follow_enabled := true:
	set(value):
		follow_enabled = value
		_apply_follow_mode()

## When true, limit_* clamp the view to the current room's board rect so nothing past
## the edges shows. A board smaller than the screen ends up statically framed; a board
## larger than the screen scrolls as the target moves. When false, limits are removed
## and the camera can always keep the target centered.
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

## Follow smoothing speed. 0 snaps the camera to the target; >0 eases toward it.
@export var smoothing_speed := 8.0:
	set(value):
		smoothing_speed = maxf(0.0, value)
		position_smoothing_enabled = smoothing_speed > 0.0
		position_smoothing_speed = maxf(0.001, smoothing_speed)

## The board this rig frames. Set by setup(); used to read board bounds for clamping
## and to convert a cell into a world point for focus_cell / static framing.
var grid_world: GridWorld

## World point the camera holds while follow_enabled is false.
var focus_world_position := Vector2.ZERO

## Screen-shake state. start_shake() arms it; _process decays it and drives the
## built-in Camera2D offset, so shake never touches any gameplay node's position.
var shake_time_left := 0.0
var shake_duration := 0.0
var shake_strength := 0.0


## Binds the rig to a board and applies every current knob, then makes it the active
## camera. Call again after a room changes grid_world.bounds so the clamp stays right.
func setup(world: GridWorld) -> void:
	grid_world = world
	zoom = Vector2(zoom_level, zoom_level)
	position_smoothing_enabled = smoothing_speed > 0.0
	position_smoothing_speed = maxf(0.001, smoothing_speed)
	_apply_bounds()
	_apply_follow_mode()
	make_current()


func _process(delta: float) -> void:
	if shake_time_left <= 0.0:
		if offset != Vector2.ZERO:
			offset = Vector2.ZERO
			shake_strength = 0.0
		return
	shake_time_left = maxf(0.0, shake_time_left - delta)
	var progress := shake_time_left / maxf(shake_duration, 0.001)
	var amount := shake_strength * progress
	var tick := Time.get_ticks_msec() / 1000.0
	offset = Vector2(sin(tick * 91.0), cos(tick * 77.0)) * amount


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
		var origin := grid_world.grid_origin
		var board_pixel_size := grid_world.bounds.size * grid_world.cell_size
		limit_left = int(origin.x)
		limit_top = int(origin.y)
		limit_right = int(origin.x + board_pixel_size.x)
		limit_bottom = int(origin.y + board_pixel_size.y)
	else:
		# Godot's effectively-unlimited sentinels.
		limit_left = -10000000
		limit_top = -10000000
		limit_right = 10000000
		limit_bottom = 10000000


func _apply_follow_mode() -> void:
	# Follow = inherit the parent actor's transform (tree-parented). Static = detach
	# with top_level and hold focus_world_position.
	top_level = not follow_enabled
	if follow_enabled:
		position = Vector2.ZERO
	elif is_inside_tree():
		global_position = focus_world_position
