# AI Workflow Rules - The Unbound Pawn

This file is the operating guide for AI assistants working on this Godot project. Read it
before planning or editing. It is the workflow and the owner's rules; the binding technical
rules are in `CLAUDE.md`, and the structure of the code is in `docs/ARCHITECTURE.md`.

## Read first, every session

1. `CLAUDE.md` — the binding rules (loaded automatically).
2. `docs/where-we-are.md` — **the status page**: what stage the project is at, what each
   area has actually reached, the roadmap and the decisions only the owner can make.
3. `docs/game-base-plan.md` — **the build plan**: what "the complete base" is, the decisions
   taken, the milestones M1a-M14 and the owner gates OG0-OG4.
4. `task_plan.md` (phase index), `progress.md` (log), `findings.md` (durable facts).
5. `git status --short` — never clobber the owner's in-progress editor changes.

Authority order when documents disagree (from `docs/game-base-plan.md`):

1. The owner's directions of 2026-10-12 (quoted below).
2. `CLAUDE.md`. The owner approved its amendments at gate OG0 (2026-10-12, recorded in
   `progress.md`) and M1b applied them; `docs/claude-md-diff.md` keeps the old and new lines.
3. `docs/ecs-conversion-plan.md`.
4. `docs/game-base-plan.md`.
5. Older docs. The code is the final witness of how things work today.

## Project Direction

- The simulation is a **full ECS** (`ecs/`; owner decision 2026-07-19, see
  `docs/ecs-conversion-plan.md`). State is pure-data components, decisions are systems,
  scenes are spawn data plus puppet views. `docs/ARCHITECTURE.md` describes the code as built.
- Build **editor-first**: reusable behavior in scripts; game content in scenes, Resources
  (`.tres`), AnimationPlayers/AnimationTrees, markers and Inspector fields. A new enemy,
  weapon, attack or room is a data edit, never new hardcoded content in a script.
- `shell/game_root.gd` (the old `main.gd`) is a thin bridge between the ECS and presentation.
  Do not add room content or gameplay decisions to it.
- Preserve the current playable slice after every change.

### The owner's directions of 2026-10-12 (quoted from `docs/game-base-plan.md` section 0)

These are translated from Vietnamese and are the only verbatim owner texts of that date.
They authorise building the whole base and restructuring the code and folders. They do
**not** pre-approve the "ask the owner first" triggers below (see "Gates and defaults").

> **#1** "A game is not only gameplay — it must tell a story. Build ONE complete base with
> everything; I will do the art and upgrade the story myself. Make it as perfect as possible
> before I jump in. Research human emotions when playing games. I trust you."
>
> **#2a** "The gameplay must also have a proper PROGRESSION path and proper SKILLS."
>
> **#2b** "Arrange the code and folders so I can jump in and handle things WITHOUT changing
> too much — based first of all on the ECS design pattern."

What this means for an agent: build the complete, tested, data-driven base described in
`docs/game-base-plan.md`; fill it with placeholder content the owner will replace by hand
(art, prose, music, tuning); keep code and folders arranged so the owner can change content
without touching code.

## Folder Ownership

The top-level folders are layers; `docs/ARCHITECTURE.md` has the tree and the table of which
layer may name which (`tests/architecture/test_dependency_edges.gd` enforces it).

- `content/` — **the owner's folder**: data, art, audio and words. Zero `.gd` files
  (test-enforced). A folder name is the id; a leading underscore (`_shared`) is not an id.
  `enemies/<id>/` (`enemy.tres`, `body.png`, the enemy's own sub-resources, `_shared/` for the pieces
  several enemies use), `rooms/<id>/room.tscn`, `rules/<id>/page.tres`, `skills/<id>/`,
  `pickups/<id>/`, `player/`, `difficulty/`, `world/world.tres`, `tilesets/<kit>/`,
  `feel/piece_sizes.tres` (how big each kind of piece is inside its cell).
  `content/_placeholders.json` lists which art and audio are still stand-ins.
- `schema/` — Resource classes (`EnemyDefinition`, `MovementConfig`, `AttackPattern`, ...), one
  class per file, no behaviour beyond `validate()`-style checks.
- `ecs/` — the simulation: `core/` (`EcsWorld`, `EcsGrid`, `EcsSystem`, `WorldFlags`,
  `InputSnapshot`, `HudSnapshot`, `PlayerSnapshot`), `components/` (`ecs_components.gd`, frozen; every new component
  its own file, such as `tuning.gd`), `systems/<folder>/`, `events/` (`events.gd` declares every
  event, `commands.gd` every request presentation may push) and `schedule/` (one file per stage of
  the tick plus `schedule.gd`: the order the systems run in is data there and nowhere else). No art,
  prose or tuning numbers.
