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


## Where the top-left corner of a body picture goes, in pixels from the cell's centre: the picture
## is centred sideways (rounded down for an odd width, so it stays on whole pixels) and its bottom
## edge stands on the kind's base line, then `anchor_offset` (a VisualDefinition's own nudge) is
## added. A kind with no row stands its picture's bottom edge on the cell's centre, the way the
## old art did. The one formula the view, the preview tool and the tests all use.
func body_top_left(piece_type: StringName, picture_size: Vector2, anchor_offset := Vector2.ZERO) -> Vector2:
	var row := row_for(piece_type)
	var base_line := float(row.base_offset_y) if row != null else 0.0
	return Vector2(-floorf(picture_size.x / 2.0), base_line - picture_size.y) + anchor_offset


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
