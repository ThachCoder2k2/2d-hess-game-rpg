extends UnboundTest

## The HUD safe zone (requirement 180; docs/game-base-plan.md 10, D-29, 15 M4): no widget of the production HUD covers a
## row of the board. The picture is 640 x 360 and the tallest board is 18 x 9 cells of 32 px, centred, so its rows run from
## y 36 to y 324; the HUD lives in the two strips left over, the top one (y 0 to 32, at most 28 px tall, the boss bar inside it)
## and the bottom one (y 326 to 360). The M2 review found the old HUD overlapping row 0 by about 10 px: its status line
## sat at y 28 to 44 and its strike line at y 322 to 336.
##
## Measured on the real HUD scene, every widget in `GameHud.widgets()` SHOWN OR RESERVED (a hidden Believe slot and boss
## bar keep their rectangles), against the board rectangle of every room the game has and against the largest board the
## strips allow. Held to:
##   - the widget lies inside the top strip or inside the bottom strip, at least SIDE_MARGIN from the left and right edges
##     of the picture, and a widget in the top strip is at most MOST_BAR_HEIGHT tall;
##   - it intersects no board;
##   - no two widgets overlap, except the control hints and the debug readout, which are the same place on purpose
##     (F3 swaps them);
##   - the two reserved slots (Believe, the boss bar) exist and are hidden;
##   - the effects that DO cover the board, the damage flash and the result panel, are hidden at rest and are not widgets
##     of the strips: the panel is shown only when the room has ended.
## The measuring is run first on rectangles that must be reported: the old HUD's own, a widget that pokes into row 0 from
## above, one that pokes into the last row from below, and one that is too tall.

const VIEW_SIZE := Vector2(640, 360)
const TOP_STRIP := Rect2(0, 0, 640, 32)
const BOTTOM_STRIP := Rect2(0, 326, 640, 34)
const MOST_BAR_HEIGHT := 28.0
const SIDE_MARGIN := 4.0
## The largest board the strips leave room for: 18 columns by 9 rows.
const LARGEST_BOARD_CELLS := Vector2i(18, 9)
const CELL_SIZE := 32

var paths := TestPaths.new(self)


func _init() -> void:
	suite_title = "HUD SAFE ZONE TEST"
	await process_frame
	_the_measuring_can_fail()
	var boards := _the_boards()
	var hud := paths.load_scene(paths.hud_scene()).instantiate() as GameHud
	root.add_child(hud)
	await process_frame
	_every_widget_is_its_own_scene(hud)
	_every_widget_keeps_to_a_strip(hud, boards)
	_no_two_widgets_overlap(hud)
	_the_reserved_slots(hud)
	_the_effects_that_cover_the_board(hud)
	hud.set_debug_visible(true)
	_every_widget_keeps_to_a_strip(hud, boards, " (with the debug readout up)")
	hud.queue_free()
	finish()


## Every board a room of the game has (read off the room scenes) and the largest board, as { name: Rect2 }.
func _the_boards() -> Dictionary:
	var boards := {}
	boards["the largest board, %d x %d" % [LARGEST_BOARD_CELLS.x, LARGEST_BOARD_CELLS.y]] = _board_rect(LARGEST_BOARD_CELLS)
	var room_count := 0
	for room_id in DirAccess.get_directories_at(paths.rooms_directory()):
		if room_id.begins_with("_"):
			continue
		var room := paths.load_scene(paths.room_scene(StringName(room_id))).instantiate()
		var size: Variant = room.get("board_size")
		if size is Vector2i:
			boards["room %s, %d x %d" % [room_id, size.x, size.y]] = _board_rect(size)
			room_count += 1
		room.free()
	_expect(room_count >= 5, "setup: the walk read the board of %d rooms (at least 5)" % room_count)
	return boards


func _board_rect(cells: Vector2i) -> Rect2:
	return Rect2(EcsGrid.centred_origin(cells, CELL_SIZE, VIEW_SIZE), Vector2(cells * CELL_SIZE))


