# Third-Party Notices

**STUB (M1a, 2026-10-12).** This lists what in this repository is not original work of the
project owner, so the credits and any release can acknowledge it correctly. It is incomplete
by design: M4 recorded the font slots below (the font files themselves are the owner's) and M14 completes the file
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

## Slots for files the owner supplies

### UI fonts (owner-supplied)

- **What:** the pixel fonts of the UI, dialogue, Book and HUD numerals. The game names four slots in
  `content/ui/theme/theme.tres` (`schema/ui/ui_theme.gd`); the file for each is put at its path by the owner:
  `assets/fonts/ui_body_pixel.ttf` (main font), `assets/fonts/ui_small_pixel.ttf` (HUD numerals),
  `assets/fonts/ui_title_pixel.ttf` (headings), `assets/fonts/child_hand.ttf` (the child's lines, M6).
  The asset list (`docs/assets/spec/ui_story.json`, group `fonts_ui`) recommends open-licence fonts and says
  what to check.
- **Status:** **owner-supplied.** No font file is in this repository today: nothing was downloaded, and the game
  uses the engine's own default font (Godot's, MIT, credited under Godot Engine below) until a file is put
  at a slot's path.
- **Action when a font file is added:** add its entry here under its own `###` heading with a
  `- **License:**` bullet and the licence text in a `text` block (the SIL Open Font License 1.1 for the fonts
  the asset list suggests), then run `godot --headless --path . -s tools/build_credits_licenses.gd` so the
  credits show it. `tests/text/test_font_vietnamese_coverage.gd` fails if the file cannot write every
  Vietnamese letter.

### Input glyphs (owner-supplied)

- **What:** the keyboard and gamepad pictures of the control prompts and the Controls panel. The game looks for them at
  the paths of the asset list (`docs/assets/spec/ui_story.json`, group `glyphs_kenney`, folder `assets/ui/glyphs`), for
  example `assets/ui/glyphs/keyboard/key_w.png` and `assets/ui/glyphs/gamepad/btn_a.png`
  (`presentation/ui/input_glyphs/input_glyphs.gd` holds the table of which control uses which file).
- **Status:** **owner-supplied.** No glyph file is in this repository today: nothing was downloaded, and a prompt reads
  its words (`[Space]`, `[A]`) until a file is put at its path. The owner's plan is Kenney's pack "Input Prompts Pixel",
  which Kenney publishes under CC0 (public domain): the light 16x16 tiles, copied and renamed as the asset list says.
- **Action when the files are added:** CC0 asks for no credit, but the project credits it anyway: add an entry here under
  its own `###` heading with a `- **License:**` bullet and the licence text in a `text` block, then run
  `godot --headless --path . -s tools/build_credits_licenses.gd` so the credits show it.

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
  The default Godot font is the engine's. The pixel fonts for the final UI are the owner's: see
  "UI fonts (owner-supplied)" above.
