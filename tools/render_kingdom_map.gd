extends SceneTree

## Renders the whole kingdom to a single image, so the map can be reviewed
## without opening the editor or walking it in-game.
##
## Run WITH a renderer (no --headless), capturing frames to a folder:
##   Godot --path . -s tools/render_kingdom_map.gd \
##     --write-movie /tmp/kingdom/map.png --fixed-fps 10
##
## The camera zooms out to fit all 72x40 cells in the window; the last frame
## written is the finished map.

const MAP_SCENE := "res://objects/world/kingdom_world_tilemap.tscn"
const BOARD_SIZE := Vector2i(72, 40)
const CELL_SIZE := 32
const GRID_ORIGIN := Vector2(64, 36)

## Frames to hold before quitting — the movie writer needs a few to flush.
const HOLD_FRAMES := 8

var frames_left := HOLD_FRAMES


func _init() -> void:
	var map_scene := load(MAP_SCENE) as PackedScene
	if map_scene == null:
		printerr("RENDER KINGDOM MAP: cannot load %s" % MAP_SCENE)
		quit(1)
		return

	var stage := Node2D.new()
	stage.add_child(map_scene.instantiate())

	var board_pixels := Vector2(BOARD_SIZE) * CELL_SIZE
	# The viewport has no size yet during _init, and the OS window may be
	# scaled or maximized — the project's render size is what gets captured.
	var window_size := Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width")),
		float(ProjectSettings.get_setting("display/window/size/viewport_height")))
	var camera := Camera2D.new()
	# Zoom below 1 pulls back; take the tighter axis so nothing is cropped.
	camera.zoom = Vector2.ONE * minf(window_size.x / board_pixels.x, window_size.y / board_pixels.y)
	camera.position = GRID_ORIGIN + board_pixels * 0.5
	stage.add_child(camera)

	root.add_child(stage)
	camera.make_current()
	print("RENDER KINGDOM MAP: staged %s at zoom %.3f" % [MAP_SCENE, camera.zoom.x])


func _process(_delta: float) -> bool:
	frames_left -= 1
	if frames_left <= 0:
		print("RENDER KINGDOM MAP: done")
		quit(0)
	return false
