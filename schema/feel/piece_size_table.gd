class_name PieceSizeTable
extends Resource

## The size of every kind of piece inside its cell, as data (content/feel/piece_sizes.tres). The
## owner's decision of 2026-10-12: "a chess piece is smaller than its cell", never exactly
## cell-sized and never taller than it, and heights follow a real chess set (pawn lowest, king
## tallest). This table is where that decision is written down; the actor view, the art contract
## and the tests all read it, and validate() holds the rules:
##   - every body box, with its base line, fits inside its footprint with `minimum_margin` pixels
##     to every edge;
##   - between the kinds that exist, pawn < knight, bishop, rook < queen < king in height;
##   - no kind is listed twice.
## A boss is one more row (a piece_type of its own, and a bigger footprint if it stands on
## several cells).

## The ladder of heights, shortest first. Kinds on the same rung may differ from each other; every
## kind on a rung must be strictly taller than every listed kind on the rungs below it.
const HEIGHT_LADDER: Array[Array] = [
	[&"pawn"],
	[&"knight", &"bishop", &"rook"],
	[&"queen"],
	[&"king"],
]

## The cell the boxes were drawn for, in pixels. A test holds it equal to EcsGrid.cell_size.
@export var cell_size := 32
## The least empty space, in pixels, between a piece and every edge of its footprint.
@export var minimum_margin := 2
## The art spec's canvas (docs/assets: every piece is drawn on a cell-sized canvas, 32 x 32, with
## its base rim on one row and the rows below it empty). A body picture exactly cell_size by
## cell_size is that canvas: the picture stands where the cell is, so row `cell_canvas_base_row`
## of the picture lies on the kind's base line (the spec's anchor (16, 30) is the row 30 of 32,
## which is `base_offset_y` 14 below the cell's centre). Any other body picture is "tight": no
## larger than the kind's box, its bottom edge on the base line.
@export var cell_canvas_base_row := 30
## One row per kind of piece.
@export var rows: Array[PieceSize] = []


## The row for a kind, or null when the table has none.
func row_for(piece_type: StringName) -> PieceSize:
	for row in rows:
		if row != null and row.piece_type == piece_type:
			return row
	return null


func piece_types() -> Array[StringName]:
	var kinds: Array[StringName] = []
	for row in rows:
		if row != null:
			kinds.append(row.piece_type)
	return kinds


## Is this picture size the art spec's cell-sized canvas (see `cell_canvas_base_row`)?
func is_cell_canvas(picture_size: Vector2) -> bool:
	return Vector2i(picture_size) == Vector2i(cell_size, cell_size)


## Where the top-left corner of a body picture goes, in pixels from the cell's centre: the picture
## is centred sideways (rounded down for an odd width, so it stays on whole pixels) and the row
## that carries its base stands on the kind's base line, then `anchor_offset` (a VisualDefinition's
## own nudge) is added. That row is the picture's bottom edge for a tight picture, and row
## `cell_canvas_base_row` for the cell-sized canvas of the art spec, which therefore lands exactly
## on the cell. A kind with no row stands the base on the cell's centre, the way the old art did.
## The one formula the view, the preview tool and the tests all use.
func body_top_left(piece_type: StringName, picture_size: Vector2, anchor_offset := Vector2.ZERO) -> Vector2:
	var row := row_for(piece_type)
	var base_line := float(row.base_offset_y) if row != null else 0.0
	var base_row_of_picture := float(cell_canvas_base_row) if is_cell_canvas(picture_size) else picture_size.y
	return Vector2(-floorf(picture_size.x / 2.0), base_line - base_row_of_picture) + anchor_offset


## Where a kind's box lies on the art spec's cell-sized canvas, in the canvas's own pixels: centred
## sideways, its bottom edge on `cell_canvas_base_row`. For the pawn on 32 x 32 that is the rectangle
## (7, 8) to (25, 30) the spec describes ("18 x 22, top at y=8").
func box_on_cell_canvas(row: PieceSize) -> Rect2i:
	return Rect2i(Vector2i(floori((cell_size - row.body_box.x) / 2.0), cell_canvas_base_row - row.body_box.y), row.body_box)


## Why a body picture does not fit a kind's row, one sentence each; empty when it fits. A tight
## picture (not cell-sized) must be no larger than the box: the whole png counts, padding
## included. The cell-sized canvas of the art spec may be as big as the cell, but the pixels it
## draws (`opaque_rect`, in the picture's own pixels) must lie inside the box on that canvas. A
## kind with no row is reported elsewhere (ContentDb), so this answers empty for it.
func picture_problems(piece_type: StringName, picture_size: Vector2i, opaque_rect: Rect2i) -> PackedStringArray:
	var problems := PackedStringArray()
	var row := row_for(piece_type)
	if row == null:
		return problems
	var box := row.body_box
	if is_cell_canvas(picture_size):
		var allowed := box_on_cell_canvas(row)
		if opaque_rect.size.x > 0 and opaque_rect.size.y > 0 and not allowed.encloses(opaque_rect):
			problems.append("its body picture is the %d x %d canvas of the art spec but its drawn pixels (x %d to %d, y %d to %d) leave the %d x %d box of a %s, which on that canvas is x %d to %d, y %d to %d (the base rim on row %d, the rows below it empty; content/feel/piece_sizes.tres)." % [picture_size.x, picture_size.y, opaque_rect.position.x, opaque_rect.end.x, opaque_rect.position.y, opaque_rect.end.y, box.x, box.y, piece_type, allowed.position.x, allowed.end.x, allowed.position.y, allowed.end.y, cell_canvas_base_row])
	elif picture_size.x > box.x or picture_size.y > box.y:
		problems.append("its body picture is %d x %d px but a %s may be drawn at most %d x %d px, or on the %d x %d canvas of the art spec with its drawn pixels inside that box (content/feel/piece_sizes.tres)." % [picture_size.x, picture_size.y, piece_type, box.x, box.y, cell_size, cell_size])
	return problems