## The sentences that say why `rect` is not a safe place for a widget, empty when it is.
func _problems_of(rect: Rect2, boards: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	var in_top := TOP_STRIP.encloses(rect)
	var in_bottom := BOTTOM_STRIP.encloses(rect)
	if not in_top and not in_bottom:
		problems.append("is in neither strip")
	if rect.position.x < SIDE_MARGIN or rect.end.x > VIEW_SIZE.x - SIDE_MARGIN:
		problems.append("is closer than %d px to a side of the picture" % int(SIDE_MARGIN))
	if in_top and rect.size.y > MOST_BAR_HEIGHT:
		problems.append("is %d px tall in the top strip (at most %d)" % [int(rect.size.y), int(MOST_BAR_HEIGHT)])
	for board_name: String in boards:
		var board: Rect2 = boards[board_name]
		if board.grow(-0.01).intersects(rect):
			problems.append("covers %s (its rows run y %d to %d)" % [board_name, int(board.position.y), int(board.end.y)])
	return problems


func _the_measuring_can_fail() -> void:
	var boards := {"the largest board": _board_rect(LARGEST_BOARD_CELLS)}
	_expect(_problems_of(Rect2(8, 4, 624, 42), boards).size() > 0, "the measuring reports the old HUD's top panel (y 4 to 46: it covered row 0)")
	_expect(_problems_of(Rect2(18, 28, 606, 16), boards).size() > 0, "and the old status line (y 28 to 44)")
	_expect(_problems_of(Rect2(490, 322, 136, 14), boards).size() > 0, "and the old strike line (y 322 to 336: it covered the last row)")
	_expect(_problems_of(Rect2(6, 2, 100, 30), boards).size() > 0, "and a bar 30 px tall in the top strip")
	_expect(_problems_of(Rect2(0, 4, 100, 24), boards).size() > 0, "and one against the picture's edge")
	_expect(_problems_of(Rect2(6, 4, 146, 24), boards).is_empty() and _problems_of(Rect2(8, 342, 624, 16), boards).is_empty(), "while a widget inside a strip is let through")


func _every_widget_is_its_own_scene(hud: GameHud) -> void:
	var scene_paths: Array[String] = []
	var all_in_the_widgets_folder := true
	for widget in hud.widgets():
		var scene_path := widget.scene_file_path
		scene_paths.append(scene_path)
		all_in_the_widgets_folder = all_in_the_widgets_folder and scene_path.begins_with("res://presentation/ui/hud/widgets/")
	var distinct := {}
	for scene_path in scene_paths:
		distinct[scene_path] = true
	_expect(hud.widgets().size() >= 8 and not scene_paths.has("") and all_in_the_widgets_folder, "the HUD is %d widgets, each instanced from a scene of its own under presentation/ui/hud/widgets/" % hud.widgets().size())
	_expect(distinct.size() == scene_paths.size(), "and no two widgets share a scene")


func _every_widget_keeps_to_a_strip(hud: GameHud, boards: Dictionary, suffix := "") -> void:
	var all_clear := true
	for widget in hud.widgets():
		var problems := _problems_of(widget.get_global_rect(), boards)
		if not problems.is_empty():
			all_clear = false
			printerr("  %s %s: %s" % [widget.name, widget.get_global_rect(), "; ".join(problems)])
	_expect(all_clear, "every widget, shown or reserved, lies in a strip, off the picture's edges, and off the rows of all %d boards%s" % [boards.size(), suffix])


func _no_two_widgets_overlap(hud: GameHud) -> void:
	var widgets := hud.widgets()
	var meeting: Array[String] = []
	for first_index in widgets.size():
		for second_index in range(first_index + 1, widgets.size()):
			var first := widgets[first_index]
			var second := widgets[second_index]
			var is_the_swapped_pair := (first == hud.control_prompts and second == hud.debug_readout) or (first == hud.debug_readout and second == hud.control_prompts)
			if not is_the_swapped_pair and first.get_global_rect().grow(-0.01).intersects(second.get_global_rect()):
				meeting.append("%s and %s" % [first.name, second.name])
	_expect(meeting.is_empty(), "no two widgets overlap (%s)" % ", ".join(meeting))
	_expect(hud.control_prompts.get_global_rect() == hud.debug_readout.get_global_rect(), "and the debug readout takes exactly the place of the control hints")


func _the_reserved_slots(hud: GameHud) -> void:
	_expect(hud.believe_slot != null and hud.boss_bar_slot != null and not hud.believe_slot.visible and not hud.boss_bar_slot.visible, "the Believe slot and the boss bar slot exist and are hidden: reserved for M10 and M8b")
	_expect(hud.boss_bar_slot.size == Vector2(96, 20), "the boss bar slot is the asset list's 96 x 20 frame, so the whole bar stays inside the 28 px strip")
	_expect(not hud.rank_badge.visible, "the Rank badge is hidden until the snapshot has a Rank label")


func _the_effects_that_cover_the_board(hud: GameHud) -> void:
	var effects: Array[Node] = [hud.damage_flash, hud.result_panel]
	var effect_among_the_widgets := false
	for widget in hud.widgets():
		effect_among_the_widgets = effect_among_the_widgets or effects.has(widget)
	_expect(not effect_among_the_widgets, "the damage flash and the result panel are not widgets of the strips")
	_expect(not hud.damage_flash.visible and not hud.result_panel.visible, "and both are hidden at rest: the flash lasts a fifth of a second after a hit, the panel appears when the room ends")
