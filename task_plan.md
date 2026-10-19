# The Unbound Pawn - Active Project Plan

## Active Stage 1 Tutorial Spine

The owner asked to compare the opening against commercial first stages like
*Prince of Persia: The Lost Crown* and proceed beyond a thin technical slice.

Current status:

```text
first playable Stage 1 spine implemented; structural review loop complete;
owner polish review still needed
```

Implemented route:

```text
T1_WhiteKingsFall
-> T2_FallenSwordTile
-> T3_FirstPawnClash
-> T4_BrokenRuleYard
-> B1_BlackPawnCaptain
-> H1_ChessRugHub
```

Scene files (moved to `content/rooms/<id>/room.tscn` by M1b):

- `content/rooms/t1_white_kings_fall/room.tscn`
- `content/rooms/t2_fallen_sword_tile/room.tscn`
- `content/rooms/t3_first_pawn_clash/room.tscn`
- `content/rooms/t4_broken_rule_yard/room.tscn`
- `content/rooms/b1_black_pawn_captain/room.tscn`
- `content/rooms/h1_chess_rug_hub/room.tscn`

Verification:

- Godot import passes.
- `tests/run_tests.gd` passes.
- `git diff --check` passes.

Remaining owner-review gates:

- S1.1: T1/T2 opening readability.
- S1.2: T3 first duel feel.
- S1.3: T4 rule-break escalation.
- S1.4: B1 first boss quality.
- S1.5: H1 Toybox/world-opening clarity.

Completed self-review improvements:

- Boss exit to Hub is locked until the boss room is cleared.
- T3 and T4 forward exits are locked until their tutorial fights are cleared.
- The wooden sword is now a real T2 unlock; attacks are unavailable before it.

Known limitation:

- The structure is now enforceable, but room layout, difficulty, art clarity,
  and child-narration tone still need in-editor play review.

---

## Current Planning State

The project is currently in **production planning / owner review**, not active
implementation.

The owner has set the working rule:

```text
plan -> owner approval -> implementation -> verification -> owner review -> accepted
```

No new Godot implementation should start from the current planning docs until
the owner explicitly approves the relevant batch or task.

Current active planning files:

- `docs/production-checklist.md`
- `docs/production-approval-board.md`
- `docs/production-review-dashboard.md`
- `docs/game-production-aspects-checklist.md`
- `docs/game-production-aspect-specs.md`
- `docs/review-batch-1-foundation.md`
- `docs/review-batch-2-first-playable-feel.md`
- `docs/review-batch-3-first-chain-production-rules.md`
- `docs/review-batch-4-vertical-slice-expansion.md`
- `docs/review-batch-5-full-game-expansion.md`
- `docs/production/t1-white-kings-fall-production-spec.md`
- `docs/production/act-1-opening-to-first-boss-flow-map.md`

Current batch status:

| Batch | Status | Next Action |
|---|---|---|
| Batch 1 - Foundation | approved | T1 initial build in progress |
| Batch 2 - First Playable Feel | draft | owner review / revise / approve |
| Batch 3 - First Chain Production Rules | draft | owner review / revise / approve |
| Batch 4 - Vertical Slice Expansion | draft | owner review / revise / approve |
| Batch 5 - Full Game Expansion | draft | owner review / revise / approve |

Recommended next owner-facing step:

```text
Build and verify the approved initial `T1_WhiteKingsFall` editable Godot room,
then hand it to the owner for in-editor review.
```

Recommended next Codex-only step, if the owner says "continue" but does not
approve implementation:

```text
Improve review clarity, cross-links, and acceptance checklists. Do not build.
```

---

# Historical Implementation Plan

The sections below are historical implementation context and editor-first
technical decisions. They are useful background, but they do not override the
current approval workflow above.

## Goal

Build the first playable Godot 4 vertical slice, then grow it into a short editor-first Godot game. Current direction: move away from hardcoded room scripting and toward Godot scenes, child-node components, Inspector-configured Resources, authored rooms, and AnimationPlayer/VFX/SFX assets that can be tuned in the editor.

## Phases

