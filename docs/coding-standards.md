# Coding Standards

Conventions for this project, written against the code as it is built today (a full
ECS runtime, see `docs/ARCHITECTURE.md`). Aligned with the official
[GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
and [project organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html)
best practices. Consistency matters more than any single rule. `CLAUDE.md` holds the
binding rules; where this file and `CLAUDE.md` disagree, `CLAUDE.md` wins.

## Naming

- `snake_case` for all files and folders (Godot 4 default; avoids case-sensitivity
  export bugs). No spaces in filenames.
- `PascalCase` for node names and `class_name`.
- A scene, its root node and its controller script share a name where a scene has one
  controller (`hud.tscn` -> root `HUD` -> `hud.gd` / `GameHud`).
- Suffix by role: `*_system.gd` (an `EcsSystem`), `*_component.gd` (an editor
  `EntityComponent` node, NOT runtime data), `*_marker.gd` (an editor-draggable room
  marker). Runtime component data classes live in `ecs/components/`: the existing ones are inner
  classes of `EcsComponents`, a new one is its own file with a `KEY` const. The folder tells
  the two kinds of "component" apart: `ecs/components/` is runtime data, `authoring/entity_components/`
  is editor nodes.
- Event types are past-tense `snake_case` `StringName`s (`step_finished`, `attack_landed`,
  `defeated`).

### Self-documenting names

A name must convey what it holds or does without opening the body. Favor clarity over
brevity; there is no prize for short names.

- **Dictionaries state their direction:** `entity_by_cell` (cell -> entity),
  `cell_by_entity` (entity -> cell), `item_by_cell`, `exit_by_cell`,
  `store_by_component`. Not `actors`, `cells`.
- **Values state their semantics:** `state_time_left` (counts down), `observe_delay`
  (matches the data field it loads), `move_reservations`. Not `time`, `t`, `res`.
- **No cryptic or abbreviated names.** `reservations` -> `move_reservations`; `archetype`
  (held a `DecisionConfig`) -> `decision_profile`.
- **Doc-comment every non-obvious data structure** with `##`. For dictionaries state
  key -> value and why it exists (see `EcsGrid`'s dictionaries and
  `EcsWorld.store_by_component`). These also surface in the editor help tooltip.

**Before renaming anything, survey first.** GDScript renames break silently in two places
the compiler will not catch:

1. `@export` names serialized into `.tscn` / `.tres` — grep the scene and resource files.
2. String property access `object.get("name")` / `object.set("name")` — grep for it
   (`EcsBoot` reads `board_size` and `grid_cell` this way, for example).

Rename the declaration only after confirming neither references the old name (or update
those in the same change), then run the full verify suite.

## GDScript member order

Order every script's members this way (the official order; the codebase follows it):

```text
1.  @tool / @icon
2.  class_name
3.  extends
4.  ## doc comment
5.  signals
6.  enums
7.  constants
8.  static vars
9.  @export vars
10. regular vars
11. @onready vars
12. _init()
13. _ready()
14. other virtuals (_process, _draw, ...)
15. public methods
16. private methods (_prefixed)
```

Properties before methods; public before private; `_init` / `_ready` before runtime
methods.

## Typing

Static types on vars, params and returns (`var cell: Vector2i`, `func f(x: int) -> bool`).
Prefer `:=` inference for locals. Typed arrays (`Array[Vector2i]`, `Array[Dictionary]`)
and typed dictionaries (`Dictionary[StringName, PackedScene]`) where the element type is
known. A new `class_name` needs one `--headless --editor --quit` import pass before
strict-typed scripts that reference it parse headlessly.

## The ECS rules (what makes code belong where)

These are the rules `CLAUDE.md` makes binding, with the reasoning.

### State is a component

- A component is a **pure-data class** with a `StringName` key const (`const HEALTH :=
  &"health"`). The 13 that exist are inner classes of `ecs/components/ecs_components.gd`,
  which is **frozen except for edits to existing classes**; every NEW component gets its own
  file in `ecs/components/` with a `KEY` const, so parallel work does not collide on one file.
  No methods with decisions in them. If a "component" grows a method that decides something,
  that method is a system.
- A component stays small: it holds what a system needs to remember between ticks
  (timers, current state, targets), not what the designer tunes. Tuning lives in `.tres`.
- Add a component field with a sensible default, document it with `##` when the meaning
  is not obvious from the name, and update every spawn path that must set it
  (`EcsActorFactory`, `EntityComponent.apply()`).

### Decisions are systems

- A system extends `EcsSystem` (`ecs/core/ecs_system.gd`), lives in `ecs/systems/<phase>/`
  (`input`, `decide`, `move`, `act`, `resolve`, `view`, and the folders the plan adds), is
  registered in `_make_world` of `shell/game_root.gd` (and mirrored in `tools/world_dumper.gd`,
  which the deterministic dump uses), and runs once per frame in registration order. Order is
  meaningful; do not reorder without reading the dependencies in `docs/ARCHITECTURE.md`. The
  plan (M3a) moves the order into one file per phase, `ecs/schedule/<phase>.gd`, with a test
  that fails if a system file is not listed.
- A system reads and writes components (through `world.query`, `get_component`, ...) and the
  grid. It **never calls another system**, never reads another system's private state, and
  never touches a node. Systems talk through components, `world.damage_events` and
  `world.emit_event`.
- Only `ViewSyncSystem` may touch nodes. If a system seems to need a node, it needs an event
  or a component field that `ViewSyncSystem` (or the bridge) turns into the node change.
- Do not use the `Input` singleton in a new system. `PlayerInputSystem` is the one existing
  exception and is slated to move behind an input snapshot.
- Give a system a `##` header saying what it reads, what it writes and what it emits.
- Port-then-refactor: when moving logic into a system, port the math verbatim first and
  clean up after behavior parity is proven by the tests.

### Events go out, data comes through components

- `world.emit_event({"type": &"name", ...})` is the only channel from the simulation to
  presentation. Presentation (the `shell/game_root.gd` bridge, HUD, board, camera, sound) reads
  `drain_events()` once per frame. Every key in the payload is documented where the event
  is emitted; see the table in `docs/ARCHITECTURE.md`.
- Damage is a request: append `{target, amount, direction}` to `world.damage_events`;
  `HealthSystem` is the only consumer.
- Presentation must not decide gameplay. Where the current bridge reads or writes components
  directly, that is a listed deviation in `docs/ARCHITECTURE.md`, not a pattern to copy.

### Authoring is spawn data, with zero logic

- A room scene is spawn data: parked `ActorView` nodes (position -> cell, `definition` and
  Inspector overrides -> component values), painted solid tiles, and grid markers. `EcsBoot`
  bakes them once; after boot the nodes are puppets.
- An editor-draggable component extends `EntityComponent` (`authoring/entity_components/`): it
  holds Inspector `@export` data and one `apply(world, entity_id)` that writes the entity's
  components. It never runs logic. A component node on an instance beats the definition.
- A marker extends `GridMarker` (`authoring/markers/`; `@tool`, drag-to-snap, `grid_cell`) and
  holds data only.
- An actor view is `Sprite2D`s under `MotionRoot/SpriteRoot`, a sibling `AnimationPlayer`
  (clips) and an `AnimationTree` (state graph). Keyframe `SpriteRoot`, never `MotionRoot`.
  Never `_draw()` an actor or pickup body; board overlays may use `_draw()`.
- **There is one actor view**, `presentation/views/actors/actor_view_base.tscn`; the clips and the graph
  exist once, in it. Never copy it. A new enemy needs no scene (instance the base, set `definition`); a
  thin inherited scene (`<id>_enemy.tscn`) only sets exports, stays under 40 lines and owns no clip, graph or
  other sub-resource (`test_one_actor_view`). What differs between pieces is data in `VisualDefinition`:
  the body picture, `piece_type`, `anchor_offset` and `clip_speed_scales` (a per-clip tempo; the base's
  `TimeScale` nodes apply it, because `AnimationPlayer.speed_scale` does nothing under an `AnimationTree`).
- **A piece is smaller than its cell** (owner, 2026-10-12). The size of each kind is data
  (`content/feel/piece_sizes.tres`, `PieceSizeTable`: a body box, a base line, a footprint), never a number in a
  scene or a script. Place a body only through `PieceSizeTable.body_top_left()` (`ViewSyncSystem` does); never hand-set
  `BodySprite.position`. Everything an actor draws (body, pips, arrow, weapon, aura) stays within 14 px of the cell
  centre, with 2 px to every edge. A clip may hop or shake a piece by at most the 2 px margin, and a clip that rotates
  `SpriteRoot` must turn about the body's middle, not the cell's centre. A new actor, clip or offset is checked by
  `tests/architecture/test_pieces_inside_cell.gd` and drawn by `tools/render_actor_preview.gd`; if either goes red,
  change the art or the offset, not the margin.
- The cell-to-cell slide is procedural (`MovementSystem` progress, `ViewSyncSystem`
  position). Never keyframe it, because it is the gameplay timing of the dodge window.

## Content vs behavior (the core rule)

- **Behavior -> script.** Reusable logic only. No hardcoded room content, enemy rosters or
  tuning numbers in code.
- **Content -> scene or `.tres`.** Enemy stats, AI weights, attack shapes, weapon data, room
  layout, objective text and movement rules live in Resources and scenes. New enemy, weapon,
  attack or room means editing data, not scripts.
- **Never duplicate a value** in both code and a `.tres`. The Resource is the single source of
  truth; code loads it (`EcsActorFactory.spawn_enemy` reads the definition).
- Shared Resources are immutable at runtime. `duplicate(true)` before mutating a per-instance
  copy (a picked-up `EnemyWeapon`).
- Enemy locomotion is data: `MovementConfig.allowed_directions` lists the offsets of one
  move. Never encode a piece's movement in a system.
- **Look content up by id, through `ContentDb`** (`shell/content/`, a static class): the id is the
  folder name under `content/<kind>/` and is spelled in one place. Code outside the shell does not
  load `content/` by path; a scene names what it needs by uid. Adding a kind is one line in
  `ContentDb._ensure_kinds()`, a `validate()` on its schema class, and a minimum count in
  `tests/content/test_validate_all.gd`. A reference between entries goes by id, and
  `ContentDb.validate_cross_refs()` fails on one that points at nothing.
- The hero's numbers are `content/player/player.tres` (`PlayerDefinition`), baked by `EcsBoot` like an
  enemy's definition; an `EntityComponent` node on the instance beats it field by field. Do not put a
  tuning value on the player scene.
- **Every definition class answers `validate()`** with readable sentences (empty when healthy), and
  `ContentDb.validate()` fails a kind whose class has none. A new enemy, room or skill is a folder with
  its role file: nothing registers it, `ContentDb` finds it by name and `test_validate_all` checks it.
- A text copy of a `.tres` or `.tscn` also copies its header `uid`; remove it from the copy, leave a reference to
  a file you just made path-only, then run import, `tools/stamp_uids.gd`, import, and `-- --check` (the steps and
  what each prevents are in `.claude/commands/new-enemy.md`). Duplicating in the editor's FileSystem dock does the
  uid part itself.

## Folder placement

The top-level folders are layers (`docs/ARCHITECTURE.md` has the tree and the table of which
layer may name which; `tests/architecture/test_dependency_edges.gd` enforces it).

- Anything the owner tunes, draws, records or writes -> `content/`, under the folder of its kind
  (`enemies/<id>/`, `rooms/<id>/`, `skills/<id>/`, `pickups/<id>/`, `rules/<id>/`, `tilesets/<kit>/`,
  `world/`, `difficulty/`, `player/`). **`content/` holds zero `.gd` files** (test-enforced). The
  folder name is the id, written once; a leading underscore (`_shared`) is not an id. Each id
  folder holds the role file its kind needs (`enemy.tres`, `room.tscn`, `page.tres`) and role-named
  art (`body.png`, `icon.png`, `background.png`): art names are roles, so the owner overwrites a file
  and nothing else changes.
- A Resource class (the shape of content) -> `schema/<area>/`, one class per file, `##` on every
  `@export`.
- Simulation -> `ecs/` (`core/`, `components/`, `systems/<phase>/`). No art, prose or tuning
  numbers in it.
- Things dragged into a scene (`EntityComponent` nodes, markers, the room root) and the baker
  (`EcsBoot`, `EcsActorFactory`) -> `authoring/`.
- Views, the HUD, the board, the camera, sound playback -> `presentation/`. It reads events; it
  never decides.
- The game around the game (the one game scene and its bridge, save state, later the title and
  pause flow) -> `shell/`.
- Raw art and audio not owned by one content item -> `assets/` (`tiles/<kit>/atlas.*`,
  `ui/`, `sfx/`, `music/`, `map_pieces/`). Hand-drawn art never goes in a gitignored folder.
  `assets/_generated/` is generator output only: gitignored, never hand-edited, and **no tracked
  scene may name it** (a stand-in picture is copied into `content/` by `tools/seed_placeholders.gd`).
- Build and one-off scripts -> `tools/`. Tests -> `tests/` (see Tests below).
- TileMap `tile_map_data` is a binary blob: never hand-edit it; use a `tools/` paint script.
- **Move and rename files only with `tools/move_res.py`** (`git mv` for the file and its
  `.uid`/`.import` sidecar, every `res://` string rewritten), never by hand or in the editor's
  FileSystem dock; run `tools/stamp_uids.gd -- --check` and expect CLEAN.
- **Sidecars:** commit every new `.gd` with its `.gd.uid` and every new image or audio file with
  its `.import` (run the import pass first). `test_sidecars_tracked` fails on a missing, stale or
  orphan sidecar.
- A tool that saves a scene with `ResourceSaver` goes through `tools/save_keeping_uids.gd`;
  a plain `ResourceSaver.save()` drops the uids (`tests/architecture/test_tools_keep_uids.gd`).

## Built-in nodes first

**Mandatory research step before implementing any new mechanic:**

1. **Built-in?** Search the Godot class reference for a node or engine feature that already
   provides the capability. If one fits, use it.
2. **Addon?** If no built-in fits, look for a proven, maintained addon (Godot Asset Library,
   GitHub — check license, Godot 4 support, recent commits). Adding a dependency needs the
   owner's approval first.
3. **Custom script** only when neither fits. State in the commit message why the built-in or
   addon route did not work, so the decision is auditable.

Never re-implement what a node already does.

| Need | Use the built-in | Not |
|---|---|---|
| Delays, cooldowns in presentation | `Timer` node or `get_tree().create_timer()` | hand-decremented floats in `_process` |
| Property animation over time | `Tween` / `AnimationPlayer` / `AnimationTree` | manual lerp bookkeeping |
| Pathfinding | `AStarGrid2D` (used in `EcsGrid`) | hand-rolled BFS or Dijkstra |
| Tile floors and walls | `TileMapLayer` + `TileSet` (`solid` custom data) | per-cell Polygon2D or Sprite nodes |
| UI layout | Containers, anchors | manual position math on Controls |
| Screen-fixed UI | `CanvasLayer` | moving UI to follow the camera |
| Camera follow, limits, shake | `Camera2D` properties | scripted camera math |
| Node lookup | scene-unique names (`%Node`), `@export` NodePath | brittle absolute paths |
| Sound | `AnimationPlayer` audio tracks (motion), `SfxManager` registry (events), `default_bus_layout.tres` (mixing) | ad-hoc `AudioStreamPlayer.new()` in code |

The sanctioned exception to "no timers by hand": simulation timers live in components
(`state_time_left`, `impact_left`, ...) and are decremented by systems, because the
simulation is driven by `EcsWorld.tick(delta)` and must be deterministic under test.
Collision is cell-based through `EcsGrid`, not physics.

## Scenes

- **One controller script per scene**, on the root, named after it. Actor view roots carry
  `ActorView` and nothing else; they hold no gameplay.
- **Self-contained**: a scene owns what it needs and takes outside data through `@export` or
  a `setup()` call, never by reaching up the tree.
- Use `_get_configuration_warnings()` so the editor self-documents missing setup
  (`EntityComponent` warns when it is not under an `ActorView`).
- Keep sub-scene children non-editable unless there is a reason. Actor sprites and the
  `AnimationPlayer` live directly in each actor scene, so they are always editable.

## Tests

- Add or update tests for behavior and scene-ownership changes. Assertion labels are English
  statements of the guarantee; write them to read as a spec.
- Simulation behavior is tested by driving `EcsWorld.tick(delta)` by hand
  (`manual_tick = true`) and asserting on components and drained events. Headless tests have
  no real keys, so write `MoveIntent` / `AttackIntent` exactly as `PlayerInputSystem` would.
- A test that reads a file must also assert the content is non-empty; a stale `res://` path
  otherwise reads `""` and passes vacuously.
- New suites extend `UnboundTest` (`tests/support/unbound_test.gd`): it has a watchdog so a
  script error cannot hang the run, it fails a suite that asserted nothing, and it prints
  `PASS:` / `FAIL:` lines the runner reads. A suite named `test_*.gd` anywhere under `tests/`
  is found by `tools/run_all_tests.py` without editing it. Every suite must print at least one
  `PASS:` line, even a report-only guard (assert that its scan saw enough files). All current
  `test_*.gd` suites follow this; only the older `run_tests.gd` and `*_test.gd` suites still
  extend `SceneTree` directly. A guard that cannot run (for example no git) must FAIL, never
  print PASS (skipped). `tests/architecture/test_all_scripts_load.gd` compiles every script, which
  the import pass does not.
- A new test names a `res://` file through `TestPaths` (`tests/support/paths.gd`), which asserts
  the file exists. Folder moves then edit one file instead of every suite. Suites live in a
  folder by kind: `tests/architecture/` (guards), `tests/bridge/`, `tests/audio/`,
  `tests/content/`; the dump baselines are `tests/baselines/dump_<room>.txt` (change one in the
  same commit as the change that explains it, and say so in the message).
- Never rename or delete a `PASS:` label that is in `tests/baseline_labels.txt`; if a label
  must change, record `old label -> new label` in `tests/label_renames.txt`.
- Keep the playable slice green: `python3 tools/run_all_tests.py --strict` and `git diff --check`
  after meaningful changes (`/verify`).

## Patterns in use, and ones we deliberately do not use

In use:

- **ECS with scene-authored spawn data.** Entities are ids, components are data, systems are
  logic, scenes are puppets (see above).
- **Resources as data (type-object / flyweight).** `EnemyDefinition` composes shared
  sub-resources; many enemies share one `MovementConfig`.
- **Factory via definition.** `EcsActorFactory` builds an entity from a definition; no
  scattered `new()` construction of gameplay state.
- **Events up, calls down.** Systems emit events; the bridge and presentation consume them.
- **Data-driven AI.** A `DecisionConfig` `.tres` is a personality; the scorer in
  `EnemyAISystem` is shared.

Deliberately not used (do not add them without a real need and the owner's say):

- **No ECS addon or framework.** The small in-repo `EcsWorld` is the runtime; the plan keeps
  it (`docs/game-base-plan.md` D-28).
- **No global event-bus autoload.** The event queue is on the world; the bridge drains it.
  Only `SfxManager` and `WorldState` are autoloads.
- **No node-based gameplay components.** Gameplay behavior never lives on a node. Nodes are
  authoring data (`EntityComponent`) or presentation.

## Git

- One logical change per commit, scoped, with a why-focused message.
- Don't revert the owner's in-progress editor changes; stage explicit paths, never
  `git add -A` over uncommitted editor or UID changes.
- Commit every new `.gd` together with its `.gd.uid` sidecar.

## What the plan adds next

`docs/game-base-plan.md` §13.3 lists conventions that M1b did not need and later milestones add:
systems grouped by phase with the order kept as data in `ecs/schedule/` (M3a), the file-naming suffixes `*_effect.gd`, `*_handler.gd`, `*_bridge.gd` as
those kinds appear, and `.po` text keys instead of literal strings. Those are targets, not rules
yet; the rules above are the ones the code and the guards already hold.
