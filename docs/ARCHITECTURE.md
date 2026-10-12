# Architecture

The Unbound Pawn — a 2D top-down grid-combat RPG in Godot 4.6.3. This document
describes the code **as it is built today** (checked against the tree on 2026-10-12, at
the end of milestone M1b, the folder migration). The simulation is a full ECS; the
node-composition architecture that older docs described (`GridWorld`, `FreeEnemy`,
`PawnHero`, `EnemyActor`, `EncounterDirector`, per-actor component nodes) was deleted in
the ECS conversion (`docs/ecs-conversion-plan.md`, owner decision 2026-07-19). The folders
were rearranged in M1b to the tree of `docs/game-base-plan.md` section 13; the move is
recorded file by file in `docs/migration-notes.md` and `tools/move_res_log.tsv`.

Pair this file with `docs/coding-standards.md` (conventions), `AGENTS.md` (workflow),
`CLAUDE.md` (binding rules), `docs/OWNER_GUIDE.md` (how the owner changes things) and
`docs/where-we-are.md` (status). Where those disagree with the code, the code wins; where
`CLAUDE.md` disagrees with this file, `CLAUDE.md` wins until the owner approves a change.

## The idea in one paragraph

Scenes are **spawn data and puppets**. Parked `ActorView` nodes in a room scene say
what spawns where; at boot `EcsBoot` turns each into an **entity** (an integer id) with
**components** (pure data) in an `EcsWorld`. **Systems** read and write components in a
fixed order each frame, and tell the outside world what happened by pushing **events**
onto a queue. The `ViewSyncSystem` is the only system that touches nodes: it moves and
animates the puppet views from component data. `shell/game_root.gd` is a thin **bridge**:
it builds the world, ticks it, then drains the event queue into HUD text, board overlays,
camera shake, sound and zone travel. Tuning lives in `.tres` Resources under `content/`.

## The ECS contract

| Concept | Where it lives | Rule |
|---|---|---|
| Entity | an `int` from `EcsWorld.create_entity()` | no behaviour, no node |
| Component | an inner class of `ecs/components/ecs_components.gd` (`EcsComponents.Health`, ...) plus a `StringName` key const (`EcsComponents.HEALTH`) | pure data; no decisions. The file is frozen except for edits to existing classes: a new component is its own file in `ecs/components/` with a `KEY` const |
| Store | `EcsWorld.store_by_component`: component key -> `{entity id -> component}` | access only through `add_component` / `get_component` / `has_component` / `remove_component` / `query` |
| System | a class extending `EcsSystem` in `ecs/systems/<phase>/` | reads and writes components, never calls another system, never touches a node (except `ViewSyncSystem`) |
| World | `EcsWorld` (a `Node`) in `ecs/core/` | owns the stores, the systems list, the grid, the event and damage queues, and the attack token |
| Events | `EcsWorld.emit_event({"type": &"...", ...})`, read once per frame with `drain_events()` | the only channel from simulation to presentation |
| Damage queue | `EcsWorld.damage_events`: `[{target, amount, direction}]` | written by `CombatSystem` and `EnemyAISystem`, drained only by `HealthSystem` |
| Spatial index | `EcsWorld.grid` (`EcsGrid`) in `ecs/core/` | cell occupancy, blocks, move reservations, A*, doors, gates, floor items |

`EcsWorld.tick(delta)` calls every system in registration order. `game_root.gd` sets
`manual_tick = true` and ticks the world from its own `_process`, so a room that has
ended (`room_ending`) simply stops ticking. Tests also drive `tick(delta)` by hand.

## Folder structure (what exists today)

The top-level folders are layers. Each has one job, and the table after the tree says which
layer may name which.

