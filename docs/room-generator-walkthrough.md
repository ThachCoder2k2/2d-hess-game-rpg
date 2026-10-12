# The room generator, read head to toe

`docs/room-generator.md` is the **map**: where things live, what to edit when.
This is the **walk**: the same code in the order the machine runs it, with the
real lines quoted, following one block of the picture from the sentence that
describes it to the two pixels it becomes.

Read this once with the file open beside it. After that the map is enough.

---

## Part 0 — the block we are following

Everything below traces one concrete block, so that no step is abstract.

**The block:** `(1880, 1448)`. It is on the front of the toy chest, low down on
the right-hand side, below the bookcase. In cells that is `(117, 90)`.

By the end of the walk it is the colour `#2e565c` at world pixels
`(3760, 2896)`, `(3761, 2896)`, `(3760, 2897)`, `(3761, 2897)`, it is solid, it
stands 0 inches high, and it belongs to object 13.

Everything that happens to it happens in eleven steps and every one of them is
below.

---

## Part 1 — the four numbers, and why the file has no others

`tools/generate_demo_map.gd:44-155`.

```gdscript
const INCHES_PER_CELL := 1.5
const BLOCKS_PER_CELL := 16
const PIXELS_PER_BLOCK := 2
const CAMERA_PITCH_ABOVE_FLOOR_IN_DEGREES := 65.0
```

Three units, one camera. Read them as a chain, biggest to smallest:

```
1 cell  = 1.5 real inches  = 16 blocks = 32 world pixels
1 block = one pixel of a reference art pack = 2 world pixels
```

The camera turns real inches into blocks, and it does it **twice**, differently,
because a floor and a wall are not seen the same way:

```gdscript
const BLOCKS_PER_PLAN_INCH := 10.667    # an inch measured ACROSS the floor
const BLOCKS_PER_HEIGHT_INCH := 4.5     # an inch measured UP  (plan x cos 65)
```

This is the whole reason the room reads as a room. A 30-inch desk is
`30 * 10.667 = 320` blocks wide and shows `30 * 4.5 = 135` blocks of apron. A
3-inch toy block is 32 wide and 14 tall. Every piece writes its own arithmetic
into a `real` field, so a wrong camera angle can be caught by reading, without
running anything:

```gdscript
"real": "30 x 18 in plan (320 x 192); lid at 18 in, so 81 blocks of front",
```

One cheat is declared at the top of the file and nowhere else: the floor is
drawn **without** foreshortening, so cells stay square and a chessboard stays a
chessboard. Every top-down game makes that cheat. The bug it replaced was making
it *differently per object* — blocks at 63°, wardrobe at 70°, desk at 79°, floor
at 90° — which reads as wrong without ever telling you why.

Then the two numbers that are level design rather than drawing:

```gdscript
const MAX_STEP_IN_INCHES := 6     # up
const MAX_DROP_IN_INCHES := 24    # down
```

Climbing and falling are different moves. That asymmetry is what makes a route
run one way only, and it is the only reason this room has shortcuts instead of
corridors.

---

## Part 2 — a piece, as data

`tools/generate_demo_map.gd:360` — the chest our block belongs to.

```gdscript
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
        ...
```

Read that as a drawing instruction list, top of the object to bottom, back to
front. Each entry is one rectangle plus what it is made of.

**Our block is in the ninth entry**, the one that says `its front`.

Note what a piece is *not*: it has no position. It is drawn once, in its own
coordinates, from its own north-west corner. Position lives somewhere else:

```gdscript
const PLACEMENTS := [
    ...
    {"piece": "bookcase", "origin": Vector2i(100, 57)},
    {"piece": "toy_chest", "origin": Vector2i(100, 76)},
    ...
]
```

That separation is the reason moving furniture is a one-line edit and the reason
a piece can never come apart from its own shadow.

Three optional keys on an emit do most of the shaping:

| Key | Does | Watch for |
| --- | --- | --- |
| `up_in_inches` | overrides the piece's height *for this rectangle* | this is how one object carries a **ramp** — the blanket is four rectangles at 18, 12, 6, 0 |
| `repeat: {count, step}` | one entry becomes a row of identical details | **every copy shares this entry's height.** That bug gave all six bookcase shelves the top shelf's height and broke the climb |
| `only_on_ground` | paints only over floor and rug | shadows. Without it a shadow climbs the wall behind the object |

(A fourth, `skew_east_per_row`, shifts one block east per row south. Only the
sunbeam uses it.)

