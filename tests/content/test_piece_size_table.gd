extends UnboundTest

## The size of a piece inside its cell is data (docs/owner-decisions.md, 2026-10-12: "a chess
## piece is smaller than its cell"; content/feel/piece_sizes.tres). This suite proves the shipped
## table says what the owner decided and that PieceSizeTable.validate() really holds the rules:
## every box fits its footprint with the margin, heights follow a real chess set, no kind twice.

const TABLE_PATH := "res://content/feel/piece_sizes.tres"
## Kinds the table must carry today, so the owner's ladder is not quietly shortened.
const REQUIRED_PIECE_TYPES: Array[StringName] = [&"pawn", &"knight", &"bishop", &"rook", &"queen", &"king"]


func _init() -> void:
	suite_title = "PIECE SIZE TABLE TEST"
	var table := load(TABLE_PATH) as PieceSizeTable
	if not _expect(table != null, "content/feel/piece_sizes.tres loads as a PieceSizeTable"):
		finish()
		return
	_check_shipped_table(table)
	_check_validation_bites(table)
	_check_pictures_against_rows(table)
	finish()


func _check_shipped_table(table: PieceSizeTable) -> void:
	var warnings := table.validate()
	for warning in warnings:
		printerr("  piece size table: %s" % warning)
	_expect(warnings.is_empty(), "the shipped table passes its own validate()")
	_expect(ContentDb.piece_sizes() != null and ContentDb.piece_sizes().resource_path == TABLE_PATH, "ContentDb.piece_sizes() returns content/feel/piece_sizes.tres")
	_expect(table.cell_size == EcsGrid.new().cell_size, "the table's cell_size equals the grid's cell size (%d)" % table.cell_size)
	_expect(table.minimum_margin >= 2, "the margin the owner asked for is at least 2 px (it is %d)" % table.minimum_margin)
	for piece_type in REQUIRED_PIECE_TYPES:
		_expect(table.row_for(piece_type) != null, "the table has a row for '%s'" % piece_type)

	# A piece is smaller than its cell: strictly inside, with the margin, on every side.
	var half_cell := table.cell_size / 2.0
	for row in table.rows:
		var extent := PieceSizeTable.vertical_extent_of(row)
		_expect(row.body_box.x < table.cell_size and row.body_box.y < table.cell_size, "%s: the box %s is smaller than the %d px cell" % [row.piece_type, row.body_box, table.cell_size])
		_expect(extent.x >= -half_cell + table.minimum_margin and extent.y <= half_cell - table.minimum_margin, "%s: the box stands between %d and %d px from the cell's centre, at least %d px from the top and bottom edges" % [row.piece_type, extent.x, extent.y, table.minimum_margin])
		_expect(row.body_box.x / 2.0 <= half_cell - table.minimum_margin, "%s: the box is %d wide, at least %d px from the side edges" % [row.piece_type, row.body_box.x, table.minimum_margin])

	# Heights follow a real chess set.
	var pawn := table.row_for(&"pawn")
	var queen := table.row_for(&"queen")
	var king := table.row_for(&"king")
	_expect(pawn.body_box.y < table.row_for(&"knight").body_box.y and pawn.body_box.y < table.row_for(&"bishop").body_box.y and pawn.body_box.y < table.row_for(&"rook").body_box.y, "a pawn is the lowest piece")
	_expect(table.row_for(&"knight").body_box.y < queen.body_box.y and table.row_for(&"bishop").body_box.y < queen.body_box.y and table.row_for(&"rook").body_box.y < queen.body_box.y, "knight, bishop and rook are lower than the queen")
	_expect(queen.body_box.y < king.body_box.y, "the king is the tallest piece")


