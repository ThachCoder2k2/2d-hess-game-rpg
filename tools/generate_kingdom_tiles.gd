extends SceneTree
## Bakes the room's materials as pixel tiles, one PNG per material plus a contact
## sheet and a manifest.
##
## Same art language as tools/generate_chess_sprites.gd, so pieces and ground
## read as one set: 1 art block = 2 world pixels, flat colour only, no gradient,
## no dither, no noise. A tile is 16x16 blocks (32 world px = one board cell).
##
## THE RIM MOVED. Tiles used to carry their own one-block rim on every side,
## which is why a floor of them read as a tiled bathroom instead of a room: a
## tabletop thirty-eight cells wide came out as eight hundred separate bricks.
## A tile is now painted FLAT, and the map stamper draws one rim around each
## BODY — the wall, the rug, the table — where it meets a different body. An
## object is outlined once, at its silhouette, the way a real thing is.
##
## Each material is a 4x4 grid of PATCHES, one flat colour per patch — the
## owner's rule, verbatim: "one grid is one color or may be a 2*2 4*4 or 8*8 not
## this much bro". Big surfaces are deliberately near-flat; a floor gets its
## grain from a 2px SEAM line instead, which is how floorboards actually read
## from above: long joints every ten inches, not a checker every two.
##
## Run:
##     HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot \
##         --headless --path . -s tools/generate_kingdom_tiles.gd

const OUTPUT_DIR := "res://assets/sprites/generated/tiles"
const BLOCK_SIZE_IN_WORLD_PIXELS := 2
const TILE_SIZE_IN_BLOCKS := 16
const PATCH_SIZE_IN_BLOCKS := 4
const PATCHES_PER_SIDE := TILE_SIZE_IN_BLOCKS / PATCH_SIZE_IN_BLOCKS

