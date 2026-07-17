# Restructure Plan — type-based → feature-based (future reference)

**Status: not scheduled.** The project is type-based today and that is the right
call at ~34 scripts / ~27 scenes (see `ARCHITECTURE.md`). This document is the
blueprint to migrate to a feature-based ("screaming") layout **when it's worth it**,
so the decision and the mechanics are ready in advance.

## When to trigger

Do this migration only when one or more is true:
- Project grows past ~100 scenes / ~10k LOC.
- Adding a feature means editing 4+ scattered folders every time.
- More than one person works on the code and "where does this go" recurs.
- You keep hunting across `scripts/`, `objects/`, `resources/` for one entity's files.

Until then, the type-based layout is cheaper to keep than to churn.

## Why feature-based (the payoff)

Group everything an entity needs in one folder. Deleting a feature = delete one
folder. No cross-folder hunting. Relative paths. This is the Godot community's
preferred layout for larger projects (official docs, GDQuest, abmarnie, SlayHorizon).

## Target structure

```
res://
├─ assets/                     raw art only (unchanged)
├─ addons/                     third-party (none yet)
├─ autoload/                   global singletons (none yet — placeholder)
├─ core/                       engine-level, feature-agnostic
│  ├─ grid_world.gd/.tscn
│  ├─ grid_actor.gd
│  └─ encounter_director.gd/.tscn
├─ features/
│  ├─ player/
│  │  ├─ pawn_hero.gd  player.tscn
│  │  └─ attacks/ wooden_sword.tres  pencil_thrust.tres
│  ├─ enemies/
│  │  ├─ enemy_actor.gd  free_enemy.gd
│  │  ├─ components/ grid_movement, enemy_brain, health, equipment (+.tscn)
│  │  ├─ ai/ attack_pattern.gd  enemy_context.gd  enemy_intent.gd
│  │  ├─ data/ enemy_definition, movement_config, decision_config,
│  │  │        visual_definition, difficulty_profile (schemas)
│  │  ├─ pawn/    black_pawn.tscn + pawn_recruit/pawn_armed.tres + its movement/
│  │  │           decision/attack/visual .tres + black_pawn_visual.tscn
│  │  ├─ knight/  (same shape)
│  │  └─ bishop/  (same shape)
│  ├─ weapons/    enemy_weapon.gd  weapon_pickup.gd/.tscn  weapon_pickup_visual.tscn
│  │             + pencil_spear/ruler_blade.tres
│  └─ combat/     attack_profile.gd  prototype_board.gd/.tscn
├─ world/         markers (grid_marker + 4), room_encounter, grid_lines_overlay,
│                 tilemaps, tilesets, room_objective
├─ rooms/         first_encounter.tscn (+ future rooms)
├─ ui/            hud.gd/.tscn
├─ main.tscn  main.gd
├─ tests/  tools/  docs/
```

Note: `piece_visual.gd`/`pickup_visual.gd` are shared → keep in `features/enemies/`
and `features/weapons/` respectively, or a small `shared/visuals/` if reused wider.

## The key technical fact

- **`class_name` references are path-independent.** Godot resolves global classes by
  name, not path, so `var x: GridWorld` keeps working after a move. Most
  script-to-script references survive untouched.
- **What breaks on a move** are *path-based* references:
  - `.tscn` / `.tres` `ext_resource ... path="res://..."`
  - `preload("res://...")` / `load("res://...")` string literals in scripts
  - `.uid` sidecar files
  - `project.godot` `run/main_scene` + input/autoload paths

## Migration procedure (do it this way to stay safe)

1. **Branch first.** `git checkout -b restructure`. Never on `main`.
2. **Clean tree.** Commit/stash all work; no dirty editor files (the human's UID
   edits must be committed first).
3. **Move through the Godot editor, not the shell.** Drag files in the FileSystem
   dock. Godot 4.4+ rewrites dependent `ext_resource` paths + `.uid` automatically.
   Moving with `mv`/`git mv` breaks path refs — only do that if every ref is `uid://`.
4. **Move in dependency order** (leaves first): schemas/data → components → visuals
   → actor scenes → world/markers → rooms → main. Import + verify after each batch.
5. **Fix script string paths.** `grep -rn 'preload("res://\|load("res://' scripts/`
   and update each to the new path.
6. **Update `project.godot`** `run/main_scene` if `main.tscn` moved.
7. **Rewrite the docs.** `AGENTS.md` folder-ownership section, `ARCHITECTURE.md`
   folder tree, and this plan's "done" note.
8. **Verify** (see checklist), commit in logical batches, open a PR, merge only green.

## Move mapping (current → target), high level

| Current | Target |
|---|---|
| `scripts/core/*`, `scripts/combat/encounter_director.gd`, `scripts/actors/grid_actor.gd` | `core/` |
| `scripts/actors/pawn_hero.gd`, `objects/actors/player.tscn`, `objects/visuals/pawn_hero_visual.tscn`, `resources/attacks/{wooden_sword,pencil_thrust}` | `features/player/` |
| `scripts/actors/free_enemy.gd`, `scripts/entities/enemy_actor.gd`, `scripts/components/*`, `scripts/ai/*`, `scripts/data/*` | `features/enemies/{,components,ai,data}/` |
| each enemy's `.tscn` + its `enemies/*.tres` + movement/decision/attack/visual `.tres` + `*_visual.tscn` | `features/enemies/<name>/` |
| `scripts/combat/{attack_profile,enemy_weapon}.gd`, `scripts/world/weapon_pickup.gd`, weapon `.tres`, pickup scenes | `features/combat/` + `features/weapons/` |
| `scripts/world/{markers,room_encounter,prototype_board,grid_lines_overlay}.gd` + their scenes, tiles | `world/` |
| `scenes/rooms/*` | `rooms/` |
| `scenes/ui/*`, `scripts/ui/*` | `ui/` |

## Risks

- **Broken refs** if moved outside the editor without uid coverage → do it in-editor.
- **`.import` regeneration** for moved art → re-import, don't hand-edit.
- **Test path strings** — `tests/*.gd` use `load("res://objects/...")`; grep + fix all.
- **Merge conflicts** with the human's in-editor work — do the migration when the
  tree is quiet, in one focused branch.
- **Reversibility** — one big PR; if it goes wrong, drop the branch. Do NOT partially
  land it.

## Verification checklist (must all pass before merge)

```bash
# 1. no stale res:// paths to old locations
grep -rn 'res://scripts/\|res://objects/\|res://scenes/' . --include=*.gd --include=*.tscn --include=*.tres
# 2. editor import clean
Godot --headless --path . --editor --quit
# 3. full test suite green
Godot --headless --path . -s tests/run_tests.gd    # + the 6 runtime tests
# 4. game runs
Godot --headless --path . --quit-after 600          # zero script errors
# 5. real-renderer capture looks identical
```

## Estimated effort

~half a day of careful in-editor moving + path fixups + doc rewrite + verification,
assuming a quiet tree. Not hard, but tedious and all-or-nothing — hence "do it once,
when it's worth it," not incrementally.
