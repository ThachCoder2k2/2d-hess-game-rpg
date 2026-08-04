#!/usr/bin/env python3
"""Trace the chess-knight glyph into the span tables generate_chess_sprites.gd uses.

Every hand-authored knight silhouette in this project read wrong, because the
numbers were typed from memory of a reference instead of measured off one. This
script measures: it renders U+265E (BLACK CHESS KNIGHT) large, crops it to its
own bounding box, scales that box uniformly down to the sprite's row count, and
reports the leftmost and rightmost filled block of every row. The result is the
typeface designer's horse, not ours.

Interior holes (the eye socket, the gaps between mane strands) do not need
filling: taking the min and max filled column of a row spans straight across
them, which is exactly what a solid silhouette wants.

Run:
    python3 tools/trace_knight_glyph.py

Then paste the two printed arrays over KNIGHT_FRONT / KNIGHT_BACK in
tools/generate_chess_sprites.gd and re-run that generator. Do not hand-edit a
single row afterwards — retrace instead.

Requires Pillow (`python3 -m pip install pillow`).
"""

import math

from PIL import Image, ImageDraw, ImageFont

# Apple Symbols cuts a clean horse head with one ear and no extra mane strands.
# Arial Unicode is the fallback; Times New Roman has no U+265E at all (tofu).
FONT_PATH = "/System/Library/Fonts/Apple Symbols.ttf"
GLYPH = "♞"
RENDER_POINTS = 900

# The head occupies this many rows of the sprite; the pedestal is lathed below it.
TARGET_ROWS = 21

# Shift right so the neck's base centres over the pedestal. Measured, not guessed:
# offset 0 puts the muzzle tip hard against x=0, leaving the outline ring nowhere
# to go, and centring on the lathe axis instead pushes it to x=-1.
X_OFFSET = 1


def render_glyph_mask() -> tuple[list[list[bool]], int, int]:
    """Render the glyph black-on-white and return a filled/empty grid of its bbox."""
    font = ImageFont.truetype(FONT_PATH, RENDER_POINTS)
    canvas = Image.new("L", (RENDER_POINTS * 2, RENDER_POINTS * 2), 255)
    ImageDraw.Draw(canvas).text(
        (RENDER_POINTS // 2, RENDER_POINTS // 4), GLYPH, font=font, fill=0
    )

    # Everything darker than mid-grey is ink. The glyph is solid, so the exact
    # threshold does not matter; only the antialiased fringe sits near it.
    ink = canvas.point(lambda v: 255 if v < 128 else 0)
    box = ink.getbbox()
    if box is None:
        raise SystemExit(f"{FONT_PATH} has no glyph for U+265E (rendered blank)")
    ink = ink.crop(box)

    width, height = ink.size
    pixels = ink.load()
    grid = [[pixels[x, y] > 0 for x in range(width)] for y in range(height)]
    return grid, width, height


def trace_spans(grid: list[list[bool]], width: int, height: int) -> tuple[list[int], list[int]]:
    """Reduce the full-resolution mask to one [leftmost, rightmost] pair per sprite row."""
    scale = TARGET_ROWS / height
    front: list[int] = []
    back: list[int] = []

    for row in range(TARGET_ROWS):
        # The band of source rows that collapses into this one sprite row.
        top = int(row / scale)
        bottom = max(top + 1, int((row + 1) / scale))
        filled = [
            x
            for y in range(top, min(bottom, height))
            for x in range(width)
            if grid[y][x]
        ]
        if not filled:
            # Should not happen for a solid glyph, but never emit a broken row.
            front.append(front[-1] if front else 0)
            back.append(back[-1] if back else 0)
            continue
        # Floor the left edge and ceil the right: a block the glyph touches at
        # all is a block the silhouette owns.
        front.append(math.floor(min(filled) * scale) + X_OFFSET)
        back.append(math.ceil((max(filled) + 1) * scale) - 1 + X_OFFSET)

    return front, back


def print_block_grid(front: list[int], back: list[int]) -> None:
    """Draw the traced silhouette in ASCII so the shape can be judged before pasting."""
    span_end = max(back) + 2
    for row, (lo, hi) in enumerate(zip(front, back)):
        cells = "".join("#" if lo <= x <= hi else "." for x in range(span_end))
        print(f"{row:3d} {cells}")


def main() -> None:
    grid, width, height = render_glyph_mask()
    front, back = trace_spans(grid, width, height)

    print(
        f"glyph {width} x {height} px -> {TARGET_ROWS} rows, "
        f"{max(back) - min(front) + 1} blocks wide, x offset {X_OFFSET}"
    )
    print()
    print_block_grid(front, back)
    print()
    print(f"const KNIGHT_FRONT := {front}")
    print(f"const KNIGHT_BACK := {back}")


if __name__ == "__main__":
    main()
