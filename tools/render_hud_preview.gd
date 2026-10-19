extends SceneTree

## Draws the production HUD over the tallest board and writes the pictures, so the owner can see "the HUD stays in its two strips and
## never covers a row of the board" (docs/game-base-plan.md D-29, 10; tests/presentation/test_hud_safe_zone.gd is the gate) without
## opening the editor or playing a room:
##
##   assets/_generated/previews/hud_playing.png        a fight: Courage 2 of 3, the thrust ready, 3 of 4 enemies, a sentence on the status line
##   assets/_generated/previews/hud_top_strip_full.png the top strip at its fullest: five pips, a cooldown, twelve enemies, Rank 8
##   assets/_generated/previews/hud_debug_readout.png  F3: the debug readout in the place of the control hints
##   assets/_generated/previews/hud_gamepad.png        the control hints after the pad was touched
##   assets/_generated/previews/hud_result.png         the result panel of a won room
##   assets/_generated/previews/hud_pseudo_language.png the top strip and the result panel with every line 40 percent longer
##
## The board is an 18 x 9 checker (the tallest the strips leave room for), centred in the 640 x 360 picture, so a widget that
## covers a row of it is drawn covering it. Every picture is 1280 x 720: the game's own 640 x 360 at a whole-number 2x, nearest
## neighbour. The HUD is the real scene (res://presentation/ui/hud/hud.tscn) fed a HudSnapshot, as the game feeds it.
##
## NEEDS A WINDOW: it draws with the real renderer, so run it WITHOUT --headless (a window opens for a moment):
##
##   godot --path . -s tools/render_hud_preview.gd
##
## The output folder is gitignored (generated, never hand-edited). Exit code: 0 = written, 1 = a scene or the output could not be
## handled, 2 = there is no renderer (--headless).

const OUTPUT_DIRECTORY := "res://assets/_generated/previews"
const HUD_SCENE := "res://presentation/ui/hud/hud.tscn"
const BOARD_CELLS := Vector2i(18, 9)
const CELL_SIZE := 32
const ZOOM := 2
const FRAMES_TO_SETTLE := 3

const FLOOR_COLORS: Array[Color] = [Color("#8c7a66"), Color("#7a6a58")]
const BACKGROUND_COLOR := Color("#6b5a4c")

var _viewport: SubViewport
var _hud: GameHud
var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("RENDER HUD PREVIEW: this tool draws with the real renderer; run it without --headless")
		quit(2)
		return
	var hud_scene := load(HUD_SCENE) as PackedScene
	var view_size := Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width")),
		float(ProjectSettings.get_setting("display/window/size/viewport_height")))
	if hud_scene == null or DirAccess.make_dir_recursive_absolute(OUTPUT_DIRECTORY) != OK:
		printerr("RENDER HUD PREVIEW: cannot load %s or make %s" % [HUD_SCENE, OUTPUT_DIRECTORY])
		quit(1)
		return
	TextService.set_language(&"en")
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(view_size)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)
	_draw_the_board(view_size)
	_hud = hud_scene.instantiate() as GameHud
	_viewport.add_child(_hud)
	await process_frame

	var snapshot := _fight_snapshot()
	_hud.show_room(snapshot)
	_hud.set_status("MSG_ENEMY_PICKED_UP", {"piece": TextKey.of("ENEMY_PAWN_ARMED_PIECE"), "weapon": TextKey.of("ITEM_PENCIL_SPEAR_NAME")})
	await _write("hud_playing")

	var full := _fight_snapshot()
	full.player_courage_current = 4
	full.player_courage_max = 5
	full.room_enemies_remaining = 12
	full.room_enemies_total = 12
	full.skill_cooldown_left = 1.9
	full.skill_cooldown_duration = 2.0
	full.rank_label = 8
	_hud.refresh(full)
	await _write("hud_top_strip_full")

	_hud.refresh(snapshot)
	_hud.set_strike_owner(TextKey.of("ENEMY_PAWN_ARMED_PIECE"))
	_hud.set_debug_visible(true)
	await _write("hud_debug_readout")
	_hud.set_debug_visible(false)

	var pad := LastInputDevice.new()
	pad.device = InputGlyphs.Device.GAMEPAD
	_hud.add_child(pad)
	_hud.configure_controls(InputGlyphs.new(), pad)
	await _write("hud_gamepad")
	_hud.configure_controls(InputGlyphs.new(), null)

	_hud.show_result("UI_RESULT_CLEARED", "UI_RESULT_CLEARED_SUBTITLE")
	await _write("hud_result")

	TextService.install_pseudo_language()
	TextService.set_language(&"qps")
	_hud.refresh(full)
	await _write("hud_pseudo_language")
	TextService.set_language(&"en")
	quit(1 if _failed else 0)


## The board's rows as a checker, under the HUD.
func _draw_the_board(view_size: Vector2) -> void:
	var backdrop := ColorRect.new()
	backdrop.color = BACKGROUND_COLOR
	backdrop.size = view_size
	_viewport.add_child(backdrop)
	var origin := EcsGrid.centred_origin(BOARD_CELLS, CELL_SIZE, view_size)
	for row in BOARD_CELLS.y:
		for column in BOARD_CELLS.x:
			var cell := ColorRect.new()
			cell.color = FLOOR_COLORS[(row + column) % 2]
			cell.position = origin + Vector2(column, row) * CELL_SIZE
			cell.size = Vector2(CELL_SIZE, CELL_SIZE)
			_viewport.add_child(cell)


func _fight_snapshot() -> HudSnapshot:
	var snapshot := HudSnapshot.new()
	snapshot.player_entity = 1
	snapshot.player_courage_current = 2
	snapshot.player_courage_max = 3
	snapshot.player_cell = Vector2i(3, 7)
	snapshot.player_facing = Vector2i.UP
	snapshot.sword_unlocked = true
	snapshot.room_enemies_remaining = 3
	snapshot.room_enemies_total = 4
	return snapshot


## Lets the viewport draw, then saves it at 2x.
func _write(picture_name: String) -> void:
	for _frame in FRAMES_TO_SETTLE:
		await process_frame
	var image := _viewport.get_texture().get_image()
	image.resize(image.get_width() * ZOOM, image.get_height() * ZOOM, Image.INTERPOLATE_NEAREST)
	var path := "%s/%s.png" % [OUTPUT_DIRECTORY, picture_name]
	if image.save_png(path) != OK:
		printerr("RENDER HUD PREVIEW: cannot write %s" % path)
		_failed = true
		return
	print("RENDER HUD PREVIEW: wrote %s (%d x %d)" % [path, image.get_width(), image.get_height()])
