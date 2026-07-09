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

## Components

- Prefer composition: an entity gains behavior from child component nodes
  (`GridMovement`, `Health`, `Equipment`, `EnemyBrain`), not from a deep class
  hierarchy. Keep every component doing real work — no hollow proxy nodes.

## Tests

- Add or update tests for behavior and scene ownership changes. Assertion messages
  are English statements of the guarantee — write them to read as a spec.
- Keep the playable slice green: run `tests/run_tests.gd` + the runtime tests +
  an editor import after meaningful changes.

## Git

- One logical change per commit, scoped, with a why-focused message.
- Don't revert the human's in-progress editor changes; stage explicit paths.
