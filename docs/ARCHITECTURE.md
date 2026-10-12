# Architecture

The Unbound Pawn — a 2D top-down grid-combat RPG in Godot 4.6.3. This document
describes the code **as it is built today** (checked against `scripts/` on
2026-10-12, branch `game-base`). The simulation is a full ECS; the node-composition
architecture that older docs described (`GridWorld`, `FreeEnemy`, `PawnHero`,
`EnemyActor`, `EncounterDirector`, per-actor component nodes) was deleted in the ECS
conversion (`docs/ecs-conversion-plan.md`, owner decision 2026-07-19).

Pair this file with `docs/coding-standards.md` (conventions), `AGENTS.md` (workflow),
`CLAUDE.md` (binding rules) and `docs/where-we-are.md` (status). Where those disagree
with the code, the code wins; where `CLAUDE.md` disagrees with this file, `CLAUDE.md`
wins until the owner approves a change.

## The idea in one paragraph

Scenes are **spawn data and puppets**. Parked `ActorView` nodes in a room scene say
what spawns where; at boot `EcsBoot` turns each into an **entity** (an integer id) with
**components** (pure data) in an `EcsWorld`. **Systems** read and write components in a
fixed order each frame, and tell the outside world what happened by pushing **events**
onto a queue. The `ViewSyncSystem` is the only system that touches nodes: it moves and
animates the puppet views from component data. `scripts/main.gd` is a thin **bridge**: it
builds the world, ticks it, then drains the event queue into HUD text, board overlays,
camera shake, sound and zone travel. Tuning lives in `.tres` Resources.

## The ECS contract

| Concept | Where it lives | Rule |
|---|---|---|
| Entity | an `int` from `EcsWorld.create_entity()` | no behaviour, no node |
| Component | an inner class of `scripts/ecs/ecs_components.gd` (`EcsComponents.Health`, ...) plus a `StringName` key const (`EcsComponents.HEALTH`) | pure data; no decisions |
| Store | `EcsWorld.store_by_component`: component key -> `{entity id -> component}` | access only through `add_component` / `get_component` / `has_component` / `remove_component` / `query` |
| System | a class extending `EcsSystem` in `scripts/ecs/systems/` | reads and writes components, never calls another system, never touches a node (except `ViewSyncSystem`) |
| World | `EcsWorld` (a `Node`) | owns the stores, the systems list, the grid, the event and damage queues, and the attack token |
| Events | `EcsWorld.emit_event({"type": &"...", ...})`, read once per frame with `drain_events()` | the only channel from simulation to presentation |
| Damage queue | `EcsWorld.damage_events`: `[{target, amount, direction}]` | written by `CombatSystem` and `EnemyAISystem`, drained only by `HealthSystem` |
| Spatial index | `EcsWorld.grid` (`EcsGrid`) | cell occupancy, blocks, move reservations, A*, doors, gates, floor items |

`EcsWorld.tick(delta)` calls every system in registration order. `main.gd` sets
`manual_tick = true` and ticks the world from its own `_process`, so a room that has
ended (`room_ending`) simply stops ticking. Tests also drive `tick(delta)` by hand.

## Folder structure (what exists today)

```text
project.godot        main scene scenes/main.tscn; autoloads SfxManager, WorldState
default_bus_layout.tres  audio buses (Master <- SFX / Music / UI)

scenes/              entry, rooms and UI scenes the owner opens directly
  main.tscn          the one game scene (Main + PrototypeBoard + PawnHero + CurrentZone + HUD ...)
  rooms/             first_encounter, t1..t4, b1, h1 (Stage 1) — RoomEncounter scenes
  zones/             the_kingdom.tscn (the old one-big-board world, still in the world graph)
  ui/                hud.tscn, rule_book.tscn
objects/             reusable prefabs
  actors/            player.tscn, black_pawn.tscn, knight_enemy.tscn, bishop_enemy.tscn, enemy_base.tscn
  markers/           blocker, gate, pickup_spawn_point, player_unlock markers
  world/             prototype_board, room_encounter, weapon_pickup, tilemap scenes
  visuals/           weapon_pickup_visual.tscn
  audio/             sfx_manager.tscn
resources/           .tres data: enemies/ movement/ decisions/ attacks/ weapons/ visuals/
                     difficulty/ objectives/ rules/ tiles/ world/
scripts/
  ecs/               the simulation: ecs_world, ecs_grid, ecs_system, ecs_components,
                     ecs_boot, ecs_actor_factory, actor_view, systems/, components/
  data/ ai/ combat/  Resource schemas (EnemyDefinition, MovementConfig, DecisionConfig,
                     AttackPattern, AttackProfile, EnemyWeapon, WorldGraph, RuleBook, ...)
  world/             room markers, RoomEncounter, PrototypeBoard, CameraRig, WorldState
  ui/ visuals/ audio/ presentation: GameHud, RuleBookUI, PickupVisual, SfxManager
  main.gd            the bridge (605 lines)
tests/               run_tests.gd + six runtime tests (see Testing)
tools/               generators and one-off build scripts (never shipped)
assets/              raw art, sfx, music (generated art is gitignored; README explains the build)
docs/                this file, coding-standards.md, plans, design/, archive/
```