| Phase | Status | Deliverable |
|---|---|---|
| 1. Repository foundation | complete | Design docs, Godot project structure, import settings |
| 2. Grid runtime | complete | Grid coordinates, occupancy, movement reservations |
| 3. Player combat | complete | Buffered movement, facing, sword attack, damage target |
| 4. Prototype room | complete | Playable authored room with pixel-art placeholders and HUD |
| 5. Verification | complete | Headless launch, automated logic checks, project validation |
| 6. Commit milestone | complete | Clean Git commit and documented next milestone |
| 7. Combat revision spec | complete | Turning, weapon/skill loadout, Pencil Thrust rules |
| 8. Flexible attacks | complete | Attack profiles, one-cell sword, two-cell thrust |
| 9. Black Pawn AI | complete | Advance, diagonal telegraph, strike, recovery |
| 10. Damage and reset | complete | Invulnerability, defeat, room restart |
| 11. Milestone verification | complete | Tests, runtime capture, commit, push |
| 12. AI architecture research | complete | Pattern, utility, intent states, coordination research |
| 13. AI implementation planning | complete | Phased Godot component and test plan |
| 14. Free-movement redesign | complete | Cardinal enemy navigation and facing-aware attacks |
| 15. Enemy weapon framework | complete | Spawned equipment, pickups, replacement attacks |
| 16. Encounter coordination | complete | Shared attack token and AI pause flow |
| 17. Knight enemy | complete | Free movement and L-shaped unarmed attack |
| 18. Mixed encounter verification | complete | Tests, rendered capture, commit, push |
| 19. Enemy behavior research | complete | Archetypes, tells, groups, bosses, data-driven AI |
| 20. Enemy behavior bible | complete | Pawn through King, weapons, encounters, tests |
| 21. Detailed enemy production spec | complete | Timing, data contracts, state tables, maneuvers, recipes, telemetry |
| 22. Enemy AI implementation roadmap | complete | Six incremental milestones with file scope, tests, and acceptance gates |
| 23. Intent foundation implementation | complete | Pawn and Knight use context, scored intents, patterns, archetypes, memory, and active pursuit |
| 24. Enemy debug visualization | complete | F3 boundaries, intent paths, and live behavior labels |
| 25. AI pursuit stability | complete | A* routing, goal commitment, loop prevention, occupied-goal rejection, and crash verification |
| 26. Attack lifecycle crash fix | complete | Safe invulnerability timer plus forced headless and real-renderer attack regression tests |
| 27. Editor-first architecture plan | complete | Scene/component/Resource ownership and six-phase migration roadmap |
| 28. Typed data foundation | complete | Inspector-editable enemy, movement, decision, attack, weapon, difficulty, and visual Resources |
| 29. Base enemy scene shell | complete | `enemy_base.tscn`, six visible component scenes, and compatibility host |
| 30. Grid movement extraction | complete | Base enemy registration, legal moves, reservations, tween, and completion owned by component |
| 31. Equipment extraction | complete | Weapon state, tag validation, defaults, pickup, geometry, damage, and timing owned by component |
| 32. Health extraction | complete | `HealthComponent` owns `EnemyActor` damage, hit feedback, defeat cleanup, and editor-owned AnimationPlayer hooks |
| 33. AI workflow rules | complete | `AGENTS.md` defines editor-first rules, planning workflow, verification commands, and next-phase guidance for future AI agents |
| 34. Human editor workflow | complete | `AGENTS.md` defines AI/human ownership, editor handoff format, in-editor review checklists, and full game completion gates |
| 35. Editor-first encounter scaffolding | complete | `RoomEncounter`, enemy/pickup spawn point scenes, and `first_encounter.tscn` now own the first room's blockers, pickups, enemies, and message |
| 36. Editor-owned room objectives | complete | `RoomObjective` Resources now own room objective text, defeat text, and win-condition logic while `RoomEncounter` emits room completion |
| 37. Editor-owned main scene foundation | complete | `Main.tscn` now owns editor-visible world, director, board, player, room, and HUD scene children while `main.gd` binds to scene nodes with test fallbacks |
| 38. Scene-backed spawn templates | complete | Enemy and pickup spawn markers now instantiate editor-assigned PackedScenes, player attacks use `.tres` profiles, and board theme colors are Inspector-editable |
| 39. Editor-owned actor visuals | complete | Player, Pawn, Knight, base enemy, and weapon pickup presentation now live in scene-owned `Visual` children instead of actor/pickup `_draw()` methods |
| 40. Generic enemy scene variants | complete | `black_pawn.tscn` and `knight_enemy.tscn` now use generic `EnemyActor` roots with component children and definition-driven identity |
| 41. Editor-owned room art | complete | `first_encounter.tscn` now owns visible `RoomArt` floor, grid, boundary, set-dressing, enemy preview, and pickup preview nodes; `PrototypeBoard` is the overlay in `main.tscn` |
| 42. Room authoring markers | complete | Hero start, blockers, pickups, and enemy spawns are draggable grid-snapping marker nodes that drive runtime placement; room editing guide added |
| 43. TileMap room floor | complete | First encounter floor uses `TileMapLayer` plus `TileSet` resources instead of one Polygon2D node per board tile |
| 44. Scene/object folder cleanup | complete | `scenes/` now contains only main playable scenes, rooms, and UI; reusable editable templates live under `objects/` |
| 45. Sprite-based visual objects | complete | Hero, Pawn, Knight, and weapon pickup visuals now use real PNG sprites, `Sprite2D` children, and `AnimationPlayer` motion instead of script-drawn bodies |
| 46. Richer visual animations | complete | Added `step` walk clips, enriched hero `hurt`/`attack` and enemy `telegraph` windups, pickup breathe, locomotion wiring in `piece_visual.gd`, and `[editable path="Visual"]` on actor prefabs; all AnimationPlayer-owned |
| 47. Editor-first refactor (cleanup + de-dup) | complete | Removed dead FreeEnemy `_draw_*`; hero attack profiles load from `.tres` instead of hardcoded stats; `main.gd` HUD updates route only through the HUD scene (removed mirror vars, `_bind_hud_references`, and elif fallbacks) |
| 48. Data-driven attack patterns + legacy retirement | complete | `AttackPattern` computes cells from `cell_offsets` data; migrated pawn/knight patterns to `.tres`; deleted `PawnPattern`/`KnightPattern`/`BlackPawn`/`KnightEnemy`/`TrainingDummy`; spawns require an editor `enemy_scene`; fixed a latent debug-redraw crash on freed enemies |
| 49. Resource-driven weapon art and piece names | complete | Optional `texture` on `EnemyWeapon`/`AttackProfile` (visuals prefer it over id lookups); authored `piece_name` on `EnemyDefinition` replaces display-name string guessing |
| 50. Brain code relocation | deferred | Moving the scoring *code* from `FreeEnemy` into `EnemyBrainComponent` is behavior-risky churn with no expandability gain; deferred. The AI *data* surface was fixed instead (phase 51) |
| 51. AI editor surface (DecisionConfig) | complete | `EnemyBrainComponent` gains an optional `DecisionConfig` export (AI knobs now on the AI node); `DecisionConfig` absorbs `EnemyArchetype` (deleted) plus `preferred_distance`, the previously hardcoded weights, and data-driven `flank_bonus`/`axis_change_bonus`; the `role=="flanker"` branch is gone so new personalities are pure `.tres`. Behavior preserved (verified against AI unit tests + 1200-frame sim) |
| 52. Data-only Bishop enemy | complete | New Bishop (diagonal move, diagonal-beam attack, sniper AI) authored entirely from `.tres` + a scene wiring the generic `EnemyActor`; no new GDScript. Test proves the data-driven pipeline end to end |
| 53. Redundant component removal | complete | Deleted hollow `AttackComponent` + `EnemyDebugComponent` (methods never called; logic lives in `FreeEnemy`); slimmed `EnemyBrainComponent` to its used `decision` export. Enemies now carry 4 functional components (GridMovement, EnemyBrain, Health, Equipment). Behavior unchanged (tests + import + sim clean) |
| 54. Shared GridMarker base | complete | Extracted the grid-snap logic duplicated across the 4 room markers (`EnemySpawnPoint`, `PickupSpawnPoint`, `HeroStartMarker`, `BlockerMarker`) into a `GridMarker` base; subclasses keep only their data/preview/`_draw`. ~110 duplicated lines removed, one source for cell-snapping. Behavior unchanged (full suite + import clean) |
| 55. GridLines overlay node | complete | Collapsed `RoomArt/GridLines`' 27 hand-placed `Line2D` nodes into one `GridLinesOverlay` script node (exported dims/color, `_draw`). Same grid, far cleaner room dock. Verified via tests + real-renderer capture |
| 56. Kingdom floor re-theme | human_review | Added a kingdom tile set (marble checker + red carpet + gold trim) and a paint build tool; repainted the first room floor as a throne-room (marble checkerboard + centre carpet runner + castle-wall border, thrones, banners). Grid contrast kept for combat readability. First-pass placeholder art awaiting the owner's in-editor approval |
| 57. Mechanic audit + hardening | complete | 1800-frame runtime sweep found zero errors. Added a dodge-mechanic test (step out of a telegraphed cell → no damage; passes). Fixed a latent `GridWorld.register_actor` gap (now rejects reserved cells so a spawn can't overwrite a mid-move actor) + test. Full suite green |
| 58. Structure research + standards docs | complete | Researched Godot folder/code best practices (docs, GDQuest, abmarnie, SlayHorizon). Decision: keep the type-based layout (clean + consistent at this size; feature-based only pays off at scale). Added `docs/ARCHITECTURE.md` (folders, runtime tree, systems, reading order) and `docs/coding-standards.md` (naming, GDScript member order, typing, scene/content rules). Confirmed scripts already follow the official member order (no reorder needed) |
| 59. Feature-based restructure blueprint | ready | Wrote `docs/restructure-plan.md`: trigger conditions, target feature-based tree, current→target move mapping, safe in-editor migration procedure, risks, and verification checklist. Not scheduled — execute only if the project outgrows the type-based layout (~100+ scenes) |
| 60. Code-structure research + patterns doc | complete | Researched Godot code architecture patterns (composition, signals/decoupling, DI, state machines, event bus, factory). Audit: the codebase already matches best practice (composition, Resources-as-data, "call down/signal up", DI, config warnings, factory spawns, enum state machine). No restructure needed. Documented the patterns in use + deliberate non-choices (no event bus/ECS) + the accepted `free_enemy.gd` size tradeoff in `docs/coding-standards.md` |
| 61. Agent rules + workflow commands | complete | Added `CLAUDE.md` (Claude-Code-native session rules: read-first order, non-negotiables, environment gotchas, verify-before-commit block) and reusable `.claude/commands/` slash workflows: `/verify` (full test+import+diff), `/new-enemy` (data-only enemy recipe), `/milestone` (phase-gate loop). Future agent sessions get consistent rules + repeatable workflows |
| 62. Naming clarity pass | complete | Owner-requested rename of cryptic core names, verified safe first (no `.tscn` serialization, no string-access): `reservations→move_reservations`, `occupied_cells→actor_by_cell`, `actor_cells→cell_by_actor`, `item_cells→item_by_cell` (dict; public method names preserved), `archetype→decision_profile`, `state_time→state_time_left`, `think_time→observe_delay`; added `##` doc comments on all five GridWorld dictionaries explaining key→value and the reserve→commit protocol. All tests green |
| 63. Obsidian code vault | complete | `docs/vault/` — 11 interlinked notes (Home MOC, Grid World, Movement, Player, Data Resources, Enemy AI, Enemy Composition, Combat and Telegraph, World and Rooms, Presentation, Glossary, Script Index) explaining every script by system with `[[wikilinks]]` + code refs. Open the folder as an Obsidian vault; graph view shows how systems connect |
| 64. Node-based main cleanup | complete | Owner's `CameraRig` committed (follow, board clamp, zoom, smoothing), then behaviors moved onto their owning nodes: screen shake lives on the CameraRig (drives built-in `Camera2D.offset`; `Main.position` never moves), the damage flash is fully HUD-owned (`flash_damage()` + its own Tween, no per-frame relay), and `main.gd` holds a typed `GameHud` ref (direct calls replace `hud.call("...")` strings). `main.gd` is pure coordination now. Full suite green |
| 83. M3b Game root and save | human_review | Fifth milestone of `docs/game-base-plan.md`, in three steps (the `game_root` split and `EventRouter`; the objective and checkpoint rules with `GameFlow`; the save). **Step 1 on branch `base/m3b-1` (save v3 and world flags, plus three M3a leftovers):** `SaveService` replaces `WorldState` (one slot behind a slot id, `configure(root)`, v3 sections `[meta]` `[checkpoint]` `[world]` `[player]` `[flags]`, atomic write with `.bak` and an integrity footer so a damaged file is recognised before the parser prints an engine error, a loader that never wipes: file, `.bak`, the v2 `world_state.cfg`, a clean new game, each step logged; a newer game's save is never overwritten; the profile file); migration from a REAL v2 fixture; `request_save(reason)` accepts only the success events of R17 and `test_request_save_callers` lists the callers; world flags carried through room swaps, the file and a relaunch; guards that only the service writes a save and that no suite touches the real one. Behaviour changes (D-16 / R17): a death no longer writes the save; a save of another version is no longer wiped silently. **Step 2 on branch `base/m3b-2` (the `game_root` split and `GameFlow`):** `shell/game_root.gd` 637 to 176 lines (a lint holds it under 200 and free of event reactions); `EventRouter` plus one bridge per responsibility (`presentation/bridges/`: HUD, board, camera, sound, status line; `shell/bridges/`: save, zone trip, Book, room outcome, despawn), a bridge suite for each reaction that had none, `ZoneStage` and `ShellKeys`; `GameFlow` serves a death or the R key by rebuilding the room inside the scene, so both `reload_current_scene()` calls are gone (`test_no_scene_reload`); the bridge suites keep their assertions and changed only their call sites. **Step 3 on branch `base/m3b-3` (objectives, checkpoints, the death rules, the carry):** `ObjectiveSystem` (react stage) judges the room from its own entity (`RoomObjectiveState`, made by `EcsBoot` only when the shell asks, so the six room dumps and the actor golden are untouched) and says `room_cleared`; `CheckpointSystem` (progress stage) sets a checkpoint when the pawn comes through a door of a room whose scene says `checkpoint_on_entry` (data on the hub and the boss room; no script names a room), refills Courage through the heal queue (Believe has a named seam, M10) and answers the hero's fall with `respawn_requested`; the bridges only answer (the run's cleared rooms and checkpoint and their saves, the defeat beat, the HUD pips); a cleared room stays cleared (D-17) and a floor weapon is room-local (D-16: only a `persistent` marker is remembered); the zone swap carries a `PlayerSnapshot` instead of a bare integer. **The plan's gap, recorded in 5.2:** "back to the latest checkpoint" vs "only the current room resets" is read the least punishing way: a death (and a Continue) put the pawn on the entry of the room it is in, never farther back; the checkpoint refills and is what the pause menu will name. Behaviour changes (D-16/D-17): cleared rooms stay empty, floor weapons come back, a plain trip no longer saves, a hub or boss door refills Courage. New suites: `test_objective_system`, `test_checkpoint_system`, `test_checkpoint_rules`, `test_cleared_rooms`, `test_player_carry_zone_swaps`. 85 suites, 235 of 235 baseline labels (14 through `label_renames.txt`, unchanged). Docs: ARCHITECTURE, coding-standards, CLAUDE.md, AGENTS.md, OWNER_GUIDE (section 7, Vietnamese: where the save lives, how to start clean, what survives a death, what to try), tools/README, the plan's 5.2, 9.3 and M3b entry. Tag `m3b-done`. Awaiting the owner: die and respawn at a room's entry (B1's door is a checkpoint); clear T3 and watch it stay empty; quit and relaunch; say whether a death should go back to the checkpoint instead. Next is M4 |
| 82. M3a Runtime seams (schedule, events, commands, world fields; input, HUD and player snapshots, room origin; the grid's cell kinds, leaps, rays and cached paths; the tick budget) | human_review | Fourth milestone of `docs/game-base-plan.md`; no gameplay rule changed (movement, combat and AI timings untouched; the six room dumps are byte-identical, all 235 baseline labels still pass). Step 1 on branch `base/m3a-1`: **the tick order is data**, one file per stage in `ecs/schedule/` plus `Schedule.populate`, which `game_root` and the world dumper both call (the duplicated lists are gone; `test_schedule_order`, `test_schedule_complete`); **every event is declared once** in `ecs/events/events.gd` with its payload keys, `EcsWorld.emit_event` asserts the declaration, `test_events_declared` reads the code; **damage knows who dealt it** (`Events.emit_damage` with `source` and `tags` on every producer, carried into `damaged` and `defeated`); **every shared field of `EcsWorld` landed at once** (`frozen`, `flags`, `tuning`, `input_snapshot`, `hud_snapshot`, `commands`, `view_commands`, the heal queue); a frozen world ticks only the command and view systems (`test_frozen_world`); **`world.commands` works** (`ecs/events/commands.gd`, `CommandSystem` first in the schedule, freeze, thaw, set_flag, tuning_set, `command_rejected`; `test_commands_channel`); `ViewSyncSystem` plays `view_commands`; `EcsBoot.boot(world, EcsBootOptions)`. Step 2 on branch `base/m3a-2`: **the controls have one reader** (`shell/input/input_poller.gd` fills `world.input_snapshot` once per frame, `PlayerInputSystem` reads only it, `test_input_snapshot` drives buffer, chord and tap window by injected snapshots, `test_input_only_in_poller` fails on any other `Input.`; the old and new system left identical state over 7,472 ticks of random play); **the HUD and the board read a snapshot** (`HudSnapshot` fields, `HudSnapshotSystem` in the view stage, `PrototypeBoard` draws from it, no script under `presentation/` names `EcsComponents` or `EcsWorld`, the board's two undecided dependency edges are gone; `test_hud_snapshot`, `test_board_draws_from_snapshot`); **`PlayerSnapshot`** defines what the pawn carries between rooms and into a save (`test_player_snapshot_roundtrip`), applied by `EcsBoot` when `EcsBootOptions.player_snapshot` is set; **each room centres its own board** (`EcsBoot.shape_grid`, `EcsGrid.centred_origin`; the six rooms are 16x9 so the dumps are byte-identical; `test_room_origin`) and **the camera frames the room** (`CameraRig.limits_for_board`; `test_camera_frames`, ledger req 118). Step 3 on branch `base/m3a-3`: **a cell knows what it is made of** (`CellKinds` in `ecs/core/cell_kinds.gd`: floor, wall, gap, leapable_block, chalk, corruption, each with three rules; `EcsGrid.cell_kind_by_cell`, `set_cell_kind` as the only writer of the terrain, `blocked_cells` derived, `layout_version`, the empty `cell_effect_by_cell` store for M10; the TileSets carry a `kind` custom-data layer next to `solid`, `EcsBoot.apply_tile_kinds` reads it, `tools/cell_kind_painter.gd` is what both paint tools paint through; existing rooms keep identical walkability, `test_grid_cell_kinds`); **a leap lets go of its origin and a ray stops at what stops it** (`begin_leap`/`finish_leap`, untargetable in flight, `can_leap_over`, `ray_cells`; no skill uses them yet; `test_leap_occupancy`, `test_ray_stops_at_blockers`); **the pathfinder is built once per layout** (`get_grid_path` keeps one `AStarGrid2D` per `layout_version`) **and the attack search looks near the hero** (bounded to the attack shape's reach), with identical decisions proved against the old code kept in `tests/support/reference_pathing.gd` (`test_path_cache`, `test_attack_setup_search`, 18,000 further ticks identical between the `base/m3a-2` and `base/m3a-3` checkouts); **a room's tick has a budget** (`tests/perf/test_room_tick_budget.gd`: an 18x9 room, 8 enemies, real views, mean tick 0.15 to 0.5 ms measured against a 2 ms bound). Docs: ARCHITECTURE, coding-standards, CLAUDE.md, AGENTS.md, tools/README, OWNER_GUIDE (the `kind` row; two "available after M3a" rows now available). Tag `m3a-done`. Awaiting the owner: nothing visible changed; the only owner-facing addition is the `kind` field a tile can carry in the TileSet editor. Next is M3b |
| 81. M2 Content registry and actor collapse | human_review | Third milestone of `docs/game-base-plan.md`; no gameplay rule changed (movement, combat timings and AI untouched; the six room dumps still say the same about every entity and cell). Three steps on branches `base/m2-1` to `base/m2-3`: **`ContentDb`** (a static registry, ten kinds, an id is a folder name, `validate()` and `validate_cross_refs()`), **`PlayerDefinition`** and `content/player/player.tres` (the pawn's numbers leave `player.tscn`, a node on an instance still wins); the four 353-line actor scenes become **one `actor_view_base.tscn` plus four thin scenes** (`test_actor_collapse_golden` proves every baked field equal to the old scenes), with the body picture, anchor and per-clip speeds as `VisualDefinition` data, so a new enemy needs no scene; and the owner's decision of 2026-10-12 that **a piece is smaller than its cell** (it reverses phase 66): the size table `content/feel/piece_sizes.tres`, everything an actor draws within 14 px of the cell centre, the generated chess family drawn to the table and seeded as placeholders (26 listed), `tools/render_actor_preview.gd` writing `assets/_generated/previews/pieces_in_cells.png`, `test_pieces_inside_cell`. `/new-enemy` rewritten and walked once on a scratch copy (`test_pawn`, 5 health; 1 file for a re-skin, 3 with a picture); `docs/OWNER_GUIDE.md` rows updated and section 6 added in Vietnamese; plan section 12 amended. 35 suites, 235 of 235 baseline labels (9 through `label_renames.txt`), `stamp_uids --check` CLEAN, a fresh clone plus bootstrap green. Tag `m2-done`. Awaiting the owner: open the preview picture and say whether the pieces look right in their cells; approve or redraw the four stand-in bodies (the knight was retraced on 15 rows to fit its 20 x 24 box, an edit to an approved shape; the black pawn and the bishop are new stand-ins); rook, queen, king and boss bodies do not exist yet (rows of the table only). **Fix round after the review (branch `base/m2-fix`, tag `m2-done` moved):** a piece a room stretches (the B1 captain at 1.18x) can no longer pass the cell rule, the 32 x 32 canvas of the owner's asset list is a body shape the game accepts and places exactly (the four stand-ins are now canvases), a hit's shove stops at the margin, the preview shows overflow in magenta and adds a picture of the actors the rooms place, five unread `VisualDefinition` fields are gone, `ContentDb` reports a silently dropped reference. Left for the owner and the integrator: the bishop is shorter than the knight, the aura, arrow and pip sizes disagree between `docs/assets` and the scene. Next is M3a |
| 80. M1b Folder migration | human_review | Second milestone of `docs/game-base-plan.md`; no gameplay change. Four steps on branches `base/m1b-1` to `base/m1b-4` (64 commits, the strict runner green after every one): the uid stamp and generated output moved to `assets/_generated/`; all 51 scripts into `schema/ ecs/ authoring/ presentation/ shell/`; all content into `content/` (zero `.gd`, folder = id), the fixtures into `tests/fixtures/`, the 12 tracked sprites into their content folders; then the placeholder tools (`seed_placeholders.gd`, `list_placeholders.gd`, `content/_placeholders.json` with 25 files), the `CLAUDE.md` amendments A-1 to A-9 (approved at OG0), and the prose docs (`ARCHITECTURE`, `coding-standards`, `AGENTS`, `README`, `OWNER_GUIDE`, `tools/README`, `.claude/commands/*`). Every `move` went through `tools/move_res.py`; 26 suites, 235 of 235 baseline labels, `stamp_uids --check` CLEAN, a fresh clone plus bootstrap green. Guards enforcing: sidecars, dependency edges, content has no `.gd`, content references, no old paths, fixtures present, placeholder manifest. Tag `m1b-done`. Awaiting the owner: browse `content/`, read `docs/OWNER_GUIDE.md`, decide the five undecided dependency edges and six room references (`docs/migration-notes.md`) before `allowed_edges.txt` is frozen; next is M2 |
| 79. M1a Safety net and tooling | human_review | First milestone of `docs/game-base-plan.md`; no gameplay change, no file moved. One strict test runner (`tools/run_all_tests.py`) with a baseline-label manifest, `UnboundTest`/`TestPaths`, five `main.gd` bridge characterization suites, the UID stamper, `move_res.py`, the deterministic room dump with six baselines, report-only architecture guards, the fixed audio bus layout, a requirements ledger and its test, and rewritten docs. Green after the review fixes (20 suites, 235 baseline labels; the runner and the tools have their own `--self-test`). OG0 was answered on 2026-10-12 (recorded in `progress.md`); M1b is row 80 |
| 78. The hero wakes up | human_review | Owner ask: a wakeup animation. Zero script changes — the boot pose is graph-owned. `player.tscn` gains a 1.25s `wake` clip (SpriteRoot rotation −90° → 0 with a twitch, a shove-up overshoot and a squash/stretch settle, plus an audio track firing the new `wake_stir.wav` at 0.3s) and a `wake` state whose `Start` edge replaces `Start → idle`; existing transitions are reused, not duplicated (`T_recover` AtEnd drops it to idle, `T_to_step` lets player input cut it short, `T_travel` lets hurt/attack/defeat interrupt). `RESET` gained a rotation track so the editor restores upright. New SFX generator `wake_stir()` in `tools/generate_sfx.py`. Suite asserts the clip exists AND that the graph's Start edge points at it. Art direction is owner-owned: awaiting in-editor approval |
| 77. The map reads as a kingdom | human_review | Owner verdict on the semi-open world: "too anotony" — every carved cell wore the same wood/sand checker and every uncarved cell the same toy block. Atlas grown 6 → 19 tiles (cobble, carpet, marble, boards, rampart, tower, hedge, bookshelf, moat, banner, cottage, 2 alternate block stackings); `tools/paint_zone_tilemaps.gd` now owns 10 DISTRICTS (nearest-anchor) that skin BOTH floor and facing rock, man-made halls as rectangles vs nature as organic bowls, a curtain wall + keep ring + library ring + moat painted over rock only (so they can never break connectivity — road crossings self-form as gatehouses), scattered L-shaped cottages, and a deterministic 3-way block mix for deep rock. Same 657-cell single-component world, 25 required spawn cells validated. Art direction is owner-owned: awaiting in-editor approval |
| 76. Structured sound: buses + SfxManager | complete | Three-layer audio law in CLAUDE.md + /new-sound workflow; default_bus_layout.tres (Master <- SFX/Music/UI) with actor AudioPlayers on SFX; pooled SfxManager autoload with Inspector stream registry (pickup_chime, room_clear, defeat_jingle) played only by the main.gd bridge from drained events. Suite asserts layout + registry |
| 75. Sound telegraphs + defeat clip | complete | Four generated SFX (tools/generate_sfx.py -> assets/sfx) keyed as audio tracks inside actor clips via per-scene AudioStreamPlayer (telegraph beep, sword whoosh, hurt thud, defeat crumple); every actor gains a terminal defeat state + clip, entered once by ViewSync on the death edge; main.gd death tween replaced by a scheduled despawn. Reactions are now 100% editor-owned. Suite asserts defeat clip + audio player on all 5 scenes |
| 74. AnimationTree state graphs | complete | Animation transitions moved from code into editor-owned AnimationTree StateMachines on all 5 actor scenes (idle/step/hurt/attack + enemy telegraph; auto conditions for locomotion, travel() entries for one-shots, at_end recovery, telegraph xfade). ViewSyncSystem now publishes conditions + travel edges only, with a tree-less fallback for test views. Slide stays procedural (gameplay timing). Suite asserts the graphs |
| 73. Component nodes: editor-draggable ECS components | complete | Authoring-component pattern: EntityComponent base + HealthComponent/WeaponComponent/AIComponent nodes dragged under actor views; EcsBoot bakes them into entity components at spawn (instance spec beats definition). Nodes in the dock, tables at runtime; specs hold zero logic. Covered by room-test assertions |
| 72. Full ECS conversion (phases A-D) | complete | Owner-directed ("go for ecs"). Runtime is now entities + pure-data components + systems (`scripts/ecs/`): EcsWorld/EcsGrid core, PlayerInput/EnemyAI/Movement/Combat/Health/ViewSync systems, EcsActorFactory (.tres → components), EcsBoot (parked ActorViews → entities, solid tiles → blocks, pickups → items). main.gd = boot + event bridge; actor scenes = ActorView puppets (zero logic, asserted); node runtime layer deleted (grid_actor/grid_world/pawn_hero/free_enemy/enemy_actor/director/context + 8 components). Authoring unchanged: drag views, override definitions, paint walls, tune .tres. Suite = run_tests + 3 ECS tests + room + HUD boots, all green; render capture verified. Design doc: docs/ecs-conversion-plan.md |
| 71. Player component split | complete | Split `pawn_hero.gd` into behavior components mirroring the enemy skeleton: `PlayerInputComponent` (keys → intents, hold-repeat, buffering), `PlayerCombatComponent` (attack coroutine, cooldowns, `try_skill`), `PlayerHealthComponent` (courage, invulnerability, defeat), base `PlayerComponent` with `configure(host)` injection. State + signals + facades stay on PawnHero (HUD/enemies/tests untouched); combat/health self-create for bare-script test instances; `_get_configuration_warnings` flags missing components. Extension path: new control scheme or skill = swap/extend one node. Suite green + frame identical |
| 70. Flatten actor visuals (canonical node structure) | complete | Removed the `Visual` wrapper from player + all enemies (researched Godot convention: sprites + AnimationPlayer live directly on the actor). `player.tscn` and the 4 enemy scenes own `MotionRoot/SpriteRoot` sprites, per-piece animation libraries, and TelegraphAura/FacingArrow/HealthPips (enemies); `pawn_hero.gd`/`free_enemy.gd` drive them via typed `@onready` refs (`_update_appearance`) — the polling `PieceVisual.sync_from_*` bridge with stringly `.get()` access is gone. Deleted `piece_visual.gd` + 3 piece visual scenes (pickups keep theirs); weapon/attack sprites moved into `.tres` `texture` fields (killing the id-lookup fallback); `VisualDefinition` dropped `visual_scene`/`legacy_draw_kind`. Tests re-pointed; suite green + frame verified |
| 69. Enemies are real scene children | complete | Same rule as the hero: enemy scenes are instanced directly in the room and parked where they fight — `RoomEncounter._setup_enemies` registers each `FreeEnemy` child at its parked cell, wires signals, activates, and equips `definition.default_weapon`. Deleted `EnemySpawnPoint` (script+scene) and all Preview/EditorLabel scaffolding; the armed pawn is a `black_pawn.tscn` instance with a `pawn_armed.tres` override. WYSIWYG: the editor shows the actual combatants. Scene reload keeps restart working. Suite green + frame verified |
| 68. Paint-once walls (solid tiles) | complete | Added a `solid` custom-data layer to the kingdom TileSet (wall/throne/banner = true); `RoomEncounter._apply_solid_tiles` blocks every painted solid cell at setup — paint IS collision. Deleted the playground-era `Boundary` décor and the 4 `BlockerMarker` nodes (interior walls now painted into the regenerated tilemap; marker class kept as legacy). The stone border ring is now genuinely solid (was walkable art). Tests re-pointed at the mechanism; suite green; F3 frame shows every painted wall registered as blocked |
| 67. Redundancy cleanup (scene data + board) | complete | Killed the triple-defined blocker cells (markers stay the sole truth; removed the stale `blocked_cells` array from `first_encounter.tscn` and the board's `editor_blocked_cells` copy), deleted `PrototypeBoard`'s dead pre-TileMap floor path (`draw_base_layer`, base-layer colors, playground border, `@tool` editor preview — 309→216 lines; now a pure combat overlay), and dropped the never-read `telegraph_style` field from `AttackPattern` + its 3 `.tres` lines. Suite green, overlay frame verified |
| 66. Chess-piece proportions | superseded | **Superseded 2026-10-12 by M2 (row 81):** the owner decided a piece is smaller than its cell (`docs/owner-decisions.md`), so pieces are no longer 1.5 cells tall, `BodySprite` is no longer at (0,-8) and nothing overlaps the row above; row-based depth stays and nothing needs it. What phase 66 did when it was complete: Researched the top-down convention (1 tile wide × 1.5–2 tiles tall, feet-anchored, top-half overlaps the row above, lower rows draw on top). Pieces scaled from ~34px icons to ~48px (1.5-cell) figures with feet anchors (BodySprite at (0,−8)); facing arrow/health pips/weapon anchor raised to match; row-based depth added (`GridActor.update_depth_from_row`: `z_index = 2 + cell.y`) so lower pieces overlap upper ones. Pickups stay flat/cell-sized. Presentation-only; suite green + frame verified |
| 65. Hero is its own spawn marker | complete | Markers are for runtime-instantiated things; the hero already exists, so dragging `PawnHero` in the editor IS the spawn point — `main.gd` floors the parked position (`world_to_cell`, bounds-checked, export fallback) and `setup()` re-centers on the cell. Deleted the `HeroStart` marker (script, scene, room node, room flow); parked the hero at cell (3,7) in `main.tscn`; updated 3 tests + vault/guide docs. One-step authoring, no more double hero in the editor. Full suite green + spawn frame verified |

## Editor-First Full Game Roadmap

This roadmap is the long-range production plan for making the whole game in Godot Editor first. Scripts should provide reusable behavior, but rooms, enemies, pickups, UI, animations, VFX, SFX, and narrative beats should be authored through scenes, child nodes, Resources, and Inspector fields whenever practical.

Folder ownership:
- `scenes/` is for entry scenes, authored rooms, and UI scenes that should be opened directly in Godot Editor.
- `objects/` is for reusable object templates and prefabs: actors, components, markers, visuals, pickups, combat helpers, and world helper nodes.
- `resources/` is for Inspector-tunable data; use `.tres` files when a value should be shared, swapped, or balanced.
- `scripts/` is for reusable behavior and migration fallbacks, not authored room content.

| Phase | Status | Deliverable |
|---|---|---|
| E1. Editor foundation | in_progress | `Main.tscn`, `GameWorld.tscn`, `RoomEncounter.tscn`, `Player.tscn`, `EnemyBase.tscn`, `WeaponPickup.tscn`, and `HUD.tscn` replace direct runtime composition where possible |
| E2. Editor-first encounter system | human_review | `RoomEncounter`, `EnemySpawnPoint`, `PickupSpawnPoint`, authored blockers, room messages, win conditions, and spawn configuration are editable in Godot Inspector; awaiting in-editor room-feel approval |
| E3. Player combat core | pending | Player movement, turn mode, sword, Pencil Thrust, invulnerability, cooldown, and timing become Inspector-tunable through scene exports and attack profile Resources |
| E4. Enemy system | pending | Pawn, Knight, Bishop, Rook, Queen, and King use configurable enemy scenes and typed Resources for movement, attacks, decisions, visuals, weapons, and difficulty |
| E5. Combat feedback | pending | Telegraphs, hit flash, damage shake, pickup glow, defeat effects, and sound cues move toward reusable AnimationPlayer/VFX/SFX scenes |
| E6. Room and world structure | pending | Tutorial, first battlefield, weapon playground, Knight boss, Bishop/Rook challenge rooms, Queen arena, and King final room are connected as authored `.tscn` rooms |
| E7. Narrative layer | pending | Child imagination/fourth-wall story uses dialogue Resources, trigger zones, player-hand interventions, and AnimationPlayer cutscene beats |
| E8. Art direction pass | pending | Replace shape placeholders with Enter-the-Gungeon-readable pixel sprites, toy weapons, playground tiles, crayon UI, and childlike props |
| E9. Boss production | pending | Knight, Bishop, Rook, Queen, and King boss scenes use authored phases, arena-specific patterns, telegraphs, and Resource-driven attack timelines |
| E10. Vertical slice | pending | 10-15 minute demo with tutorial, one normal encounter, one weapon encounter, one Knight boss, win/lose/restart, story framing, UI, and sound |
| E11. Full short game | pending | Roughly 2-hour game with 5-7 room groups, 5 bosses, 6-10 weapons/skills, simple progression, final King duel, and ending |
| E12. Polish and release | pending | Save/checkpoint system, settings, controller support, audio mix, builds, store page assets, trailer capture, QA, and release packaging |

## Immediate Editor-First Next Phase

Continue **E1. Editor foundation** while E2 waits for human room-feel review. The first E1 slice moved Main, GridWorld, EncounterDirector, PrototypeBoard, PawnHero, FirstEncounter, and HUD into editor-visible scenes.

Target deliverables:
- `scenes/main.tscn`
- `objects/actors/player.tscn`
- `objects/actors/black_pawn.tscn`
- `objects/actors/knight_enemy.tscn`
- `objects/actors/enemy_base.tscn`
- `objects/world/weapon_pickup.tscn`
- `objects/visuals/pawn_hero_visual.tscn`
- `objects/visuals/black_pawn_visual.tscn`
- `objects/visuals/knight_enemy_visual.tscn`
- `objects/visuals/weapon_pickup_visual.tscn`
- `objects/world/grid_world.tscn`
- `objects/world/prototype_board.tscn`
- `objects/combat/encounter_director.tscn`
- `scenes/ui/hud.tscn`
- Next: convert the remaining combat feedback overlays into reusable VFX/AnimationPlayer scenes, then begin editor-authored tutorial room structure.

Acceptance criteria:
- `scenes/main.tscn` opens with visible child nodes for world, combat director, board, player, room, and HUD.
- `main.gd` coordinates already-authored child scenes instead of constructing the full scene tree directly.
- Direct script instantiation in tests still works through scene fallback creation.
- Enemy and pickup spawn markers instantiate editor-assigned PackedScenes for live gameplay nodes.
- Pawn and Knight gameplay templates use the generic `EnemyActor` script plus scene-owned components, not Pawn/Knight-specific root scripts.
- `EnemyActor` damage and defeat flow goes through `HealthComponent`, which owns hurt/defeat feedback animations through an editor-visible `AnimationPlayer`.
- Player attack profiles and board theme values are configurable through `.tres` Resources or Inspector exports.
- Player and enemy actors own their sprites + `AnimationPlayer` directly in their scenes; weapon pickups own an editable `Visual` scene child.
- `first_encounter.tscn` owns a visible `RoomArt/TileMap` TileMapLayer for board tiles plus separate grid lines, boundaries, and playground set dressing.
- Hero start, blocker cells, weapon pickups, and enemy spawns are draggable marker nodes with `grid_cell` fields that runtime setup reads.
- Marker preview children show enemies and pickups in editor and hide at runtime.
- Existing gameplay behavior, HUD, debug view, tests, restart flow, and editor import still pass.
- The human owner can now inspect the main scene tree in Godot Editor before deeper composition migration.

## Decisions

- Godot version: 4.6.3.
- Rendering: native 2D at 640x360 with integer scaling and nearest filtering.
- Logical tile size: 32 pixels.
- Game logic is cell-based; sprites and animation are presentation.
- Placeholder art will be intentionally styled and project-native, then replaced using the art bible.
- The first foundation milestone stopped before enemy AI and the Knight boss; Black Pawn AI was added in the following milestone.
- `Shift + direction` turns the pawn without moving.
- The slice loadout is one Wooden Sword plus Pencil Thrust on `Q`.
- Pencil Thrust reaches two cells and has longer recovery.
- Pencil Thrust uses cooldown only during the slice; resource cost waits for playtesting.
- Enemy AI will use chess patterns plus utility scoring, executed by a shared intent state machine.
- Encounter coordination will use room-level attack tokens and a threat map.
- AI reads only the hero's current or visibly reserved destination cell.
- All common enemies move one cell in four cardinal directions.
- Unarmed attacks retain chess-piece geometry relative to facing.
- Equipping a toy weapon replaces the piece's chess-shaped attack.
- Enemies may spawn armed or collect a weapon during combat.
- Each chess piece has a distinct tactical role and positioning personality.
- Bosses use authored maneuver phases rather than unrestricted common-enemy utility.
- Project direction is editor-first: content should be placed and tuned in Godot scenes/resources before adding more hardcoded gameplay content.
- The next recommended implementation phase is the editor-first encounter system, not more scripted room composition.
- Future AI sessions should read `AGENTS.md` first for editor-first workflow rules, verification expectations, and current priorities.
- AI should hand off room feel, player feel, enemy feel, art/audio taste, narrative tone, and release review tasks to the human owner inside Godot Editor when the relevant phase reaches a tuning gate.
- World shape (owner decision, 2026-07): **connected rooms**, not one big scrolling map. The world is a freely explorable set of bounded boards joined by door/exit transitions (Zelda-screen style); `GridWorld.bounds` stays per-room. Combat arenas remain tight and readable; exploration freedom comes from room connectivity (E6), not from removing bounds.
- `RoomObjective` Resources own room start/clear/defeat copy and win-condition checks; `RoomEncounter` emits `room_completed`, while `main.gd` only reacts with HUD/result flow.
- `Main.tscn` now owns editor-visible child scene instances for GridWorld, EncounterDirector, PrototypeBoard, PawnHero, FirstEncounter, and HUD; `main.gd` resolves those child nodes first and uses scene fallbacks only for tests.
- Spawn markers should prefer `PackedScene` templates (`black_pawn.tscn`, `knight_enemy.tscn`, `weapon_pickup.tscn`) and keep direct constructors only as compatibility fallbacks.
- Gameplay actors and pickups should not own production `_draw()` methods; actor presentation is Sprite2D children + an `AnimationPlayer` inside each actor scene (pickups: `weapon_pickup_visual.tscn`).
- Enemy identity in runtime UI/status should come from `EnemyDefinition` data rather than class checks. Legacy `BlackPawn` and `KnightEnemy` classes remain only as direct-test compatibility until they are deleted.
- `EnemyActor.take_damage()` delegates to `HealthComponent`; legacy `FreeEnemy.take_damage()` remains only for old direct-test compatibility.
- Room floor, grid-line, boundary, and set-dressing presentation should live in the room scene under `RoomArt`; `PrototypeBoard` should stay responsible for telegraph cells, hit flashes, and debug path overlays.
- Gameplay placement should be represented by marker nodes, not parallel art plus hidden arrays. `RoomEncounter` should read markers first and keep exported arrays only as compatibility fallbacks.
- Board floor art should use TileMapLayer and TileSet assets. Avoid adding one Polygon2D node per floor tile.
- Keep reusable object `.tscn` templates under `objects/`; keep `scenes/` limited to playable/editor entry scenes, rooms, and UI.
- Actor and pickup bodies should be real sprite/animation scene nodes. Do not reintroduce `_draw()` body rendering in `pawn_hero.gd`, `free_enemy.gd`, or `scripts/visuals/pickup_visual.gd`.
- Chess-piece sprite art (owner-approved look, 2026-08) is generated, not hand-painted: `tools/generate_chess_sprites.gd` owns the shape tables and bakes `assets/_generated/chess/`. Change a silhouette by editing a row radius and re-running; never repaint an exported PNG. Its `manifest.json` is the only source for frame size, `anchor_row` (the row that sits on the CELL CENTRE) and `block_size_in_world_pixels`.

## Errors Encountered

| Error | Attempt | Resolution |
|---|---:|---|
| `draw_ellipse` helper conflicts with Godot 4.6 native method | 1 | Renamed project helper to `_draw_pixel_ellipse` |
| Godot cannot write editor caches under sandboxed macOS home | 1 | Run verification with an isolated writable `HOME` under `/tmp` |
| Objective HUD path caused recursive deferred calls and message queue exhaustion | 1 | Store and update a direct `objective_label` reference |
| Initial push authenticated as GitHub user `fishtechainer` and was denied | 1 | Switched this repository remote to existing `github.com-work` SSH alias, authenticated as `ThachCoder2k2` |
| Pencil Thrust used an async attack return value inside `if` | 1 | Added synchronous `can_start_attack()` guard and launched the coroutine separately |
| Turn action accidentally included Ctrl due to keycode assumption | 1 | Inspected `InputEvent.as_text()`, removed Ctrl, and added a binding test |
| Cardinal move helper inferred inline directions as `Variant` | 1 | Added explicit `Vector2i` loop and destination types |
| Godot headless movie capture crashed in the dummy texture renderer | 1 | Keep headless mode for logic/runtime checks and use the real renderer for visual capture |
| Grid path helper collided with native `Node.get_path()` | 1 | Renamed the helper to `get_grid_path()` |
| GDScript could not infer the type of a new Resource loaded from script in `run_tests.gd` | 1 | Typed the instances as `Resource` and called objective methods dynamically, matching the pre-editor-import bridge style |
| `SceneTree._init` tests checked `Main._ready()` bindings too early | 1 | Kept ownership checks in the main suite and moved ready-time binding checks into the deferred HUD runtime test |
| Newly added global visual classes were not available during early headless script loading | 1 | Older gameplay scripts reference visual children dynamically through `Node` and `has_method()` until editor import registers the classes |
| Sprite generator failed to parse: `Cannot infer the type of "mane_centre" variable` | 1 | Indexing an untyped `Array` yields Variant, so `:=` cannot infer from it. Extracted an explicitly typed local (`var mane_start: int = ...`) before the float math |
