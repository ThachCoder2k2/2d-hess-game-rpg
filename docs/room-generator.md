# The room generator — a reading guide

Two scripts in `tools/` build the demo room. Nothing in the game runs them; they
are run by hand and they write files. This is the map of them, in the order that
makes them readable rather than the order they appear on disk.

Reading the code for the first time? Read
[`room-generator-walkthrough.md`](room-generator-walkthrough.md) instead — the
same code in the order the machine runs it, following one block of the picture
from the sentence that describes it to the two pixels it becomes. Come back here
afterwards; this page is the reference you keep.

```bash
HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot --headless --path . -s tools/generate_kingdom_tiles.gd
```

```bash
HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot --headless --path . -s tools/generate_demo_map.gd
```

Tiles first, always: the map script reads the tile manifest for colours, bodies
and solidity.

## Who owns what

| Script | Lines | Owns |
| --- | --- | --- |
| `generate_kingdom_tiles.gd` | 578 | the 47 **materials**: colour, grain, weave, body, solid |
| `generate_demo_map.gd` | 1926 | the **room, the furniture, the level**, and the picture |

## Four numbers everything else is derived from

Change one of these and the whole room changes with it. They live at the top of
`generate_demo_map.gd` and nothing anywhere hard-codes a value they imply.

| Constant | Value | Means |
| --- | --- | --- |
| `INCHES_PER_CELL` | 1.5 | one cell is one square of a real chessboard |
| `BLOCKS_PER_CELL` | 16 | the drawing unit; one block = one pixel of a reference art pack |
| `PIXELS_PER_BLOCK` | 2 | a block is two world pixels, so a cell is 32 |
| `CAMERA_PITCH_ABOVE_FLOOR_IN_DEGREES` | 65 | the camera, and the only reason the two scales below differ |

From the camera come the two scales every size in the file is quoted in:

```
one inch ACROSS the floor  = BLOCKS_PER_PLAN_INCH   = 10.667 blocks
one inch of HEIGHT         = BLOCKS_PER_HEIGHT_INCH = 4.5 blocks   (plan x cos 65)
```

So a 30-inch desk shows 135 blocks of apron and a 3-inch toy block shows 14.
Every piece repeats its own conversion in its `real` field, so a wrong camera
angle is visible by reading, without running anything.

One cheat, declared: the floor is drawn without foreshortening so cells stay
square and a chessboard stays a chessboard. Every top-down game makes it. What
is not allowed is making it differently per object — that was the bug that made
the first draft read as a patchwork.

## The file is two halves

`generate_demo_map.gd` looks long. It is not: **840 of its 1926 lines are data
you edit, and the machinery underneath is 920 lines you read once.**

| Lines | What | Touch it when |
| --- | --- | --- |
| 44–155 | constants | changing the camera, the scale, the climb rules |
| 158–218 | `THE_ROOM` | moving a wall, the window, the door |
| 219–894 | `PIECES` | drawing or reshaping a piece of furniture |
| 895–920 | `LEVEL` | writing down the level's shape (documentation only) |
| 922–960 | `PLACEMENTS` | **moving furniture — one line each** |
| 962–995 | `NODES`, `REQUIRED_ROUTES` | changing what must be reachable |
| 997–1005 | `CLOSE_UPS` | changing which crops get saved |
| 1007+ | machinery | rarely |

## The data structures

**`PIECES`** — a catalogue. Each entry is one object drawn once in its own
coordinates, at its own north-west corner:

```gdscript
"toy_chest": {
    "size": Vector2i(320, 273),          # footprint in blocks
    "unit": "blocks",                    # or "cells" for the old coarse ones
    "real": "30 x 18 in plan (320 x 192); lid at 18 in, so 81 blocks of front",
    "up_in_inches": 18,                  # how high its surface stands
    "emits": [ ... ],                    # rectangles, in paint order
}
```

An `emits` entry is a rectangle plus what it is made of:

```gdscript
{"rect": Rect2i(0, 192, 320, 81), "material": "paint_face", "up_in_inches": 0,
    "note": "its front — eighty-one blocks, eighteen inches"}
```

Four optional keys do the heavy lifting:

- `up_in_inches` — overrides the piece's height for this rectangle. This is how
  one object carries a ramp: the blanket is four rectangles at 18, 12, 6 and 0.
- `repeat: {count, step}` — one entry becomes a row of identical details.
  Spindles, quilting, book spines. **Careful: every copy shares the entry's
  height.** That bug gave all six bookcase shelves the top shelf's height and
  broke the climb.
- `only_on_ground` — paints only over floor and rug, so a shadow cannot climb
  the wall, spill into the dark past the room, or lie across the next piece.
- `skew_east_per_row` — shifts one block east per block south. Only the sunbeam
  uses it.

**`PLACEMENTS`** — where each piece stands, in **cells**, in paint order. Later
covers earlier. Moving furniture is editing one line.