## Every material in the room. Keys:
## palette — four flat colours, [ink, dark, mid, light]. Index 0 is the ink the
##           stamper shades a body's edge with; index 3 is the light it lifts it
##           with. The fixed upper-left light the chess pieces use.
## patch   — 4 rows of 4 palette indices; one flat colour per 8x8 world pixels.
## seam    — optional "top" or "left": a single ink block along that edge. This
##           is how floorboards get their joint without the tile turning into a
##           pattern; it lands on the cell boundary and reads as one long line.
## body    — which silhouette this material belongs to. The stamper outlines
##           where the body changes, never inside one, so a wall is one wall and
##           a floor is one floor. Materials that share a body share an outline.
## raised  — true when the body stands above the floor and takes a lit top-left
##           edge as well as its shadowed bottom-right one.
## grain   — how many rows apart this wood's grain lines run, drawn by the map
##           stamper so they carry across cells into one long line. 0 for
##           anything that is not sawn wood. A big flat surface with no grain
##           reads as a coloured rectangle the moment you look at it closely.
## weave   — how many blocks apart this cloth's weave runs, hatched on the
##           diagonal by the map stamper. 0 for anything that is not woven or
##           papered. Wood gets grain, cloth gets weave; a surface with neither
##           is a flat colour, and a flat colour is what a rectangle looks like.
## solid   — true when the material blocks movement.
const MATERIALS := {
	# --- the room's shell -----------------------------------------------------
	# The north wall is drawn as a FACE, not as a band of floor seen from above:
	# a rail along its top, papered plaster, its skirting board, and the shadow
	# it drops on the boards. That is the top-down RPG convention every interior
	# pack uses, and it is what tells you in one glance which way is "up" in the
	# room. The other three sides are behind or beside the camera, so they are
	# one dark edge and nothing more.
	"wall_rail": {
		"palette": ["#100c14", "#3b2c1e", "#4a3524", "#5e452e"],
		"patch": ["2222", "2222", "2222", "2222"],
		"grain": 2,
		"body": "wall",
		"raised": true,
		"solid": true,
		"note": "the picture rail capping the wall — the room's ceiling line",
	},
	"wallpaper": {
		"palette": ["#1c2028", "#7e8ca3", "#96a5bd", "#adbad0"],
		"patch": ["2222", "2222", "2222", "2222"],
		"weave": 9,
		"body": "wall",
		"raised": false,
		"solid": true,
		"note": "the papered wall of a child's room — cool, so the warm floor reads against it",
	},
	"wallpaper_stripe": {
		"palette": ["#1c2028", "#7e8ca3", "#96a5bd", "#adbad0"],
		"patch": ["2222", "2222", "2222", "2222"],
		"seam": "left",
		"weave": 9,
		"body": "wall",
		"raised": false,
		"solid": true,
		"note": "the same paper with one of its stripes on it — every fourth column, the way a roll repeats",
	},
	"wallpaper_side": {
		"palette": ["#161920", "#5f6b7e", "#727f94", "#8593a8"],
		"patch": ["2222", "2222", "2222", "2222"],
		"weave": 9,
		"body": "wall_side",
		"raised": false,
		"solid": true,
		"note": "the same paper on a wall that runs away from you — darker, because it stands at right angles to the window, and that difference is the only thing that draws the corner of a room",
	},
	"skirting": {
		"palette": ["#20242e", "#b3a992", "#d2c7ac", "#e6dcc2"],
		"patch": ["3333", "2222", "2222", "1111"],
		"body": "wall",
		"raised": true,
		"solid": true,
		"note": "the skirting board at the wall's foot — one pale line, and the floor reads as indoors",
	},
	"wall_shadow": {
		"palette": ["#1a1108", "#63421f", "#75502a", "#8a6136"],
		"patch": ["2222", "2222", "2222", "2222"],
		"body": "floor",
		"raised": false,
		"solid": false,
		"note": "the boards right under the wall, in its shadow — what stops the floor from looking pasted on",
	},
	"window_frame": {
		"palette": ["#140d06", "#6b4a2c", "#805a36", "#9a7044"],
		"patch": ["2222", "2222", "2222", "2222"],
		"body": "window",
		"raised": true,
		"solid": true,
		"note": "the window's painted timber frame",
	},
	"window_glass": {
		"palette": ["#140d06", "#7fa8c4", "#a3c8dd", "#d2e8f4"],
		"patch": ["2222", "2222", "2222", "2222"],
		"body": "window",
		"raised": false,
		"solid": true,
		"note": "the pane, with the glazing bar between lights — the room's one source of daylight",
	},
	"door_frame": {
		"palette": ["#140d06", "#6b4a2c", "#805a36", "#9a7044"],
		"patch": ["2222", "2222", "2222", "2222"],
		"body": "door",
		"raised": true,
		"solid": true,
		"note": "the door's casing, standing proud of the paper",
	},
	"door_leaf": {
		"palette": ["#160a08", "#8a4436", "#a1543f", "#b9694e"],
		"patch": ["2222", "2222", "2222", "2222"],
		"grain": 4,
		"body": "door",
		"raised": false,
		"solid": true,
		"note": "the door itself, shut — the way out of the room and out of the demo",
	},
	"room_edge": {
		"palette": ["#000000", "#0d0b11", "#14121a", "#1c1922"],
		"patch": ["2222", "2222", "2222", "2222"],
		"body": "edge",
		"raised": false,
		"solid": true,
		"note": "the dark past the room's other three sides — they are beside and behind the camera, so they are not drawn",
	},
	"floor_plank": {
		"palette": ["#2b2118", "#66584a", "#8c7c6b", "#a3947f"],
		"patch": ["2222", "2222", "2222", "2222"],
		"grain": 4,
		"body": "floor",
		"raised": false,
		"solid": false,
		"note": "bare floorboard — warm mid brown, the ground of the whole room",
	},
	"daylight": {
		"palette": ["#2b2118", "#a08b5e", "#d4bc86", "#ead39c"],
		"patch": ["2222", "2222", "2222", "2222"],
		"grain": 4,
		"body": "floor",
		"raised": false,
		"solid": false,
		"note": "the same boards where the window lands on them — brighter, not a different floor",
	},
	# --- what the room is furnished with -------------------------------------
	"wood_face": {
		"palette": ["#140d06", "#5c3d20", "#6e4a28", "#845a33"],
		"patch": ["2222", "2222", "2222", "2222"],
		"grain": 3,
		"body": "wood_face",
		"raised": true,
		"solid": true,
		"note": "the vertical front of a wooden thing — a headboard, a desk's apron, a chair's back. Seen face on, so it is a wall to a pawn",
	},
	"pillow": {
		"palette": ["#241f1a", "#c9bda8", "#e2d8c4", "#f2ece0"],
		"patch": ["2222", "2222", "2222", "2222"],
		"weave": 8,
		"body": "bed",
		"raised": true,
		"solid": false,
		"note": "a pillow — at a pawn's scale, a white hill at the head of the bed",
	},
	"paint_top": {
		"palette": ["#0e1d22", "#39646b", "#487a80", "#5b9098"],
		"patch": ["2222", "2222", "2222", "2222"],
		"body": "chest",
		"raised": true,
		"solid": false,
		"note": "the painted lid of a toy chest — the one thing in the room a child chose the colour of",
	},
	"paint_face": {
		"palette": ["#0e1d22", "#25464c", "#2e565c", "#3b686e"],
		"patch": ["2222", "2222", "2222", "2222"],
		"body": "chest_face",
		"raised": true,
		"solid": true,
		"note": "the toy chest seen face on — its front, which a pawn has to walk around",
	},
	"shelf_face": {
		"palette": ["#150c06", "#4e3218", "#5e3d1e", "#734d28"],
		"patch": ["2222", "2222", "2222", "2222"],
		"grain": 3,
		"body": "shelf_face",
		"raised": true,
		"solid": true,
		"note": "the front of a tall thing — a wardrobe, a bookcase; too high to climb, so it is simply a cliff",
	},
	"deep_pile": {
		"palette": ["#1a0f12", "#40202a", "#552b33", "#6b3a41"],
		"patch": ["2222", "2222", "2222", "2222"],
		"weave": 6,
		"body": "rug",
		"raised": true,
		"solid": false,
		"note": "thick rug pile — where the pawn wakes, slow and ash-dark",
	},
	"deep_pile_worn": {
		"palette": ["#1a0f12", "#55333a", "#6d4750", "#855b62"],
		"patch": ["2222", "2222", "2222", "2222"],
		"weave": 6,
		"body": "rug",
		"raised": false,
		"solid": false,
		"note": "pile trodden flat — the readable path across the rug",
	},
	"furniture_shade": {
		"palette": ["#150d08", "#6b5335", "#7d6140", "#8f704b"],
		"patch": ["2222", "2222", "2222", "2222"],
		"body": "floor",
		"raised": false,
		"solid": false,
		"note": "floor in a piece of furniture's shadow — every shade falls south-east, away from the window",
	},
	"chalk_path": {
		"palette": ["#2a2620", "#8f8a78", "#b8b2a0", "#d8d3c2"],
		"patch": ["1221", "1331", "1331", "1221"],
		"body": "floor",
		"raised": false,
		"solid": false,
		"note": "a child's chalk line — the map's only signage, points onward",
	},
	"furniture_leg": {
		"palette": ["#0d0803", "#33200e", "#452c14", "#5a3a1c"],
		"grain": 2,
		"patch": ["2222", "2222", "2222", "2222"],
		"body": "leg",
		"raised": true,
		"solid": true,
		"note": "a turned post seen from above — a bed, chair or table leg you cannot pass",
	},
	"crossbar": {
		"palette": ["#170c05", "#4a2c14", "#5e3a1c", "#734a26"],
		"patch": ["2222", "2222", "2222", "2222"],
		"grain": 3,
		"body": "crossbar",
		"raised": true,
		"solid": false,
		"note": "a stretcher between two legs — six inches up, flat enough to walk",
	},
	"chair_seat": {
		"palette": ["#241408", "#8a5624", "#a0682c", "#b87d38"],
		"patch": ["2222", "2222", "2222", "2222"],
		"grain": 3,
		"body": "seat",
		"raised": true,
		"solid": false,
		"note": "a seat eighteen inches up — the middle rung of any climb",
	},
	"table_top": {
		"palette": ["#2b1a09", "#a8712e", "#c08436", "#d69a48"],
		"patch": ["2222", "2222", "2222", "2222"],
		"grain": 4,
		"body": "table",
		"raised": true,
		"solid": false,
		"note": "a tabletop, high and polished — where a child sets things out",
	},
	"mattress": {
		"palette": ["#20202b", "#8f92a8", "#a8abc0", "#c2c5d6"],
		"patch": ["2222", "2222", "2222", "2222"],
		"weave": 7,
		"body": "bed",
		"raised": true,
		"solid": false,
		"note": "a bed's made-up top — the biggest flat thing in a child's room",
	},
	"blanket": {
		"palette": ["#1c1226", "#5e3f7a", "#71508f", "#8a66a8"],
		"patch": ["2222", "2222", "2222", "2222"],
		"weave": 5,
		"body": "bed",
		"raised": true,
		"solid": false,
		"note": "the blanket thrown over the bed's foot, one fold proud of the rest",
	},
	"shelf_top": {
		"palette": ["#150c06", "#7a5228", "#8f6230", "#a5763c"],
		"patch": ["2222", "2222", "2222", "2222"],
		"grain": 4,
		"body": "shelf_top",
		"raised": true,
		"solid": false,
		"note": "the top of a tall thing, seen from above — out of reach, so it is scenery",
	},
	"mattress_seam": {
		"palette": ["#20202b", "#767a8f", "#8a8ea3", "#a0a4b8"],
		"patch": ["2222", "2222", "2222", "2222"],
		"weave": 7,
		"body": "bed",
		"raised": false,
		"solid": false,
		"note": "the quilting and the piped edge of a mattress — at a pawn's scale, ridges you walk over",
	},
	"blanket_fold": {
		"palette": ["#1c1226", "#4a3161", "#5a3d75", "#6b4a89"],
		"patch": ["2222", "2222", "2222", "2222"],
		"weave": 5,
		"body": "bed",
		"raised": false,
		"solid": false,
		"note": "a crease in the blanket, and its turned-over top edge",
	},
	"metal": {
		"palette": ["#1a1508", "#846f2c", "#9c8438", "#b89e4e"],
		"patch": ["2222", "2222", "2222", "2222"],
		"body": "metal",
		"raised": true,
		"solid": false,
		"note": "brass — a handle, a hinge, a latch, a lamp's stem",
	},
	"page": {
		"palette": ["#2a2820", "#d2cdbb", "#e8e3d2", "#f6f2e6"],
		"patch": ["2222", "2222", "2222", "2222"],
		"body": "page",
		"raised": true,
		"solid": false,
		"note": "paper left on a desk — to a pawn, a white field with a sharp edge",
	},
	"rug_motif": {
		"palette": ["#1a0f12", "#7d5a3a", "#946d47", "#ad8155"],
		"patch": ["2222", "2222", "2222", "2222"],
		"weave": 6,
		"body": "rug",
		"raised": false,
		"solid": false,
		"note": "the pattern woven into the rug — its border stripes and the medallion in its middle",
	},
	"gate_face": {
		"palette": ["#050a12", "#152840", "#1d3757", "#274a72"],
		"patch": ["2222", "2222", "2222", "2222"],
		"body": "gate_face",
		"raised": true,
		"solid": false,
		"note": "the shaded side of a blue thing — a block's front, a book's board seen edge on",
	},
	"crayon_face": {
		"palette": ["#1a0c00", "#6b2f0a", "#84400f", "#9c5218"],
		"patch": ["2222", "2222", "2222", "2222"],
		"body": "crayon_face",
		"raised": true,
		"solid": false,
		"note": "and the shaded side of an orange one",
	},
	"shelf_ledge": {
		"palette": ["#150c06", "#5c3c1e", "#6e4a26", "#845c30"],
		"patch": ["2222", "2222", "2222", "2222"],
		"grain": 3,
		"body": "shelf_ledge",
		"raised": true,
		"solid": false,
		"note": "the flat of a shelf, seen face on — a ledge you stand on, which is what makes a bookcase a staircase instead of a wall",
	},
	"box_ruins": {
		"palette": ["#2b1c0d", "#7a5a2e", "#96723d", "#b08a4e"],
		"patch": ["2222", "2222", "2222", "2222"],
		"grain": 3,
		"weave": 4,
		"body": "box",
		"raised": true,
		"solid": false,
		"note": "torn cardboard — the spilled box, walls to fight between",
	},
	"crayon_ramp": {
		"palette": ["#2a1400", "#a54a10", "#d4691a", "#f08a34"],
		"patch": ["2323", "2323", "1212", "1212"],
		"body": "crayons",
		"raised": true,
		"solid": false,
		"note": "a spill of crayons laid like logs — a climb off the floor",
	},
	"ruler_bridge": {
		"palette": ["#33270a", "#a8871a", "#cfa72a", "#ecc84e"],
		"patch": ["2222", "2222", "2222", "2222"],
		"body": "ruler",
		"raised": true,
		"solid": false,
		"note": "the Ruler: one cell wide, no cover, the crossing you dread",
	},
	"sag": {
		"palette": ["#12141f", "#2c3350", "#3a4364", "#4c577c"],
		"patch": ["2222", "2222", "2222", "2222"],
		"weave": 5,
		"body": "cloth",
		"raised": false,
		"solid": false,
		"note": "sagging fabric — every step funnels toward the middle",
	},
	"tablecloth": {
		"palette": ["#1a1520", "#43385a", "#55486f", "#6a5a88"],
		"patch": ["2222", "2222", "2222", "2222"],
		"weave": 5,
		"body": "cloth_wall",
		"raised": true,
		"solid": true,
		"note": "hanging cloth — a wall you cannot pass and cannot see through",
	},
	"lamplight": {
		"palette": ["#2c2210", "#b89a48", "#d4b45c", "#ecd07e"],
		"patch": ["2222", "2222", "2222", "2222"],
		"body": "table",
		"raised": true,
		"solid": false,
		"note": "the lamp's pool on the tabletop; the kingdom sits in it",
	},
	"board_light": {
		"palette": ["#2a2418", "#a89a76", "#c6b78f", "#e0d3ac"],
		"patch": ["2222", "2222", "2222", "2222"],
		"body": "board",
		"raised": false,
		"solid": false,
		"note": "the board's pale square — inside here, chess rules bind",
	},
	"board_dark": {
		"palette": ["#14100a", "#3c3222", "#4d412c", "#5f5138"],
		"patch": ["2222", "2222", "2222", "2222"],
		"body": "board",
		"raised": false,
		"solid": false,
		"note": "the board's dark square, the other half of the boss floor",
	},
	"gate": {
		"palette": ["#0a0f1a", "#22406b", "#2f5a94", "#4a7fc4"],
		"patch": ["1331", "1331", "1331", "1331"],
		"body": "gate",
		"raised": true,
		"solid": false,
		"note": "the seam the Knight defends; crossing it starts the fight",
	},
	"void": {
		"palette": ["#05060a", "#0a0c12", "#10131c", "#161a26"],
		"patch": ["2222", "2222", "2222", "2222"],
		"body": "void",
		"raised": false,
		"solid": true,
		"note": "nothing at all — the room covers every cell, so this only shows where an object left a hole",
	},
}