Our entry uses `up_in_inches: 0` — the chest *stands* at 18 (its lid) but its
front face is a vertical wall, and a wall is not a surface you stand on.

---

## Part 3 — `_init`, the whole program on one screen

`tools/generate_demo_map.gd:1007`. Everything else in the file is a subroutine
of this.

```gdscript
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
```

Ten calls, in a fixed order, and the order carries the meaning:

1. `_load_tiles` — **first**, always. Colours, bodies, solidity, grain and weave
   all come from the tile manifest, so the map physically cannot disagree with
   the tiles.
2. `_load_hand_pieces` — anything you drew yourself, before anything is placed.
3. `_regions` — flatten the room and the furniture into absolute rectangles,
   skipping the procedural version of anything hand-drawn.
4. `_paint` — rasterise those rectangles into flat grids.
5. `_apply_hand_heights` — your height maps overwrite those grids.
6. `_find_broken_routes` — **the gate.** Walk every required route. Any break and
   the script prints it and `quit(1)`s: nothing is written, the old PNG survives.
7. `_stamp` — draw. Five passes.
8. `_composite_hand_art` — paste your PNGs on top, untouched.
9. `_to_world_pixels` — double, nearest neighbour, never anything else.
10. save the map, the close-ups, the manifest, the specimen sheet, and re-export
    every drawing template.

The one thing to take from the shape of it: **the routes are checked between the
geometry and the picture.** A room that severs itself never gets drawn.

---

## Part 4 — `_regions` and `_emit`: from a piece's coordinates to the room's

`tools/generate_demo_map.gd:1094`.

```gdscript
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
```

Three things happen here and nowhere else in the file.

**The room goes down first**, at object index 0. Then each placement, in list
order, at object index `index + 1`. Later placements paint over earlier ones —
`PLACEMENTS` is a paint order, not a set.

**Cells become blocks:** `placement["origin"] * BLOCKS_PER_CELL`. Placements are
written in cells because that is how you think about furniture; everything after
this line is blocks.

**A hand-drawn piece is skipped**, not merged. `continue`. That is what lets you
replace one piece and leave the other twenty-three procedural.

`_scale_of` is the bridge between the old coarse pieces and the new detailed
ones:

```gdscript
func _scale_of(piece: Dictionary) -> int:
	return 1 if piece.get("unit", "cells") == "blocks" else BLOCKS_PER_CELL
```

A piece authored in cells has each of its numbers multiplied by 16. A piece
authored in blocks says every block itself — which is where the detail lives,
and why the second-generation pieces read and the first-generation ones do not.

Then `_emit` (`:1124`) does the actual arithmetic:

```gdscript
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
				...
```

Two lines to read closely:

- `emitted.get("up_in_inches", up)` — **the emit's own height wins over its
  object's.** This one `get` is the entire ramp mechanic.
- the `Rect2i(...)` — `repeat` is expanded here, by translating the rectangle,
  which is why every copy shares one `up_in_inches`. The known trap, in one line.

### Our block, after Part 4

| | |
| --- | --- |
| piece | `toy_chest`, `PLACEMENTS` index 12 → **object index 13** |
| origin | cell `(100, 76)` → block `(1600, 1216)` |
| scale | `1` (authored in blocks) |
| emit rect | `Rect2i(0, 192, 320, 81)` |
| absolute rect | `Rect2i(1600, 1408, 320, 81)` |
| material | `paint_face` |
| up_in_inches | `0` |

Block `(1880, 1448)` falls inside that rectangle, 280 blocks east and 232 south
of the chest's own corner. You can confirm this without running anything: the
generated `demo_map.json` lists all 459 regions with their absolute block
rectangles, and region 206 is exactly `(1600, 1408, 320, 81)`.

---

## Part 5 — `_paint`: five grids, three million entries each

`tools/generate_demo_map.gd:1223`. First the grids are made empty:

```gdscript
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
```

`count` is `2048 * 1536` = **3,145,728**. Five flat arrays, one entry per block,
indexed `y * width + x`. They are `Packed*Array` and integers rather than
anything richer for exactly that reason — and for the same reason the hand-art
paths later read raw bytes instead of calling `get_pixel` three million times.

| Grid | Holds | Empty value | Read later by |
| --- | --- | --- | --- |
| `material_by_block` | index into the material name list | `void` | the stamper, the manifest |
| `height_by_block` | inches | `0` | the route walker |
| `solid_by_block` | 0 or 1 | `0` | the route walker |
| `object_by_block` | who owns this block | `-1` | the bevel, the hole counter |
| `order_by_block` | *when* it was laid | `-1` | the contact shadow |

