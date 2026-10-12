extends SceneTree
## Draws the demo world at the scale of the thing that walks it, and stamps it
## with the tiles from tools/generate_kingdom_tiles.gd.
##
## THE SCALE IS THE PAWN'S. One cell is one chess square: an inch and a half.
## Every interior art pack draws a bedroom for someone six feet tall, so their
## bed comes out seven tiles wide. Ours is walked by a piece an inch high, so the
## same bed is fifty cells wide and has to be drawn like a building. The
## chessboard is eight cells across — twelve real inches, a real board — and the
## room around it is a hundred and twenty-eight. The kingdom is a speck on the
## floor of a child's bedroom.
##
## THE CAMERA IS SIXTY-FIVE DEGREES ABOVE THE FLOOR, AND EVERYTHING OBEYS IT.
## This was the thing most wrong with the first draft: each object was drawn at
## whatever angle looked fine on its own, so the alphabet blocks were at sixty
## three degrees, the wardrobe at seventy, the desk at seventy-nine and the floor
## at ninety. A picture with five camera angles in it reads as wrong without ever
## telling you why.
##
## Sixty-five is measured off the reference packs: their vertical faces come out
## at four tenths of the object's real height once both are in the same units,
## which is cos 63° to cos 67°. Below sixty and a five-foot wardrobe hides half
## the room; above seventy-five and every face is a stripe, which is the flatness
## this draft had.
##
## Two numbers follow from the angle and everything in this file is one of them:
##     one inch across the floor = BLOCKS_PER_PLAN_INCH
##     one inch of height        = BLOCKS_PER_HEIGHT_INCH   (plan x cos 65)
##
## ONE CHEAT, DECLARED: the floor is drawn without foreshortening, so cells stay
## square and a chessboard stays a chessboard and a move range is not a lozenge.
## Every top-down game makes this cheat. What is not allowed is making it
## differently for each object, which is what the first draft did.
##
## THE OUTLINE IS PER OBJECT, NOT PER TILE, and the light is fixed: one window in
## the north wall, light from the upper left, so every shadow falls south-east.
##
## Run (tiles first — this script stamps their PNGs and reads their manifest):
##     HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot \
##         --headless --path . -s tools/generate_kingdom_tiles.gd
##     HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot \
##         --headless --path . -s tools/generate_demo_map.gd

const TILE_DIR := "res://assets/_generated/tiles"

## WHERE THE HAND-DRAWN ART GOES. Two folders, and the difference matters:
##   PIECE_ART_DIR       — yours. Drop "bed.png" and "bed_height.png" in here and
##                         the next run uses them instead of the procedural
##                         version. NOTHING in this script ever writes here.
##   PIECE_TEMPLATE_DIR  — mine. Every run re-exports each piece as a PNG pair
##                         you can open in Aseprite and paint over: the art at
##                         one pixel per block, and the height map beside it,
##                         already correct. Overwritten every run, so never edit
##                         in here — copy across to PIECE_ART_DIR first.
##
## A piece is replaced on its own. Draw the bed, leave the other eighteen
## procedural, and the room still builds and still checks its routes.
const PIECE_ART_DIR := "res://assets/map_pieces"

## The room's shell is drawn on the same terms as a piece: "the_room.png" and
## "the_room_height.png", the whole map at one pixel per block, always at the
## top-left corner. Its template comes out identical to what the generator makes
## now, so you can repaint the wallpaper or redraw the window and leave the rest
## of the floor exactly as it is.
const ROOM_ART_NAME := "the_room"
const PIECE_TEMPLATE_DIR := "res://assets/_generated/piece_templates"

## THE HEIGHT MAP'S KEY. One flat colour per height, painted at one pixel per
## block on the "<name>_height.png" beside your art. Anything left transparent is
## not part of the piece and the floor shows through. Magenta means solid: a leg,
## a door, the front of a wardrobe — seen, never entered.
##
## These are also written out as a swatch strip and a palette file next to the
## templates, so you can eyedropper them instead of typing hex.
const SOLID_COLOUR := "ff00ff"
const HEIGHT_IN_INCHES_BY_COLOUR := {
	"1a3a1a": 0, "2e7d32": 6, "66bb46": 12, "b7e04a": 18, "ffee58": 24,
	"ffb300": 30, "fb8c00": 36, "e65100": 42, "d84315": 48, "b71c1c": 54,
	"6a1b9a": 60,
}
const OUTPUT_DIR := "res://assets/_generated/maps"
const MAP_WIDTH_IN_CELLS := 128
const MAP_HEIGHT_IN_CELLS := 96

## One art block is two world pixels and there are sixteen to a cell. One block
## here is exactly one pixel in the reference art packs, which is what puts this
## art in the same weight class as theirs instead of sixteen times coarser.
const BLOCKS_PER_CELL := 16
const PIXELS_PER_BLOCK := 2
const CELL_SIZE_IN_PIXELS := BLOCKS_PER_CELL * PIXELS_PER_BLOCK
const MAP_WIDTH_IN_BLOCKS := MAP_WIDTH_IN_CELLS * BLOCKS_PER_CELL
const MAP_HEIGHT_IN_BLOCKS := MAP_HEIGHT_IN_CELLS * BLOCKS_PER_CELL

## One cell is one square of the chessboard the demo ends on: an inch and a half.
const INCHES_PER_CELL := 1.5

## THE CAMERA. Sixty-five degrees above the floor; the two scales every size in
## this file is quoted in follow from it. Ten and two thirds blocks to a plan
## inch, four and a half to an inch of height — so a thirty-inch desk shows a
## hundred and thirty-five blocks of apron and a three-inch toy block shows
## fourteen, and both are the same room seen from the same place.
const CAMERA_PITCH_ABOVE_FLOOR_IN_DEGREES := 65.0
const BLOCKS_PER_PLAN_INCH := 10.667
const BLOCKS_PER_HEIGHT_INCH := 4.5

## Climbing up and dropping down are not the same move, and the difference is
## what makes a level loop. A pawn hauls itself up six inches — four times its
## own height, already a real climb — but it will step off anything up to two
## feet. So a route can run one way only: you climb the bookcase the long way
## round and drop onto the bed, and you can never go back up that way. Every
## shortcut in this level is one of those.
const MAX_STEP_IN_INCHES := 6
const MAX_DROP_IN_INCHES := 24

## Every height in the room is a multiple of this, so the manifest can write one
## digit per cell instead of a number.
const HEIGHT_STEP_IN_INCHES := 6

## The floor's boards: six inches wide, seven feet long, butts staggered course
## to course so no joint runs straight across.
const ROWS_PER_FLOORBOARD := 4
const CELLS_PER_BOARD_LENGTH := 56
const BOARD_STAGGER_PER_ROW := 21

## The width in world pixels of the rim drawn around a body. One art block.
const RIM_WIDTH_IN_PIXELS := 2

## How far south-east a thing laid on a surface throws its contact shadow.
const CONTACT_SHADOW_IN_BLOCKS := 3

## What counts as ground a shadow may fall on.
const GROUND_BODIES := {"floor": true, "rug": true}

## How far apart the pieces stand on the specimen sheet, in cells.
const SHEET_GUTTER_IN_CELLS := 6

## One character per material for the manifest's grid.
const CODE_BY_MATERIAL := {
	"void": ".", "room_edge": "#", "wall_rail": "^", "wallpaper": "p",
	"wallpaper_stripe": "|", "wallpaper_side": "s", "skirting": "=", "wall_shadow": "v",
	"window_frame": "N", "window_glass": "O", "door_frame": "J", "door_leaf": "D",
	"floor_plank": "-", "daylight": "*", "deep_pile": "P", "deep_pile_worn": "w",
	"rug_motif": "r", "furniture_shade": "c", "chalk_path": "h",
	"furniture_leg": "F", "crossbar": "K", "chair_seat": "s", "table_top": "t",
	"wood_face": "f", "shelf_face": "H", "shelf_top": "U", "shelf_ledge": "l", "mattress": "m",
	"mattress_seam": "n", "blanket": "B", "blanket_fold": "b", "pillow": "i",
	"paint_top": "y", "paint_face": "Y", "metal": "M", "page": "a",
	"gate_face": "g", "crayon_face": "j", "box_ruins": "X", "crayon_ramp": "C",
	"ruler_bridge": "R", "sag": "S", "tablecloth": "T", "lamplight": "L",
	"board_light": "1", "board_dark": "2", "gate": "G",
}

## The room's shell, in blocks. The wall is drawn as a face at the camera's
## angle: ninety-six inches of wall is 96 x 4.5 = 432 blocks, twenty-seven cells,
## which leaves sixty-six cells of floor — ninety-nine inches deep. Heights on
## the wall are measured from the floor and converted the same way, so the
## window's sill really is thirty inches up and the door really is eighty tall.
const THE_ROOM := {
	"name": "the_room",
	"note": "A child's bedroom with three of its four walls drawn: the far one face on, and the left and right ones running away from you down the sides of the frame. Only the near wall is missing, because that is where the camera is",
	"up_in_inches": 0,
	"emits": [
		{"rect": Rect2i(0, 0, 2048, 1536), "material": "room_edge",
			"note": "the dark the room is cut out of"},
		{"rect": Rect2i(128, 432, 1792, 1056), "material": "floorboards",
			"note": "The Boards — a hundred and sixty-eight inches across, six-inch boards, butts staggered"},
		{"rect": Rect2i(128, 0, 1792, 18), "material": "wall_rail",
			"note": "the picture rail along the far wall"},
		{"rect": Rect2i(128, 18, 1792, 396), "material": "paper",
			"note": "THE FAR WALL — eighty-eight inches of papered plaster, seen face on"},
		{"rect": Rect2i(128, 414, 1792, 18), "material": "skirting",
			"note": "and its skirting"},
		{"rect": Rect2i(128, 432, 1792, 32), "material": "wall_shadow",
			"note": "the shadow it drops on the boards"},
		{"rect": Rect2i(0, 0, 128, 1488), "material": "wallpaper_side",
			"note": "THE LEFT WALL, running away from you down the side of the frame — darker than the far wall, because it faces the wrong way for the window"},
		{"rect": Rect2i(0, 0, 16, 1488), "material": "wall_rail",
			"note": "the corner line where it turns out of shot"},
		{"rect": Rect2i(100, 432, 28, 1056), "material": "skirting",
			"note": "and its skirting, meeting the boards"},
		{"rect": Rect2i(1920, 0, 128, 1488), "material": "wallpaper_side",
			"note": "THE RIGHT WALL, the same on the other side"},
		{"rect": Rect2i(2032, 0, 16, 1488), "material": "wall_rail",
			"note": "its corner line"},
		{"rect": Rect2i(1920, 432, 28, 1056), "material": "skirting",
			"note": "and its skirting"},
		{"rect": Rect2i(128, 432, 32, 1056), "material": "wall_shadow",
			"note": "the shadow the left wall drops on the boards"},
		{"rect": Rect2i(1888, 432, 32, 1056), "material": "wall_shadow",
			"note": "and the right wall's"},
		{"rect": Rect2i(16, 940, 96, 440), "material": "door_frame",
			"note": "THE DOOR, moved onto the left wall — which is where a bedroom door usually is, and it hands the whole far wall back to the furniture"},
		{"rect": Rect2i(28, 960, 72, 400), "material": "door_leaf",
			"note": "its leaf, shut"},
		{"rect": Rect2i(40, 1000, 48, 150), "material": "door_frame", "note": "its upper panel"},
		{"rect": Rect2i(40, 1180, 48, 150), "material": "door_frame", "note": "and its lower one"},
		{"rect": Rect2i(84, 1140, 20, 40), "material": "metal", "note": "the handle"},
		{"rect": Rect2i(528, 117, 544, 198), "material": "window_frame",
			"note": "The Window's frame"},
		{"rect": Rect2i(544, 135, 512, 162), "material": "window_glass",
			"note": "forty-eight inches of glass, sill at thirty, head at sixty-six"},
		{"rect": Rect2i(704, 135, 20, 162), "material": "window_frame", "note": "a glazing bar"},
		{"rect": Rect2i(876, 135, 20, 162), "material": "window_frame",
			"note": "and the other — three lights, which is what makes a rectangle a window"},
		{"rect": Rect2i(528, 297, 544, 18), "material": "skirting", "note": "and the sill it sits on"},
		{"rect": Rect2i(544, 464, 512, 700), "material": "sunlight", "skew_east_per_row": 1,
			"note": "The Sun — the window's own width, raked one block east per block south"},
	],
}