- `authoring/` — things dragged into a scene: `entity_components/` (`EntityComponent` nodes),
  `markers/`, `room_encounter`, and the baker (`ecs_boot.gd` with its `EcsBootOptions`,
  `ecs_actor_factory.gd`). No logic.
- `presentation/` — how the world is shown: `views/` (`ActorView`, pickup views, and
  `views/actors/`: `actor_view_base.tscn`, the one actor view, plus the thin scenes inheriting it), `ui/hud/`, `ui/codex/`, `board/`, `camera/`, `audio/`. Reads events;
  never decides.
- `shell/` — the game around the game: `game_root.tscn/.gd` (the one game scene and its bridge),
  `content/` (`ContentDb`, the content registry) and `save/world_state.gd`.
- `assets/` shared raw art and audio (`tiles/`, `ui/`, `sfx/`, `music/`, `map_pieces/`; the
  gitignored `_generated/` is generator output only) · `tools/` build scripts and generators ·
  `tests/` headless tests · `docs/` documentation.

Do not move authored room layout or gameplay placement into scripts. Do not move or rename a
file by hand: `tools/move_res.py` does it with the sidecars and every `res://` string
(`tools/README.md`). The rest of the plan's tree (`content/story|audio|ui|...` and the rest of
`content/feel/`) appears with the milestones that need it (`shell/content/` and
`content/feel/piece_sizes.tres` came with M2; `ecs/events/` and `ecs/schedule/` with M3a).

## Current Priority

The base is built milestone by milestone from `docs/game-base-plan.md` section 15.
**M1a (safety net and tooling), M1b (folder migration), M2 (content registry and actor collapse) and
M3a (runtime seams) are done and wait in `human_review`**. M1b moved every script, scene and resource into the new tree with no
gameplay change (the strict runner stayed green after every move, the six room dumps changed only by path
strings), applied the `CLAUDE.md` amendments the owner approved at OG0, and added the placeholder tools.
M2 added `ContentDb` (content by id, two validators), `PlayerDefinition` (`content/player/player.tres`),
collapsed the four 353-line actor scenes into one `actor_view_base.tscn` plus thin scenes, and built the
owner's decision of 2026-10-12 that a piece is smaller than its cell (`content/feel/piece_sizes.tres`, the
generated chess family drawn to it, `tools/render_actor_preview.gd`, `test_pieces_inside_cell`). M3a landed
every shared field and seam once, with no gameplay change (the tick order as data in `ecs/schedule/`, the
declared events and the commands channel, the input, HUD and player snapshots, each room's own origin and the
camera framing it, the grid's cell kinds, leaps, rays and cached pathing, and a per-room tick budget test). Next
is **M3b** (the split of `game_root.gd` and the save service). The owner can browse `content/`, run `tools/list_placeholders.gd` for the art
and audio TODO, open `assets/_generated/previews/pieces_in_cells.png`, and read `docs/OWNER_GUIDE.md`
(section 6 is the in-cell rule, in Vietnamese).
Current status of every area, and what is waiting on the owner, lives in
`docs/where-we-are.md`. Do not start a broad new phase while the current one has a broken
playable slice.

## Collaboration Model

AI assistants do the repeatable implementation work and prepare editor-ready structures. The
human owner makes taste, feel, layout and final approval decisions inside Godot Editor.

AI owns:
- Scripts, Resources, scene scaffolds, tests, migration bridges, verification, commits and
  technical documentation.
- Creating first-pass `.tscn` files that open correctly in Godot and expose useful Inspector
  fields.
- Keeping the project playable after every milestone.
- Updating planning files and explaining what changed.

Human owner owns:
- Final play-feel approval: movement speed, attack timing, telegraph readability, damage feel
  and room difficulty.
- Final editor layout approval: room shape, enemy placement, pickup placement, blockers,
  props and camera framing.
- Final art/audio taste: sprites, palette, animation style, sound choices, music mood and UI
  personality. Art direction is human-owned: hand off for approval, never finalize it. No AI
  art is ever finalized.
- Story tone approval: child voice, fourth-wall moments, dialogue wording and ending emotion.

Ask the human owner before:
- Replacing the art direction.
- Changing core controls.
- Changing the intended 2-hour scope.
- Removing an existing mechanic.
- Making a destructive migration that cannot be easily compared against the current playable
  slice.
- Adding a dependency (an addon or plugin).

Do not ask before:
- Adding tests.
- Creating editor-friendly wrappers around existing runtime behavior.
- Moving hardcoded values into exported fields or Resources while preserving defaults.
- Fixing crashes, parser errors, import errors or regressions.
- Updating planning and workflow docs.

### Gates and defaults

`docs/game-base-plan.md` section 2.3 lists the places where the base plan touches the "ask
first" triggers above (core controls, scope, removed mechanics, the folder migration,
departures from the 2026-07-28 cut). The owner confirmed the folder migration, the control and
rule changes and cleared rooms at OG0; the other rows stay defaults until a later gate. The plan
gives the owner cheap vetoes at five gates:

| Gate | When | The owner checks |
|---|---|---|
| OG0 | end of M1a, before M1b | the `CLAUDE.md` diff, the standing-rule table, the migration plan (**answered 2026-10-12**: the move and the amendments, cleared rooms stay cleared, English story source, the control changes; verbatim in `progress.md`) |
| OG1 | after M5 | plays title to credits through stub rooms: does the skeleton feel right? |
| OG2 | after M7b | the feel: Sword, Pencil, Rule Step, movement lock, stagger, buffer expiry |
| OG3 | after M9 | Stage 1 plus Toybox, the first complete district |
| OG4 | after M13 | the whole game, before handoff polish |

If the owner does not respond, agents continue on the stated defaults and log the assumption
in `progress.md`.

## Human Editor Work Checklist

Some work should intentionally happen inside Godot Editor. When a phase reaches one of these
points, stop and hand the project to the human owner for review or tuning.

Room and encounter review:
- Open the room `.tscn`.
- Move enemy spawn points (parked `ActorView` nodes) until the first 10 seconds feel readable.
- Move weapon pickups so they create interesting risk, not random clutter.
- Check blockers and paths for unfair traps.
- Play the room at least three times: cautious, aggressive and intentionally sloppy.

Player feel review:
- Tune the player's step duration, repeat delay, skill cooldown, Courage and invulnerability
  (`content/player/player.tres`, a `PlayerDefinition`) and the attack recovery (the `AttackProfile`
  `.tres` files in `content/skills/`).
- Confirm `Shift + direction`, `Space` and `Q` still feel natural.
- Decide whether the pawn should feel heavier, sharper or more frantic.

Enemy feel review:
- Watch each enemy alone, then in a group.
- Confirm attack tells are visible before damage.
- Confirm the Knight feels like a real threat without feeling unfair.
- Approve each new enemy type before it is used in many rooms.

Art/audio review:
- Replace placeholder sprites/sounds only when the gameplay object is stable.
- Check readability at 640x360 before judging beauty.
- Prefer strong silhouettes and readable colors over decorative detail.
- Approve each art batch in-engine, not only from asset previews.

Narrative review:
- Read dialogue in context while moving through the room.
- Keep child-imagination lines short enough to read during play.
- Approve fourth-wall moments before expanding them into later rooms.

Release review:
- Play exported builds, not only editor runs.
- Check keyboard/controller settings.
- Check audio volume on headphones and speakers.
- Watch for save/checkpoint bugs across app restarts.

### Handoff Format For Human Editor Work

When editor work is needed, give the human owner the scene path to open, the exact
properties or nodes to tune, the desired feel target, and a short checklist for what to
report back, in this shape:

```text
Open: <scene path>
Tune: <node/property list>
Goal: <desired gameplay/art/story feel>
Try: <short playtest checklist>
Tell me: <specific feedback needed>
```

Keep the handoff short enough that the owner can act on it immediately.

## Planning Files

Use the persistent planning files as project memory:

- `docs/where-we-are.md` — the status page: stage, per-area status, risks, roadmap, the
  owner's open decisions.
- `docs/game-base-plan.md` — the build plan: decisions, milestones, risks, gates.
- `task_plan.md` — phases, statuses, decisions and errors.
- `findings.md` — technical discoveries and design conclusions.
- `progress.md` — completed work and verification results.
- `docs/ARCHITECTURE.md` — what the code is and how it runs; the reading order.
- `docs/coding-standards.md` — naming, member order, typing and ECS conventions.

