# Architecture

The Unbound Pawn — a 2D top-down grid-combat RPG in Godot 4.6.3. This document
describes the code **as it is built today** (checked against the tree on 2026-10-19, after
milestone M3a, the runtime seams: the schedule, the declared events, the commands channel, the
world's shared fields, the input and HUD snapshots, the player carry, the per-room origin, and the
grid's cell kinds, leaps, rays and cached paths). The simulation is a full ECS; the
node-composition architecture that older docs described (`GridWorld`, `FreeEnemy`,
`PawnHero`, `EnemyActor`, `EncounterDirector`, per-actor component nodes) was deleted in
the ECS conversion (`docs/ecs-conversion-plan.md`, owner decision 2026-07-19). The folders
were rearranged in M1b to the tree of `docs/game-base-plan.md` section 13; the move is
recorded file by file in `docs/migration-notes.md` and `tools/move_res_log.tsv`. M2 then added the
content registry (`ContentDb`), the hero as data (`PlayerDefinition`), the one actor view and the table
that keeps every piece smaller than its cell; the section "The content registry, the hero and the actor
view" below is where they fit together.

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
| System | a class extending `EcsSystem` in `ecs/systems/<folder>/`, with `const PHASE` naming its stage | reads and writes components, never calls another system, never touches a node (except `ViewSyncSystem`) |
| Schedule | `ecs/schedule/`: one file per stage plus `schedule.gd` (`Schedule.populate(world)`) | the order the systems tick in; data, and the only list of it |
| World | `EcsWorld` (a `Node`) in `ecs/core/` | owns the stores, the systems list, the grid, the queues and records listed in "The world's shared fields" below, and the attack token |
| Events | `EcsWorld.emit_event({"type": Events.NAME, ...})`, read once per frame with `drain_events()`; declared in `ecs/events/events.gd` | the only channel from simulation to presentation |
| Commands | `EcsWorld.push_command(Commands.x(...))`, declared in `ecs/events/commands.gd`, applied by `CommandSystem` at the head of the next tick | the only channel from presentation and settings into the simulation |
| Damage and heal queues | `EcsWorld.damage_events`: `[{target, source, amount, direction, tags}]`, `EcsWorld.heal_events`: `[{target, source, amount}]` | built only by `Events.emit_damage()` and `Events.emit_heal()` (from `CombatSystem` and `EnemyAISystem`, later checkpoints), drained only by `HealthSystem` |
| Spatial index | `EcsWorld.grid` (`EcsGrid`) in `ecs/core/` | cell occupancy, blocks, move reservations, A*, doors, gates, floor items |

`EcsWorld.tick(delta)` calls every system in registration order, and `Schedule.populate(world)` registers
them in the order of `ecs/schedule/`. A frozen world (`frozen`) ticks only the systems whose
`runs_while_frozen()` is true: `CommandSystem`, so a freeze can be lifted, and `ViewSyncSystem`, so the
picture keeps being drawn; the check is made before each system, so a freeze applied at the head of a
tick stops the rest of that tick. `game_root.gd` sets `manual_tick = true` and ticks the world from its
own `_process`, so a room that has ended (`room_ending`) simply stops ticking. Tests also drive
`tick(delta)` by hand.

## Folder structure (what exists today)

The top-level folders are layers. Each has one job, and the table after the tree says which
layer may name which.

```text
project.godot            main scene shell/game_root.tscn; autoloads SfxManager, SaveService
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
  core/                  EcsWorld, EcsGrid, CellKinds, EcsSystem, WorldFlags, InputSnapshot, HudSnapshot, PlayerSnapshot
  components/            ecs_components.gd (frozen); tuning.gd (Tuning), and every new component in its own file
  systems/<folder>/      command/CommandSystem  input/PlayerInputSystem  decide/EnemyAISystem
                         move/MovementSystem  act/CombatSystem  resolve/HealthSystem  view/ViewSyncSystem
  events/                events.gd (every event, its payload, emit_damage/emit_heal), commands.gd (every request)
  schedule/              one file per stage of the tick + schedule.gd (the order is data here)

authoring/               THINGS YOU DRAG INTO A SCENE: Inspector data + apply(); no logic
  ecs_boot.gd            the baker: reads a room scene, builds the world (EcsBoot.boot(world, EcsBootOptions))
  ecs_boot_options.gd    everything boot() needs besides the world, as named fields (EcsBootOptions)
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
  game_root.gd/.tscn     the one game scene and its bridge (637 lines; split in M3b)
  content/               ContentDb (the content registry, a static class) and ContentKind
  input/input_poller.gd  InputPoller: the one reader of the Input singleton; fills world.input_snapshot once per frame
  save/                  SaveService (the autoload: the run in memory, the slots on disk, the profile) and its
                         helpers SaveData, SaveFile, SaveMigration, SaveLoadResult (see Persistence)

assets/                  shared raw art and audio not owned by one content item
  tiles/<kit>/atlas.svg  tile atlases   ui/actor_view/  the overlay pictures every actor view shares
  map_pieces/            the owner's hand-drawn bedroom pieces   sfx/ music/   audio
  concept-art/           references, never shipped   _generated/   generator output (gitignored)

tools/                   generators, the runner, the migration scripts (never shipped; tools/README.md)
tests/                   run_tests.gd + six runtime tests + architecture/ audio/ bridge/ content/ ecs/ presentation/ support/
                         fixtures/ (the 72x40 kingdom, first_encounter, the harness fixtures) baselines/
docs/                    this file, coding-standards.md, OWNER_GUIDE.md, plans, design/, archive/
```

Not built yet (the plan's later milestones): `schema/skills`,
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

Three edges and six room references are not decided by the owner yet and are printed on
every run (report-only, an entry nothing uses fails the suite): `EcsBoot` and `EntityComponent`
name `ActorView`; `PickupSpawnPoint` names `WeaponPickup`; the six Stage 1 rooms carry a
`GridLinesOverlay` from `presentation/board/`. The allowed-edge table is not frozen until the owner
decides them (`docs/migration-notes.md`). A fourth, `PrototypeBoard` reading `EcsComponents` and
`EcsWorld`, was settled by M3a step 2 rather than decided: the overlay draws from the `HudSnapshot`,
the one `ecs/core` class the presentation row of the table names (`CLASS_ALLOWANCES` in the edge test),
and the edges are gone.

## Runtime flow

```text
shell/game_root.tscn  ->  Main (shell/game_root.gd)
  _ready()      SaveService.ensure_session() (Continue, when no run has begun), reads the run's
                checkpoint (which zone, which entry), swaps the zone node if the run was saved
                elsewhere, then calls _boot_zone(entry_id)
  _boot_zone()  1. _make_world(): new EcsWorld + Schedule.populate (the systems, order below)
                   and EcsBoot.shape_grid(): the room's bounds and its centred grid origin
                2. EcsBoot.boot(world, EcsBootOptions) -> the "cast"
                3. reapply the run (world flags, taken pickups, opened gates, unlocks, health carry)
                4. HudSnapshotSystem.build(world), board.setup(grid, hud_snapshot),
                   camera_rig.setup(grid), HUD setup
  _process()    input_poller.poll(delta, world.input_snapshot)  ->  ecs.tick(delta)
                ->  _handle_events(ecs.drain_events())  ->  HUD refresh from world.hud_snapshot
```

Death and `R` reload the scene; the `SaveService` (an autoload) holds the run in memory and
remembers the zone and entry, so the reload boots in the right place. Zone travel (`zone_exit`
event) fades out, swaps the zone scene node, **rebuilds the whole `EcsWorld`**, and fades in. No
entity survives. What carries over is the player view node, the run in the `SaveService` (its
flags are loaded into every new world), the carried health (`game_root.player_health_carry`),
and the HUD, board and camera nodes, which are re-bound by `setup()`.

### System order (the schedule, `ecs/schedule/`)

The order is data: one file per stage in `ecs/schedule/` (`command`, `input`, `decide`, `cell_effects`,
`move`, `act`, `resolve`, `react`, `progress`, `view`) and `Schedule.populate(world)`, which both
`shell/game_root.gd` and `tools/world_dumper.gd` call. A system file carries `const PHASE` naming the
stage that lists it. A stage is named for when it runs and a folder for what its systems are about, so
they differ where the plan's order (`docs/game-base-plan.md` 13.4) visits one folder several times; the
empty stages (`cell_effects`, `react`, `progress`) wait for the milestones that fill them.
`tests/ecs/test_schedule_order.gd` holds the whole planned order, including systems that do not exist
yet, and `tests/architecture/test_schedule_complete.gd` fails on a system file that is not listed
exactly once.

| # | System (stage, folder) | Reads | Writes / emits |
|---|---|---|---|
| 1 | `CommandSystem` (`command`, `command/`) | `world.commands`, `world.command_handler_by_type` | `world.frozen`, `world.flags`, `world.tuning`; whatever a registered handler changes; emits `flag_set`, `command_rejected`. Runs while the world is frozen |
| 2 | `PlayerInputSystem` (`input`, `input/`) | `world.input_snapshot` (never the `Input` singleton), `PLAYER_TAG`, `PLAYER_INPUT`, `MOVE_STATE` | `MOVE_INTENT` (buffered and held-key steps), `FACING` (turn in place), `ATTACK_INTENT` |
| 3 | `EnemyAISystem` (`decide`, `decide/`) | `ENEMY_AI`, `GRID_POS`, `FACING`, `MOVE_STATE`, the grid, the hero | `MOVE_INTENT`, `FACING`, `ENEMY_AI` state, `WEAPON_SLOT` (pickup), `damage_events`; owns the attack token; emits `intent_changed`, `telegraph_started/finished`, `attack_resolved`, `pickup_taken`, `weapon_changed` |
| 4 | `MovementSystem` (`move`, `move/`) | `MOVE_INTENT`, `MOVE_STATE`, `GRID_POS` | reserve -> commit through the grid; `GRID_POS`, `MOVE_STATE`; emits `step_started/finished/blocked`, `gate_opened`, `zone_exit`, `zone_exit_locked`, `player_unlock` |
| 5 | `CombatSystem` (`act`, `act/`) | `ATTACK_INTENT`, `PLAYER_COMBAT`, `GRID_POS`, `FACING` | attack lifecycle as timers; `damage_events`; emits `attack_started`, `attack_landed`, `attack_locked`, `skill_cooldown` |
| 6 | `HealthSystem` (`resolve`, `resolve/`) | `damage_events`, `heal_events` | `HEALTH`; defeat (disables player control, or unregisters an enemy and frees the token); emits `damaged`, `defeated`, `healed` |
| 7 | `ViewSyncSystem` (`view`, `view/`) | almost everything, read-only; `view_commands`. Runs while the world is frozen | the **only** node writes: position, depth (`z_index = 2 + row`), tint, aura, facing arrow, weapon, health pips, `AnimationTree` conditions and `travel()` |

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
`docs/coding-standards.md`); the first such file is `tuning.gd` (`Tuning`, the assist knobs, held by the
world as `EcsWorld.tuning`).

## The world's shared fields (`EcsWorld`)

Every field a later milestone needs landed in one commit of M3a (plan 14.5), so later work adds
behaviour and never a field to the hot file. Each is documented where it is declared.

| Field | Holds | Changed by |
|---|---|---|
| `frozen` | the simulation is held still (cutscene, pause) | the `freeze_requested` / `unfreeze_requested` commands |
| `flags` | `WorldFlags`: switches (bool) and counters (int) the story and progression ask about; `to_dictionary()` for the save | the `set_flag` command, or a system that owns a counter |
| `tuning` | `Tuning`: `telegraph_time_scale`, `enemy_pace_scale`, `input_buffer_window`, `extra_courage`; neutral by default, nothing reads them yet | the `tuning_set` command |
| `input_snapshot` | `InputSnapshot`: per action pressed, just pressed, just released, held time, press timestamp (`InputPoller` in the shell fills it once per frame; `PlayerInputSystem` reads only it) | the shell |
| `hud_snapshot` | `HudSnapshot`: the hero's courage, cell, facing, sword and skill cooldown, the attack token owner, and one `EnemyBrief` per enemy (cell, committed goal, telegraph progress); rebuilt in place at the end of every tick, plus a revision counter | `HudSnapshotSystem` (the shell also calls its `build()` once after booting a room) |
| `commands`, `command_handler_by_type` | the requests from presentation, and the Callable that applies each type | `push_command()`; `register_command_handler()` |
| `view_commands` | cosmetic instructions for the views (`Commands.play_state`) | `push_view_command()`; consumed by `ViewSyncSystem` |
| `heal_events` | heal requests `{target, source, amount}` | `Events.emit_heal()`; consumed by `HealthSystem` |

The grid's own fields landed in the same milestone and are described under "The grid": `cell_kind_by_cell`,
`layout_version`, `cell_effect_by_cell` and `leap_by_entity`.

`flags` is a fresh object for every world, and the shell rebuilds the world for every room, so what must
outlive a room (flags, the player's carry) is carried by the shell and the save in M3b.

### What the pawn carries (`PlayerSnapshot`)

`ecs/core/player_snapshot.gd` is the carry contract of plan 14.2, defined once: courage (current and max), Believe,
unlocked skill ids and applied upgrades, equipped pages and Margin, the direction lock, the facing and the
run's flags (`WorldFlags`). It has a dictionary form that survives JSON (`to_dictionary()`, `from_dictionary()`,
which tolerates a damaged or older save and refuses a newer one), `capture(world, hero)` for the old world
at the exit, and `apply_to(world, hero)` for the new one. The per-room rows of the plan's table (cooldowns,
status, the cast, the attack lock and token, telegraphs, hit progress, the floor weapon, cell effects) are
deliberately not fields, so they reset with the world. The facing is captured but only restored when
asked (`restore_player_facing`): a room change leaves it to the entry marker. Believe, skills, pages, Margin
and the lock have fields but no component yet; the milestone that adds one adds a line to `capture()` and
`apply_to()`. `EcsBootOptions.player_snapshot` makes `EcsBoot.boot()` apply it right after the hero is
built. Nothing in the shell passes one yet: M3b's zone swap does. `test_player_snapshot_roundtrip` holds it.

