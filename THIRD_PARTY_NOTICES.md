# Third-Party Notices

**STUB (M1a, 2026-10-12).** This lists what in this repository is not original work of the
project owner, so the credits and any release can acknowledge it correctly. It is incomplete
by design: milestone M4 adds the pixel font and M14 completes the file
(`docs/game-base-plan.md` section 1.1 D20, section 12). The project's own license is in
`LICENSE`. Nothing here has been legally reviewed.

**The credits are generated from this file** (`docs/game-base-plan.md` 9.2). Every `###` entry that has a
`- **License:**` bullet is credited in the game's Licenses block (`content/story/credits_licenses.tres`): its
heading is the name, the bullet is the licence, and the first fenced `text` block after the bullet is the
licence text. An entry with no License bullet (a provenance question, a slot nobody has filled) is not a credit.
After editing an entry, run `godot --headless --path . -s tools/build_credits_licenses.gd`;
`tests/shell/test_credits_licenses_current.gd` fails while the credits are stale.

## Needs the owner's check

### The Black Knight silhouette was traced from a system font glyph

- **What:** the Knight sprite's silhouette. `tools/trace_knight_glyph.py` renders the chess
  glyph U+265E (BLACK CHESS KNIGHT) from a system font, measures its outline row by row, and
  prints the span tables that `tools/generate_chess_sprites.gd` uses to draw the Knight. Since
  M2 the tables are traced on 15 rows instead of 21 (the owner decided a piece is smaller than its
  cell; the same glyph, the same script, `--rows 15`), and that knight is now also the body of the
  enemy `knight_tracker` (`content/enemies/knight_tracker/body.png`, a copy of the generator's
  `knight_idle.png`, recorded as a placeholder).
- **Source font:** the script's `FONT_PATH` is `/System/Library/Fonts/Apple Symbols.ttf`
  (Apple Symbols, shipped with macOS), with Arial Unicode named as a fallback in its comments.
  Which font produced the span tables now committed in `tools/generate_chess_sprites.gd` is not
  recorded; please confirm.
- **Why it matters:** a system font is licensed for use on the operating system, and a glyph
  outline is the typeface designer's work. Whether a silhouette derived from it may be shipped
  inside a game is not settled here.
- **Action:** **the owner decides.** The plan flags the sprite for redraw or replacement before
  any release (`docs/game-base-plan.md` D-07 and section 12, "Provenance"). Until then treat the
  Knight sprite as a placeholder with unresolved provenance, not as cleared art.

### Art files with no recorded provenance

The repository does not say how these were made, so they cannot be called original or cleared
yet. Please say how each was produced and whether it will ship.

- `assets/concept-art/*.png` (five images) and `docs/design/concept-art/` (a pathway map).
  `docs/design/gdd.md` calls such images exploratory concept art "rather than the final
  rendering method", so they are references, not shipped game art.
- The 12 source sprites that used to sit directly in `assets/sprites/generated/`: now
  `content/player/icon.png` (was `hero_pawn.png`), `content/skills/wooden_sword/icon.png`
  (`toy_sword.png`), `content/pickups/{pencil_spear,ruler_blade}/icon.png`,
  `content/pickups/toy_weapon/pickup.png` and
  `assets/ui/actor_view/{facing_arrow,health_pip_full,health_pip_empty,warning_aura}.png`. (Three
  more, the bodies `content/player/body.png` (was `hero_pawn_unarmed.png`),
  `content/enemies/pawn_recruit/body.png` (`black_pawn.png`) and
  `content/enemies/knight_tracker/body.png` (`black_knight.png`), were replaced at M2 by the
  generator's own pieces, so they are no longer in this list; the old files are in git history.)
  No script draws them (`README.md`), and `docs/where-we-are.md` calls the character sprites
  temporary July placeholders.
- `assets/map_pieces/bed.png` and `bed_height.png`. `README.md` treats this folder as hand-drawn
  source art; please confirm these two are your own work.

## Third-party software that ships or is required

### Godot Engine

- **What:** the engine the game runs on (Godot 4.6). It is not vendored in this repository; the
  binary is installed beside the project. An exported game contains it.
- **License:** MIT.

```text
Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md).
Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- **TODO (M14):** an exported build also contains Godot's own bundled third-party components.
  Their notices must be added; Godot lists them in its `COPYRIGHT.txt` and in the editor under
  Help, About, Third-party Licenses.

## Build-time tools (not shipped)

- **Pillow (PIL)**, used only by `tools/trace_knight_glyph.py` (`python3 -m pip install pillow`).
  Licensed under the open-source PIL Software License (HPND). It is not part of the game.

## Checked and original to this project

- Sound effects (`assets/sfx/*.wav`) and the march (`assets/music/unbound_march.wav`) are
  synthesised from scratch by `tools/generate_sfx.py` and `tools/generate_music.py`, which import
  only the Python standard library.
- The generated chess pieces, kingdom tiles, maps and Stage 1 room backgrounds are drawn by the
  `tools/generate_*.gd` scripts (output is gitignored; the scripts are the source). The bodies of
  the hero, the black pawns, the knight and the bishop in `content/*/body.png` are copies of that
  output (placeholders in `content/_placeholders.json`); the knight's shape is the traced glyph
  above, the others are lathe rows written in the generator.
- There are no addons (`addons/` does not exist) and no bundled fonts in the repository today.
  The default Godot font is the engine's. The pixel font for the final UI is chosen in M4 and
  must be listed here.