## Every piece of furniture, drawn once in its own coordinates, in blocks. Each
## entry:
##   size  — footprint in blocks.
##   real  — what it measures in a shop AND how that becomes blocks, so the
##           camera angle can be checked against any piece without running it.
##   up_in_inches — how high its main surface stands; an emit may override it.
##   emits — rectangles relative to the piece's north-west corner, in paint
##           order. "repeat" makes one entry into a row of identical details.
const PIECES := {
	"bed": {
		"size": Vector2i(800, 656),
		"unit": "blocks",
		"real": "75 x 39 in plan (800 x 416 blocks); headboard 14 in above the mattress (63 blocks)",
		"up_in_inches": 24,
		"note": "A child's single bed, head to the wall, with a blanket trailing off one corner that is the only way up",
		"emits": [
			{"rect": Rect2i(24, 24, 800, 455), "material": "furniture_shade", "up_in_inches": 0, "only_on_ground": true,
				"note": "the shadow of the frame"},
			{"rect": Rect2i(0, 0, 800, 63), "material": "wood_face", "up_in_inches": 0,
				"note": "The Headboard — fourteen inches above the mattress, so sixty-three blocks of face"},
			{"rect": Rect2i(0, 0, 800, 10), "material": "shelf_top", "up_in_inches": 0,
				"note": "the light along its top rail"},
			{"rect": Rect2i(56, 14, 26, 45), "material": "shelf_top", "up_in_inches": 0,
				"repeat": {"count": 9, "step": Vector2i(80, 0)},
				"note": "nine turned spindles — a colonnade at this scale"},
			{"rect": Rect2i(0, 63, 40, 416), "material": "furniture_leg", "up_in_inches": 0,
				"note": "the left side rail"},
			{"rect": Rect2i(760, 63, 40, 416), "material": "furniture_leg", "up_in_inches": 0,
				"note": "and the right — a pawn crosses neither"},
			{"rect": Rect2i(56, 63, 688, 8), "material": "mattress_seam", "note": "the mattress piping, head corner"},
			{"rect": Rect2i(48, 71, 704, 8), "material": "mattress_seam", "note": "wider"},
			{"rect": Rect2i(40, 79, 720, 384), "material": "mattress_seam", "note": "down both sides"},
			{"rect": Rect2i(48, 463, 704, 8), "material": "mattress_seam", "note": "in again"},
			{"rect": Rect2i(56, 471, 688, 8), "material": "mattress_seam", "note": "and its foot corner"},
			{"rect": Rect2i(56, 71, 688, 400), "material": "mattress",
				"note": "The Mattress — twenty-four inches up, the widest high ground in the room"},
			{"rect": Rect2i(88, 116, 624, 4), "material": "mattress_seam",
				"repeat": {"count": 6, "step": Vector2i(0, 58)},
				"note": "quilting, six seams across it"},
			{"rect": Rect2i(136, 79, 4, 384), "material": "mattress_seam",
				"repeat": {"count": 8, "step": Vector2i(72, 0)},
				"note": "and eight the other way, which makes it a quilt and not a slab"},
			{"rect": Rect2i(80, 79, 256, 8), "material": "pillow", "note": "The Pillow, head corner"},
			{"rect": Rect2i(72, 87, 272, 8), "material": "pillow", "note": "widening"},
			{"rect": Rect2i(64, 95, 288, 112), "material": "pillow", "note": "the body of it — a white hill"},
			{"rect": Rect2i(72, 207, 272, 8), "material": "pillow", "note": "narrowing"},
			{"rect": Rect2i(80, 215, 256, 8), "material": "pillow", "note": "and its foot corner"},
			{"rect": Rect2i(96, 150, 224, 6), "material": "mattress_seam",
				"note": "the crease where a head lay in it"},
			{"rect": Rect2i(56, 311, 688, 160), "material": "blanket",
				"note": "The Blanket, pulled up over the foot of the bed"},
			{"rect": Rect2i(56, 311, 688, 28), "material": "blanket_fold",
				"note": "its turned-over top edge"},
			{"rect": Rect2i(104, 339, 6, 132), "material": "blanket_fold",
				"repeat": {"count": 7, "step": Vector2i(88, 0)},
				"note": "seven creases running down it"},
			{"rect": Rect2i(48, 479, 192, 44), "material": "blanket", "up_in_inches": 18,
				"note": "and spilling off the foot-right corner: the first rung down"},
			{"rect": Rect2i(48, 479, 192, 8), "material": "blanket_fold", "up_in_inches": 18,
				"note": "the fold at its lip, which is what makes a rung read as a rung"},
			{"rect": Rect2i(48, 523, 192, 44), "material": "blanket", "up_in_inches": 12, "note": "the second"},
			{"rect": Rect2i(48, 523, 192, 8), "material": "blanket_fold", "up_in_inches": 12, "note": "and its fold"},
			{"rect": Rect2i(48, 567, 192, 44), "material": "blanket", "up_in_inches": 6, "note": "the third"},
			{"rect": Rect2i(48, 567, 192, 8), "material": "blanket_fold", "up_in_inches": 6, "note": "and its fold"},
			{"rect": Rect2i(48, 611, 192, 45), "material": "blanket", "up_in_inches": 0,
				"note": "and the hem, on the boards. THE ONLY WAY UP ONTO THE BED"},
			{"rect": Rect2i(48, 611, 192, 8), "material": "blanket_fold", "up_in_inches": 0,
				"note": "with the last fold on it"},
		],
	},
	"desk": {
		"size": Vector2i(512, 392),
		"unit": "blocks",
		"real": "48 x 24 in plan (512 x 256 blocks); top at 30 in, so 135 blocks of apron",
		"up_in_inches": 30,
		"note": "The desk under the window — the highest ground in the room, and its drawer is left open",
		"emits": [
			{"rect": Rect2i(24, 24, 512, 368), "material": "furniture_shade", "up_in_inches": 0, "only_on_ground": true,
				"note": "its shadow"},
			{"rect": Rect2i(16, 0, 480, 8), "material": "table_top", "note": "the desktop's back edge, corners in"},
			{"rect": Rect2i(8, 8, 496, 8), "material": "table_top", "note": "wider"},
			{"rect": Rect2i(0, 16, 512, 224), "material": "table_top",
				"note": "The Desktop — thirty inches up; from here you see the whole room"},
			{"rect": Rect2i(8, 240, 496, 8), "material": "table_top", "note": "in again"},
			{"rect": Rect2i(16, 248, 480, 8), "material": "table_top", "note": "and its rounded front"},
			{"rect": Rect2i(0, 16, 512, 8), "material": "crossbar", "note": "the dark band along the back"},
			{"rect": Rect2i(32, 48, 160, 112), "material": "page", "note": "homework, abandoned"},
			{"rect": Rect2i(48, 72, 128, 6), "material": "crossbar",
				"repeat": {"count": 3, "step": Vector2i(0, 24)},
				"note": "three lines of writing on it, each a wall a pawn's own height"},
			{"rect": Rect2i(224, 32, 112, 80), "material": "box_ruins", "note": "a book, face down"},
			{"rect": Rect2i(224, 32, 16, 80), "material": "crossbar", "note": "its spine"},
			{"rect": Rect2i(328, 36, 8, 72), "material": "page", "note": "and the block of its pages"},
			{"rect": Rect2i(384, 32, 64, 16), "material": "lamplight", "note": "the lamp's pool, the top of it"},
			{"rect": Rect2i(368, 48, 96, 16), "material": "lamplight", "note": "widening"},
			{"rect": Rect2i(352, 64, 128, 96), "material": "lamplight", "note": "its middle — round, because a lamp throws a circle"},
			{"rect": Rect2i(368, 160, 96, 16), "material": "lamplight", "note": "narrowing"},
			{"rect": Rect2i(384, 176, 64, 16), "material": "lamplight", "note": "and the bottom"},
			{"rect": Rect2i(392, 88, 48, 48), "material": "metal", "note": "the shade, seen from directly above"},
			{"rect": Rect2i(404, 100, 24, 24), "material": "pillow", "note": "and the bulb inside it"},
			{"rect": Rect2i(208, 192, 120, 10), "material": "crayon_ramp", "note": "a pencil"},
			{"rect": Rect2i(328, 194, 12, 6), "material": "wood_face", "note": "sharpened"},
			{"rect": Rect2i(240, 216, 104, 10), "material": "gate", "note": "and a blue one"},
			{"rect": Rect2i(344, 218, 12, 6), "material": "wood_face", "note": "also sharpened"},
			{"rect": Rect2i(0, 256, 512, 135), "material": "wood_face", "up_in_inches": 0,
				"note": "The Apron — a hundred and thirty-five blocks, which is thirty inches at this camera"},
			{"rect": Rect2i(0, 256, 512, 8), "material": "shelf_top", "up_in_inches": 0,
				"note": "the bead moulded along its top"},
			{"rect": Rect2i(0, 256, 48, 135), "material": "furniture_leg", "up_in_inches": 0, "note": "front-left leg"},
			{"rect": Rect2i(464, 256, 48, 135), "material": "furniture_leg", "up_in_inches": 0, "note": "front-right leg"},
			{"rect": Rect2i(144, 256, 224, 135), "material": "crossbar", "up_in_inches": 24,
				"note": "THE OPEN DRAWER, pulled right out. Its front covers the whole depth of the apron, so its top edge meets the desktop and its bottom edge meets the stool — that is the only reason the ladder joins up"},
			{"rect": Rect2i(152, 264, 208, 8), "material": "wood_face", "up_in_inches": 24,
				"note": "the line where its front is rebated"},
			{"rect": Rect2i(224, 306, 64, 24), "material": "metal", "up_in_inches": 24, "note": "its brass handle"},
			{"rect": Rect2i(212, 312, 10, 12), "material": "metal", "up_in_inches": 24, "note": "a screw"},
			{"rect": Rect2i(290, 312, 10, 12), "material": "metal", "up_in_inches": 24, "note": "and the other"},
		],
	},
	"chair": {
		"size": Vector2i(192, 273),
		"unit": "blocks",
		"real": "18 x 18 in plan (192 x 192); seat at 18 in, so 81 blocks of front",
		"up_in_inches": 18,
		"note": "The desk stool. It has no back on purpose: at sixty-five degrees a backrest is drawn between the seat and the desk, and a pawn cannot climb through one. Backless, and the whole ladder works",
		"emits": [
			{"rect": Rect2i(24, 24, 192, 249), "material": "furniture_shade", "up_in_inches": 0, "only_on_ground": true,
				"note": "its shadow"},
			{"rect": Rect2i(16, 0, 160, 8), "material": "chair_seat", "note": "the seat's back edge, corners in"},
			{"rect": Rect2i(8, 8, 176, 8), "material": "chair_seat", "note": "wider"},
			{"rect": Rect2i(0, 16, 192, 160), "material": "chair_seat",
				"note": "The Seat — eighteen inches up, and its north edge touches the open drawer"},
			{"rect": Rect2i(8, 176, 176, 8), "material": "chair_seat", "note": "in again"},
			{"rect": Rect2i(16, 184, 160, 8), "material": "chair_seat", "note": "and its rounded front"},
			{"rect": Rect2i(24, 40, 144, 6), "material": "crossbar",
				"repeat": {"count": 3, "step": Vector2i(0, 40)},
				"note": "three slats across it"},
			{"rect": Rect2i(0, 192, 192, 81), "material": "crossbar", "up_in_inches": 0,
				"note": "the stool's front — eighty-one blocks, eighteen inches at this camera"},
			{"rect": Rect2i(0, 192, 192, 27), "material": "crossbar", "up_in_inches": 12,
				"note": "and in it the side rail at twelve inches — the second rung"},
			{"rect": Rect2i(0, 219, 192, 27), "material": "crossbar", "up_in_inches": 6,
				"note": "and the stretcher at six — the first, where a pawn starts climbing"},
			{"rect": Rect2i(0, 192, 20, 81), "material": "furniture_leg", "up_in_inches": 0,
				"note": "its left legs, seen edge on"},
			{"rect": Rect2i(172, 192, 20, 81), "material": "furniture_leg", "up_in_inches": 0,
				"note": "and its right — the middle stays open, which is the way up"},
		],
	},
	"toy_chest": {
		"size": Vector2i(320, 273),
		"unit": "blocks",
		"real": "30 x 18 in plan (320 x 192); lid at 18 in, so 81 blocks of front",
		"up_in_inches": 18,
		"note": "The toy chest at the foot of the bed — the one thing here whose colour the child chose",
		"emits": [
			{"rect": Rect2i(24, 24, 320, 249), "material": "furniture_shade", "up_in_inches": 0, "only_on_ground": true,
				"note": "its shadow"},
			{"rect": Rect2i(16, 0, 288, 8), "material": "paint_top", "note": "the lid's back edge, corners in"},
			{"rect": Rect2i(8, 8, 304, 8), "material": "paint_top", "note": "wider"},
			{"rect": Rect2i(0, 16, 320, 160), "material": "paint_top",
				"note": "The Lid — twelve inches up, the lowest thing a pawn can get onto"},
			{"rect": Rect2i(8, 176, 304, 8), "material": "paint_top", "note": "in again"},
			{"rect": Rect2i(16, 184, 288, 8), "material": "paint_top", "note": "and its rounded front"},
			{"rect": Rect2i(48, 0, 28, 192), "material": "metal",
				"repeat": {"count": 3, "step": Vector2i(96, 0)},
				"note": "three brass straps over it"},
			{"rect": Rect2i(0, 16, 320, 8), "material": "metal", "note": "the banding round its top"},
			{"rect": Rect2i(0, 192, 320, 81), "material": "paint_face", "up_in_inches": 0,
				"note": "its front — eighty-one blocks, eighteen inches"},
			{"rect": Rect2i(48, 192, 28, 81), "material": "metal", "up_in_inches": 0,
				"repeat": {"count": 3, "step": Vector2i(96, 0)},
				"note": "the straps carrying on down it"},
			{"rect": Rect2i(144, 216, 32, 34), "material": "metal", "up_in_inches": 0, "note": "the latch, shut"},
			{"rect": Rect2i(152, 230, 16, 10), "material": "paint_face", "up_in_inches": 0, "note": "and its keyhole"},
			{"rect": Rect2i(0, 192, 24, 81), "material": "metal", "up_in_inches": 0, "note": "a corner bracket"},
			{"rect": Rect2i(296, 192, 24, 81), "material": "metal", "up_in_inches": 0, "note": "and the other"},
		],
	},
	"wardrobe": {
		"size": Vector2i(384, 526),
		"unit": "blocks",
		"real": "36 x 24 in plan (384 x 256); 60 in tall, so 270 blocks of door",
		"up_in_inches": 60,
		"note": "The wardrobe — five feet, forty times a pawn. Not a climb; a cliff, and now it is drawn as one",
		"emits": [
			{"rect": Rect2i(24, 24, 384, 502), "material": "furniture_shade", "up_in_inches": 0, "only_on_ground": true,
				"note": "its shadow — the longest in the room"},
			{"rect": Rect2i(0, 0, 384, 224), "material": "shelf_top", "note": "its top, five feet up and out of reach"},
			{"rect": Rect2i(0, 0, 384, 24), "material": "wood_face", "note": "the cornice round it"},
			{"rect": Rect2i(0, 18, 384, 6), "material": "shelf_top", "note": "and the bead under it"},
			{"rect": Rect2i(0, 224, 384, 32), "material": "wood_face", "note": "the front edge of the top, dropping away"},
			{"rect": Rect2i(0, 256, 384, 270), "material": "shelf_face", "up_in_inches": 0,
				"note": "its doors — two hundred and seventy blocks, which is sixty inches at this camera"},
			{"rect": Rect2i(24, 288, 144, 200), "material": "wood_face", "up_in_inches": 0, "note": "the left door's panel"},
			{"rect": Rect2i(40, 304, 112, 168), "material": "shelf_face", "up_in_inches": 0, "note": "sunk into it"},
			{"rect": Rect2i(216, 288, 144, 200), "material": "wood_face", "up_in_inches": 0, "note": "the right door's"},
			{"rect": Rect2i(232, 304, 112, 168), "material": "shelf_face", "up_in_inches": 0, "note": "sunk the same"},
			{"rect": Rect2i(176, 256, 32, 270), "material": "wood_face", "up_in_inches": 0,
				"note": "the seam between them, which is the gap, and it is shut"},
			{"rect": Rect2i(158, 372, 18, 56), "material": "metal", "up_in_inches": 0, "note": "a handle"},
			{"rect": Rect2i(208, 372, 18, 56), "material": "metal", "up_in_inches": 0, "note": "and its pair"},
			{"rect": Rect2i(0, 508, 384, 18), "material": "wood_face", "up_in_inches": 0, "note": "the plinth it stands on"},
		],
	},
	"bookcase": {
		"size": Vector2i(384, 290),
		"unit": "blocks",
		"real": "36 x 12 in plan (384 x 128); 36 in tall, so 162 blocks of front in six shelves of six inches",
		"up_in_inches": 36,
		"note": "THE BOOKCASE IS THE STAIRCASE. Six shelves, six inches apart, is exactly a pawn's climb repeated — so an open bookcase is a tower, and its top is twelve inches above the bed's foot, which is a drop you can take and never climb back",
		"emits": [
			{"rect": Rect2i(24, 24, 384, 266), "material": "furniture_shade", "up_in_inches": 0, "only_on_ground": true,
				"note": "its shadow"},
			{"rect": Rect2i(0, 0, 384, 128), "material": "shelf_top", "note": "its top, thirty-six inches up"},
			{"rect": Rect2i(0, 0, 384, 14), "material": "wood_face", "note": "its top edge"},
			{"rect": Rect2i(0, 128, 384, 27), "material": "shelf_ledge", "up_in_inches": 30,
				"note": "the top shelf, thirty inches — the last step before the top"},
			{"rect": Rect2i(0, 155, 384, 27), "material": "shelf_ledge", "up_in_inches": 24, "note": "twenty-four"},
			{"rect": Rect2i(0, 182, 384, 27), "material": "shelf_ledge", "up_in_inches": 18, "note": "eighteen"},
			{"rect": Rect2i(0, 209, 384, 27), "material": "shelf_ledge", "up_in_inches": 12, "note": "twelve"},
			{"rect": Rect2i(0, 236, 384, 27), "material": "shelf_ledge", "up_in_inches": 6,
				"note": "six — and this one a pawn can reach from the boards"},
			{"rect": Rect2i(0, 263, 384, 27), "material": "shelf_ledge", "up_in_inches": 0,
				"note": "and the plinth it all stands on"},
			{"rect": Rect2i(0, 128, 384, 4), "material": "crossbar", "up_in_inches": 30,
				"note": "the front edge of each shelf — written out one by one, because a repeat would give all six the top shelf's height and quietly break the climb"},
			{"rect": Rect2i(0, 155, 384, 4), "material": "crossbar", "up_in_inches": 24, "note": "the second"},
			{"rect": Rect2i(0, 182, 384, 4), "material": "crossbar", "up_in_inches": 18, "note": "the third"},
			{"rect": Rect2i(0, 209, 384, 4), "material": "crossbar", "up_in_inches": 12, "note": "the fourth"},
			{"rect": Rect2i(0, 236, 384, 4), "material": "crossbar", "up_in_inches": 6, "note": "the fifth"},
			{"rect": Rect2i(0, 263, 384, 4), "material": "crossbar", "up_in_inches": 0, "note": "and the plinth's"},
			{"rect": Rect2i(16, 132, 30, 22), "material": "box_ruins", "up_in_inches": 30,
				"repeat": {"count": 5, "step": Vector2i(70, 0)},
				"note": "books on the top shelf, pushed back so the ledge stays walkable"},
			{"rect": Rect2i(48, 132, 14, 22), "material": "gate", "up_in_inches": 30,
				"repeat": {"count": 5, "step": Vector2i(70, 0)},
				"note": "the thin blue ones between them"},
			{"rect": Rect2i(16, 159, 26, 22), "material": "crayon_ramp", "up_in_inches": 24,
				"repeat": {"count": 5, "step": Vector2i(70, 0)},
				"note": "orange ones on the next shelf down"},
			{"rect": Rect2i(44, 159, 16, 22), "material": "paint_top", "up_in_inches": 24,
				"repeat": {"count": 5, "step": Vector2i(70, 0)},
				"note": "and teal"},
			{"rect": Rect2i(16, 186, 22, 22), "material": "paint_top", "up_in_inches": 18,
				"repeat": {"count": 4, "step": Vector2i(88, 0)},
				"note": "and fewer on the third — the shelves empty out as they come down, which is why the climb is possible"},
			{"rect": Rect2i(120, 213, 30, 22), "material": "box_ruins", "up_in_inches": 12,
				"note": "one book left on the fourth"},
			{"rect": Rect2i(250, 240, 26, 22), "material": "crayon_ramp", "up_in_inches": 6,
				"note": "and one on the bottom"},
		],
	},
	"play_table": {
		"size": Vector2i(384, 364),
		"unit": "blocks",
		"real": "36 x 24 in plan (384 x 256); top at 24 in, so 108 blocks of apron",
		"up_in_inches": 24,
		"note": "THE PLAY TABLE. A child set a game out on it and walked away. Everything climbs toward this",
		"emits": [
			{"rect": Rect2i(24, 24, 384, 340), "material": "furniture_shade", "up_in_inches": 0, "only_on_ground": true,
				"note": "its shadow"},
			{"rect": Rect2i(6, 0, 372, 4), "material": "table_top", "note": "the tabletop's back edge, corners already in"},
			{"rect": Rect2i(3, 4, 378, 3), "material": "table_top", "note": "a step wider"},
			{"rect": Rect2i(1, 7, 382, 2), "material": "table_top", "note": "and wider"},
			{"rect": Rect2i(0, 9, 384, 238), "material": "table_top", "note": "the top itself, twenty-four inches up"},
			{"rect": Rect2i(1, 247, 382, 2), "material": "table_top", "note": "coming back in"},
			{"rect": Rect2i(3, 249, 378, 3), "material": "table_top", "note": "further"},
			{"rect": Rect2i(6, 252, 372, 4), "material": "table_top", "note": "and its rounded front"},
			{"rect": Rect2i(112, 48, 144, 144), "material": "crossbar", "note": "the board's frame, mitred round it"},
			{"rect": Rect2i(117, 53, 134, 134), "material": "wood_face", "note": "the line inlaid inside the frame"},
			{"rect": Rect2i(120, 56, 128, 128), "material": "board",
				"note": "THE BOARD — eight cells, sixteen blocks a square, twelve real inches"},
			{"rect": Rect2i(168, 184, 32, 8), "material": "gate",
				"note": "The Gate, notched into the frame on the board's south edge"},
			{"rect": Rect2i(126, 155, 4, 4), "material": "pillow", "repeat": {"count": 4, "step": Vector2i(32, 0)},
				"note": "four white pawns on the near rank: heads"},
			{"rect": Rect2i(127, 159, 2, 1), "material": "pillow", "repeat": {"count": 4, "step": Vector2i(32, 0)}, "note": "necks"},
			{"rect": Rect2i(125, 160, 6, 2), "material": "pillow", "repeat": {"count": 4, "step": Vector2i(32, 0)}, "note": "collars"},
			{"rect": Rect2i(125, 162, 6, 3), "material": "pillow", "repeat": {"count": 4, "step": Vector2i(32, 0)}, "note": "bodies"},
			{"rect": Rect2i(124, 165, 8, 2), "material": "pillow", "repeat": {"count": 4, "step": Vector2i(32, 0)},
				"note": "and bases — twelve blocks tall, which is a pawn you can recognise"},
			{"rect": Rect2i(174, 123, 4, 4), "material": "pillow", "note": "one pushed two ranks up: its head"},
			{"rect": Rect2i(175, 127, 2, 1), "material": "pillow", "note": "its neck"},
			{"rect": Rect2i(173, 128, 6, 2), "material": "pillow", "note": "its collar"},
			{"rect": Rect2i(173, 130, 6, 3), "material": "pillow", "note": "its body"},
			{"rect": Rect2i(172, 133, 8, 2), "material": "pillow", "note": "its base"},
			{"rect": Rect2i(142, 75, 4, 4), "material": "wood_face", "repeat": {"count": 3, "step": Vector2i(32, 0)}, "note": "three dark pawns: heads"},
			{"rect": Rect2i(143, 79, 2, 1), "material": "wood_face", "repeat": {"count": 3, "step": Vector2i(32, 0)}, "note": "necks"},
			{"rect": Rect2i(141, 80, 6, 2), "material": "wood_face", "repeat": {"count": 3, "step": Vector2i(32, 0)}, "note": "collars"},
			{"rect": Rect2i(141, 82, 6, 3), "material": "wood_face", "repeat": {"count": 3, "step": Vector2i(32, 0)}, "note": "bodies"},
			{"rect": Rect2i(140, 85, 8, 2), "material": "wood_face", "repeat": {"count": 3, "step": Vector2i(32, 0)}, "note": "and bases"},
			{"rect": Rect2i(40, 214, 16, 5), "material": "pillow", "note": "a white pawn lying on its side"},
			{"rect": Rect2i(38, 216, 4, 3), "material": "pillow", "note": "its head, rolled clear"},
			{"rect": Rect2i(62, 222, 16, 5), "material": "pillow", "note": "and another"},
			{"rect": Rect2i(60, 224, 4, 3), "material": "pillow", "note": "its head"},
			{"rect": Rect2i(300, 214, 16, 5), "material": "wood_face", "note": "a dark one down as well"},
			{"rect": Rect2i(316, 216, 4, 3), "material": "wood_face", "note": "and its head"},
			{"rect": Rect2i(0, 256, 384, 108), "material": "wood_face", "up_in_inches": 0,
				"note": "the apron — a hundred and eight blocks, twenty-four inches"},
			{"rect": Rect2i(0, 256, 384, 6), "material": "shelf_top", "up_in_inches": 0, "note": "the bead along its top"},
			{"rect": Rect2i(16, 256, 44, 80), "material": "furniture_leg", "up_in_inches": 0, "note": "the front-left leg"},
			{"rect": Rect2i(20, 336, 36, 28), "material": "furniture_leg", "up_in_inches": 0, "note": "tapering as it goes down"},
			{"rect": Rect2i(324, 256, 44, 80), "material": "furniture_leg", "up_in_inches": 0, "note": "the front-right leg"},
			{"rect": Rect2i(328, 336, 36, 28), "material": "furniture_leg", "up_in_inches": 0, "note": "and its taper"},
		],
	},
	"book_stack": {
		"size": Vector2i(192, 269),
		"unit": "blocks",
		"real": "18 in of picture book (192 blocks) per cover; each book 6 in thick, so 27 blocks of page block",
		"up_in_inches": 0,
		"note": "Picture books stacked beside the play table. You get the top book's cover and, under it, the cream page block of every book below — that block IS the thickness",
		"emits": [
			{"rect": Rect2i(24, 24, 192, 245), "material": "furniture_shade", "up_in_inches": 0, "only_on_ground": true,
				"note": "its shadow"},
			{"rect": Rect2i(10, 0, 170, 128), "material": "gate", "up_in_inches": 24,
				"note": "the top book's cover, flush with the tabletop it leans on"},
			{"rect": Rect2i(38, 26, 114, 40), "material": "pillow", "up_in_inches": 24, "note": "a white label on it"},
			{"rect": Rect2i(48, 36, 94, 6), "material": "gate_face", "up_in_inches": 24, "note": "a line of title"},
			{"rect": Rect2i(48, 48, 70, 6), "material": "gate_face", "up_in_inches": 24, "note": "and a shorter second line"},
			{"rect": Rect2i(10, 128, 170, 27), "material": "page", "up_in_inches": 24,
				"note": "its page block — twenty-seven blocks, which is six inches at this camera"},
			{"rect": Rect2i(10, 128, 170, 4), "material": "gate_face", "up_in_inches": 24, "note": "and the board overhanging it"},
			{"rect": Rect2i(2, 155, 182, 11), "material": "paint_top", "up_in_inches": 18,
				"note": "the second book, pushed a little off square the way a pile is"},
			{"rect": Rect2i(2, 166, 182, 27), "material": "page", "up_in_inches": 18, "note": "and its page block"},
			{"rect": Rect2i(2, 166, 182, 4), "material": "paint_face", "up_in_inches": 18, "note": "and its overhang"},
			{"rect": Rect2i(6, 193, 178, 11), "material": "crayon_ramp", "up_in_inches": 12, "note": "the third"},
			{"rect": Rect2i(6, 204, 178, 27), "material": "page", "up_in_inches": 12, "note": "its page block"},
			{"rect": Rect2i(6, 204, 178, 4), "material": "crayon_face", "up_in_inches": 12, "note": "and its overhang"},
			{"rect": Rect2i(0, 231, 190, 11), "material": "box_ruins", "up_in_inches": 6, "note": "and the atlas at the bottom"},
			{"rect": Rect2i(0, 242, 190, 27), "material": "page", "up_in_inches": 6, "note": "its page block"},
			{"rect": Rect2i(0, 242, 190, 4), "material": "crossbar", "up_in_inches": 6, "note": "and its overhang"},
		],
	},
	"poster": {
		"size": Vector2i(256, 68),
		"unit": "blocks",
		"real": "24 in wide (256 blocks) x 15 in tall on the wall (68 blocks)",
		"up_in_inches": 0,
		"note": "A drawing taped over the bed — a house, a sun and a sky, done by whoever owns this room",
		"emits": [
			{"rect": Rect2i(0, 0, 256, 68), "material": "wood_face", "note": "the sheet's edge against the paper"},
			{"rect": Rect2i(4, 4, 248, 60), "material": "gate", "note": "sky, filled in right to the edge"},
			{"rect": Rect2i(4, 44, 248, 20), "material": "paint_top", "note": "and grass under it"},
			{"rect": Rect2i(188, 10, 36, 6), "material": "crayon_ramp", "note": "a sun, top of it"},
			{"rect": Rect2i(180, 16, 52, 16), "material": "crayon_ramp", "note": "its middle"},
			{"rect": Rect2i(188, 32, 36, 6), "material": "crayon_ramp", "note": "and its bottom"},
			{"rect": Rect2i(48, 28, 96, 24), "material": "box_ruins", "note": "a house"},
			{"rect": Rect2i(32, 18, 128, 12), "material": "crayon_ramp", "note": "with a red roof"},
			{"rect": Rect2i(80, 40, 26, 14), "material": "wood_face", "note": "and a door in it"},
			{"rect": Rect2i(116, 34, 18, 12), "material": "pillow", "note": "and a window"},
			{"rect": Rect2i(28, 10, 36, 8), "material": "pillow", "note": "a cloud"},
			{"rect": Rect2i(90, 14, 24, 8), "material": "pillow", "note": "and another"},
			{"rect": Rect2i(0, 0, 28, 8), "material": "page", "note": "the tape on its top-left corner"},
			{"rect": Rect2i(228, 0, 28, 8), "material": "page", "note": "and its top-right"},
		],
	},
	"curtain": {
		"size": Vector2i(112, 162),
		"unit": "blocks",
		"real": "10 in of cloth (107 blocks) hanging 36 in (162 blocks)",
		"up_in_inches": 0,
		"note": "One curtain, pushed to the side of the window — the same purple as the blanket, because a child's room is bought in sets",
		"emits": [
			{"rect": Rect2i(0, 0, 112, 12), "material": "wood_face", "note": "the rail it hangs from"},
			{"rect": Rect2i(0, 12, 112, 150), "material": "blanket", "note": "the panel"},
			{"rect": Rect2i(14, 12, 8, 150), "material": "blanket_fold",
				"repeat": {"count": 5, "step": Vector2i(22, 0)},
				"note": "five folds hanging down it"},
			{"rect": Rect2i(0, 150, 112, 12), "material": "blanket_fold", "note": "and the hem at its foot"},
		],
	},
	"blocks": {
		"size": Vector2i(176, 148),
		"unit": "blocks",
		"real": "3 in cubes: 32 blocks across, 14 blocks of face each",
		"up_in_inches": 0,
		"note": "Wooden alphabet blocks, stacked and abandoned — a staircase eighteen inches high that nobody built on purpose",
		"emits": [
			{"rect": Rect2i(24, 24, 176, 124), "material": "furniture_shade", "up_in_inches": 0, "only_on_ground": true,
				"note": "their shadow"},
			{"rect": Rect2i(0, 70, 32, 32), "material": "gate", "up_in_inches": 6, "note": "a blue block on the ground"},
			{"rect": Rect2i(0, 102, 32, 14), "material": "gate_face", "up_in_inches": 0, "note": "and its front, in shade"},
			{"rect": Rect2i(40, 70, 32, 32), "material": "crayon_ramp", "up_in_inches": 6, "note": "an orange one"},
			{"rect": Rect2i(40, 102, 32, 14), "material": "crayon_face", "up_in_inches": 0, "note": "and its front"},
			{"rect": Rect2i(80, 70, 32, 32), "material": "paint_top", "up_in_inches": 6, "note": "and a green one"},
			{"rect": Rect2i(80, 102, 32, 14), "material": "paint_face", "up_in_inches": 0, "note": "and its front"},
			{"rect": Rect2i(8, 78, 16, 16), "material": "pillow", "up_in_inches": 6, "note": "a letter on its face"},
			{"rect": Rect2i(48, 78, 16, 16), "material": "pillow", "up_in_inches": 6, "note": "another"},
			{"rect": Rect2i(88, 78, 16, 16), "material": "pillow", "up_in_inches": 6, "note": "and another"},
			{"rect": Rect2i(20, 24, 32, 32), "material": "box_ruins", "up_in_inches": 12, "note": "one stacked on top"},
			{"rect": Rect2i(20, 56, 32, 14), "material": "crossbar", "up_in_inches": 6, "note": "its front"},
			{"rect": Rect2i(60, 24, 32, 32), "material": "gate", "up_in_inches": 12, "note": "and its neighbour"},
			{"rect": Rect2i(60, 56, 32, 14), "material": "gate_face", "up_in_inches": 6, "note": "and its front"},
			{"rect": Rect2i(28, 32, 16, 16), "material": "pillow", "up_in_inches": 12, "note": "a letter"},
			{"rect": Rect2i(68, 32, 16, 16), "material": "pillow", "up_in_inches": 12, "note": "another"},
			{"rect": Rect2i(40, 0, 32, 24), "material": "crayon_ramp", "up_in_inches": 18,
				"note": "and the last one, eighteen inches up"},
			{"rect": Rect2i(48, 6, 16, 14), "material": "pillow", "up_in_inches": 18, "note": "and its letter"},
		],
	},
	"ball": {
		"size": Vector2i(96, 96),
		"unit": "blocks",
		"real": "a 9 in rubber ball — 96 blocks across",
		"up_in_inches": 6,
		"note": "A ball, stopped where it stopped — round, which nothing else in this room is",
		"emits": [
			{"rect": Rect2i(24, 24, 96, 96), "material": "furniture_shade", "up_in_inches": 0, "only_on_ground": true,
				"note": "its shadow"},
			{"rect": Rect2i(28, 0, 40, 8), "material": "crayon_ramp", "note": "the top of it"},
			{"rect": Rect2i(14, 8, 68, 8), "material": "crayon_ramp", "note": "widening"},
			{"rect": Rect2i(6, 16, 84, 8), "material": "crayon_ramp", "note": "and again"},
			{"rect": Rect2i(2, 24, 92, 8), "material": "crayon_ramp", "note": "and again"},
			{"rect": Rect2i(0, 32, 96, 32), "material": "crayon_ramp", "note": "its middle, full width"},
			{"rect": Rect2i(2, 64, 92, 8), "material": "crayon_ramp", "note": "narrowing"},
			{"rect": Rect2i(6, 72, 84, 8), "material": "crayon_ramp", "note": "and again"},
			{"rect": Rect2i(14, 80, 68, 8), "material": "crayon_ramp", "note": "and again"},
			{"rect": Rect2i(28, 88, 40, 8), "material": "crayon_ramp", "note": "and the bottom"},
			{"rect": Rect2i(0, 38, 96, 10), "material": "pillow", "note": "a white stripe round its middle"},
			{"rect": Rect2i(0, 48, 96, 10), "material": "gate", "note": "and a blue one under it"},
			{"rect": Rect2i(18, 12, 18, 12), "material": "pillow", "note": "and the shine the window puts on it"},
		],
	},
	"laundry_basket": {
		"size": Vector2i(224, 273),
		"unit": "blocks",
		"real": "21 x 18 in plan (224 x 192); 18 in tall, so 81 blocks of side",
		"up_in_inches": 18,
		"note": "The washing basket, not emptied. Wicker, so a pawn can see through it and still not get in",
		"emits": [
			{"rect": Rect2i(24, 24, 224, 249), "material": "furniture_shade", "up_in_inches": 0, "only_on_ground": true,
				"note": "its shadow"},
			{"rect": Rect2i(0, 0, 224, 192), "material": "box_ruins", "note": "the rim and the mouth of it, eighteen inches up"},
			{"rect": Rect2i(20, 20, 184, 152), "material": "shelf_face", "note": "and the dark inside"},
			{"rect": Rect2i(0, 192, 224, 81), "material": "shelf_face", "up_in_inches": 0,
				"note": "its woven side — eighty-one blocks, eighteen inches"},
			{"rect": Rect2i(16, 192, 14, 81), "material": "box_ruins", "up_in_inches": 0,
				"repeat": {"count": 6, "step": Vector2i(32, 0)},
				"note": "the weave, six uprights of it"},
			{"rect": Rect2i(0, 216, 224, 12), "material": "box_ruins", "up_in_inches": 0,
				"repeat": {"count": 2, "step": Vector2i(0, 30)},
				"note": "and two bands round its waist"},
			{"rect": Rect2i(120, 8, 72, 40), "material": "pillow", "note": "a sock hanging over the edge"},
			{"rect": Rect2i(130, 48, 40, 24), "material": "pillow", "note": "and the rest of it, inside"},
		],
	},
	"spilled_crayons": {
		"size": Vector2i(128, 96),
		"unit": "blocks",
		"real": "3.5 in crayons — 37 blocks long, 8 wide",
		"up_in_inches": 0,
		"note": "Crayons where they landed — the smallest things in the room, and still a pawn's own height",
		"emits": [
			{"rect": Rect2i(0, 4, 37, 8), "material": "crayon_ramp", "note": "one lying east to west"},
			{"rect": Rect2i(37, 6, 7, 4), "material": "wood_face", "note": "worn to a point"},
			{"rect": Rect2i(10, 4, 8, 8), "material": "page", "note": "and its paper label"},
			{"rect": Rect2i(48, 26, 37, 8), "material": "gate", "note": "a blue one"},
			{"rect": Rect2i(85, 28, 7, 4), "material": "wood_face", "note": "its point"},
			{"rect": Rect2i(58, 26, 8, 8), "material": "page", "note": "its label"},
			{"rect": Rect2i(20, 52, 37, 8), "material": "paint_top", "note": "a green one"},
			{"rect": Rect2i(57, 54, 7, 4), "material": "wood_face", "note": "its point"},
			{"rect": Rect2i(30, 52, 8, 8), "material": "page", "note": "its label"},
			{"rect": Rect2i(70, 74, 37, 8), "material": "box_ruins", "note": "and a brown one, snapped"},
			{"rect": Rect2i(100, 40, 8, 34), "material": "crayon_ramp", "note": "and one that rolled the other way"},
		],
	},
	"toy_car": {
		"size": Vector2i(96, 60),
		"unit": "blocks",
		"real": "9 in long, 4 in wide (96 x 43 plan); 3 in tall, so 14 blocks of flank",
		"up_in_inches": 6,
		"note": "A toy car left where it was pushed — nine inches, which to a pawn is a bus",
		"emits": [
			{"rect": Rect2i(24, 24, 96, 60), "material": "furniture_shade", "up_in_inches": 0, "only_on_ground": true,
				"note": "its shadow"},
			{"rect": Rect2i(8, 4, 80, 4), "material": "crayon_ramp", "note": "the body's nose"},
			{"rect": Rect2i(4, 8, 88, 4), "material": "crayon_ramp", "note": "widening"},
			{"rect": Rect2i(0, 12, 96, 26), "material": "crayon_ramp", "note": "its roof and flank"},
			{"rect": Rect2i(4, 38, 88, 4), "material": "crayon_ramp", "note": "in again"},
			{"rect": Rect2i(8, 42, 80, 4), "material": "crayon_ramp", "note": "and its tail"},
			{"rect": Rect2i(26, 0, 44, 4), "material": "gate", "note": "the cab's roof"},
			{"rect": Rect2i(22, 4, 52, 20), "material": "gate", "note": "and the cab on top"},
			{"rect": Rect2i(30, 10, 36, 10), "material": "window_glass", "note": "its windscreen"},
			{"rect": Rect2i(0, 46, 96, 14), "material": "crayon_face", "up_in_inches": 0,
				"note": "its flank in shade — fourteen blocks, three inches"},
			{"rect": Rect2i(8, 44, 20, 16), "material": "furniture_leg", "up_in_inches": 0, "note": "a wheel"},
			{"rect": Rect2i(68, 44, 20, 16), "material": "furniture_leg", "up_in_inches": 0, "note": "and another"},
			{"rect": Rect2i(13, 48, 10, 8), "material": "metal", "up_in_inches": 0, "note": "its hub"},
			{"rect": Rect2i(73, 48, 10, 8), "material": "metal", "up_in_inches": 0, "note": "and its hub"},
			{"rect": Rect2i(4, 4, 16, 4), "material": "metal", "note": "a bumper"},
			{"rect": Rect2i(76, 4, 16, 4), "material": "metal", "note": "and its pair"},
		],
	},
	"slippers": {
		"size": Vector2i(208, 96),
		"unit": "blocks",
		"real": "9 x 4 in each (96 x 43 plan), lying flat",
		"up_in_inches": 0,
		"note": "Slippers, kicked off and not lined up — the only two things in this room that are a pair",
		"emits": [
			{"rect": Rect2i(8, 16, 32, 6), "material": "paint_top", "note": "the left slipper's toe"},
			{"rect": Rect2i(0, 22, 48, 40), "material": "paint_top", "note": "its body"},
			{"rect": Rect2i(8, 62, 32, 6), "material": "paint_top", "note": "and its heel"},
			{"rect": Rect2i(10, 28, 28, 24), "material": "paint_face", "note": "and the hole your foot goes in"},
			{"rect": Rect2i(128, 6, 32, 6), "material": "paint_top", "note": "the right slipper's toe"},
			{"rect": Rect2i(120, 12, 48, 40), "material": "paint_top", "note": "its body, lying further off"},
			{"rect": Rect2i(128, 52, 32, 6), "material": "paint_top", "note": "and its heel"},
			{"rect": Rect2i(130, 18, 28, 24), "material": "paint_face", "note": "and its hole"},
		],
	},
	"light_switch": {
		"size": Vector2i(44, 24),
		"unit": "blocks",
		"real": "4 in wide (43 blocks) x 5 in tall on the wall (23 blocks)",
		"up_in_inches": 0,
		"note": "The light switch, at a child's shoulder height and forty times a pawn's",
		"emits": [
			{"rect": Rect2i(0, 0, 44, 24), "material": "page", "note": "its plate"},
			{"rect": Rect2i(12, 5, 20, 14), "material": "wood_face", "note": "the rocker on it, pressed down"},
			{"rect": Rect2i(20, 1, 5, 3), "material": "metal", "note": "a screw"},
			{"rect": Rect2i(20, 20, 5, 3), "material": "metal", "note": "and the one under it"},
		],
	},
	"socket": {
		"size": Vector2i(44, 16),
		"unit": "blocks",
		"real": "4 in wide (43 blocks) x 3.5 in tall on the wall (16 blocks)",
		"up_in_inches": 0,
		"note": "A socket over the skirting — the sort of thing you only notice when you are an inch tall",
		"emits": [
			{"rect": Rect2i(0, 0, 44, 16), "material": "page", "note": "its plate"},
			{"rect": Rect2i(10, 7, 7, 5), "material": "wood_face", "note": "one hole"},
			{"rect": Rect2i(27, 7, 7, 5), "material": "wood_face", "note": "the other"},
			{"rect": Rect2i(19, 2, 6, 4), "material": "wood_face", "note": "and the earth above them"},
		],
	},
	"wall_trophy": {
		"size": Vector2i(224, 168),
		"unit": "blocks",
		"real": "21 in of shield and crossed swords, hung at 60 in",
		"up_in_inches": 0,
		"note": "A shield with two swords crossed behind it, hung dead centre over the bed. The reference rooms all have one of these and it is the single loudest thing on their walls",
		"emits": [
			{"rect": Rect2i(0, 0, 26, 18), "material": "metal",
				"repeat": {"count": 8, "step": Vector2i(26, 18)},
				"note": "the first sword, stepped down to the right"},
			{"rect": Rect2i(198, 0, 26, 18), "material": "metal",
				"repeat": {"count": 8, "step": Vector2i(-26, 18)},
				"note": "the second, stepped the other way — the two of them make the cross"},
			{"rect": Rect2i(0, 0, 26, 18), "material": "wood_face", "note": "one hilt"},
			{"rect": Rect2i(198, 0, 26, 18), "material": "wood_face", "note": "and the other"},
			{"rect": Rect2i(72, 40, 80, 12), "material": "crayon_ramp", "note": "the shield's top edge"},
			{"rect": Rect2i(66, 52, 92, 56), "material": "crayon_ramp", "note": "its face"},
			{"rect": Rect2i(74, 108, 76, 16), "material": "crayon_ramp", "note": "coming in"},
			{"rect": Rect2i(88, 124, 48, 14), "material": "crayon_ramp", "note": "and again"},
			{"rect": Rect2i(102, 138, 20, 12), "material": "crayon_ramp", "note": "to a point"},
			{"rect": Rect2i(78, 56, 68, 10), "material": "metal", "note": "the band across it"},
			{"rect": Rect2i(102, 66, 20, 46), "material": "metal", "note": "and the boss down its middle"},
		],
	},
	"wall_shelf": {
		"size": Vector2i(160, 96),
		"unit": "blocks",
		"real": "15 in shelf with a toy helmet on it",
		"up_in_inches": 0,
		"note": "A little shelf with a toy helmet on it — the thing a child puts the prize on",
		"emits": [
			{"rect": Rect2i(0, 62, 160, 14), "material": "wood_face", "note": "the shelf board"},
			{"rect": Rect2i(0, 62, 160, 5), "material": "shelf_top", "note": "the light along its lip"},
			{"rect": Rect2i(18, 76, 12, 20), "material": "wood_face", "note": "a bracket under it"},
			{"rect": Rect2i(130, 76, 12, 20), "material": "wood_face", "note": "and the other"},
			{"rect": Rect2i(36, 20, 88, 42), "material": "crayon_ramp", "note": "the helmet's bowl"},
			{"rect": Rect2i(48, 12, 64, 8), "material": "crayon_ramp", "note": "its crown"},
			{"rect": Rect2i(10, 24, 26, 12), "material": "pillow", "note": "a horn"},
			{"rect": Rect2i(124, 24, 26, 12), "material": "pillow", "note": "and the other"},
			{"rect": Rect2i(2, 16, 12, 10), "material": "pillow", "note": "the horn's tip"},
			{"rect": Rect2i(146, 16, 12, 10), "material": "pillow", "note": "and its pair"},
			{"rect": Rect2i(50, 40, 60, 12), "material": "wood_face", "note": "and the slot it sees through"},
		],
	},
	"pennant": {
		"size": Vector2i(128, 76),
		"unit": "blocks",
		"real": "12 in felt pennant, pinned to the wall",
		"up_in_inches": 0,
		"note": "A felt pennant, pinned up and never taken down",
		"emits": [
			{"rect": Rect2i(0, 0, 128, 13), "material": "gate", "note": "its top edge"},
			{"rect": Rect2i(0, 13, 110, 13), "material": "gate", "note": "coming in"},
			{"rect": Rect2i(0, 26, 92, 13), "material": "gate", "note": "and in"},
			{"rect": Rect2i(0, 39, 74, 13), "material": "gate", "note": "and in"},
			{"rect": Rect2i(0, 52, 56, 13), "material": "gate", "note": "and in"},
			{"rect": Rect2i(0, 65, 38, 11), "material": "gate", "note": "to a point"},
			{"rect": Rect2i(0, 0, 14, 76), "material": "crayon_ramp", "note": "the band down its hoist"},
			{"rect": Rect2i(24, 24, 40, 14), "material": "pillow", "note": "and a letter stitched on it"},
		],
	},
	"cardboard_box": {
		"size": Vector2i(448, 240),
		"unit": "blocks",
		"real": "42 x 22 in of box, standing 18 in — half of it below the frame",
		"up_in_inches": 18,
		"note": "A packing box left at the near edge of the room, half out of shot. The reference rooms all put something big and cut off across the bottom of the frame; it is what gives the floor a foreground and stops the picture being a plan",
		"emits": [
			{"rect": Rect2i(24, 24, 448, 216), "material": "furniture_shade", "up_in_inches": 0, "only_on_ground": true,
				"note": "its shadow"},
			{"rect": Rect2i(16, 0, 416, 8), "material": "box_ruins", "note": "its back edge, corners in"},
			{"rect": Rect2i(0, 8, 448, 120), "material": "box_ruins", "note": "the open top of it"},
			{"rect": Rect2i(24, 20, 400, 96), "material": "crossbar", "note": "and the dark inside"},
			{"rect": Rect2i(24, 20, 400, 10), "material": "box_ruins", "note": "a flap folded in at the back"},
			{"rect": Rect2i(24, 106, 400, 10), "material": "box_ruins", "note": "and one at the front"},
			{"rect": Rect2i(0, 128, 448, 81), "material": "box_ruins", "up_in_inches": 0,
				"note": "its side, eighteen inches of it"},
			{"rect": Rect2i(0, 128, 448, 6), "material": "crossbar", "up_in_inches": 0, "note": "the fold at its lip"},
			{"rect": Rect2i(160, 150, 128, 40), "material": "crossbar", "up_in_inches": 0,
				"note": "and something written on the side in marker"},
		],
	},
	"rug": {
		"size": Vector2i(448, 640),
		"unit": "blocks",
		"real": "42 x 60 in on the floor (448 x 640 blocks)",
		"up_in_inches": 0,
		"note": "The rug the play table stands on — bound edge, woven border, a medallion and fringe at both ends",
		"emits": [
			{"rect": Rect2i(0, 0, 448, 640), "material": "deep_pile", "note": "its bound edge"},
			{"rect": Rect2i(24, 24, 400, 592), "material": "rug_motif", "note": "the woven border stripe"},
			{"rect": Rect2i(44, 44, 360, 552), "material": "deep_pile_worn", "note": "and its field"},
			{"rect": Rect2i(64, 64, 320, 8), "material": "rug_motif", "note": "an inner line along its head"},
			{"rect": Rect2i(64, 568, 320, 8), "material": "rug_motif", "note": "one along its foot"},
			{"rect": Rect2i(64, 64, 8, 512), "material": "rug_motif", "note": "and one down each side"},
			{"rect": Rect2i(376, 64, 8, 512), "material": "rug_motif", "note": "the other side"},
			{"rect": Rect2i(176, 264, 96, 112), "material": "rug_motif", "note": "the medallion woven in the middle"},
			{"rect": Rect2i(192, 280, 64, 80), "material": "deep_pile", "note": "and the field inside it"},
			{"rect": Rect2i(208, 300, 32, 40), "material": "rug_motif", "note": "and its eye"},
			{"rect": Rect2i(16, 0, 8, 24), "material": "deep_pile_worn", "up_in_inches": 0,
				"repeat": {"count": 26, "step": Vector2i(16, 0)},
				"note": "fringe along its head, twenty-six strands"},
			{"rect": Rect2i(16, 616, 8, 24), "material": "deep_pile_worn", "up_in_inches": 0,
				"repeat": {"count": 26, "step": Vector2i(16, 0)},
				"note": "and the same along its foot"},
		],
	},
}