`object_by_block` filling with `-1` is what makes an unclaimed block detectable
at all; `order_by_block` is the one that is not obvious, and Part 9 pays it off.

Then the loop that does the work:

```gdscript
	var order := 0
	for region in regions:
		order += 1
		...
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
```

Five lines write five grids and there is no cleverness: **last writer wins.**
`maxi`/`mini` clamp to the map so a piece can hang off the edge without crashing.
`only_on_ground` reads the grid *as it currently stands* before deciding — which
is how a shadow refuses to climb the wall or lie across the next object.

`plain` is a small optimisation: most materials resolve to themselves, so the
per-block `_resolve` call only happens for the four that are patterns.

### Our block, after Part 5

At `i = 1448 * 2048 + 1880 = 2967384`:

```
material_by_block[i] = index of "paint_face"
height_by_block[i]   = 0
object_by_block[i]   = 13
order_by_block[i]    = 207
solid_by_block[i]    = 1        # tiles["paint_face"]["solid"] is true
```

`solid` is not a decision this file makes. It comes from
`tools/generate_kingdom_tiles.gd`:

```gdscript
	"paint_face": {
		"palette": ["#0e1d22", "#25464c", "#2e565c", "#3b686e"],
		"patch": ["2222", "2222", "2222", "2222"],
		"body": "chest_face",
		"raised": true,
		"solid": true,
		"note": "the toy chest seen face on — its front, which a pawn has to walk around",
	},
```

One material, one truth, in one place.

---

## Part 6 — patterns and cells: `_resolve` and `_cell`

Two small functions that are easy to skip and shouldn't be.

```gdscript
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
```

Four materials are written as one word and become many. The chessboard is the
clearest: `"board"` is one rectangle in the data and comes out as a checker,
because the checker is a function of position, not of authoring.

Note it divides down to cells before deciding. A floorboard course, a wallpaper
stripe and a board square are all cell-sized things, so they are decided in
cells even though they are painted in blocks.

```gdscript
func _cell(painted: Dictionary, key: String, x: int, y: int) -> int:
	var block_x := x * BLOCKS_PER_CELL + BLOCKS_PER_CELL / 2
	var block_y := y * BLOCKS_PER_CELL + BLOCKS_PER_CELL / 2
	return painted[key][block_y * int(painted["width"]) + block_x]
```

**The art is drawn in blocks. The game is played in cells.** This is the only
bridge between them: it samples the middle block of a cell and calls that the
cell's value. The route walker and the manifest both come through here, so a
detail smaller than half a cell can be drawn but cannot change gameplay — which
is the correct trade and worth knowing you made it.

Our block `(1880, 1448)` is the exact middle block of cell `(117, 90)`:
`117 * 16 + 8 = 1880`, `90 * 16 + 8 = 1448`. That cell reports material code
`Y` (= `paint_face`) and height digit `0` in the generated manifest.

And the canary, which learned a lesson:

```gdscript
## Counts cells nothing claimed. It asks WHO owns the cell rather than what it is
## made of: a hand-drawn piece has an owner and no material, so counting
## materials reported the whole floor missing the moment the room was drawn by
## hand. A canary that cries wolf is worse than no canary.
func _count_holes(painted: Dictionary) -> int:
```

It reported 7,899 false holes the first time the room was hand-drawn. Reading
`object_by_block < 0` instead of the material fixed it.

---

## Part 7 — `_apply_hand_heights`: your drawing becomes physics

`tools/generate_demo_map.gd:1706`. This runs **after** `_paint` and **before**
the route check, which is the whole point: hand-drawn art is checked by the same
walker as generated art.

```gdscript
	var inches_by_rgb := {}
	for hex in HEIGHT_IN_INCHES_BY_COLOUR:
		inches_by_rgb[hex.hex_to_int()] = HEIGHT_IN_INCHES_BY_COLOUR[hex]
	var solid_rgb: int = SOLID_COLOUR.hex_to_int()
```

The key it is decoding:

```gdscript
const SOLID_COLOUR := "ff00ff"
const HEIGHT_IN_INCHES_BY_COLOUR := {
	"1a3a1a": 0, "2e7d32": 6, "66bb46": 12, "b7e04a": 18, "ffee58": 24,
	"ffb300": 30, "fb8c00": 36, "e65100": 42, "d84315": 48, "b71c1c": 54,
	"6a1b9a": 60,
}
```

