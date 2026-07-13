# Coding Standards

Conventions for this project. Aligned with the official
[GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
and [project organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html)
best practices. Consistency matters more than any single rule.

## Naming

- `snake_case` for all files and folders (Godot 4 default; avoids case-sensitivity
  export bugs).
- `PascalCase` for node names and `class_name` (matches built-in nodes).
- Name a scene, its root node, and its controller script the same thing where a
  scene has one controller (e.g. `hud.tscn` → root `HUD` → `hud.gd`/`GameHud`).
- No spaces in filenames; use underscores.

## GDScript member order

Order every script's members this way (official order — the codebase already
follows it, keep it that way):

```
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

Rules of thumb: properties before methods; public before private; `_init`/`_ready`
before runtime methods.

## Typing

- Use static types on vars, params, and returns where practical
  (`var cell: Vector2i`, `func f(x: int) -> bool`). Catches errors, improves
  autocomplete. Prefer `:=` inference for locals.

## Scenes

- **One controller script per scene**, on the root node, named after it.
- **Self-contained**: a scene owns what it needs; it should instantiate without
  knowing its environment. If it needs outside data, inject it via `setup()` /
  `@export`, don't reach up the tree.
- Use `_get_configuration_warnings()` so the editor self-documents missing setup
  (see `enemy_actor.gd`).
- Keep sub-scene children non-editable unless there's a reason (the actor prefabs
  enable `[editable path="Visual"]` deliberately, for sprite/animation tweaking).

## Content vs behavior (the core rule)

- **Behavior → script.** Reusable logic only. No hardcoded room content, enemy
  rosters, or tuning values baked in code.
- **Content → scene or `.tres`.** Enemy stats, AI weights, attack shapes, weapon
  data, room layout, and objective text live in Resources / scenes.
- Do not duplicate a value in both code and a `.tres`. The Resource is the source
  of truth; code loads it (see `pawn_hero._ensure_attack_profiles`).
- Actor/pickup bodies are `Sprite2D` + `AnimationPlayer`, never `_draw()`. Overlays
  (board telegraphs, debug, grid lines) may use `_draw()`.

## Folder placement

- New reusable prefab `.tscn` → `objects/`, never `scenes/`.
- New tunable data → a `.tres` in the matching `resources/` subfolder.
- New reusable behavior → `scripts/<area>/`.
- Raw art → `assets/`. Build/one-off scripts → `tools/`.

## Built-in nodes first

If Godot already ships a node or engine feature for a capability, use it instead of
writing custom script logic. Check the class reference before building any "system".

| Need | Use the built-in | Not |
|---|---|---|
| Delays / cooldowns | `Timer` node or `get_tree().create_timer()` | hand-decremented floats in `_process` (only OK when the value drives per-frame visuals, e.g. telegraph progress) |
| Property animation over time | `Tween` (movement) / `AnimationPlayer` (authored clips) | manual lerp bookkeeping in `_process` |
| Overlap / proximity detection | `Area2D` + `body_entered`/`area_entered` | distance checks every frame (grid-cell logic via `GridWorld` is the sanctioned exception — combat is cell-based, not physics-based) |
| Pathfinding | `AStarGrid2D` (already used in `GridWorld`) | hand-rolled BFS/Dijkstra |
| Tile floors | `TileMapLayer` + `TileSet` | per-cell Polygon2D/Sprite nodes |
| UI layout | Containers (`HBox`/`VBox`/`Margin`...), anchors | manual position math on Controls |
| Screen-fixed UI | `CanvasLayer` | moving UI to follow the camera |
| Camera follow/limits/shake | `Camera2D` properties | scripted camera math |
| Node lookup | scene-unique names (`%Node`), `@export` NodePath | brittle absolute paths |

Existing compliance examples: movement uses `Tween`, visuals use `AnimationPlayer`,
the floor is a `TileMapLayer`, pathfinding is `AStarGrid2D`, the HUD is a
`CanvasLayer`. Keep new work at that bar.

## Components

- Prefer composition: an entity gains behavior from child component nodes
  (`GridMovement`, `Health`, `Equipment`, `EnemyBrain`), not from a deep class
  hierarchy. Keep every component doing real work — no hollow proxy nodes.

## Tests

- Add or update tests for behavior and scene ownership changes. Assertion messages
  are English statements of the guarantee — write them to read as a spec.
- Keep the playable slice green: run `tests/run_tests.gd` + the runtime tests +
  an editor import after meaningful changes.

## Design patterns in use

The codebase already follows idiomatic Godot patterns. Keep to them; don't
introduce heavier architecture without a concrete need (YAGNI).

- **Composition over inheritance.** An entity gains behavior from child component
  nodes (`GridMovement`, `Health`, `Equipment`, `EnemyBrain`), configured by the
  host. Add a capability = add a component/Resource, not a subclass. Avoid deep
  class trees (this is why the `BlackPawn`/`KnightEnemy` subclasses were retired).
- **Resources as data (type-object / flyweight).** Per-entity data lives in `@export`
  Resources (`EnemyDefinition` → movement/decision/attack/visual). Shared `.tres`
  are treated as immutable at runtime; duplicate (`duplicate(true)`) when an instance
  needs to mutate (e.g. a picked-up weapon). Use `@export` for Resource refs,
  `@onready`/`get_node` for child-node refs.
- **Signals for decoupling ("call down, signal up").** A node calls its children
  directly (down); it talks to parents/siblings by emitting a signal (up). Signal
  names are past tense (`telegraph_started`, `attack_resolved`, `room_completed`,
  `damaged`, `defeated`). Connect at the common parent (`Main` wires hero/room/HUD).
- **Dependency injection.** Scenes are self-contained and receive their environment
  via `setup(...)` or `@export`, never by reaching up the tree with `get_parent()`.
  Components get their host via `configure(host)`.
- **Factory via scene + definition.** Spawners instantiate an editor-assigned
  `PackedScene` and stamp it with a definition (`EnemySpawnPoint.create_enemy`);
  no scattered `new()` construction.
- **State machine: enum + `match`.** `FreeEnemy` uses a 5-state enum
  (`OBSERVE/TELEGRAPH/COMMIT/RECOVER/DEFEATED`) with a `match` in `_process`. This is
  correct — a node-based state machine is over-engineering under ~6 states. Only
  reach for one if states exceed ~6 and need reuse/independent editing.

Deliberate non-choices (don't add these without a real need):
- **No Event Bus / Autoload singleton.** `Main` mediates cross-node wiring; adding a
  global signal bus is only worth it for distant nodes or runtime-instanced UI.
- **No ECS.** Godot's node tree already gives composition; a parallel ECS would fight
  the engine.

Known accepted tradeoff:
- `free_enemy.gd` (~530 lines) concentrates sensing, scoring, movement, attack
  lifecycle, and damage. It stretches single-responsibility, but the AI is already
  data-driven via `DecisionConfig`, so relocating the code buys churn, not
  capability. Revisit only if the AI grows substantially.

## Git

- One logical change per commit, scoped, with a why-focused message.
- Don't revert the human's in-progress editor changes; stage explicit paths.