## THE LEVEL. A bedroom arranged the way bedrooms are arranged — bed head to the
## wall away from the door, desk under the window, wardrobe on the blank wall,
## chest at the foot of the bed, rug in the middle, toys where they were dropped
## — and then read as a Souls level, because at a pawn's scale that is what a
## furnished room already is: a vertical space with one safe corner, several
## ways up, and exactly one way back down.
##
## THE LOOP, which is the whole design:
##   The Landing (0")  the boards behind the bookcase; where you wake, and the
##                     only corner of the room nothing can reach you in.
##        |
##   The Long Boards   the open middle. No cover, long sight lines, and the two
##                     things hunting you can see the whole of it.
##        |            \
##   The Toy Country    \  The Stool (6-18") -> The Open Drawer (24") ->
##   blocks, ball,       \  THE DESK (30"). A dead end on purpose: the highest
##   basket. A side       \ ground in the room, and all it holds is a rule page.
##   path, and cover.
##        |
##   THE BOOKCASE      six shelves, six inches apart. The climb, and it is long
##   (6-30 -> 36")     and it is exposed and there is no way off it halfway.
##        |
##        v  ONE-WAY DROP, twelve inches
##   THE BED (24")     high ground you can only arrive at, never leave the way
##                     you came. Walk its length to the blanket.
##        |
##   THE BLANKET       24 -> 18 -> 12 -> 6 -> 0, landing in the middle of the
##                     room a step from the play table. THE SHORTCUT: after you
##                     have opened it once, the bookcase climb is optional.
##        |
##   THE PLAY TABLE    the book stack is the stair; the board is the arena; the
##   (24")             gate on its south edge is the fog door.
##
## Everything above is checked by REQUIRED_ROUTES before the map is written, and
## the drop rule makes the direction real: the bookcase-to-bed link only works
## downhill, so the loop cannot be run backwards.
const LEVEL := [
	{"area": "the_landing", "cell": Vector2i(104, 90), "up_in_inches": 0,
		"note": "the safe corner behind the bookcase — where you wake"},
	{"area": "the_long_boards", "cell": Vector2i(80, 89), "up_in_inches": 0,
		"note": "the open middle, no cover, two hunters"},
	{"area": "the_toy_country", "cell": Vector2i(30, 82), "up_in_inches": 0,
		"note": "blocks, ball and basket — the side path, and the only cover on the floor"},
	{"area": "the_bookcase_foot", "cell": Vector2i(104, 86), "up_in_inches": 0,
		"note": "the bottom shelf, the start of the climb"},
	{"area": "the_bookcase_top", "cell": Vector2i(108, 70), "up_in_inches": 36,
		"note": "thirty-six inches, and the only way off it is down"},
	{"area": "the_bed", "cell": Vector2i(95, 45), "up_in_inches": 24,
		"note": "arrived at by dropping twelve inches, and there is no climbing back"},
	{"area": "the_blanket", "cell": Vector2i(78, 66), "up_in_inches": 0,
		"note": "the shortcut's foot, a step from the play table"},
	{"area": "the_stool", "cell": Vector2i(50, 64), "up_in_inches": 6,
		"note": "the first rung of the side path"},
	{"area": "the_desk", "cell": Vector2i(50, 35), "up_in_inches": 30,
		"note": "the highest ground in the room, and a dead end"},
	{"area": "the_book_stair", "cell": Vector2i(70, 87), "up_in_inches": 6,
		"note": "the stair up to the arena"},
	{"area": "the_board", "cell": Vector2i(51, 77), "up_in_inches": 24,
		"note": "THE ARENA — eight squares, and inside them chess rules bind"},
	{"area": "the_door", "cell": Vector2i(20, 30), "up_in_inches": 0,
		"note": "shut, and it stays shut — the way out of the demo, not out of the level"},
]

