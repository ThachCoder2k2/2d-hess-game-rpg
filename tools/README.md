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

Generated art is gitignored, so a new checkout has scenes whose textures do not exist yet and no
class registry. The script imports once as a warm-up (so the audio autoload loads; on a fresh clone it
prints "Failed loading resource" for the room art that does not exist yet, which it reports but
tolerates), runs the four generators, imports again, and exits non-zero on any `ERROR`,
`SCRIPT ERROR` or `Parse Error` from the generators or from that second import. About 50 s.
Verified on a brand-new `git clone` of the branch: after the script, the whole suite and every new
test pass and `git status` is clean.

## Every tool, one line each

| Tool | What it does |
|---|---|
| `bootstrap_worktree.sh` | Makes a fresh clone or worktree test-ready: import pass, the four generators below, import pass. |
| `run_all_tests.py` | The verification gate (`/verify`): import pass, every suite in its own bounded process, baseline-label check. `--strict`, `--only`, `--list`, `--verbose`. `--self-test` checks the gate itself (canned hangs, script errors, FAIL lines, missing verdicts, vanished labels, a fake Godot) in about 5 s with no Godot. |
| `stamp_uids.gd` | Text-level UID stamper (never calls `ResourceSaver`): adds `uid=` to uid-less scene/resource headers and to path-only `ext_resource` lines. `-- --check` only reports and exits 1 if anything would change. Idempotent. |
| `move_res.py` | `git mv` a file or folder with its `.uid`/`.import` sidecars and rewrite every `res://` string that pointed at it. `--dry-run`, `--rewrite-only`, `--rename-action`, `--import-pass`, `--self-test`. |
| `dump_world.gd` | Boots a room headless, runs N manual ticks, prints the sorted node paths, texture paths and entity cells/components. `--room=t1`, `--write-baselines`, `--list`. |
| `world_dumper.gd` | The dump logic, shared by `dump_world.gd` and `tests/architecture/test_dump_baselines.gd` (a helper, not a command; no `class_name`). |
| `generate_chess_sprites.gd` | Bakes the chess-piece sprites (art language v13) to `assets/sprites/generated/chess/`. |
| `generate_kingdom_tiles.gd` | Bakes the room materials as pixel tiles, a contact sheet and a manifest (same art language as the pieces). |
| `generate_demo_map.gd` | Draws the pawn-scale bedroom demo world with the kingdom tiles into `assets/sprites/generated/maps/`. |
| `generate_stage1_room_art.gd` | Paints the Stage-1 room backgrounds (T1, T2, ...) into `assets/sprites/generated/rooms/`. |
| `generate_playground_tilemap.gd` | Builds the playground tile set and tilemap scene. Uses `ResourceSaver`: run `stamp_uids.gd` after it. |
| `paint_kingdom_tilemap.gd` | Paints the first room's throne-room floor into `objects/world/kingdom_tilemap.tscn`. Uses `ResourceSaver`: run `stamp_uids.gd` after it. |
| `paint_zone_tilemaps.gd` | Carves the 72x40 kingdom board into `objects/world/kingdom_world_tilemap.tscn`. Uses `ResourceSaver`: run `stamp_uids.gd` after it. |
| `render_kingdom_map.gd` | Renders the whole kingdom to one image for review; needs a real renderer (no `--headless`) and `--write-movie`. |
| `generate_sfx.py` | Generates the placeholder SFX as mono WAV files into `assets/sfx/`. |
| `generate_music.py` | Generates the placeholder A-minor march loop into `assets/music/`. |
| `trace_knight_glyph.py` | Traces the knight glyph into the span tables `generate_chess_sprites.gd` uses (needs a font with U+265E). |

Never use the editor UID tool, the `update_project_uids` MCP tool, or a `ResourceLoader.load` plus
`ResourceSaver.save` loop to "fix" uids: on this project it added 0 uids, turned 38 more
references path-only and rewrote 587 non-uid lines (`docs/game-base-plan.md` 13.7).

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
M1a ships only the tool; M1b commits the stamped tree.

## move_res.py

```bash
tools/move_res.py --dry-run resources/difficulty content/difficulty   # print every change, touch nothing
tools/move_res.py resources/difficulty content/difficulty             # git mv + rewrite + log
tools/move_res.py --import-pass SRC DST                               # then run the import pass (GODOT_BIN)
tools/move_res.py --rewrite-only SRC DST                              # the move was already done by hand
tools/move_res.py --rewrite-only scenes/owner_edit.tscn               # replay the whole move log onto a late file
tools/move_res.py --rename-action skill_1 skill_slot_1                # InputMap action rename
tools/move_res.py --self-test                                         # 27 checks in a throwaway git repo
```

* Rewrites `res://` strings in `*.gd *.tscn *.tres *.cfg *.md project.godot`, and also `*.import`
  (`source_file=`), `*.gdshader`, `*.json`, `*.sh`, `*.yml` and `tests/baselines/*.txt` (the dump
  baselines name texture and script paths, so they follow a move). `uid://` is never touched.
* Matches whole path segments: moving `res://resources/difficulty` leaves `res://resources/difficulty_old/`
  and `res://resources/difficulty.tres` alone. CRLF files keep their line endings.
* Not rewritten on purpose: `docs/archive/`, `.godot/`, `.git/`, `addons/`, nested `.claude/worktrees/`,
  `move_res.py` itself and its log. Prose that names paths without `res://` is not touched.
* Each real move appends `old<TAB>new` to `tools/move_res_log.tsv` (created on first use; commit it with
  the move). `--rewrite-only FILE...` replays that log, in order, onto files that arrive late, which is
  how the owner's edits to old-layout scenes are fixed after a rebase (plan 13.6).
* Refuses an existing destination, a missing source, a sidecar on its own, `.git`/`.godot`/`addons`,
  and moving a folder into itself.

Proven on a scratch copy (a separate throwaway git repo, never the worktree), stamped tree:

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

The dump mirrors `scripts/main.gd` (`_make_world` + `_boot_zone`): the same six systems in the same order,
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