## The grid (`EcsGrid`)

`EcsWorld.grid` is the spatial service, defaults `cell_size = 32`, `grid_origin = (64, 36)`,
`bounds = (0, 0, 16, 9)`. A room shapes it at boot (`EcsBoot.shape_grid`): its `board_size` sets the
bounds and `EcsGrid.centred_origin()` sets the origin that centres that board in the 640x360 picture
(read from project.godot, not repeated in code): a 16x9 room starts at (64, 36), an 18x9 arena at
(32, 36), an 18x10 board at (32, 20). A board larger than the picture (the 72x40 kingdom fixture)
keeps the fixed anchor `EcsGrid.FALLBACK_ORIGIN` on that axis, because the camera scrolls there. The
art, `GridLinesOverlay` and markers of a room that is not 16x9 are authored for that origin.
Its dictionaries are all documented in the file:

- `entity_by_cell`, `cell_by_entity`, `move_reservations`, `item_by_cell`, and the terrain below.
- Baked door and gate data: `exit_by_cell` (zone exits), `gate_by_cell` (one-way shortcut
  gates), `player_unlock_by_cell` (player verb unlocks).
- Every other kind of room marker has no field of its own: `marker_by_cell[kind][cell]` holds its data
  (`add_marker`, `marker_at`, `marker_cells`, `remove_marker`), so a new marker adds a baker and not a field
  to the grid (`tests/ecs/test_grid_markers.gd`). Nothing bakes into it yet; the traversal gap (M5) and the
  triggers (M6) are the first.