## The same, for a loaded picture: its size, and the box around its drawn (not fully transparent)
## pixels. Reads the picture's pixels, so call it from tests and tools, never per frame.
func picture_problems_of_texture(piece_type: StringName, texture: Texture2D) -> PackedStringArray:
	return picture_problems(piece_type, Vector2i(texture.get_size()), opaque_rect_of(texture))


## The rectangle around the drawn pixels of a picture (any alpha above zero), in the picture's own
## pixels; an empty rectangle for a fully transparent picture. A picture whose pixels cannot be
## read counts as drawn edge to edge, the cautious answer.
static func opaque_rect_of(texture: Texture2D) -> Rect2i:
	var used := Rect2i(Vector2i.ZERO, Vector2i(texture.get_size()))
	var image := texture.get_image()
	if image != null:
		if image.is_compressed():
			image.decompress()
		used = image.get_used_rect()
	return used


## The vertical extent of a row's picture relative to the cell's centre: [top, bottom], pixels,
## negative upward. The picture is `body_box.y` tall and its bottom edge is at `base_offset_y`.
static func vertical_extent_of(row: PieceSize) -> Vector2i:
	return Vector2i(row.base_offset_y - row.body_box.y, row.base_offset_y)


func validate() -> PackedStringArray:
	var warnings := PackedStringArray()
	if cell_size < 1:
		warnings.append("Piece size table: cell_size must be at least 1.")
	if minimum_margin < 0:
		warnings.append("Piece size table: minimum_margin cannot be negative.")
	if cell_canvas_base_row < 1 or cell_canvas_base_row > cell_size:
		warnings.append("Piece size table: cell_canvas_base_row must be between 1 and the cell size (it is %d)." % cell_canvas_base_row)
	if rows.is_empty():
		warnings.append("Piece size table: it has no rows.")
	var seen: Dictionary[StringName, bool] = {}
	for row in rows:
		if row == null:
			warnings.append("Piece size table: a row is empty.")
			continue
		warnings.append_array(row.validate())
		if seen.has(row.piece_type):
			warnings.append("Piece size table: '%s' is listed twice." % row.piece_type)
		seen[row.piece_type] = true
		warnings.append_array(_fit_warnings(row))
	warnings.append_array(_ladder_warnings())
	return warnings


## Does the row's box, standing on its base line, stay `minimum_margin` away from every edge of
## its footprint? The footprint's centre is the origin, so it spans +-(footprint * cell / 2).
func _fit_warnings(row: PieceSize) -> PackedStringArray:
	var warnings := PackedStringArray()
	if row.body_box.x < 1 or row.body_box.y < 1 or row.footprint_cells.x < 1 or row.footprint_cells.y < 1:
		return warnings
	var half_width := row.footprint_cells.x * cell_size / 2.0
	var half_height := row.footprint_cells.y * cell_size / 2.0
	if row.body_box.x / 2.0 > half_width - minimum_margin:
		warnings.append("Piece size '%s': its box is %d wide, which leaves less than %d px to the sides of a %d x %d cell footprint." % [row.piece_type, row.body_box.x, minimum_margin, row.footprint_cells.x, row.footprint_cells.y])
	var extent := vertical_extent_of(row)
	if extent.y > half_height - minimum_margin:
		warnings.append("Piece size '%s': its base line (%d px below the centre) leaves less than %d px to the bottom of its footprint." % [row.piece_type, row.base_offset_y, minimum_margin])
	if extent.x < -(half_height - minimum_margin):
		warnings.append("Piece size '%s': a %d px tall box on a base line %d px below the centre reaches %d px above it, which leaves less than %d px to the top of its footprint." % [row.piece_type, row.body_box.y, row.base_offset_y, -extent.x, minimum_margin])
	return warnings


## Chess heights: every kind on a rung of HEIGHT_LADDER is strictly taller than every listed kind
## on the rungs below it. Kinds the table does not list are skipped.
func _ladder_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	for upper_rung_index in range(1, HEIGHT_LADDER.size()):
		for upper_kind: StringName in HEIGHT_LADDER[upper_rung_index]:
			var upper_row := row_for(upper_kind)
			if upper_row == null:
				continue
			for lower_rung_index in range(upper_rung_index):
				for lower_kind: StringName in HEIGHT_LADDER[lower_rung_index]:
					var lower_row := row_for(lower_kind)
					if lower_row != null and upper_row.body_box.y <= lower_row.body_box.y:
						warnings.append("Piece size table: a %s (%d px tall) must be taller than a %s (%d px tall), as in a real chess set." % [upper_kind, upper_row.body_box.y, lower_kind, lower_row.body_box.y])
	return warnings
