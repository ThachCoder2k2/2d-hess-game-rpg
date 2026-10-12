# tools/

Build scripts, generators and migration helpers. Nothing here ships with the game.
Run Godot scripts from the project root; the project path contains a space, so quote it.

```bash
G="../Godot.app/Contents/MacOS/Godot"          # from a git worktree: "../../../../Godot.app/Contents/MacOS/Godot"
export HOME=/tmp/unbound-pawn-godot            # private HOME: Godot writes user:// data and editor settings there
"$G" --headless --path . -s tools/<script>.gd -- <options>
```

Options go after `--` (a bare `--check` right after the script also works). A new `class_name`
needs one `--headless --editor --quit` import pass before headless scripts can use it.

## Fresh clone or new worktree: one command

```bash
tools/bootstrap_worktree.sh                    # or: GODOT_BIN=/path/to/Godot BOOTSTRAP_HOME=/tmp/x tools/bootstrap_worktree.sh
```

A new checkout has no class registry (`.godot/`), so strict-typed scripts do not parse until an import
pass has run, and it has none of the generated art (gitignored). No tracked scene names generated art
any more (the room backgrounds are tracked stand-ins in `content/`, see "Placeholders" below), but the
generated pictures are still what `seed_placeholders.gd` copies from for a new room. The script imports
once as a warm-up (so the audio autoload loads; it reports any error that pass printed but tolerates
it), runs the four generators, imports again, and exits non-zero on any `ERROR`,
`SCRIPT ERROR` or `Parse Error` from the generators or from that second import. About 50 s.
Verified on a brand-new `git clone` of the branch: after the script, the whole suite and every new
test pass and `git status` is clean.

### Where generator output goes

Everything a generator writes lives under `assets/_generated/` (gitignored, never hand-edited):
`chess/`, `tiles/`, `maps/`, `rooms/`, `previews/` and `piece_templates/` (the paintable templates
`generate_demo_map.gd` re-exports on every run). The output folder is one `const` at the top of
each generator (`OUT_DIR`, `OUTPUT_DIR`, `TILE_DIR`, `PIECE_TEMPLATE_DIR`). Hand-drawn source art
is never written by a tool: `assets/map_pieces/` and the 12 tracked sprites that used to sit in
`assets/sprites/generated/` (now `content/<kind>/<id>/body.png|icon.png` and `assets/ui/actor_view/`).

No tracked scene names a generated PNG (`tests/content/test_placeholders_manifest.gd` fails if one does). A generated picture reaches the game only by being copied into
`content/` (tracked) by `seed_placeholders.gd`; the copy gets its own `.import` uid, which the scene names.

## Every tool, one line each