- The movement protocol is **reserve -> commit**: `begin_move` claims the destination before
  the slide, `finish_move` lands it. While sliding, the origin stays occupied and the
  destination reserved, so nobody can race into either.
- Gameplay is cell-based; there is no physics collision.
- Multi-cell footprints (the 2x2 and 3x3 bosses) are M8b's, not M3a's. `entity_by_cell` can already name one entity
  from several cells, but the rest of the grid still assumes an entity is ONE cell wide, and M8b has to change
  each of these:
  - `cell_by_entity` maps an entity to a single cell (a footprint needs an anchor cell plus its offsets, or a list);
  - `register_entity`, `begin_move` and `begin_leap` claim one cell (and `can_begin_move`, `can_begin_leap` test one);
  - `unregister_entity` erases the one cell `cell_by_entity` names from `entity_by_cell`, so it would leave the
    rest of a footprint standing on the board;
  - `finish_move` vacates one origin cell and occupies one destination cell, and `get_reserved_cell` answers with
    the first reserved cell it finds;
  - `leap_by_entity` holds one `from` and one `to` cell, and `leap_landing_cell` answers with one cell.
  `get_grid_path` also marks other pieces solid one cell each. Everything that only asks "who stands on this
  cell?" (`entity_at`, `ray_cells`, the telegraph cells) already works for a piece that fills several.

### What a cell is made of (cell kinds)

`cell_kind_by_cell` maps a cell to a kind for every cell that is not plain floor (a cell it does not list is
floor). The vocabulary is `CellKinds` (`ecs/core/cell_kinds.gd`), one row per kind with three rules:

| Kind | Walkable | Stops a ray | A leap may cross |
|---|---|---|---|
| `floor` | yes | no | yes |
| `wall` (also a closed gate) | no | yes | no |
| `gap` | no | no | yes |
| `leapable_block` | no | yes (cover) | yes |
| `chalk` | yes | no | yes |
| `corruption` | yes | no | yes |