## validate() is only worth having if it complains. Each case copies the shipped table, breaks it
## one way and requires the complaint to name the kind.
func _check_validation_bites(shipped: PieceSizeTable) -> void:
	var too_wide := _copy_of(shipped)
	too_wide.row_for(&"knight").body_box = Vector2i(29, 24)
	_expect(_complaints(too_wide).contains("'knight'") and _complaints(too_wide).contains("sides"), "a box too wide for the margin is reported, naming the kind")

	var too_tall := _copy_of(shipped)
	too_tall.row_for(&"king").body_box = Vector2i(22, 31)
	_expect(_complaints(too_tall).contains("'king'") and _complaints(too_tall).contains("top"), "a box that reaches the top edge is reported, naming the kind")

	var too_low := _copy_of(shipped)
	too_low.row_for(&"pawn").base_offset_y = 15
	_expect(_complaints(too_low).contains("'pawn'") and _complaints(too_low).contains("bottom"), "a base line too close to the bottom edge is reported, naming the kind")

	var cell_sized := _copy_of(shipped)
	cell_sized.row_for(&"queen").body_box = Vector2i(32, 32)
	cell_sized.row_for(&"queen").base_offset_y = 16
	_expect(_complaints(cell_sized).contains("'queen'"), "a piece exactly as big as its cell is reported: the owner wants it smaller")

	var knight_below_pawn := _copy_of(shipped)
	knight_below_pawn.row_for(&"knight").body_box = Vector2i(20, 22)
	_expect(_complaints(knight_below_pawn).contains("knight") and _complaints(knight_below_pawn).contains("taller than a pawn"), "a knight no taller than a pawn is reported (heights follow a real chess set)")

	var king_below_queen := _copy_of(shipped)
	king_below_queen.row_for(&"king").body_box = Vector2i(22, 26)
	_expect(_complaints(king_below_queen).contains("king") and _complaints(king_below_queen).contains("taller than a queen"), "a king no taller than a queen is reported")

	var listed_twice := _copy_of(shipped)
	var second_pawn := PieceSize.new()
	second_pawn.piece_type = &"pawn"
	listed_twice.rows.append(second_pawn)
	_expect(_complaints(listed_twice).contains("'pawn' is listed twice"), "a kind listed twice is reported")

	var without_ladder_kinds := PieceSizeTable.new()
	var lone_boss := PieceSize.new()
	lone_boss.piece_type = &"boss_test"
	lone_boss.body_box = Vector2i(60, 70)
	lone_boss.footprint_cells = Vector2i(3, 3)
	lone_boss.base_offset_y = 44
	without_ladder_kinds.rows.append(lone_boss)
	_expect(without_ladder_kinds.validate().is_empty(), "a boss row on a 3 x 3 footprint may be bigger than one cell and passes: the table allows bosses")
	lone_boss.footprint_cells = Vector2i.ONE
	_expect(_complaints(without_ladder_kinds).contains("'boss_test'"), "the same boss row on a single cell is reported")

	_expect(not PieceSizeTable.new().validate().is_empty(), "an empty table is reported")
	_expect(shipped.row_for(&"dragon") == null, "row_for() answers null for a kind the table does not have")