const PLACEMENTS := [
	{"piece": "curtain", "origin": Vector2i(32, 8)},
	{"piece": "curtain", "origin": Vector2i(61, 8)},
	{"piece": "poster", "origin": Vector2i(68, 7)},
	{"piece": "wall_trophy", "origin": Vector2i(84, 6)},
	{"piece": "wall_shelf", "origin": Vector2i(104, 15)},
	{"piece": "pennant", "origin": Vector2i(70, 16)},
	{"piece": "light_switch", "origin": Vector2i(75, 13)},
	{"piece": "socket", "origin": Vector2i(106, 23)},

	# --- THE FAR WALL, west to east: three big pieces, backs on the wall, and the
	# door is no longer taking up a quarter of it
	{"piece": "wardrobe", "origin": Vector2i(9, 27)},
	{"piece": "desk", "origin": Vector2i(34, 27)},
	{"piece": "bed", "origin": Vector2i(70, 27)},

	# --- THE RIGHT WALL: the bookcase that is also the staircase, and the chest
	{"piece": "bookcase", "origin": Vector2i(100, 57)},
	{"piece": "toy_chest", "origin": Vector2i(100, 76)},

	# --- THE MIDDLE stays clear. Only the rug and what stands on it.
	{"piece": "rug", "origin": Vector2i(46, 60)},
	{"piece": "chair", "origin": Vector2i(44, 51)},
	{"piece": "play_table", "origin": Vector2i(50, 70)},
	{"piece": "book_stack", "origin": Vector2i(74, 72)},

	# --- THE NEAR EDGE, half out of frame
	{"piece": "cardboard_box", "origin": Vector2i(86, 88)},

	# --- and every loose thing pushed to a corner or an edge, where dropped
	# things actually end up, rather than left lying in the middle of the floor
	{"piece": "laundry_basket", "origin": Vector2i(10, 84)},
	{"piece": "blocks", "origin": Vector2i(26, 86)},
	{"piece": "slippers", "origin": Vector2i(12, 74)},
	{"piece": "toy_car", "origin": Vector2i(38, 88)},
	{"piece": "ball", "origin": Vector2i(88, 80)},
	{"piece": "spilled_crayons", "origin": Vector2i(96, 84)},
]