```text
project.godot            main scene shell/game_root.tscn; autoloads SfxManager, WorldState
default_bus_layout.tres  audio buses (Master <- SFX / Music / UI / Voice)

content/                 THE OWNER'S FOLDER: data, art, audio, words. Zero .gd files (test-enforced).
                         Folder name = id; a leading underscore (_shared) is not an id.
  _placeholders.json     sha256 of every file that is still a stand-in for the owner's art or audio
  difficulty/            standard.tres (global health and damage multipliers)
  enemies/<id>/          enemy.tres (EnemyDefinition) + the enemy's own movement / decision /
                         unarmed_attack / visual .tres and body.png (pawn_recruit, pawn_armed,
                         backstep_pawn, charging_pawn, black_pawn_captain, knight_tracker, bishop_zoner)
  enemies/_shared/       sub-resources several pawns share: movement/ attacks/ decisions/ visuals/
  pickups/<id>/          the floor weapons (EnemyWeapon .tres) and their pictures
  player/                player.tres (PlayerDefinition), visual.tres (its VisualDefinition), body.png, icon.png
  feel/                  piece_sizes.tres: how big each kind of piece is drawn inside its cell
  rooms/<id>/            room.tscn (a RoomEncounter) and, for T1 and T2, background.png
  rules/<id>/page.tres   Book of House Rules pages; rule_book.tres lists them
  skills/<id>/           the Wooden Sword and Pencil Thrust AttackProfile .tres and the sword icon
  tilesets/<kit>/        tileset.tres + tilemap.tscn (kingdom, playground); tile_map_data is binary
  world/world.tres       WorldGraph: zone id -> room scene

schema/                  THE SHAPE OF CONTENT: one Resource class per file
  entity/                EnemyDefinition, PlayerDefinition, VisualDefinition, MovementConfig, DecisionConfig, EnemyIntent
  attacks/               AttackPattern, AttackProfile, EnemyWeapon
  world/                 WorldGraph, RoomObjective, RuleBook, RuleEntry
  feel/                  DifficultyProfile, PieceSizeTable, PieceSize

ecs/                     THE SIMULATION: rules only; no art, prose or tuning numbers
  core/                  EcsWorld, EcsGrid, EcsSystem
  components/            ecs_components.gd (frozen)
  systems/<phase>/       input/PlayerInputSystem  decide/EnemyAISystem  move/MovementSystem
                         act/CombatSystem  resolve/HealthSystem  view/ViewSyncSystem

authoring/               THINGS YOU DRAG INTO A SCENE: Inspector data + apply(); no logic
  ecs_boot.gd            the baker: reads a room scene, builds the world (EcsBoot)
  ecs_actor_factory.gd   builds actor entities from definitions (EcsActorFactory)
  entity_components/     EntityComponent nodes (Combat, Health, Input, Movement, AI, Weapon)
  markers/               zone entry/exit, gate, player unlock, pickup spawn, blocker (+ their scenes)
  room_encounter.gd/.tscn  the room scene root

presentation/            HOW THE WORLD IS SHOWN: reads events, never decides
  views/                 actor_view.gd, weapon_pickup + pickup_visual, and actors/: actor_view_base.tscn
                         (the one actor view) and the thin scenes that inherit it (player, black_pawn,
                         knight_enemy, bishop_enemy)
  ui/hud/  ui/codex/     GameHud scene, the Book of House Rules screen
  board/                 PrototypeBoard (telegraphs, F3 debug) and GridLinesOverlay
  camera/                CameraRig
  audio/                 SfxManager (autoload scene)

shell/                   THE GAME AROUND THE GAME
  game_root.gd/.tscn     the one game scene and its bridge (605 lines; split in M3b)
  save/world_state.gd    WorldState autoload: zone, entry, taken pickups, opened gates, read pages

assets/                  shared raw art and audio not owned by one content item
  tiles/<kit>/atlas.svg  tile atlases   ui/actor_view/  the overlay pictures every actor view shares
  map_pieces/            the owner's hand-drawn bedroom pieces   sfx/ music/   audio
  concept-art/           references, never shipped   _generated/   generator output (gitignored)

tools/                   generators, the runner, the migration scripts (never shipped; tools/README.md)
tests/                   run_tests.gd + six runtime tests + architecture/ audio/ bridge/ content/ support/
                         fixtures/ (the 72x40 kingdom, first_encounter, the harness fixtures) baselines/
docs/                    this file, coding-standards.md, OWNER_GUIDE.md, plans, design/, archive/
```

