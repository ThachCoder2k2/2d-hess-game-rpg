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
- **Editor-first, ECS runtime.** The simulation is full ECS (`ecs/` —
  read `docs/ecs-conversion-plan.md` first). Scenes are spawn data + puppet
  views (parked ActorViews become entities at boot); tuning lives in `.tres`.
  To add a new enemy/weapon/attack/room, edit data — never hardcode content in
  scripts, never put logic in views/components (systems own all decisions).
- **Where things go (the ECS map):**
  - New state → a pure-data class with a `KEY` const in its own file under
	`ecs/components/`. `ecs_components.gd` is frozen except for edits to existing classes.
  - New decision/behavior → a system in `ecs/systems/<phase>/` (with `const PHASE`
	naming its stage) plus one line in `ecs/schedule/<phase>.gd`;
	`test_schedule_complete` fails if a system file is unlisted. The tick order is data
	there and nowhere else: `shell/game_root.gd` and `tools/world_dumper.gd` both call
	`Schedule.populate`, so never add a system to either. ONLY `ViewSyncSystem` may
	touch nodes. Systems talk via components and the event/damage queues, never by
	calling each other or presentation. A new event is a const and a row in
	`ecs/events/events.gd` (payload keys documented; `test_events_declared`); damage and
	heals are queued only through `Events.emit_damage()` / `Events.emit_heal()`.
  - New editor-draggable component → extend `EntityComponent` in
	`authoring/entity_components/` (Inspector data + one `apply()`; `EcsBoot` bakes
	it at spawn; a node on an instance beats the definition; zero logic). Runtime
	data classes live in `ecs/components/`.
  - Animation transitions → the `AnimationTree` graph of `presentation/views/actors/
	actor_view_base.tscn`, the ONE actor view (the clips and the graph exist once there; the thin
	scenes that inherit it, player / black_pawn / knight_enemy / bishop_enemy, carry none, and a
	new enemy needs no scene: instance the base and set `definition`). States, transitions,
	xfades, at_end recovery are editor-owned; `ViewSyncSystem` only publishes
	conditions and fires `travel()` on event edges. Clips stay on the
	sibling `AnimationPlayer`; keyframe `SpriteRoot`, never `MotionRoot`. How fast a piece plays
	a clip is data (`VisualDefinition.clip_speed_scales`), not a copy of the clip.
  - The cell-to-cell slide is procedural (MovementSystem/ViewSync) — gameplay
	timing for the reserve→commit dodge window; never keyframe it.
  - Presentation consumes `drain_events()` and the read-only `HudSnapshot`. It
	writes the simulation only by pushing typed requests on `world.commands`
	(`world.push_command(Commands.set_flag(...))`, declared in `ecs/events/commands.gd`;
	`CommandSystem` applies them at the head of the next tick), never by setting
	components. (`world.commands` and the `HudSnapshot`, filled each tick by
	`HudSnapshotSystem`, exist since M3a; no script under `presentation/` names
	`EcsComponents` or `EcsWorld`, and `tests/architecture/test_dependency_edges.gd`
	fails if one does.)
  - Controls: `shell/input/input_poller.gd` is the only code that calls the `Input`
	singleton. It fills `world.input_snapshot` once per frame and a system reads that
	(`test_input_only_in_poller`); test a control rule by injecting an `InputSnapshot`
	(`tests/ecs/test_input_snapshot.gd`).
  - Sound (three layers, one owner each): motion sounds → audio tracks inside
	the actor's clips (keying its `AudioPlayer`, bus `SFX`); mixing →
	`default_bus_layout.tres` (Master ← SFX/Music/UI); event sounds with no
	clip (pickups, room clear, jingles, UI) → the `SfxManager` autoload's
	Inspector stream registry, played ONLY by the `shell/game_root.gd` bridge from
	drained events. Systems never play audio. The registry will be keyed from
	`content/audio/sound_bank.tres` (not built yet; today the keys are
	Inspector exports on `presentation/audio/sfx_manager.tscn`). Recipe: `/new-sound`.
- **Content is looked up by id.** `ContentDb` (`shell/content/`, a static class, no autoload) lists
  `content/<kind>/` folders; the folder name is the id. Do not load `content/` by path from `ecs/`,
  `authoring/` or `presentation/`: a scene names a resource by uid, the shell asks `ContentDb`. A new
  kind is one line in `ContentDb._ensure_kinds()`, a `validate()` on its class and a minimum in
  `tests/content/test_validate_all.gd`. The hero's tuning is `content/player/player.tres`.