## What the player meets, in the order they meet it. The first node is the bonfire.
const NODES := [
	{"cell": Vector2i(94, 86), "kind": "spawn", "label": "THE LANDING — you wake here, under the bookcase, in the one corner nothing reaches"},
	{"cell": Vector2i(80, 84), "kind": "double_step", "label": "The Long Boards — open ground, and something hunting on it"},
	{"cell": Vector2i(20, 80), "kind": "pawn", "label": "The Toy Country — cover, and a fallen pawn holding it"},
	{"cell": Vector2i(102, 74), "kind": "landmark", "label": "The bookcase's bottom shelf — the climb starts here"},
	{"cell": Vector2i(102, 60), "kind": "vista", "label": "The bookcase top, thirty-six inches — the only way off is down"},
	{"cell": Vector2i(95, 45), "kind": "promoted", "label": "THE PROMOTED, met on the bed you cannot leave the way you came"},
	{"cell": Vector2i(78, 67), "kind": "shortcut", "label": "The blanket's hem — THE SHORTCUT, and it opens the level"},
	{"cell": Vector2i(50, 64), "kind": "page", "label": "The stool's stretcher — the side path begins"},
	{"cell": Vector2i(50, 35), "kind": "page", "label": "THE DESK, thirty inches up: a rule page, and no way on"},
	{"cell": Vector2i(80, 88), "kind": "landmark", "label": "The book stair — the arena is above it"},
	{"cell": Vector2i(60, 81), "kind": "gate", "label": "THE GATE on the board's south edge"},
	{"cell": Vector2i(61, 77), "kind": "boss", "label": "THE KNIGHT — he defends the square, not himself"},
	{"cell": Vector2i(12, 70), "kind": "door", "label": "The door in the left wall, shut"},
]

