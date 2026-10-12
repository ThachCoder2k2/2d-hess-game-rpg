extends SceneTree

## Bakes the approved chess-piece sprites (art language "v13") to PNG.
##
## The art language, written down here so this file is readable without the
## design doc:
##   - A piece is a vertical stack of rows, one block tall each.
##   - Body rows are LATHE rows: one radius per row, mirrored about the centre.
##     A material name on a row swaps its palette for that row only — that is
##     how collars, gold bands and the double-step's red band are made. Never
##     by drawing them on top.
##   - The knight's head is not a lathe. It is hand-authored spans, one
##     [front, back] pair per row, because a horse head is asymmetric.
##   - Shading is THREE FLAT BANDS off the row's own centre. No gradient, no
##     dithering, no fourth stop.
##   - The outline is a one-block near-black ring dilated OUTSIDE the body, so
##     adding it does not shrink the silhouette. That costs one block of
##     padding on every side, which is why an exported frame is width + 2.
##   - A piece is smaller than its cell (the owner's decision of 2026-10-12).
##     One block is ONE world pixel, so a frame is drawn at scale 1, centred on
##     the cell's centre line, with its BOTTOM EDGE `base_offset_y` pixels below
##     the cell's centre (content/feel/piece_sizes.tres, the PieceSizeTable). The
##     same table gives every kind its largest box; the generator reads it and
##     refuses to write a piece that does not fit.
##   - A piece of a kind that has a row is WRITTEN on the cell-sized canvas of the
##     owner's art spec (32 x 32, base rim on row 30): the files the owner will
##     draw have that shape, so the stand-ins have it too. The pixels are the same;
##     they only gain a transparent border and show in the same screen pixels.
##
## Run:
##   HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot \
##     --headless --path . -s tools/generate_chess_sprites.gd

const OUT_DIR := "res://assets/_generated/chess"

## The kind of piece (a row of content/feel/piece_sizes.tres) each generated piece is drawn for.
## A piece with no entry has no row yet and is not checked: the promoted pawn is the mini-boss, and
## bosses get their own rows when the first one is built.
const PIECE_TYPE_BY_PIECE := {
	"pawn": "pawn",
	"black_pawn": "pawn",
	"double_step": "pawn",
	"knight": "knight",
	"bishop": "bishop",
}

## Every palette is exactly four entries: [outline, dark, mid, light].
## Index 0 is a real drawn colour (the ring), not a shading stop.
const PALETTES := {
	"IV": ["#1a1218", "#c39aa0", "#ecdcd2", "#fffaf4"],  # ivory — the pawn
	"BK": ["#04060b", "#0d1422", "#1b2537", "#39485f"],  # obsidian — the knight
	"SB": ["#04060b", "#37455a", "#55677f", "#8195ad"],  # steel band — his pedestal
	"BR": ["#1b1114", "#6a4a4a", "#93706d", "#c09a95"],  # brown — the promoted
	"RD": ["#3d0a08", "#b02a16", "#e8512a", "#ff8a5c"],  # red accent
	"NV": ["#0c0d16", "#232b45", "#3c4763", "#66748f"],  # navy — double-step
	"ST": ["#0d1018", "#48566e", "#7186a3", "#adc0d6"],  # steel collar
	"GB": ["#3a2405", "#b8860f", "#f2c63c", "#ffeaa0"],  # gold band
}
const EYE_WHITE := "#fffdf2"
const EYE_EMBER := "#ff7a3c"

## Telegraph states. Not decoration — these map one-to-one onto the combat
## states the ECS already runs, so a player can read intent with the HUD off.
const STATE_ORDER := ["idle", "alert", "windup", "commit", "hurt", "down"]

## 3x3 eye stamps. K = outline colour, W = sclera, P = pupil, E = ember,
## '.' = leave the body colour alone.
const EYE_MASKS := {
	"idle": ["KK.", ".KK", "WWP"],
	"alert": ["KKK", "...", "WPW"],
	"windup": ["...", "KKK", "WPP"],
	"commit": ["...", "KKK", "EEE"],
	"hurt": ["...", "KK.", ".KK"],
	"down": ["K.K", ".K.", "K.K"],
}

