# ECS Conversion Plan

Owner decision (2026-07-19): convert the runtime to full ECS ("go for ecs", picked
"Full ECS conversion" over hybrid/stay). This supersedes the node-composition
actor architecture (phases 70-71) and amends the editor-first rule as described
in "Authoring doctrine" below.

## Architecture

- **Entity** = integer id. No behavior, no node.
- **Component** = pure data (typed inner classes in `scripts/ecs/ecs_components.gd`).
  No methods beyond trivial constructors.
- **System** = logic that queries entities by component set and mutates data.
  Ticked in fixed order by the world each frame.
- **World** (`scripts/ecs/ecs_world.gd`, `EcsWorld extends Node`) = component
  stores (`store_by_component: component name → {entity_id → data}`), entity
  lifecycle, system registry + tick loop, and an event queue
  (`pending_events: Array[Dictionary]`) for cross-system messages
  (damage, attack_landed, defeated, pickup_taken) that the HUD/camera bridge
  consumes after each tick.
- **GridWorld survives** as the spatial-index service owned by the world
  (occupancy, reservations, A*). It stops being a node parent of actors;
  `actor` refs in its dictionaries become entity ids.
- **Views are puppets.** The flattened actor scenes (sprites + AnimationPlayer,
  phase 70) lose their gameplay scripts and become view scenes driven by
  `ViewSyncSystem` from component data. No view reads input; no system touches
  a sprite directly.

## Authoring doctrine (amends editor-first)

Scenes stop being behavior owners and become **spawn data + presentation**:
parked view instances in `main.tscn` / room scenes define what spawns where
(position → cell, Inspector overrides → component values). At boot, `main.gd`
reads them, creates entities, and keeps the nodes as puppet views. Painting
solid tiles stays the wall-authoring mechanism (feeds GridWorld blocks).
Tuning stays in `.tres` (EnemyDefinition, AttackProfile, DecisionConfig...) —
resources become component templates.

## Components (initial set)

| Component | Data | Replaces |
|---|---|---|
| `GridPos` | `cell` | GridActor.current_cell |
| `Facing` | `direction` | GridActor.facing |
| `MoveIntent` | `direction` | input/AI step requests |
| `MoveState` | `from_cell, to_cell, progress, duration, moving` | GridActor tween |
| `PlayerTag` | `control_enabled` | PawnHero identity |
| `PlayerCombat` | `wooden_sword, pencil_thrust, attack_on_cooldown, cooldown_left, skill_cooldown_left, active_attack, attack_visual_time, impact_timer, pending_cells` | PlayerCombatComponent |
| `Health` | `current, max, invulnerable_left, flash_left, hurt_visual_time` | courage + enemy health |
| `EnemyAI` | `state, state_time_left, decision_profile, definition, action_memory, recent_cells, committed_goal..., locked_cells` | FreeEnemy state machine |
| `EnemyWeaponSlot` | `weapon` | equipment |
| `PickupItem` | `weapon` | WeaponPickup data |
| `ViewRef` | `node` | render binding |

## Systems (tick order)

1. `PlayerInputSystem` — keys → MoveIntent / attack + skill events / turn.
2. `EnemyAISystem` — observe/decide (ports free_enemy scoring verbatim).
3. `MovementSystem` — resolves MoveIntent via GridWorld reserve→commit,
   advances MoveState progress.
4. `CombatSystem` — attack token, telegraph timers, hero attack impact,
   damage events into the queue.
5. `HealthSystem` — consumes damage events, invulnerability, defeat, death.
6. `PickupSystem` — entity-on-cell weapon collection.
7. `ViewSyncSystem` — writes positions/clips/tints/weapon sprites to ViewRef
   nodes (the only system allowed to touch nodes).

## Phases (each ends green + committed; node game keeps running until D)

- **A. Core + movement slice** — world, components, queries, events;
  PlayerInput/Movement/ViewSync; ECS runtime test: hero entity steps with
  reservation rules, blocked cells, view follows. Node game untouched.
- **B. Combat slice** — CombatSystem + HealthSystem + hero attacks; port
  dodge/token/invulnerability tests to ECS.
- **C. Enemy AI slice** — EnemyAISystem (scoring port), telegraphs, pickups,
  EnemyDefinition → component template factory.
- **D. Flip + delete** — main.gd boots EcsWorld from scene data; HUD/camera
  bridge consumes events; strip gameplay scripts from actor scenes (views);
  delete pawn_hero.gd behavior, free_enemy.gd, enemy_actor.gd, player/enemy
  behavior components; port remaining tests; update CLAUDE/AGENTS/vault docs.

## Rules for the conversion

- Never half-flip: until phase D lands whole, `scenes/main.tscn` runs the node
  game and all existing tests stay green.
- Systems never call node APIs except ViewSyncSystem.
- Components hold no logic; if a "component" grows a method with a decision in
  it, it's a system.
- Port AI scoring math verbatim first, refactor later — behavior parity before
  cleanup.