## Every route that must be walkable. Each is a link in the loop, and the drop
## rule makes half of them one-way.
const REQUIRED_ROUTES := [
	{"from": Vector2i(94, 86), "to": Vector2i(80, 84), "note": "the landing out onto the long boards"},
	{"from": Vector2i(94, 86), "to": Vector2i(20, 80), "note": "the boards west into the toy country"},
	{"from": Vector2i(94, 86), "to": Vector2i(12, 70), "note": "and on to the door in the left wall"},
	{"from": Vector2i(94, 86), "to": Vector2i(102, 74), "note": "the landing to the foot of the bookcase"},
	{"from": Vector2i(94, 86), "to": Vector2i(102, 60), "note": "UP THE SIX SHELVES TO THE TOP"},
	{"from": Vector2i(94, 86), "to": Vector2i(95, 45), "note": "AND DOWN THE TWELVE-INCH DROP ONTO THE BED"},
	{"from": Vector2i(94, 86), "to": Vector2i(78, 67), "note": "along the bed and down the blanket — the shortcut"},
	{"from": Vector2i(94, 86), "to": Vector2i(50, 64), "note": "the boards to the stool"},
	{"from": Vector2i(94, 86), "to": Vector2i(50, 35), "note": "UP THE STOOL AND THE OPEN DRAWER ONTO THE DESK"},
	{"from": Vector2i(94, 86), "to": Vector2i(80, 88), "note": "the boards to the book stair"},
	{"from": Vector2i(94, 86), "to": Vector2i(61, 77), "note": "UP THE BOOKS ONTO THE BOARD"},
]

## The crops saved beside the whole-room view, at full resolution — the pawn's
## own view. A room that only works zoomed out is a floor plan; one that only
## works zoomed in is a diorama.
const CLOSE_UPS := [
	{"name": "close_up_board.png", "rect": Rect2i(44, 66, 44, 28),
		"note": "the arena: the play table, the board, the gate and the book stair"},
	{"name": "close_up_shortcut.png", "rect": Rect2i(84, 48, 44, 32),
		"note": "the shortcut: the bookcase top, the drop onto the bed, the chest below"},
	{"name": "close_up_desk.png", "rect": Rect2i(32, 22, 44, 32),
		"note": "the side path: the window, the desk, its open drawer and the stool"},
]


func _init() -> void:
	var tiles := _load_tiles()
	if tiles.is_empty():
		quit(1)
		return
	if not _make_output_dir():
		return

	var hand := _load_hand_pieces()
	var regions := _regions(hand)
	var painted := _paint(regions, tiles, MAP_WIDTH_IN_BLOCKS, MAP_HEIGHT_IN_BLOCKS)
	if not _apply_hand_heights(painted, hand):
		return

	var broken := _find_broken_routes(painted, tiles)
	if not broken.is_empty():
		for route in broken:
			printerr("route broken: ", route)
		quit(1)
		return

	var block_map := _stamp(painted, tiles)
	if block_map == null:
		return
	_composite_hand_art(block_map, hand)
	var map := _to_world_pixels(block_map)
	if not _save(map, "demo_map.png"):
		return
	for close_up in CLOSE_UPS:
		var rect: Rect2i = close_up["rect"]
		if not Rect2i(0, 0, MAP_WIDTH_IN_CELLS, MAP_HEIGHT_IN_CELLS).encloses(rect):
			printerr("close-up ", close_up["name"], " runs off the map: ", rect)
			quit(1)
			return
		var crop := map.get_region(Rect2i(
			rect.position * CELL_SIZE_IN_PIXELS, rect.size * CELL_SIZE_IN_PIXELS
		))
		if not _save(crop, close_up["name"]):
			return
	if not _write_manifest(painted, regions):
		return

	var sheet_size := _sheet_size()
	var sheet_blocks := _stamp(_paint(_sheet_regions(), tiles, sheet_size.x, sheet_size.y), tiles)
	if sheet_blocks == null or not _save(_to_world_pixels(sheet_blocks), "furniture_sheet.png"):
		return
	if not _export_templates(tiles):
		return

	print(
		"room %dx%d cells (%d x %d blocks) = %d x %d inches, %d pieces placed, %d regions, %d routes climbed, %d holes" % [
			MAP_WIDTH_IN_CELLS, MAP_HEIGHT_IN_CELLS,
			MAP_WIDTH_IN_BLOCKS, MAP_HEIGHT_IN_BLOCKS,
			int(MAP_WIDTH_IN_CELLS * INCHES_PER_CELL),
			int(MAP_HEIGHT_IN_CELLS * INCHES_PER_CELL),
			PLACEMENTS.size(), regions.size(), REQUIRED_ROUTES.size(), _count_holes(painted),
		]
	)
	print("close-ups saved: ", ", ".join(CLOSE_UPS.map(func(c): return c["name"])))
	print(
		"hand-drawn pieces in use: %s" % [
			", ".join(hand.keys()) if not hand.is_empty() else "none yet — templates written to " + PIECE_TEMPLATE_DIR
		]
	)
	print(
		"furniture sheet %dx%d blocks, %d pieces: %s" % [
			sheet_size.x, sheet_size.y, PIECES.size(), ", ".join(PIECES.keys())
		]
	)
	quit()


func _make_output_dir() -> bool:
	var absolute_output_dir := ProjectSettings.globalize_path(OUTPUT_DIR)
	if DirAccess.dir_exists_absolute(absolute_output_dir):
		return true
	var made := DirAccess.make_dir_recursive_absolute(absolute_output_dir)
	if made != OK:
		printerr("could not create ", OUTPUT_DIR, ": ", made)
		quit(1)
		return false
	return true


## Flattens the room and everything standing in it into absolute regions. The
## only place a piece's own coordinates become the room's, so a piece can never
## come apart from its shadow, its posts or its blanket.
func _regions(hand: Dictionary = {}) -> Array:
	var regions := []
	if not hand.has(ROOM_ART_NAME):
		regions = _emit(
			THE_ROOM["name"], 0, THE_ROOM["up_in_inches"], Vector2i.ZERO,
			THE_ROOM["emits"], 1
		)
	for index in PLACEMENTS.size():
		var placement: Dictionary = PLACEMENTS[index]
		if hand.has(placement["piece"]):
			continue
		var piece: Dictionary = PIECES[placement["piece"]]
		regions.append_array(_emit(
			placement["piece"], index + 1, piece["up_in_inches"],
			placement["origin"] * BLOCKS_PER_CELL, piece["emits"], _scale_of(piece)
		))
	return regions


## How many blocks one of a piece's own units is. A piece authored in cells is
## the old, coarse way and each of its numbers is sixteen blocks; a piece
## authored in blocks says every block itself, which is where the detail lives.
func _scale_of(piece: Dictionary) -> int:
	return 1 if piece.get("unit", "cells") == "blocks" else BLOCKS_PER_CELL


## One object's emits, moved to where the object stands, with "repeat" expanded.
## An emit's own "up_in_inches" wins over its object's, which is how one piece
## carries a ramp; "repeat" turns one entry into a row of identical details, so a
## spindle or a book spine is written once and counted, never copied.
func _emit(
	name: String, object_index: int, up: int, origin: Vector2i, emits: Array, scale: int
) -> Array:
	var regions := []
	for emitted in emits:
		var rect: Rect2i = emitted["rect"]
		var repeat: Dictionary = emitted.get("repeat", {})
		var count: int = repeat.get("count", 1)
		var step: Vector2i = repeat.get("step", Vector2i.ZERO)
		for copy in count:
			regions.append({
				"object": name,
				"object_index": object_index,
				"up_in_inches": emitted.get("up_in_inches", up),
				"rect": Rect2i(
					origin + (rect.position + step * copy) * scale, rect.size * scale
				),
				"skew_east_per_row": emitted.get("skew_east_per_row", 0),
				"only_on_ground": emitted.get("only_on_ground", false),
				"material": emitted["material"],
				"note": emitted["note"],
			})
	return regions


## Lays every piece out in one row on dark ground, each in its own object slot so
## each gets its own outline: the pieces judged as things, before any room is
## furnished with them.
func _sheet_regions() -> Array:
	var size := _sheet_size()
	var regions: Array = [{
		"object": "sheet", "object_index": 0, "up_in_inches": 0,
		"rect": Rect2i(0, 0, size.x, size.y), "skew_east_per_row": 0,
		"only_on_ground": false,
		"material": "room_edge", "note": "the ground the specimens stand on",
	}]
	var gutter := SHEET_GUTTER_IN_CELLS * BLOCKS_PER_CELL
	var cursor := gutter
	var index := 1
	for name in PIECES:
		var piece: Dictionary = PIECES[name]
		regions.append_array(_emit(
			name, index, piece["up_in_inches"],
			Vector2i(cursor, gutter), piece["emits"], _scale_of(piece)
		))
		cursor += piece["size"].x * _scale_of(piece) + gutter
		index += 1
	return regions


## How big the specimen sheet has to be to hold every piece in one row, with the
## shadow each one throws, plus a gutter all round.
func _sheet_size() -> Vector2i:
	var gutter := SHEET_GUTTER_IN_CELLS * BLOCKS_PER_CELL
	var width := gutter
	var tallest := 0
	for name in PIECES:
		var piece: Dictionary = PIECES[name]
		var size: Vector2i = piece["size"] * _scale_of(piece)
		width += size.x + gutter
		tallest = maxi(tallest, size.y)
	return Vector2i(width, tallest + gutter * 2)


## Reads the tile manifest: which materials block movement, which body each one
## belongs to, and the colours its rim is drawn with, so the stamper and the
## route walker can never disagree with the tiles the map is made of.
func _load_tiles() -> Dictionary:
	var path := "%s/manifest.json" % TILE_DIR
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		printerr("missing ", path, " — run tools/generate_kingdom_tiles.gd first")
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("tiles"):
		printerr("unreadable tile manifest at ", path)
		return {}

	var tiles: Dictionary = parsed["tiles"]
	for material in CODE_BY_MATERIAL:
		if not tiles.has(material):
			printerr("the map uses ", material, " but ", path, " has no such tile")
			return {}
	return tiles