| Tool | What it does |
|---|---|
| `bootstrap_worktree.sh` | Makes a fresh clone or worktree test-ready: import pass, the four generators below, import pass, then the actor preview picture. |
| `run_all_tests.py` | The verification gate (`/verify`): import pass, every suite in its own bounded process, baseline-label check. `--strict`, `--only`, `--list`, `--verbose`. `--self-test` checks the gate itself (canned hangs, script errors, FAIL lines, missing verdicts, vanished labels, a fake Godot) in about 5 s with no Godot. |
| `stamp_uids.gd` | Text-level UID stamper (never calls `ResourceSaver`): adds `uid=` to uid-less scene/resource headers and to path-only `ext_resource` lines. `-- --check` only reports and exits 1 if anything would change. Idempotent. |
| `save_keeping_uids.gd` | The helper every tool that would call `ResourceSaver` uses instead (a helper, not a command; no `class_name`): `save_keeping_uid()` puts the file's previous header uid back after a save, `stamp_uids_last()` runs the stamper in a child Godot process. `tests/architecture/test_tools_keep_uids.gd` fails if a tool calls `ResourceSaver.save()` itself. |
| `move_res.py` | `git mv` a file or folder with its `.uid`/`.import` sidecars and rewrite every `res://` string that pointed at it. `--dry-run`, `--rewrite-only`, `--rename-action`, `--import-pass`, `--self-test`. |
| `dump_world.gd` | Boots a room headless, runs N manual ticks, prints the sorted node paths, texture paths and entity cells/components. `--room=t1`, `--write-baselines`, `--list`. |
| `world_dumper.gd` | The dump logic, shared by `dump_world.gd` and `tests/architecture/test_dump_baselines.gd` (a helper, not a command; no `class_name`). |
| `dump_actor_golden.gd` | Prints, or with `-- --write` records, how every actor scene looks to the rest of the game: nodes, values, clips, animation graph, and the entity `EcsBoot` bakes. The recorded file `tests/baselines/actor_collapse_golden.txt` was captured from the four hand-copied actor scenes before M2 collapsed them, so `--write` refuses to replace it without `--force`. |
| `actor_dumper.gd` | The description logic behind `dump_actor_golden.gd` and `tests/architecture/test_actor_collapse_golden.gd` (a helper, not a command; no `class_name`). |
| `seed_placeholders.gd` | Copies a generator's stand-in picture into `content/` only when the target is absent, and records the sha256 of every placeholder in `content/_placeholders.json`. `-- --check` changes nothing and exits 1 if there is work to do. Never re-records a file already listed. |
| `list_placeholders.gd` | Prints the owner's art and audio TODO by kind: every listed file whose sha256 still equals the recorded one. Overwriting a file clears its flag by itself. Exit 1 if a listed file is gone. |
| `placeholder_manifest.gd` | The manifest logic shared by the two tools above and `tests/content/test_placeholders_manifest.gd` (a helper, not a command; no `class_name`). |
| `render_actor_preview.gd` | Headless. Draws the hero, a black pawn, a knight and a bishop in their 32 x 32 cells, facing every way, armed and telegraphing, with the cell edges and the 2 px margin marked, at 4x whole-number zoom, into `assets/_generated/previews/pieces_in_cells.png`: how the owner sees that a piece is smaller than its cell without opening the editor. Composed on the CPU with `Image`, so it needs no renderer. |
| `actor_stage.gd` | Boots one actor view into a throwaway ECS world with only `ViewSyncSystem` and sets its facing, weapon or telegraph (a helper, not a command; no `class_name`). Used by the preview tool and `tests/architecture/test_pieces_inside_cell.gd`. |
| `actor_cell_probe.gd` | Measures what an actor view draws, in pixels from its cell's centre, from the opaque pixels of every visible sprite (a helper, not a command; no `class_name`). |
| `generate_chess_sprites.gd` | Bakes the chess-piece sprites (art language v13) to `assets/_generated/chess/`: the white pawn (the hero), the black pawn, the bishop, the knight, and the double-step and promoted pawns, six states each. One block is one world pixel, and it reads the size table (`content/feel/piece_sizes.tres`) and refuses to write a piece that does not fit its box. |
| `generate_kingdom_tiles.gd` | Bakes the room materials as pixel tiles, a contact sheet and a manifest (same art language as the pieces) into `assets/_generated/tiles/`. |
| `generate_demo_map.gd` | Draws the pawn-scale bedroom demo world with the kingdom tiles into `assets/_generated/maps/` and re-exports the paintable piece templates to `assets/_generated/piece_templates/`. |
| `generate_stage1_room_art.gd` | Paints the Stage-1 room backgrounds (T1, T2, ...) into `assets/_generated/rooms/`. |
| `generate_playground_tilemap.gd` | Builds the playground tile set and tilemap scene. Saves through `save_keeping_uids.gd` and stamps uids last. |
| `paint_kingdom_tilemap.gd` | Paints the first room's throne-room floor into `content/tilesets/kingdom/tilemap.tscn`. Saves through `save_keeping_uids.gd` and stamps uids last. |
| `paint_zone_tilemaps.gd` | Carves the 72x40 kingdom board into `tests/fixtures/the_kingdom/tilemap.tscn`. Saves through `save_keeping_uids.gd` and stamps uids last. |
| `render_kingdom_map.gd` | Renders the whole kingdom to one image for review; needs a real renderer (no `--headless`) and `--write-movie`. |
| `generate_sfx.py` | Generates the placeholder SFX as mono WAV files into `assets/sfx/`. |
| `generate_music.py` | Generates the placeholder A-minor march loop into `assets/music/`. |
| `trace_knight_glyph.py` | Traces the knight glyph into the span tables `generate_chess_sprites.gd` uses (needs a font with U+265E and Pillow); `--rows N` sets how many sprite rows the head takes (the shipped knight is traced at 15). |

