class_name PieceSize
extends Resource

## How big one kind of chess piece is drawn inside its cell: one row of the PieceSizeTable
## (content/feel/piece_sizes.tres). The owner's decision of 2026-10-12 is that a piece is smaller
## than its cell, so this row is the contract for the picture: draw body.png no larger than
## `body_box`, and the game stands its bottom edge `base_offset_y` pixels below the cell's centre.

## The kind of piece: pawn, knight, bishop, rook, queen, king, or the name of a boss row. A
## VisualDefinition names it (its piece_type) to say which row it is drawn to.
@export var piece_type: StringName = &""
## The largest picture the owner may draw for this kind, in pixels: width, then height. The
## picture is the whole png (its transparent padding counts), drawn at scale 1.
@export var body_box := Vector2i(18, 22)
## Pixels from the cell's centre DOWN to the bottom edge of the picture. The picture is centred
## on the cell's centre line horizontally.
@export var base_offset_y := 14
## How many cells the piece's footprint covers (width, height). 1 x 1 for every ordinary piece; a
## future boss that stands on several cells names its footprint here and its box may grow with it.
@export var footprint_cells := Vector2i.ONE


func validate() -> PackedStringArray:
	var warnings := PackedStringArray()
	if piece_type == &"":
		warnings.append("A piece size row needs a piece_type.")
	if body_box.x < 1 or body_box.y < 1:
		warnings.append("Piece size '%s': body_box must be at least 1 x 1 (it is %s)." % [piece_type, body_box])
	if footprint_cells.x < 1 or footprint_cells.y < 1:
		warnings.append("Piece size '%s': footprint_cells must be at least 1 x 1 (it is %s)." % [piece_type, footprint_cells])
	return warnings
