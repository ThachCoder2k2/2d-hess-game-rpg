extends SceneTree
## Bakes the Under-the-Table floor materials as pixel tiles, one PNG per material
## plus a contact sheet and a manifest.
##
## Same art language as tools/generate_chess_sprites.gd, so pieces and ground read
## as one set: 1 art block = 2 world pixels, flat colour only, no gradient, no
## dither, no noise. A tile is 16x16 blocks (32 world px = one board cell).
##
## The floor is deliberately coarse. Each tile is a 4x4 grid of PATCHES, one flat
## colour per patch — the owner's rule, verbatim: "one grid is one color or may be
## a 2*2 4*4 or 8*8 not this much bro". A material is therefore four strings of
## four characters, each character an index into that material's four-colour
## palette. Nothing else draws.
##
## Every tile carries a one-block rim: dark down the bottom and right edges, light
## along the top and left when the material stands proud of its neighbours. That
## is the same fixed upper-left light the pieces use, and it is what makes a field
## of floor read as discrete squares instead of one carved blob.
##
## Run:
##     HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot \
##         --headless --path . -s tools/generate_kingdom_tiles.gd

const OUTPUT_DIR := "res://assets/sprites/generated/tiles"
const BLOCK_SIZE_IN_WORLD_PIXELS := 2
const TILE_SIZE_IN_BLOCKS := 16
const PATCH_SIZE_IN_BLOCKS := 4
const PATCHES_PER_SIDE := TILE_SIZE_IN_BLOCKS / PATCH_SIZE_IN_BLOCKS

## Every material of the demo world, in the order the player meets them: the
## carpet you wake on, the open floor, the ruins, the climb, and the kingdom.
##
## palette — four flat colours, [ink, dark, mid, light]. Index 0 is the rim.
## patch   — 4 rows of 4 palette indices; one flat colour per 8x8 world pixels.
## raised  — true when the material sits above its neighbours and takes a lit
##           top-left edge as well as the shadowed bottom-right one.
## solid   — true when the material blocks movement.
const MATERIALS := {
	"deep_pile": {
		"palette": ["#1a0f12", "#40202a", "#552b33", "#6b3a41"],
		"patch": ["1221", "2112", "1221", "2112"],
		"raised": true,
		"solid": false,
		"note": "thick carpet; where the pawn wakes up, slow and ash-dark",
	},
	"deep_pile_worn": {
		"palette": ["#1a0f12", "#55333a", "#6d4750", "#855b62"],
		"patch": ["1211", "2122", "1121", "2212"],
		"raised": false,
		"solid": false,
		"note": "carpet trodden flat — the readable path through the pile",
	},
	"varnish": {
		"palette": ["#241206", "#6b3f1c", "#855126", "#9c6432"],
		"patch": ["2222", "1111", "2222", "3333"],
		"raised": false,
		"solid": false,
		"note": "polished floorboard; the open middle where sightlines are long",
	},
	"chalk_path": {
		"palette": ["#2a2620", "#8f8a78", "#b8b2a0", "#d8d3c2"],
		"patch": ["1221", "1331", "1331", "1221"],
		"raised": false,
		"solid": false,
		"note": "a child's chalk line — the map's only signage, points onward",
	},
	"box_ruins": {
		"palette": ["#2b1c0d", "#7a5a2e", "#96723d", "#b08a4e"],
		"patch": ["2112", "1221", "2113", "1223"],
		"raised": true,
		"solid": false,
		"note": "the spilled chess box, torn cardboard walls to fight between",
	},
	"sag": {
		"palette": ["#12141f", "#2c3350", "#3a4364", "#4c577c"],
		"patch": ["1111", "1221", "1221", "1111"],
		"raised": false,
		"solid": false,
		"note": "the sagging fabric bowl; every step funnels toward the middle",
	},
	"crayon_ramp": {
		"palette": ["#2a1400", "#a54a10", "#d4691a", "#f08a34"],
		"patch": ["2323", "2323", "1212", "1212"],
		"raised": true,
		"solid": false,
		"note": "a spill of crayons laid like logs — the climb out of the floor",
	},
	"ruler_bridge": {
		"palette": ["#33270a", "#a8871a", "#cfa72a", "#ecc84e"],
		"patch": ["1111", "2222", "2323", "1111"],
		"raised": true,
		"solid": false,
		"note": "the Ruler: one plank wide, no cover, the crossing you dread",
	},
	"crossbar": {
		"palette": ["#170c05", "#402512", "#55321a", "#6b4324"],
		"patch": ["1122", "1122", "2211", "2211"],
		"raised": true,
		"solid": false,
		"note": "the table's crossbar — high road, drops away on both sides",
	},
	"lamplight": {
		"palette": ["#2c2210", "#8a7333", "#a89049", "#c9b06a"],
		"patch": ["2332", "3333", "3333", "2332"],
		"raised": false,
		"solid": false,
		"note": "the pool of lamplight the kingdom sits in; safety you can see",
	},
	"board_light": {
		"palette": ["#2a2418", "#a89a76", "#c6b78f", "#e0d3ac"],
		"patch": ["2222", "2222", "2222", "2222"],
		"raised": false,
		"solid": false,
		"note": "the board's pale square — inside here, chess rules bind",
	},
	"board_dark": {
		"palette": ["#14100a", "#3c3222", "#4d412c", "#5f5138"],
		"patch": ["2222", "2222", "2222", "2222"],
		"raised": false,
		"solid": false,
		"note": "the board's dark square, the other half of the boss floor",
	},
	"gate": {
		"palette": ["#0a0f1a", "#22406b", "#2f5a94", "#4a7fc4"],
		"patch": ["1331", "1331", "1331", "1331"],
		"raised": true,
		"solid": false,
		"note": "the seam the Knight defends; crossing it starts the fight",
	},
	"tablecloth": {
		"palette": ["#1a1520", "#43385a", "#55486f", "#6a5a88"],
		"patch": ["1212", "1212", "1212", "1212"],
		"raised": true,
		"solid": true,
		"note": "hanging cloth — the wall that closes the world's west side",
	},
	"void": {
		"palette": ["#05060a", "#0a0c12", "#10131c", "#161a26"],
		"patch": ["1121", "1211", "2111", "1112"],
		"raised": false,
		"solid": true,
		"note": "the dark under the table; the edge of everything",
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
			"solid": material["solid"],
			"raised": material["raised"],
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
		"%d tiles at %dx%d px, %d patches per side" % [
			ids.size(), tile_pixels, tile_pixels, PATCHES_PER_SIDE
		]
	)
	quit()


## Paints one material: flat patches first, then the rim that squares it off.
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

	var ink := Color(palette[0])
	var lit := Color(palette[3])
	# Shadow down the bottom and right: the fixed upper-left light the pieces use.
	_fill_blocks(image, Vector2i(0, TILE_SIZE_IN_BLOCKS - 1), Vector2i(TILE_SIZE_IN_BLOCKS, 1), ink)
	_fill_blocks(image, Vector2i(TILE_SIZE_IN_BLOCKS - 1, 0), Vector2i(1, TILE_SIZE_IN_BLOCKS), ink)
	if material["raised"]:
		_fill_blocks(image, Vector2i.ZERO, Vector2i(TILE_SIZE_IN_BLOCKS, 1), lit)
		_fill_blocks(image, Vector2i.ZERO, Vector2i(1, TILE_SIZE_IN_BLOCKS), lit)
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