## The knight's head, row by row, ear tip down to the base of the neck. Front is
## the leftmost block of the row (he faces left), back the rightmost.
##
## THESE NUMBERS ARE TRACED, NOT DESIGNED. Every hand-authored revision of this
## silhouette read wrong. What follows is the outline of the actual chess knight
## glyph U+265E (BLACK CHESS KNIGHT) as cut by Apple Symbols: rendered at 900pt,
## cropped to its bounding box, scaled uniformly to 15 rows, reduced to one
## [leftmost, rightmost] filled pair per row, then shifted one block right so the
## neck centres over the pedestal. The ear, the brow, the eye socket, the muzzle
## taper and the throat cut are the typeface's proportions, not mine.
## Do not "improve" a single row by hand. To change the shape, retrace the glyph
## with `tools/trace_knight_glyph.py --rows 15` and paste both arrays wholesale.
##
## Why 15 rows and not the 21 the owner approved: at one pixel per block the 21-row
## knight is 26 x 32, as tall as the cell, and the owner decided a piece is smaller
## than its cell. The size table gives the knight 20 x 24, and no whole-number
## scaling gets 26 x 32 into that, so the SAME glyph was traced again on fewer rows
## (`--rows 15`, the tool the paragraph above names). The approved 21-row arrays,
## kept here so the old knight can be rebuilt by pasting them back:
##   KNIGHT_FRONT := [5, 5, 5, 5, 4, 4, 3, 3, 2, 1, 1, 1, 1, 1, 1, 2, 6, 6, 6, 6, 6]
##   KNIGHT_BACK := [10, 10, 11, 13, 14, 15, 16, 16, 17, 17, 18, 18, 18, 18, 19, 19, 19, 19, 19, 19, 19]
## (and the pedestal rows of the approved knight: 7.0, 6.4 SB, 6.0, 6.4, 7.0, 7.8, 8.8 SB, 9.6, 9.0
## on a body 24 wide.)
const KNIGHT_FRONT := [4, 4, 3, 3, 2, 2, 1, 1, 1, 1, 1, 3, 4, 4, 4]
const KNIGHT_BACK := [7, 8, 10, 11, 11, 12, 13, 13, 13, 13, 13, 14, 14, 14, 13]

## The promoted pawn's crown is a cross — also hand-authored spans.
const CROSS_SPANS := [[7, 8], [7, 8], [5, 10], [7, 8], [7, 8]]

var _pieces := {}


func _init() -> void:
	_build_pieces()
	var absolute_out_dir := ProjectSettings.globalize_path(OUT_DIR)
	var dir_error := DirAccess.make_dir_recursive_absolute(absolute_out_dir)
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		printerr("GENERATE CHESS SPRITES: cannot create %s (error %d)" % [OUT_DIR, dir_error])
		quit(1)
		return

	var size_table := ContentDb.piece_sizes()
	if size_table == null:
		printerr("GENERATE CHESS SPRITES: content/feel/piece_sizes.tres does not load; run the editor import pass first")
		quit(1)
		return

	var manifest := {}
	var pieces_that_do_not_fit := PackedStringArray()
	for piece_id: String in _pieces:
		var frames: Array[Image] = []
		for state: String in STATE_ORDER:
			frames.append(_raster(piece_id, state))

		var frame_width := frames[0].get_width()
		var frame_height := frames[0].get_height()
		var entry := {
			"frame_width": frame_width,
			"frame_height": frame_height,
			"states": STATE_ORDER,
			"sheet": "%s_states.png" % piece_id,
		}
		var box_note := "no size row yet"
		var on_cell_canvas := false
		if PIECE_TYPE_BY_PIECE.has(piece_id):
			var piece_type := StringName(PIECE_TYPE_BY_PIECE[piece_id])
			var row := size_table.row_for(piece_type)
			if row == null:
				pieces_that_do_not_fit.append("%s: the size table has no row for '%s'" % [piece_id, piece_type])
			else:
				entry["piece_type"] = String(piece_type)
				entry["box_width"] = row.body_box.x
				entry["box_height"] = row.body_box.y
				var fits := frame_width <= row.body_box.x and frame_height <= row.body_box.y
				box_note = "box %d x %d %s" % [row.body_box.x, row.body_box.y, "ok" if fits else "TOO BIG"]
				if not fits:
					pieces_that_do_not_fit.append("%s is %d x %d but a %s may be at most %d x %d" % [piece_id, frame_width, frame_height, piece_type, row.body_box.x, row.body_box.y])
				else:
					# The owner's art spec (docs/assets) draws every piece on the cell-sized canvas, so the
					# stand-ins do too: the same pixels, on the same screen pixels as a tight picture would
					# be, but the file is the shape the owner's own files will be.
					on_cell_canvas = true
					for index in frames.size():
						frames[index] = _on_cell_canvas(frames[index], size_table)
					entry["canvas_width"] = size_table.cell_size
					entry["canvas_height"] = size_table.cell_size
					entry["canvas_base_row"] = size_table.cell_canvas_base_row
		manifest[piece_id] = entry
		for index in frames.size():
			_save(frames[index], "%s/%s_%s.png" % [OUT_DIR, piece_id, STATE_ORDER[index]])
		_save(_strip(frames), "%s/%s_states.png" % [OUT_DIR, piece_id])
		print("  %-12s %2d x %-2d   %s%s" % [piece_id, frame_width, frame_height, box_note, ", on the %d x %d cell canvas" % [size_table.cell_size, size_table.cell_size] if on_cell_canvas else ""])

	if not pieces_that_do_not_fit.is_empty():
		for line in pieces_that_do_not_fit:
			printerr("GENERATE CHESS SPRITES: %s" % line)
		printerr("GENERATE CHESS SPRITES: a piece is smaller than its cell; fix the shape or the table (content/feel/piece_sizes.tres), not the check")
		quit(1)
		return

	# One block of art is ONE world pixel since the owner decided a piece is smaller than its
	# cell: a frame is placed at scale 1, its bottom edge on the piece's base line. Recorded so
	# no scene has to rediscover it.
	manifest["block_size_in_world_pixels"] = 1

	var manifest_path := "%s/manifest.json" % OUT_DIR
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		printerr("GENERATE CHESS SPRITES: cannot write %s" % manifest_path)
		quit(1)
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()

	print("GENERATE CHESS SPRITES: %d pieces x %d states -> %s" % [
		_pieces.size(), STATE_ORDER.size(), OUT_DIR,
	])
	quit(0)