The folder ownership rules in `CLAUDE.md` still apply (`scenes/` = entry/rooms/ui only,
`objects/` = prefabs, `resources/` = data, `scripts/` = behaviour, `assets/` = raw art,
`tools/` = build scripts). See "Where this is going" for the planned re-organisation.

## Runtime flow

```text
scenes/main.tscn  ->  Main (scripts/main.gd)
  _ready()      reads WorldState (which zone, which entry), swaps the zone node if the
                run was saved elsewhere, then calls _boot_zone(entry_id)
  _boot_zone()  1. _make_world(): new EcsWorld + the six systems (order below)
                2. EcsBoot.boot(world, player_view, room_root, ...) -> the "cast"
                3. reapply persistence (taken pickups, opened gates, unlocks, health carry)
                4. board.setup(grid, world), camera_rig.setup(grid), HUD setup
  _process()    ecs.tick(delta)  ->  _handle_events(ecs.drain_events())  ->  HUD refresh
```

Death and `R` reload the scene; `WorldState` (an autoload) remembers the zone and entry
so the reload boots in the right place. Zone travel (`zone_exit` event) fades out,
swaps the zone scene node, **rebuilds the whole `EcsWorld`**, and fades in. No entity
survives. What carries over is the player view node, `WorldState` (including the carried
health), and the HUD, board and camera nodes, which are re-bound by `setup()`.

### System order (the schedule, set in `Main._make_world`)

| # | System | Reads | Writes / emits |
|---|---|---|---|
| 1 | `PlayerInputSystem` | the `Input` singleton, `PLAYER_TAG`, `PLAYER_INPUT`, `MOVE_STATE` | `MOVE_INTENT` (buffered and held-key steps), `FACING` (turn in place), `ATTACK_INTENT` |
| 2 | `EnemyAISystem` | `ENEMY_AI`, `GRID_POS`, `FACING`, `MOVE_STATE`, the grid, the hero | `MOVE_INTENT`, `FACING`, `ENEMY_AI` state, `WEAPON_SLOT` (pickup), `damage_events`; owns the attack token; emits `intent_changed`, `telegraph_started/finished`, `attack_resolved`, `pickup_taken`, `weapon_changed` |
| 3 | `MovementSystem` | `MOVE_INTENT`, `MOVE_STATE`, `GRID_POS` | reserve -> commit through the grid; `GRID_POS`, `MOVE_STATE`; emits `step_started/finished/blocked`, `gate_opened`, `zone_exit`, `zone_exit_locked`, `player_unlock` |
| 4 | `CombatSystem` | `ATTACK_INTENT`, `PLAYER_COMBAT`, `GRID_POS`, `FACING` | attack lifecycle as timers; `damage_events`; emits `attack_started`, `attack_landed`, `attack_locked`, `skill_cooldown` |
| 5 | `HealthSystem` | `damage_events` | `HEALTH`; defeat (disables player control, or unregisters an enemy and frees the token); emits `damaged`, `defeated` |
| 6 | `ViewSyncSystem` | almost everything, read-only | the **only** node writes: position, depth (`z_index = 2 + row`), tint, aura, facing arrow, weapon, health pips, `AnimationTree` conditions and `travel()` |

Enemy AI is a utility scorer (`EnemyIntent`: attack, move, pickup, turn, wait) driving a
state machine (`STATE_OBSERVE -> TELEGRAPH -> RECOVER -> OBSERVE`, plus `DEFEATED`;
`STATE_COMMIT` is defined and handled but nothing enters it today). An
enemy attacks only if it holds the room's single **attack token**
(`EcsWorld.attack_token_owner`). A strike locks its cells when the telegraph starts and
damages the hero only if the hero's *current* cell is still in that locked set, which is
what makes dodging possible. Enemies target the hero's **reserved** destination while the
hero slides, never buffered input. An idle enemy only starts deciding once the hero is
inside its `aggro_radius` (the leash).