Rules:
- Read `task_plan.md` before starting any multi-step work.
- Update `progress.md` after meaningful changes (what, why, verification, commit hash).
- Update `findings.md` when you discover a durable design or technical fact.
- Update phase status in `task_plan.md` when a phase starts or completes.
- Log errors in `task_plan.md` instead of silently retrying the same failed approach.
- Never write "owner approved" unless you paste the owner's exact sentence and its date.
  Agent self-review is not owner review.

## Phase-Gate Workflow

Every item moves through the owner's six steps, and none is skipped:

```text
1 plan  ->  2 owner approves  ->  3 build  ->  4 verify  ->  5 owner plays and reviews  ->  6 accepted
```

Every major phase follows this loop (`/milestone` runs it):

1. Re-read `CLAUDE.md`, this file, `docs/where-we-are.md`, `task_plan.md` and recent
   `progress.md`.
2. Define the smallest playable milestone for the phase and write it down.
3. Build editor-visible scenes and resources first, with scripts only where behavior is
   needed.
4. Preserve compatibility with the current playable slice.
5. Add or update automated tests for behavior and scene wiring.
6. Run `/verify`: headless tests, editor import and `git diff --check`.
7. Commit (explicit paths, one logical change) and push the technical milestone.
8. Hand off any editor tuning checklist to the human owner (Open/Tune/Goal/Try/Tell me).
9. Record the owner's feedback in `findings.md` or `progress.md`, verbatim and dated.
10. Iterate until the phase acceptance gate is met. Where the plan names an owner gate
    (OG0-OG4), stop at it.

Do not start a broad new phase while the current phase has a broken playable slice.

## Editor-First Implementation Rules

- Prefer `.tscn` scenes for rooms, HUD, markers, actor views and reusable effects.
- Prefer typed `.tres` Resources for configurable data: enemy definitions, movement, attacks,
  decisions, weapons, difficulty, room objectives, the Book of House Rules and the world graph.
- Prefer exported variables for values designers tune in the Inspector.
- Prefer `EntityComponent` nodes (`authoring/entity_components/`) when per-instance data belongs
  to an actor and should stay visible in the scene tree. They hold Inspector data and one
  `apply()`; `EcsBoot` bakes them into the entity at spawn. They hold zero logic.
- Prefer direct room-art nodes for first-pass room readability (`RoomArt/TileMap`,
  `RoomArt/GridLines`, `RoomArt/SetDressing`) over runtime-only drawing. Painted tiles with
  `solid = true` custom data are the walls.
- Keep runtime overlays separate from authored art. `PrototypeBoard` draws telegraphs, hit
  flashes and debug paths; room floors and props live in the room scene.
- Keep gameplay placement tied to marker or view nodes: if a designer can move something that
  affects play, the moved node is the source `EcsBoot` reads.
- The simulation is ECS and `CLAUDE.md` is binding: new state is a pure-data component; a
  decision is a system; only `ViewSyncSystem` touches nodes; presentation consumes
  `drain_events()` and never decides gameplay. Do not reintroduce node-based gameplay
  components or per-enemy subclasses.
- Research before building any new mechanic, in this order: (1) a built-in node or engine
  feature that already supports it (Timer, Tween, AnimationPlayer, Area2D signals,
  TileMapLayer, AStarGrid2D, Camera2D, CanvasLayer, UI containers); (2) a proven maintained
  addon — ask the human owner before adding a dependency; (3) only then a custom script,
  stating in the commit why neither fit. Never re-implement what a node already does. See
  `docs/coding-standards.md` "Built-in nodes first".
- Use self-documenting names. A name must convey what it holds or does without reading the
  body: dictionaries state their direction (`entity_by_cell`, `cell_by_entity`), values state
  their semantics (`state_time_left`, `observe_delay`), and cryptic or abbreviated names are
  avoided. Add a `##` doc comment to every non-obvious data structure (key -> value for
  dictionaries). Before renaming, survey `.tscn`/`.tres` for serialized `@export` names and
  `get("name")` string access; those break silently.
- Shared Resource assets are immutable at runtime; `duplicate(true)` per-instance mutable
  weapon or profile data.
- Never duplicate a value in both code and a `.tres`; the Resource is the truth.
- Do not add `_draw()` for actor or pickup bodies. They are `Sprite2D` plus `AnimationPlayer`.
  Overlays (board telegraphs, debug, grid lines) may use `_draw()`.
- Never hand-edit a TileMap's `tile_map_data` (a binary blob); use a `tools/` paint script.
- Never use `ResourceSaver` to re-save existing scenes or resources; it drops UIDs and
  rewrites headers. A tool that must save a scene goes through `tools/save_keeping_uids.gd`.