## How a body picture is judged and placed. Two shapes are allowed: a tight picture no larger than
## the kind's box, its bottom edge on the base line; or the art spec's cell-sized canvas (32 x 32,
## base rim on row 30) whose drawn pixels lie inside the box on that canvas. Sizes and pixel boxes
## are given directly, so no picture file is needed.
func _check_pictures_against_rows(table: PieceSizeTable) -> void:
	var canvas := Vector2i(table.cell_size, table.cell_size)
	_expect(table.cell_canvas_base_row == table.cell_size - 2, "the art spec's base row is %d of %d: two empty rows under the rim, the spec's anchor (16, 30)" % [table.cell_canvas_base_row, table.cell_size])
	_expect(table.is_cell_canvas(Vector2(canvas)) and not table.is_cell_canvas(Vector2(32, 40)) and not table.is_cell_canvas(Vector2(18, 22)), "only a picture exactly one cell big is the canvas of the art spec")

	# The boxes on the spec's canvas are the rectangles docs/assets prints: top at y=8 for the pawn,
	# 6 for knight, bishop and rook, 4 for the queen, 2 for the king, 2 px of margin at the sides.
	var expected_canvas_boxes := {&"pawn": Rect2i(7, 8, 18, 22), &"knight": Rect2i(6, 6, 20, 24), &"bishop": Rect2i(6, 6, 20, 24), &"rook": Rect2i(6, 6, 20, 24), &"queen": Rect2i(5, 4, 22, 26), &"king": Rect2i(5, 2, 22, 28)}
	for piece_type: StringName in expected_canvas_boxes:
		_expect(table.box_on_cell_canvas(table.row_for(piece_type)) == expected_canvas_boxes[piece_type], "the %s box on the spec's canvas is %s" % [piece_type, expected_canvas_boxes[piece_type]])

	# A tight picture: fits at the box, not a pixel over, placed on the base line.
	_expect(table.picture_problems(&"pawn", Vector2i(18, 22), Rect2i(0, 0, 18, 22)).is_empty(), "a tight 18 x 22 pawn fits its box")
	_expect(not table.picture_problems(&"pawn", Vector2i(19, 22), Rect2i(0, 0, 19, 22)).is_empty(), "a tight pawn one pixel too wide is reported")
	_expect("\n".join(table.picture_problems(&"pawn", Vector2i(26, 32), Rect2i(0, 0, 26, 32))).contains("its body picture is 26 x 32 px but a pawn may be drawn at most 18 x 22 px"), "an oversized tight picture is reported with both sizes")
	_expect(not table.picture_problems(&"pawn", Vector2i(32, 40), Rect2i(7, 8, 18, 22)).is_empty(), "the old 32 x 40 pawn picture is reported: it is not the cell-sized canvas")
	_expect(table.body_top_left(&"pawn", Vector2(18, 20)) == Vector2(-9, -6), "a tight 18 x 20 pawn stands with its bottom edge on the base line (top-left (-9, -6))")
	_expect(table.body_top_left(&"pawn", Vector2(18, 20), Vector2(1, -2)) == Vector2(-8, -8), "the visual's own anchor_offset nudges it from there")

	# The spec's canvas: the body box fits, anything outside it is reported, and it lands on the cell.
	_expect(table.picture_problems(&"pawn", canvas, Rect2i(7, 8, 18, 22)).is_empty(), "a pawn on the spec's canvas, its body exactly the box, fits")
	_expect(table.picture_problems(&"pawn", canvas, Rect2i(9, 12, 10, 14)).is_empty(), "a smaller body anywhere inside the box fits")
	_expect(table.picture_problems(&"knight", canvas, Rect2i(6, 6, 20, 24)).is_empty(), "a knight on the spec's canvas fits its 20 x 24 box")
	_expect(not table.picture_problems(&"pawn", canvas, Rect2i(6, 6, 20, 24)).is_empty(), "a pawn drawn as big as a knight on the canvas is reported")
	_expect("\n".join(table.picture_problems(&"pawn", canvas, Rect2i(7, 10, 18, 22))).contains("leave the 18 x 22 box of a pawn"), "a pawn body that sinks below the base rim is reported, naming the kind and the box")
	_expect(not table.picture_problems(&"pawn", canvas, Rect2i(8, 8, 18, 22)).is_empty(), "a pawn body shifted two pixels sideways is reported")
	_expect(table.picture_problems(&"pawn", canvas, Rect2i()).is_empty(), "a fully transparent canvas has nothing outside the box")
	_expect(table.picture_problems(&"dragon", canvas, Rect2i(0, 0, 32, 32)).is_empty(), "a kind with no row is for ContentDb to report, not this check")
	_expect(table.body_top_left(&"pawn", Vector2(canvas)) == Vector2(-16, -16), "the spec's canvas lands exactly on the cell: its top-left is the cell's")
	_expect(table.body_top_left(&"king", Vector2(canvas)) == Vector2(-16, -16), "...for a king too, whatever the box")
	_expect(table.body_top_left(&"pawn", Vector2(canvas), Vector2(0, 1)) == Vector2(-16, -15), "...and anchor_offset still nudges it")

	# A picture read from real pixels: the body box is found from the drawn pixels, not the png size.
	var image := Image.create_empty(canvas.x, canvas.y, false, Image.FORMAT_RGBA8)
	image.fill_rect(Rect2i(7, 8, 18, 22), Color.WHITE)
	var texture := ImageTexture.create_from_image(image)
	_expect(PieceSizeTable.opaque_rect_of(texture) == Rect2i(7, 8, 18, 22), "the drawn pixels of a canvas are found (7, 8, 18 x 22)")
	_expect(table.picture_problems_of_texture(&"pawn", texture).is_empty(), "a real 32 x 32 canvas with an 18 x 22 body passes for a pawn")
	image.fill_rect(Rect2i(7, 30, 18, 2), Color.WHITE)
	_expect(not table.picture_problems_of_texture(&"pawn", ImageTexture.create_from_image(image)).is_empty(), "the same canvas with feet in the two rows under the rim is reported")


func _complaints(table: PieceSizeTable) -> String:
	return "\n".join(table.validate())


func _copy_of(table: PieceSizeTable) -> PieceSizeTable:
	return table.duplicate(true) as PieceSizeTable
