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
  marker). Runtime component data classes are inner classes of `EcsComponents`.
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

- A component is a **pure-data inner class** of `scripts/ecs/ecs_components.gd` plus a
  `StringName` key const (`const HEALTH := &"health"`). No methods with decisions in them.
  If a "component" grows a method that decides something, that method is a system.
- A component stays small: it holds what a system needs to remember between ticks
  (timers, current state, targets), not what the designer tunes. Tuning lives in `.tres`.
- Add a component field with a sensible default, document it with `##` when the meaning
  is not obvious from the name, and update every spawn path that must set it
  (`EcsActorFactory`, `EntityComponent.apply()`).

### Decisions are systems

- A system extends `EcsSystem` (`scripts/ecs/systems/`), is registered in `Main._make_world`,
  and runs once per frame in registration order. Order is meaningful; do not reorder without
  reading the dependencies in `docs/ARCHITECTURE.md`.
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
  presentation. Presentation (the `main.gd` bridge, HUD, board, camera, sound) reads
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
- An editor-draggable component extends `EntityComponent` (`scripts/ecs/components/`): it
  holds Inspector `@export` data and one `apply(world, entity_id)` that writes the entity's
  components. It never runs logic. A component node on an instance beats the definition.
- A marker extends `GridMarker` (`@tool`, drag-to-snap, `grid_cell`) and holds data only.
- An actor view is `Sprite2D`s under `MotionRoot/SpriteRoot`, a sibling `AnimationPlayer`
  (clips) and an `AnimationTree` (state graph). Keyframe `SpriteRoot`, never `MotionRoot`.
  Never `_draw()` an actor or pickup body; board overlays may use `_draw()`.
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

## Folder placement (today)

- Entry, room and UI scenes the owner opens -> `scenes/`. Reusable prefabs -> `objects/`.
- Tunable data -> a `.tres` in the matching `resources/` subfolder.
- Simulation -> `scripts/ecs/` (components, systems, grid, boot, factory). Resource schemas ->
  `scripts/data/`, `scripts/ai/`, `scripts/combat/`. Room markers and overlays ->
  `scripts/world/`. Presentation -> `scripts/ui/`, `scripts/visuals/`, `scripts/audio/`.
- Raw art and audio -> `assets/`. Build and one-off scripts -> `tools/`. Tests -> `tests/`.
- Generated art goes where its generator writes it and is gitignored; never hand-edit it.
- TileMap `tile_map_data` is a binary blob: never hand-edit it; use a `tools/` paint script.
- Do not move or rename files by hand in the editor dock; the scripted migration of
  `docs/game-base-plan.md` §13.3 will do that with UID safety.

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
  `PASS:` line, even a report-only guard (assert that its scan saw enough files).
- A new test names a `res://` file through `TestPaths` (`tests/support/paths.gd`), which asserts
  the file exists. Folder moves then edit one file instead of every suite.
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

## Where this is going

`docs/game-base-plan.md` §13.3 lists the conventions the migration will add: one Resource
class per file with `##` docs and a `validate()`, every new component in its own file with
a `KEY` const (`ecs_components.gd` frozen), systems grouped by phase with the order kept as
data in `ecs/schedule/`, ids derived from folder names, and a `content/` folder with zero
`.gd`. Those are **targets, not rules yet**: follow this file until the owner approves the
`CLAUDE.md` changes at gate OG0 and the folders move.
