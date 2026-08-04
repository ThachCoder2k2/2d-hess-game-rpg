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
##   - The foot of a piece sits on the CELL CENTRE, not on the cell's bottom
##     edge. `anchor_row` in the manifest is the row (counted from the top of
##     the frame) that must land on the centre of the grid cell.
##
## Run:
##   HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot \
##     --headless --path . -s tools/generate_chess_sprites.gd

const OUT_DIR := "res://assets/sprites/generated/chess"

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
## cropped to its bounding box, scaled uniformly to 21 rows, reduced to one
## [leftmost, rightmost] filled pair per row, then shifted one block right so the
## neck centres over the pedestal. The ear, the brow, the eye socket, the muzzle
## taper and the throat cut are the typeface's proportions, not mine.
## Do not "improve" a single row by hand. To change the shape, retrace the glyph
## with `tools/trace_knight_glyph.py` and paste both arrays wholesale.
const KNIGHT_FRONT := [5, 5, 5, 5, 4, 4, 3, 3, 2, 1, 1, 1, 1, 1, 1, 2, 6, 6, 6, 6, 6]
const KNIGHT_BACK := [10, 10, 11, 13, 14, 15, 16, 16, 17, 17, 18, 18, 18, 18, 19, 19, 19, 19, 19, 19, 19]

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

	var manifest := {}
	for piece_id: String in _pieces:
		var frames: Array[Image] = []
		for state: String in STATE_ORDER:
			var frame := _raster(piece_id, state)
			frames.append(frame)
			_save(frame, "%s/%s_%s.png" % [OUT_DIR, piece_id, state])
		_save(_strip(frames), "%s/%s_states.png" % [OUT_DIR, piece_id])

		var frame_width := frames[0].get_width()
		var frame_height := frames[0].get_height()
		manifest[piece_id] = {
			"frame_width": frame_width,
			"frame_height": frame_height,
			# Row (from the frame's top) that must sit on the grid cell's centre.
			"anchor_row": frame_height - 3,
			"states": STATE_ORDER,
			"sheet": "%s_states.png" % piece_id,
		}
		print("  %-12s %2d x %-2d   anchor row %d" % [
			piece_id, frame_width, frame_height, frame_height - 3,
		])

	# One block of art is two world pixels, so a sprite drawn at scale 2 lines
	# up with the 32px grid. Recorded here so no scene has to rediscover it.
	manifest["block_size_in_world_pixels"] = 2

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
	_pieces["pawn"] = {
		"width": 16,
		"palette": "IV",
		"eye_row": 2,
		"rows": [
			_lathe(2.6), _lathe(3.4), _lathe(3.8), _lathe(3.8), _lathe(3.4), _lathe(2.6),
			_lathe(1.8), _lathe(1.6), _lathe(1.6),
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
		# 24, not 22: the traced neck is 14 blocks across and sits in x 6..19, so
		# the pedestal has to be wide enough to carry it. centre = 12.
		"width": 24,
		"palette": "BK",
		"head": knight_head,
		# One eye, not a mirrored pair — the knight is seen in profile. All three
		# facial marks sit in the glyph's own hollows: the eye socket at rows 4-6,
		# the nostril in the muzzle tip, the mouth in the gap at row 13.
		"eye_at": Vector2i(5, 4),
		"nostril": Vector2i(2, 12),
		"mouth_row": 13,
		"mouth_span": Vector2i(6, 8),
		# The pedestal: it starts as wide as the neck it carries, pinches once
		# under a steel ring, then flares out to the widest block of any piece.
		"rows": [
			_lathe(7.0), _lathe(6.4, "SB"), _lathe(6.0), _lathe(6.4),
			_lathe(7.0), _lathe(7.8), _lathe(8.8, "SB"), _lathe(9.6), _lathe(9.0),
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