## Paints every region into ART BLOCK resolution — sixteen blocks to a cell, one
## block to two world pixels. This is the whole point of working in blocks: a
## piece is no longer a mosaic of thirty-two pixel squares but a drawing with the
## same grain of control a hand pixel artist has. One reference-pack pixel is one
## of our blocks, so a bed fifty cells wide gets eight hundred blocks across
## instead of fifty, and details smaller than a cell — a highlight, a screw head,
## a rounded corner — become sayable.
##
## The grids are flat integer arrays because three million entries of anything
## richer would not fit in a tool script's patience. Returns:
##   material_by_block — index into MATERIAL_NAMES; "void" where nothing painted.
##   height_by_block   — how high that block's surface stands, in inches.
##   object_by_block   — who owns it; the stamper outlines where this changes.
func _paint(regions: Array, tiles: Dictionary, width: int, height: int) -> Dictionary:
	var names := _material_names()
	var index_by_material := {}
	for index in names.size():
		index_by_material[names[index]] = index
	var body_by_index := PackedStringArray()
	for name in names:
		body_by_index.append(tiles[name]["body"])
	var ground_by_index := PackedByteArray()
	for name in names:
		ground_by_index.append(1 if GROUND_BODIES.has(tiles[name]["body"]) else 0)

	var count := width * height
	var material_by_block := PackedInt32Array()
	material_by_block.resize(count)
	material_by_block.fill(index_by_material["void"])
	var height_by_block := PackedInt32Array()
	height_by_block.resize(count)
	height_by_block.fill(0)
	var object_by_block := PackedInt32Array()
	object_by_block.resize(count)
	object_by_block.fill(-1)
	var solid_by_block := PackedByteArray()
	solid_by_block.resize(count)
	solid_by_block.fill(0)
	var order_by_block := PackedInt32Array()
	order_by_block.resize(count)
	order_by_block.fill(-1)

	var order := 0
	for region in regions:
		order += 1
		var rect: Rect2i = region["rect"]
		var up: int = region["up_in_inches"]
		var object_index: int = region["object_index"]
		var skew: int = region["skew_east_per_row"]
		var only_on_ground: bool = region["only_on_ground"]
		var material: String = region["material"]
		var plain: int = index_by_material.get(material, -1)
		for y in range(maxi(rect.position.y, 0), mini(rect.end.y, height)):
			var lean := (y - rect.position.y) * skew
			var row := y * width
			for x in range(maxi(rect.position.x + lean, 0), mini(rect.end.x + lean, width)):
				var here := row + x
				if only_on_ground and ground_by_index[material_by_block[here]] == 0:
					continue
				material_by_block[here] = (
					plain if plain >= 0 else index_by_material[_resolve(material, x, y)]
				)
				height_by_block[here] = up
				object_by_block[here] = object_index
				order_by_block[here] = order
				solid_by_block[here] = 1 if tiles[names[material_by_block[here]]]["solid"] else 0

	return {
		"width": width,
		"height": height,
		"names": names,
		"body_by_index": body_by_index,
		"material_by_block": material_by_block,
		"height_by_block": height_by_block,
		"object_by_block": object_by_block,
		"order_by_block": order_by_block,
		"solid_by_block": solid_by_block,
	}


## Every material this map can paint, in one fixed order, so a block can hold an
## index instead of a name.
func _material_names() -> PackedStringArray:
	var names := PackedStringArray()
	for material in CODE_BY_MATERIAL:
		names.append(material)
	return names


## Turns a material written as a pattern into the one this block gets. The
## patterns are still measured in cells — a floorboard course, a wallpaper
## stripe, a board square are all cell-sized things — so this reads the block's
## cell before deciding.
func _resolve(material: String, block_x: int, block_y: int) -> String:
	var x := block_x / BLOCKS_PER_CELL
	var y := block_y / BLOCKS_PER_CELL
	match material:
		"floorboards":
			return "floor_plank"
		"sunlight":
			return "daylight"
		"paper":
			return "wallpaper_stripe" if block_x % (6 * BLOCKS_PER_CELL) < 2 else "wallpaper"
		"board":
			return "board_light" if (x + y) % 2 == 0 else "board_dark"
		_:
			return material


## Reads one cell out of the block grids, sampling its middle. Gameplay is still
## played on cells — a piece stands on a square, not on a block — so the route
## walker and the manifest both come through here.
func _cell(painted: Dictionary, key: String, x: int, y: int) -> int:
	var block_x := x * BLOCKS_PER_CELL + BLOCKS_PER_CELL / 2
	var block_y := y * BLOCKS_PER_CELL + BLOCKS_PER_CELL / 2
	return painted[key][block_y * int(painted["width"]) + block_x]


## Counts cells nothing claimed. It asks WHO owns the cell rather than what it is
## made of: a hand-drawn piece has an owner and no material, so counting
## materials reported the whole floor missing the moment the room was drawn by
## hand. A canary that cries wolf is worse than no canary.
func _count_holes(painted: Dictionary) -> int:
	var holes := 0
	for y in MAP_HEIGHT_IN_CELLS:
		for x in MAP_WIDTH_IN_CELLS:
			if _cell(painted, "object_by_block", x, y) < 0:
				holes += 1
	return holes


## Flood-fills from the spawn and reports every required route whose ends did not
## both land in the same walkable region. A step is walkable when the target is
## not solid AND the two surfaces are within MAX_STEP_IN_INCHES of each other —
## the same rule the player will feel, so the map cannot promise a climb the room
## does not physically offer.
func _find_broken_routes(painted: Dictionary, tiles: Dictionary) -> Array:
	var solid_by_block: PackedByteArray = painted["solid_by_block"]
	var width: int = painted["width"]
	var start: Vector2i = NODES[0]["cell"]
	var reached := {start: true}
	var frontier: Array[Vector2i] = [start]
	var steps: Array[Vector2i] = [
		Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN
	]
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		var standing := _cell(painted, "height_by_block", cell.x, cell.y)
		for step in steps:
			var next: Vector2i = cell + step
			if next.x < 0 or next.y < 0:
				continue
			if next.x >= MAP_WIDTH_IN_CELLS or next.y >= MAP_HEIGHT_IN_CELLS:
				continue
			if reached.has(next):
				continue
			var at := (next.y * BLOCKS_PER_CELL + BLOCKS_PER_CELL / 2) * width \
				+ next.x * BLOCKS_PER_CELL + BLOCKS_PER_CELL / 2
			if solid_by_block[at] == 1:
				continue
			var landing := _cell(painted, "height_by_block", next.x, next.y)
			if landing - standing > MAX_STEP_IN_INCHES:
				continue
			if standing - landing > MAX_DROP_IN_INCHES:
				continue
			reached[next] = true
			frontier.append(next)

	var broken := []
	for route in REQUIRED_ROUTES:
		if not reached.has(route["from"]) or not reached.has(route["to"]):
			broken.append(route["note"])
	return broken


## Draws the picture one block per pixel, then doubles it to world pixels. Three
## passes, in the order a pixel artist works: lay the flat colour, put the grain
## into the woods, then bevel every body — lit along its top and left, ink down
## its bottom and right. The bevel is what a hand artist spends most of their
## time on and it is the single biggest reason their work reads and a field of
## flat rectangles does not.
func _stamp(painted: Dictionary, tiles: Dictionary) -> Image:
	var width: int = painted["width"]
	var height: int = painted["height"]
	var names: PackedStringArray = painted["names"]
	var material_by_block: PackedInt32Array = painted["material_by_block"]
	var object_by_block: PackedInt32Array = painted["object_by_block"]
	var body_by_index: PackedStringArray = painted["body_by_index"]

	var mid := _colour_table(tiles, names, "mid")
	var ink := _colour_table(tiles, names, "ink")
	var lit := _colour_table(tiles, names, "lit")
	var dark := _colour_table(tiles, names, "dark")
	var shade := _mixed_table(tiles, names, "mid", "ink", 0.34)
	var weft := _mixed_table(tiles, names, "mid", "dark", 0.22)
	var order_by_block: PackedInt32Array = painted["order_by_block"]
	var raised_by_index := PackedByteArray()
	var grain_by_index := PackedInt32Array()
	var weave_by_index := PackedInt32Array()
	for name in names:
		raised_by_index.append(1 if tiles[name]["raised"] else 0)
		grain_by_index.append(int(tiles[name]["grain"]) * BLOCKS_PER_CELL)
		weave_by_index.append(int(tiles[name]["weave"]))

	var pixels := PackedByteArray()
	pixels.resize(width * height * 4)

	# 1. the flat colour of every block
	for i in width * height:
		var m := material_by_block[i] * 4
		var o := i * 4
		pixels[o] = mid[m]
		pixels[o + 1] = mid[m + 1]
		pixels[o + 2] = mid[m + 2]
		pixels[o + 3] = 255

	# 2. the weave in the cloths and papers — a diagonal hatch, because a flat
	#    colour is what a rectangle looks like and cloth is never a flat colour
	for y in height:
		var row := y * width
		for x in width:
			var i := row + x
			var index := material_by_block[i]
			var weave := weave_by_index[index]
			if weave == 0 or (x + y) % weave != 0:
				continue
			var w := index * 4
			var o := i * 4
			pixels[o] = weft[w]
			pixels[o + 1] = weft[w + 1]
			pixels[o + 2] = weft[w + 2]

	# 3. the grain in the woods, and the staggered butts in the floor alone
	for y in height:
		var course := y / BLOCKS_PER_CELL / ROWS_PER_FLOORBOARD
		var stagger := (course * BOARD_STAGGER_PER_ROW) % CELLS_PER_BOARD_LENGTH
		var row := y * width
		for x in width:
			var i := row + x
			var index := material_by_block[i]
			var grain := grain_by_index[index]
			if grain == 0:
				continue
			var on_grain := y % grain < 2
			var on_butt := (
				body_by_index[index] == "floor"
				and (x / BLOCKS_PER_CELL + stagger) % CELLS_PER_BOARD_LENGTH == 0
				and x % BLOCKS_PER_CELL < 2
			)
			if not on_grain and not on_butt:
				continue
			var d := index * 4
			var o := i * 4
			pixels[o] = dark[d]
			pixels[o + 1] = dark[d + 1]
			pixels[o + 2] = dark[d + 2]

	# 4. the contact shadow: anything laid down AFTER the surface under it — a
	#    pencil on a desk, a pawn on a board, a book on a shelf — drops a short
	#    shadow south-east onto that surface. This is what makes a small thing sit
	#    ON something instead of being printed on it.
	var reach := CONTACT_SHADOW_IN_BLOCKS
	for y in range(reach, height):
		var row := y * width
		for x in range(reach, width):
			var i := row + x
			var over := i - reach * width - reach
			if order_by_block[over] <= order_by_block[i]:
				continue
			var index := material_by_block[i]
			if body_by_index[material_by_block[over]] == body_by_index[index]:
				continue
			var s := index * 4
			var o := i * 4
			pixels[o] = shade[s]
			pixels[o + 1] = shade[s + 1]
			pixels[o + 2] = shade[s + 2]

	# 5. the bevel, one block wide, around each body and nowhere inside one
	for y in height:
		var row := y * width
		for x in width:
			var i := row + x
			var index := material_by_block[i]
			var body := body_by_index[index]
			var owner := object_by_block[i]
			var north := y > 0 and _other(material_by_block, object_by_block, body_by_index, i - width, body, owner)
			var west := x > 0 and _other(material_by_block, object_by_block, body_by_index, i - 1, body, owner)
			var south := y < height - 1 and _other(material_by_block, object_by_block, body_by_index, i + width, body, owner)
			var east := x < width - 1 and _other(material_by_block, object_by_block, body_by_index, i + 1, body, owner)
			var o := i * 4
			if south or east:
				var k := index * 4
				pixels[o] = ink[k]
				pixels[o + 1] = ink[k + 1]
				pixels[o + 2] = ink[k + 2]
			elif (north or west) and raised_by_index[index] == 1:
				var l := index * 4
				pixels[o] = lit[l]
				pixels[o + 1] = lit[l + 1]
				pixels[o + 2] = lit[l + 2]

	return Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, pixels)


## Doubles a block-resolution picture into world pixels. One block, two pixels,
## nearest neighbour — never anything else, or the art stops being pixel art.
func _to_world_pixels(block_image: Image) -> Image:
	var image := Image.create_from_data(
		block_image.get_width(), block_image.get_height(), false,
		Image.FORMAT_RGBA8, block_image.get_data()
	)
	image.resize(
		image.get_width() * PIXELS_PER_BLOCK, image.get_height() * PIXELS_PER_BLOCK,
		Image.INTERPOLATE_NEAREST
	)
	return image


## True when that neighbouring block belongs to a different silhouette — another
## object, or the same object wearing a different body.
func _other(
	material_by_block: PackedInt32Array, object_by_block: PackedInt32Array,
	body_by_index: PackedStringArray, at: int, body: String, owner: int
) -> bool:
	if object_by_block[at] != owner:
		return true
	return body_by_index[material_by_block[at]] != body


## One material's tone mixed part way toward another, for the weave hatch and the
## contact shadow — both of which are the same colour, only darker.
func _mixed_table(
	tiles: Dictionary, names: PackedStringArray, from_key: String, to_key: String, amount: float
) -> PackedByteArray:
	var table := PackedByteArray()
	for name in names:
		var colour := Color(tiles[name][from_key]).lerp(Color(tiles[name][to_key]), amount)
		table.append(colour.r8)
		table.append(colour.g8)
		table.append(colour.b8)
		table.append(255)
	return table


## One material's chosen tone, unpacked to bytes so the stamper's inner loops
## never touch a Color.
func _colour_table(tiles: Dictionary, names: PackedStringArray, key: String) -> PackedByteArray:
	var table := PackedByteArray()
	for name in names:
		var colour := Color(tiles[name][key])
		table.append(colour.r8)
		table.append(colour.g8)
		table.append(colour.b8)
		table.append(255)
	return table


func _save(image: Image, file_name: String) -> bool:
	var saved := image.save_png("%s/%s" % [OUTPUT_DIR, file_name])
	if saved != OK:
		printerr("could not save ", file_name, ": ", saved)
		quit(1)
		return false
	return true


