# Architecture

The Unbound Pawn — a 2D top-down grid-combat RPG in Godot 4.6.3. This document
describes the code **as it is built today** (checked against the tree on 2026-10-19, after
milestone M3a, M3b and M4; M3a built the runtime seams: the schedule, the declared events, the commands channel, the
world's shared fields, the input and HUD snapshots, the player carry, the per-room origin, and the
grid's cell kinds, leaps, rays and cached paths). The simulation is a full ECS; the
node-composition architecture that older docs described (`GridWorld`, `FreeEnemy`,
`PawnHero`, `EnemyActor`, `EncounterDirector`, per-actor component nodes) was deleted in
the ECS conversion (`docs/ecs-conversion-plan.md`, owner decision 2026-07-19). The folders
were rearranged in M1b to the tree of `docs/game-base-plan.md` section 13; the move is
recorded file by file in `docs/migration-notes.md` and `tools/move_res_log.tsv`. M2 then added the
content registry (`ContentDb`), the hero as data (`PlayerDefinition`), the one actor view and the table
that keeps every piece smaller than its cell; the section "The content registry, the hero and the actor
view" below is where they fit together. M3b then replaced `WorldState` with the `SaveService` (step 1,
section "Persistence") and split `shell/game_root.gd` into an `EventRouter`, one bridge per
responsibility and a `GameFlow` that starts a room again without reloading the scene (step 2, section
"Presentation and the bridges"), and step 3 moved the rules of a room's end into the simulation
(`ObjectiveSystem`, `CheckpointSystem`: sections "System order" and "Rooms, checkpoints and deaths").
M4 then built the shell in four steps. Step 1 made `AppRoot` the main scene: the whole run is a `GameFlow` state machine (boot,
title, playing, paused, ending, credits), the title, the credits and the autosave tick exist, and the music and the fade live in
`AppRoot` and survive every screen (section "The app around the game"). Step 2 gave the game its full `InputMap` with a gamepad
event on every played action and the pause menu. Step 3 added the settings screen, the Controls panel, the glyph lookup and the
text pipeline (sections "Text" and "Settings, controls and glyphs"). Step 4 made the HUD a layer of widgets, each a scene of its own,
kept in two strips so none covers a row of the board (section "The HUD: widgets in two strips"), and gave the camera its
integer-pixel snap.

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
animates the puppet views from component data. `shell/game_root.gd` is the in-game scene: it
builds the world, ticks it, and hands the drained event queue to the **bridges**, one per
responsibility (HUD, board overlay, camera shake, sound, the status line, the save, zone travel, the
Book, the end of a room); it holds no rule itself. Tuning lives in `.tres` Resources under `content/`.

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
| Damage and heal queues | `EcsWorld.damage_events`: `[{target, source, amount, direction, tags}]`, `EcsWorld.heal_events`: `[{target, source, amount}]` | built only by `Events.emit_damage()` and `Events.emit_heal()` (damage from `CombatSystem` and `EnemyAISystem`, heals from `CheckpointSystem`), drained only by `HealthSystem` |
| Spatial index | `EcsWorld.grid` (`EcsGrid`) in `ecs/core/` | cell occupancy, blocks, move reservations, A*, doors, gates, floor items |

`EcsWorld.tick(delta)` calls every system in registration order, and `Schedule.populate(world)` registers
them in the order of `ecs/schedule/`. A frozen world (`frozen`) ticks only the systems whose
`runs_while_frozen()` is true: `CommandSystem`, so a freeze can be lifted, and `ViewSyncSystem`, so the
picture keeps being drawn; the check is made before each system, so a freeze applied at the head of a
tick stops the rest of that tick. `game_root.gd` sets `manual_tick = true` and ticks the world from its
own `_process`, so a room that has ended (`RoomOutcomeBridge.room_ending`) simply stops ticking. Tests
also drive `tick(delta)` by hand.

## Folder structure (what exists today)

The top-level folders are layers. Each has one job, and the table after the tree says which
layer may name which.

```text
project.godot            main scene shell/app_root.tscn (AppRoot); autoloads SfxManager, SaveService; config/version
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
  story/                 credits.tres (CreditsDefinition: the owner, the engine) and credits_licenses.tres (generated
                         from THIRD_PARTY_NOTICES.md by tools/build_credits_licenses.gd); every word of the game lives in
                         story/text/<language>/{story,ui,skills,rooms}.po (en is complete, vi is empty)
  ui/theme/theme.tres    UiTheme: the project theme; it names the four font files the owner supplies (assets/fonts/)
  rules/<id>/page.tres   Book of House Rules pages; rule_book.tres lists them
  skills/<id>/           the Wooden Sword and Pencil Thrust AttackProfile .tres and the sword icon
  tilesets/<kit>/        tileset.tres + tilemap.tscn (kingdom, playground); tile_map_data is binary. `greybox/` is the
                         kit tools/build_room.gd paints with: one flat tile for each kind of cell (CellKinds)
  world/world.tres       WorldGraph: the rooms with their map slots, the doors between them, the locks, the districts' regions

schema/                  THE SHAPE OF CONTENT: one Resource class per file
  entity/                EnemyDefinition, PlayerDefinition, VisualDefinition, MovementConfig, DecisionConfig, EnemyIntent
  attacks/               AttackPattern, AttackProfile, EnemyWeapon
  world/                 WorldGraph (+ WorldRoom, WorldEdge, WorldLock, WorldRegion, FlagId), RoomObjective, RuleBook, RuleEntry
  feel/                  DifficultyProfile, PieceSizeTable, PieceSize
  story/                 CreditsDefinition, CreditsSection
  ui/                    UiTheme (a Theme that names the owner's font files)
  settings/              GameSettings (the player's choices, ONE object) and SettingDefinition (one row of its table)

ecs/                     THE SIMULATION: rules only; no art, prose or tuning numbers
  core/                  EcsWorld, EcsGrid, CellKinds, EcsSystem, WorldFlags, InputSnapshot, HudSnapshot, PlayerSnapshot
  components/            ecs_components.gd (frozen); tuning.gd (Tuning), room_objective_state.gd, room_checkpoint.gd,
                         and every new component in its own file
  systems/<folder>/      command/CommandSystem  input/PlayerInputSystem  decide/EnemyAISystem
                         move/MovementSystem  act/CombatSystem  resolve/HealthSystem
                         react/ObjectiveSystem  progress/CheckpointSystem  view/HudSnapshotSystem, ViewSyncSystem
  events/                events.gd (every event, its payload, emit_damage/emit_heal), commands.gd (every request)
  schedule/              one file per stage of the tick + schedule.gd (the order is data here)

authoring/               THINGS YOU DRAG INTO A SCENE: Inspector data + apply(); no logic
  ecs_boot.gd            the baker: reads a room scene, builds the world (EcsBoot.boot(world, EcsBootOptions))
  ecs_boot_options.gd    everything boot() needs besides the world, as named fields (EcsBootOptions)
  ecs_actor_factory.gd   builds actor entities from definitions (EcsActorFactory)
  entity_components/     EntityComponent nodes (Combat, Health, Input, Movement, AI, Weapon)
  markers/               zone entry/exit, gate, player unlock, pickup spawn, blocker, traversal gap, state variant (+ their scenes)
  room_encounter.gd/.tscn  the room scene root (zone id, objective, `checkpoint_on_entry`, and the room's meta)

presentation/            HOW THE WORLD IS SHOWN: reads events, never decides
  views/                 actor_view.gd, weapon_pickup + pickup_visual, and actors/: actor_view_base.tscn
                         (the one actor view) and the thin scenes that inherit it (player, black_pawn,
                         knight_enemy, bishop_enemy)
  ui/hud/                GameHud (the layer), HudWidget (the base of a widget) and widgets/: one scene and script per widget
                         (CouragePips + CouragePip, RankBadge, SkillSlots + SkillSlot, EnemyCount, ObjectiveLine, ControlPrompts,
                         DebugReadout, the reserved BelieveSlot and BossBarSlot) and the two effects, DamageFlash and ResultPanel
  ui/codex/              the Book of House Rules screen
  ui/menu/               ConfirmPanel: the shared yes-or-no question (New Game over a used slot; the pause menu's confirms)
  ui/autosave_indicator/ AutosaveIndicator: the tick that shows for a second after every autosave
  ui/theme/              UiFonts: puts the owner's font files on the project theme when the game starts; UiContrast: the
                         High-contrast menus look (opaque panels, outlines, white text), put on and taken off that theme
  ui/input_glyphs/       InputGlyphs (the lookup: an InputMap action + a device -> the owner's 16x16 picture or the words that
                         stand in), InputGlyph, LastInputDevice (which device was used last), GlyphStrip, ActionPrompt
  ui/controls/           ControlsPanel (built from the InputMap each time it opens) and ControlsCatalog (names, pages, "coming later")
  text/                  TextService (the ONE caller of the engine's translation), TextKey, LiveText, PseudoLocale
  board/                 PrototypeBoard (telegraphs, F3 debug) and GridLinesOverlay
  camera/                CameraRig (frames the room; the view always starts on a whole pixel)
  audio/                 SfxManager (autoload scene)
  bridges/               EventRouter and the bridges that only draw, say or play: EventBridge (their base), HudBridge,
                         BoardBridge, CameraBridge, AudioBridge, MessageBridge. They name no world, save or component.

shell/                   THE GAME AROUND THE GAME
  app_root.gd/.tscn      AppRoot, the main scene: owns the GameFlow, the music, the autosave tick and the fade, and swaps the screen
  transition_layer.gd    TransitionLayer: the persistent fade to black and back (a CanvasLayer that runs while paused)
  title/                 TitleScreen (the menu, New Game's confirm, the rug board) and TitleSummary (what the slot says: Continue, card, notice)
  credits/               CreditsScreen: lays out content/story/credits.tres and scrolls it; holding Confirm skips
  game_root.gd/.tscn     the in-game scene (test-capped at 200 lines): builds the world, ticks it, routes events; runs alone too
  game_flow.gd           GameFlow: the state machine of the run (boot, title, playing, paused, respawning, ending, credits)
  zone_stage.gd          ZoneStage: scene-tree plumbing (the world node, the entry cell, zone and hero-view swaps)
  shell_keys.gd          ShellKeys: pause (Esc, Start), F3 (the debug view: the board's layer and the HUD's readout), F11 and B,
                         read from the frame's InputSnapshot
  pause/                 PauseMenu (Resume, Book, Settings, Controls, Assist options, Restart Room, Quit to Title; the two last ask
                         first) and PauseSummary (what its questions say)
  settings/              SettingsScreen (four pages built from the table), SettingsStore (the profile file), SettingsApplier
                         (volumes, fullscreen, language, high-contrast menus)
  bridges/               the bridges that must reach the world, the save or a component: ShellBridge (their base),
                         SaveBridge, ZoneTravelBridge, BookBridge, RoomOutcomeBridge, DespawnBridge, SettingsBridge
  content/               ContentDb (the content registry, a static class) and ContentKind
  input/input_poller.gd  InputPoller: the one reader of the Input singleton; fills world.input_snapshot once per frame
  save/                  SaveService (the autoload: the run in memory, the slots on disk, the profile) and its
                         helpers SaveData, SaveFile, SaveMigration, SaveLoadResult (see Persistence)

assets/                  shared raw art and audio not owned by one content item
  tiles/<kit>/atlas.svg  tile atlases   ui/actor_view/  the overlay pictures every actor view shares
  map_pieces/            the owner's hand-drawn bedroom pieces   sfx/ music/   audio
  concept-art/           references, never shipped   _generated/   generator output (gitignored)

tools/                   generators, the runner, the migration scripts (never shipped; tools/README.md)
tests/                   run_tests.gd + six runtime tests + architecture/ audio/ bridge/ content/ ecs/ input/ presentation/ settings/
                         shell/ support/ text/
                         fixtures/ (the 72x40 kingdom, first_encounter, the harness fixtures) baselines/
docs/                    this file, coding-standards.md, OWNER_GUIDE.md, plans, design/, archive/
```