## One lathe row: half-width in blocks, plus an optional palette override that
## applies to this row only.
func _lathe(radius: float, material: String = "") -> Dictionary:
	return {"radius": radius, "material": material}


func _build_pieces() -> void:
	# The pawn's profile, top to bottom: round head, pinched neck, steel collar,
	# a body that swells, then a stepped slab base. The neck pinch is what keeps
	# it from reading as a baby — the head must never be the widest part.
	var pawn_rows := [
		_lathe(2.6), _lathe(3.4), _lathe(3.8), _lathe(3.8), _lathe(3.4), _lathe(2.6),
		_lathe(1.8), _lathe(1.6), _lathe(1.6),
		_lathe(3.4, "ST"), _lathe(3.8, "ST"),
		_lathe(2.2), _lathe(2.6), _lathe(3.0), _lathe(3.6),
		_lathe(4.8), _lathe(5.6), _lathe(6.0),
	]
	_pieces["pawn"] = {
		"width": 16,
		"palette": "IV",
		"eye_row": 2,
		"rows": pawn_rows,
	}

	# The same pawn in the black pieces' obsidian: the enemy the hero's white pawn meets. Same
	# rows, same steel collar, only the palette differs, so it is the approved silhouette.
	_pieces["black_pawn"] = {
		"width": 16,
		"palette": "BK",
		"eye_row": 2,
		"rows": pawn_rows,
	}

	# The bishop: a finial, an ovoid mitre, a steel collar, a stem and the pawn's base, all turned
	# on the lathe like the pawn so it stands in the same family. Black, like the knight.
	# Placeholder shape for the owner to redraw or approve; the eyes sit on the widest mitre rows.
	_pieces["bishop"] = {
		"width": 16,
		"palette": "BK",
		"eye_row": 5,
		"rows": [
			_lathe(1.2), _lathe(1.8), _lathe(1.2),
			_lathe(2.4), _lathe(3.2), _lathe(3.8), _lathe(3.8), _lathe(3.8), _lathe(3.4), _lathe(2.8),
			_lathe(2.0),
			_lathe(3.4, "ST"), _lathe(3.8, "ST"),
			_lathe(2.2), _lathe(2.6), _lathe(3.0), _lathe(3.6),
			_lathe(4.8), _lathe(5.6), _lathe(6.0),
		],
	}

	# Same silhouette as the pawn plus one extra collar row, in navy with a red
	# band. The power has to be readable before the enemy moves, so the band is
	# a material swap on the collar rows rather than a decal.
	_pieces["double_step"] = {
		"width": 16,
		"palette": "NV",
		"eye_row": 2,
		"rows": [
			_lathe(2.6), _lathe(3.4), _lathe(3.8), _lathe(3.8), _lathe(3.4), _lathe(2.6),
			_lathe(1.8), _lathe(1.6), _lathe(1.6),
			_lathe(3.4, "RD"), _lathe(3.9, "RD"), _lathe(3.4, "RD"),
			_lathe(2.2), _lathe(2.6), _lathe(3.0), _lathe(3.6),
			_lathe(4.8), _lathe(5.6), _lathe(6.0),
		],
	}

	# The mini-boss: a pawn that reached the eighth rank. Taller, brown, crowned
	# with a red cross and belted twice in gold.
	var cross: Array[Array] = []
	for span: Array in CROSS_SPANS:
		cross.append([span[0], span[1]])
	_pieces["promoted"] = {
		"width": 16,
		"palette": "BR",
		"head": cross,
		"head_palette": "RD",
		"eye_row": 6,
		"rows": [
			_lathe(3.6), _lathe(4.0),
			_lathe(2.0), _lathe(1.8),
			_lathe(3.6, "GB"), _lathe(4.0, "GB"),
			_lathe(2.6), _lathe(2.8), _lathe(3.0), _lathe(3.2), _lathe(3.4),
			_lathe(3.8, "GB"), _lathe(4.2, "GB"),
			_lathe(5.0), _lathe(6.0), _lathe(6.4),
		],
	}

	# The first boss. Tallest piece on the board, and the only one whose head is
	# hand-authored rather than turned. He is one solid obsidian colour — no mane,
	# no trim: the shape alone has to carry him, and the only lighter blocks are
	# the two steel rings of his pedestal.
	var knight_head: Array[Array] = []
	for row in KNIGHT_FRONT.size():
		knight_head.append([KNIGHT_FRONT[row], KNIGHT_BACK[row]])
	_pieces["knight"] = {
		# 18: the traced neck is 11 blocks across and sits in x 4..14, so the pedestal has
		# to be wide enough to carry it. centre = 9. (24 for the 21-row knight.)
		"width": 18,
		"palette": "BK",
		"head": knight_head,
		# One eye, not a mirrored pair — the knight is seen in profile. All three
		# facial marks sit in the glyph's own hollows: the eye socket at rows 3-5, the
		# nostril in the muzzle tip, the mouth along the underside of the muzzle. (The marks
		# are placed by hand on the traced rows, scaled from the 21-row knight's.)
		"eye_at": Vector2i(4, 3),
		"nostril": Vector2i(1, 8),
		"mouth_row": 10,
		"mouth_span": Vector2i(3, 5),
		# The pedestal: it starts as wide as the neck it carries, pinches once
		# under a steel ring, then flares out to the widest block of the piece.
		"rows": [
			_lathe(6.0), _lathe(5.0, "SB"), _lathe(4.8), _lathe(5.2),
			_lathe(6.0), _lathe(7.0, "SB"), _lathe(7.6),
		],
	}