`blocked_cells` is **derived**: every cell whose kind cannot be walked on. `set_cell_kind(cell, kind)` is the
only writer of the terrain (`add_block` and `open_gate` call it; `tests/ecs/test_grid_cell_kinds.gd` fails if any
other script writes `blocked_cells` or `cell_kind_by_cell`); it refuses a cell off the board, a kind that does
not exist, and a non-walkable kind under a piece or a reservation. `layout_version` counts every real change of
the terrain and of `bounds`; anything that caches a fact about the terrain keeps the version it was built for.
`cell_effect_by_cell` is the (empty) store of the `CellEffectSystem` of M10, landed here so that milestone does
not edit this file's fields.

The kinds are **authored** in the TileSet: the `kind` custom-data layer (text) sits next to `solid`
(`content/tilesets/kingdom/tileset.tres` and the fixture's). A tile that fills `kind` in with a known kind
gives its cell that kind; a tile that leaves it empty is a wall when `solid` is true and floor otherwise, which
is why every existing tile means what it always meant. `EcsBoot.apply_tile_kinds` reads the room's
`RoomArt/TileMap` once at boot. No shipped tile fills `kind` in yet: the art for a gap, a block, chalk and
corruption belongs to the milestones that use them (a tile is tagged in the TileSet editor, Custom Data ->
kind). `tools/cell_kind_painter.gd` is the part of a paint tool that knows kinds (a tool states what a cell IS
beside the art it picked and the helper refuses a tile that does not read as that kind);
both paint tools (`tools/paint_kingdom_tilemap.gd`, `tools/paint_zone_tilemaps.gd`) paint through it, so a new
kind is painted by stating it, never by hand-editing `tile_map_data`. The world dump names the kinds in a room's
grid and board once a room has one besides floor and wall.

### Leaps and rays

- `begin_leap(entity, from, to)` / `finish_leap(entity)`: a step holds both its cells until it lands; a leap does
  not. At takeoff the origin is released and the landing cell is reserved; in the air the entity stands on no
  cell (`leap_by_entity` records from and to), so nothing aimed at a cell finds it, and `HealthSystem` ignores
  damage to an airborne entity. `can_begin_leap` is the refusal rule; `can_leap_over(cell)` says whether a leap
  may pass over a cell (the kind's third rule, and never a door). No skill uses them yet: Rule Step (M7a) and the
  Knight (M8a) are the first. `test_leap_occupancy`.
- `ray_cells(origin, direction, max_cells, stop_kinds, stop_before_occupied)`: the cells a straight line covers
  (any non-zero step, so diagonals too), nearest first, ending before the board's edge or the first stopping kind
  (walls and blocks by default, never gaps). Pieces are not terrain, so a line covers the cell of whoever stands in
  it unless `stop_before_occupied` ends it before them, for a charge. Rook charges, Bishop lanes and Queen lines
  are made of it. `test_ray_stops_at_blockers`.

### Pathing and its cost

`get_grid_path` (and `get_path_distance`, `get_next_path_cell`) keeps one `AStarGrid2D` per `layout_version`
and marks the pieces and reservations in the way solid for the length of one question only (no diagonals; a
goal that is held is still a goal). It used to build a pathfinder per question. `test_path_cache` counts builds
and holds the answers equal, cell for cell, to the old code kept in `tests/support/reference_pathing.gd`.
The enemy's search for the cell to attack from (`EnemyAISystem._find_attack_setup_goal`) looks only at the cells
within the attack shape's reach of the hero, measured from the shape itself; `test_attack_setup_search` holds
that it picks the same cell as the old whole-board scan, and replays whole rooms side by side with the old code.
`tests/perf/test_room_tick_budget.gd` ticks an 18x9 room with eight enemies and real views for 1800 ticks (a hero
that keeps changing place, so the enemies never sleep) and asserts a mean and a median tick of 2 ms or less, a 99th
percentile of 8 ms or less, and one pathfinder built for the whole run. Measured on the development machine
(Apple M5, Godot 4.6.3 headless): mean 0.15 ms and 99th percentile 0.45 ms on a quiet machine, up to 0.5 ms and
2 ms on a busy one; before the two changes the mean was 0.8 to 1.2 ms and the 99th percentile 7 to 10 ms. The
bounds are generous on purpose, so a noisy machine does not fail the suite, while a change that makes the tick
several times slower still does.

## Authoring: scenes as spawn data

| Piece | File | What it does |
|---|---|---|
| `ActorView` | `presentation/views/actor_view.gd` | the puppet and spawn marker. Spawn data: `definition: EnemyDefinition` (null on the player) or `player_definition: PlayerDefinition` (null on an enemy, `content/player/player.tres`); plus appearance exports (tints, facing mark, the `PieceSizeTable`), the in-cell knobs (`facing_mark_distance`, `weapon_anchor`, `weapon_rest_length`, `weapon_held_scale`) and the pictures (default weapon, pips). No logic. |
| Actor scenes | `presentation/views/actors/` | **One actor view**: `actor_view_base.tscn` holds the nodes, every clip and the one animation graph; `player.tscn`, `black_pawn.tscn`, `knight_enemy.tscn` and `bishop_enemy.tscn` inherit it and say only what is theirs (13 to 20 lines each; `test_one_actor_view` holds that). A new enemy needs no scene: instance the base and set `definition`. |
| `PieceSizeTable` | `schema/feel/piece_size_table.gd` (+ `piece_size.gd`), `content/feel/piece_sizes.tres` | the owner's rule that a piece is smaller than its cell, as data: per kind a body box, a base line (px below the cell centre) and a footprint in cells; `validate()` holds the margin and the chess heights; `body_top_left()` is the one placement formula. |
| `EntityComponent` nodes | `authoring/entity_components/` | Inspector-draggable children of an `ActorView`; `EcsBoot` calls `apply(world, entity_id)` at spawn. Six exist: `CombatComponent`, `HealthComponent`, `InputComponent`, `MovementComponent` (overrides of the player's `PlayerDefinition`; the player scene carries none, so `content/player/player.tres` is the only source) and `AIComponent`/`WeaponComponent` (per-instance enemy overrides). A node on an instance beats the definition, field by field. Zero logic. |
| `EcsBoot` | `authoring/ecs_boot.gd` | static `boot(world, options)`, where `options` is an `EcsBootOptions` (`authoring/ecs_boot_options.gd`: `player_view`, `room_root`, `fallback_player_cell`, `skipped_pickup_names`, `opened_gate_ids`, `player_snapshot`, `restore_player_facing`; a new need is a new field, never a new argument; `EcsBootOptions.for_scene(hero, room)` is the common case): sizes the grid from `RoomEncounter.board_size`, bakes the tile kinds (`apply_tile_kinds`), `ZoneExitMarker`, `PlayerUnlockMarker` and `GateMarker`; spawns the player from the view's `PlayerDefinition` (class defaults when it names none) and applies its `EntityComponent` nodes, then every `ActorView` child of the room that has a `definition`, then pickups. Returns the cast dictionary (`player`, `enemies`, `view_by_entity`, `piece_name_by_entity`, pickup maps). |
| `EcsActorFactory` | `authoring/ecs_actor_factory.gd` | `spawn_player` (bare hero, kept), `spawn_player_from_definition` (what `EcsBoot` calls), `spawn_enemy`, `spawn_pickup`: assemble an entity's components from the `.tres` data and apply the difficulty multipliers. |
| `ContentDb` | `shell/content/content_db.gd` (+ `content_kind.gd`) | the content registry, a static class (no autoload, so it works inside a suite's `_init()`). Ids are folder names under `content/<kind>/`, listed lazily once per kind. `ids(kind)`, `fetch(kind, id)`, `all(kind)`, `player()`, `world()`, `piece_sizes()`, `validate()`, `validate_cross_refs()`. Ten kinds registered (one line each in `_ensure_kinds()`). Only the shell may name it; tests and tools call the two validators, nothing calls them at game start. |
| `RoomEncounter` | `authoring/room_encounter.gd` | a room scene root: `board_size`, `zone_id`, prose, and a `RoomObjective`. It carries data only. |
| Markers | `authoring/markers/` | `GridMarker` base (drag to snap, writes `grid_cell`). `ZoneEntryMarker`/`ZoneExitMarker` (doors), `GateMarker`, `PlayerUnlockMarker`, `PickupSpawnPoint`. `BlockerMarker` is a legacy marker `EcsBoot` no longer bakes; walls are painted tiles. |
| Terrain | `RoomArt/TileMap` | a tile's custom data says what its cell is: `kind` (floor, wall, gap, leapable_block, chalk, corruption) when filled in, else `solid = true` is a wall and anything else floor. A cell that cannot be walked on is a blocked cell. Paint = collision. |

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

## The content registry, the hero and the actor view

What M2 added, in the order a piece travels from a folder to the board.

**`ContentDb`** (`shell/content/content_db.gd`, `content_kind.gd`) is the only code that loads `content/` by id. A
static class, not an autoload, because no autoload exists while a suite's `_init()` runs
(`test_content_db_in_init` asserts it works there). An id is a folder name (or a file name), listed once per kind on
the first ask; a name starting with `_` (`_shared`) or `.` is not an id. Ten kinds are registered, one line each in
`ContentDb._ensure_kinds()`:

| Kind | Folder under `content/` | The id is | Main file | Class |
|---|---|---|---|---|
| `player` | `player/` | the kind itself | `player.tres` | `PlayerDefinition` |
| `world` | `world/` | the kind itself | `world.tres` | `WorldGraph` |
| `piece_sizes` | `feel/` | the kind itself | `piece_sizes.tres` | `PieceSizeTable` |
| `enemies` | `enemies/` | the folder name | `<id>/enemy.tres` | `EnemyDefinition` |
| `rooms` | `rooms/` | the folder name | `<id>/room.tscn` | `PackedScene` |
| `rules` | `rules/` | the folder name | `<id>/page.tres` | `RuleEntry` |
| `skills` | `skills/` | the folder name | `<id>/<id>.tres` | `AttackProfile` |
| `pickups` | `pickups/` | the folder name | `<id>/<id>.tres` | `EnemyWeapon` |
| `difficulty` | `difficulty/` | the file name | `<id>.tres` | `DifficultyProfile` |
| `tilesets` | `tilesets/` | the folder name | `<id>/tileset.tres` | `TileSet` |

`ids(kind)`, `has_id`, `path_of`, `fetch(kind, id)` (null when unknown, never an error), `all(kind)`, and the
shortcuts `player()`, `world()` and `piece_sizes()`. Everything comes from `ResourceLoader`'s shared cache, so
`duplicate()` before changing a resource. Two validators return readable sentences and are empty when all is well;
tests and tools call them and nothing calls them at game start. `validate()` checks each entry: the main file exists,
loads and is the right class, the class's own `validate()` is empty, the folder is lowercase snake_case, an `id`
property equals the folder and no two entries claim one id, and every property a `.tres` assigns a resource to holds one (Godot leaves a property empty, with no message, when the named resource is of another class). `validate_cross_refs()` checks the references between
entries: a Book page's `piece_id` is an enemy, an enemy's difficulty, default weapon and weapon preferences are
registered, the player's two attacks are skills, **every actor's `piece_type` is a row of the size table and its body
picture fits that row (a tight picture inside the box, or the 32 x 32 canvas of the art spec with its drawn pixels inside the box)**, the world graph and the room folders agree, every door leads to a zone and an
entry marker that exist, every room's `zone_id` equals its folder and every enemy parked in a room is a registered
enemy. `tests/content/test_validate_all.gd` runs both over the real tree; `test_content_db_detects_problems` runs them
over a deliberately broken tree under `user://` and requires each defect to be named. A new kind is one
`_add_kind` line, a `validate()` on its class and a minimum count in `test_validate_all`.

**`PlayerDefinition`** (`schema/entity/player_definition.gd`, `content/player/player.tres`) is the hero as data:
`max_courage`, `invulnerability_duration`, `step_duration`, `held_repeat_delay`, `skill_cooldown_duration`,
`starts_with_sword`, the two `AttackProfile` files (`wooden_sword`, `pencil_thrust`), `piece_name`, and its
`VisualDefinition` (`content/player/visual.tres`: piece type `pawn`, `body.png`, clip speeds). `ActorView.player_definition`
names it; `EcsBoot` calls `EcsActorFactory.spawn_player_from_definition` to bake it into the player entity, exactly as an
`EnemyDefinition` is baked into an enemy. `player.tscn` carries no tuning number and no `EntityComponent` node. A node
of that kind on a room's instance of the player still wins over the file, field by field, so one room can override a value
without touching the shared file. A class default equals the pre-M2 hero, so a view with no definition plays as before;
`test_player_definition` proves each field reaches the entity.

**The actor view.** There is one: `presentation/views/actors/actor_view_base.tscn`. Its nodes are
`ActorView` (the script, the spawn data) with `TelegraphAura`, `MotionRoot/SpriteRoot` (`BodySprite`, `FacingArrow`,
`WeaponPivot/WeaponSprite`, `HealthPips/Pip0..2`), `AnimationPlayer` (the clips), `AnimationTree` (the graph) and
`AudioPlayer`. The four scenes beside it inherit it and set only what is theirs. A piece's look is data read by
`ViewSyncSystem`, the only writer:

| What | Comes from | Written to |
|---|---|---|
| the body picture and where it stands | `VisualDefinition.body_texture`, `piece_type`, `anchor_offset` and the size table's `PieceSizeTable.body_top_left()` | `BodySprite.texture` and `.position`, at scale 1 |
| how fast each clip plays | `VisualDefinition.clip_speed_scales` (clip name to a multiple, default 1.0) | the `TimeScale` node of each graph state, parameter `parameters/<state>/TimeScale/scale` |
| the telegraph tint | `ActorView.telegraph_modulate` (a thin scene may set its own; `VisualDefinition` has no tint field: a field is added when a system reads it) | the aura |
| the facing arrow, the held weapon's size and place, the pips | `ActorView.facing_mark_distance` (10 px out on the facing side), `weapon_held_scale` (0.16), `weapon_anchor`, `weapon_rest_length`; pips are placed by the base scene along the top margin line (a queen and a king stand up into that row, so theirs are drawn over the crown; the in-cell test names those two kinds) | the arrow, the weapon, the pips |

**The size table and who reads it.** `content/feel/piece_sizes.tres` (`PieceSizeTable`, one `PieceSize` row per kind: `body_box`,
`base_offset_y`, `footprint_cells`) is the owner's rule that a piece is smaller than its cell, written as data
(`docs/owner-decisions.md`, 2026-10-12). `PieceSizeTable.validate()` holds the 2 px margin and the chess height order.
Six readers keep to it: `ViewSyncSystem` (places the body, and limits a hit's drawn shove to the margin), `ContentDb.validate_cross_refs()` (a picture
that does not fit its row, by `PieceSizeTable.picture_problems()`, is a problem), `tools/generate_chess_sprites.gd` (refuses to draw a piece that does not fit), `test_piece_size_table`
(the table's own rules), `tests/architecture/test_pieces_inside_cell.gd` (boots the hero, the three thin scenes and every
enemy of `content/enemies/`, and every actor a room scene places as the room places it, through the real `EcsBoot` and `ViewSyncSystem`, in every facing, armed, telegraphing, shoved by a hit and at
about 600 clip poses, and measures the opaque pixels each actor draws against its cell, in the cell's own frame so a scale shows: 2 px from every edge) and
`tools/render_actor_preview.gd` (draws the hero, a black pawn, the knight and the bishop, and every actor the rooms place, in their cells at 4x with a gutter into
`assets/_generated/previews/pieces_in_cells.png` and `pieces_placed_in_rooms.png`, composed on the CPU with `Image`, no renderer needed; pixels in the margin band are magenta and counted). A new
kind of piece is a row; a boss is a row with a bigger footprint. `tools/actor_stage.gd` and `tools/actor_cell_probe.gd`
are the shared helpers of the last two.

## The event contract

`ecs/events/events.gd` declares every event once: a const for its name, and a row with its status
(`emitted` or `future`), what happened and every payload key with its type and meaning. That file is the
contract and this section only summarises it. `EcsWorld.emit_event()` asserts in debug builds that an event
is declared, is `emitted` and carries exactly the documented keys, and
`tests/architecture/test_events_declared.gd` reads the code for every emitted name (an emitted event must be
declared, a declared `emitted` one must be emitted, and a `future` one must not be). The 27 events the plan adds
later are reserved by name as `future` and gain their payload when their milestone starts emitting them.

22 types are emitted today (the 19 the plan counted when M3a began, plus `healed`, `flag_set` and
`command_rejected`). `game_root.gd` `_handle_events` matches 15 of them; the others (`step_started`,
`step_finished`, `step_blocked`, `attack_started`, and the three new ones) are emitted for tests and future
presentation.

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
| `damaged` | `entity`, `amount`, `remaining`, `direction`, `source`, `tags` | bridge: shake, HUD courage, damage flash |
| `defeated` | `entity`, `source`, `tags` | bridge: despawn timer, room completion, player death/reload |
| `healed` | `entity`, `amount`, `remaining`, `source` | — |
| `pickup_taken` | `item`, `cell` | bridge: the save (`pickup_taken`), pickup sound, free the pickup view |
| `weapon_changed` | `entity`, `weapon` | bridge: status text |
| `player_unlock` | `entity`, `id`, `message` | bridge: the save (`unlock_gained`), unlock the sword |
| `gate_opened` | `entity`, `gate`, `cell` | bridge: the save (`shortcut_opened`), hide the gate visual |
| `zone_exit` | `entity`, `zone`, `entry` | bridge: zone travel |
| `zone_exit_locked` | `entity`, `zone`, `entry`, `cell` | bridge: locked-door message |
| `flag_set` | `flag`, `value` | — |
| `command_rejected` | `command`, `reason` | — |

Damage carries who dealt it: `Events.emit_damage(world, target, amount, direction, source, tags)` is the only
way to queue a request, `source` is the attacking entity (0 for none) and `tags` the attack's own tags (an armed
enemy's weapon tags; empty for the player's attacks and unarmed patterns until the attack framework of M8a).
`HealthSystem` passes both on, which is what the death frame (R8) and the player-kill check (R14) read.

The way back into the simulation is the same kind of contract: `ecs/events/commands.gd` declares each request
(`freeze_requested`, `unfreeze_requested`, `set_flag`, `tuning_set` handled today; `actor_command` and
`equip_page` reserved) and the cosmetic `play_state` view command; `CommandSystem` drains `world.commands` first
in every tick and drops a request that is malformed, unhandled or refused with a `command_rejected` event.

## Presentation and the bridge

Presentation consumes `drain_events()` and never decides gameplay.

- `shell/game_root.gd` — the bridge and zone-travel host (see Runtime flow). It owns fades,
  the Book toggle, the F3 debug view, F11 fullscreen and scene reload.
- `PrototypeBoard` (`presentation/board/`) — the combat overlay: telegraph cells, hit flashes,
  F3 debug paths. The one place `_draw()` is allowed for gameplay overlays. It reads the board
  geometry from the grid (duck-typed) and everything else from `world.hud_snapshot`.
- `GameHud` (`presentation/ui/hud/`, a `CanvasLayer`) — courage, skill cooldown, enemy count,
  status, damage flash, result panel. It owns all its own formatting.
- `CameraRig` (`presentation/camera/`) — a `Camera2D` that is a child of the player view (so it
  follows by tree parenting), clamps to the room and shakes via the built-in offset. A room that fits the
  picture is held still with the board centred and every cell on screen (the limits are one view wide
  around the board's centre, `CameraRig.limits_for_board`); a larger one scrolls with the hero and stops
  at its edges. The shell calls `setup(grid)` after every boot, so the clamp follows the new room
  (`test_camera_frames`).
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
  picture (`VisualDefinition.body_texture`, scale 1) so its base is on the kind's base line (a tight
  picture's bottom edge; the 32 x 32 canvas of the art spec lands exactly on the cell)
  (`PieceSizeTable.body_top_left`), puts the facing arrow on the facing side of the cell, scales the
  held weapon to `weapon_held_scale`, and leaves the aura's size to the telegraph clip. The base
  scene places the pips along the top edge and sizes the aura so that everything an actor draws is
  within 14 px of the cell centre. Clips cap their hops and shakes at the 2 px margin. Row-based
  depth (z by row) is kept; nothing needs it any more. Measured by `test_pieces_inside_cell`,
  drawn for the owner by `tools/render_actor_preview.gd`.

## Persistence

`SaveService` (autoload, `shell/save/save_service.gd`; it replaced `WorldState` in M3b step 1) is the one
owner of everything written about a playthrough (`docs/game-base-plan.md` 9.3, D-16).

- **The run in memory**: `SaveService.state`, a `SaveData`. The bridge writes the facts it learns from events
  into it (a taken pickup, an opened gate, an unlock, a read Book page, the checkpoint) and reads it back at
  every room boot. It survives a scene reload because the node is an autoload. The ECS world's flags are
  loaded into every booted world and copied back into the run through the service's `saving` signal.
- **The file**: one slot behind a slot id (`SINGLE_SLOT`), a `ConfigFile` at `<root>/saves/slot_<n>.cfg`
  (root `user://`; `configure(root)` for tests). Sections: `[meta]` (version 3, play time, room, timestamp),
  `[checkpoint]` (zone, entry), `[world]` (cleared rooms, defeated bosses, taken pickups, opened gates, read
  Book pages, rescues, Rule Pages, shards), `[player]` (the `PlayerSnapshot` without current Courage: health
  never saves) and `[flags]` (the `WorldFlags`). Written by write-temp, verify, keep the old file as `.bak`,
  rename (`SaveFile`); the file ends with an integrity footer (a ConfigFile comment) so a damaged file is
  recognised before the parser prints an engine error on it.
- **Loading** (`read_slot`) never wipes and never throws: the file, else its `.bak`, else (first slot) the v2
  `world_state.cfg`, else a clean new game, each step logged and a notice key set for the title (M4). An older
  format is migrated by `SaveMigration` (v2 to v3 today; the v2 file is kept as `world_state.cfg.migrated`
  after the first v3 save); a format too old to migrate is reported obsolete and left on disk; a save from a
  newer game is never read as damaged and never overwritten (`new_game` renames it to `.newer_game`).
  Nothing loads by itself: `ensure_session()` continues the active slot when the in-game scene starts and no
  run has begun, until `GameFlow` (M4) loads on Continue.
- **Who may save**: the shell calls `request_save(reason)` with one of `AUTOSAVE_REASONS`, the success events
  of R17 (room cleared, shortcut opened, persistent pickup, boss defeated, rescue, checkpoint reached, a beat
  flagged `save_after`, an unlock, a Book page). A death, a hit or a quit is not one: a death writes nothing.
  `tests/save/test_request_save_callers.gd` lists the callers; `tests/architecture/test_save_written_only_by_save_service.gd`
  holds that nothing else writes a save file.
- **The profile** (`<root>/profile.cfg`, same writer): what outlives a slot, today the `completed` mark, which
  a New Game keeps.

Health is carried across a zone travel (`game_root.player_health_carry`) but is never saved.

## Known deviations from the rules (honest list)

These exist today and are scheduled to be fixed by `docs/game-base-plan.md` §14, not by
ad-hoc edits:

- Nothing in `presentation/` reads a component any more (the HUD bridge and the board read
  `world.hud_snapshot`), but `game_root.gd` still WRITES a few: `PlayerTag.control_enabled`,
  `PlayerCombat.sword_unlocked`, the health carry and removing `VIEW_REF`. The channel that replaces the
  writes (`world.commands`) exists since M3a step 1 but nothing pushes on it yet; M3b moves the
  writes over (the carry through the `PlayerSnapshot`). The skill slot is redrawn on `skill_cooldown`
  events, as it always was, so after the sword is found it says "find sword" until the first
  skill is used; the M4 widgets draw the snapshot every frame and end that.
- Three shell keys (`F3`, `F11`, `B`) are raw keys, not `InputMap` actions. `InputPoller` publishes them in
  the snapshot as `debug_view_toggle`, `fullscreen_toggle` and `rule_book_toggle` so nobody else calls
  `Input`; M4 adds the actions under the same names and deletes the table (`R` is already the
  `restart_room` action).
- `ViewSyncSystem` blinks the invulnerability tint from the wall clock.
- `game_root.gd` (637 lines) still holds travel, death, persistence and HUD wiring together
  (the split is M3b).
- The checkpoint is moved on every zone travel, not only at a hub or a boss-room entry (D-16), and the save is
  requested with `checkpoint_reached` at each of those travels: the interim stand-in for the checkpoint rules
  (M3b step 3). The `cleared_room_ids` and `defeated_boss_ids` sets are saved and loaded but nothing writes them yet.
- The 72x40 kingdom (`tests/fixtures/the_kingdom.tscn`) is still a zone in the shipped world
  graph (`content/world/world.tres`, the one documented exception in
  `test_content_references.gd`, so the H1 exit keeps resolving until M5), and `first_encounter`
  (`tests/fixtures/first_encounter.tscn`) is a standalone room only the tests load.

## Reading order

1. `ecs/core/ecs_world.gd`, `ecs/components/ecs_components.gd`, `ecs/core/ecs_system.gd` — the whole ECS in ~400 lines,
   then `ecs/schedule/schedule.gd` (the order), `ecs/events/events.gd` and `ecs/events/commands.gd` (the two channels).
2. `ecs/core/ecs_grid.gd` (with `ecs/core/cell_kinds.gd`) — the board, the reserve -> commit protocol, the cell kinds, leaps, rays and the cached pathfinder.
3. `ecs/systems/input/player_input_system.gd` -> `ecs/systems/move/movement_system.gd` — one full step.
4. `ecs/systems/act/combat_system.gd` -> `ecs/systems/resolve/health_system.gd` — one full attack.
5. Data schemas: `schema/entity/*`, `schema/attacks/*`, `schema/world/*`, `schema/feel/*`.
6. `ecs/systems/decide/enemy_ai_system.gd` — the big one (381 lines).
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
| `tests/architecture/` | the guards: `test_dependency_edges`, `test_content_references`, `test_content_has_no_gd`, `test_sidecars_tracked`, `test_no_path_only_ext_resource`, `test_no_old_res_paths`, `test_fixtures_present`, `test_tools_keep_uids`, `test_all_scripts_load`, `test_dump_baselines`, `test_world_dumper_entry_cell`, `test_schedule_complete`, `test_events_declared`, `test_input_only_in_poller`, `test_save_written_only_by_save_service`, `test_suites_isolate_the_save` |
| `tests/ecs/` | the runtime seams of M3a: `test_schedule_order`, `test_world_fields`, `test_frozen_world`, `test_commands_channel`, `test_view_commands`, `test_emit_damage`, `test_heal_queue`, `test_boot_options`, `test_input_snapshot`, `test_hud_snapshot`, `test_player_snapshot_roundtrip`, `test_room_origin`, `test_grid_cell_kinds`, `test_leap_occupancy`, `test_ray_stops_at_blockers`, `test_path_cache`, `test_attack_setup_search` |
| `tests/bridge/` | `game_root.gd` characterization: travel, death and respawn, persistence, health carry, the Book, the world flags |
| `tests/save/` | the save: `test_save_roundtrip`, `test_save_migration_v2` (with the real v2 file in `tests/fixtures/saves/`), `test_corrupt_save_falls_back`, `test_request_save_callers` (R17), `test_profile_survives_new_game` |
| `tests/presentation/` | the board overlay drawing from the snapshot, and the camera framing the room (`test_board_draws_from_snapshot`, `test_camera_frames`) |
| `tests/perf/` | `test_room_tick_budget`: an 18x9 room with eight enemies ticks in 2 ms or less on average, and builds one pathfinder |
| `tests/audio/`, `tests/content/` | the bus layout; the requirements ledger and the placeholder manifest |
| `tests/support/` | `UnboundTest`, `TestPaths` (the only place a new test names a `res://` path), `reference_pathing.gd` (the pathing and the attack search as they were before M3a, the yardstick the new code is compared with), the harness's own test |
| `tests/fixtures/`, `tests/baselines/` | the kingdom, `first_encounter`, the harness fixtures and the v2 save; the six deterministic room dumps |

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

The tree above is the part of `docs/game-base-plan.md` §13 that M1b, M2 and M3a built: the folders, the
moves, the guards that keep code and content where they belong, the placeholder tools, the content
registry, the hero as data, the one actor view and the in-cell size table (M2), and, from M3a, the schedule files,
`events.gd` with `Events.emit_damage`, the commands channel with `CommandSystem`, the frozen world and the
world's other shared fields, the `EcsBoot` options object, the `InputPoller` and `PlayerInputSystem` reading the
`InputSnapshot`, the `HudSnapshot` and its system, the `PlayerSnapshot`, the per-room origin and camera framing,
and the grid's cell kinds, leaps, rays, cached paths and bounded attack search. The ECS contract is kept as it was.
Still to come, in plan order: the split of `game_root.gd` and the save service (M3b),
then the shell, input, text, story, skills, bosses and the other five districts. The
owner-facing "how do I change X" table, with real paths for what exists today, is
`docs/OWNER_GUIDE.md`.