func _init() -> void:
	var absolute_output_dir := ProjectSettings.globalize_path(OUTPUT_DIR)
	if not DirAccess.dir_exists_absolute(absolute_output_dir):
		var made := DirAccess.make_dir_recursive_absolute(absolute_output_dir)
		if made != OK:
			printerr("could not create ", OUTPUT_DIR, ": ", made)
			quit(1)
			return

	var manifest := {
		"tile_size_in_pixels": TILE_SIZE_IN_BLOCKS * BLOCK_SIZE_IN_WORLD_PIXELS,
		"block_size_in_world_pixels": BLOCK_SIZE_IN_WORLD_PIXELS,
		"patch_size_in_blocks": PATCH_SIZE_IN_BLOCKS,
		"tiles": {},
	}
	var ids: Array = MATERIALS.keys()
	var tile_pixels := TILE_SIZE_IN_BLOCKS * BLOCK_SIZE_IN_WORLD_PIXELS
	var sheet := Image.create(
		ids.size() * tile_pixels, tile_pixels, false, Image.FORMAT_RGBA8
	)

	for index in ids.size():
		var id: String = ids[index]
		var material: Dictionary = MATERIALS[id]
		var tile := _raster(material)
		if not _save(tile, "%s/%s.png" % [OUTPUT_DIR, id]):
			return
		sheet.blit_rect(
			tile,
			Rect2i(Vector2i.ZERO, tile.get_size()),
			Vector2i(index * tile_pixels, 0)
		)
		manifest["tiles"][id] = {
			"file": "%s.png" % id,
			"body": material["body"],
			"grain": material.get("grain", 0),
			"weave": material.get("weave", 0),
			"solid": material["solid"],
			"raised": material["raised"],
			"ink": material["palette"][0],
			"mid": material["palette"][2],
			"dark": material["palette"][1],
			"lit": material["palette"][3],
			"note": material["note"],
		}

	if not _save(sheet, "%s/tiles_sheet.png" % OUTPUT_DIR):
		return
	manifest["sheet"] = "tiles_sheet.png"

	var manifest_file := FileAccess.open("%s/manifest.json" % OUTPUT_DIR, FileAccess.WRITE)
	if manifest_file == null:
		printerr("could not write the tile manifest: ", FileAccess.get_open_error())
		quit(1)
		return
	manifest_file.store_string(JSON.stringify(manifest, "\t"))
	manifest_file.close()

	print(
		"%d tiles at %dx%d px, %d patches per side, rims left to the stamper" % [
			ids.size(), tile_pixels, tile_pixels, PATCHES_PER_SIDE
		]
	)
	quit()


