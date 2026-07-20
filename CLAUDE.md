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
- **Editor-first, ECS runtime.** The simulation is full ECS (`scripts/ecs/` —
  read `docs/ecs-conversion-plan.md` first). Scenes are spawn data + puppet
  views (parked ActorViews become entities at boot); tuning lives in `.tres`.
  To add a new enemy/weapon/attack/room, edit data — never hardcode content in
  scripts, never put logic in views/components (systems own all decisions).
- **Where things go (the ECS map):**
  - New state → pure-data class + key const in `scripts/ecs/ecs_components.gd`.
  - New decision/behavior → a system in `scripts/ecs/systems/` ticked by the
	world; ONLY `ViewSyncSystem` may touch nodes. Systems talk via components
	and the event/damage queues, never by calling each other or presentation.
  - New editor-draggable component → extend `EntityComponent` in
	`scripts/ecs/components/` (Inspector data + one `apply()`; `EcsBoot` bakes
	it at spawn; a node on an instance beats the definition; zero logic).
  - Animation transitions → the actor scene's `AnimationTree` graph (states,
	xfades, at_end recovery are editor-owned; `ViewSyncSystem` only publishes
	conditions and fires `travel()` on event edges). Clips stay on the
	sibling `AnimationPlayer`; keyframe `SpriteRoot`, never `MotionRoot`.
  - The cell-to-cell slide is procedural (MovementSystem/ViewSync) — gameplay
	timing for the reserve→commit dodge window; never keyframe it.
  - Presentation (HUD/board/camera/main.gd) consumes `drain_events()` only;
	it never reaches into the simulation.
- **Research before building any new mechanic.** Mandatory order:
  1. Search Godot's built-in nodes/engine features for the capability
	 (Timer, Tween, AnimationPlayer, Area2D signals, TileMapLayer, AStarGrid2D,
	 Camera2D shake/limits, CanvasLayer, containers...). If one fits, use it.
  2. If no built-in fits, check for a proven, maintained addon/plugin
	 (Godot Asset Library / GitHub). Ask the human before adding a dependency.
  3. Only if neither fits, write it yourself in script — and say why in the
	 commit message. Never re-implement what a node already does.
- **Never duplicate a value** in both code and a `.tres`. The Resource is the truth.
- **Self-documenting names.** A name must say what it holds or does without opening
  the code: dictionaries state their direction (`actor_by_cell`, `cell_by_actor`),
  timers state their semantics (`state_time_left`, `observe_delay`), no cryptic or
  abbreviated names (`reservations` → `move_reservations`). Every non-obvious data
  structure gets a `##` doc comment (key → value for dictionaries). Before renaming
  anything, survey first: grep `.tscn`/`.tres` for serialized `@export` names and
  grep for `get("name")` string access — those break silently on rename.
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
for t in ecs_runtime ecs_combat ecs_enemy room_encounter_runtime encounter_hud_runtime; do
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