## Components (the 13 keys in `ecs_components.gd`)

| Key | Class | Holds |
|---|---|---|
| `GRID_POS` | `GridPos` | `cell` |
| `FACING` | `Facing` | `direction` |
| `MOVE_INTENT` | `MoveIntent` | `direction` (consumed by `MovementSystem` each tick) |
| `MOVE_STATE` | `MoveState` | `from_cell`, `to_cell`, `progress`, `duration`, `moving` |
| `PLAYER_TAG` | `PlayerTag` | `control_enabled` |
| `PLAYER_INPUT` | `PlayerInput` | buffered direction, hold time, `held_repeat_delay` |
| `ATTACK_INTENT` | `AttackIntent` | `kind`: `none` / `sword` / `skill` (consumed by `CombatSystem`) |
| `PLAYER_COMBAT` | `PlayerCombat` | the two `AttackProfile`s, `sword_unlocked`, cooldown and swing timers, `pending_cells` |
| `HEALTH` | `Health` | `current`, `max_value`, invulnerability and flash timers, `recoil` |
| `ENEMY_AI` | `EnemyAI` | state, timers, `decision_profile`, `attack_pattern`, `allowed_directions`, memories, `locked_attack_cells` |
| `WEAPON_SLOT` | `WeaponSlot` | the equipped `EnemyWeapon` |
| `PICKUP_ITEM` | `PickupItem` | the floor `EnemyWeapon` |
| `VIEW_REF` | `ViewRef` | the puppet `Node2D` plus clip edge-detection memory (view-side bookkeeping) |

`ecs_components.gd` is one file of inner classes (135 lines). New state means a new inner
class plus a key const there (see `docs/coding-standards.md`).

## The grid (`EcsGrid`)