## Paints one material: flat patches, then its seam line if it has one. No rim —
## the map stamper draws that once per body, not once per cell.
func _raster(material: Dictionary) -> Image:
	var side := TILE_SIZE_IN_BLOCKS * BLOCK_SIZE_IN_WORLD_PIXELS
	var image := Image.create(side, side, false, Image.FORMAT_RGBA8)
	var palette: Array = material["palette"]
	var patch: Array = material["patch"]

	for patch_y in PATCHES_PER_SIDE:
		var row: String = patch[patch_y]
		for patch_x in PATCHES_PER_SIDE:
			var stop := row.substr(patch_x, 1).to_int()
			var colour := Color(palette[stop])
			var origin := Vector2i(patch_x, patch_y) * PATCH_SIZE_IN_BLOCKS
			_fill_blocks(image, origin, Vector2i.ONE * PATCH_SIZE_IN_BLOCKS, colour)

	var seam: String = material.get("seam", "")
	if seam == "top":
		_fill_blocks(image, Vector2i.ZERO, Vector2i(TILE_SIZE_IN_BLOCKS, 1), Color(palette[1]))
	elif seam == "left":
		_fill_blocks(image, Vector2i.ZERO, Vector2i(1, TILE_SIZE_IN_BLOCKS), Color(palette[1]))
	return image


## Fills a rectangle measured in art blocks, not pixels — nothing here ever
## addresses a single pixel, which is what keeps the output free of stray dots.
func _fill_blocks(image: Image, origin: Vector2i, size: Vector2i, colour: Color) -> void:
	image.fill_rect(
		Rect2i(
			origin * BLOCK_SIZE_IN_WORLD_PIXELS,
			size * BLOCK_SIZE_IN_WORLD_PIXELS
		),
		colour
	)


func _save(image: Image, path: String) -> bool:
	var result := image.save_png(path)
	if result != OK:
		printerr("could not save ", path, ": ", result)
		quit(1)
		return false
	return true