Never use the editor UID tool, the `update_project_uids` MCP tool, or a `ResourceLoader.load` plus
`ResourceSaver.save` loop to "fix" uids: on this project it added 0 uids, turned 38 more
references path-only and rewrote 587 non-uid lines (`docs/game-base-plan.md` 13.7).

## Placeholders: seed them, then list what is left

The owner supplies art and audio one file per thing (plan section 12 and the owner's direction of
2026-10-12), by overwriting a file whose name and role never change. Two tools and one manifest
make that safe:

```bash
"$G" --headless --path . -s tools/seed_placeholders.gd -- --check   # report what would be copied or recorded
"$G" --headless --path . -s tools/seed_placeholders.gd              # copy what is absent, record what is new
"$G" --headless --path . --editor --quit                            # import the copies, then commit them with their .import
"$G" --headless --path . -s tools/list_placeholders.gd              # the owner's TODO, by kind
```

`content/_placeholders.json` holds one line per stand-in with its `path`, `kind`, `id`, `sha256` and
`origin`. **A file is a placeholder if and only if its sha256 still equals the recorded one**, so overwriting
the file clears the flag with no other edit (a flag kept anywhere else would go stale). The seed tool
never overwrites a file and never re-records one that is already listed, so running it again after the
owner replaced a picture cannot turn the owner's art back into a "placeholder". A file that exists but
is in neither seed list is the owner's and is never recorded. To add a stand-in (a new room background,
a new enemy body, a new sound), add its row to `GENERATED_SEEDS` or `ADOPTED_PLACEHOLDERS` at the top of
`seed_placeholders.gd`, run the tool, import, and commit; `tests/content/test_placeholders_manifest.gd`
fails if a row is not recorded, a listed file is gone, or a tracked scene names `assets/_generated/`.
Measured on this tree at M1b: 25 placeholders (3 bodies, 4 icons, 1 pickup, 2 room backgrounds, 1 tile
atlas, 4 interface pictures, 9 sound effects, 1 music loop); overwriting one file moved the count from 25
to 24 still to replace and put "1 replaced by you" in the summary.

## Tools that save scenes: keep the uids

`ResourceSaver.save()` on an existing `.tscn`/`.tres` drops the header uid and the uid on every
`[ext_resource]` line (measured when the three tools below were migrated: seven room scenes name
`kingdom_tilemap.tscn` by its header uid). Running the stamper afterwards would not repair that: it
invents a NEW header uid. So `paint_kingdom_tilemap.gd`, `paint_zone_tilemaps.gd` and
`generate_playground_tilemap.gd` save through `save_keeping_uids.gd`
(`save_keeping_uid()` restores the previous header uid with `ResourceSaver.set_uid()`) and call
`stamp_uids_last()` once, last (it adds the `[ext_resource]` uids from their targets). Checked by
running each tool on the committed tree: the only diff left is the node's `unique_id` (Godot picks a
new random one on every save; harmless) and, for the playground scene, the dropped `load_steps` and a
renumbered `ext_resource` id. Run the editor import pass afterwards. A new tool that saves a scene
must do the same; `tests/architecture/test_tools_keep_uids.gd` fails if it calls
`ResourceSaver.save()` directly or forgets `stamp_uids_last()`.

`generate_sfx.py`, `generate_music.py` and the PNG generators never touch a scene or resource (they
write `.wav` and `.png` only), so they need no stamping.

## stamp_uids.gd

```bash
"$G" --headless --path . -s tools/stamp_uids.gd -- --check      # report; exit 1 if anything would change
"$G" --headless --path . -s tools/stamp_uids.gd                 # stamp; --verbose lists every changed line
"$G" --headless --path . --editor --quit                        # then register the new uids
```