**`REQUIRED_ROUTES`** — pairs of cells that must be walkable from the spawn.
This is not documentation: a broken route **stops the build**.

## What `_init` does, in order

1. `_load_tiles` — read the tile manifest. Colours, bodies, solidity, grain,
   weave all come from there, so the map can never disagree with the tiles.
2. `_load_hand_pieces` — anything you have drawn yourself.
3. `_regions` — flatten `THE_ROOM` + `PLACEMENTS` into absolute rectangles,
   skipping the procedural version of anything hand-drawn. **This is the only
   place a piece's own coordinates become the room's**, which is why a piece can
   never come apart from its shadow, its legs or its blanket.
4. `_paint` — rasterise into the grids (below).
5. `_apply_hand_heights` — your height maps overwrite those grids.
6. `_find_broken_routes` — walk every required route. **Any break: `quit(1)`,
   nothing is written.**
7. `_stamp` — draw the picture. Five passes, in the order a pixel artist works:
   flat colour → weave → grain → contact shadow → bevel.
8. `_composite_hand_art` — paste your PNGs on top, untouched.
9. `_to_world_pixels` — double it, nearest neighbour, never anything else.
10. save the map, the close-ups, the manifest, the specimen sheet, and re-export
    every template.

## The grids

`_paint` returns four flat arrays, one entry per block, `y * width + x`:

| Grid | Holds | Read by |
| --- | --- | --- |
| `material_by_block` | index into `CODE_BY_MATERIAL` | the stamper, the manifest |
| `height_by_block` | inches | the route walker |
| `solid_by_block` | 0 or 1 | the route walker |
| `object_by_block` | who owns the cell | the bevel, the hole counter |

Plus `order_by_block` — when each block was laid, which is how the contact
shadow knows a pencil is lying **on** a desk rather than printed into it.

They are `PackedInt32Array` because the room is 2048 x 1536 = **three million
blocks**, and anything richer would not fit in a tool script's patience. For the
same reason the hand-art paths read raw bytes rather than calling `get_pixel`.

Gameplay is still played on **cells**, not blocks. `_cell()` samples the middle
block of a cell, and the route walker and the manifest both go through it.

## The climb rules

```gdscript
const MAX_STEP_IN_INCHES := 6    # up
const MAX_DROP_IN_INCHES := 24   # down
```

Climbing and falling are different moves, and that asymmetry is the level
design. A route can run one way only: you climb the bookcase's six shelves the
long way round, drop twelve inches onto the bed, and cannot go back up. Make
them equal and every shortcut in the room stops being a shortcut.

## Hand-drawn art

A piece is replaced by dropping **two** PNGs into `assets/art/pieces/`:

```
bed.png          the art,     one pixel per block
bed_height.png   the heights, one pixel per block
```

Both or neither — one alone is reported rather than half-applied. In the height
map, one flat colour is one height, magenta is solid, transparent is "not part of
this piece". The key is written out three ways next to the templates:
`height_key.png` to eyedropper from, `height_key.gpl` for Aseprite,
`height_key.json` for a script.

`the_room` is drawable on the same terms, at the origin, covering the whole map.

Templates are re-exported to `assets/_generated/piece_templates/` on **every run** and
are identical to what the generator draws, so you paint over them rather than
starting from nothing — and so you replace one piece at a time while everything
else keeps building and the routes keep being checked.

**Nothing in either script ever writes to `assets/art/pieces/`.**

## The things that stop the build

Not warnings. The script calls `quit(1)` and writes nothing.

| Check | Catches |
| --- | --- |
| `_find_broken_routes` | furniture that severs the level |
| `_count_holes` | a cell nothing claimed |
| height map colour not in the key | a typo, with the pixel coordinate |
| art and height map different sizes | a mismatched pair |
| art without a height map, or the reverse | half a piece |
| close-up rectangle off the map | a crop that would come out white |
| a material the tile manifest does not have | tiles and map out of step |

Between them these caught seven real bugs while the room was being built,
including several introduced minutes earlier: shelf ledges declared solid, a
`repeat` that flattened six shelf heights into one, a cardboard box parked across
the only corridor, and a wardrobe that sealed the floor in front of the door.

## Where to change what

| To do this | Edit |
| --- | --- |
| move a piece of furniture | one line in `PLACEMENTS` |
| reshape a piece | its `emits` in `PIECES` |
| move a wall, window or door | `THE_ROOM` |
| change the camera angle | `CAMERA_PITCH_ABOVE_FLOOR_IN_DEGREES` and the two scales, then every face height |
| change how far a pawn climbs | `MAX_STEP_IN_INCHES` / `MAX_DROP_IN_INCHES` |
| add a colour or material | `MATERIALS` in the tiles script, then a character in `CODE_BY_MATERIAL` |
| change what must be reachable | `REQUIRED_ROUTES` |
| draw a piece by hand | nothing — drop two PNGs in `assets/art/pieces/` |