Dark green is the floor, going up through green, yellow, orange, red to purple
at five feet. Magenta means solid: seen, never entered. The same key is written
out three ways next to the templates — `height_key.png` to eyedropper from,
`height_key.gpl` for Aseprite, `height_key.json` for a script — so you never
type a hex code.

The inner loop, per pixel:

```gdscript
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
```

Three rules worth memorising before you draw anything:

- **transparent means "not part of this piece"** and leaves whatever is
  underneath alone. That is how you draw a chair with gaps between its legs.
- **an unknown colour stops the build**, with the exact pixel coordinate. An
  anti-aliased brush or a colour-picked-by-eye is a typo, and guessing what you
  meant would be worse than refusing.
- `order_by_block = 10000 + object_index` — hand art is laid "after everything",
  so the contact-shadow pass in Part 9 treats it as sitting on top of the room
  rather than being printed into it.

Loading is deliberately strict too (`:1667`): art without a height map, or a
height map without art, is reported rather than half-applied, and a mismatched
pair of sizes is reported rather than stretched.

**Nothing in either script ever writes to `assets/art/pieces/`.** Templates go to
`assets/_generated/piece_templates/` and are overwritten every run; your work goes in
the other folder and is never touched.

---

## Part 8 — `_find_broken_routes`: the gate

`tools/generate_demo_map.gd:1346`. A breadth-of-nothing flood fill from the
spawn, and the only reason the room can be rearranged confidently.

```gdscript
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
			...
			if solid_by_block[at] == 1:
				continue
			var landing := _cell(painted, "height_by_block", next.x, next.y)
			if landing - standing > MAX_STEP_IN_INCHES:
				continue
			if standing - landing > MAX_DROP_IN_INCHES:
				continue
			reached[next] = true
			frontier.append(next)
```

Four cardinal steps — the same moves the pawn has. Three refusals, in order:
solid, too high to climb, too far to fall. Then:

```gdscript
	var broken := []
	for route in REQUIRED_ROUTES:
		if not reached.has(route["from"]) or not reached.has(route["to"]):
			broken.append(route["note"])
	return broken
```

And the routes it is checking are prose:

```gdscript
	{"from": Vector2i(94, 86), "to": Vector2i(102, 60), "note": "UP THE SIX SHELVES TO THE TOP"},
	{"from": Vector2i(94, 86), "to": Vector2i(95, 45), "note": "AND DOWN THE TWELVE-INCH DROP ONTO THE BED"},
	{"from": Vector2i(94, 86), "to": Vector2i(78, 67), "note": "along the bed and down the blanket — the shortcut"},
```

When one breaks you get the sentence back, not a coordinate:

```
route broken: UP THE BOOKS ONTO THE BOARD
```

This is not documentation and it is not a test suite you remember to run. It is
in the build path, before anything is drawn, and it caught seven real bugs while
this room was being built — most of them self-inflicted minutes earlier:

| It caught | Which had looked like |
| --- | --- |
| `shelf_face` declared `solid` | a bookcase that read as a staircase but was a wall |
| a `repeat` giving six shelves one height | a staircase with six identical steps |
| a toy block's front face declared solid | a 3-inch block sealing a 14-cell corridor |
| the play table's back legs | a book stack that could not be climbed |
| a cardboard box parked in a corridor | a tidy corner |
| a wardrobe on the floor in front of the door | a sensible place for a wardrobe |

Because `MAX_DROP` is four times `MAX_STEP`, half the routes are one-way by
construction. Set them equal and every shortcut in the room silently stops being
a shortcut — the walker would still pass, and the level would be gone.

*(Small note while reading: `_find_broken_routes` takes a `tiles` argument it
never uses — solidity now comes from the grid. Harmless, removable.)*

### Our block, after Part 8

`solid_by_block[i] == 1`, so cell `(117, 90)` is never entered. The chest's front
is a wall you walk around, which is what its `note` said it was.

---

## Part 9 — `_stamp`: five passes, in the order a pixel artist works

`tools/generate_demo_map.gd:1391`. This is the longest function and the one that
decides whether the picture reads. It builds a raw `PackedByteArray` of RGBA and
sweeps it five times.

First it builds colour tables — one lookup per material rather than per block:

```gdscript
	var mid := _colour_table(tiles, names, "mid")
	var ink := _colour_table(tiles, names, "ink")
	var lit := _colour_table(tiles, names, "lit")
	var dark := _colour_table(tiles, names, "dark")
	var shade := _mixed_table(tiles, names, "mid", "ink", 0.34)
	var weft := _mixed_table(tiles, names, "mid", "dark", 0.22)
```

