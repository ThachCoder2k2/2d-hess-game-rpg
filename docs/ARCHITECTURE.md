# Architecture

The Unbound Pawn — a 2D top-down grid-combat RPG in Godot 4.6. This document is
the map of the codebase: folders, the runtime node tree, the core systems, and
the order to read things in. Pair it with `coding-standards.md` for conventions
and `AGENTS.md` for workflow rules.

## Guiding principle

**Code is reusable behavior; content is scenes + Resources.**
To change *what happens*, edit a script. To change *content* (a new enemy, a new
weapon, a room layout), edit a `.tscn` or a `.tres` — no code. The Bishop enemy
was built entirely from data with zero new script, proving the split holds.

## Folder structure (type-based)

```
scenes/      Playable/entry scenes only: main.tscn, rooms/, ui/
objects/     Reusable prefabs: actors/ components/ markers/ visuals/ world/ combat/
resources/   Tunable data (.tres): enemies/ movement/ decisions/ attacks/ weapons/
             visuals/ difficulty/ objectives/ tiles/
scripts/     Reusable behavior: actors/ ai/ combat/ components/ core/ data/
             entities/ ui/ visuals/ world/
assets/      Raw art: sprites/ tiles/
tests/       Headless test scripts
tools/       Build/one-off scripts (e.g. paint_kingdom_tilemap.gd)
docs/        This file, coding-standards.md, and design/
```

Ownership rules (also in `AGENTS.md`):
- `scenes/` — only scenes the human opens directly (entry, rooms, UI).
- `objects/` — reusable prefab templates. New reusable `.tscn` goes here, not `scenes/`.
- `resources/` — `.tres` data; the source of truth for tuning.
- `scripts/` — behavior + migration bridges; never authored room content.

This is a *type-based* layout. The Godot community generally prefers
*feature-based* ("screaming") folders for large projects, but at this size
(~34 scripts, ~27 scenes) the type-based split is clean, consistent, and cheaper
to keep than to migrate. Revisit if the project grows past ~100 scenes.

## Runtime node tree (what runs on F5)

```
Main (main.gd — coordinator, wires systems, no content built in code)
├─ GridWorld          cell truth: occupancy, reservations, blocks, items, A* paths
├─ EncounterDirector  one shared attack token → no unfair simultaneous strikes
├─ PrototypeBoard     combat overlay: telegraphs, hit flash, F3 debug paths
├─ PawnHero           player: move, turn, sword, pencil thrust, courage, invuln
├─ FirstEncounter     room: RoomArt + draggable markers drive spawns/blockers
└─ HUD                owns its own labels + all formatting
```

Every enemy is the same skeleton:

```
EnemyActor (generic script + an EnemyDefinition .tres)
├─ Visual                Sprite2D + AnimationPlayer (idle/step/attack/hurt/telegraph)
├─ GridMovementComponent registration, steps, legal moves, move tween
├─ EnemyBrainComponent   optional per-enemy DecisionConfig (AI knobs)
├─ HealthComponent       damage, hurt/defeat feedback, token release on death
└─ EquipmentComponent    weapons, attack geometry/damage/timing when armed
```

## Core systems

- **Grid** (`scripts/core/grid_world.gd`) — the foundation. All positions/collisions
  are cell-based. Actors register, reserve a destination (`begin_move`), then commit
  (`finish_move`). Never sprite-overlap collision.
- **Player combat** — attacks are `AttackProfile` `.tres` (sword 1-cell, thrust
  2-cell). The attack is a coroutine: impact delay → damage → recovery.
- **Enemy AI** (`scripts/actors/free_enemy.gd`) — a state machine
  (OBSERVE→TELEGRAPH→COMMIT→RECOVER→DEFEATED) driving utility scoring: build
  candidate intents, score each from a `DecisionConfig`, pick the best, execute.
- **Telegraph + dodge** — enemies telegraph the cells they will hit, then resolve;
  damage only if the target's *current* cell is still in the locked set. Stepping
  out dodges. One shared attack token (`EncounterDirector`) prevents pile-ons.
- **Data model** — an `EnemyDefinition` `.tres` references `MovementConfig`,
  `DecisionConfig`, `AttackPattern`, `VisualDefinition`, `DifficultyProfile`, and an
  optional default `EnemyWeapon`. That is the entire "what makes this enemy unique".

## How to extend (editor only, no code)

- **New enemy**: `EnemyDefinition` + movement/decision/attack/visual `.tres` + a
  scene variant on the generic `EnemyActor`.
- **New attack shape**: a `cell_offsets` list in an `AttackPattern` `.tres`.
- **New weapon**: an `EnemyWeapon`/`AttackProfile` `.tres` + a texture.
- **New room / layout**: drag the marker nodes, paint the TileMap.

## Reading order (learn the codebase)

1. `core/grid_world.gd`, `actors/grid_actor.gd` — the board + how bodies move.
2. `combat/attack_profile.gd`, `actors/pawn_hero.gd` — one full player action.
3. Data schemas: `data/movement_config.gd`, `ai/attack_pattern.gd`,
   `data/decision_config.gd`, `data/enemy_definition.gd`.
4. AI: `ai/enemy_context.gd`, `ai/enemy_intent.gd`, `combat/encounter_director.gd`,
   then `actors/free_enemy.gd` (the big one).
5. Composition: `components/*`, then `entities/enemy_actor.gd`.
6. Assembly: `world/grid_marker.gd` + markers, `world/room_encounter.gd`,
   `main.gd` (read last).

Presentation (`visuals/*`, `world/prototype_board.gd`, `ui/hud.gd`) only when needed.
Read `tests/run_tests.gd` alongside step 4 — the assertion names are the spec.

## Testing

`tests/run_tests.gd` (logic suite, ~150 assertions) plus 6 runtime SceneTree tests
(attack, movement, equipment, knight movement, room, HUD). Run headless:

```bash
HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot --headless --path . -s tests/run_tests.gd
```

New global classes (e.g. a new `class_name`) need one `--editor --quit` import pass
before strict-typed scripts referencing them will parse headlessly.