- Art and audio the owner supplies are swapped by overwriting a file whose name and role never
  change (`body.png`, `icon.png`, `background.png`). Stand-ins are tracked files in `content/` (or
  `assets/`), never in the gitignored `assets/_generated/`; `tools/seed_placeholders.gd` records
  them and `tools/list_placeholders.gd` lists what is left, by file hash.

## Full Game Completion Workflow

These gates describe the whole game, in the order the owner set them. Each gate ends with a
playable build or scene set that can be reviewed in the editor. The concrete build schedule is
`docs/game-base-plan.md` section 15 (milestones M1a-M14 and gates OG0-OG4), and where each
gate stands is in `docs/where-we-are.md`.

Gate 1: Editor foundation
- Main game scene opens cleanly.
- Player, enemy views, pickup, HUD, board and room encounter are real scenes.
- No critical content remains trapped only in `shell/game_root.gd`.

Gate 2: First playable encounter
- The first room is an authored room scene.
- Enemies, pickups, blockers, objective text and win condition are editable.
- The human owner approves room feel in Godot Editor.

Gate 3: Tutorial flow
- A small tutorial teaches move, turn, sword, telegraph dodge, thrust, pickup denial and reset.
- The tutorial uses editor-placed triggers and short text.
- The human owner confirms it teaches without feeling slow.

Gate 4: Enemy family
- Pawn, Knight, Bishop, Rook, Queen and King have Resources, a `piece_sizes.tres` row and a body picture
  (an actor scene only when the piece needs its own telegraph colour or facing mark; otherwise the
  one `actor_view_base.tscn` with `definition` set).
- Each enemy has a readable attack identity and editor-tunable timing.
- Each enemy is tested in a simple room before being mixed with others.

Gate 5: Weapons and skills
- Six to ten weapons/skills exist as Resources or scenes.
- Each has clear attack geometry, timing, cooldown/recovery and feedback.
- The human owner chooses which ones are kept for the 2-hour game.

Gate 6: World structure
- The short game has 5-7 room groups.
- Rooms connect through doors/exits or a simple world map (the world graph).
- Checkpoints and restart behavior are reliable.

Gate 7: Bosses
- Knight, Bishop, Rook, Queen and King boss scenes exist.
- Boss phases are authored through scene nodes, Resources or AnimationPlayers.
- Each boss tests a mechanic the player has already learned.

Gate 8: Narrative pass
- Child imagination framing is present from start to ending.
- Fourth-wall/player-help moments are placed as authored events.
- Dialogue is short, readable and approved in context.

Gate 9: Art and audio pass
- Placeholder shapes are replaced where it matters most.
- Sprites, UI, VFX, SFX and music support readability.
- Every attack, hit, pickup, death, room clear and low-health state has feedback.

Gate 10: Vertical slice build
- A 10-15 minute demo can be exported.
- It includes tutorial, one normal room, one weapon room, one boss, story framing and
  restart/win/lose flow.
- The human owner can send it to another player for feedback.

Gate 11: Full short game content lock
- All rooms, bosses, weapons, skills and narrative beats are implemented.
- No new core mechanics are added after this gate unless a playtest reveals a blocking issue.
- Bugs and tuning take priority over new ideas.

Gate 12: Release polish
- Save/checkpoint, settings, controller support, audio mix, builds, store assets, trailer
  capture and QA are complete.
- Exported builds are tested from a clean folder.
- The project is ready for Itch.io or Steam page preparation.

## Code Rules

- Keep gameplay logic cell-based through `EcsGrid`. Entities use grid registration, move
  reservations (reserve, then commit) and explicit cell occupancy rather than sprite overlap.
- Enemy attacks must telegraph before resolving. Damage checks the target's *current* cell
  against the cells locked at telegraph start, so stepping out dodges.
- One room-level attack token (`EcsWorld.attack_token_owner`) prevents unfair simultaneous
  enemy strikes.
- Enemy AI reads the hero's current or visibly reserved destination cell, never buffered
  input.
- Weapon attacks replace the enemy's chess-shaped attack while equipped; they do not change
  how the piece moves.
