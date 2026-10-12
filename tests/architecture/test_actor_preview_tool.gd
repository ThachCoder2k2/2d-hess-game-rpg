extends UnboundTest

## tools/render_actor_preview.gd is how the owner sees "a piece is smaller than its cell" without
## opening the editor, so it has to keep working AND keep telling the truth. It runs headless, exits
## 0 and writes two pictures at a whole-number zoom: the hero and the three enemy scenes, and every
## actor a room scene places, as placed. Each cell has a gutter, grid lines and margin squares are
## drawn under the pieces and never over their pixels, and any piece pixel that crosses the margin is
## painted magenta and counted: a normal run says 0, a run with the actors stretched says how many
## (so the picture is proven able to show an overflow, not only to show nothing wrong).
## test_pieces_inside_cell is the gate on the numbers; this one guards the pictures the owner looks at.

const TOOL_PATH := "res://tools/render_actor_preview.gd"
const FIRST_CELL_ROW_OF_HERO := 0
const ROW_OF_BLACK_PAWN := 1
## The hero's "alert" cell is empty on purpose: the hero never telegraphs.
const HERO_ALERT_COLUMN := 8
const HERO_REST_COLUMN := 0
const STRETCH_FACTOR := "1.5"

var constants: Dictionary
var table: PieceSizeTable


func _init() -> void:
	suite_title = "ACTOR PREVIEW TOOL TEST"
	watchdog_seconds = 55.0
	var tool_script := load(TOOL_PATH) as GDScript
	if not _expect(tool_script != null, "tools/render_actor_preview.gd loads"):
		finish()
		return
	constants = tool_script.get_script_constant_map()
	table = ContentDb.piece_sizes()
	var cell_size := table.cell_size
	var zoom := int(constants["ZOOM"])
	var pitch := cell_size + 2 * int(constants["CELL_GUTTER"])
	var column_count := (constants["COLUMNS"] as Array).size()

	for path_name in ["OUTPUT_PATH", "PLACED_OUTPUT_PATH", "OVERFLOW_DEMO_PATH"]:
		var stale_path := String(constants[path_name])
		if FileAccess.file_exists(stale_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(stale_path))
	var printed := _run_tool([])
	_expect(printed.count("RENDER ACTOR PREVIEW: wrote") == 2, "the tool says it wrote both pictures")
	_expect(printed.count("; 0 pixel(s) outside the margin") == 2, "both pictures report 0 pixels outside the margin")
	_expect(not FileAccess.file_exists(String(constants["OVERFLOW_DEMO_PATH"])), "a normal run does not write the overflow demo")

	# The first picture: the four canonical actors.
	var canonical := _load_picture(String(constants["OUTPUT_PATH"]))
	if canonical != null:
		var row_count := (constants["ACTORS"] as Array).size()
		_check_size(canonical, row_count, int(constants["NAME_STRIP_WIDTH"]), pitch, column_count, zoom, "pieces_in_cells.png")
		_check_cells(canonical, pitch, zoom)
		_expect(_count_pixels_of(canonical, constants["OVERFLOW_COLOR"]) == 0, "no piece pixel in pieces_in_cells.png is marked as crossing the margin")

	# The second picture: every actor a room places, as placed.
	var placed := _load_picture(String(constants["PLACED_OUTPUT_PATH"]))
	if placed != null:
		var placed_count := _count_actors_placed_in_rooms()
		_expect(placed_count >= 5, "the rooms place %d actors (at least 5)" % placed_count)
		_check_size(placed, placed_count, int(constants["PLACED_NAME_STRIP_WIDTH"]), pitch, column_count, zoom, "pieces_placed_in_rooms.png (one row per placed actor)")
		_expect(_count_pixels_of(placed, constants["OVERFLOW_COLOR"]) == 0, "no piece pixel in pieces_placed_in_rooms.png is marked as crossing the margin")

	# The proof that an overflow shows: stretch every actor and the tool must say so, and paint it.
	var stretched_printed := _run_tool(["--stretch=%s" % STRETCH_FACTOR])
	_expect(stretched_printed.count("RENDER ACTOR PREVIEW: wrote") == 1, "the stretched run writes one picture, the overflow demo")
	var pixels_reported := _reported_overflow_pixels(stretched_printed)
	_expect(pixels_reported > 0, "the stretched run reports pixels outside the margin (%d)" % pixels_reported)
	var demo := _load_picture(String(constants["OVERFLOW_DEMO_PATH"]))
	if demo != null:
		var demo_pixels := _count_pixels_of(demo, constants["OVERFLOW_COLOR"])
		_expect(demo_pixels > 0, "the overflow demo paints the crossing pixels in the loud colour (%d zoomed pixels)" % demo_pixels)
		_expect(demo_pixels == pixels_reported * zoom * zoom, "...exactly the pixels the tool counted (%d x %d x %d)" % [pixels_reported, zoom, zoom])
	finish()