**Pass 1 — flat colour.**

```gdscript
	for i in width * height:
		var m := material_by_block[i] * 4
```

Every block gets its material's mid tone. Nothing else. At the end of pass 1 the
picture is a field of flat rectangles, and it looks like one.

**Pass 2 — weave.** A diagonal hatch in cloth and paper:

```gdscript
			if weave == 0 or (x + y) % weave != 0:
				continue
```

`(x + y) % n` is a diagonal line. Cloth is never a flat colour.

**Pass 3 — grain, and the floorboards' staggered butts.**

```gdscript
		var course := y / BLOCKS_PER_CELL / ROWS_PER_FLOORBOARD
		var stagger := (course * BOARD_STAGGER_PER_ROW) % CELLS_PER_BOARD_LENGTH
		...
			var on_grain := y % grain < 2
			var on_butt := (
				body_by_index[index] == "floor"
				and (x / BLOCKS_PER_CELL + stagger) % CELLS_PER_BOARD_LENGTH == 0
				and x % BLOCKS_PER_CELL < 2
			)
```

Grain runs across cell boundaries into one long line — that is why it is drawn
here by the map and not baked into each tile. The stagger offsets each course of
boards so no joint runs straight across the room, which is how a real floor is
laid.

**Pass 4 — the contact shadow.** The subtle one, and the payoff for
`order_by_block`:

```gdscript
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
```

`over` is the block three up and three to the left. If what is there was laid
*after* what is here, then it is standing **on** this, and this gets darkened.
A pencil on a desk, a pawn on a board, a book on a shelf. The body check stops an
object shadowing itself.

Without this pass small objects look printed onto surfaces. With it they sit on
them. It is three lines of comparison and it does more for the picture than any
amount of extra detail in the objects.

**Pass 5 — the bevel.** One block wide, around each body, and nowhere inside one:

```gdscript
			var north := y > 0 and _other(material_by_block, object_by_block, body_by_index, i - width, body, owner)
			...
			if south or east:
				pixels[o] = ink[k] ...
			elif (north or west) and raised_by_index[index] == 1:
				pixels[o] = lit[l] ...
```

Light from the upper left, fixed for the whole room: lit along the top and left,
ink down the bottom and right. `raised` gates the highlight so flat things on
the floor get an outline but not a lift.

The test for "am I at an edge" is:

```gdscript
func _other(
	material_by_block: PackedInt32Array, object_by_block: PackedInt32Array,
	body_by_index: PackedStringArray, at: int, body: String, owner: int
) -> bool:
	if object_by_block[at] != owner:
		return true
	return body_by_index[material_by_block[at]] != body
```

**Different owner, or different body, is an edge.** Six lines, and they are the
single most important fix in the whole project.

The original tiles each carried their own rim, so a 38-cell tabletop came out as
eight hundred outlined bricks and the room read as a patchwork quilt. Moving the
rim from the tile to the *body* means an object is outlined once, at its
silhouette, the way a real thing is. If you read one function in this file
closely, read this one.

### Our block, after Part 9

| Pass | What happens to `(1880, 1448)` |
| --- | --- |
| 1 flat | `paint_face` mid → **`#2e565c`** |
| 2 weave | `paint_face` has no weave → skipped |
| 3 grain | not sawn wood → skipped |
| 4 shadow | the block up-left is the same face, laid at the same time → skipped |
| 5 bevel | every neighbour is the same owner and the same body → interior, no bevel |

It comes out `#2e565c`. Undramatic on purpose: most blocks are, and the five
passes exist for the minority at the edges, which are the ones the eye reads.

---

## Part 10 — out to disk

```gdscript
func _to_world_pixels(block_image: Image) -> Image:
```

Doubles the block picture. Nearest neighbour, never anything else, or the art
stops being pixel art. `(1880, 1448)` becomes the four world pixels at
`(3760, 2896)`.

`_composite_hand_art` (`:1774`) runs *before* the doubling and pastes your PNGs
over the finished procedural picture at block resolution:

```gdscript
		block_map.blend_rect(
			art,
			Rect2i(Vector2i.ZERO, art.get_size()),
			placement["origin"] * BLOCKS_PER_CELL
		)
```

No bevel, no grain, no shadow is added over your work — you drew those. Note it
uses the same `placement["origin"] * BLOCKS_PER_CELL` as `_regions`, so a
hand-drawn piece stands exactly where the procedural one stood.