- Enemy locomotion is the piece's own chess law and is data: `MovementConfig.
  allowed_directions` lists the offsets of one move (Pawn cardinal, Bishop diagonal, Knight
  L). It is never hardcoded in a system.
- Runtime labels, HUD text and encounter logic identify enemies from `EnemyDefinition` data
  (`piece_name`, `id`), never from class checks.
- Damage is a request on `world.damage_events`, applied only by `HealthSystem`. Systems talk
  through components and events, never by calling each other.
- Persistent facts (taken pickups, opened gates, unlocks, current zone) live in the
  `WorldState` autoload and are fed back into `EcsBoot` at boot.

## Visual And Feedback Rules

- Combat readability is more important than decoration.
- Telegraphs must clearly show where and when an enemy will attack.
- Hits should have clear feedback: flash, shake, impact color, sound.
- Pickups should remain easy to notice on the board.
- Debug overlays must remain optional and toggled with `F3`.
- Gameplay code does not own presentation drawing. Actor and pickup bodies are sprites and
  animation clips in their scenes; `ViewSyncSystem` drives them from component data.
- New production visuals move toward sprites, AnimationPlayers/AnimationTrees, VFX scenes and
  audio nodes attached in `.tscn` files.
- Sound has three layers with one owner each: motion sounds are audio tracks inside the actor's
  clips; mixing lives in `default_bus_layout.tres`; event sounds with no clip go through the
  `SfxManager` registry, played only by the `shell/game_root.gd` bridge from drained events.
  Systems never play audio. Recipe: `/new-sound`.

## Testing And Verification

Run `/verify` (see `.claude/commands/verify.md`) after every behavior change. `/verify` is
the two tool self-tests (`python3 tools/run_all_tests.py --self-test` and
`python3 tools/move_res.py --self-test`), then `python3 tools/run_all_tests.py --strict`, then
`git diff --check` (and the import and `stamp_uids.gd --check` lines of `CLAUDE.md`). The runner does the
editor import pass, then runs every suite it finds by name: `tests/run_tests.gd`, the older
runtime tests (`ecs_runtime`, `ecs_combat`, `ecs_enemy`, `room_encounter_runtime`,
`encounter_hud_runtime`, `zone_travel_runtime`) and everything under `tests/` named
`test_*.gd` (`architecture/`, `audio/`, `bridge/`, `content/`, `support/`). A new suite needs
no edit to the runner. Never edit `tests/baseline_labels.txt` to turn the runner green: a
vanished label means a check disappeared; a renamed one goes in `tests/label_renames.txt`.
A change that moves a path a room prints (a texture, a script) changes `tests/baselines/dump_<room>.txt`:
regenerate it in the same commit and say in the message that only a path string changed; any other
dump change is a regression.
The other build tools (`stamp_uids.gd`, `move_res.py`, `dump_world.gd`, `bootstrap_worktree.sh`,
`seed_placeholders.gd`, `list_placeholders.gd`) are described in `tools/README.md`. By hand:

```bash
G="../Godot.app/Contents/MacOS/Godot"
HOME=/tmp/unbound-pawn-godot "$G" --headless --path . -s tests/run_tests.gd
HOME=/tmp/unbound-pawn-godot "$G" --headless --path . --editor --quit
git diff --check
```

Environment notes: the project path contains a space (quote it). Use an isolated writable
`HOME`. A new `class_name` needs one import pass before headless scripts can use it. macOS has
no `timeout`; bound a run with `perl -e 'alarm shift; exec @ARGV' 120 ...`. The macOS
certificate warning and the RID-leak error at the end of a `--write-movie` capture are
harmless. A fresh clone or worktree runs `tools/bootstrap_worktree.sh` first (the class
registry and the generated art; see `tools/README.md`).

## Git Rules

- Do not revert user changes. Preserve the owner's dirty files: stage explicit paths, never
  `git add -A` over uncommitted editor or UID changes.
- One logical change per commit, with a why-focused message. Branch first if on `main`.
- Commit every new `.gd` together with its `.gd.uid` sidecar.
- Commit and push completed milestones.
- Leave unrelated untracked or generated files alone unless the task explicitly owns them.
- Do not move or rename files by hand; use `tools/move_res.py` (plan section 13.3), one folder per
  commit, and commit new sidecars (`.gd.uid`, `.import`) with their files.

## Next Recommended Work

Follow `docs/where-we-are.md` section 5 for the order of work and `docs/game-base-plan.md`
section 15 for the milestone you are on. M1a, M1b, M2 and M3a are done; the next milestone is M3b (the
split of `game_root.gd`, the save service). Three dependency edges and six room references are still
undecided (listed in `tests/architecture/test_dependency_edges.gd` and `test_content_references.gd`);
the owner decides them before `tests/architecture/allowed_edges.txt` is frozen.