Not built yet (the plan's later milestones): `schema/skills`,
`schema/progression`, `schema/audio`, the rest of `schema/story`,
`shell/pause|settings`, `presentation/story|vfx`, `content/story|audio|ui|bosses|props|progression` and the rest of `content/feel`,
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

## The app around the game

```text
shell/app_root.tscn  ->  AppRoot (shell/app_root.gd), the main scene, never replaced
  MusicPlayer        the march; autoplay, bus Music, PROCESS_MODE_ALWAYS (a death, a room change or the title never restart it)
  ScreenHost         the ONE current screen is its child: TitleScreen, GameRoot or CreditsScreen
  OverlayLayer       AutosaveIndicator (the tick); keeps running while the tree is paused
  MenuLayer          the PauseMenu (hidden until the flow is PAUSED), the SettingsScreen and the ControlsPanel (each hidden
                     until asked for; later siblings sit on top and take the key first); keeps running while the tree is paused
  LastInputDevice    which device the player used last, for the prompts' glyph set
  TransitionLayer    the fade to black and back; the topmost layer; swallows the mouse while it is visible
```

`GameFlow` (`shell/game_flow.gd`, a plain object AppRoot owns) is the state machine of plan 9.1 and decides which
request is legal when; AppRoot shows. A request is a method (`start_new_game`, `continue_game`, `request_pause`,
`quit_to_title`, `reach_ending`, `show_credits`, ...), a refused one changes nothing, and `state_changed` is what
AppRoot listens to:

```text
BOOT -> TITLE -> (New Game | Continue) -> PLAYING <-> PAUSED
PLAYING -> RESPAWNING -> PLAYING          a death, or Restart Room: the room is rebuilt behind the fade
PLAYING -> ENDING -> CREDITS -> TITLE     the completed mark is written when the ending is reached
TITLE -> CREDITS -> TITLE                 replay from the title
PLAYING | PAUSED | ENDING -> TITLE        Quit to Title (writes nothing; progress since the last save is lost)
```

A screen change is fade to black, free the old screen (taken out of the tree at once), build the new one, fade back;
changes run one after another in the order asked (`AppRoot._queue_step`), so a quick double request cannot build two
screens. A pause is not a screen change: AppRoot sets `get_tree().paused` when the state is PAUSED and opens the pause menu
(Restart Room is the menu's command, D-18), and GameFlow refuses a pause during a zone trip, a waiting rebuild and the defeat beat.
New Game calls `SaveService.start_new_run()`: a clean run begins and the slot's file becomes that clean run at once,
the old save stays as the `.bak`, the profile (the `completed` mark) is untouched. Continue first asks
`read_slot()` whether the slot holds readable progress (a damaged file with no backup, one too old to migrate and one
from a newer game do not), then `load_slot()`: the game scene boots in the room and on the entry of the LAST SAVE.
`TitleSummary.from_save()` is what the title shows about the slot (Continue offered, the card, the one-line notice
when the loader fell back to the `.bak` or gave up, the `completed` mark). The in-game scene is built by AppRoot with
the app's flow handed to it before it enters the tree (`game.game_flow = ...`); run alone (a test, F6 in the editor)
it makes its own flow, already PLAYING, and `SaveService.ensure_session()` continues the saved run. The scene
names no AppRoot (`test_app_root_is_main_scene`). The zone trip keeps its own fade in the game scene
(`ZoneTravelBridge`): a trip between two rooms is the game's, a change of screen is the app's.

## Runtime flow

```text
shell/game_root.tscn  ->  GameRoot (shell/game_root.gd, class GameRoot)
  _ready()      attaches the bridges to the scene's nodes and registers each with the EventRouter, in the
                order _bridges() lists; SaveBridge.begin() continues the saved run when none has begun; the
                run's room and entry say which zone and entry to boot on (the zone node is swapped if the
                run was saved elsewhere); then boot_zone(entry_id)
  boot_zone()   1. ZoneStage.make_world(): new EcsWorld + Schedule.populate (the systems, order below)
                   and EcsBoot.shape_grid(): the room's bounds and its centred grid origin
                2. EcsBoot.boot(world, EcsBootOptions) -> the "cast" (the options carry what the run
                   already knows: taken persistent pickups, opened gates, whether the room is already
                   cleared; how the pawn arrived: the entry, through a door or not; the PlayerSnapshot a
                   zone trip carries; and `with_room_rules`, which gives the room its own entity)
                3. every bridge is bound to the new world's HudSnapshot and cast; SaveBridge.restore_run()
                   (world flags, the run's room and entry, closed-gate pictures), BookBridge.meet_pieces(),
                   SaveBridge.apply_unlocks(), RoomOutcomeBridge.begin_room()
                4. HudSnapshotSystem.build(world), then the board, camera and HUD bridges draw the room
  _process()    input_poller.poll(delta, world.input_snapshot)  ->  ShellKeys.handle(snapshot)  ->
                ecs.tick(delta)  ->  router.route(ecs.drain_events())  ->  HudBridge.refresh()
```

A death and the pause menu's Restart Room do not reload the scene. When the hero falls, `CheckpointSystem` says
`respawn_requested`; `RoomOutcomeBridge` plays the defeat beat (0.85 s) and AppRoot answers the pause menu's confirmed
Restart Room, and both call `GameFlow.request_respawn()`, which raises its own `respawn_requested` signal, waits out a zone trip under way
and (under AppRoot) the fade to black, and at the end of the frame has `GameRoot.respawn()` rebuild the room: a fresh instance of the zone the run says
the pawn is in, a fresh hero view in its boot pose (a fallen hero's view rests in its defeat clip), the Book
closed, nothing carried, then `boot_zone()` on the entry the pawn came in by (D-16: a death resets only the room
it happened in). The `SaveService` (an autoload) holds the run in memory and remembers the room and entry, so the
rebuilt room is in the right place. What the scene keeps is the run, the music, the F3 switch and the HUD, board
and camera nodes (re-bound by `setup()`). Zone travel (`zone_exit` event, `ZoneTravelBridge`) fades out, swaps the
zone scene node, **rebuilds the whole `EcsWorld`**, and fades in. No entity survives. What carries over is the
hero's view node, the run in the `SaveService` (its flags are loaded into every new world) and the
`PlayerSnapshot` the bridge captured when the trip began (Courage, the sword, the flags; `EcsBoot` applies it to
the new hero).

### System order (the schedule, `ecs/schedule/`)

The order is data: one file per stage in `ecs/schedule/` (`command`, `input`, `decide`, `cell_effects`,
`move`, `act`, `resolve`, `react`, `progress`, `view`) and `Schedule.populate(world)`, which both
`shell/zone_stage.gd` (for the in-game scene) and `tools/world_dumper.gd` call. A system file carries `const PHASE` naming the
stage that lists it. A stage is named for when it runs and a folder for what its systems are about, so
they differ where the plan's order (`docs/game-base-plan.md` 13.4) visits one folder several times; the
empty stage (`cell_effects`) waits for the milestone that fills it.
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
| 7 | `ObjectiveSystem` (`react`, `react/`) | `ENEMY_AI`, `PLAYER_TAG`, `HEALTH`, the room's `RoomObjectiveState` (and its `RoomObjective`) | `RoomObjectiveState` (the counts, `cleared`, `failed`); emits `room_cleared` |
| 8 | `CheckpointSystem` (`progress`, `progress/`) | the room's `RoomCheckpoint` and `RoomObjectiveState`, `PLAYER_TAG`, `HEALTH` | `RoomCheckpoint` (what it has said); `heal_events` (the checkpoint refill); emits `checkpoint_set`, `respawn_requested` |
| 9 | `HudSnapshotSystem` (`view`, `view/`) | the hero, the room's counts, the enemies | `world.hud_snapshot`, in place |
| 10 | `ViewSyncSystem` (`view`, `view/`) | almost everything, read-only; `view_commands`. Runs while the world is frozen | the **only** node writes: position, depth (`z_index = 2 + row`), tint, aura, facing arrow, weapon, health pips, `AnimationTree` conditions and `travel()` |

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
`docs/coding-standards.md`). Three such files exist: `tuning.gd` (`Tuning`, the assist knobs, held by the
world as `EcsWorld.tuning`) and, on the **room's own entity** (see "Rooms, checkpoints and deaths"),
`room_objective_state.gd` (`RoomObjectiveState`: the zone, the room's `RoomObjective`, the enemy counts, `cleared`,
`failed`) and `room_checkpoint.gd` (`RoomCheckpoint`: the entry the pawn came by, whether coming in is a
checkpoint, whether it came through a door, and what `CheckpointSystem` has already said).

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
built. The zone swap passes one (`ZoneTravelBridge` captures it when a trip starts, `GameRoot.boot_zone` hands it
to `EcsBoot`): Courage, the sword and the flags arrive in the next room, the per-room rows and the facing do not
(`test_player_carry_zone_swaps`). `test_player_snapshot_roundtrip` holds the class itself.

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
| `EcsBoot` | `authoring/ecs_boot.gd` | static `boot(world, options)`, where `options` is an `EcsBootOptions` (`authoring/ecs_boot_options.gd`: `player_view`, `room_root`, `fallback_player_cell`, `skipped_pickup_names`, `opened_gate_ids`, `room_already_cleared`, `with_room_rules`, `entry_id`, `entered_by_door`, `player_snapshot`, `restore_player_facing`; a new need is a new field, never a new argument; `EcsBootOptions.for_scene(hero, room)` is the common case): sizes the grid from `RoomEncounter.board_size`, bakes the tile kinds (`apply_tile_kinds`), `ZoneExitMarker`, `PlayerUnlockMarker` and `GateMarker`; spawns the player from the view's `PlayerDefinition` (class defaults when it names none) and applies its `EntityComponent` nodes, then every `ActorView` child of the room that has a `definition` (none, and their puppets removed, when the run already cleared the room), then pickups, then (with `with_room_rules`) the room's own entity, last, so every other entity keeps its number. Returns the cast dictionary (`player`, `enemies`, `view_by_entity`, `piece_name_by_entity`, pickup maps, `persistent_pickup_by_entity`, `room`). |
| `EcsActorFactory` | `authoring/ecs_actor_factory.gd` | `spawn_player` (bare hero, kept), `spawn_player_from_definition` (what `EcsBoot` calls), `spawn_enemy`, `spawn_pickup`: assemble an entity's components from the `.tres` data and apply the difficulty multipliers. |
| `ContentDb` | `shell/content/content_db.gd` (+ `content_kind.gd`) | the content registry, a static class (no autoload, so it works inside a suite's `_init()`). Ids are folder names under `content/<kind>/`, listed lazily once per kind. `ids(kind)`, `fetch(kind, id)`, `all(kind)`, `player()`, `world()`, `piece_sizes()`, `validate()`, `validate_cross_refs()`. Ten kinds registered (one line each in `_ensure_kinds()`). Only the shell may name it; tests and tools call the two validators, nothing calls them at game start. |
| `RoomEncounter` | `authoring/room_encounter.gd` | a room scene root: `board_size`, `zone_id`, prose, a `RoomObjective`, and `checkpoint_on_entry` (true on the hub and the boss room: coming in through a door is a checkpoint, D-16). Since M5 it also carries the room's META (docs/game-base-plan.md 7.5): `act` (1 to 6, 7 = the Ending), `district`, `layout_archetype`, `recipe` (Rest, Teach, Test, Twist, Boss, Shortcut...), `content_status` (STUB, GREYBOX, DRESSED, FINAL) and `time_of_night` (inert data, D-31). Every field has a doc and an editor configuration warning; `configuration_problems()` is the same list for tests and tools (a scene under `content/rooms/` is a shipped room and is also held to an id equal to its folder, a start line, an act, a district and an archetype). It carries data only. |
| Markers | `authoring/markers/` | `GridMarker` base (drag to snap, writes `grid_cell`). `ZoneEntryMarker`/`ZoneExitMarker` (doors: a door is a FLOOR cell one step inside the room's ring of wall, like the east doors, and its entry marker is the cell next to it, one further in, so the pawn arrives beside the door and a step back through it is the way home; a door on the ring itself is a solid cell nobody can stand on, and `tests/content/test_room_doors_reachable.gd` fails it), `GateMarker`, `PlayerUnlockMarker`, `PickupSpawnPoint` (`persistent`: a reward taken once for the whole run; off, it is a floor weapon of its room and is back whenever the room starts). `BlockerMarker` is a legacy marker `EcsBoot` no longer bakes; walls are painted tiles. A `GridMarker` follows its room: with a `RoomEncounter` parent it snaps to that room's `board_size` and the origin that centres it (an 18x9 arena starts at x 32, not 64), and `PlayerUnlockMarker` bakes from `grid_cell` like a pickup. M5 adds two DATA-ONLY schemas. `TraversalGapMarker` (`grid_cell`, `length` 1 to 3, `direction`, `verb` chalk_path or rule_step, `free_when_calm`): a mandatory crossing over gap cells; `EcsBoot` copies it to each cell it covers in `EcsGrid.marker_by_cell` under `TraversalGapMarker.KIND`, and the verbs that cross it arrive with M7 and M10. `StateVariantMarker` (`variant_id`, `requires_flags`, `forbids_flags`): a prop, its children, that shows only in a state; M6 bakes it into a `FlagVisible` component. Both warn in the Inspector and answer `configuration_problems()`. |
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
`WorldGraph` (`content/world/world.tres`; see "The world graph and the room builder" below) are the other schemas. Shared
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
entry marker that exist (`WorldCheck` does the world part: see below), every room's `zone_id` equals its folder and every enemy parked in a room is a registered
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

25 types are emitted today (the 19 the plan counted when M3a began, plus `healed`, `flag_set` and
`command_rejected` from M3a and `room_cleared`, `checkpoint_set` and `respawn_requested` from M3b step 3). The
bridges answer 19 of them through the `EventRouter`; the others (`step_started`, `step_finished`,
`step_blocked`, `attack_started`, `flag_set`, `command_rejected`) are emitted for tests and future
presentation, and the router drops a type nobody registered for.

| Event | Payload keys | Handled by |
|---|---|---|
| `step_started` / `step_finished` | `entity`, `cell` | — |
| `step_blocked` | `entity`, `direction` | — |
| `attack_started` | `entity`, `cells` | — |
| `attack_landed` | `entity`, `cells`, `hit_count`, `profile` | BoardBridge (strike flash), CameraBridge (shake), MessageBridge (status) |
| `attack_locked` | `entity` | MessageBridge ("no weapon yet") |
| `skill_cooldown` | `entity`, `time_left` | HudBridge (skill slot) |
| `telegraph_started` / `telegraph_finished` | `entity` (+ `cells`) | BoardBridge |
| `attack_resolved` | `entity`, `cells` | BoardBridge |
| `intent_changed` | `entity`, `intent` | BoardBridge (F3 paths) |
| `damaged` | `entity`, `amount`, `remaining`, `direction`, `source`, `tags` | CameraBridge (shake), HudBridge (Courage, flash), MessageBridge (status) |
| `defeated` | `entity`, `source`, `tags` | BoardBridge (clear marks), DespawnBridge (view after the clip) |
| `healed` | `entity`, `amount`, `remaining`, `source` | HudBridge (Courage pips: a checkpoint refill is a heal from source 0) |
| `pickup_taken` | `item`, `cell` | SaveBridge (`pickup_taken`, for a persistent pickup only), AudioBridge (chime), DespawnBridge (free the pickup view) |
| `weapon_changed` | `entity`, `weapon` | MessageBridge |
| `player_unlock` | `entity`, `id`, `message` | SaveBridge (`unlock_gained`, the sword), AudioBridge, MessageBridge |
| `gate_opened` | `entity`, `gate`, `cell` | SaveBridge (`shortcut_opened`, hide the gate picture), AudioBridge, MessageBridge |
| `zone_exit` | `entity`, `zone`, `entry` | ZoneTravelBridge |
| `zone_exit_locked` | `entity`, `zone`, `entry`, `cell`, `message` | MessageBridge (locked-door line: the door's own `locked_message`, else a generic one) |
| `room_cleared` | `zone`, `defeated`, `total`, `has_objective` | SaveBridge (`cleared_room_ids`, saves `room_cleared`), RoomOutcomeBridge (the result screen, when the room ends) |
| `checkpoint_set` | `zone`, `entry`, `refills` | SaveBridge (the run's checkpoint, saves `checkpoint_reached`) |
| `respawn_requested` | `entity`, `zone`, `entry` | SaveBridge (takes the world's flags), RoomOutcomeBridge (the defeat beat, then `GameFlow.request_respawn`) |
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

## Presentation and the bridges

Presentation consumes `drain_events()` and never decides gameplay. The scene does not react to events
itself: `EventRouter` (`presentation/bridges/event_router.gd`) hands each drained event to the bridges that
registered for its type, in the order `GameRoot._bridges()` lists them, and a type nobody registered for is
dropped. A bridge is ONE responsibility; it learns the running room only through the world's `HudSnapshot` and
the cast `EcsBoot` returned (`EventBridge.bind_world`, after every boot). The dependency table (13.1) splits them
in two folders:

| Bridge | Where | Owns | Events |
|---|---|---|---|
| `BoardBridge` | `presentation/bridges/` | telegraph cells, strike flashes, F3 intent paths on `PrototypeBoard` | `telegraph_*`, `attack_resolved`, `attack_landed`, `intent_changed`, `defeated` |
| `CameraBridge` | `presentation/bridges/` | the two screen shakes (named constants), framing each room | `attack_landed`, `damaged` |
| `HudBridge` | `presentation/bridges/` | the HUD: it hands the snapshot to the widgets every frame (Courage, the skill slot, the enemy count, the Rank badge and the debug readout's cell line draw themselves from it), flashes the screen on a hit on the hero, puts the result panel up and names the enemy that strikes next on the debug readout (a name is the cast's, not the snapshot's) | `damaged` |
| `MessageBridge` | `presentation/bridges/` | every sentence an event puts on the status line (as text keys, `MSG_...` rows of ui.po) and `say(key, params)` for the others | `attack_locked`, `attack_landed`, `damaged`, `weapon_changed`, `player_unlock`, `gate_opened`, `zone_exit_locked` |
| `AudioBridge` | `presentation/bridges/` | the event sounds through the `SfxManager` registry; the only caller of it | `pickup_taken`, `player_unlock`, `gate_opened` (+ `play()` for the room outcome) |
| `SaveBridge` | `shell/bridges/` | what the room writes into the run and the run gives back to each room (cleared rooms, the checkpoint, the room and entry the pawn is in, persistent pickups, gates, unlocks, flags); the ONLY asker of saves (R17) | `pickup_taken`, `player_unlock`, `gate_opened`, `room_cleared`, `checkpoint_set`, `respawn_requested` |
| `DespawnBridge` | `shell/bridges/` | a taken floor weapon's view; a defeated enemy's view after its 0.6 s defeat clip | `pickup_taken`, `defeated` |
| `RoomOutcomeBridge` | `shell/bridges/` | what a room's end looks like: the result screen of a won room (quiet in the world unless the room has an objective), the hero's fall, the 0.85 s defeat beat and the request to start the room again; it judges nothing | `room_cleared`, `respawn_requested` |
| `ZoneTravelBridge` | `shell/bridges/` | the trip between zones (guards, fade, swap, boot, fade) and the `PlayerSnapshot` it carries | `zone_exit` |
| `BookBridge` | `shell/bridges/` | a met piece writes its page; the B key opens the Book | none (called by the scene and `ShellKeys`) |
| `SettingsBridge` | `shell/bridges/` | makes the settings of the room true: the camera bridge's shake scale, the HUD's and the board's Reduce flashing, the board's High-contrast danger, the poller's hold-or-toggle, and the four assists plus Reduce flashing as `tuning_set` commands (sent again after every boot) | none (it listens to `GameSettings.changed`) |

The six in `presentation/bridges/` name no world, no save and no component, so 13.1 lets them live in
presentation. The six in `shell/bridges/` (base class `ShellBridge`, which holds the `GameRoot`) write the
run, rebuild the world or flip a component, so they sit in the layer allowed to name everything. The plan's
tree (13.2) lists a `save` handler under `presentation/bridges/`; 13.1 forbids presentation to name the
`SaveService`, so it is in the shell. Each bridge has a test that drives it through a real router
(`tests/bridge/test_*_bridge.gd`) or through the real scene.

- `shell/game_root.gd` — the in-game scene (see Runtime flow): finds its nodes, boots the world, ticks it
  and routes the events. It holds no rule (`test_game_root_is_thin`: at most 200 lines, no event handler, no save
  request, no scene reload). `shell/zone_stage.gd` holds the scene-tree plumbing, `shell/shell_keys.gd` the
  game's own keys (pause, F3, F11, B).
- `shell/game_flow.gd` — `GameFlow`, the state machine of plan 9.1 (see "The app around the game"). A death and
  the pause menu's Restart Room `request_respawn()`, it raises `respawn_requested` and, once per frame, after a trip under way and
  after AppRoot's fade, `GameRoot.respawn()` starts the room again. Nothing reloads the scene
  (`test_no_scene_reload`) and nothing calls `change_scene` (`test_app_root_is_main_scene`).
- `PrototypeBoard` (`presentation/board/`) — the combat overlay: telegraph cells, hit flashes,
  F3 debug paths. The one place `_draw()` is allowed for gameplay overlays. It reads the board
  geometry from the grid (duck-typed) and everything else from `world.hud_snapshot`.
- `GameHud` (`presentation/ui/hud/`, a `CanvasLayer`) — the layer that holds the widgets and routes to them (see "The HUD:
  widgets in two strips"). It decides nothing; every word it shows is a text key resolved by `TextService` and kept in the
  player's language by a `LiveText` (see "Text").
- `CameraRig` (`presentation/camera/`) — a `Camera2D` that is a child of the player view (so it
  follows by tree parenting), clamps to the room and shakes via the built-in offset. A room that fits the
  picture is held still with the board centred and every cell on screen (the limits are one view wide
  around the board's centre, `CameraRig.limits_for_board`); a larger one scrolls with the hero and stops
  at its edges. The shell calls `setup(grid)` after every boot, so the clamp follows the new room
  (`test_camera_frames`). **The view always starts on a whole pixel of the world** (D-30, requirement 10;
  `snap_to_whole_pixels`, on by default): all art is drawn 1x1 at 640 x 360, so a view between two pixels would
  shimmer as the follow point eases or the screen shakes. The engine's own smoothing runs after anything the rig
  can do, so with the snap on the rig eases the follow point itself (the same exponential catch-up, cut on
  `setup()`), asks the engine where the view lands (`force_update_scroll`), and moves it by less than half a
  pixel through the camera's `offset`, which the engine adds after the board's limits. The shake is rounded to
  whole pixels and is still scaled by the Screen shake setting (`CameraBridge.shake_scale`). Measured on the
  SubViewport's own canvas transform (`test_camera_snap`). The slide of a piece between cells is procedural gameplay
  timing: it is worked out in floats and `ViewSyncSystem` draws the view on the nearest whole pixel (`test_piece_slide_snap`), the
  simulation never sees the rounded position; the project's `snap_2d_transforms_to_pixel` rounds in window pixels (half a game pixel at
  1280 x 720) and was left alone, as was `stretch/scale_mode = integer` (the owner's call: it letterboxes a window that is not a
  multiple of 640 x 360).
- `RuleBookUI` (`presentation/ui/codex/`) — the Book of House Rules screen (key `B`).
- `SfxManager` (autoload, `presentation/audio/`) — pooled one-shot playback for event sounds
  with no clip. Motion sounds are audio tracks in the actor's `AnimationPlayer` clips. Only the
  `AudioBridge` calls it.
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

## The HUD: widgets in two strips

The HUD (docs/game-base-plan.md D-29, 9.2, 10) is a `CanvasLayer` (`GameHud`, `presentation/ui/hud/hud.tscn`) that holds one scene
per widget (`presentation/ui/hud/widgets/`), so a milestone adds a skill slot, a boss bar or a Believe mark by editing that
widget's scene and not a shared one. A widget extends `HudWidget` (a `Control` that takes no mouse): `refresh(snapshot)` draws what
the `HudSnapshot` says and does nothing when nothing changed, `forget_drawn()` makes the next frame draw it all again (a room that
just booted). A widget decides nothing and names no component, no world and no `Input` (`test_hud_widgets` scans the scripts).

```text
top strip, y 0 to 32 (a bar at most 28 px tall)                                 bottom strip, y 326 to 360
  CouragePips    x   6..152  the caption and one pip per point (at most 5)        ObjectiveLine    y 327..341  the status line
  BelieveSlot    x 156..192  RESERVED, hidden (M10)                               ControlPrompts   y 342..358  the control hints
  SkillSlots     x 198..318  room for four 24 px slots; slot 1 is the thrust      DebugReadout     y 342..358  F3: takes the hints' place
  BossBarSlot    x 322..418  RESERVED, hidden (M8b); 96 x 20, the asset list's frame
  EnemyCount     x 420..552  "ENEMIES 3/4"
  RankBadge      x 556..630  the Rank label as blue tally marks; hidden until the snapshot has one (M7c)
effects, not widgets of a strip:  DamageFlash (a fifth of a second after a hit; off with Reduce flashing)
                                  ResultPanel (the end of a room; hidden at the next one)
```

- **Who feeds what.** The snapshot feeds Courage (`player_courage_current/max`), the skill slot (`sword_unlocked`,
  `skill_cooldown_left/duration`), the enemy count (`room_enemies_remaining/total`), the Rank badge (`rank_label`, 0 until M7c) and the debug
  readout's cell line (`player_cell`, `player_facing`). The words of the status line come from the `MessageBridge`
  (`GameHud.set_status`); the damage flash and the result panel from the `HudBridge`; the strike line of the debug readout from the
  `HudBridge` too, because the name of a piece is the cast's. Courage needs no event: `HudSnapshotSystem` runs at the end of the tick
  that took the Courage, before the events are routed, so the frame that routes the hit draws it.
- **The safe zone** (`test_hud_safe_zone`, requirement 180). Every widget, shown or reserved, lies inside a strip, 4 px from the
  edges of the picture, and intersects no board: not that of any room, nor the largest 18 x 9 board the strips leave room for (its rows run
  y 36 to 324). The old HUD covered row 0 by about 10 px. The result panel is the one piece that sits over the board, and only when
  the room has ended. A board larger than the picture scrolls under the strips by design.
- **Control hints** are built from the `InputMap` and `LastInputDevice` (`ControlPrompts`): the first glyph of each action for the device
  in use, the owner's Kenney picture when the file is there and the words otherwise (`[Space]`, `[A]`), in the language in use;
  Move shows four glyphs on a keyboard and one on a pad. AppRoot owns the glyph finder and the device tracker and hands them to
  the game scene, which hands them to the HUD (`GameHud.configure_controls`); a scene run alone shows the keyboard.
- **Debug fields** (requirement 181): the pawn's cell and facing and the enemy that strikes next are in `DebugReadout`, hidden at the
  start. F3 (`ShellKeys`, the `debug_view_toggle` action) switches the board's debug layer and the readout together; the readout
  takes the place of the control hints. The scene's `debug_enabled` is forced off in a release export
  (`ShellKeys.debug_view_at_start`), whatever the scene says; `test_debug_overlay_default` drives it on the real scene.
- **Art.** The widgets are plain nodes today (a `Panel` with a `StyleBoxFlat` for a pip, `ColorRect`s, labels). The owner's pictures
  (the asset list's `hud_*` groups: pips, plates, frames, strips) arrive as textures and styles on these scenes; the Courage pip
  already takes its two looks as `StyleBox` exports. Nothing loads `content/ui/hud/` by path (the content rule): a scene names its
  picture by uid.

## Text: keys, rows and the language

Every word the player reads is a ROW of a gettext file and is named by a KEY (docs/game-base-plan.md 8.9, D-24, D-25).
Scenes, `.tres` files and scripts hold keys (`UI_PAUSE_RESUME`, `ROOM_T3_FIRST_PAWN_CLASH_LOCKED`,
`PAGE_FIRST_LAW_TITLE`); nothing but `TextService` asks the engine to translate (`test_tr_only_in_text_service`).

```text
content/story/text/<language>/{story,ui,skills,rooms}.po    four files per language, one table for the engine
  en/   complete; every row has words and a `#.` translator comment (test_po_domains_merge)
  vi/   empty on purpose; a key with no row falls back to en (project.godot internationalization/locale/fallback)
project.godot [internationalization] locale/translations     lists all eight files: several translations of ONE locale
presentation/text/
  text_service.gd   TextService.t(key, params): the row, with {name} filled; a key with no row renders as itself;
                    set_language(), languages(), language_name(); PREFIXES_BY_DOMAIN says which file a key's prefix belongs in
  text_key.gd       TextKey: a key (and its params) waiting to go INTO another line ("{piece} picked up {weapon}"), so a
                    language switch renames the piece inside the sentence too
  live_text.gd      LiveText: a child node of a screen; remembers which key and params each control shows and resolves them
                    again on NOTIFICATION_TRANSLATION_CHANGED; on_language_change() for screens built from data
  pseudo_locale.gd  PseudoLocale: the generated `qps` language, +40 percent and accented, {name} and %d untouched
```

- **Scenes** hold the key in a Label's or Button's `text`; the engine translates it and redraws it itself when the
  language changes (built-in auto translate), so a scene needs no code for its words. **Scripts** call
  `TextService.t(key, params)` and, when the text must follow a language change, put it on a `LiveText`
  (`set_text(control, key, params)`). A `TextKey` in a param is resolved with the line that holds it.
- **Resources** hold keys: `RoomEncounter.room_message`, `ZoneExitMarker.locked_message`, `PlayerUnlockMarker.message`, the
  `RoomObjective` lines, `RuleEntry`, `display_name`/`piece_name` of enemies, weapons and attacks, the credits. The schema classes
  never resolve them (schema may name nothing); the bridges and screens do.
- **Prefix -> file:** `UI_`, `MSG_`, `PROMPT_` -> ui.po; `ROOM_` -> rooms.po; `SKILL_`, `ITEM_` -> skills.po; `DLG_`, `AMB_`,
  `BOOK_`, `PAGE_`, `CHAR_`, `ENEMY_`, `BOSS_`, `CREDIT_`, `END_`, `CLUE_` -> story.po. Per-lane prefixes keep two lanes out of
  the same file.
- **Dumps and goldens print keys**, never sentences (`tools/world_dumper.gd`): a rewritten `.po` line must not change a baseline.
- **Guards:** `test_text_keys` (no prose left in a script, scene or resource; every key named exists; its allow-list is exact
  and gives a reason per entry), `test_po_domains_merge`, `test_tr_only_in_text_service`, `test_language_switch_redraws_live`,
  `test_layout_pseudo_locale` (HUD, title, pause menu, the four pages of the settings screen and the three of the Controls panel
  at 640 x 360 with every line 40 percent longer), `test_pseudo_locale`, `test_text_service`.
- **Tests run in English**: `UnboundTest` sets it before any suite starts, because the machine's own locale may be anything.
- **Fonts:** `content/ui/theme/theme.tres` is a `UiTheme` and the PROJECT theme (project.godot `gui/theme/custom`), so it also
  reaches Controls under a `CanvasLayer` (the HUD), which a Window's theme does not. It names four font files under
  `assets/fonts/` (the owner supplies them; nothing is downloaded); `UiFonts.apply` (called by AppRoot) sets the ones that exist
  and leaves the engine's default font where there is no file. `test_font_vietnamese_coverage` checks all 134 precomposed
  Vietnamese letters of the font in use; `test_font_slots` the slots.

## Settings, controls and glyphs

What the player chooses (docs/game-base-plan.md 9.2, 5.8, 10) is ONE object, `GameSettings` (`schema/settings/`), a table of
`SettingDefinition`s: the volume of each bus (Master, Music, SFX, UI), fullscreen, language, High-contrast menus, screen-shake
scale, Reduce flashing, High-contrast danger, hold-or-toggle for turn mode, Guard and Focus, and the four assists (Warning time, Enemy
pace, Extra Courage, Input forgiveness: neutral names, all at the standard game, never switched on for the player, D-22). The table
holds each setting's key, kind (slider, switch, choice, language), page, name key, default and range, so the screen, the profile and
the checks read one place; a new setting is one row, one name in `ui.po` and the line that makes it do something. Assists and
settings live in the profile (`profile.cfg`, `setting_<key>`), not in a slot: a New Game keeps them (the plan's 5.8 says assists are
per save; they are per profile here, which keeps them in one place and reachable from the title).

```text
AppRoot owns        settings: GameSettings   settings_store: SettingsStore   settings_applier: SettingsApplier
  at start          SettingsStore.load_settings()  (a value missing or unusable takes its default, logged with the reason; a
                    first run is one line)  ->  SettingsApplier.apply_all()
  on every change   GameSettings.changed  ->  apply_all()  and a write to the profile half a second after the last change
                    (flush_settings(): also when the settings screen closes, on Quit and on window close)
SettingsApplier     buses (volume in dB, muted at 0), the window's fullscreen, TextService.set_language, UiContrast.apply(theme)
SettingsBridge      (in the game scene, handed the same GameSettings) CameraBridge.shake_scale, GameHud and PrototypeBoard
                    reduce_flash, PrototypeBoard.high_contrast_danger, InputPoller.set_toggle_mode, and world.tuning through
                    `tuning_set` commands (after every boot too: a room is a new world)
SettingsScreen      four pages built from the table; edits GameSettings and nothing else; reachable from the title and the
                    pause menu (which also has Controls and Assist options, the last opening the Assists page)
```

Reduce flashing reaches the pieces through a `Tuning` knob (`reduce_flash`) that `ViewSyncSystem` reads: no hurt tint and no
seven-per-second invulnerability blink (the hero stays a steady, fainter colour). The camera shake, the HUD flash and the board's
strike flash and pulse are switched at their own node. A telegraph is never removed. The assists reach `world.tuning` and no system
reads them yet: the milestone that does is named on each field of `ecs/components/tuning.gd`.

**Controls and glyphs.** `ControlsPanel` (`presentation/ui/controls/`) is built from the live InputMap every time it opens: a
page per kind of control (`ControlsCatalog`), a row per action, a keyboard column and a gamepad column; an action the catalog has
no row for is listed under its own name and `test_controls_panel_from_inputmap` fails until it gets one; an action that does
nothing yet says "(coming later)" (the child's R, D-18). The pictures come from `InputGlyphs`: for an action and a device it finds
the owner's 16x16 file at the path the asset list gives (`assets/ui/glyphs/keyboard|gamepad/<name>.png`, the Kenney pack, which the
owner copies in; nothing is downloaded) and always the words that stand in (`[Space]`, `[A]`, `[Left Stick Up]`); every path it can
name is held to the asset list and every control the InputMap binds is held to a slot in it (`test_input_glyphs`).
`LastInputDevice` follows the hand (a key press, a pad button, a stick pushed past drift) and an `ActionPrompt` shows the matching
glyph set, in the language in use. Only the InputPoller reads the `Input` singleton; the device tracker listens to events.

## Persistence

`SaveService` (autoload, `shell/save/save_service.gd`; it replaced `WorldState` in M3b step 1) is the one
owner of everything written about a playthrough (`docs/game-base-plan.md` 9.3, D-16).

- **The run in memory**: `SaveService.state`, a `SaveData`. The bridge writes the facts it learns from events
  into it (a cleared room, a taken persistent pickup, an opened gate, an unlock, a read Book page, the
  checkpoint) and reads it back at every room boot. It survives a rebuild of the room because the node is an
  autoload. The ECS world's flags are loaded into every booted world and copied back into the run when a trip
  begins, when the hero falls and through the service's `saving` signal (just before a write).
- **Where the pawn stands, and the checkpoint, are two facts** (`SaveService.note_room()`, `SaveBridge`): the
  ROOM and the ENTRY it came in by (`state.room_id`, `state.room_entry_id`, `[meta] room` and `room_entry`) move
  at every room boot and are what a death and a Continue return to; the CHECKPOINT (`checkpoint_zone_id`,
  `checkpoint_entry_id`, `[checkpoint]`) is the latest hub or boss-room door the pawn came through and only
  `checkpoint_set` moves it. Both are in memory until the next success event writes them. See "Rooms,
  checkpoints and deaths".
- **The file**: one slot behind a slot id (`SINGLE_SLOT`), a `ConfigFile` at `<root>/saves/slot_<n>.cfg`
  (root `user://`; `configure(root)` for tests). Sections: `[meta]` (version 3, play time, room, room entry,
  timestamp), `[checkpoint]` (zone, entry), `[world]` (cleared rooms, defeated bosses, taken pickups, opened gates, read
  Book pages, rescues, Rule Pages, shards), `[player]` (the `PlayerSnapshot` without current Courage: health
  never saves) and `[flags]` (the `WorldFlags`). Written by write-temp, verify, keep the old file as `.bak`,
  rename (`SaveFile`); the file ends with an integrity footer (a ConfigFile comment) so a damaged file is
  recognised before the parser prints an engine error on it.
- **Loading** (`read_slot`) never wipes and never throws: the file, else the save an interrupted write left as
  `.tmp` (see below), else its `.bak`, else (first slot) the v2 `world_state.cfg`, else a clean new game, each
  step logged and a notice key set for the title (M4). A write has three steps (build and verify `.tmp`, the old
  file becomes `.bak`, `.tmp` becomes the file); a crash between the last two leaves no file, the old save as
  `.bak` and the NEW save, complete, as `.tmp`. The loader takes that `.tmp` when it is readable and not older
  than the `.bak` (a `.tmp` is always written after the file that became the `.bak`, so equal times, which the
  clock's whole seconds give two quick saves, count as newer) and `load_slot` finishes the rename, so the
  player does not lose the progress the interrupted save was writing and no notice is shown. A `.tmp` that is
  damaged, older than the `.bak`, or beside a readable file is not used (and a `.tmp` from a newer game is
  protected like the file and the `.bak`). An older
  format is migrated by `SaveMigration` (v2 to v3 today; the v2 file is kept as `world_state.cfg.migrated`
  after the first v3 save); a format too old to migrate is reported obsolete and left on disk; a save from a
  newer game is never read as damaged and never overwritten (`new_game` renames it to `.newer_game`).
  Nothing loads by itself: `GameFlow` loads on Continue (`load_slot`) and begins on New Game (`start_new_run`);
  a game scene started alone calls `ensure_session()`, which continues the active slot when no run has begun.
- **Who may save**: one file, `shell/bridges/save_bridge.gd`, calls `request_save(reason)` with one of
  `AUTOSAVE_REASONS`, the success events of R17 (room cleared, shortcut opened, persistent pickup, boss defeated, rescue, checkpoint reached, a beat
  flagged `save_after`, an unlock, a Book page). A death, a hit, a quit, a plain trip between rooms and a floor
  weapon an enemy picked up are not: they write nothing.
  `tests/save/test_request_save_callers.gd` lists the callers; `tests/architecture/test_save_written_only_by_save_service.gd`
  holds that nothing else writes a save file.
- **The profile** (`<root>/profile.cfg`, same writer): what outlives a slot, today the `completed` mark, which
  a New Game keeps (`GameFlow.reach_ending()` writes it).
- **New Game** (`start_new_run`) is the player's command and not a success event (R17): it begins a clean run and
  writes it over the slot's file at once, so a relaunch cannot bring the old run back; the file it replaces is kept
  as the `.bak` (a damaged one as `.corrupt`, a newer game's as `.newer_game`) and no `autosaved` tick shows. The
  `autosaved` signal is what AppRoot's tick listens to.

Courage is carried across a zone travel (the `PlayerSnapshot` of `ZoneTravelBridge.carried_player_snapshot`) but
is never saved: every launch starts the room at full Courage, and a checkpoint refills it.

**Where the file is.** In Godot's user data folder for this project, `saves/slot_0.cfg` (and `slot_0.cfg.bak`, the
save before it): on macOS `~/Library/Application Support/Godot/app_userdata/The Unbound Pawn/`, which the editor
opens with Project -> Open User Data Folder. Delete both for a clean start; `profile.cfg` beside them is the
profile (the `completed` mark) and survives a New Game. `docs/OWNER_GUIDE.md` has the same in Vietnamese.

## Rooms, checkpoints and deaths

What the rules of D-16 and D-17 are made of (M3b step 3). The simulation judges, the shell answers.

| Thing | Where it lives | Rule |
|---|---|---|
| The room as an entity | `EcsBoot._spawn_room_entity`, only with `EcsBootOptions.with_room_rules` (the shell sets it; the world dump and the actor stage do not, so they hold only what spawns) | one entity per played room, made last, carrying `RoomObjectiveState` and `RoomCheckpoint` |
| Cleared (D-17) | `ObjectiveSystem` says `room_cleared`; `SaveBridge` writes the zone into `cleared_room_ids` and saves | a cleared room's enemies are not spawned on any later boot (a return, a death in it, a relaunch) and their parked puppets are removed; its exits that need the room cleared are open |
| A room that is left uncleared | nothing: the room is rebuilt from its scene | all its enemies come back at full health |
| Checkpoint (D-16) | `RoomEncounter.checkpoint_on_entry` (data, on the hub and the boss room); `CheckpointSystem` on the first tick after the pawn came through a door | refills Courage through the heal queue, says `checkpoint_set`; `SaveBridge` records it (`checkpoint_zone_id`, `checkpoint_entry_id`) and saves `checkpoint_reached`. So the checkpoint is where Courage refills and what the pause menu will name (M4); nothing returns the pawn to it. A launch, a respawn and a plain trip are not checkpoints |
| Death (D-16, the reading of plan 5.2) | `ObjectiveSystem` marks the room failed, `CheckpointSystem` says `respawn_requested`, `RoomOutcomeBridge` shows the defeat and asks `GameFlow`, `GameRoot.respawn()` rebuilds | the pawn is respawned on the entry of the room it fell in (`RoomCheckpoint.entry_id`, the marker it came into that room by; read back from the run's `room_zone_id()` and `room_entry_id()`) with full Courage; the room starts over whole (a boss room in its first phase until M8b); never at the checkpoint, nothing farther back; nothing saved |
| Continue (D-16) | `SaveBridge.room_zone_id()` / `room_entry_id()` read the run's `room_id` and `room_entry_id` (`[meta] room`, `room_entry`), which `GameRoot._ready()` boots | the room and entry of the LAST SAVE, not the checkpoint record: saves are written only at success events, so right after a checkpoint that is the checkpoint's entry and after a room clear it is that room |
| Persists across a death | the run (`SaveData`) | unlocks, flags (the run takes the world's when the hero falls), cleared rooms, defeated bosses, opened gates, rescues, Rule Pages, shards, taken persistent pickups, the checkpoint |
| Room-local, resets with the room | the room's scene | floor weapons (a `PickupSpawnPoint` that is not `persistent`), what an enemy holds, every timer, telegraph and cell effect |
| Believe | `CheckpointSystem._refill_believe` | a named seam that refills nothing until M10 adds the component |

## The world graph and the room builder

What the world is made of and how a room gets made (M5 step 1; plan 7.1, 7.5). The scenes stay the truth about a room's
doors, entries and enemies; `content/world/world.tres` is the truth about how rooms join and where each sits on the map.

| Thing | Where it lives | Rule |
|---|---|---|
| The world as data | `content/world/world.tres` (`WorldGraph`, `schema/world/`) | `rooms` (`WorldRoom`: id, scene, `map_slot` on the 8 x 10 slot grid: the slot has no other home), `edges` (`WorldEdge`: the door `from_room/door` leads to `to_room/to_entry`, `one_way`, an optional `lock_id`), `locks` (`WorldLock`: `room_clear`, `flag`, `unlock` or `counter_at_least`, and a `message_key`), `regions` (`WorldRegion`: the slots a district may use). `start_room_id` is T1. The runtime's questions stay `has_zone()` and `get_zone_scene()`. |
| Flag ids | `schema/world/flag_id.gd` (`FlagId`) | one spelling for `boss.knight_captain`-style ids, used by a flag lock and by a `StateVariantMarker`, so a typo is caught where it is written |
| The 72x40 kingdom | `tests/fixtures/the_kingdom.tscn` | NOT in the graph (D-02). Tests load it by path (`TestPaths.shipped_rooms_and_kingdom()` for the suites that walk every board); no door leads into it |
| Checks that need both the graph and the scenes | `shell/content/world_check.gd` (`WorldCheck`), fed by `RoomScan` (`shell/content/room_scan.gd`: one read of a scene) | `graph`, `folders`, `scenes`, `entries`, `exits_resolve`, `edges_match_doors`, `return_doors` (every way in has a way back unless the edge is `one_way`), `no_orphan_rooms`, `locks` (every lock has a message key with an English row; a door that waits for a clear is held by a `room_clear` lock and a door that waits for a flag by a `flag` lock on the same flag and the same line), `progression` (the whole world walked in the order the bosses fall: see below), `map`, `room_meta`. One implementation for `ContentDb.validate_cross_refs()`, `tests/content/test_world_graph.gd` (which also breaks a copy of the graph on purpose to prove each check can fail) and `tools/print_world_map.gd` |
| Room meta | `RoomEncounter` (`act`, `district`, `layout_archetype`, `recipe`, `content_status`, `time_of_night`, `checkpoint_on_entry`, `board_size`, and since step 3 the encounter meta `objective_kind`, `threat_budget`, `threat_shapes`, `intro`, `intensity`) | every field has a doc and a configuration warning; `configuration_problems()` is the same list for the editor, the tests and the tools |
| The map for QA | `tools/print_world_map.gd` (the drawing is `tools/world_map_printer.gd`) | an ASCII map of every slot, room, door and lock, ending in a line of what `WorldCheck` finds wrong |
| The room builder | `tools/build_room.gd` (the steps are `tools/room_builder.gd`, `room_layout.gd`, `room_scene_writer.gd`, `built_rooms_manifest.gd`) | an ASCII layout in `tools/layouts/<room_id>.txt` becomes `content/rooms/<id>/room.tscn`. `--legend` prints the format (it is the header of `room_layout.gd`), `--check` validates every layout, `--layout=` and `--out=` build a scratch copy |
| The greybox tile kit | `content/tilesets/greybox/` | one flat tile for every cell kind (`CellKinds`): a room the builder makes is painted from these INDIVIDUAL tiles, never from a picture of a room (owner decision 2026-10-12) |

How the builder keeps its promises:

- **Text, with uids.** The scene is written as `.tscn` text (the header uid is a hash of the room id, so a rebuild keeps it, and every `ext_resource` has its
  `uid=`), then `tools/stamp_uids.gd` runs. The tiles are the one thing that is not text, and nobody hand-edits that blob: they are painted by
  `tools/cell_kind_painter.gd`, which states the kind of every cell next to the tile chosen for it and refuses a tile that does not read as that kind.
- **It never overwrites a scene it cannot prove is its own.** A scene is the truth once it exists (the owner may have edited it in the editor), so an existing
  `room.tscn` is refused. `--force` rebuilds only a scene that has a row in `tools/layouts/built_rooms.json` AND whose sha256 still equals the recorded one,
  that is, one the tool built and nobody touched. A hand-made scene (all six of Stage 1) has no row, so not even `--force` reaches it.
- **It checks what it wrote.** Before keeping a build, the builder boots the scene it wrote and compares the grid, the doors, the entries and the enemies with the
  layout; a build that fails any step leaves the target as it was.
- **The proof.** `tests/tools/test_build_room.gd` draws the hand-made Stage 1 room `t4_broken_rule_yard` as a layout (`tests/fixtures/layouts/`, not
  `tools/layouts/`, which holds only rooms that ship), builds it into a scratch folder and requires the booted picture (bounds, origin, every cell's kind, doors,
  entries, enemies, the pickup, the meta) to equal the hand-made room's.
- **The words.** A layout carries the English of its room's name, arrival line and any locked-door or unlock line; the builder appends each row to
  `content/story/text/en/rooms.po` with its `#.` comment, once, and the scene holds only the keys.

**The 34 rooms, the bosses, the hub's locks and the ending (M5 step 2).** Every room of plan 7.4 exists: 28 stubs (the 27 new rooms and `tb1`) made by
`tools/build_room.gd` from `tools/layouts/`, beside the six hand-made Stage 1 rooms. A stub has the plan's id, size (16x9, the five boss arenas and `ub2`
18x9), archetype, role, act, district and time of night, `content_status` STUB, at least one piece of its family where the plan gives it combat, and doors
that are open unless the plan gates them behind a clear (the boss rooms' way on, `ub2`). **No stub needs a verb that does not exist**: no layout uses a
gap on the walk or a `traversal` crossing; where the plan wants a skill (Rule Step, Chalk Path, Eraser Guard) the floor is whole and the need is a
promise in the world file (below). The Knight of `tb1` and the Bishop of `bs1` stand in a corner pocket (the cells they could move or strike to are
wall): a preview the pawn can still reach. `dev_sandbox` is not here: it is not a shipping room (the plan counts 34 plus the sandbox) and M6 builds it.

| Thing | Where it lives | Rule |
|---|---|---|
| A boss | `EnemyDefinition.defeat_flag` (`boss.<its own id>`, held by `validate()`) | a piece is a boss because its definition names the flag. `BossDefeatSystem` (`ecs/systems/progress/`, after the phases M8b adds and before `CheckpointSystem`) sets the flag in the world's flags the first tick the piece is down and says `boss_defeated` once (the flag already being set is the "once"); a hero who fell in the same tick wins, so the flag is never set over a boss who stands again. `SaveBridge` answers with `defeated_boss_ids` and a `boss_defeated` autosave; the flag rides the world's flags into the run like any other. The six: `black_pawn_captain` and the stand-ins `knight_captain`, `bishop_oracle`, `rook_warden`, `queen_of_tricks`, `black_king` (data only, one cell, Courage 8 to 12; footprints and phases are M8b) |
| A door that waits for a flag | `ZoneExitMarker.requires_flag` + `locked_message`; a `flag` `WorldLock` on its edge | `EcsBoot` bakes `requires_flag` into the door's dictionary only when it is set (so every other door and every Stage 1 baseline is byte-identical); `MovementSystem` says `zone_exit_locked` with the door's line until `world.flags` holds the flag. The hub's five district doors wait for the boss before each (D-21) |
| A door that ends the run | `ZoneExitMarker.ends_run` (a layout's `ending_exit`) | leads nowhere (no target, no edge); `MovementSystem` says `ending_reached` instead of travelling. Only the Desk (`e1_morning_desk`) has one, at the far end of the board |
| A lock that is a promise | `WorldLock.arrives_in` (`M7c`), `WorldEdge.skill_lock_id` | the runtime holds a door for `room_clear` and `flag` locks (`WorldEdge.lock_id`); an `unlock` or `counter_at_least` lock names the milestone that will hold it and until then holds nothing, so a door can name the verb it will also need (`needs_rule_step`, `needs_chalk_path`, `needs_eraser_guard`, eleven doors) and stays open. `WorldCheck` refuses a promise with no date and a date on a lock that is held |
| The route | `WorldCheck.walk_the_route` and the `progression` check | walks the graph from T1 with the flags unset: a door passes when it has no lock, a clear lock in a room that holds something to clear, or a flag lock whose flag is set; a boss's flag is set when its room can be cleared (it holds a piece and has a door that waits for the clear); a skill lock holds nothing. Reports a flag nobody sets, a clear door in a room with nothing to clear, a room cut off by a lock, and a world with no door that ends the run. `tools/print_world_map.gd` prints the walk (the ROUTE section) |
| The ending | `Ending` and `EndingCard` (`schema/story/`), `content/story/endings/ending.tres`, `ContentDb.ending()`, `shell/ending/ending_screen.tscn`, `shell/bridges/ending_bridge.gd` | `ending_reached` -> `EndingBridge` (once; refused during a zone trip or a room's end) turns the hero's control off and asks `GameFlow.reach_ending()` (which writes the `completed` mark) -> `AppRoot` shows the cards in place of the room -> `finished` -> `GameFlow.finish_ending()` -> the credits -> the title with the empty square. The cards are `END_` rows of `story.po`; the playable Desk, the tokens and the ten-second hold are M13 |

The world file was written once from the scenes by a throwaway script (the scenes are the truth about doors; the file adds the slots, the one-way
shortcuts, the skill locks and the regions); it is plain data and is edited by hand from here. The rooms' counts, ids and families are held by
`tests/content/test_plan_rooms.gd` against the plan's table (`tests/fixtures/plan_room_table.gd`), `tests/content/test_room_status.gd` counts the statuses (and
`tools/list_placeholders.gd` prints them), and `tests/bridge/test_boss_flow.gd` and `tests/shell/test_ending_flow.gd` drive the flag doors and the ending through the real scene.

The two data-only marker schemas of M5 (`TraversalGapMarker`, `StateVariantMarker`) are described with the markers above; the verbs that cross a traversal gap
arrive with M7 and M10, and a state variant is baked into a flag-driven visibility component by M6.

### Rooms are content: the encounter meta, the lints and the route bot (M5 step 3)

A room is content (`content/rooms/<id>/room.tscn`, the folder name is the id), the world is content (`content/world/world.tres`), and what a room is MEANT to be is data on its
root, so the rules about rooms can be checked before the room is good. Three things were added, none of which the game runs:

| Thing | Where it lives | Rule |
|---|---|---|
| What a piece weighs | `EnemyDefinition.threat_points` (every `content/enemies/<id>/enemy.tres`) | recruit 1, armed 2, backstep 2, charging 2, knight 3, bishop 3, rook 4 (plan 5.3); a boss's is its phase-1 budget (6, 7, 7, 8, 8, 9). `validate()` refuses 0, so an enemy is rated before a room holds it; `/new-enemy` says so |
| What a room is meant to be | `RoomEncounter`: `objective_kind` (clear, reach, survive, waves, none: inert until M9), `threat_budget` (points live at once; the biggest wave in a gauntlet; a boss's phase-1 budget), `threat_shapes` (shapes live at once, R28), `intro`, `intensity` (0-10, R32) | the numbers of plan 7.4 as Inspector fields under an Encounter meta group. The layout format has the five keys (`objective`, `threat`, `shapes`, `intro`, `intensity`), so a room built by `tools/build_room.gd` carries them; the six Stage 1 scenes have them written by hand. `RoomEncounter.threat_problems()` is the ONE written form of R4 (a Teach room carries 3 or less), R18 (Test and Twist 3 to 6, per wave in a gauntlet, T3's `intro` exempt from the floor, the room before a boss 6 or less) and R28 (shapes by act 2/2/2/2/3/4, bosses 2/3/3/3/4/4): the Inspector's warnings, the layout reader and the lints all call it |
| The lints | `tests/support/plan_lints.gd` (the rules, as functions over a table), `tests/fixtures/plan_encounter_table.gd` (the plan's 7.4 table as data: live pieces, fenced previews, objective, intensity, rewards, minutes; with `plan_room_table.gd` it is the fixture the lints run on) | seven suites, each over the table AND over the shipped rooms: `test_preview_before_lethal` (R27: every family is introduced fenced, or by the `intro` room, before its first live piece), `test_threat_budget` (R18 and R28: sums, shapes, Teach, Test and Twist, waves, the room before a boss), `test_room_data_audit` (R4's Teach ladder, one new geometry at a time, every room answers, why adjacent, each district's format-breaker, the arc of R32, and the encounter meta of all 34 scenes equal to the plan's rows), `test_enemy_placement` (5.3's Placed in column against 7.4 and against the scenes), `test_layout_archetypes` (no two rooms in a row of the critical path share one), `test_district_loops` (every district stands on a loop or a one-way shortcut of the doors; the Under-Bed and the Desk are exemptions that fail when stale), `test_reward_cadence` (R37: no more than six minutes of critical path between two persistent rewards) |
| The route bot | `tests/playthrough/route_bot.gd`, run by `tests/playthrough/test_full_route.gd` | boots `AppRoot`, presses New Game, walks the 35 steps of the critical path by key presses (the sword for ordinary pieces, a damage event for a boss: the plan allows it until M8b), ends the run at the Desk and stops on the title, in about 20 s of real time (the plan's budget is 90 s; the runner gives the suite 120 s, `SUITE_TIMEOUT_OVERRIDES`). It drives the simulation by hand, so its measurements are the game's own seconds and the same on every run: `docs/route_times.md` is rewritten by the test, only when it changed |

How the lints stay honest:

- **Each can fail, shown in the suite.** A suite copies the table (`PlanEncounterTable.copy_of_rows()`, `PlanLints.copy_of_graph()`), breaks one row on purpose (a second Knight, a missing fenced preview, a
  room with no loop, a boss that gives nothing) and requires the sentence, then judges the real data clean again. A hand edit of a real `.tres` or scene turns the matching suite red too (tried, then undone).
- **A rule a stub cannot be held to is a REPORT line, and the line says when it becomes enforcing.** The scenes park live what the plan shows fenced (tb1, bs1, bt1), a gauntlet's waves at once (ub2), a guard beside
  every boss and no hazard, so the parked pieces are weighed against the designed budget in report-only mode (22 of 34 rooms match today); the fenced instance of a family (M8a), near groups (M8a), boss shapes (M8b), rewards
  as pickups and beats (M6 on) and ub2's waves (M13) are the other REPORT lines. Everything else is enforced, in the table and on the 34 scenes.
- **The table is the plan's and the lints found two things in it.** R37 fails on the plan's own Reward column at the Queen's room (6.5 minutes) and the Black King's (9) unless the story beats the plan lists INSIDE those fights
  (S20, the Queen's address; S24, the three memory alcoves) count, which they do (the fixture lists them as `mid_rewards`; `findings.md` asks the plan's table to say so); and the Under-Bed has no loop or shortcut because its
  boss's door ends the run, so it is written down as an exemption. Plan 7.4's ub3 (`4/2`) is a Recruit and three rewrite pulses of 1 point each.
- **Where the numbers live.** Threat points on the definition, the caps on `RoomEncounter`, the plan's columns in the fixture: a tuned value in the content is judged against the plan's table (M14 tunes them and edits both).

`tests/playthrough/test_full_route.gd` needs two things of the support code: `Support.walk_to_cell` goes round a door cell when the grid's shortest path would cross one (tb2's entry sits in a one-cell lane beside its
door), and every other room it walks is the ordinary stub, so a stub that cannot be walked, cleared or left fails the route by name (`test_room_doors_reachable` and `test_room_markers_on_floor` hold the same 34 rooms
floor by floor and now say which room and how many markers they looked at).

## Known deviations from the rules (honest list)

These exist today and are scheduled to be fixed by `docs/game-base-plan.md` §14, not by
ad-hoc edits:

- Nothing in `presentation/` reads a component any more (the HUD bridge and the board read
  `world.hud_snapshot`), but the shell still WRITES a few: `PlayerTag.control_enabled` (`GameRoot.set_player_control`,
  called by the Book, a trip and a won room), `PlayerCombat.sword_unlocked` (`SaveBridge.apply_unlocks`) and
  `VIEW_REF` (`DespawnBridge`). The channel that replaces the writes (`world.commands`) exists since M3a
  step 1 but nothing pushes on it yet; the hero's Courage is no longer one of them (the zone swap carries a
  `PlayerSnapshot`). (The skill slot used to be redrawn on `skill_cooldown` events and said "find sword" after the
  sword was found; the M4 widgets draw the snapshot every frame and ended that.)
- (Removed in M4 step 2: the shell keys `F3`, `F11` and `B` are `InputMap` actions now, `debug_view_toggle`,
  `fullscreen_toggle` and `rule_book_toggle`, and `restart_room` is gone: restarting is the pause menu's command.)
- `ViewSyncSystem` blinks the invulnerability tint from the wall clock.
- Nothing returns the pawn to the checkpoint. D-16 says both "return to the latest checkpoint" and "a death
  resets only the current uncleared room"; the least punishing reading is built (a death puts the pawn back on
  the entry of the room it fell in, and a Continue on the room and entry of the last save, plan 5.2), so the
  checkpoint is recorded, is where Courage refills and is what the pause menu's Quit question names. `defeated_boss_ids` is saved and loaded but nothing writes it until M8b, and a
  boss's phases (the "highest checkpointed phase" of D-43) are M8b's: a boss room starts over whole.
- `Tuning.extra_courage` is set by the Extra Courage assist (a `tuning_set` command) but not read at the checkpoint
  refill, and the other three assists reach `world.tuning` with no system reading them yet (M7b, M8a, M8c are named on
  each field); the refill names Believe in its event only once M10 adds the component.
- The HUD's rank badge, Believe slot and boss bar are inert: the Rank label (`HudSnapshot.rank_label`) stays 0 until M7c fills it, and
  the other two draw nothing before M10 and M8b. Skill slots 2 to 4 are declared in the `InputMap` and absent from the HUD until M7a gives
  the snapshot a list of skills.
- The 72x40 kingdom (`tests/fixtures/the_kingdom.tscn`) left the shipped world graph at M5 step 1 (plan D-02):
  it is a fixture the tests load by path (`TestPaths.shipped_rooms_and_kingdom()` for the suites that walk every
  board), no door of the game leads into it, and `test_content_references.gd` no longer has an exception for it.
  `first_encounter` (`tests/fixtures/first_encounter.tscn`) is a standalone room only the tests load.
- The doors of H1 are not locked yet. `WorldLock` has the data (room clear, flag, unlock, counter, each with its
  message key) and the three Stage 1 clear-locks use it, but a FLAG lock is enforced by nothing: wiring the hub's doors
  to `boss.<id>` flags is M5 step 2 (it needs the shell to hand the room's locks to `EcsBoot`, and `MovementSystem` to
  read them), and the skill locks arrive in M7c.

## Reading order

1. `ecs/core/ecs_world.gd`, `ecs/components/ecs_components.gd`, `ecs/core/ecs_system.gd` — the whole ECS in ~400 lines,
   then `ecs/schedule/schedule.gd` (the order), `ecs/events/events.gd` and `ecs/events/commands.gd` (the two channels).
2. `ecs/core/ecs_grid.gd` (with `ecs/core/cell_kinds.gd`) — the board, the reserve -> commit protocol, the cell kinds, leaps, rays and the cached pathfinder.
3. `ecs/systems/input/player_input_system.gd` -> `ecs/systems/move/movement_system.gd` — one full step.
4. `ecs/systems/act/combat_system.gd` -> `ecs/systems/resolve/health_system.gd` — one full attack.
5. Data schemas: `schema/entity/*`, `schema/attacks/*`, `schema/world/*`, `schema/feel/*`.
6. `ecs/systems/decide/enemy_ai_system.gd` — the big one (381 lines).
7. `authoring/ecs_boot.gd`, `ecs_actor_factory.gd`, `presentation/views/actor_view.gd`, `authoring/entity_components/*`.
8. `ecs/systems/view/view_sync_system.gd`, then `shell/game_root.gd`, `presentation/bridges/event_router.gd` and
   the bridges (start with `hud_bridge.gd`, then `shell/bridges/zone_travel_bridge.gd`) last.

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
| `tests/architecture/` | the guards: `test_dependency_edges`, `test_content_references`, `test_content_has_no_gd`, `test_sidecars_tracked`, `test_no_path_only_ext_resource`, `test_no_old_res_paths`, `test_fixtures_present`, `test_tools_keep_uids`, `test_all_scripts_load`, `test_dump_baselines`, `test_world_dumper_entry_cell`, `test_schedule_complete`, `test_events_declared`, `test_input_only_in_poller`, `test_save_written_only_by_save_service`, `test_suites_isolate_the_save`, `test_game_root_is_thin`, `test_no_scene_reload` |
| `tests/ecs/` | the runtime seams of M3a and the two systems of M3b: `test_objective_system`, `test_checkpoint_system`, `test_schedule_order`, `test_world_fields`, `test_frozen_world`, `test_commands_channel`, `test_view_commands`, `test_emit_damage`, `test_heal_queue`, `test_boot_options`, `test_input_snapshot`, `test_hud_snapshot`, `test_player_snapshot_roundtrip`, `test_room_origin`, `test_grid_cell_kinds`, `test_leap_occupancy`, `test_ray_stops_at_blockers`, `test_path_cache`, `test_attack_setup_search` |
| `tests/bridge/` | the in-game scene and its bridges: the characterization suites (travel, death and respawn, persistence, health carry, the Book, the world flags), `test_game_flow`, `test_event_router`, one suite per bridge (`test_board_bridge`, `test_camera_bridge`, `test_audio_bridge`, `test_message_bridge`, `test_hud_bridge`, `test_bridge_despawn`, `test_bridge_room_outcome`), `test_shell_keys`, and the rules of M3b step 3 through the real scene: `test_checkpoint_rules`, `test_cleared_rooms`, `test_player_carry_zone_swaps`; `test_bridge_backtracking` walks the pawn home from H1 to T1 on foot, by key presses, through every west door, and `test_bridge_route_on_foot` walks it forward from a clean T1 to the hub (the sword in T2, every piece of T3, T4 and B1 brought down with the sword, each east door the clear opened); `test_owner_guide_steps` does the "things to try" of `docs/OWNER_GUIDE.md` section 7 in the rooms as they are, in the guide's order from a clean save (a fall, Restart Room from the pause menu, a cleared room, a checkpoint, a floor weapon, a relaunch); a suite that follows a player brings a pawn down with the sword by the real input path (`Support.kill_with_sword`: walk beside it, face it, press attack), never with a damage request, which needs no cell and let a pawn on a wall go unnoticed; `test_kill_with_sword` proves that helper can say no; `test_held_key_through_a_door` holds a walking key down through a door and through a respawn and shows the pawn stays where it arrived (`InputPoller.require_fresh_press`, called by `GameRoot.boot_zone`); `bridge_support.gd` is their shared fixture (it also walks: `tap_direction`, `walk_to_cell`, `walk_through_door`, and fights: `kill_with_sword`) |
| `tests/shell/` | the app around the game (M4 step 1): `test_app_flow` (boot, title, New Game into T1, pause, a rebuild behind the fade, Quit to Title, Continue, the credits, the ending), `test_ending_flow` (the ending's data, the card screen alone, and the whole way from the Desk's last door through the cards and the credits to the title with the mark), `test_game_flow_states` (the state machine's table), `test_new_game_resets_slot`, `test_continue_loads_checkpoint`, `test_title_summary`, `test_title_screen`, `test_credits_screen`, `test_credits_licenses_current`, `test_transition_layer`, `test_autosave_indicator`, `test_confirm_panel`, `test_app_root_is_main_scene`; `shell_support.gd` boots AppRoot for them |
| `tests/save/` | the save: `test_save_roundtrip`, `test_save_migration_v2` (with the real v2 file in `tests/fixtures/saves/`), `test_corrupt_save_falls_back`, `test_request_save_callers` (R17), `test_profile_survives_new_game` |
| `tests/input/` | the controls (M4 steps 2 and 3): `test_input_actions_have_pad_events`, `test_input_poller_rules` (dominant axis, hold-or-toggle, a fresh press for a new room), `test_input_glyphs` (every path is the asset list's, every bound control has a slot, the words stand in, the device is followed), `test_controls_panel_from_inputmap` |
| `tests/settings/` | the settings (M4 step 3): `test_settings_roundtrip` (the table, the profile, garbage and missing keys with a logged reason), one `test_setting_*` suite per setting that looks at the real target (volumes, fullscreen, language, shake scale, reduce flash, high-contrast danger, high-contrast menus, assists, hold-or-toggle), `test_every_setting_has_a_target` (fails a setting no suite moves), `test_settings_screen` (built from the table, reachable from the title and the pause menu), `test_pause_assist_options`; `settings_support.gd` boots the app for them |
| `tests/text/` | the words (M4 step 3): `test_text_service`, `test_pseudo_locale`, `test_po_domains_merge`, `test_text_keys`, `test_language_switch_redraws_live`, `test_layout_pseudo_locale`, `test_font_slots`, `test_font_vietnamese_coverage` |
| `tests/presentation/` | the board overlay drawing from the snapshot, the camera framing the room and starting on a whole pixel (`test_board_draws_from_snapshot`, `test_camera_frames`, `test_camera_snap`), and the HUD (M4 step 4): `test_hud_widgets` (each widget alone, from a snapshot), `test_hud_safe_zone` (every widget in a strip and off every board), `test_debug_overlay_default` (F3 on the real scene) |
| `tests/perf/` | `test_room_tick_budget`: an 18x9 room with eight enemies ticks in 2 ms or less on average, and builds one pathfinder |
| `tests/audio/`, `tests/content/` | the bus layout; the requirements ledger and the placeholder manifest; `test_room_doors_reachable` (every room of the world graph booted for real: every entry on floor, every door floor, reachable from every entry and leading to an entry that exists); `test_room_markers_on_floor` (the same boot: every parked enemy stands on floor and is in the grid, every pickup and unlock marker is on floor and can be walked to from every entry, every gate is on floor and can be pushed); and since M5 step 1 `test_world_graph` (every exit resolves, every room has an entry, no orphan, every lock has a message key with an English row, the kingdom is not in the graph, and each `WorldCheck` check is broken on purpose to prove it can fail), `test_room_meta` (the `RoomEncounter` meta and its configuration warnings), `test_marker_schemas` (`TraversalGapMarker` and `StateVariantMarker`) and, since M5 step 2, `test_plan_rooms` (the 34 rooms against the plan's table: id, size, archetype, role, act, district, pieces, shut doors, bosses), `test_room_status` (the content ladder counted) and, since M5 step 3, the seven lints against the plan's 7.4 table (`test_preview_before_lethal`, `test_threat_budget`, `test_room_data_audit`, `test_enemy_placement`, `test_layout_archetypes`, `test_district_loops`, `test_reward_cadence`: the section above), with `test_room_doors_reachable` and `test_room_markers_on_floor` now proving they covered every room of the plan and every marker in it |
| `tests/playthrough/` | the whole game (M5 step 3): `test_full_route` (boot, title, New Game, the 35 steps of the critical path, every boss, the ending, the credits, the title; under 90 s; writes `docs/route_times.md`) and its bot `route_bot.gd` |
| `tests/tools/` | the tools that make content (M5 step 1): `test_room_layout` (the layout format: every kind of cell and object, every way a layout can be wrong), `test_build_room` (the rebuilt Stage 1 room equals the hand-made one, the refusals, the manifest, a failed build leaves nothing), `test_print_world_map` (the ASCII map, the route and its checks line) |
| `tests/support/` | `UnboundTest`, `TestPaths` (the only place a new test names a `res://` path), `reference_pathing.gd` (the pathing and the attack search as they were before M3a, the yardstick the new code is compared with), `plan_lints.gd` (the lints' rules as functions), the harness's own test |
| `tests/fixtures/`, `tests/baselines/` | the kingdom, `first_encounter`, the harness fixtures and the v2 save; the plan's tables as data (`plan_room_table.gd`, `plan_encounter_table.gd`); the six deterministic room dumps |

The canonical runner is `python3 tools/run_all_tests.py --strict`: it runs the editor import
pass first, then every suite as its own process with a 60 s timeout (120 s for the whole-route test, `SUITE_TIMEOUT_OVERRIDES`; a script error in a
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
and the grid's cell kinds, leaps, rays, cached paths and bounded attack search, and from M3b the save service
(step 1), the split of `game_root.gd` into the `EventRouter`, the bridges and `GameFlow` (step 2), and
`ObjectiveSystem`, `CheckpointSystem`, the `PlayerSnapshot` in the zone swap and the checkpoint, death and
cleared-room rules of D-16 and D-17 (step 3), and, from M4 step 3, the settings screen, the Controls panel and the glyph lookup (built on the gamepad events and the pause menu of step 2), the text pipeline (the `.po` files, `TextService`, the pseudo-language, every literal a key) and the font slot, and, from M4 step 1, `AppRoot` as the main scene with the `GameFlow`
state machine, the persistent fade, the title, the credits (data in `content/story/credits.tres`, licences generated
from `THIRD_PARTY_NOTICES.md`), the autosave tick and the corrupt-save notice. The ECS contract is kept as it was.
and, from M4 step 4, the HUD as widgets in two strips with its safe-zone test, the control hints from the `InputMap`, the F3 debug
readout and the camera's integer-pixel snap, which closes M4's Tier A, and, from M5 step 1, the room builder (`tools/build_room.gd`), the world as one graph of rooms, doors, map slots and locks
(`content/world/world.tres`, with the kingdom out of it), the room meta on `RoomEncounter`, the two data-only marker schemas and `tools/print_world_map.gd`, from M5 step 2 the 34 rooms, the bosses' flags, the hub's locks and the ending, and from M5
step 3 the encounter meta, the seven lints against the plan's table and the route bot with `docs/route_times.md`.
Still to come, in plan order: the first-run card (Tier B), story, skills, bosses
and the other five districts. The
owner-facing "how do I change X" table, with real paths for what exists today, is
`docs/OWNER_GUIDE.md`.
