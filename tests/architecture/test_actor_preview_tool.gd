extends UnboundTest

## tools/render_actor_preview.gd is how the owner sees "a piece is smaller than its cell" without
## opening the editor, so it has to keep working: it runs headless, exits 0, and writes a picture
## of the right size, at a whole-number zoom, with the grid lines and the margin squares drawn and
## the pieces in their cells. (test_pieces_inside_cell is the gate on the numbers; this one guards
## the picture the owner looks at.)

const TOOL_PATH := "res://tools/render_actor_preview.gd"
const FIRST_CELL_ROW_OF_HERO := 0
## The hero's "alert" cell is empty on purpose: the hero never telegraphs.
const HERO_ALERT_COLUMN := 8
const HERO_REST_COLUMN := 0


func _init() -> void:
	suite_title = "ACTOR PREVIEW TOOL TEST"
	watchdog_seconds = 55.0
	var paths := TestPaths.new(self)
	var tool_script := load(TOOL_PATH) as GDScript
	if not _expect(tool_script != null, "tools/render_actor_preview.gd loads"):
		finish()
		return
	var constants := tool_script.get_script_constant_map()
	var output_path := String(constants["OUTPUT_PATH"])
	var zoom := int(constants["ZOOM"])
	var name_strip_width := int(constants["NAME_STRIP_WIDTH"])
	var header_height := int(constants["HEADER_HEIGHT"])
	var row_count := (constants["ACTORS"] as Array).size()
	var column_count := (constants["COLUMNS"] as Array).size()
	var table := ContentDb.piece_sizes()
	var cell_size := table.cell_size

	var absolute_output := ProjectSettings.globalize_path(output_path)
	if FileAccess.file_exists(output_path):
		DirAccess.remove_absolute(absolute_output)
	var output: Array = []
	var arguments := PackedStringArray(["--headless", "--path", paths.project_directory_on_disk(), "-s", TOOL_PATH])
	var exit_code := OS.execute(OS.get_executable_path(), arguments, output, true)
	var printed := "".join(PackedStringArray(output))
	_expect(exit_code == 0, "the tool exits 0 (got %d)" % exit_code)
	_expect(printed.contains("RENDER ACTOR PREVIEW: wrote"), "the tool says it wrote the picture")
	if not _expect(FileAccess.file_exists(output_path), "%s exists" % output_path):
		finish()
		return

	var picture := Image.load_from_file(absolute_output)
	if not _expect(picture != null and not picture.is_empty(), "the picture loads"):
		finish()
		return
	var expected_width := (name_strip_width + column_count * cell_size) * zoom
	var expected_height := (header_height + row_count * cell_size) * zoom
	_expect(picture.get_width() == expected_width and picture.get_height() == expected_height,
		"the picture is %d x %d: %d rows of %d cells of %d px at %dx (it is %d x %d)" % [expected_width, expected_height, row_count, column_count, cell_size, zoom, picture.get_width(), picture.get_height()])
	_expect(zoom >= 4 and picture.get_width() % zoom == 0 and picture.get_height() % zoom == 0, "the zoom is a whole number, at least 4x")

	# The grid line on the left edge of the first cell and the margin square inside it.
	var cells_left := name_strip_width * zoom
	var cells_top := header_height * zoom
	_expect(picture.get_pixel(cells_left, cells_top + zoom) == constants["GRID_COLOR"], "grid lines are drawn on the cell edges")
	var margin_offset := table.minimum_margin * zoom
	_expect(picture.get_pixel(cells_left + margin_offset, cells_top + margin_offset + zoom) == constants["MARGIN_COLOR"], "the margin square is drawn %d px inside the cell" % table.minimum_margin)

	# The hero stands in its first cell and the "alert" cell is empty: count what is not background.
	var hero_rest_pixels := _pieces_pixels_in_cell(picture, constants, FIRST_CELL_ROW_OF_HERO, HERO_REST_COLUMN, cell_size)
	var hero_alert_pixels := _pieces_pixels_in_cell(picture, constants, FIRST_CELL_ROW_OF_HERO, HERO_ALERT_COLUMN, cell_size)
	_expect(hero_rest_pixels > 100 * zoom * zoom / 4, "the hero is drawn in its first cell (%d non-background pixels)" % hero_rest_pixels)
	_expect(hero_alert_pixels == 0, "the hero's empty 'alert' cell has nothing in it (%d non-background pixels)" % hero_alert_pixels)
	finish()


## Pixels inside a cell (inside the margin square, so the guide lines do not count) that are not
## one of the two cell background colours.
func _pieces_pixels_in_cell(picture: Image, constants: Dictionary, row: int, column: int, cell_size: int) -> int:
	var zoom := int(constants["ZOOM"])
	var margin_offset := 3 * zoom
	var cell_pixels := cell_size * zoom
	var left := int(constants["NAME_STRIP_WIDTH"]) * zoom + column * cell_pixels
	var top := int(constants["HEADER_HEIGHT"]) * zoom + row * cell_pixels
	var backgrounds: Array = constants["CELL_COLORS"]
	var count := 0
	for y in range(top + margin_offset, top + cell_pixels - margin_offset):
		for x in range(left + margin_offset, left + cell_pixels - margin_offset):
			if not backgrounds.has(picture.get_pixel(x, y)):
				count += 1
	return count