## Writes the layout a paint script will read: one character per cell, one digit
## of height per cell (in six-inch steps), every piece with its real size, the
## regions each object emitted, and the nodes that say why each place exists.
func _write_manifest(painted: Dictionary, regions: Array) -> bool:
	var names: PackedStringArray = painted["names"]
	var material_rows := []
	var height_rows := []
	for y in MAP_HEIGHT_IN_CELLS:
		var material_row := ""
		var height_row := ""
		for x in MAP_WIDTH_IN_CELLS:
			material_row += CODE_BY_MATERIAL[names[_cell(painted, "material_by_block", x, y)]]
			height_row += str(_cell(painted, "height_by_block", x, y) / HEIGHT_STEP_IN_INCHES)
		material_rows.append(material_row)
		height_rows.append(height_row)

	var written_pieces := []
	for name in PIECES:
		var piece: Dictionary = PIECES[name]
		written_pieces.append({
			"piece": name,
			"unit": piece.get("unit", "cells"),
			"width": piece["size"].x,
			"height": piece["size"].y,
			"up_in_inches": piece["up_in_inches"],
			"real": piece["real"],
			"note": piece["note"],
		})

	var written_placements := []
	for placement in PLACEMENTS:
		var origin: Vector2i = placement["origin"]
		written_placements.append({
			"piece": placement["piece"], "x": origin.x, "y": origin.y,
		})

	var written_regions := []
	for region in regions:
		var rect: Rect2i = region["rect"]
		written_regions.append({
			"object": region["object"],
			"up_in_inches": region["up_in_inches"],
			"material": region["material"],
			"block_x": rect.position.x,
			"block_y": rect.position.y,
			"block_width": rect.size.x,
			"block_height": rect.size.y,
			"note": region["note"],
		})

	var written_nodes := []
	for node in NODES:
		var cell: Vector2i = node["cell"]
		written_nodes.append({
			"x": cell.x, "y": cell.y, "kind": node["kind"], "label": node["label"],
		})

	var manifest := {
		"width": MAP_WIDTH_IN_CELLS,
		"height": MAP_HEIGHT_IN_CELLS,
		"cell_size_in_pixels": CELL_SIZE_IN_PIXELS,
		"blocks_per_cell": BLOCKS_PER_CELL,
		"pixels_per_block": PIXELS_PER_BLOCK,
		"inches_per_cell": INCHES_PER_CELL,
		"max_step_in_inches": MAX_STEP_IN_INCHES,
		"height_step_in_inches": HEIGHT_STEP_IN_INCHES,
		"image": "demo_map.png",
		"furniture_sheet": "furniture_sheet.png",
		"legend": CODE_BY_MATERIAL,
		"grid": material_rows,
		"heights": height_rows,
		"pieces": written_pieces,
		"placements": written_placements,
		"regions": written_regions,
		"nodes": written_nodes,
	}

	var file := FileAccess.open("%s/demo_map.json" % OUTPUT_DIR, FileAccess.WRITE)
	if file == null:
		printerr("could not write the map manifest: ", FileAccess.get_open_error())
		quit(1)
		return false
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	return true

## Loads whatever you have drawn. A piece counts as hand-drawn when BOTH files
## exist: "<name>.png" for the art and "<name>_height.png" beside it for where a
## pawn may stand and how high. One without the other is almost always a mistake
## and is reported rather than silently half-applied.
func _load_hand_pieces() -> Dictionary:
	var hand := {}
	var drawable := PIECES.keys()
	drawable.append(ROOM_ART_NAME)
	for name in drawable:
		var art_path := "%s/%s.png" % [PIECE_ART_DIR, name]
		var height_path := "%s/%s_height.png" % [PIECE_ART_DIR, name]
		var has_art := FileAccess.file_exists(art_path)
		var has_height := FileAccess.file_exists(height_path)
		if not has_art and not has_height:
			continue
		if has_art != has_height:
			printerr(
				"piece ", name, " has ", "art but no height map" if has_art else "a height map but no art",
				" — draw both, or neither"
			)
			continue
		var art := Image.load_from_file(art_path)
		var heights := Image.load_from_file(height_path)
		if art == null or heights == null:
			printerr("could not read the art for ", name)
			continue
		art.convert(Image.FORMAT_RGBA8)
		heights.convert(Image.FORMAT_RGBA8)
		if art.get_size() != heights.get_size():
			printerr(
				"piece ", name, ": art is ", art.get_size(), " but its height map is ",
				heights.get_size(), " — they must be the same size, one pixel per block"
			)
			continue
		hand[name] = {"art": art, "heights": heights}
	return hand


## Reads each hand-drawn piece's height map into the grids the route walker uses.
## One pixel is one block. Transparent means "not part of this piece" and leaves
## whatever is underneath; magenta means solid; every other colour is a height
## out of HEIGHT_IN_INCHES_BY_COLOUR. An unknown colour is a typo in your
## palette, so it stops the build rather than guessing.
func _apply_hand_heights(painted: Dictionary, hand: Dictionary) -> bool:
	if hand.is_empty():
		return true
	var inches_by_rgb := {}
	for hex in HEIGHT_IN_INCHES_BY_COLOUR:
		inches_by_rgb[hex.hex_to_int()] = HEIGHT_IN_INCHES_BY_COLOUR[hex]
	var solid_rgb: int = SOLID_COLOUR.hex_to_int()
	var width: int = painted["width"]
	var height: int = painted["height"]
	var height_by_block: PackedInt32Array = painted["height_by_block"]
	var solid_by_block: PackedByteArray = painted["solid_by_block"]
	var object_by_block: PackedInt32Array = painted["object_by_block"]
	var order_by_block: PackedInt32Array = painted["order_by_block"]

	var laid := []
	if hand.has(ROOM_ART_NAME):
		laid.append({"name": ROOM_ART_NAME, "origin": Vector2i.ZERO, "object_index": 0})
	for index in PLACEMENTS.size():
		var placement: Dictionary = PLACEMENTS[index]
		if hand.has(placement["piece"]):
			laid.append({
				"name": placement["piece"],
				"origin": placement["origin"] * BLOCKS_PER_CELL,
				"object_index": index + 1,
			})

	for lay in laid:
		var heights: Image = hand[lay["name"]]["heights"]
		var origin: Vector2i = lay["origin"]
		var object_index: int = lay["object_index"]
		var art_width := heights.get_width()
		var data := heights.get_data()
		for y in heights.get_height():
			var map_y := origin.y + y
			if map_y < 0 or map_y >= height:
				continue
			var row := map_y * width
			var art_row := y * art_width
			for x in art_width:
				var map_x := origin.x + x
				if map_x < 0 or map_x >= width:
					continue
				var at := (art_row + x) * 4
				if data[at + 3] < 128:
					continue
				var rgb := (data[at] << 16) | (data[at + 1] << 8) | data[at + 2]
				var here := row + map_x
				if rgb == solid_rgb:
					solid_by_block[here] = 1
				elif inches_by_rgb.has(rgb):
					height_by_block[here] = inches_by_rgb[rgb]
					solid_by_block[here] = 0
				else:
					printerr(
						lay["name"], ": height map has #%06x" % rgb, " at ", Vector2i(x, y),
						", which is not in the key. Eyedropper from ",
						PIECE_TEMPLATE_DIR, "/height_key.png"
					)
					quit(1)
					return false
				object_by_block[here] = object_index
				order_by_block[here] = 10000 + object_index
	return true


## Pastes each hand-drawn piece over the finished procedural picture, at block
## resolution and respecting its alpha. It goes on last and untouched: no bevel,
## no grain, no contact shadow is added over your work, because you drew those.
func _composite_hand_art(block_map: Image, hand: Dictionary) -> void:
	if hand.has(ROOM_ART_NAME):
		var room: Image = hand[ROOM_ART_NAME]["art"]
		block_map.blend_rect(room, Rect2i(Vector2i.ZERO, room.get_size()), Vector2i.ZERO)
	for placement in PLACEMENTS:
		if not hand.has(placement["piece"]):
			continue
		var art: Image = hand[placement["piece"]]["art"]
		block_map.blend_rect(
			art,
			Rect2i(Vector2i.ZERO, art.get_size()),
			placement["origin"] * BLOCKS_PER_CELL
		)


## Writes every piece out as the pair of PNGs you would draw by hand: the art at
## one pixel per block, and the height map beside it already filled in. Open
## either in Aseprite, paint over it, copy both into PIECE_ART_DIR, and the next
## run uses yours. Rewritten every run, so nothing you edit in here survives —
## which is exactly why you edit the copy, not this.
func _export_templates(tiles: Dictionary) -> bool:
	var absolute := ProjectSettings.globalize_path(PIECE_TEMPLATE_DIR)
	if not DirAccess.dir_exists_absolute(absolute):
		if DirAccess.make_dir_recursive_absolute(absolute) != OK:
			printerr("could not create ", PIECE_TEMPLATE_DIR)
			quit(1)
			return false

	var colour_by_height := {}
	for colour in HEIGHT_IN_INCHES_BY_COLOUR:
		colour_by_height[HEIGHT_IN_INCHES_BY_COLOUR[colour]] = colour

	for name in PIECES:
		var piece: Dictionary = PIECES[name]
		var scale := _scale_of(piece)
		var size: Vector2i = piece["size"] * scale
		if not _export_one(
			name, size, _emit(name, 1, piece["up_in_inches"], Vector2i.ZERO, piece["emits"], scale),
			tiles, colour_by_height
		):
			return false

	if not _export_one(
		ROOM_ART_NAME, Vector2i(MAP_WIDTH_IN_BLOCKS, MAP_HEIGHT_IN_BLOCKS),
		_emit(ROOM_ART_NAME, 1, THE_ROOM["up_in_inches"], Vector2i.ZERO, THE_ROOM["emits"], 1),
		tiles, colour_by_height
	):
		return false

	return _write_height_key(colour_by_height)


## Renders one drawable — a piece, or the whole room — to the PNG pair you would
## draw by hand. The art gets alpha nought wherever nothing was painted, so the
## floor shows through your silhouette; the height map gets one flat colour per
## height beside it. Both are written through raw byte arrays rather than
## set_pixel, because the room alone is three million pixels.
func _export_one(
	name: String, size: Vector2i, regions: Array, tiles: Dictionary,
	colour_by_height: Dictionary
) -> bool:
	var painted := _paint(regions, tiles, size.x, size.y)
	var stamped := _stamp(painted, tiles)
	if stamped == null:
		return false

	var object_by_block: PackedInt32Array = painted["object_by_block"]
	var height_by_block: PackedInt32Array = painted["height_by_block"]
	var solid_by_block: PackedByteArray = painted["solid_by_block"]

	var bytes_by_height := {}
	for inches in colour_by_height:
		var colour := Color(colour_by_height[inches])
		bytes_by_height[inches] = [colour.r8, colour.g8, colour.b8]
	var solid := Color(SOLID_COLOUR)

	var art_bytes := stamped.get_data()
	var height_bytes := PackedByteArray()
	height_bytes.resize(size.x * size.y * 4)
	for i in size.x * size.y:
		var at := i * 4
		if object_by_block[i] < 0:
			art_bytes[at + 3] = 0
			height_bytes[at + 3] = 0
			continue
		height_bytes[at + 3] = 255
		if solid_by_block[i] == 1:
			height_bytes[at] = solid.r8
			height_bytes[at + 1] = solid.g8
			height_bytes[at + 2] = solid.b8
			continue
		var inches := height_by_block[i]
		if not bytes_by_height.has(inches):
			printerr(name, " stands at ", inches, " inches, which has no colour in the key")
			quit(1)
			return false
		var rgb: Array = bytes_by_height[inches]
		height_bytes[at] = rgb[0]
		height_bytes[at + 1] = rgb[1]
		height_bytes[at + 2] = rgb[2]

	var art := Image.create_from_data(size.x, size.y, false, Image.FORMAT_RGBA8, art_bytes)
	var heights := Image.create_from_data(size.x, size.y, false, Image.FORMAT_RGBA8, height_bytes)
	if art.save_png("%s/%s.png" % [PIECE_TEMPLATE_DIR, name]) != OK:
		printerr("could not write the template for ", name)
		quit(1)
		return false
	if heights.save_png("%s/%s_height.png" % [PIECE_TEMPLATE_DIR, name]) != OK:
		printerr("could not write the height template for ", name)
		quit(1)
		return false
	return true


## Writes the height key three ways: a swatch strip to eyedropper from, a GIMP
## palette Aseprite can load, and a JSON so a future script can read it. Same
## numbers in all three, taken from HEIGHT_IN_INCHES_BY_COLOUR.
func _write_height_key(colour_by_height: Dictionary) -> bool:
	var inches: Array = colour_by_height.keys()
	inches.sort()
	var swatch := 32
	var strip := Image.create(swatch * (inches.size() + 1), swatch, false, Image.FORMAT_RGBA8)
	strip.fill_rect(Rect2i(0, 0, swatch, swatch), Color(SOLID_COLOUR))
	var palette := "GIMP Palette\nName: Unbound Pawn heights\n#\n"
	var solid := Color(SOLID_COLOUR)
	palette += "%3d %3d %3d\tsolid\n" % [solid.r8, solid.g8, solid.b8]
	for index in inches.size():
		var colour := Color(colour_by_height[inches[index]])
		strip.fill_rect(Rect2i(swatch * (index + 1), 0, swatch, swatch), colour)
		palette += "%3d %3d %3d\t%d inches\n" % [colour.r8, colour.g8, colour.b8, inches[index]]

	if strip.save_png("%s/height_key.png" % PIECE_TEMPLATE_DIR) != OK:
		printerr("could not write the height key strip")
		quit(1)
		return false
	var file := FileAccess.open("%s/height_key.gpl" % PIECE_TEMPLATE_DIR, FileAccess.WRITE)
	if file == null:
		printerr("could not write the height palette")
		quit(1)
		return false
	file.store_string(palette)
	file.close()

	var key := {"solid": SOLID_COLOUR, "inches_by_colour": HEIGHT_IN_INCHES_BY_COLOUR}
	var json := FileAccess.open("%s/height_key.json" % PIECE_TEMPLATE_DIR, FileAccess.WRITE)
	if json == null:
		printerr("could not write the height key")
		quit(1)
		return false
	json.store_string(JSON.stringify(key, "\t"))
	json.close()
	return true
