# CLAUDE.md — agent rules for this project

The Unbound Pawn — a 2D grid-combat RPG in Godot 4.6. This file is loaded every
session. Read `AGENTS.md` for the full workflow, and `docs/ARCHITECTURE.md` +
`docs/coding-standards.md` for structure and conventions.

## Read first, every session
1. `AGENTS.md` — direction, folder ownership, phase-gate workflow, git rules.
2. `task_plan.md` — phase index + statuses (what's done, what's `human_review`/`deferred`).
3. `progress.md` / `findings.md` — detail + durable decisions.
4. `git status --short` — never clobber the human's in-progress editor changes.

## Non-negotiable rules
- **Editor-first.** Code is reusable behavior; content is scenes + `.tres`. To add a
  new enemy/weapon/attack/room, edit data — do not hardcode content in scripts.
- **Never duplicate a value** in both code and a `.tres`. The Resource is the truth.
- **No `_draw()` for actor/pickup bodies.** They are `Sprite2D` + `AnimationPlayer`.
  Overlays (board telegraphs, debug, grid lines) may use `_draw()`.
- **Folder ownership:** `scenes/` = entry/rooms/ui only · `objects/` = reusable prefabs
  · `resources/` = `.tres` data · `scripts/` = behavior · `assets/` = raw art ·
  `tools/` = build scripts.
- **Preserve the playable slice.** Keep tests green after every change.
- **Preserve the human's dirty files.** Stage explicit paths in commits; never
  `git add -A` over uncommitted editor/UID changes. Art direction is human-owned —
  hand off for approval, don't finalize.
- **One logical change per commit**, why-focused message, on a branch if on `main`.

## Environment gotchas (learned the hard way)
- The project path contains a space (`.../Personal /Games/...`). Quote paths.
- Godot binary: `../Godot.app/Contents/MacOS/Godot` (parent dir). Run headless with an
  isolated writable home: `HOME=/tmp/unbound-pawn-godot`.
- **A new `class_name` (global class) needs one `--editor --quit` import pass** before
  strict-typed scripts referencing it will parse headlessly. Run import, then tests.
- TileMap `tile_map_data` is a binary blob — do not hand-edit; use a `tools/` paint
  script (see `tools/paint_kingdom_tilemap.gd`).
- Headless `--write-movie` capture leaks RIDs at exit — that error is cosmetic.

## Verify before you commit (run from project root)
```bash
G="../Godot.app/Contents/MacOS/Godot"
HOME=/tmp/unbound-pawn-godot "$G" --headless --path . -s tests/run_tests.gd
for t in attack_runtime component_movement_runtime component_equipment_runtime \
         component_knight_movement_runtime room_encounter_runtime encounter_hud_runtime; do
  HOME=/tmp/unbound-pawn-godot "$G" --headless --path . -s tests/${t}_test.gd
done
HOME=/tmp/unbound-pawn-godot "$G" --headless --path . --editor --quit   # import clean
git diff --check                                                        # whitespace
```
Expect `TESTS COMPLETE: 0 failure(s)` + each runtime test `PASS`.

## Workflows
Reusable slash-command workflows live in `.claude/commands/`:
- `/verify` — run the full check above.
- `/new-enemy` — scaffold a data-only enemy (the Bishop recipe, zero new script).
- `/milestone` — the phase-gate loop (read docs → smallest slice → build → verify →
  update planning docs → commit).

## After meaningful work
Update `progress.md` (what + why + verification), bump phase status in `task_plan.md`,
add durable facts to `findings.md`. Then commit + push.
