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
- State about the ROOM (not about an actor) goes on the room's own entity: `EcsBoot` makes one per played room
  (only when `EcsBootOptions.with_room_rules` is set) and the systems that judge the room query for its
  component (`RoomObjectiveState`, `RoomCheckpoint`). Do not add a field to `EcsWorld` for it: the world's
  fields all landed in M3a. A fact only the shell knows (how the pawn arrived, what the run has cleared) reaches
  the room entity through `EcsBootOptions`, so `EcsBoot` and the systems never read the save.
- Add a component field with a sensible default, document it with `##` when the meaning
  is not obvious from the name, and update every spawn path that must set it
  (`EcsActorFactory`, `EntityComponent.apply()`).

### Decisions are systems

- A system extends `EcsSystem` (`ecs/core/ecs_system.gd`), lives in `ecs/systems/<folder>/`
  (`command`, `input`, `decide`, `move`, `act`, `resolve`, `view`, and the folders the plan adds)
  with `const PHASE := &"<stage>"`, and is listed with one line in the stage's file in
  `ecs/schedule/` (`command`, `input`, `decide`, `cell_effects`, `move`, `act`, `resolve`,
  `react`, `progress`, `view`). It runs once per frame in the order the schedule gives:
  `shell/zone_stage.gd` (the in-game scene's world) and `tools/world_dumper.gd` both call
  `Schedule.populate(world)` and keep no list of their own. A stage is named for when it runs, a folder for what its systems are about,
  so they differ where the plan's order visits one folder several times. `test_schedule_order` holds
  the whole planned order and `test_schedule_complete` fails on a system file that is not listed once.
  Order is meaningful; do not reorder without reading the dependencies in `docs/ARCHITECTURE.md`.
- A system reads and writes components (through `world.query`, `get_component`, ...) and the
  grid. It **never calls another system**, never reads another system's private state, and
  never touches a node. Systems talk through components, `world.damage_events`,
  `world.heal_events` and `world.emit_event`. The one indirect path is a command handler: a system
  that owns the state a command changes registers it with `world.register_command_handler()`, and
  `CommandSystem` calls it at the head of the tick.
- A frozen world (`world.frozen`) ticks only the systems that answer yes to `runs_while_frozen()`
  (the command and view systems). A new system answers no unless it keeps the frozen world alive.
- Only `ViewSyncSystem` may touch nodes. If a system seems to need a node, it needs an event
  or a component field that `ViewSyncSystem` (or the bridge) turns into the node change.
- Never use the `Input` singleton. `shell/input/input_poller.gd` is the only file that calls it
  (`tests/architecture/test_input_only_in_poller.gd` fails on any other); it copies the controls into
  `world.input_snapshot` once per frame, and a system reads that. To test a rule that depends on
  the controls, inject an `InputSnapshot` (`set_action`) and tick: see `tests/ecs/test_input_snapshot.gd`.
- Give a system a `##` header saying what it reads, what it writes and what it emits.
- Port-then-refactor: when moving logic into a system, port the math verbatim first and
  clean up after behavior parity is proven by the tests.

### Events go out, data comes through components

- `world.emit_event({"type": Events.NAME, ...})` is the only channel from the simulation to
  presentation. The in-game scene (`shell/game_root.gd`) reads
  `drain_events()` once per frame and its `EventRouter` hands each event to the bridges (HUD, board, camera,
  sound, status line in `presentation/bridges/`; save, zone trip, Book, room outcome, despawn in `shell/bridges/`). Every event is declared once in `ecs/events/events.gd`: a const,
  and a row with its status, what happened and every payload key; `emit_event` asserts in debug
  builds that an event matches its row, and `test_events_declared` reads the code for every emitted
  name. A new event is a const and a row inside your own banner there.
- Damage and healing are requests: `Events.emit_damage(world, target, amount, direction, source, tags)`
  and `Events.emit_heal(world, target, amount, source)` are the only ways to queue them, and
  `HealthSystem` is the only consumer. `source` is the acting entity (0 for none) and travels on into
  the `damaged` and `defeated` events.
- The way back is `world.commands`: presentation pushes typed requests built by `ecs/events/commands.gd`
  (`world.push_command(Commands.set_flag(...))`), and `CommandSystem` applies them at the head of the
  next tick. A bridge never sets a flag, a freeze or a setting itself.
- Presentation must not decide gameplay. Where the current bridge reads or writes components
  directly, that is a listed deviation in `docs/ARCHITECTURE.md`, not a pattern to copy.
- A rule about how a room goes (is it cleared, did the pawn fall, is this door a checkpoint, what refills) is a
  SYSTEM that says so with an event (`room_cleared`, `respawn_requested`, `checkpoint_set`); the bridges only
  answer: `SaveBridge` writes the fact into the run and saves, `RoomOutcomeBridge` shows the result screen and
  the defeat beat, `HudBridge` redraws. A bridge that counts, compares or decides has taken a system's job
  (`test_game_root_is_thin` and the bridge tests keep the scene and the bridges to reactions).
- The state a bridge keeps in the run (`SaveService.state`) is for what must outlive a room: write it where the
  success event is handled, never in a system, and ask for a save only there, with a literal reason from
  `SaveService.AUTOSAVE_REASONS` (`test_request_save_callers`). What a death must not lose is in the run; what
  a death resets is in the room's scene. Which rooms are checkpoints is data on the room
  (`RoomEncounter.checkpoint_on_entry`), which pickups are rewards is data on the marker
  (`PickupSpawnPoint.persistent`): no script names a room or a pickup by id.

### The board answers, systems ask

- What a cell is made of is a kind (`CellKinds`, `ecs/core/cell_kinds.gd`): one table, one row per kind, three rules
  (walkable, stops a ray, a leap may cross). A skill, hazard or drawing routine asks the table
  (`CellKinds.is_walkable()`, `stops_rays()`, `is_leapable()`); it never repeats a list of kinds. A new kind is a
  row there and the tile that says it (the TileSet's `kind` custom data, tagged in the editor).
- `EcsGrid.set_cell_kind()` is the only writer of the terrain; `blocked_cells` and `layout_version` follow from it,
  and `test_grid_cell_kinds` fails on any other script that writes them. Anything that caches a fact about the
  terrain (the pathfinder, a drawing of the kinds) keeps the `layout_version` it was built for and rebuilds when
  it moves.
- A leap and a ray are grid services, not skill code. `begin_leap` / `finish_leap` hold the landing cell and let
  go of the origin (the leaper stands on no cell in the air and takes no damage); `ray_cells` walks a line and
  stops at what stops it. A skill decides which cells it wants, the grid says what holds them.
- Cost is a rule, not a hope. A question a system asks every decision must not scan the board or build a
  pathfinder: `get_grid_path` reuses one `AStarGrid2D` per layout, and the enemy's search for the cell to attack
  from only looks within the attack shape's reach of the hero. `tests/perf/test_room_tick_budget.gd` ticks an
  18x9 room with eight enemies and fails above a 2 ms mean tick or if the run builds more than one pathfinder. When you
  make a faster version of something, keep the old body in `tests/support/` and compare the two on random input
  (`reference_pathing.gd`, `test_path_cache`, `test_attack_setup_search`): the speed-up is only allowed to change
  how fast the answer comes.

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
| Pathfinding | `AStarGrid2D` (used in `EcsGrid`, built once per `layout_version`, not per question) | hand-rolled BFS or Dijkstra |
| Tile floors, walls and gaps | `TileMapLayer` + `TileSet` (`kind` and `solid` custom data) | per-cell Polygon2D or Sprite nodes |
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
  `tests/content/`, `tests/ecs/` (the simulation's seams), `tests/presentation/`, `tests/perf/` (budgets: a measured cost with a generous bound, never a
  bound tight enough to fail on a busy machine); the dump baselines are `tests/baselines/dump_<room>.txt` (change one in the
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
  Only `SfxManager` and `SaveService` are autoloads.
- **No node-based gameplay components.** Gameplay behavior never lives on a node. Nodes are
  authoring data (`EntityComponent`) or presentation.

## Git

- One logical change per commit, scoped, with a why-focused message.
- Don't revert the owner's in-progress editor changes; stage explicit paths, never
  `git add -A` over uncommitted editor or UID changes.
- Commit every new `.gd` together with its `.gd.uid` sidecar.

## What the plan adds next

`docs/game-base-plan.md` §13.3 lists conventions that M1b did not need and later milestones add:
the file-naming suffixes `*_effect.gd`, `*_handler.gd`, `*_bridge.gd` as those kinds appear, and `.po`
text keys instead of literal strings. Those are targets, not rules yet; the rules above are the
ones the code and the guards already hold (the schedule, the declared events and commands, the snapshots, the
cell kinds and the cached pathing landed with M3a).