Then, back in `_init`:

- **the close-ups.** Each is cropped from the full map at full resolution, and a
  rectangle that runs off the map stops the build rather than saving a white
  image:

  ```gdscript
  		if not Rect2i(0, 0, MAP_WIDTH_IN_CELLS, MAP_HEIGHT_IN_CELLS).encloses(rect):
  			printerr("close-up ", close_up["name"], " runs off the map: ", rect)
  ```

  A room that only works zoomed out is a floor plan; one that only works zoomed
  in is a diorama. Three crops keep both honest.

- **`_write_manifest`** (`:1580`) — `demo_map.json`: the four unit constants, a
  per-cell material grid one character wide, a per-cell height grid one digit
  wide, all 459 regions with absolute block rectangles, the nodes, the pieces,
  the placements. This is how you check a claim about the room without opening
  the PNG. Everything traced in this document was verified against it.

- **the specimen sheet** — every piece laid out in a row on dark ground, each in
  its own object slot so each gets its own outline. Pieces judged as things,
  before any room is furnished with them.

- **`_export_templates`** (`:1794`) — every piece written back out as the PNG pair
  you would draw by hand, art and height map, already correct. Rewritten every
  run, so you paint over the current state rather than starting from nothing.

---

## Part 11 — the other script

`tools/generate_kingdom_tiles.gd`, 578 lines, and 415 of them are the `MATERIALS`
dictionary. It owns 47 materials and nothing else:

```gdscript
	"paint_top": {
		"palette": ["#0e1d22", "#39646b", "#487a80", "#5b9098"],
		"patch": ["2222", "2222", "2222", "2222"],
		"body": "chest",
		"raised": true,
		"solid": false,
		"note": "the painted lid of a toy chest — the one thing in the room a child chose the colour of",
	},
```

| Key | Read by |
| --- | --- |
| `palette` | `[ink, dark, mid, light]` — passes 1, 3 and 5 of the stamper |
| `patch` | 4x4 flat colours, deliberately near-flat for big surfaces |
| `body` | the silhouette this belongs to — the bevel outlines where this changes |
| `raised` | takes a lit top-left edge as well as a shadowed bottom-right one |
| `grain` / `weave` | passes 3 and 2 |
| `solid` | blocks movement, read straight into `solid_by_block` |
| `seam` | a single ink block on one edge — how a floorboard gets its joint |

Run it first, always. The map script reads its manifest, so the two can never
disagree about what a colour is or whether you can walk through it.

---

## Part 12 — how to read the file yourself

Four sittings, in this order:

1. **The header comment and the constants** (`:1-155`). Thirty lines of prose and
   twenty constants. If you understand the four units and the two camera scales,
   the other 1,800 lines are consequences.
2. **`_init`** (`:1007-1078`). Seventy lines. The whole program.
3. **One piece and its placement.** Pick `toy_chest` (`:360`) and follow it
   through `_regions` → `_emit` → `_paint`. That is this walkthrough's Parts 4
   and 5, and once you have done it once for one piece you have done it for all
   twenty-four.
4. **`_stamp`** (`:1391-1516`) and **`_other`** (`:1531`). The picture, and the six
   lines that make it read.

Everything else — `_save`, `_colour_table`, `_sheet_regions`, `_export_one` — is
plumbing you can read the day you need to change it.

## The whole journey, on one page

| Step | Where | What our block is |
| --- | --- | --- |
| a sentence | `PIECES["toy_chest"]`, 9th emit | `its front — eighty-one blocks, eighteen inches` |
| a position | `PLACEMENTS[12]` | cell `(100, 76)` |
| an absolute rectangle | `_regions` → `_emit` | `Rect2i(1600, 1408, 320, 81)`, object 13 |
| five grid writes | `_paint` | material `paint_face`, height 0, owner 13, order 207, solid 1 |
| a cell | `_cell` | `(117, 90)`, manifest code `Y`, height digit `0` |
| a wall | `_find_broken_routes` | solid — never entered, walked around |
| a colour | `_stamp` pass 1 | `#2e565c` |
| still that colour | passes 2–5 | no weave, no grain, no shadow, interior so no bevel |
| four pixels | `_to_world_pixels` | `(3760, 2896)` to `(3761, 2897)` |
| a file | `_save` | `assets/_generated/maps/demo_map.png` |
| a fact you can check | `_write_manifest` | `demo_map.json`, region 206 |