## Three flat bands off the row's own centre. `u` is -1 at the row's left edge
## and +1 at its right. The asymmetry (the light band sits left of centre) is
## the single fixed light direction: upper-left.
func _band(u: float) -> int:
	if u < -0.70:
		return 2
	if u < -0.20:
		return 3
	if u < 0.45:
		return 2
	return 1


func _colour(palette: String, tone: int) -> Color:
	return Color(PALETTES[palette][tone])


func _raster(piece_id: String, state: String) -> Image:
	var piece: Dictionary = _pieces[piece_id]
	var body_width: int = piece["width"]
	var centre := body_width / 2.0
	var head: Array = piece.get("head", [])
	var head_rows := head.size()
	var rows: Array = piece["rows"]
	var body_height := head_rows + rows.size()

	# One block of padding all round gives the outline ring somewhere to live.
	var width := body_width + 2
	var height := body_height + 2

	var spans: Array[Array] = []
	var occupied: Array[Array] = []
	for y in height:
		var occupancy_row: Array[bool] = []
		for x in width:
			occupancy_row.append(false)
		occupied.append(occupancy_row)

	for y in body_height:
		if y < head_rows:
			spans.append([head[y][0], head[y][1]])
		else:
			var radius: float = rows[y - head_rows]["radius"]
			spans.append([roundi(centre - radius), roundi(centre + radius) - 1])
		for x in range(spans[y][0], spans[y][1] + 1):
			if x >= 0 and x < body_width:
				occupied[y + 1][x + 1] = true

	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var base_palette: String = piece["palette"]

	for y in body_height:
		var left: int = spans[y][0]
		var right: int = spans[y][1]
		var row_centre := (left + right) / 2.0
		var row_radius := maxf(0.8, (right - left + 1) / 2.0)
		var is_head := y < head_rows
		for x in range(left, right + 1):
			if x < 0 or x >= body_width:
				continue

			var palette := base_palette
			if is_head:
				if piece.has("head_palette"):
					palette = piece["head_palette"]
			elif rows[y - head_rows]["material"] != "":
				palette = rows[y - head_rows]["material"]

			var tone := _band((x + 0.5 - (row_centre + 0.5)) / row_radius)

			# The top and bottom faces of the volume, so pieces stack in depth.
			if not _is_occupied(occupied, x + 1, y):
				tone = 3
			if not _is_occupied(occupied, x + 1, y + 2):
				tone = 1

			image.set_pixel(x + 1, y + 1, _colour(palette, tone))

	if piece.has("nostril"):
		var nostril: Vector2i = piece["nostril"]
		_stamp(image, nostril.x + 1, nostril.y + 1, _colour(base_palette, 0))
	if piece.has("mouth_row"):
		var mouth: Vector2i = piece["mouth_span"]
		var mouth_row: int = piece["mouth_row"]
		for x in range(mouth.x, mouth.y + 1):
			_stamp(image, x + 1, mouth_row + 1, _colour(base_palette, 0))

	_draw_eyes(image, piece, state, centre, base_palette)
	_dilate_outline(image, occupied, _colour(base_palette, 0))
	return image