`EcsWorld.grid` is the spatial service, defaults `cell_size = 32`, `grid_origin = (64, 36)`,
`bounds = (0, 0, 16, 9)` (a room's `board_size` overrides the bounds at boot). Its
dictionaries are all documented in the file:

- `blocked_cells`, `entity_by_cell`, `cell_by_entity`, `move_reservations`, `item_by_cell`.
- Baked door and gate data: `exit_by_cell` (zone exits), `gate_by_cell` (one-way shortcut
  gates), `player_unlock_by_cell` (player verb unlocks).
- The movement protocol is **reserve -> commit**: `begin_move` claims the destination before
  the slide, `finish_move` lands it. While sliding, the origin stays occupied and the
  destination reserved, so nobody can race into either.
- Pathing: `get_grid_path` builds an `AStarGrid2D` per call (no diagonals; other movers and
  reservations are solid). Gameplay is cell-based; there is no physics collision.

## Authoring: scenes as spawn data

| Piece | File | What it does |
|---|---|---|
| `ActorView` | `scripts/ecs/actor_view.gd` | the puppet and spawn marker. `definition: EnemyDefinition` (null on the player) plus appearance exports (tints, weapon anchor, pip textures). No logic. |
| `EntityComponent` nodes | `scripts/ecs/components/` | Inspector-draggable children of an `ActorView`; `EcsBoot` calls `apply(world, entity_id)` at spawn. Six exist: `CombatComponent`, `HealthComponent`, `InputComponent`, `MovementComponent` (the player's kit; `HealthComponent` and `MovementComponent` also work as per-instance overrides) and `AIComponent`/`WeaponComponent` (per-instance enemy overrides). A node on an instance beats the definition. Zero logic. |
| `EcsBoot` | `scripts/ecs/ecs_boot.gd` | static `boot(...)`: sizes the grid from `RoomEncounter.board_size`, bakes solid tiles, `ZoneExitMarker`, `PlayerUnlockMarker` and `GateMarker`; spawns the player, then every `ActorView` child of the room that has a `definition`, then pickups. Returns the cast dictionary (`player`, `enemies`, `view_by_entity`, `piece_name_by_entity`, pickup maps). |
| `EcsActorFactory` | `scripts/ecs/ecs_actor_factory.gd` | `spawn_player`, `spawn_enemy`, `spawn_pickup`: assemble an entity's components from the `.tres` data and apply the difficulty multipliers. |
| `RoomEncounter` | `scripts/world/room_encounter.gd` | a room scene root: `board_size`, `zone_id`, prose, and a `RoomObjective`. It carries data only. |
| Markers | `scripts/world/*_marker.gd`, `pickup_spawn_point.gd` | `GridMarker` base (drag to snap, writes `grid_cell`). `ZoneEntryMarker`/`ZoneExitMarker` (doors), `GateMarker`, `PlayerUnlockMarker`, `PickupSpawnPoint`. `BlockerMarker` is a legacy marker `EcsBoot` no longer bakes; walls are painted tiles. |
| Walls | `RoomArt/TileMap` | any tile whose custom data `solid = true` becomes a blocked cell. Paint = collision. |

Enemies are real scene children: instance `black_pawn.tscn` (or knight, bishop) in a room,
park it on a cell, and override `definition` to vary it. What the editor shows is what spawns.

## The data model

`EnemyDefinition` (`.tres`) composes shared sub-resources: `MovementConfig`,
`DecisionConfig`, `AttackPattern` (the unarmed attack), `VisualDefinition`,
`DifficultyProfile` and an optional default `EnemyWeapon`. The player's kit uses
`AttackProfile` `.tres` files (`wooden_sword`, `pencil_thrust`). `RuleBook`/`RuleEntry`
(the Book of House Rules), `RoomObjective` and `WorldGraph` (zone id -> room scene) are
the other schemas. Shared Resources are treated as immutable at runtime; instances
`duplicate(true)` before mutating (a picked-up weapon).

**Enemy locomotion is the piece's own chess law**, and it is data: `MovementConfig.
allowed_directions` is a list of offsets, one move per step. Pawns use the four cardinal
offsets (the Charging Pawn two-cell cardinal offsets), the Bishop the four diagonals (`resources/movement/bishop_diagonal.tres`), the
Knight the eight L offsets (`knight_standard.tres`), landing on a free cell. The June
"all enemies move cardinally" note in `findings.md` is superseded
(`docs/game-base-plan.md` D-08). Equipping a weapon replaces the piece's chess-shaped
*attack*, not its movement.

## The event contract

19 event types exist. `main.gd` `_handle_events` matches 15 of them; the other four
(`step_started`, `step_finished`, `step_blocked`, `attack_started`) are emitted for tests
and future presentation.

| Event | Payload keys | Handled by |
|---|---|---|
| `step_started` / `step_finished` | `entity`, `cell` | — |
| `step_blocked` | `entity`, `direction` | — |
| `attack_started` | `entity`, `cells` | — |
| `attack_landed` | `entity`, `cells`, `hit_count`, `profile` | bridge: board flash, camera shake, status |
| `attack_locked` | `entity` | bridge: status ("no weapon yet") |
| `skill_cooldown` | `entity`, `time_left` | bridge: HUD bar |
| `telegraph_started` / `telegraph_finished` | `entity` (+ `cells`) | board overlay |
| `attack_resolved` | `entity`, `cells` | board overlay |
| `intent_changed` | `entity`, `intent` | board debug paths |
| `damaged` | `entity`, `amount`, `remaining` | bridge: shake, HUD courage, damage flash |
| `defeated` | `entity` | bridge: despawn timer, room completion, player death/reload |
| `pickup_taken` | `item`, `cell` | bridge: `WorldState`, pickup sound, free the pickup view |
| `weapon_changed` | `entity`, `weapon` | bridge: status text |
| `player_unlock` | `entity`, `id`, `message` | bridge: `WorldState`, unlock the sword |
| `gate_opened` | `entity`, `gate`, `cell` | bridge: `WorldState`, hide the gate visual |
| `zone_exit` | `entity`, `zone`, `entry` | bridge: zone travel |
| `zone_exit_locked` | `entity`, `zone`, `entry`, `cell` | bridge: locked-door message |

## Presentation and the bridge

Presentation consumes `drain_events()` and never decides gameplay.

- `scripts/main.gd` — the bridge and zone-travel host (see Runtime flow). It owns fades,
  the Book toggle, the F3 debug view, F11 fullscreen and scene reload.
- `PrototypeBoard` — the combat overlay: telegraph cells, hit flashes, F3 debug paths. The
  one place `_draw()` is allowed for gameplay overlays.
- `GameHud` (`CanvasLayer`) — courage, skill cooldown, enemy count, status, damage flash,
  result panel. It owns all its own formatting.
- `CameraRig` — a `Camera2D` that is a child of the player view (so it follows by tree
  parenting), clamps to the board rect and shakes via the built-in offset.
- `RuleBookUI` — the Book of House Rules screen (key `B`).
- `SfxManager` (autoload) — pooled one-shot playback for event sounds with no clip. Motion
  sounds are audio tracks in the actor's `AnimationPlayer` clips. Only the bridge calls it.
- Actor scenes — `Sprite2D`s under `MotionRoot/SpriteRoot`, a sibling `AnimationPlayer`
  for clips, and an `AnimationTree` state graph (states, transitions, crossfades are
  editor-owned; `ViewSyncSystem` publishes conditions and calls `travel()` on event edges).
  The cell-to-cell slide is procedural (`MovementSystem` progress -> `ViewSyncSystem`
  position) so the dodge window is gameplay timing, never keyframed.

## Persistence

`WorldState` (autoload, `scripts/world/world_state.gd`) is pure data saved to
`user://world_state.cfg` (`ConfigFile`, `SAVE_VERSION = 2`): current zone and entry,
taken pickups, opened gates, read Book pages, player unlocks. Health is carried across a
zone travel but is never saved. The bridge writes it from events and feeds it back into
`EcsBoot` on every boot.

## Known deviations from the rules (honest list)

These exist today and are scheduled to be fixed by `docs/game-base-plan.md` §14, not by
ad-hoc edits:

- The bridge and `PrototypeBoard` read components directly (`ecs.get_component(...)`), and
  `main.gd` writes a few (`PlayerTag.control_enabled`, `PlayerCombat.sword_unlocked`, the
  health carry, removing `VIEW_REF`). The plan replaces this with a `world.commands` request
  queue and a read-only `HudSnapshot` (M3a).
- `PlayerInputSystem` polls the `Input` singleton, and `main.gd` polls raw keys (`R`, `F3`,
  `F11`, `B`). The plan moves input behind an `InputSnapshot` and `InputMap` actions.
- `ViewSyncSystem` blinks the invulnerability tint from the wall clock.
- `main.gd` (605 lines) still holds travel, death, persistence and HUD wiring together.
- The 72x40 kingdom (`scenes/zones/the_kingdom.tscn`) is still a zone in the shipped world
  graph, and `first_encounter` is a standalone room only the tests load; the plan turns
  both into test fixtures.

## Reading order

1. `scripts/ecs/ecs_world.gd`, `ecs_components.gd`, `ecs_system.gd` — the whole ECS in ~250 lines.
2. `scripts/ecs/ecs_grid.gd` — the board and the reserve -> commit protocol.
3. `scripts/ecs/systems/player_input_system.gd` -> `movement_system.gd` — one full step.
4. `scripts/ecs/systems/combat_system.gd` -> `health_system.gd` — one full attack.
5. Data schemas: `scripts/data/*`, `scripts/ai/attack_pattern.gd`, `scripts/combat/*`.
6. `scripts/ecs/systems/enemy_ai_system.gd` — the big one (337 lines).
7. `scripts/ecs/ecs_boot.gd`, `ecs_actor_factory.gd`, `actor_view.gd`, `components/*`.
8. `scripts/ecs/systems/view_sync_system.gd`, then `scripts/main.gd` last.

Read `tests/run_tests.gd` and `tests/ecs_*_test.gd` alongside — the assertion labels are
the spec.

## Testing

`tests/run_tests.gd` (data and structure: grid rules, actor scenes as pure views, the
`.tres` content) plus six runtime `SceneTree` tests: `ecs_runtime`, `ecs_combat`,
`ecs_enemy`, `room_encounter_runtime`, `encounter_hud_runtime`, `zone_travel_runtime`.
Run them with `/verify` (see `.claude/commands/verify.md`) or by hand:

```bash
HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot --headless --path . -s tests/run_tests.gd
```

A new `class_name` needs one `--headless --editor --quit` import pass before strict-typed
scripts that reference it parse headlessly. A script error in a test's `_init` can hang the
Godot process, so bound runs with `perl -e 'alarm shift; exec @ARGV' 120 ...` (macOS has no
`timeout`). `python3 tools/run_all_tests.py` becomes the canonical runner in M1a.

## Where this is going

`docs/game-base-plan.md` §13 describes a target tree: `content/` (the owner's data, art,
audio and words, zero `.gd`), `schema/` (Resource classes), `ecs/` (simulation, with
systems grouped by phase and the order kept as data), `authoring/` (things dragged into a
scene), `presentation/`, and `shell/`. The ECS contract above is kept as is. **None of that
tree is built yet**; M1b moves the files with scripted, one-folder-per-commit migrations
once the owner approves the `CLAUDE.md` changes at gate OG0. Until then, every path in this
document is the real, current one.