Pass 1 adds `uid="uid://..."` to every `.tscn`/`.tres` header that lacks one. Pass 2 adds `uid=`
before `path=` on every path-only `[ext_resource]` line, taking the uid from the target's header,
its `<file>.uid` (`.gd`) or the `uid=` of its `<file>.import` (png, wav, svg). Only header and
`ext_resource` lines are ever edited, so the diff is exactly one changed line per stamped line.
Exit codes: apply 0 = fully stamped, 2 = a reference could not be resolved; `--check` 0 = clean,
1 = something to do. Skips `.godot/`, `.git/`, `.claude/`, `addons/` and folders with a `.gdignore`;
absent folders are fine, and `tests/fixtures` is scanned (the kingdom fixture is a real scene).

Measured on a scratch copy of the tree at M1a (the numbers the plan quotes):

| | |
|---|---|
| scene/resource files scanned | 66 |
| headers without uid, stamped | 49 |
| `ext_resource` lines | 251 total, 213 path-only, 213 stamped, 0 missing |
| stamped by target type | gd 57, tres 57, tscn 46, png 31, wav 21, svg 1 |
| files changed | 54 |
| diff (`git diff --numstat --minimal`) | +262 -262 = 49 + 213, every changed line is a header or an `ext_resource` line that only gained ` uid="..."` |
| second run | `--check` exit 0 "CLEAN", re-apply changes nothing |
| after `--editor --quit` import | 0 errors, full suite green (`TESTS COMPLETE: 0 failure(s)` plus six runtime `PASS`) |

(Plain `git diff --numstat` reports 273 because git's default diff pairs up the blank line between
the header and the first `ext_resource` block; `--minimal` and `--patience` give 262.)
M1a shipped the tool; M1b step 1 ran it over the real tree (the numbers above, exactly) and committed the result alone. `tests/architecture/test_no_path_only_ext_resource.gd` now enforces zero path-only lines, so a scene saved without the stamper fails the suite.

## move_res.py

```bash
tools/move_res.py --dry-run content/enemies/old_id content/enemies/new_id   # print every change, touch nothing
tools/move_res.py content/enemies/old_id content/enemies/new_id             # git mv + rewrite + log
tools/move_res.py --import-pass SRC DST                               # then run the import pass (GODOT_BIN)
tools/move_res.py --rewrite-only SRC DST                              # the move was already done by hand
tools/move_res.py --rewrite-only path/to/owner_edit.tscn              # replay the whole move log onto a late file
tools/move_res.py --rename-action skill_1 skill_slot_1                # InputMap action rename
tools/move_res.py --self-test                                         # 27 checks in a throwaway git repo
```

* Rewrites `res://` strings in `*.gd *.tscn *.tres *.cfg *.md project.godot`, and also `*.import`
  (`source_file=`), `*.gdshader`, `*.json`, `*.sh`, `*.yml` and `tests/baselines/*.txt` (the dump
  baselines name texture and script paths, so they follow a move). `uid://` is never touched.
  A move that renames the folder an id lives in (`content/enemies/<id>/`) also changes what a test
  that builds a path from the id sees: grep for format strings (`"%s"` paths) afterwards, because only
  whole `res://` paths are rewritten.
* Matches whole path segments: moving `res://old/folder` leaves `res://old/folder_old/`
  and `res://old/folder.tres` alone. CRLF files keep their line endings.
* Not rewritten on purpose: `docs/archive/`, `.godot/`, `.git/`, `addons/`, nested `.claude/worktrees/`,
  `move_res.py` itself and its log. Prose that names paths without `res://` is not touched.
* Each real move appends `old<TAB>new` to `tools/move_res_log.tsv` (created on first use; commit it with
  the move). `--rewrite-only FILE...` replays that log, in order, onto files that arrive late, which is
  how the owner's edits to old-layout scenes are fixed after a rebase (plan 13.6).
* Refuses an existing destination, a missing source, a sidecar on its own, `.git`/`.godot`/`addons`,
  and moving a folder into itself.

M1b's real moves (130 lines, oldest first) are in `tools/move_res_log.tsv`, and
`docs/migration-notes.md` explains them. The paths in the next table are the pre-migration ones: it
records the proof made at M1a on a scratch copy (a separate throwaway git repo, never the worktree),
stamped tree:

| Step | Result |
|---|---|
| `--dry-run resources/difficulty content/difficulty` | listed 7 lines in 7 files, nothing written |
| real move of `resources/difficulty` (leaf folder) | `git mv` recorded as a rename, 7 `ext_resource` paths rewritten, import pass 0 errors, suite green |
| real move of `resources/rules` | 7 lines in 3 files including the `load("res://...")` literal in `tests/run_tests.gd`, suite green |
| control: bare `git mv resources/objectives` on the stamped tree | suite still green: the stamped uids keep scenes resolving, which is why M1b stamps first |
| control: bare `git mv resources/enemies` (string literals in `.gd` not rewritten) | suite RED: `unarmed_attack` on Nil, `max_health` on Nil, `Array` index error in 3 suites |
| same move with `move_res.py resources/enemies content/enemies` | 22 lines in 11 files, import 0 errors, suite green |

## dump_world.gd and the baselines

```bash
"$G" --headless --path . -s tools/dump_world.gd -- --room=t1                          # print one room
"$G" --headless --path . -s tools/dump_world.gd -- --write-baselines                  # rewrite tests/baselines/dump_*.txt
"$G" --headless --path . -s tests/architecture/test_dump_baselines.gd                 # compare (enforcing)
```

The dump mirrors `shell/game_root.gd` (`_make_world` + `_boot_zone`): the same six systems in the same order,
the player view on the room's `start` entry marker, then `EcsBoot.boot` with no taken pickups and no
opened gates, then 120 manual ticks of 1/60 s with the player idle. It skips `WorldState`, the HUD, the
board overlay and audio on purpose: they depend on the save file or on real time. Output sections:
`[grid]`, `[board]` (ASCII map), `[entities at boot]` (every component field), `[entities after 120 ticks]`,
`[nodes]` (sorted paths with type, script, position) and `[textures]` (sorted sprite and tile-set paths).
Floats print with 4 decimals; engine-generated node names (`@Node2D@12`) lose their counter; nodes under an
`ActorView` print structure only (animation drives their transforms).

Baselines for `t1 t2 t3 t4 b1 h1` live in `tests/baselines/dump_<room>.txt`. Determinism check at M1a:
`--write-baselines` run twice in fresh processes gave six identical files, and each room dumped alone in its own
process equals the in-sequence output. Mutation check: moving the T3 pawn one cell in the scene made
`test_dump_baselines.gd` fail with the changed lines printed (board row, entity cell, node position) and
exit code 1. After an intended change, regenerate and review the baseline diff in the same commit.
A fresh checkout needs `tools/bootstrap_worktree.sh` first (the rooms name generated textures).

## Real-renderer boot in the agent sandbox (plan G7, risk 28)

**Answer: YES.** A non-headless boot of the main scene works here.

Command (from the project root, Godot 4.6.3, macOS, windowed project settings left as they are):

```bash
HOME=/tmp/upg-m1a-tools "../Godot.app/Contents/MacOS/Godot" --path . --quit-after 180
```

Exact output (stdout and stderr), exit code 0, about 7 s wall clock (`--quit-after` counts frames: 180 of them):

```
Godot Engine v4.6.3.stable.official.7d41c59c4 - https://godotengine.org
OpenGL API 4.1 Metal - 90.5 - Compatibility - Using Device: Apple - Apple M5
```

Pixels were proven too, not just a clean exit: a scratch script (not committed) instanced the main scene,
waited 60 frames and saved `root.get_texture().get_image()`. The result was a 3420x1923 image with 1059
distinct sampled colours showing the T1 room, the pawn, the fallen king and the full HUD. The renderer is
`gl_compatibility` on `Apple M5`.

Caveats for G7: this was the owner's Mac with a display attached. `window/size/mode=3` makes the game
open fullscreen, so every real-renderer run flashes the screen for its duration; a CI or remote sandbox
without a GPU or window server has not been tested and must re-run this exact command to know. The
tolerance for a perceptual compare is not recorded here: G7 stays an owner-review artefact until a
reference frame exists. Headless runs (everything else in this folder) never need a renderer.