func _is_occupied(occupied: Array[Array], x: int, y: int) -> bool:
	if y < 0 or y >= occupied.size():
		return false
	if x < 0 or x >= occupied[y].size():
		return false
	return occupied[y][x]


## Only ever paints over a block that already belongs to the body, so a facial
## mark can never punch a hole in the silhouette.
func _stamp(image: Image, x: int, y: int, colour: Color) -> void:
	if x < 0 or x >= image.get_width() or y < 0 or y >= image.get_height():
		return
	if image.get_pixel(x, y).a == 0.0:
		return
	image.set_pixel(x, y, colour)


func _draw_eyes(
	image: Image, piece: Dictionary, state: String, centre: float, palette: String
) -> void:
	var mask: Array = EYE_MASKS[state]
	var slots: Array[Vector2i] = []
	var mirrored: Array[bool] = []
	if piece.has("eye_at"):
		slots.append(piece["eye_at"])
		mirrored.append(false)
	else:
		var eye_row: int = piece["eye_row"]
		slots.append(Vector2i(roundi(centre) - 4, eye_row))
		mirrored.append(false)
		slots.append(Vector2i(roundi(centre) + 1, eye_row))
		mirrored.append(true)

	for slot in slots.size():
		for row in 3:
			var line: String = mask[row]
			for column in 3:
				var glyph := line[2 - column] if mirrored[slot] else line[column]
				if glyph == ".":
					continue
				_stamp(
					image,
					slots[slot].x + column + 1,
					slots[slot].y + row + 1,
					_eye_colour(glyph, palette)
				)


func _eye_colour(glyph: String, palette: String) -> Color:
	match glyph:
		"W":
			return Color(EYE_WHITE)
		"E":
			return Color(EYE_EMBER)
	# 'K' (lash line) and 'P' (pupil) both take the piece's own outline colour.
	return _colour(palette, 0)


## Grows the ring OUTWARD from the body, into the padding, so the silhouette
## keeps the size it was authored at.
func _dilate_outline(image: Image, occupied: Array[Array], colour: Color) -> void:
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.0:
				continue
			var touches_body := false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					if _is_occupied(occupied, x + dx, y + dy):
						touches_body = true
						break
				if touches_body:
					break
			if touches_body:
				image.set_pixel(x, y, colour)


## A tight frame placed on the art spec's cell-sized canvas (docs/assets): centred on the cell's
## centre line the way a tight picture is (PieceSizeTable.body_top_left), its bottom edge on the
## canvas's base row. Nothing is resampled; the frame is only given the transparent border.
func _on_cell_canvas(frame: Image, size_table: PieceSizeTable) -> Image:
	var canvas := Image.create_empty(size_table.cell_size, size_table.cell_size, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	var top_left := Vector2i(floori(size_table.cell_size / 2.0) - floori(frame.get_width() / 2.0), size_table.cell_canvas_base_row - frame.get_height())
	canvas.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), top_left)
	return canvas


## The six states laid out left to right in STATE_ORDER, one frame per cell.
func _strip(frames: Array[Image]) -> Image:
	var frame_width := frames[0].get_width()
	var frame_height := frames[0].get_height()
	var sheet := Image.create_empty(
		frame_width * frames.size(), frame_height, false, Image.FORMAT_RGBA8
	)
	sheet.fill(Color(0, 0, 0, 0))
	for index in frames.size():
		sheet.blit_rect(
			frames[index],
			Rect2i(0, 0, frame_width, frame_height),
			Vector2i(index * frame_width, 0)
		)
	return sheet


func _save(image: Image, path: String) -> void:
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		printerr("GENERATE CHESS SPRITES: cannot write %s (error %d)" % [path, error])