func _run_tool(extra_arguments: Array) -> String:
	var paths := TestPaths.new(self)
	var arguments := PackedStringArray(["--headless", "--path", paths.project_directory_on_disk(), "-s", TOOL_PATH])
	if not extra_arguments.is_empty():
		arguments.append("--")
		for argument in extra_arguments:
			arguments.append(String(argument))
	var output: Array = []
	var exit_code := OS.execute(OS.get_executable_path(), arguments, output, true)
	_expect(exit_code == 0, "the tool exits 0%s (got %d)" % [" with %s" % " ".join(PackedStringArray(extra_arguments)) if not extra_arguments.is_empty() else "", exit_code])
	return "".join(PackedStringArray(output))


func _load_picture(path: String) -> Image:
	if not _expect(FileAccess.file_exists(path), "%s exists" % path):
		return null
	var picture := Image.load_from_file(ProjectSettings.globalize_path(path))
	if not _expect(picture != null and not picture.is_empty(), "%s loads" % path.get_file()):
		return null
	return picture


func _check_size(picture: Image, row_count: int, name_strip_width: int, pitch: int, column_count: int, zoom: int, label: String) -> void:
	var expected_width := (name_strip_width + column_count * pitch) * zoom
	var expected_height := (int(constants["HEADER_HEIGHT"]) + row_count * pitch) * zoom
	_expect(picture.get_width() == expected_width and picture.get_height() == expected_height,
		"%s is %d x %d: %d rows of %d cells of %d px with a %d px gutter, at %dx (it is %d x %d)" % [label, expected_width, expected_height, row_count, column_count, table.cell_size, int(constants["CELL_GUTTER"]), zoom, picture.get_width(), picture.get_height()])
	_expect(zoom >= 4 and picture.get_width() % zoom == 0 and picture.get_height() % zoom == 0, "%s: the zoom is a whole number, at least 4x" % label)