Not built yet (the plan's later milestones): `ecs/events/`, `ecs/schedule/`, `schema/skills`,
`schema/progression`, `schema/story`, `schema/audio`,
`shell/title|pause|settings|credits`, `presentation/story|vfx|bridges`, `content/story|audio|ui|bosses|props|progression` and the rest of `content/feel`,
`authoring/markers/` beyond today's.

### Which layer may name which

Checked on every run by `tests/architecture/test_dependency_edges.gd` (the real `class_name`
graph, ENFORCING) and `tests/architecture/test_content_references.gd` (what `content/` may
reference). Starting-point table from `docs/game-base-plan.md` 13.1:

| From | May depend on |
|---|---|
| `content` | `schema`, `authoring`, `presentation/views` base scenes, `assets` (and itself) |
| `schema` | engine only |
| `ecs` | `schema`; one documented exception: `ViewSyncSystem -> ActorView` (the art-contract test will guard the node paths) |
| `authoring` | `ecs/core`, `ecs/components`, `schema` |
| `presentation` | `ecs/events`, `schema`, `HudSnapshot`. Never `ecs/components` |
| `shell` | everything |

Five edges and six room references are not decided by the owner yet and are printed on
every run (report-only, an entry nothing uses fails the suite): `EcsBoot` and `EntityComponent`
name `ActorView`; `PickupSpawnPoint` names `WeaponPickup`; `PrototypeBoard` reads `EcsComponents`
and `EcsWorld`; the six Stage 1 rooms carry a `GridLinesOverlay` from `presentation/board/`. The
allowed-edge table is not frozen until the owner decides them (`docs/migration-notes.md`).

## Runtime flow

```text
shell/game_root.tscn  ->  Main (shell/game_root.gd)
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

The order is the list in `shell/game_root.gd`, mirrored by `tools/world_dumper.gd` (the
deterministic dump). The plan (M3a) turns it into data: one file per phase in
`ecs/schedule/`. The phase folders under `ecs/systems/` already exist.

| # | System (phase folder) | Reads | Writes / emits |
|---|---|---|---|
| 1 | `PlayerInputSystem` (`input/`) | the `Input` singleton, `PLAYER_TAG`, `PLAYER_INPUT`, `MOVE_STATE` | `MOVE_INTENT` (buffered and held-key steps), `FACING` (turn in place), `ATTACK_INTENT` |
| 2 | `EnemyAISystem` (`decide/`) | `ENEMY_AI`, `GRID_POS`, `FACING`, `MOVE_STATE`, the grid, the hero | `MOVE_INTENT`, `FACING`, `ENEMY_AI` state, `WEAPON_SLOT` (pickup), `damage_events`; owns the attack token; emits `intent_changed`, `telegraph_started/finished`, `attack_resolved`, `pickup_taken`, `weapon_changed` |
| 3 | `MovementSystem` (`move/`) | `MOVE_INTENT`, `MOVE_STATE`, `GRID_POS` | reserve -> commit through the grid; `GRID_POS`, `MOVE_STATE`; emits `step_started/finished/blocked`, `gate_opened`, `zone_exit`, `zone_exit_locked`, `player_unlock` |
| 4 | `CombatSystem` (`act/`) | `ATTACK_INTENT`, `PLAYER_COMBAT`, `GRID_POS`, `FACING` | attack lifecycle as timers; `damage_events`; emits `attack_started`, `attack_landed`, `attack_locked`, `skill_cooldown` |
| 5 | `HealthSystem` (`resolve/`) | `damage_events` | `HEALTH`; defeat (disables player control, or unregisters an enemy and frees the token); emits `damaged`, `defeated` |
| 6 | `ViewSyncSystem` (`view/`) | almost everything, read-only | the **only** node writes: position, depth (`z_index = 2 + row`), tint, aura, facing arrow, weapon, health pips, `AnimationTree` conditions and `travel()` |

Enemy AI is a utility scorer (`EnemyIntent`: attack, move, pickup, turn, wait) driving a
state machine (`STATE_OBSERVE -> TELEGRAPH -> RECOVER -> OBSERVE`, plus `DEFEATED`;
`STATE_COMMIT` is defined and handled but nothing enters it today). An
enemy attacks only if it holds the room's single **attack token**
(`EcsWorld.attack_token_owner`). A strike locks its cells when the telegraph starts and
damages the hero only if the hero's *current* cell is still in that locked set, which is
what makes dodging possible. Enemies target the hero's **reserved** destination while the
hero slides, never buffered input. An idle enemy only starts deciding once the hero is
inside its `aggro_radius` (the leash).

## Components (the 13 keys in `ecs/components/ecs_components.gd`)

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

`ecs_components.gd` is one file of inner classes (135 lines) and is frozen except for edits
to existing classes. New state means a new file in `ecs/components/` with a `KEY` const (see
`docs/coding-standards.md`).

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
| `ActorView` | `presentation/views/actor_view.gd` | the puppet and spawn marker. Spawn data: `definition: EnemyDefinition` (null on the player) or `player_definition: PlayerDefinition` (null on an enemy, `content/player/player.tres`); plus appearance exports (tints, facing mark, the `PieceSizeTable`), the in-cell knobs (`facing_mark_distance`, `weapon_anchor`, `weapon_rest_length`, `weapon_held_scale`) and the pictures (default weapon, pips). No logic. |
| Actor scenes | `presentation/views/actors/` | **One actor view**: `actor_view_base.tscn` holds the nodes, every clip and the one animation graph; `player.tscn`, `black_pawn.tscn`, `knight_enemy.tscn` and `bishop_enemy.tscn` inherit it and say only what is theirs (13 to 20 lines each; `test_one_actor_view` holds that). A new enemy needs no scene: instance the base and set `definition`. |
| `PieceSizeTable` | `schema/feel/piece_size_table.gd` (+ `piece_size.gd`), `content/feel/piece_sizes.tres` | the owner's rule that a piece is smaller than its cell, as data: per kind a body box, a base line (px below the cell centre) and a footprint in cells; `validate()` holds the margin and the chess heights; `body_top_left()` is the one placement formula. |
| `EntityComponent` nodes | `authoring/entity_components/` | Inspector-draggable children of an `ActorView`; `EcsBoot` calls `apply(world, entity_id)` at spawn. Six exist: `CombatComponent`, `HealthComponent`, `InputComponent`, `MovementComponent` (overrides of the player's `PlayerDefinition`; the player scene carries none, so `content/player/player.tres` is the only source) and `AIComponent`/`WeaponComponent` (per-instance enemy overrides). A node on an instance beats the definition, field by field. Zero logic. |
| `EcsBoot` | `authoring/ecs_boot.gd` | static `boot(...)`: sizes the grid from `RoomEncounter.board_size`, bakes solid tiles, `ZoneExitMarker`, `PlayerUnlockMarker` and `GateMarker`; spawns the player from the view's `PlayerDefinition` (class defaults when it names none) and applies its `EntityComponent` nodes, then every `ActorView` child of the room that has a `definition`, then pickups. Returns the cast dictionary (`player`, `enemies`, `view_by_entity`, `piece_name_by_entity`, pickup maps). |
| `EcsActorFactory` | `authoring/ecs_actor_factory.gd` | `spawn_player` (bare hero, kept), `spawn_player_from_definition` (what `EcsBoot` calls), `spawn_enemy`, `spawn_pickup`: assemble an entity's components from the `.tres` data and apply the difficulty multipliers. |
| `ContentDb` | `shell/content/content_db.gd` (+ `content_kind.gd`) | the content registry, a static class (no autoload, so it works inside a suite's `_init()`). Ids are folder names under `content/<kind>/`, listed lazily once per kind. `ids(kind)`, `fetch(kind, id)`, `all(kind)`, `player()`, `world()`, `piece_sizes()`, `validate()`, `validate_cross_refs()`. Ten kinds registered (one line each in `_ensure_kinds()`). Only the shell may name it; tests and tools call the two validators, nothing calls them at game start. |
| `RoomEncounter` | `authoring/room_encounter.gd` | a room scene root: `board_size`, `zone_id`, prose, and a `RoomObjective`. It carries data only. |
| Markers | `authoring/markers/` | `GridMarker` base (drag to snap, writes `grid_cell`). `ZoneEntryMarker`/`ZoneExitMarker` (doors), `GateMarker`, `PlayerUnlockMarker`, `PickupSpawnPoint`. `BlockerMarker` is a legacy marker `EcsBoot` no longer bakes; walls are painted tiles. |
| Walls | `RoomArt/TileMap` | any tile whose custom data `solid = true` becomes a blocked cell. Paint = collision. |

Enemies are real scene children: instance an actor scene from `presentation/views/actors/`
(`black_pawn.tscn`, `knight_enemy.tscn`, `bishop_enemy.tscn`, or `actor_view_base.tscn` itself) in a
room, park it on a cell, and override `definition` to vary it. What the editor shows is what spawns.

## The data model

`EnemyDefinition` (`content/enemies/<id>/enemy.tres`) composes sub-resources: `MovementConfig`,
`DecisionConfig`, `AttackPattern` (the unarmed attack), `VisualDefinition`,
`DifficultyProfile` and an optional default `EnemyWeapon`. The pieces several pawns share are
in `content/enemies/_shared/{movement,attacks,decisions,visuals}/`; an enemy's own are beside
its `enemy.tres`, named for the `EnemyDefinition` export they fill (`movement.tres`,
`decision.tres`, `unarmed_attack.tres`, `visual.tres`). The player has one `PlayerDefinition`
(`content/player/player.tres`: Courage, invulnerability, step time, hold-repeat delay, skill cooldown,
whether the sword starts unlocked, and the two `AttackProfile` `.tres` files
`content/skills/wooden_sword/` and `content/skills/pencil_thrust/`).
`RuleBook`/`RuleEntry` (the Book of House Rules, `content/rules/`), `RoomObjective` and
`WorldGraph` (`content/world/world.tres`: zone id -> room scene) are the other schemas. Shared
Resources are treated as immutable at runtime; instances `duplicate(true)` before mutating (a
picked-up weapon).

**Enemy locomotion is the piece's own chess law**, and it is data: `MovementConfig.
allowed_directions` is a list of offsets, one move per step. Pawns use the four cardinal
offsets (`content/enemies/_shared/movement/pawn_standard.tres`; the Charging Pawn two-cell
cardinal offsets in `content/enemies/charging_pawn/movement.tres`), the Bishop the four
diagonals (`content/enemies/bishop_zoner/movement.tres`), the Knight the eight L offsets
(`content/enemies/knight_tracker/movement.tres`), landing on a free cell. The June "all
enemies move cardinally" note in `findings.md` is superseded (`docs/game-base-plan.md` D-08).
Equipping a weapon replaces the piece's chess-shaped *attack*, not its movement.

## The event contract

19 event types exist. `game_root.gd` `_handle_events` matches 15 of them; the other four
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

- `shell/game_root.gd` — the bridge and zone-travel host (see Runtime flow). It owns fades,
  the Book toggle, the F3 debug view, F11 fullscreen and scene reload.
- `PrototypeBoard` (`presentation/board/`) — the combat overlay: telegraph cells, hit flashes,
  F3 debug paths. The one place `_draw()` is allowed for gameplay overlays.
- `GameHud` (`presentation/ui/hud/`, a `CanvasLayer`) — courage, skill cooldown, enemy count,
  status, damage flash, result panel. It owns all its own formatting.
- `CameraRig` (`presentation/camera/`) — a `Camera2D` that is a child of the player view (so it
  follows by tree parenting), clamps to the board rect and shakes via the built-in offset.
- `RuleBookUI` (`presentation/ui/codex/`) — the Book of House Rules screen (key `B`).
- `SfxManager` (autoload, `presentation/audio/`) — pooled one-shot playback for event sounds
  with no clip. Motion sounds are audio tracks in the actor's `AnimationPlayer` clips. Only the
  bridge calls it.
- Actor scenes (`presentation/views/actors/`) — `Sprite2D`s under `MotionRoot/SpriteRoot`, a
  sibling `AnimationPlayer` for clips, and an `AnimationTree` state graph (states, transitions,
  crossfades are editor-owned; `ViewSyncSystem` publishes conditions and calls `travel()` on
  event edges). They exist once, in `actor_view_base.tscn`: the union of the hero's and the
  enemies' clips and graph. Two `Start` edges wait for scene-set conditions, so the base boots
  awake and the hero's scene boots asleep into `wake`. Every graph state plays its clip through a
  `TimeScale` node, so `VisualDefinition.clip_speed_scales` is data. The cell-to-cell slide is
  procedural (`MovementSystem` progress -> `ViewSyncSystem` position) so the dodge window is
  gameplay timing, never keyframed.
- **A piece is smaller than its cell** (owner, 2026-10-12). `ViewSyncSystem` writes the body
  picture (`VisualDefinition.body_texture`, scale 1) so its bottom edge is on the kind's base line
  (`PieceSizeTable.body_top_left`), puts the facing arrow on the facing side of the cell, scales the
  held weapon to `weapon_held_scale`, and leaves the aura's size to the telegraph clip. The base
  scene places the pips along the top edge and sizes the aura so that everything an actor draws is
  within 14 px of the cell centre. Clips cap their hops and shakes at the 2 px margin. Row-based
  depth (z by row) is kept; nothing needs it any more. Measured by `test_pieces_inside_cell`,
  drawn for the owner by `tools/render_actor_preview.gd`.

## Persistence

`WorldState` (autoload, `shell/save/world_state.gd`) is pure data saved to
`user://world_state.cfg` (`ConfigFile`, `SAVE_VERSION = 2`): current zone and entry,
taken pickups, opened gates, read Book pages, player unlocks. Health is carried across a
zone travel but is never saved. The bridge writes it from events and feeds it back into
`EcsBoot` on every boot.

## Known deviations from the rules (honest list)

These exist today and are scheduled to be fixed by `docs/game-base-plan.md` §14, not by
ad-hoc edits:

- The bridge and `PrototypeBoard` read components directly (`ecs.get_component(...)`), and
  `game_root.gd` writes a few (`PlayerTag.control_enabled`, `PlayerCombat.sword_unlocked`, the
  health carry, removing `VIEW_REF`). The plan replaces this with a `world.commands` request
  queue and a read-only `HudSnapshot` (M3a).
- `PlayerInputSystem` polls the `Input` singleton, and `game_root.gd` polls raw keys (`R`, `F3`,
  `F11`, `B`). The plan moves input behind an `InputSnapshot` and `InputMap` actions.
- `ViewSyncSystem` blinks the invulnerability tint from the wall clock.
- `game_root.gd` (605 lines) still holds travel, death, persistence and HUD wiring together
  (the split is M3b).
- The 72x40 kingdom (`tests/fixtures/the_kingdom.tscn`) is still a zone in the shipped world
  graph (`content/world/world.tres`, the one documented exception in
  `test_content_references.gd`, so the H1 exit keeps resolving until M5), and `first_encounter`
  (`tests/fixtures/first_encounter.tscn`) is a standalone room only the tests load.

## Reading order

1. `ecs/core/ecs_world.gd`, `ecs/components/ecs_components.gd`, `ecs/core/ecs_system.gd` — the whole ECS in ~250 lines.
2. `ecs/core/ecs_grid.gd` — the board and the reserve -> commit protocol.
3. `ecs/systems/input/player_input_system.gd` -> `ecs/systems/move/movement_system.gd` — one full step.
4. `ecs/systems/act/combat_system.gd` -> `ecs/systems/resolve/health_system.gd` — one full attack.
5. Data schemas: `schema/entity/*`, `schema/attacks/*`, `schema/world/*`, `schema/feel/*`.
6. `ecs/systems/decide/enemy_ai_system.gd` — the big one (337 lines).
7. `authoring/ecs_boot.gd`, `ecs_actor_factory.gd`, `presentation/views/actor_view.gd`, `authoring/entity_components/*`.
8. `ecs/systems/view/view_sync_system.gd`, then `shell/game_root.gd` last.

Read `tests/run_tests.gd` and `tests/ecs_*_test.gd` alongside — the assertion labels are
the spec.

## Testing

`tests/run_tests.gd` (data and structure: grid rules, actor scenes as pure views, the
`.tres` content) plus six runtime `SceneTree` tests: `ecs_runtime`, `ecs_combat`,
`ecs_enemy`, `room_encounter_runtime`, `encounter_hud_runtime`, `zone_travel_runtime`. The
suites written since M1a extend `UnboundTest` (`tests/support/`) and live in folders by
kind:

| Folder | What it holds |
|---|---|
| `tests/architecture/` | the guards: `test_dependency_edges`, `test_content_references`, `test_content_has_no_gd`, `test_sidecars_tracked`, `test_no_path_only_ext_resource`, `test_no_old_res_paths`, `test_fixtures_present`, `test_tools_keep_uids`, `test_all_scripts_load`, `test_dump_baselines` |
| `tests/bridge/` | `game_root.gd` characterization: travel, death and respawn, persistence, health carry, the Book |
| `tests/audio/`, `tests/content/` | the bus layout; the requirements ledger and the placeholder manifest |
| `tests/support/` | `UnboundTest`, `TestPaths` (the only place a new test names a `res://` path), the harness's own test |
| `tests/fixtures/`, `tests/baselines/` | the kingdom, `first_encounter` and the harness fixtures; the six deterministic room dumps |

The canonical runner is `python3 tools/run_all_tests.py --strict`: it runs the editor import
pass first, then every suite as its own process with a 60 s timeout (a script error in a
test's `_init` otherwise hangs Godot), fails on any `SCRIPT ERROR`, `Parse Error` or `FAIL`,
and checks that every label in `tests/baseline_labels.txt` still prints PASS (or is renamed in
`tests/label_renames.txt`). `python3 tools/run_all_tests.py --self-test` tests the runner
itself; `/verify` runs it first. A new `class_name` needs one `--headless --editor --quit` import
pass before strict-typed scripts that reference it parse headlessly. A fresh clone or worktree
runs `tools/bootstrap_worktree.sh` first. To run one suite by hand:

```bash
HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot --headless --path . -s tests/run_tests.gd
```

## What is built and what is next

The tree above is the part of `docs/game-base-plan.md` §13 that M1b built: the folders, the
moves, the guards that keep code and content where they belong, and the placeholder tools.
The ECS contract is kept as it was. M2 has landed `ContentDb`, `PlayerDefinition`, the one `actor_view_base.tscn`
with its thin scenes and the in-cell size table; still to come, in plan order: the runtime seams — commands, the input snapshot, the `HudSnapshot`, the
schedule files, `events.gd` (M3a) — the split of `game_root.gd` and the save service (M3b),
then the shell, input, text, story, skills, bosses and the other five districts. The
owner-facing "how do I change X" table, with real paths for what exists today, is
`docs/OWNER_GUIDE.md`.