- **A piece is smaller than its cell** (owner, 2026-10-12). Never exactly cell-sized, never
  taller than the cell, heights as in a real chess set (pawn lowest, king tallest). The numbers are
  data: `content/feel/piece_sizes.tres` (a box and a base line per kind of piece, 2 px margin to
  every cell edge, validated by `PieceSizeTable.validate()`). A `VisualDefinition` names its
  `piece_type` and `body_texture`; `ViewSyncSystem` stands the picture on the base line, so a body
  picture is drawn at scale 1 and is never scaled or offset in a scene. Everything an actor shows
  (pips, facing arrow, held weapon, telegraph aura, every clip's hop and shake) stays inside the
  cell: `tests/architecture/test_pieces_inside_cell.gd` measures it, and
  `tools/render_actor_preview.gd` draws it for the owner. Bosses are sized per boss (owner,
  2026-10-13, `docs/owner-decisions.md`): most fit one cell; the Rook Warden is 2x2 in phases 1-2,
  the Rule Engine 3x3 — a multi-cell piece stays inside its footprint with the same 2 px margin.
- **All art is 1x1 pixels** at the native 640x360 (owner, 2026-10-13): pieces, tiles, props,
  effects and UI alike. No 2x2 chunky blocks.
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
- **Folder ownership:** `content/` = the owner's data, art, audio and words (zero `.gd`) ·
  `schema/` = Resource classes · `ecs/` = simulation · `authoring/` = things dragged into
  scenes · `presentation/` = views and UI · `shell/` = app, save, flow · `assets/` = shared
  raw art and audio · `tools/` · `tests/`. Inside `content/` a folder name is the id and a
  leading underscore (`_shared`) is not an id. Which layer may name which is a table in
  `docs/ARCHITECTURE.md`, enforced by `tests/architecture/test_dependency_edges.gd`.
- **Preserve the playable slice.** Keep tests green after every change.
- **Preserve the human's dirty files.** Stage explicit paths in commits; never
  `git add -A` over uncommitted editor/UID changes. Art direction is human-owned —
  hand off for approval, don't finalize.
- **One logical change per commit**, why-focused message, on a branch if on `main`.

## Environment gotchas (learned the hard way)
- The project path contains a space (`.../Personal /Games/...`). Quote paths.
- Godot binary: `../Godot.app/Contents/MacOS/Godot` (parent dir; from a git worktree it is
  four levels up). Run headless with an isolated writable home: `HOME=/tmp/unbound-pawn-godot`
  (the runner takes `GODOT` and `UNBOUND_GODOT_HOME` instead).
- **A new `class_name` (global class) needs one `--editor --quit` import pass** before
  strict-typed scripts referencing it will parse headlessly. Run import, then tests.
- TileMap `tile_map_data` is a binary blob — do not hand-edit; use a `tools/` paint
  script (see `tools/paint_kingdom_tilemap.gd`).
- Headless `--write-movie` capture leaks RIDs at exit — that error is cosmetic.
- **Stamp UIDs before moving files** (`tools/stamp_uids.gd`; `-- --check` must say CLEAN),
  and **move or rename files only with `tools/move_res.py`** (`git mv` + `.uid`/`.import`
  sidecars + every `res://` string rewritten). Not by hand, not in the editor's FileSystem dock.
- **New `.gd` and PNG/WAV files need their `.gd.uid` and `.import` sidecars committed.**
  Run the import pass before committing; `test_sidecars_tracked` also fails on a stale or
  orphan sidecar.
- **Headless `ResourceSaver` resaves drop UIDs** (every reference turns path-only). A tool
  that saves a scene goes through `tools/save_keeping_uids.gd`.
- `assets/_generated/` is gitignored generator output: no tracked scene may name it. A
  stand-in picture reaches the game as a tracked copy in `content/` (`tools/seed_placeholders.gd`);
  `tools/list_placeholders.gd` prints which files are still stand-ins for the owner's art.

## Verify before you commit (run from project root)
```bash
python3 tools/run_all_tests.py --strict      # import pass + every suite + baseline labels
G="../Godot.app/Contents/MacOS/Godot"
"$G" --headless --path . --editor --quit     # import clean (no ERROR / Parse Error)
"$G" --headless --path . -s tools/stamp_uids.gd -- --check   # zero path-only ext_resource lines
git diff --check                             # whitespace
```
Expect `0 failed` and `GREEN` from the runner (every label in `tests/baseline_labels.txt`
still PASS or renamed in `tests/label_renames.txt`), and `STAMP UIDS: CLEAN`. `/verify`
runs this plus the tools' `--self-test`s. The old per-suite shell loop is gone: the runner
discovers every suite by name, so nothing needs editing when a suite is added.

## Workflows
Reusable slash-command workflows live in `.claude/commands/`:
- `/verify` — run the full check above (the self-tests, the strict runner, the diff check).
- `/new-enemy` — scaffold a data-only enemy under `content/enemies/<id>/` (zero new script).
- `/new-sound` — add a sound the structured way (clip track or event registry).
- `/milestone` — the phase-gate loop (read docs → smallest slice → build → verify →
  update planning docs → commit).
- Still to come, each with the milestone that creates its content kind: `/new-skill` (M7a),
  `/new-room` and `/new-beat` (M14). They do not exist yet.

## After meaningful work
Update `progress.md` (what + why + verification), bump phase status in `task_plan.md`,
add durable facts to `findings.md`. Then commit + push.