## Grid, margin line and pieces in the canonical picture.
func _check_cells(picture: Image, pitch: int, zoom: int) -> void:
	var gutter := int(constants["CELL_GUTTER"])
	var margin_pixels := table.minimum_margin * zoom
	var cell_pixels := table.cell_size * zoom
	var hero_left := (int(constants["NAME_STRIP_WIDTH"]) + gutter) * zoom
	var hero_top := (int(constants["HEADER_HEIGHT"]) + gutter) * zoom
	_expect(picture.get_pixel(hero_left, hero_top + zoom) == constants["GRID_COLOR"], "grid lines are drawn on the cell edge")
	_expect(picture.get_pixel(hero_left + margin_pixels, hero_top + margin_pixels + zoom) == constants["MARGIN_COLOR"], "the margin square is drawn %d px inside the cell" % table.minimum_margin)
	_expect(picture.get_pixel(hero_left - zoom, hero_top + zoom) == constants["BACKGROUND_COLOR"], "the gutter outside the cell edge is empty background")

	# The hero stands in its first cell and the "alert" cell is empty: count what is not background.
	var hero_rest_pixels := _pieces_pixels_in_cell(picture, FIRST_CELL_ROW_OF_HERO, HERO_REST_COLUMN, pitch)
	var hero_alert_pixels := _pieces_pixels_in_cell(picture, FIRST_CELL_ROW_OF_HERO, HERO_ALERT_COLUMN, pitch)
	_expect(hero_rest_pixels > 100 * zoom * zoom / 4, "the hero is drawn in its first cell (%d non-background pixels)" % hero_rest_pixels)
	_expect(hero_alert_pixels == 0, "the hero's empty 'alert' cell has nothing in it (%d non-background pixels)" % hero_alert_pixels)

	# The lines are laid UNDER the pieces: the hero keeps the whole top margin line, and the black
	# pawn's health pips sit on that line and leave a gap in it where their pixels are.
	var line_length := cell_pixels - 2 * margin_pixels
	var hero_line := _margin_line_pixels(picture, FIRST_CELL_ROW_OF_HERO, HERO_REST_COLUMN, pitch)
	var pawn_line := _margin_line_pixels(picture, ROW_OF_BLACK_PAWN, HERO_REST_COLUMN, pitch)
	_expect(hero_line == line_length, "nothing touches the hero's top margin line, so all %d of its pixels are drawn (%d)" % [line_length, hero_line])
	_expect(pawn_line < line_length, "the black pawn's pips sit on the margin line and are drawn over it, not under it (%d of %d line pixels left)" % [pawn_line, line_length])


## Pixels inside a cell (inside the margin square, so the guide lines do not count) that are not
## one of the cell background colours.
func _pieces_pixels_in_cell(picture: Image, row: int, column: int, pitch: int) -> int:
	var zoom := int(constants["ZOOM"])
	var gutter := int(constants["CELL_GUTTER"])
	var inside := (table.minimum_margin + 1) * zoom
	var cell_pixels := table.cell_size * zoom
	var left := (int(constants["NAME_STRIP_WIDTH"]) + column * pitch + gutter) * zoom
	var top := (int(constants["HEADER_HEIGHT"]) + row * pitch + gutter) * zoom
	var backgrounds: Array = constants["CELL_COLORS"]
	var count := 0
	for y in range(top + inside, top + cell_pixels - inside):
		for x in range(left + inside, left + cell_pixels - inside):
			if not backgrounds.has(picture.get_pixel(x, y)):
				count += 1
	return count


## How many pixels of the top margin line of a cell are the margin colour.
func _margin_line_pixels(picture: Image, row: int, column: int, pitch: int) -> int:
	var zoom := int(constants["ZOOM"])
	var gutter := int(constants["CELL_GUTTER"])
	var margin_pixels := table.minimum_margin * zoom
	var cell_pixels := table.cell_size * zoom
	var left := (int(constants["NAME_STRIP_WIDTH"]) + column * pitch + gutter) * zoom
	var top := (int(constants["HEADER_HEIGHT"]) + row * pitch + gutter) * zoom
	var count := 0
	for x in range(left + margin_pixels, left + cell_pixels - margin_pixels):
		if picture.get_pixel(x, top + margin_pixels) == constants["MARGIN_COLOR"]:
			count += 1
	return count


func _count_pixels_of(picture: Image, color: Color) -> int:
	var count := 0
	for y in picture.get_height():
		for x in picture.get_width():
			if picture.get_pixel(x, y) == color:
				count += 1
	return count


## The number the tool printed before "pixel(s) outside the margin" on its first line.
func _reported_overflow_pixels(printed: String) -> int:
	var matcher := RegEx.create_from_string("(\\d+) pixel\\(s\\) outside the margin")
	var found := matcher.search(printed)
	return int(found.get_string(1)) if found != null else -1


## How many actors the room scenes place (the rows of the second picture), counted here on its own.
func _count_actors_placed_in_rooms() -> int:
	var count := 0
	for room_id in ContentDb.ids(&"rooms"):
		var room_scene := ContentDb.fetch(&"rooms", room_id) as PackedScene
		if room_scene == null:
			continue
		var room := room_scene.instantiate()
		for child in room.get_children():
			var view := child as ActorView
			if view != null and view.definition != null:
				count += 1
		room.free()
	return count
