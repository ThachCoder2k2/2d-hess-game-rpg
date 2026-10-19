# Progress Log

## 2026-06-19

- Cloned `git@github.com:ThachCoder2k2/2d-hess-game-rpg.git`.
- Confirmed the repository is empty.
- Confirmed Godot 4.6.3 stable is installed.
- Created persistent implementation planning files.
- Imported the approved GDD, pixel-art bible, vertical-slice design, and concept art.
- Implemented the Godot project, grid runtime, hero controller, sword combat, training targets, prototype room, and HUD.
- First parser run found a Godot 4.6 native method-name collision; renamed the local ellipse drawing helper.
- Headless grid test suite passes 14 checks.
- Runtime check found and fixed a recursive HUD label lookup.
- Rendered a real Godot frame and found top/bottom HUD collisions.
- Moved HUD content into clear bands and replaced crossing decorations with side accents.
- Added an automated sword-targeting assertion.
- Final runtime scene launches cleanly.
- Final automated suite passes 15 checks.
- Captured and visually inspected the corrected 1280x720 frame rendered from the 640x360 canvas.
- `git diff --check` reports no whitespace errors.
- Committed the first playable foundation to `main`.
- Pushed `main` to `ThachCoder2k2/2d-hess-game-rpg` using the existing `github.com-work` SSH identity.

## Next Milestone

- Replace training targets with Black Pawn enemy AI.
- Add reusable attack telegraph cells.
- Implement damage, invulnerability, and room reset flow.
- Build the first authored Pawn Ambush room.

## Combat Revision

- Recorded approved playtest feedback.
- Locked `Shift + direction` turning.
- Locked Wooden Sword plus Pencil Thrust for the slice.
- Chose cooldown-only Pencil Thrust for initial playtesting.
- Implemented reusable attack profiles, turn-in-place, Pencil Thrust, Black Pawn AI, telegraphs, damage, invulnerability, and room reset.
- First parser pass found an async return-value misuse in the skill guard; split readiness from execution.
- Verified the full Black Pawn movement, telegraph, strike, damage, and invulnerability loop in an eight-second rendered capture.
- Found and removed an accidental Ctrl binding from the turn action.
- Final suite passes 21 checks.
- Final headless room run completes without script or runtime errors.
- Visual capture confirms readable movement, diagonal warning, strike impact, Courage loss, and invulnerability feedback.
- Researched telegraphed grid combat, handcrafted room design, utility AI, and multi-enemy coordination.
- Wrote the complete AI behavior and implementation plan in `docs/design/ai-behavior-plan.md`.
- Approved enemy freedom revision: cardinal movement, chess-shaped unarmed attacks, and weapon replacement attacks.
- Updated AI architecture for spawned and dynamically collected weapons plus Knight behavior.
- Implemented item-layer weapon pickups, enemy weapon resources, encounter attack token, shared free-enemy brain, free-moving Pawn, and Knight.
- First parser pass required explicit `Vector2i` types in cardinal move generation.
- Expanded the suite to 36 passing behavior checks.
- Completed a clean 20-second headless mixed-encounter simulation.
- Rendered and inspected free movement, pre-armed enemies, dynamic Pawn and Knight pickups, and mixed weapon visuals.
- Final verification passes 36 tests and a 20-second runtime simulation with no script errors.
- Researched enemy archetypes, telegraphing, group coordination, modular tactics, and boss phase structure.
- Wrote `docs/design/enemy-behavior-bible.md` covering Pawn, Knight, Bishop, Rook, Queen, King, weapon behavior, encounter composition, implementation order, and testing.
- Expanded the enemy bible with exact timing targets, utility evaluation, Godot data contracts, state transition tables, weapon compatibility, boss maneuver data, encounter recipes, debug telemetry, and production acceptance gates.

## 2026-06-21

- Audited the current `FreeEnemy`, Pawn, Knight, encounter director, grid, weapons, board rendering, and automated tests.
- Chose an incremental extraction strategy that preserves the playable encounter before adding new pieces.
- Wrote a six-milestone AI implementation roadmap covering intent data, group fairness, Pawn/Knight polish, Bishop, Rook, and authored Queen/King bosses.
- Began the intent-foundation milestone after approval of the Tactical Predator behavior direction.
- Added enemy context, intent, archetype, and Pawn/Knight attack-pattern data.
- Refactored common enemies to score attacks, movement, pickups, turns, and waits with short-term action memory.
- Added awareness of the hero's visibly reserved destination while preserving locked telegraphs.
- Expanded the automated suite from 36 to 46 passing checks.
- Completed a clean 1,200-frame headless encounter simulation.
- Godot's dummy renderer crashed when asked to record a headless movie; visual capture must use the real renderer.
- Refined memory to track repeated directions instead of suppressing all movement.
- Shortened movement recovery so enemies maintain pressure without shortening attack telegraphs.
- Fixed context capture so enemies continue evaluating legal moves while the hero stands still.
- Final suite passes 47 checks.
- Final 1,200-frame runtime simulation completes without script errors.
- Real-renderer capture confirms active pursuit, facing changes, weapon pressure, and Knight angle changes.

## Enemy Debug Visualization

- Added an `F3` toggle for the complete enemy debug view.
- Added room, occupied-cell, blocked-cell, reservation, and item boundaries.
- Added color-coded intent paths for attack, move, pickup, turn, and wait decisions.
- Added live role, state, action score, and weapon labels above every enemy.
- Kept debug rendering observational so it cannot affect AI scoring or execution.
- Added continuous redraw so intent paths stay attached during tweened movement.
- Added five automated debug-data and visibility checks; the suite now passes 52 checks.
- Completed a clean 1,200-frame runtime simulation and real-renderer visual inspection.

## AI Pursuit Stability

- Replaced greedy Manhattan pursuit with cardinal `AStarGrid2D` routing around blocks, actors, and reservations.
- Added short goal commitment and six-cell movement history to prevent decision thrashing and repeated loops.
- Removed generic movement repetition penalties; recent-cell penalties now apply only when a fresh exit exists.
- Rejects occupied weapon cells as movement goals and chooses a reachable chess-attack setup cell around the holder.
- Debug movement paths now display the complete A* route.
- Debug labels flip below enemies near the top board edge.
- Expanded the suite to 56 passing checks.
- Completed two 60-second headless simulations and one 20-second real-renderer capture without a crash.

## Attack Lifecycle Crash Fix

- Forced attack selection, telegraph, damage, recovery, token cleanup, and attacker defeat while telegraphing.
- Reproduced a scene-tree lifecycle error when damage attempted to create an invulnerability timer without a valid tree.
- Hardened hero invulnerability startup and post-timer completion for startup, reload, and teardown windows.
- Applied the same scene-tree guards to player attack timing and delayed room reset.
- Added six direct attack-lifecycle checks; the main suite now passes 64 checks.
- Added `tests/attack_runtime_test.gd` for complete timed attack rendering.
- Forced-attack runtime test passes in both headless mode and the real Metal/OpenGL renderer.

## Editor-First Architecture Planning

- Audited runtime construction, enemy inheritance, AI Resources, scenes, tests, and existing migration plans.
- Selected Godot-native entity scenes, child-node components, and typed Resources instead of strict ECS.
- Defined component responsibilities, Resource contracts, editor workflows, encounter ownership, and extension rules.
- Wrote a six-phase migration that keeps the current encounter playable after every phase.
- Limited the first execution batch to typed data and `.tres` assets with no behavior extraction.

## Typed Data Foundation

- Added typed `EnemyDefinition`, `MovementConfig`, `DecisionConfig`, `DifficultyProfile`, and `VisualDefinition` Resources.
- Expanded `AttackPattern` with editable damage, timing, presentation, token, and facing metadata.
- Created Inspector assets for Pawn Recruit, armed Pawn, Tracker Knight, Pawn diagonal, Knight leap, Pencil Spear, Ruler Blade, movement, decisions, visuals, and standard difficulty.
- Wired existing Pawn and Knight actors through a compatibility layer without extracting components or changing visuals.
- Armed Pawn equipment now comes from `pawn_armed.tres`; weapon factory methods clone `.tres` assets.
- Added Resource validation and runtime parity checks; the main suite now passes 74 checks.
- Forced attack runtime test, 1,200-frame simulation, editor import, and real-renderer capture all pass.

## Base Enemy Scene Shell

- Added `enemy_base.tscn` with visible VisualRoot, movement, brain, attack, health, equipment, and debug child nodes.
- Added reusable `.tscn` scenes and typed scripts for all six components.
- Added `EnemyActor` as a compatibility host that injects itself into components while retaining `FreeEnemy` behavior.
- Verified the same base scene loads Pawn and Knight definitions and attack geometry.
- Verified removing the optional debug component does not affect combat data.
- Main suite now passes 81 checks; live encounter, forced attack test, and editor import remain clean.

## Grid Movement Component Extraction

- Moved base-enemy registration, legal destination queries, reservations, step tweening, and completion into `GridMovementComponent`.
- Added `EnemyActor` compatibility overrides that delegate movement without changing legacy Pawn/Knight paths.
- Preserved existing step signals and mirrored state required by the not-yet-extracted brain.
- Added four movement ownership checks; the main suite now passes 85 checks.
- Added a timed component movement regression covering occupancy transfer, reservation cleanup, and final positioning.
- Component movement test, forced attack test, live encounter simulation, and parser checks all pass.

## Equipment Component Extraction

- Added weapon ids and compatibility tags to Inspector Resources.
- Moved base-enemy weapon ownership, tag validation, default equipment, pickup collection, replacement geometry, damage, and timing into `EquipmentComponent`.
- Added host compatibility methods while preserving legacy Pawn/Knight equipment behavior.
- Prevented incompatible pickups from being removed before validation.
- Added fifteen equipment ownership checks; the main suite now passes 100 checks.
- Added a timed equipment regression covering signals, item cleanup, mirrored state, and active attack supply.
- Equipment, movement, forced attack, live encounter, and editor import tests all pass.

## Editor-First Full Game Roadmap - 2026-07-04

- Added a long-range editor-first roadmap to `task_plan.md` covering the full game from editor foundation through release polish.
- Preserved the existing prototype milestone history and added a separate `Editor-First Full Game Roadmap` section.
- Marked `E2. Editor-first encounter system` as the next recommended phase.
- Added immediate E2 deliverables for room scene, room encounter scene, enemy spawn points, pickup spawn points, and supporting scripts.
- Added acceptance criteria requiring the current first encounter to remain playable while enemy/pickup/blocker/message/win-condition content becomes Inspector-editable.
- Recorded the editor-first planning findings in `findings.md`.

## AI Workflow Rules - 2026-07-04

- Added `AGENTS.md` at the project root.
- Captured the editor-first project direction, E2 current priority, planning-file rules, implementation rules, combat readability rules, verification commands, and git rules.
- Updated `task_plan.md` with Phase 33 complete and a decision that future AI sessions should read `AGENTS.md` first.
- Updated `findings.md` with the purpose of the AI workflow rules file.

## Human Editor Workflow - 2026-07-04

- Expanded `AGENTS.md` with a collaboration model that separates AI implementation ownership from human editor/taste ownership.
- Added human editor checklists for room encounters, player feel, enemy feel, art/audio, narrative, and release review.
- Added a phase-gate workflow for future AI work and a standard handoff format for editor tasks.
- Added full game completion gates from editor foundation through release polish.
- Updated `task_plan.md` with Phase 34 complete and recorded the human editor handoff decision.
- Updated `findings.md` with the new AI/human ownership and completion-gate findings.

## Editor-First Encounter Scaffolding - 2026-07-04

- Added `RoomEncounter`, `EnemySpawnPoint`, and `PickupSpawnPoint` scripts and scenes.
- Added `scenes/rooms/first_encounter.tscn` with editable blockers, two pickup markers, two Pawn spawn markers, and one Knight spawn marker.
- Updated `main.gd` to load the room scene and receive room enemy events instead of hardcoding blockers, pickups, and enemy spawns directly.
- Added `tests/room_encounter_runtime_test.gd` to verify room blockers, pickups, enemy classes, armed Pawn default equipment, and room message.
- Verified `run_tests.gd`, `attack_runtime_test.gd`, component movement/equipment/Knight tests, room encounter runtime, encounter HUD runtime, headless launch, editor import, and `git diff --check`.
- Marked E2 as in progress and Phase 35 as complete in `task_plan.md`.

## Editor-Owned Room Objectives - 2026-07-04

- Added `RoomObjective` as an Inspector-editable Resource for room start text, clear result text, defeat text, and win-condition mode.
- Added `resources/objectives/first_encounter_clear_all.tres` and assigned it to `scenes/rooms/first_encounter.tscn`.
- Updated `RoomEncounter` to track defeated enemies, evaluate the objective, and emit `room_completed`.
- Updated `main.gd` so room clear and defeat copy come from the current room rather than hardcoded `main.gd` strings.
- Expanded tests for objective Resource logic and first-encounter completion signaling.
- Hit one GDScript parse issue when inferring the type of a script-loaded Resource; fixed it with explicit `Resource` typing and dynamic `call()`.
- Verified `run_tests.gd`, `attack_runtime_test.gd`, component movement/equipment/Knight tests, room encounter runtime, encounter HUD runtime, 1,200-frame headless launch, editor import, and `git diff --check`.
- Marked Phase 36 complete and moved E2 to human editor review in `task_plan.md`.

## Editor-Owned Main Scene Foundation - 2026-07-06

- Connected Godot MCP and used it to create first-pass scene files for Player, PrototypeBoard, GridWorld, EncounterDirector, and HUD.
- Reworked `scenes/main.tscn` so the main playable scene now shows GridWorld, EncounterDirector, PrototypeBoard, PawnHero, FirstEncounter, and HUD as editor-visible children.
- Added `scripts/ui/hud.gd` and `scenes/ui/hud.tscn`, moving HUD node composition out of `main.gd`.
- Updated `main.gd` to resolve exported child NodePaths first and only instantiate scene fallbacks when tests create the script directly.
- Fixed Godot warnings for integer division and shadowed parameter names in `PawnHero`, `PrototypeBoard`, `EnemyIntent`, and `main.gd`.
- Added tests proving `Main.tscn` owns editor-visible child nodes and that ready-time HUD/runtime bindings work from the scene.
- Verified `run_tests.gd`, `attack_runtime_test.gd`, component movement/equipment/Knight tests, room encounter runtime, encounter HUD runtime, 1,200-frame headless launch, editor import, and `git diff --check`.
- The 1,200-frame headless launch exits successfully but currently prints CanvasLayer teardown RID warnings after the scene-owned HUD migration.

## Scene-Backed Spawn Templates - 2026-07-06

- Added gameplay templates `objects/actors/black_pawn.tscn`, `objects/actors/knight_enemy.tscn`, and `objects/world/weapon_pickup.tscn`.
- Updated `EnemySpawnPoint` and `PickupSpawnPoint` to instantiate editor-assigned PackedScenes first, with script constructors kept only as compatibility fallbacks.
- Updated `first_encounter.tscn` so its enemy and pickup markers reference those PackedScene templates.
- Added `resources/attacks/wooden_sword.tres` and `resources/attacks/pencil_thrust.tres`, then assigned them to `player.tscn`.
- Updated `PawnHero` to use exported attack profiles from the scene while preserving default profiles for bare script tests.
- Exposed `PrototypeBoard` board, telegraph, impact, and debug colors as Inspector-editable theme fields.
- Expanded tests to verify player attack Resource ownership and scene-backed room spawns.
- Verified `run_tests.gd`, `attack_runtime_test.gd`, component movement/equipment/Knight tests, room encounter runtime, encounter HUD runtime, 1,200-frame headless launch, editor import, MCP project info, and `git diff --check`.

## Act 1 Opening Room Build - 2026-09-30

- Redesigned Act 1 as a self-contained tutorial chapter before Toybox, ending at the Black Pawn Captain and opening the Chess Rug Hub.
- Added editor-owned `T1_WhiteKingsFall` as the new starting room with visible room art nodes, tilemap, grid overlay, set dressing, entry marker, and exit marker.
- Pointed `scenes/main.tscn` at `T1_WhiteKingsFall` and placed the player at the intended opening entry.
- Added a thin editor-owned `T2_FallenSwordTile` route skeleton so T1's exit lands on a real scene and future map work has a valid next room to edit.
- Registered T1 and T2 in `resources/world/world_graph.tres`.
- Verified Godot import, `tests/run_tests.gd`, and `git diff --check` after connecting the route.

## Stage 1 Commercial Tutorial Spine - 2026-10-02

- Reframed Stage 1 against commercial tutorial openings such as *Prince of Persia: The Lost Crown*: battlefield context, teach/test rooms, first boss, then wider world opening.
- Added `docs/production/stage-1-commercial-tutorial-redesign.md` to lock the new standard and separate playable-spine completion from polish approval.
- Expanded the editable Act 1 route from T1/T2 into the full first-stage chain: `T1_WhiteKingsFall -> T2_FallenSwordTile -> T3_FirstPawnClash -> T4_BrokenRuleYard -> B1_BlackPawnCaptain -> H1_ChessRugHub`.
- Added editor-owned room scenes for T3, T4, B1, and H1, each with visible room art, grid overlay, entry markers, exit markers, and gameplay actors where appropriate.
- Added `resources/enemies/black_pawn_captain.tres` as a data-driven first boss definition using existing pawn behavior with stronger health and ruler weapon pressure.
- Registered every Stage 1 room in `resources/world/world_graph.tres`.
- Verified Godot import, `tests/run_tests.gd`, and `git diff --check`.

## Stage 1 Review Loop - 2026-10-05

- Added `docs/production/stage-1-review-loop.md` to record the self-review passes and remaining human review items.
- Review pass 1 fixed the biggest structural issue: clear-gated exits now exist, and `B1_BlackPawnCaptain/Exit_To_Hub` requires clearing the boss room.
- Review pass 2 made the story-critical sword moment real: added `PlayerUnlockMarker`, placed `FallenSwordUnlock` in T2, persisted `wooden_sword` in `WorldState`, and locked player attacks in world mode until the sword is collected.
- Review pass 3 locked the forward exits in T3 and T4 until their tutorial encounters are cleared, while keeping backtracking open.
- Review pass 4 added a `WorldState` save version so obsolete development saves reset to the new Stage 1 opening instead of booting into an old zone.
- Added tests for locked exits, sword-lock combat, player unlock persistence, and Stage 1 forward-gate validation.
- Updated `tests/encounter_hud_runtime_test.gd` from the old kingdom-start assumption to the new T1 Stage 1 start.
- Verified targeted combat/runtime tests, `tests/run_tests.gd`, `tests/encounter_hud_runtime_test.gd`, and Godot import.

## Editor-Owned Actor Visuals - 2026-07-06

- Added reusable visual scenes for the hero pawn, black pawn, knight, and weapon pickup.
- Updated player, enemy, base enemy, and pickup scenes so each owns an editable `Visual` child instance.
- Moved actor and pickup body/weapon/health/telegraph drawing out of `PawnHero`, `BlackPawn`, `KnightEnemy`, and `WeaponPickup`; gameplay scripts now sync state into visual child nodes.
- Linked `VisualDefinition` Resources to the new pawn and knight visual scenes.
- Added tests proving player, base enemy, and room-spawned enemies/pickups own visual children.
- Fixed one Godot import-order issue by using dynamic visual child calls from older gameplay scripts.
- Verified `run_tests.gd`, `attack_runtime_test.gd`, component movement/equipment/Knight tests, `room_encounter_runtime_test.gd`, `encounter_hud_runtime_test.gd`, 1,200-frame headless launch, editor import, and `git diff --check`.

## Generic Enemy Scene Variants - 2026-07-06

- Changed `objects/actors/black_pawn.tscn` and `objects/actors/knight_enemy.tscn` so both use `EnemyActor` as the root script.
- Added movement, brain, attack, health, equipment, and debug component children directly to those gameplay enemy templates.
- Kept old `BlackPawn` and `KnightEnemy` scripts only as temporary legacy/test compatibility paths.
- Moved Knight flanker positioning behavior into `EnemyActor` when its archetype role is `flanker`.
- Updated HUD and main-scene status copy to read enemy display names from `EnemyDefinition` data instead of class checks.
- Updated room and main tests to verify scene-spawned enemies are generic `EnemyActor` variants with Pawn/Knight definitions.
- Verified `run_tests.gd`, `attack_runtime_test.gd`, component movement/equipment/Knight tests, `room_encounter_runtime_test.gd`, `encounter_hud_runtime_test.gd`, 1,200-frame headless launch, editor import, and `git diff --check`.

## Health Component Extraction - 2026-07-06

- Updated `EnemyActor.take_damage()` to delegate damage and defeat handling to `HealthComponent`.
- Expanded `HealthComponent` so it owns health reduction, hurt flash/recoil values, attack-token release, grid unregistering, defeat signal emission, and delayed cleanup.
- Added an editor-visible `AnimationPlayer` inside `objects/components/health_component.tscn` with `hurt` and `defeat` animations targeting the enemy actor root.
- Kept `FreeEnemy.take_damage()` as the legacy direct-test fallback while scene-spawned enemies use the component path.
- Added tests proving the health component owns feedback animations, hurt feedback state, and defeat cleanup.
- Verified `run_tests.gd`, `attack_runtime_test.gd`, component movement/equipment/Knight tests, `room_encounter_runtime_test.gd`, `encounter_hud_runtime_test.gd`, 1,200-frame headless launch, editor import, and `git diff --check`.

## Editor-Owned Room Art - 2026-07-06

- Responded to editor review that `main.tscn` still looked like a script-generated debug scene rather than an authored room.
- Added a visible `RoomArt` subtree directly inside `scenes/rooms/first_encounter.tscn`, including floor frame, board surface, checker tiles, boundary tape, and simple playground/castle set dressing.
- Added editor-visible preview child instances under pickup and enemy spawn markers so weapons, Pawns, and the Knight are visible in the room before pressing Play.
- Updated spawn marker scripts to hide those preview children at runtime.
- Added `draw_base_layer` to `PrototypeBoard` and disabled it in `main.tscn`, making the room art own the floor while `PrototypeBoard` keeps telegraphs, hit flashes, and debug paths.
- Updated tests to assert the main scene and first room own editable board-art and marker-preview nodes.
- Verified `run_tests.gd`, `attack_runtime_test.gd`, component movement/equipment/Knight tests, `room_encounter_runtime_test.gd`, `encounter_hud_runtime_test.gd`, 1,200-frame headless launch, editor import, and `git diff --check`.
- Remaining human editor review: reopen `scenes/main.tscn` or `scenes/rooms/first_encounter.tscn`, confirm the room now reads as an actual authored battlefield, and tune/replace the placeholder `Polygon2D` art when ready.

## Room Authoring Markers - 2026-07-06

- Responded to follow-up that the editor scene should show a grid and manageable character/gameplay nodes.
- Added `HeroStartMarker` and `BlockerMarker` scenes with draggable/snap-to-grid `grid_cell` authoring behavior.
- Updated enemy and pickup spawn markers so dragging them in editor updates `grid_cell`.
- Updated `RoomEncounter` so hero start and blockers are read from marker nodes, with old exported blocked cell arrays kept as fallbacks.
- Added visible `RoomArt/GridLines` nodes to the first encounter and editor labels for hero, blockers, pickups, Pawns, armed Pawn, and Knight.
- Enabled editable children for `PawnHero` and `FirstEncounter` in `main.tscn`.
- Added `docs/design/room-authoring-guide.md` explaining which nodes to move and which nodes are visual only.
- Verified `run_tests.gd`, `attack_runtime_test.gd`, component movement/equipment/Knight tests, `room_encounter_runtime_test.gd`, `encounter_hud_runtime_test.gd`, 1,200-frame headless launch, editor import, and `git diff --check`.

## TileMap Room Floor - 2026-07-06

- Converted the first encounter floor from many individual `Polygon2D` tile nodes to a real `TileMapLayer`.
- Added `assets/tiles/playground_tiles.svg` as the small board tile atlas.
- Added `resources/tiles/playground_tileset.tres` and `objects/world/playground_tilemap.tscn`.
- Replaced `RoomArt/Tiles/*` in `first_encounter.tscn` with `RoomArt/TileMap`.
- Kept grid lines, boundaries, set dressing, and gameplay markers separate so tile editing and gameplay placement stay clean in the editor.
- Updated tests and the room authoring guide to point at the TileMapLayer workflow.
- Verified `run_tests.gd`, `attack_runtime_test.gd`, component movement/equipment/Knight tests, `room_encounter_runtime_test.gd`, `encounter_hud_runtime_test.gd`, 1,200-frame headless launch, editor import, and `git diff --check`.

## Scene/Object Folder Cleanup - 2026-07-06

- Moved reusable object templates out of `scenes/` and into `objects/`.
- `scenes/` now contains only `main.tscn`, authored room scenes, and UI scenes, so the Godot editor tree reads like actual game screens instead of a prefab dump.
- Actor, enemy, pickup, marker, component, visual, combat helper, and world helper `.tscn` files remain editable Godot scenes under `objects/`.
- Updated scene, script, resource, test, tool, README, planning, and workflow references to the new object paths.
- Verified `run_tests.gd`, `attack_runtime_test.gd`, component movement/equipment/Knight tests, `room_encounter_runtime_test.gd`, `encounter_hud_runtime_test.gd`, 1,200-frame headless launch, editor import, and `git diff --check`.

## Sprite-Based Visual Objects - 2026-07-06

- Generated first-pass PNG sprites for the hero pawn, black pawn, black knight, weapon pickup, toy sword, pencil spear, ruler blade, warning aura, facing arrow, and health pips under `assets/sprites/generated/`.
- Converted `objects/visuals/pawn_hero_visual.tscn`, `black_pawn_visual.tscn`, `knight_enemy_visual.tscn`, and `weapon_pickup_visual.tscn` to real `Sprite2D` child nodes with editor-visible `AnimationPlayer` clips.
- Reworked `PieceVisual` and `PickupVisual` so scripts sync sprite state, weapon textures, health pips, facing arrows, and telegraph visibility without drawing actor bodies through `_draw()`.
- Restored scene-backed enemy/pickup template bindings in `scenes/main.tscn` while preserving the edited marker positions, so the live room uses sprite object scenes instead of fallback constructors.
- Added tests that require sprite-based animated visuals and guard against reintroducing script-drawn piece/pickup bodies.
- Verified `run_tests.gd`, `attack_runtime_test.gd`, component movement/equipment/Knight tests, `room_encounter_runtime_test.gd`, `encounter_hud_runtime_test.gd`, 1,200-frame headless launch, editor import, `git diff --check`, and a real-renderer capture at `/tmp/unbound-pawn-sprite-pass.avi`.

## Richer Visual Animations - 2026-07-06

- Added editor-owned `step` (walk) AnimationPlayer clips to `pawn_hero_visual.tscn`, `black_pawn_visual.tscn`, and `knight_enemy_visual.tscn`; the Knight step is heavier (bigger hop, stronger squash) than the Pawn step.
- Enriched existing clips inside the AnimationPlayer (no `_draw()`): hero `hurt` now shakes, hero `attack` now adds a body lunge, and both enemy `telegraph` clips add a body squash windup so the attack tell is readable before the aura alone.
- Added a scale-pulse track to the weapon pickup `idle` clip so pickups breathe and read as obvious on the board (fixed a compounding-scale mistake: `SpriteRoot` breathes around `1.0`, not the child sprite's `0.42`).
- Wired locomotion in `scripts/visuals/piece_visual.gd`: `sync_from_hero` and `sync_from_enemy` now play `step` while the actor is moving (guarded fallback to `idle` when a visual has no `step` clip). Enemies read `is_moving` from the actor, which `GridMovementComponent` already maintains.
- Enabled `[editable path="Visual"]` on `player.tscn`, `black_pawn.tscn`, `knight_enemy.tscn`, and `weapon_pickup.tscn` so the sprite/AnimationPlayer subtree is visible and tweakable directly from each actor prefab, not only inside the nested visual scene.
- Added a `_visual_has_clip` test helper and assertions that the player, Pawn, and Knight visuals own a `step` clip.
- Verified `run_tests.gd` (0 failures), `attack_runtime_test.gd`, component movement/equipment/Knight tests, `room_encounter_runtime_test.gd`, `encounter_hud_runtime_test.gd`, editor import, `git diff --check`, and a real-renderer capture at `/tmp/unbound-pawn-anim.avi`.
- Preserved the human's uncommitted editor edits (resource UID rewrites and `main.tscn` marker moves); this milestone touched only visual/animation scenes, `piece_visual.gd`, actor prefabs, and tests.

## Editor-First Refactor - 2026-07-07

Audited the script layer (largest offenders: `free_enemy.gd` 570 lines, `main.gd`, `prototype_board.gd`) and refactored in four verified, separately committed phases. Each phase kept the playable slice green (`run_tests` 0 failures + all runtime tests + editor import + `git diff --check`).

- Phase 1 (`0145106`): deleted FreeEnemy's dead `_draw_health_pips`/`_draw_attack_warning_aura` (no callers, no redraw); hero attack profiles now load `wooden_sword.tres`/`pencil_thrust.tres` as the null fallback instead of duplicating the stats in code.
- Phase 2 (`c318199`): `main.gd` no longer mirrors HUD nodes or duplicates their formatting; removed the cached label vars, `_bind_hud_references`, and every `elif <label>` fallback so all HUD updates go through the editor-owned `GameHud` scene. Rewrote the HUD runtime test to read HUD state from the HUD scene nodes.
- Phase 3 (`b32b132`): `AttackPattern` now builds cells from an editor-authored `cell_offsets` list (facing-relative or absolute + `clip_to_board`), so a new enemy's attack shape is a pure `.tres`. Migrated `pawn_diagonal.tres`/`knight_leap.tres` (identical geometry) and deleted `PawnPattern`/`KnightPattern`. Deleted the `BlackPawn`/`KnightEnemy`/`TrainingDummy` subclasses; spawns require an editor `enemy_scene`; tests spawn the scene variants. Fixed a latent `PrototypeBoard` debug-redraw crash (typed loop var errored on a freed enemy key).
- Phase 4 (`16e83af`): optional `texture` on `EnemyWeapon`/`AttackProfile` — visuals use it directly, so a new weapon is just a `.tres` + texture (id lookups kept as fallback for current placeholders). Authored `piece_name` on `EnemyDefinition` (Pawn/Knight) replaces FreeEnemy's display-name string guessing.
- Phase D (brain extraction) deferred: enemy AI is already Resource-driven through `DecisionConfig`/archetype `.tres`, so relocating the decision plumbing out of `FreeEnemy` into `EnemyBrainComponent` is behavior-risky churn with no expandability gain. Left for an explicit, isolated pass if desired.
- Net: adding a new enemy or weapon is now editor/Resource work (definition + movement/decision/attack/visual `.tres` + a scene variant), no new GDScript required; HUD, dead code, and duplicated tuning are gone.

## AI Editor Surface - 2026-07-07 (`473e5f3`)

Researched the AI-focused editor surface at the owner's request. Found `EnemyBrainComponent` was a hollow node (zero Inspector fields) while the real AI knobs lived on a `DecisionConfig` `.tres` two hops away and were duplicated into a runtime `EnemyArchetype`; the Knight's flanker positioning was a hardcoded `role=="flanker"` branch. Fixed as one verified commit:

- `EnemyBrainComponent` now exposes an optional `DecisionConfig` export, so AI tuning is editable directly on the AI node; an enemy can override the shared `EnemyDefinition.decision`.
- `DecisionConfig` is the single AI profile: absorbed `EnemyArchetype`'s score fields (class deleted, no copy step), added `preferred_distance`, exposed the previously hardcoded weights (`preferred_distance_weight`, `turn_progress_weight`, `local_pickup_bonus`), and added `flank_bonus`/`axis_change_bonus`.
- The hardcoded flanker branch in `EnemyActor` is gone; positioning bonus is now data (`flank_bonus`/`axis_change_bonus`) in the base scoring, so a Bishop/Rook/Queen personality is a pure `.tres`.
- Behavior preserved: Knight keeps flank 30 / axis 12 / preferred distance 3, Pawn keeps distance 2. Verified against the deterministic AI unit tests (identical intent scores/choices) + a clean 1200-frame headless encounter + editor import.
- Deferred (unchanged recommendation): relocating the scoring *code* from `FreeEnemy` into `EnemyBrainComponent` — churn with behavior risk and no editor gain now that the AI *data* is fully editor-owned.

## Data-Only Bishop Enemy - 2026-07-07 (`6831b6a`)

- Validated the data-driven pipeline by adding a whole new enemy with zero new GDScript: `bishop_diagonal.tres` (MovementConfig, 4 diagonal steps), `bishop_diagonal.tres` (AttackPattern, absolute diagonal beams + `clip_to_board`), `bishop_sniper.tres` (DecisionConfig, sniper role + `flank_bonus 24`), `bishop_compatibility.tres` (VisualDefinition, reuses the knight visual as placeholder), `bishop_zoner.tres` (EnemyDefinition), and `bishop_enemy.tscn` (generic `EnemyActor` + components).
- Added tests asserting the Bishop uses `enemy_actor.gd`, moves/attacks diagonally from data, and carries a pure `DecisionConfig` AI. Own sprite is a later art-pass item.

## Redundant Component Removal - 2026-07-07 (`09b39b3`)

- Audited every script/component for redundancy. Found `AttackComponent` and `EnemyDebugComponent` were hollow scaffolds — their methods had no callers because the attack lifecycle and debug view live in `FreeEnemy` — so every enemy carried two inert nodes.
- Deleted both scripts + scenes, removed them from `enemy_base`/`black_pawn`/`knight_enemy`/`bishop_enemy`, and stripped their vars/wiring/config-warnings from `EnemyActor`. Slimmed `EnemyBrainComponent` to just its used `decision` export (its 3 accessor methods had no callers).
- Enemies now carry four functional components: `GridMovementComponent`, `EnemyBrainComponent` (AI data), `HealthComponent`, `EquipmentComponent`. Behavior unchanged; verified against the full test suite, editor import, and a 600-frame headless sim.
- Remaining minor vestige (left intentionally): `FreeEnemy.create_enemy_definition`/`create_attack_pattern` base virtuals are now only null-safety fallbacks since the subclasses are gone; harmless.

## Shared GridMarker Base - 2026-07-07

- Continued the redundancy audit into `scripts/world/`. All four room markers (`EnemySpawnPoint`, `PickupSpawnPoint`, `HeroStartMarker`, `BlockerMarker`) copy-pasted the same grid-snap block: the preview constants, the `grid_cell`/`sync_position_to_grid` exports with setters, `_process` editor snapping, `_sync_position_to_grid`, and `_position_to_grid_cell` (~30 lines each).
- Extracted a `@tool class_name GridMarker extends Node2D` base holding that logic plus a `_ready_marker()` hook. Each marker now `extends GridMarker` and keeps only its own data, preview/label visibility, and `_draw`. ~110 lines of duplication removed; cell-snapping has one source.
- Registering a brand-new global class (`GridMarker`) needs one headless editor import before the strict-typed subclasses parse — expected, same as prior global-class additions.
- Verified: `run_tests` 0 failures + all runtime tests + editor import + `git diff --check` clean. Marker behavior (drag-to-snap, previews, hero start (3,7)) unchanged.

## GridLines Overlay Node - 2026-07-07

- The room dock's biggest clutter was `RoomArt/GridLines`: 27 hand-placed `Line2D` nodes (17 vertical + 10 horizontal) for the cell grid. Replaced them with one `GridLinesOverlay` (`@tool Node2D`) that draws the grid from exported dims (`grid_origin`, `cell_size`, `columns`, `rows`, colour, width). Decorative overlay, so `_draw` is allowed and runs in editor + game.
- Two test assertions checked the removed `GridLines/Vertical_00` child; updated both to `GridLines is GridLinesOverlay`.
- Verified: `run_tests` 0 failures + `room_encounter`/`encounter_hud`/`attack`/`movement` runtime tests + editor import + a real-renderer capture (grid renders identically) + `git diff --check` clean.
- Room tree is now much lighter: RoomArt = Frame, TileMap, GridLines (1 node), Boundary, SetDressing.

## Kingdom Floor Re-theme - 2026-07-07 (`e735890`)

- Re-themed the first room floor from playground checker to a throne-room kingdom. New art `assets/tiles/kingdom_tiles.svg` (light marble, dark marble, red carpet, gold-trim carpet) + `resources/tiles/kingdom_tileset.tres`.
- The `PackedByteArray` `tile_map_data` is not hand-editable, so painting is done by a build tool: `tools/paint_kingdom_tilemap.gd` runs headless, `set_cell`s the 16x9 layout (marble checkerboard with a red carpet runner down centre columns 7-8), packs, and saves `objects/world/kingdom_tilemap.tscn`. Rerun it after changing the layout/tileset.
- Kept the light/dark checkerboard contrast on purpose: grid combat readability depends on it. The carpet reads as a throne aisle.
- `first_encounter.tscn`'s TileMap now points at `kingdom_tilemap.tscn`; the old `playground_tilemap.tscn` is left as a swappable alternate theme (still valid, just unreferenced).
- Verified: `run_tests` 0 failures + room/hud runtime tests + editor import + a real-renderer capture (throne-room floor renders, pieces/pickups/telegraphs read clearly over it) + `git diff --check` clean.
- Art status: first-pass placeholder for in-editor owner approval (AGENTS: art direction is human-owned). This shifts the floor toward a castle/kingdom read while staying inside the child-imagination frame.
- Follow-up: expanded the kingdom tileset to 7 tiles (added stone-brick wall, throne, banner) and the paint tool now frames the board with a stone-brick castle-wall border ring, twin thrones atop the carpet aisle (cells 7-8, row 0), and blue/gold banners on the side walls (rows 2 and 6). The HUD covers the space above the board, so the castle decor lives in the tilemap border rather than as set-dressing above the board. Combat still happens on the inner cells; verified via tests + real-renderer capture.

## Canonical Actor Node Structure (Visual Wrapper Flattened) - 2026-07-17

- Researched the standard Godot player/enemy structure (docs + community consensus): sprites and the `AnimationPlayer` belong directly on the actor scene; a generic "Visual" wrapper synced by polling is an anti-pattern (indirection + stringly `.get()` access, no typed errors).
- Flattened both sides per the owner's "change both player and enemies": `player.tscn` and all 4 enemy scenes (`black_pawn`, `knight_enemy`, `bishop_enemy`, `enemy_base`) now own `MotionRoot/SpriteRoot` (BodySprite, FacingArrow, WeaponPivot/WeaponSprite, HealthPips), a `TelegraphAura` (enemies), and their per-piece `AnimationPlayer` libraries — everything visible and editable in one scene tree.
- `pawn_hero.gd` / `free_enemy.gd` gained a typed Appearance section (`@export_group("Appearance")` + `@onready` node refs + `_update_appearance()` per frame). Deleted `piece_visual.gd`, the three piece visual scenes, the `visual_path`/`_sync_visual` plumbing, and the component `has_method("_sync_visual")` calls. Pickups keep their `Visual` child (out of scope).
- MotionRoot/SpriteRoot split preserved: procedural offsets (recoil, bump bob) go on MotionRoot; the AnimationPlayer animates SpriteRoot — they never fight over one property.
- Weapon/attack sprites are now data: `texture` set in `pencil_spear/ruler_blade` (`EnemyWeapon`) and `wooden_sword/pencil_thrust` (`AttackProfile`) `.tres`; the id/name-based texture lookup fallbacks are gone. `VisualDefinition` dropped `visual_scene` + `legacy_draw_kind` (they pointed at the deleted scenes).
- Removed the stale `[editable path="PawnHero/Visual"]` from `main.tscn`; tests re-pointed (`_actor_is_sprite_animated`, room `visuals_ok` checks `BodySprite`); docs updated (ARCHITECTURE, coding-standards, AGENTS, vault notes, /new-enemy).
- Verified: editor import clean, `run_tests` 0 failures, all 6 runtime tests PASS, `git diff --check` clean, real-renderer capture shows bodies/pips/facing arrow/pencil-spear weapon rendering from the actors' own sprites.

## Player Component Split - 2026-07-17

- Owner asked for the player to be component-based like the enemies ("split player script into components for me for easier to extend"), with `Player*` naming. Same skeleton as `EnemyActor`: thin coordinating host + behavior child nodes.
- New base `PlayerComponent` (`configure(host)` dependency injection — parallel to `EnemyComponent`, which stays enemy-typed) and three components: `PlayerInputComponent` (all key reading: WASD + hold-repeat + buffering + turn mode + attack/skill triggers, owns only `hold_time`/`last_held_direction`), `PlayerCombatComponent` (`try_attack` coroutine, `can_start_attack`, new `try_skill` wrapping the skill-cooldown gate), `PlayerHealthComponent` (`apply_damage`, invulnerability window).
- Design rules held: state stays on `PawnHero` (courage, cooldowns, `buffered_direction`, `control_enabled` — HUD/appearance/tests keep one source of truth), signals stay on `PawnHero`, public facades preserved (`try_attack`, `take_damage`, `can_start_attack`, `try_turn`) so `main.gd`, `free_enemy.gd` (attacks the hero), and all tests needed zero call-site changes.
- Bare-script `PawnHero.new()` instances (tests) still work: combat/health components are created on demand inside the facades (the sanctioned runtime-factory-as-fallback pattern); input is scene-only, so a bare hero has no controls — correct for tests.
- `_get_configuration_warnings()` on PawnHero flags missing components in the editor, same as EnemyActor.
- Gotcha rediscovered: `run_tests.gd` runs in `SceneTree._init`, before `_ready` — the scene hero's components exist but aren't configured yet, so the test calls `_configure_components()` manually (exactly like the enemy variant tests). The first failed assertion aborted the script before `quit()`, which presented as a suite hang, not a failure.
- Verified: editor import registers the 4 new classes, `run_tests` 0 failures (incl. new composition + binding assertions), all 6 runtime tests PASS, `git diff --check` clean, real-renderer frame identical to pre-split.

## ECS Conversion Phase A: Core + Movement Slice - 2026-07-19

- Owner chose full ECS conversion (over hybrid/stay, costs explained: editor drag-authoring becomes spawn-data + puppet views). Design + phase plan in `docs/ecs-conversion-plan.md` — read it before touching `scripts/ecs/`.
- Built the core: `EcsWorld` (entity ids, `store_by_component` stores, ordered system ticking, event queue, `manual_tick` for deterministic tests), `EcsComponents` (pure-data inner classes + store-key consts), `EcsSystem` base, `EcsGrid` (reserve→commit occupancy ported 1:1 from GridWorld for int entity ids — GridWorld's typed `actor: Node` params can't hold ids; phase D reconciles).
- Systems: `MovementSystem` (MoveIntent → begin_move/finish_move, MoveState progress, step events), `PlayerInputSystem` (keys → intents, buffering + hold-repeat port), `ViewSyncSystem` (the ONLY node-touching system: quad-eased slide, row depth, step/idle clips).
- `tests/ecs_runtime_test.gd`: 17 assertions green (registration, blocks, reservation protects destination mid-move, origin stays occupied while sliding, commit transfers occupancy, view lands on cell center + row depth, occupied-cell rejection, destroy frees cell).
- Node game untouched and green (`run_tests` 0 failures, room test PASS) — per plan rule "never half-flip": `scenes/main.tscn` runs the node game until phase D lands whole.
- Next: phase B (CombatSystem + HealthSystem + hero attacks), C (EnemyAISystem port), D (flip main.gd, strip actor scripts to views, port tests, amend CLAUDE/AGENTS editor-first doctrine).

## ECS Conversion Phase B: Combat + Health Slice - 2026-07-19

- `CombatSystem`: the attack lifecycle as timers, no coroutines — consume `AttackIntent`, lock `pending_cells` at swing start, resolve damage at `impact_left` expiry, release after `recovery_left` (recovery − impact_delay, ported timing). Damage goes into `world.damage_events`; presentation facts (`attack_started`, `attack_landed`, `skill_cooldown`) into the event queue.
- `HealthSystem`: sole consumer of `damage_events` — invulnerability window (player-tagged only), hurt/flash timers, defeat (player: control off; non-player: leaves grid, view despawn happens at the flip via the `defeated` event).
- `PlayerInputSystem` now writes `AttackIntent` (&"sword"/&"skill").
- Behavior bug caught by the test and fixed in the system: intents must be consumed every tick — an attack press during cooldown is swallowed like the node game, not banked for auto-fire after recovery.
- `tests/ecs_combat_test.gd`: 12 assertions green (lock/impact/recovery, single application per swing, skill gate, invulnerability swallow + decay, defeat event + grid removal, and the dodge rule: stepping off a locked cell before impact avoids the hit).
- Both ECS tests green; node game untouched.

## ECS Conversion Phase C: Enemy AI Slice - 2026-07-19

- `EnemyAISystem`: the FreeEnemy brain as a system — observe→decide→telegraph→commit→recover with the intent scoring ported verbatim (path-distance pursuit, goal commitment, flank/axis bonuses, repetition penalty, turn scoring). `EnemyIntent` (RefCounted) reused unchanged; `EnemyContext` logic inlined (its typed `FreeEnemy` param can't take entity ids). Attack token = `world.attack_token_owner` (EncounterDirector port); HealthSystem releases it on the holder's death.
- `EcsGrid` gained the pathing + item registry: A* (`get_grid_path`/`get_path_distance`/`get_next_path_cell`, other movers + reservations solid unless goal), `is_plannable_cell`, `get_destinations`, `item_by_cell` with register/take.
- `EcsActorFactory`: entities from the same `.tres` as the node game — `spawn_enemy` ports `_apply_definition` (movement timing, decision observe delay, unarmed pattern timings, difficulty multipliers, default weapon duplicate), plus `spawn_player`/`spawn_pickup`.
- `AttackPattern.get_attack_cells` world param is now duck-typed (only `is_inside` used) so both GridWorld and EcsGrid work; node callers unaffected (suite verified).
- `tests/ecs_enemy_test.gd`: 16 assertions green — definition-driven stats, pattern diagonals, pursuit closes path distance 8→3, telegraph locks cells + takes token, dodge by stepping off locked cells, dodged strike still releases token, held token blocks telegraphs, local pickup equips + leaves grid, lethal damage defeats + frees cell + releases token.
- All 3 ECS tests + full node suite green. Next: phase D — the flip (main.gd boots EcsWorld from scene data, actor scenes become pure views, HUD/camera bridge consumes events, port remaining tests, amend CLAUDE/AGENTS doctrine).

## ECS Conversion Phase D: The Flip - 2026-07-19

- `scenes/main.tscn` now runs the ECS game. `main.gd` boots an `EcsWorld` with all six systems, spawns the cast via `EcsBoot` (parked ActorViews → entities, painted solid tiles → blocks, pickup markers → item entities + floating views), and is otherwise a pure presentation bridge: the event queue drives HUD text, board overlay, camera shake, defeat animations, and pickup-view despawns. No gameplay decision lives outside systems.
- New `ActorView` (`scripts/ecs/actor_view.gd`): the one script on every actor scene root — spawn data (definition / attack profiles) + appearance knobs, zero logic (asserted by test: no `_draw`, no `_process`). All 5 actor scenes flipped: script swap, component child nodes removed.
- `ViewSyncSystem` grew to full appearance parity: body tint (hurt/invulnerability flicker/telegraph), recoil+bob on MotionRoot, aura pulse with telegraph progress, facing arrow, weapon sprite (attack texture / equipped weapon texture), health pips, edge-detected clips (memory lives on ViewRef — view-side data).
- Presentation adapted, not rewritten: `PrototypeBoard` keys telegraphs/intents by entity id and reads progress from the world (F3 debug paths still work via the `intent_changed` event carrying the full `EnemyIntent`); `GameHud.set_token_owner` takes a piece-name string; `CameraRig` clamps to the duck-typed `EcsGrid`; `WeaponPickup` is a dumb floating view; `RoomEncounter` is data-only (prose + objective).
- Deleted the node runtime layer: `pawn_hero.gd`, `free_enemy.gd`, `enemy_actor.gd`, `grid_actor.gd`, `grid_world.gd`(+scene), `encounter_director.gd`(+scene), `enemy_context.gd`, all 8 behavior components (+scenes). `EnemyIntent`, `AttackPattern` (world param duck-typed), markers, and all `.tres` data survive untouched — content authoring didn't change.
- Tests: `run_tests.gd` is now the data+structure suite (EcsGrid rules, views-are-pure checks, .tres content); room test boots the authored scene through `EcsBoot` (parked cells, armed pawn's spear, solid walls, pickups, objective); HUD test boots the full `main.tscn` and drives `_process` by hand (re-learned: `_ready` waits for the first frame in SceneTree tests). Deleted the 4 superseded component/attack runtime tests.
- Verify docs updated (CLAUDE.md loop, /verify, AGENTS.md commands): suite = run_tests + ecs_runtime + ecs_combat + ecs_enemy + room_encounter_runtime + encounter_hud_runtime.
- Verified: import clean, all 6 suites green, `git diff --check` clean, real-renderer capture — enemies pursue, armed pawn carries its spear, pips/arrow/pickups/HUD all live, F3 paths drawn from entity data.

## Editor-Draggable ECS Components (Spec Nodes) - 2026-07-19

- Owner wanted components back as nodes for scene authoring ("1 node as a component for ecs"). Answer: the authoring-component pattern — spec nodes in the dock, tables at runtime (same idea as Unity DOTS authoring/baking).
- New `scripts/ecs/specs/`: `ComponentSpec` base (pure Inspector data, `apply(world, entity_id)`, editor warning when not under an ActorView) + `HealthSpec` (max health / invulnerability override), `WeaponSpec` (arms the entity with an EnemyWeapon .tres copy), `AISpec` (per-instance DecisionConfig override — the old brain-component idea as spawn data).
- Workflow: open any actor scene or room instance → Add Child Node → HealthSpec/WeaponSpec/AISpec → tune in Inspector. `EcsBoot._apply_specs` bakes every spec child into the freshly spawned entity, after the definition, so an instance spec always wins.
- Specs hold zero logic — systems still own every decision; a spec is just editor-visible component data.
- Verified: import registers the 4 classes, all 6 suites green including 2 new assertions (HealthSpec overrides definition health; WeaponSpec arms at boot), whitespace clean.

## Component Nodes Renamed (Spec -> Component) - 2026-07-19

- Owner call: the editor nodes ARE the components, name them so. `ComponentSpec`->`EntityComponent` (base), `HealthSpec`->`HealthComponent`, `WeaponSpec`->`WeaponComponent`, `AISpec`->`AIComponent`; folder `scripts/ecs/specs/`->`scripts/ecs/components/`; `EcsBoot._apply_specs`->`_apply_component_nodes`.
- Safe rename: no scene serialized the old class names (only code + the room test); the node-era `HealthComponent` class was already deleted, so no collision. All 6 suites green after re-import.

## Player Carries a HealthComponent Node - 2026-07-19

- Owner flagged the player scene as "not right": it showed zero component nodes, and player health config lived nowhere in the editor (spawn_player defaults only). Enemies get health from their definition .tres; the player has no definition, so its editor surface is the component node.
- `player.tscn` now carries a `HealthComponent` child (max_health 3, invulnerability 0.7 — identical to the old defaults, now Inspector-tunable). EcsBoot bakes it at spawn like any component node. New suite assertion locks it in.

## Full Player Component Set - 2026-07-19

- Owner: "only health component?" — completed the set. `player.tscn` now carries HealthComponent + CombatComponent + MovementComponent + InputComponent nodes; the attack profiles moved OFF the ActorView root exports onto the CombatComponent node (single source — `ActorView` keeps only `definition` + appearance knobs), and step duration / held-repeat delay went from hardcoded factory defaults to Inspector fields.
- New component nodes: `CombatComponent` (wooden_sword/pencil_thrust .tres + skill cooldown → PlayerCombat), `MovementComponent` (step_duration → MoveState), `InputComponent` (held_repeat_delay → PlayerInput; no-op on enemies). Enemies unchanged — their equivalents live in the definition .tres (no duplication).
- `EcsBoot` spawns the player bare and lets the component nodes supply the kit. Suite assertions updated (CombatComponent carries the loadout; movement/input nodes present). All 6 suites green + render clean.

## Animation State Graphs on AnimationTree - 2026-07-19

- Owner picked node control for animation. Each actor scene now owns an `AnimationTree` (active, StateMachine root, driving the sibling AnimationPlayer): states idle/step/hurt/attack (+telegraph on enemies), with transitions, xfades, and at_end recovery authored in the editor graph — per our own rule, the hand-written clip picker yielded to the built-in node.
- Split of duties: locomotion (idle↔step) flows through the graph's auto conditions (`moving`/`not_moving`); one-shots (hurt/attack/telegraph) enter via `travel()` on state edges because a state machine cannot express "from any state" entries; telegraph exits via the `not_telegraphing` condition with a 0.06s xfade; hurt/attack return to idle via at_end transitions — recovery timing is editor-tunable now.
- `ViewSyncSystem` no longer picks clips: it publishes condition facts + fires travel on edges (`_drive_clips`). Views without a tree fall back to the old direct `play()` path, so bare test views keep working.
- The gameplay slide (cell-to-cell lerp from MoveState) stays procedural — unchanged, per the MotionRoot/SpriteRoot contract.
- New suite helper `_actor_has_state_graph`: all 5 actor scenes assert an active AnimationTree with a StateMachine root.
- Verified: import clean, all 6 suites green, whitespace clean, real-render capture shows tree-driven hops/pursuit/pips/weapons live.

## Sound Telegraphs + Editor-Owned Defeat - 2026-07-28

- Research follow-ups built. (1) SOUND: the missing telegraph channel per the Into the Breach/telegraphing research — four generated chiptune SFX (`tools/generate_sfx.py` → `assets/sfx/`: telegraph_warning, sword_whoosh, hurt_thud, defeat_crumple), keyed as AUDIO TRACKS inside the animation clips through each actor's new `AudioStreamPlayer`. Editor-native: retiming a clip retimes its sound; the telegraph beep re-fires each windup loop.
- (2) DEFEAT CLIP: every actor scene gains a `defeat` clip (squash to flat + crumple sound) and a terminal `defeat` state (travel-only entries from every state, no exit — holds the final pose). `ViewSyncSystem` travels to it once on the death edge (`Health.current <= 0`, `ViewRef.was_dead` memory); `main.gd`'s death tween is gone — the bridge now only schedules the view despawn 0.6s later. The last code-animated reaction is editor-owned.
- Battle scars: the open editor resaved `player.tscn` mid-surgery (uid attrs, reordered blocks, dropped `active`/`states/defeat`) — repaired surgically; and .tscn sub_resources must be DEFINED before referenced — the defeat Animation initially landed after the AnimationLibrary that referenced it, failing parse on 5 scenes; fixed by reordering. Lesson recorded: close the editor before batch scene surgery.
- Suite additions: defeat clip + AudioPlayer assertions on all 5 actor scenes. All 6 suites green, import clean, render clean.

## Structured Sound (Buses + SfxManager) - 2026-07-28

- Rule + workflow first, per owner request: CLAUDE.md's ECS map gains the three-layer sound law (motion sounds → clip audio tracks; mixing → bus layout; event sounds → SfxManager registry via the bridge; systems never play audio), and `/new-sound` is a reusable recipe in `.claude/commands/`.
- Layer 2 built: `default_bus_layout.tres` (Master ← SFX/Music/UI) wired in project.godot; all five actor `AudioPlayer`s route to the SFX bus — group volume/effects are now one Inspector away.
- Layer 3 built: `SfxManager` autoload (`objects/audio/sfx_manager.tscn` + `scripts/audio/sfx_manager.gd`) — a pool of 8 reusable players (research-recommended: no cut-offs, no per-shot node churn, sounds can't die with a freed node) with an editor-owned `streams` Dictionary registry. Three new generated event sounds: pickup_chime, room_clear (victory arpeggio), defeat_jingle (sagging notes).
- Bridge hookups in main.gd: pickup_taken → pickup chime, room complete → clear arpeggio, hero defeat → jingle; all via a null-safe `/root/SfxManager` lookup so headless tests without autoloads stay silent.
- Gotcha: on the first import pass the SfxManager scene parsed before the new WAVs were imported (one-time "Failed loading resource" noise); the second pass is clean — expected first-scan ordering, not a defect.
- Suite additions: bus layout loads; SfxManager registry carries the three event sounds and routes to SFX. All 6 suites green, import clean, render clean.

## Music on the Music Bus - 2026-07-28

- The empty Music bus gets its first content, structure-first: a `MusicPlayer` AudioStreamPlayer node in `scenes/main.tscn` (autoplay, bus `Music`, -8 dB) — zero code, the scene owns the soundtrack the same way clips own motion sounds.
- Placeholder track: `tools/generate_music.py` → `assets/music/unbound_march.wav`, a 17s A-minor chiptune march (triangle bass eighths, 25%-duty square lead over Am-F-C-G, offbeat noise hats). The WAV embeds a `smpl` loop chunk over the whole file, so Godot's default "Detect From WAV" import yields a seamless `LOOP_FORWARD` stream with no import-dock tweaking. Real music ships by dropping a file over the same path.
- Suite additions: main scene carries an autoplaying MusicPlayer, routed to Music, stream loops from its embedded WAV loop points. All 6 suites green, import clean.

## Demo Posture + macOS Export - 2026-07-28

- Debug overlay demoted from hardcoded `true` to an Inspector checkbox on the Main scene root (`@export var debug_enabled := false` in main.gd); boot pushes it to the board so the scene is the single switch, F3 still toggles live.
- Real-game window: fullscreen at boot (`window/size/mode=3`), aspect-preserving letterbox over the 640x360 viewport (`stretch/aspect="keep"`), F11 drops to windowed, hero pawn is the project icon.
- macOS export works end to end: official 4.6.3 templates installed to `~/Library/Application Support/Godot/export_templates/4.6.3.stable`; `export_presets.cfg` (gitignored per convention — local file, recreate from this recipe if lost: macOS preset, ad-hoc codesign, notarization off, universal arch, export_path `build/TheUnboundPawn.zip`); ETC2/ASTC VRAM compression enabled in project.godot (hard requirement for arm64/universal export). Export: `Godot --headless --path . --export-release "macOS" build/TheUnboundPawn.zip` with the real $HOME (templates live there). Verified: 74MB zip, universal Mach-O, boots and quits clean.
- Suite additions: debug ships off, window ships fullscreen. All 6 suites green.

## The World Exists: Two Zones + Travel (map phase 1) - 2026-07-28

- Research first (FromSoft loops recap + top-down transition patterns): fade-swap chosen because zone palettes differ (Waking Cloak devlog rationale); exits are explicit destination markers, not direction math (the "Mario pipe" problem); full digest + file-by-file plan in `docs/map-build-plan.md`. Subagent runner was broken all session (bad "medium" model alias) — research ran inline.
- The world is data: `resources/world/world_graph.tres` (zone id → scene, one entry per zone), zone scenes are RoomEncounter + new exports (`zone_id`, `board_size`) + `ZoneEntryMarker`/`ZoneExitMarker` children. EcsBoot sizes the grid per zone, bakes door cells into `EcsGrid.exit_by_cell`, and skips taken pickups.
- MovementSystem emits `zone_exit` when the PLAYER lands on a door cell (systems decide); main.gd is now also the ZoneDirector: fade out (editor-owned FadeLayer rect, bridge only tweens alpha), swap the zone node, rebuild the whole EcsWorld (`_boot_zone`), place the player on the entry marker, fade in. Only the player view node and WorldState survive a swap.
- `WorldState` autoload (pure data): current zone, last entry, health carry (travel keeps hp; death clears it → full-heal zone reset), taken pickups by stable "zone/MarkerName" id. Death/R reload lands in the CURRENT zone via WorldState, not the authored default.
- Two authored zones per the drawn design: the Toybox Yard (20×11, teach sequence: lone recruit → ambush pair → armed pawn + spear → backstep pawn corridor, clock-tower landmark) and the Chalk Gardens (24×12, charging pawns in lanes, inkwell plaza). Two new data-only pawn variants: `backstep_pawn` (fast, keeps distance 3, pounces) and `charging_pawn` (only ±2 leaps — the knight-offset machinery already supported it). `tools/paint_zone_tilemaps.gd` greyboxes both tilemaps (border walls with door gaps ARE the collision).
- World mode silences the clear-all win screen (only explicit objectives end a run — boss arenas later). first_encounter.tscn stays untouched as the standalone demo room.
- New suite: zone_travel_runtime_test (bounds per zone, door bake, zone_exit event + destination, pickup-skip, both directions). run_tests: world-graph validation — every zone instantiates, ids match, every door targets a real zone AND a real entry marker. All 7 suites green; live boot clean.

## The Loop Closes: Gates, the Bookshelf Pass, Save-to-Disk (map phase 2) - 2026-07-28

- One-way shortcut gates, grid-native: a `GateMarker` cell is solid until the PLAYER pushes into it moving in its `opens_from` direction — then it opens forever. No interact button: walking into it from the far side IS the interaction; from the near side it is a wall. MovementSystem decides (`_try_open_gate` → `gate_opened` event), EcsBoot bakes (`gate_by_cell`, skipping WorldState-opened ids), the bridge persists + hides the marker's closed-gate visual + plays the new `gate_open` sfx.
- The DS1 loop exists: Toybox Yard → Chalk Gardens (north) → Bookshelf Pass (east) → interior fight → push the `pass_home_gate` from behind → gated corridor → home door drops you ten steps from where you started. From the yard side the pocket is enterable but the gate refuses — exactly the Firelink moment, miniaturized.
- Third zone authored: the Bookshelf Pass (22×10, shelf-aisle walls, leaning-book landmark, backstep pawns + armed pawn, ruler-blade treasure at the far corner). Yard and Gardens gained east doors; all three tilemaps repainted (`tools/paint_zone_tilemaps.gd` now owns three layouts incl. the gated corridor geometry).
- WorldState saves to disk (`user://world_state.cfg`, ConfigFile): zone, entry, taken pickups, opened gates. Saved on travel/pickup/gate/death; loaded by the autoload at launch — the world resumes across app restarts. Health deliberately never saves (each launch starts the current zone fresh).
- Suite: zone_travel gains the gate trilogy (starts blocked / wrong side stays wall / right side opens + named event + never respawns blocked); run_tests gains the WorldState save-load round trip and the fourth registry sound. All 7 suites green; live boot clean.

## World v3: the Semi-Open Kingdom - 2026-07-29

- Owner verdict on v2: door-connected rectangles read as Enter the Gungeon rooms, not a soulslike world. Redesigned the MAP SYSTEM: one continuous 72×40 board (the Kingdom) — districts are carved geography (disks + winding paths out of solid rock, nothing rectangular), the camera scrolls the whole land, landmarks are visible across regions, and travel is walking, not door-teleports. HLD/DS structure on the existing engine.
- New generator: `tools/paint_zone_tilemaps.gd` carves the world (DISKS/PATHS/EXTRA_ROCK/LANDMARKS consts) and SELF-VALIDATES — BFS from the spawn must reach all carved cells or the build fails. 689 open cells, single component, first try.
- The enabling system change: the aggro leash. `DecisionConfig.aggro_radius` (default 7) + an OBSERVE-state check in EnemyAISystem — enemies beyond the radius stand idle, mid-swing states always finish. Without it, one big map means seventeen simultaneous hunters.
- Districts survive as geography, not scenes: cemetery yard SW (spawn treasure behind you, hills + warned pockets), the Stable arena as a pillared chokepoint on the only road north, the White Court plateau (nothing spawns within its aggro bubble = naturally safe hub), the Gardens fields with hedges, the Bookshelf halls with ridge aisles, a treasure nook at the world's east edge. Both one-way gates live on in carved corridors (gardens shortcut, pass home corridor).
- Zone-travel machinery KEPT (future interiors/boss seals) — the kingdom is simply the only zone; a synthetic injected door keeps MovementSystem's exit path covered in CI. Old five zone scenes + tilemaps deleted; old saves fall back gracefully to the authored default.
- Suite: kingdom census (17 inhabitants, 5 treasures, 2 gates), both gates' one-way trilogies, leash calm/wake probes (far enemy never stirs, distance-8 enemy idles, adjacent enemy wakes), injected-door zone_exit. ecs_enemy pursuit spec now starts inside the leash. All 7 suites green; live boot clean.

## The Kingdom Wears the Playground - 2026-07-29

- Owner correction: the world must look like the child's playground THEY designed, not throne-room marble. New atlas `assets/tiles/playground_world_tiles.svg` in the owner's exact language — their two original floor tiles copied verbatim (wood #7f5f51 / sand #c9a77d, crayon outlines, hand-scratches), plus chalk-road (white chalk squiggle on sand), grass mat (garden lawns), toy-block wall (stacked crayon red/blue/yellow blocks = the solid rock), and a block-tower-with-flag landmark prop.
- `resources/tiles/playground_world_tileset.tres` mirrors the kingdom tileset format (solid custom data on wall + landmark); the carve tool now paints with it and remembers WHAT carved each cell: district disks = the owner's checker, garden disks = grass, road-only cells = chalk lines — the roads between districts literally read as chalk drawn on the ground.
- Owner's original `playground_tileset.tres`/`playground_tiles.svg` untouched; kingdom (throne) tileset stays for the first_encounter demo room. All 7 suites green (toy blocks still block — solid data verified by boot tests); live screenshot approved-pending: ART DIRECTION IS OWNER-OWNED, this is the hand-off pass.

## World v2: the DS3 Opening Skeleton - 2026-07-29

- Owner verdict: three zones too simple. Researched DS3's opening (Cemetery of Ash road to Iudex, Firelink hub, High Wall loops) and rebuilt the world as five zones on that skeleton — tutorial cemetery (item behind spawn, fountain landmark, soft branch + warned hard pocket), boss-gate arena (Stable Gate, armed Wardens holding the Knight's future chamber), safe three-door hub (White Court), four-court looping level with an internal one-way shortcut (Chalk Gardens = High Wall), and the Bookshelf Pass now looping one-way back to the HUB, not the yard.
- All content-layer work: paint-tool layouts ×5, zone scenes (3 reworked, 2 new), world graph, hero start. Zero engine/system changes — the phase-1/2 machinery absorbed a full world rebuild as pure data, which was the point of building it that way.
- Suite: door-graph validation now covers 12 doors/5 zones automatically; zone_travel updated to the new geometry (gate moved to (2,9), Gardens 28×14, Yard 24×13, hub safety + triple doors asserted). Size floor relaxed to arena-size (the Stable Gate is deliberately 12×9). All 7 suites green; live boot clean.

## The Book of House Rules - 2026-07-28

- The game's compendium/lore/tutorial object, all data: `RuleEntry` .tres (piece_id + title + original chess rule + amendment + flavor) collected by `resources/rules/rule_book.tres` (`RuleBook`). Five pages authored: the first law, armed/backstep/charging pawns, and the knight (ships locked — its piece never walks the world zones yet, proving the unread-ink state).
- Unlock = first meeting: booting a zone writes a page for every EnemyDefinition present ("sharing a zone" is the meeting). Bridge-side (`_unlock_met_rules`), persisted in WorldState (`unlocked_rule_ids`, saved to disk), status line announces "[B]".
- UI: `scenes/ui/rule_book.tscn` (CanvasLayer panel: entry list + page detail, locked rows say "Unread ink") driven by presentation-only `RuleBookUI`. B toggles; player control pauses while reading. Node lookups are lazy, not @onready — headless tests drive refresh() without a frame loop (the @onready version hung the suite; same _init/_ready lesson as before).
- Suite: every book page must name a real EnemyDefinition id (a typo'd piece_id fails CI); UI renders all pages, counts known amendments, keeps unmet pages as unread ink. All 7 suites green; live boot clean.

## The Map Reads as a Kingdom - 2026-07-29

- Owner verdict on the semi-open world: "too anotony". Diagnosis was two-part and structural, not decorative — every carved cell wore the same wood/sand checker, and every uncarved cell in the 72×40 board wore the same toy-block wall, so a castle, a village and a library were the same picture with different outlines.
- Tile vocabulary grown 6 → 19 (`assets/tiles/playground_world_tiles.svg`, +`resources/tiles/playground_world_tileset.tres`): cobble courtyard, throne carpet, marble hall, library boards, rampart, wall tower, hedge, bookshelf, moat water, banner wall, cottage, plus two alternate toy-block stackings. All still crayon/toy-block material language — a kingdom built by a child out of the same box.
- `tools/paint_zone_tilemaps.gd` rewritten around DISTRICTS: 10 anchors (village, hills, pocket, muster yard, keep, two gardens, two library wings, high tower) own cells by nearest-anchor, and a district skins BOTH its floor and the rock facing it. Man-made places are rectangles (HALLS), nature stays organic disks (BOWLS) — the shape itself now says whether people built it.
- Solid decoration (curtain wall x=24, keep ring, library ring, moat, tower studs every 6) is painted ONLY over cells that are already rock. It therefore cannot break connectivity by construction: where a road crosses a wall line the gap self-forms and reads as a gatehouse or causeway. No hand-placed doorways to keep in sync.
- Two anti-monotony rules with teeth: `DISTRICT_ROCK_DEPTH = 6` (district rock only dresses the 6-cell facing; deeper fields fall back to raw blocks, so a quadrant of unreachable hedge can't happen) and `DEEP_ROCK_MIX` picked by `_cell_hash(cell)` — deterministic, so the same build always paints the same field, but the block plain no longer tiles visibly. Cottages are L-shapes and singles, not 2×2 grids that read as a spreadsheet.
- Validation kept its teeth: BFS from spawn must reach every open cell, and all 25 gameplay cells from `the_kingdom.tscn` (spawn + 17 enemies + 5 pickups + 2 gates) must be clear or the build fails. Result: `KINGDOM TILEMAP: OK (657 open cells, all reachable, 25 spawn cells clear)`.
- Verified: run_tests 0 failures, all 6 runtime suites PASS, `--editor --quit` import clean, `git diff --check` clean, and rendered frames inspected at village/keep/deep-field. ART DIRECTION IS OWNER-OWNED — this is a hand-off pass, not a final look.

## The Hero Wakes Up - 2026-07-29

- Owner asked for two things: to SEE the kingdom, and a wakeup animation. The map view needed no new code — `tools/render_kingdom_map.gd` already fits all 72×40 cells into the captured frame (project viewport is 640×360 and `--write-movie` captures at 2×, so `zoom = 640/2304 = 0.278` fills 1280×720 exactly). Rendered and reviewed: keep + moat centre, library east, courtyard west of the keep, village SW, hedge wilds, block-noise deep field.
- The wake animation is **pure data — zero script changes**, because the boot pose belongs to the state graph, not to code. `player.tscn` gains a 1.25s `wake` clip and a `wake` state, and the graph's `Start` edge moves from `idle` to `wake`. The hero view is instantiated exactly once (`scenes/main.tscn`, a parked ActorView baked by `EcsBoot`), so that edge fires once at boot and never again — no ViewSync edge, no new condition, no gameplay lock.
- The clip reads as coming to: SpriteRoot rotation −90° (flat on the ground, pivoting at the pawn's feet) → a twitch at 0.12s → still → a shove up that overshoots past upright → a squash/stretch wobble → settled at 0.0. An audio track on the clip fires the new `wake_stir.wav` at 0.3s (the shove), obeying the sound law: motion sound lives inside the clip, keyed on the actor's own `AudioPlayer`.
- Every transition out of `wake` REUSES an existing sub-resource rather than duplicating tuning: `T_recover` (AtEnd + Auto) drops wake → idle by itself, `T_to_step` (`moving` condition) lets an impatient player cut the wake short, `T_travel` lets hurt/attack/defeat interrupt. `Animation_reset` gained a rotation track so the editor's RESET restores the pawn upright instead of leaving it face-down.
- New SFX generator `wake_stir()` in `tools/generate_sfx.py`: a filtered noise rustle whose cutoff OPENS as it swells (so it reads as waking, not settling) into two rising notes (G4 → D5).
- Suite: the hero must own a `wake` clip AND the graph's `Start` edge must point at it (`_graph_starts_in`) — a clip that exists but is never entered now fails CI. run_tests 0 failures, all 6 runtime suites PASS, import clean, `git diff --check` clean, and the live boot captured at 24fps was inspected frame by frame (flat → mid-rise → upright). ART DIRECTION IS OWNER-OWNED — hand-off pass.

## The Pawn Family Ships as Pixels - 2026-08-03

- Owner asked to export the approved piece forms and save them. The art language had lived only in throwaway preview widgets across ~23 correction rounds; it is now source code in the repo, so the look is reproducible instead of remembered.
- New `tools/generate_chess_sprites.gd` (`extends SceneTree`, headless, Godot's own `Image`/`save_png` — no new dependency, nothing hand-painted). It bakes 4 pieces x 6 telegraph states + one 6-frame strip per piece + a manifest: 28 files in `assets/sprites/generated/chess/`.
- The four forms are the pawn family the demo needs: PAWN (18x20), DOUBLE_STEP (18x21, the approved special power, navy + red band), PROMOTED (18x23, the Sag mini-boss), KNIGHT (24x30, the first boss and the tallest thing on the board). The six states are IDLE / SPOTTED / WIND-UP / COMMIT / HURT / DOWN — the combat states the ECS already runs, so intent is readable with the HUD off.
- Geometry is data, not drawing. Bodies are lathe rows (one radius per row, mirrored); a material name on a row swaps that row's palette, which is how every collar, gold belt and the double-step's red band exists — none is painted on top. Only the knight's head and the promoted's cross are hand-authored spans, because they are asymmetric.
- Two rules that make the pixels read: shading is three FLAT bands off each row's own centre (no gradient, no dither, no fourth stop), and the near-black ring is dilated OUTSIDE the body so adding an outline never shrinks the silhouette — which is why a frame is width+2 and the manifest records `anchor_row = height-3`, the row that must land on the CELL CENTRE (feet on the centre, not the bottom edge).
- Verified: generator runs clean headless, `--editor --quit` produced all 28 `.import` files with no errors, and every sprite was inspected at 9x on a contact sheet. `project.godot` already sets `default_texture_filter=0` (Nearest), so no per-file import override is needed. No scene, tilemap or ECS file was touched. ART DIRECTION IS OWNER-OWNED.

## The Knight's Silhouette Is Traced, Not Drawn - 2026-08-04

- Correction to the entry above: the knight it describes (24x30, gold) was rejected. The owner asked for a full-black piece shaped like a real chess knight, then rejected four more hand-authored silhouettes in a row ("that shape looks weird", "even worse"). Every one of those revisions failed the same way, because every one was typed from memory of a reference image instead of measured off a real one.
- The fix was a change of method, not another guess. New `tools/trace_knight_glyph.py` renders U+265E (BLACK CHESS KNIGHT) from Apple Symbols at 900pt, crops it to its own bounding box, scales that box uniformly to 21 rows, and reports the leftmost and rightmost filled block of each row. Those two arrays are `KNIGHT_FRONT` / `KNIGHT_BACK` in the generator verbatim. The ear, the brow, the muzzle taper and the throat cut are the typeface designer's proportions.
- Interior holes need no filling and no scipy: taking a row's min and max filled column spans straight across them, which is exactly what a solid silhouette wants. Font matters — Apple Symbols cuts a clean single-eared head, Arial Unicode adds mane strands, Times New Roman has no glyph at all and renders tofu.
- The traced neck is 14 blocks across sitting in x 6..19, so the pedestal had to grow to carry it: knight width 22 -> 24, frame 24x32 with the outline ring, `anchor_row` 29. The pawn, double-step and promoted are byte-identical — "keep the design of the pawn" held through every revision.
- The generator's doc comment now forbids hand-editing a single row: to change the shape, retrace and paste both arrays wholesale. That is the guard against this loop happening again.
- Verified: `tools/trace_knight_glyph.py` re-emits the exact arrays that are in the generator, generator runs clean headless (4 pieces x 6 states), `--editor --quit` exit 0, `TESTS COMPLETE: 0 failure(s)`, all six runtime tests PASS, `git diff --check` clean. Owner reviewed the result and said keep it. No scene, tilemap or ECS file was touched.

## Production checklist added - 2026-09-29

- Added `docs/production-checklist.md` as the professional gate-based production checklist.
- Owner rule captured: plan small part, get approval, implement only that part, verify, owner reviews in Godot, then move on.
- No room implementation started. Next gate is M0.4: confirm first room production order.

## Gameplay research and parallel production lanes - 2026-09-29

- Researched recent/relevant gameplay references for real-time grid action, tactical telegraphs, weapon rhythm, and childlike physical-world adventure.
- Added `docs/design/gameplay-reference-research.md`.
- Updated `docs/production-checklist.md` with the Parallel Production Rule, lane board, and Milestone G for General Gameplay Design.
- No implementation started. Next gates are M0.4, M0.5, and G0.2.

## Full gameplay design V2 - 2026-09-29

- Added `docs/design/full-gameplay-design-v2.md` with a complete start-to-end gameplay design, Mermaid graphs, ASCII room/world drawings, boss progression, unlock arc, child intervention arc, risks, and vertical-slice recommendation.
- Updated `docs/production-checklist.md` so G0.2 now tracks approval of the full gameplay design V2.
- No implementation started. This is pending owner review.

## Game production aspects checklist - 2026-09-29

- Added `docs/game-production-aspects-checklist.md`, a discipline-by-discipline checklist for gameplay, level design, enemy/boss design, art direction, animation, VFX, audio, UI/UX, narrative, technical architecture, tools, QA, and release.
- Linked the aspects checklist from `docs/production-checklist.md`.
- This supports parallel production while preserving plan/approval/review gates per task.

## Clarified aspects checklist as parallel lanes - 2026-09-29

- Owner correctly pointed out the aspects checklist still looked sequential because headings were numbered and the bottom used priority numbers.
- Updated `docs/game-production-aspects-checklist.md`: removed numbered lane headings, added a parallel lane dashboard, clarified IDs are labels not order, and replaced Current Parallel Priorities with Current Active Parallel Gates.
- Production model is now explicit: all disciplines can move together, but each task still requires its own approval gate.

## Production aspect specs added - 2026-09-29

- Owner clarified that checklists are not enough: every aspect needs a completion spec and hard requirements.
- Added `docs/game-production-aspect-specs.md` defining purpose, required deliverables, completion requirements, and cannot-complete conditions for each lane: gameplay, level/world, enemy/boss, art, animation, VFX, audio, UI/UX, narrative, technical, tools, QA, and release.
- Linked the spec from `docs/game-production-aspects-checklist.md` and `docs/production-checklist.md`.
- From now on, no aspect can be marked accepted unless it satisfies its spec.

## GP.1 + LD.2 draft spec - 2026-09-29

- Added `docs/design/gp1-ld2-core-loop-first-chain-spec.md` as the combined approval spec for the core gameplay loop and first playable room chain.
- Linked GP.1 and LD.2 in `docs/game-production-aspects-checklist.md` to that spec.
- Status remains planning/draft. Nothing is approved or implemented until owner review.

## ART.1 TECH.2 NAR.1 draft specs - 2026-09-29

- Added `docs/design/art1-visual-target-spec.md` for the visual target lock gate.
- Added `docs/design/tech2-room-transition-system-spec.md` for the room transition architecture gate.
- Added `docs/design/nar1-story-outline-spec.md` for the story outline gate.
- Updated `docs/game-production-aspects-checklist.md` so ART.1, TECH.2, and NAR.1 point to their draft specs.
- These specs are pending owner review; no implementation started.

## Expanded first-gate specs across production lanes - 2026-09-29

- Added draft specs for EN.1, AN.1, FX.1, AU.1, UI.1, TOOL.2, and QA.1 under `docs/design/`.
- Updated `docs/game-production-aspects-checklist.md` so those gates now point to their spec files and are marked planning.
- These are review specs only; no implementation started.

## Foundation second-layer specs - 2026-09-29

- Added draft specs for LD.1 bedroom world layout, LD.3 room template, ART.2 tile palette list, GP.2 movement feel, GP.3 basic sword combat, and TECH.4 gameplay sandbox.
- Updated `docs/game-production-aspects-checklist.md` so those gates point to the spec files and are marked planning.
- Still no implementation started; this is expanding the reviewable planning set.

## Gameplay and level design planning specs filled - 2026-09-29

- Added draft specs for GP.4 skill system, GP.5 child intervention, GP.6 failure/checkpoints, GP.7 progression pacing.
- Added draft specs for LD.4 room formula, LD.5 Chess Rug Hub, LD.6 district layout plans, LD.7 shortcuts and locks.
- Updated `docs/game-production-aspects-checklist.md` so those rows point to their spec files and are marked planning.
- Still planning-only; no implementation started.

## Enemy and boss planning specs filled - 2026-09-29

- Added draft specs for EN.2 Knight, EN.3 Bishop, EN.4 Rook, EN.5 Queen, EN.6 King, and EN.7 encounter recipes.
- Updated `docs/game-production-aspects-checklist.md` so every enemy/boss row points to a spec file and is marked planning.
- Enemy lane is now fully spec-drafted; still pending owner review and not implemented.

## Art and animation planning specs filled - 2026-09-29

- Added ART.3-ART.7 draft specs for district art targets, character sprite list, prop list, readability audit, and final polish pass.
- Added AN.2-AN.6 draft specs for enemy animations, boss animation plans, weapon animations, child intervention animation, and AnimationTree QA.
- Updated `docs/game-production-aspects-checklist.md` so art and animation rows point to spec files and are marked planning.
- Still planning-only; no implementation started.

## VFX audio UI narrative specs filled - 2026-09-29

- Added draft specs for FX.2-FX.6, AU.2-AU.6, UI.2-UI.6, and NAR.2-NAR.6 under `docs/design/`.
- Updated `docs/game-production-aspects-checklist.md` so those rows point to spec files and are marked planning.
- Remaining unplanned areas are mainly technical support, tools/workflow, QA, and release. No implementation started.

## Full production aspects board spec-backed - 2026-09-29

- Added final support/release planning specs: TECH.3, TECH.5, TECH.6, TOOL.3-TOOL.5, QA.2-QA.5, REL.1-REL.5.
- Updated `docs/game-production-aspects-checklist.md` so every production row now points to a spec file or accepted existing gate; no actionable row remains `not_started`.
- Verified with `rg`: only the status-key definition contains `not_started`.
- There are now 76 `*-spec.md` files under `docs/design/`.
- Planning coverage is complete at the aspect/spec level; next step is owner review/approval of specs before implementation.

## Production review dashboard added - 2026-09-29

- Added `docs/production-review-dashboard.md` to group all specs into review batches instead of asking the owner to approve every spec blindly.
- Linked the dashboard from `docs/production-checklist.md`.
- Recommended next gate is Batch 1: GP.1, LD.2, LD.1, ART.1, NAR.1, TECH.2.
- If Batch 1 is approved, next task is to create the `T1_WhiteKingsFall` production spec.

## Batch 1 foundation review package - 2026-09-29

- Added `docs/review-batch-1-foundation.md`, a single owner-facing approval package for GP.1, LD.2, LD.1, ART.1, NAR.1, and TECH.2.
- Linked it from `docs/production-review-dashboard.md`.
- Next owner decision: approve/revise Batch 1. If approved, next task is `T1_WhiteKingsFall` production spec.

## Batch 2 first playable feel review package - 2026-09-29

- Added `docs/review-batch-2-first-playable-feel.md`, a single owner-facing approval package for GP.2, GP.3, EN.1, FX.1, FX.2, AU.2, and UI.1.
- Linked it from `docs/production-review-dashboard.md`.
- If Batch 1 and Batch 2 are approved, next likely planning task is the gameplay sandbox production spec.

## Batch 3 first chain production rules review package - 2026-09-29

- Added `docs/review-batch-3-first-chain-production-rules.md`, a single owner-facing approval package for LD.3, ART.2, TOOL.2, TOOL.3, TOOL.4, QA.1, and QA.2.
- Linked it from `docs/production-review-dashboard.md`.
- If Batches 1-3 are approved, first concrete production planning can start with `T1_WhiteKingsFall` production spec.

## Batch 4 vertical slice expansion review package - 2026-09-29

- Added `docs/review-batch-4-vertical-slice-expansion.md`, a single owner-facing approval package for LD.4, LD.5, LD.6, LD.7, EN.2, GP.7, and QA.5.
- Linked it from `docs/production-review-dashboard.md`.
- Batch 4 defines the first demo expansion: Chess Rug Hub -> Toybox Knight district -> Knight Captain -> Rule Step -> return to hub.

## Batch 5 full game expansion review package - 2026-09-29

- Added `docs/review-batch-5-full-game-expansion.md`, a single owner-facing approval package for the remaining full-game lanes.
- Linked it from `docs/production-review-dashboard.md`.
- Batch 5 defines long-term guardrails for later bosses, advanced skills, child intervention, full art/animation/VFX/audio/UI/narrative work, technical support, QA, and release preparation.
- Still planning-only; no Godot implementation started.

## Production approval board added - 2026-09-29

- Added `docs/production-approval-board.md` to separate owner approval state from implementation progress.
- Linked it from `docs/production-checklist.md` and `docs/production-review-dashboard.md`.
- The board lists all five review batches, dependencies, unlocks, owner review questions, and the approval command format.
- Current state remains: no batch is approved, and no new Godot implementation should start until the owner approves the relevant batch or task.

## Active plan realigned to approval workflow - 2026-09-29

- Updated `task_plan.md` with a current production-planning overlay before the historical implementation plan.
- The root plan now states that the project is in owner-review planning, lists the active planning files, shows all five batches as draft, and names Batch 1 review as the next owner-facing step.
- Updated `docs/production-checklist.md` with the active five-batch approval path and linked approval board.
- Verified edited files with `git diff --check`.

## Owner review template added - 2026-09-29

- Added `docs/owner-review-template.md` with structured forms for design review, editor scene review, gameplay feel review, art/animation review, audio review, and final approval wording.
- Linked the template from `docs/production-approval-board.md`, `docs/production-checklist.md`, and `docs/design/tool5-review-checklist-template-spec.md`.
- Expanded TOOL.5 completion requirements so feedback must identify approve/revise/block/accept decisions clearly.

## Batch 1 approved and T1 room spec drafted - 2026-09-30

- Owner approved Batch 1 Foundation after reviewing the active recommendation.
- Marked Batch 1 approved in `docs/review-batch-1-foundation.md`, `docs/production-approval-board.md`, and `docs/production-review-dashboard.md`.
- Marked Batch 1 gates approved: GP.1, LD.2, LD.1, ART.1, NAR.1, and TECH.2.
- Added `docs/production/t1-white-kings-fall-production-spec.md` as the next owner-review room spec.
- Updated `task_plan.md` and `docs/production-checklist.md` so the next step is review of the T1 spec, not implementation.
- Cleaned stale "Batch 1 is still draft" guidance in the GP.1/LD.2 spec and review dashboard.
- No Godot scene implementation started.

## Act 1 flow and kid-room map drafted - 2026-09-30

- Owner clarified the game should be split into acts, with Batch 1's foundation informing Act 1.
- Added `docs/production/act-1-opening-to-knight-boss-flow-map.md`.
- The Act 1 draft covers the full player route from White King's fall through Knight Captain, using a kid-room logical layout: chess rug hub, nearby toybox first district, visible future bedroom routes, and Rule Step as first boss reward.
- Updated `task_plan.md`, `docs/production-checklist.md`, and `docs/production-approval-board.md` so Act 1 flow review is now part of the owner-facing planning path.
- No Godot scene implementation started.

## Act 1 revised to end before Toybox - 2026-09-30

- Owner clarified that Toybox should not be part of Act 1. Act 1 needs its own tutorial arc and small boss first, similar to an action-adventure opening before the first major district.
- Replaced `docs/production/act-1-opening-to-knight-boss-flow-map.md` with `docs/production/act-1-opening-to-first-boss-flow-map.md`.
- New Act 1 route: T1 White King's Fall -> T2 Fallen Sword Tile -> T3 First Pawn Clash -> T4 Broken Rule Yard -> B1 Black Pawn Captain -> H1 Chess Rug Hub Opens.
- Toybox/Knight Captain is now Act 2, with Rule Step kept as the Act 2/Knight reward instead of the tutorial boss reward.
- Updated `task_plan.md`, `docs/production-checklist.md`, and `docs/production-approval-board.md` to point at the revised Act 1 plan.
- No Godot scene implementation started.

## T1 White King's Fall initial build started - 2026-09-30

- Owner asked to redesign and start building.
- Marked the revised Act 1 flow and T1 production spec approved for the initial build.
- Added editable room scene `scenes/rooms/t1_white_kings_fall.tscn`.
- Registered `t1_white_kings_fall` in `resources/world/world_graph.tres`.
- Updated `scenes/main.tscn` so the game starts in T1 with the pawn parked at the approved starting cell.
- T1 currently contains scene-owned TileMap, grid overlay, set dressing props, entry markers, and a future exit marker toward T2.

## Owner directions and gate OG0 — 2026-10-12 (recorded verbatim)

Owner's words in chat (Vietnamese, as typed), with the translation used by the plan:

1. "game không phải mỗi gameplay mà phải kể 1 câu chuyện ... tôi chỉ muốn bạn dựng 1 cái base đẩy đủ tất cả, còn lại tôi sẽ vẽ và nâng cấp story, bạn tính có làm được cho nó hoàn hảo nhất có thể trước khi tôi nhảy vào hay không? nghiên cứu về cảm xúc con người khi chơi game nữa nhé, tôi tin bạn"
   — build one complete base with everything; the owner draws the art and upgrades the story; research player emotion.
2. "gameplay cũng phải có lộ trình tăng tiến rồi kĩ năng đàng hoàng nhé, sau đó nhớ là sắp xếp code và folder một cách mà tôi có thể nhảy vào xử lý mà không phải thay đổi quá nhiều trước hết là dựa theo ecs design pattern"
   — a real progression and skill system; code and folders arranged ECS-first so the owner changes little.

Plan built from these: `docs/game-base-plan.md` v1.1 (commit f96a12c).

Gate OG0 answers (owner picked each option in chat, 2026-10-12):

| Question | Owner's answer |
| --- | --- |
| Move all code and folders to the ECS tree (content/, ecs/, schema/, authoring/, presentation/, shell/) and amend CLAUDE.md "Folder ownership" to match; tag pre-restructure exists | "Đồng ý" (agree) — M1b may run; the CLAUDE.md amendments of plan §2.4 apply when M1b lands the paths |
| Controls and rules (plan §2.3 T-1, T-3, T-8): R = call child (restart moves to the pause menu), Q locked until the T4 pencil pickup, movement lock while swinging, input buffer expiry; drop aim time-slow, Gentle Nudge, Rest Squares | "Đồng ý hết" (agree to all) |
| Source language of the story | "Tiếng Anh, Việt sau" — English source, Vietnamese column later |
| Cleared rooms on return (plan §2.3 T-5, reverses the 2026-07-28 Souls respawn rule) | "Giữ sạch" — cleared rooms stay cleared |

Tag `pre-restructure` (f96a12c) marks the last commit before the restructure.

## M1a Safety net and tooling - 2026-10-12

Milestone M1a of `docs/game-base-plan.md` (no gameplay change, no file moved). Five lanes built it in
separate worktrees and the integrator merged them on `base/m1a`.

- Harness: `UnboundTest` (watchdog, no vacuous pass), `TestPaths`, `tools/run_all_tests.py` (import pass,
  every suite as its own bounded process, baseline-label check), `tests/baseline_labels.txt` (235 labels from
  the seven original suites), `tests/label_renames.txt`, `docs/requirements_ledger.md` and its test.
  `/verify` now runs `python3 tools/run_all_tests.py --strict` and `git diff --check`.
- Bridge: five characterization suites in `tests/bridge/` that pin `scripts/main.gd` as it is today
  (zone travel, health carry, death and restart, persistence of pickups/gates/unlocks, the Book), so the
  M3b split can be checked against them.
- Tools: `bootstrap_worktree.sh`, `stamp_uids.gd` (+ `--check`), `move_res.py`, `dump_world.gd` with six
  room baselines (T1-T4, B1, H1), and three report-only architecture guards in `tests/architecture/`.
- Audio: `default_bus_layout.tres` now has Master as bus 0, then SFX, Music, UI, Voice; `test_audio_buses`.
- Docs: `ARCHITECTURE.md`, `coding-standards.md`, `AGENTS.md`, `README.md` and `.claude/commands/*`
  rewritten against the code; `restructure-plan.md` and the vault archived; `OWNER_GUIDE.md`,
  `claude-md-diff.md` (waits for gate OG0), `LICENSE`, `THIRD_PARTY_NOTICES.md`.
- Integration fix: the three report-only architecture guards printed no `PASS:` line, so the runner rejected
  them as having checked nothing; each now prints a PASS for its non-vacuity check.
- Verification on the merged tree: `python3 tools/run_all_tests.py --strict` is green (19 suites, 235 of 235
  baseline labels, 0 warnings); import pass has no `ERROR`/`Parse` line; `git diff --check` clean. A scratch
  copy stamped by `stamp_uids.gd` (49 headers + 213 `ext_resource` lines, 0 missing, one changed line per
  stamped line) stays green after an import pass.

### M1a review fixes - 2026-10-12

An independent review of `base/m1a` found no blocker; these are the fixes (branch `base/m1a-fix`, tag
`m1a-done` moved to its tip). Each was checked by breaking the thing it guards.

- **Every script is compiled by a test.** `tests/architecture/test_all_scripts_load.gd` loads each `.gd`
  outside `tests/fixtures/` (the import pass does not). A planted type error and a stale preload path passed
  the import pass silently and failed this suite.
- **The death test is no longer vacuous.** It plants a pending health carry before the fatal blow; deleting
  the reset from `main.gd` `_on_player_defeated` now fails two assertions (it failed none before).
- **The sidecar guard no longer prints `PASS (skipped)`** when git is unavailable; it fails and says why.
- **The 10 newer suites extend `UnboundTest`** (five bridge, audio, four architecture guards), with the main
  scene and audio folders resolved through `TestPaths`. Output was diffed before and after: labels unchanged.
- **The runner has a `--self-test`** (35 checks: hang kill of the whole process group, SCRIPT ERROR, FAIL
  line, missing verdict, vanished label, renames, discovery). Ten single-line weakenings of the runner were
  all caught. `/verify` runs it and `move_res.py --self-test` first.
- **Two legacy checks** (`actor views hold no logic at all`, `pickup visuals use Sprite2D nodes`) now also
  require a non-empty source, so a moved file fails them. Labels unchanged.
- **Ledger honesty.** New status `partial: <gap>`; rows 110, 235, 246, 247, 248 use it (the test rejects a
  partial row with no gap and prints the count). Rows 231 and 232 stay covered because the guide exists now.
- **`docs/design/room-authoring-guide.md` rewritten** against the ECS code (it also answers TOOL.3 and TOOL.4).
  `docs/room-generator*.md` were audited and kept: they document tools that still exist.
- `LICENSE` is a marked placeholder until the owner names the holder; `AGENTS.md` says M1a is done.
- **Not fixed, on purpose:** the five undecided dependency edges and `tests/architecture/allowed_edges.txt`
  (the owner or architect decides at OG0); the Tier B CI workflow file; the mixed commit trailers.
- Verification: `python3 tools/run_all_tests.py --strict` is green (20 suites, 235 of 235 baseline labels,
  0 warnings); both `--self-test` runs report 0 failures; `git diff --check` clean.

## M1b step 1 - uid stamp and generated output - 2026-10-12

First of four M1b steps (`docs/game-base-plan.md` 13.6, 15 "M1b"), branch `base/m1b-1` from `game-base`. No
gameplay change, no scene structure change, no code or content folder moved yet.

- **Stamp.** `tools/stamp_uids.gd` over the whole tree, committed alone: 54 files, 49 headers and 213
  `ext_resource` lines (251 total), 0 unresolved, one changed line per stamped line. Then
  `test_no_path_only_ext_resource` flipped to ENFORCING in its own commit (mutation check: one path-only line
  makes it fail and name the file).
- **Generated output.** `assets/sprites/generated/{chess,tiles,maps,rooms}` and `assets/art/piece_templates`
  moved to `assets/_generated/` with `tools/move_res.py` (log committed). Every generator constant, the two
  room scenes, `.gitignore` (now `assets/_generated/` only; the 12 tracked root sprites stay tracked), the
  READMEs and the authoring docs follow. The T1/T2 room-PNG uids changed with the path, so those two scene
  lines were re-pointed. `dump_t1`/`dump_t2` changed only by the texture path string; the other four dumps are
  byte-identical.
- **Tools that save scenes.** `paint_kingdom_tilemap`, `paint_zone_tilemaps` and `generate_playground_tilemap`
  now save through `tools/save_keeping_uids.gd` and stamp last; running each on the committed tree leaves only
  the random node `unique_id` in the diff. `generate_playground_tilemap` also stopped embedding a second copy of
  its tile set (it now references `playground_tileset.tres` like the tracked scene). The other generators write
  `.png`/`.wav`/`.json` only, so they never touch a scene. `tests/architecture/test_tools_keep_uids.gd` guards it.
- **Verification.** After each commit: `python3 tools/run_all_tests.py --strict` green (21 suites after the new
  guard, 235 of 235 baseline labels, 0 warnings), both `--self-test` runs 0 failures, `git diff --check` clean,
  `stamp_uids.gd --check` CLEAN. A real `git clone` of the branch plus `tools/bootstrap_worktree.sh` came out
  green with a clean `git status` and the room-PNG uids matching the scenes.
- **Not done here (later steps):** code and content folder moves, tracked-sprite move, `project.godot` paths,
  `CLAUDE.md` amendments, `test_sidecars_tracked` ENFORCING (it still reports), `task_plan.md` M1b row.

## M1b step 2 - the code moves - 2026-10-12

Second of four M1b steps, branch `base/m1b-2` from `base/m1b-1`. No gameplay change, no script body edited, no
`class_name` renamed, no scene changed except the `path=` text of `ext_resource` lines.

- **What moved.** All 51 scripts outside `tests/` and `tools/` left `scripts/` (which is gone) for the plan's
  code tree, plus the scenes that belong to them: `schema/{entity,attacks,world,feel}/`, `ecs/core/`,
  `ecs/components/ecs_components.gd`, `ecs/systems/{input,decide,move,act,resolve,view}/`, `authoring/` (the
  baker, `authoring/entity_components/`, `authoring/markers/`, `room_encounter`), `presentation/{views,ui/hud,
  ui/codex,audio,camera,board}/` and `shell/{game_root.gd/.tscn, save/world_state.gd}`. `project.godot`
  (`run/main_scene`, the `SfxManager` and `WorldState` autoloads) followed. Every move went through
  `tools/move_res.py`; the old-to-new table and the eleven judgement calls are in `docs/migration-notes.md`.
- **One commit per folder or coherent group** (19 move commits, leaf-first in the order of plan 13.6), the strict
  runner after each. The dump baselines changed in 85 lines in total and every change is only the `script=res://`
  path a moved script prints (proved line by line against the step-1 baselines).
- **EnemyIntent moved twice.** First put in `ecs/systems/decide/` (it is a `RefCounted`, not a Resource), then back
  to `schema/entity/` as the plan says: the dependency report showed the first placement adds a presentation to
  ecs/systems edge, because the board's F3 overlay and `game_root.gd` also name it. The report on the final tree
  equals the one printed on the step-1 tree (5 NOT ALLOWED edges, 1 documented exception).
- **Guards.** `test_dependency_edges.gd` dropped its `LEGACY_LAYER_RULES` table (a layer is the top folder) and now
  fails on a script outside the layer folders. `test_audio_buses.gd` scans every scene in the project instead of
  `scenes/` and `objects/` (they are being emptied), through the new `TestPaths.project_directory()`.
- **Verification.** `python3 tools/run_all_tests.py --strict` green after every commit (21 suites, 235 of 235
  baseline labels, 0 warnings, none renamed); both `--self-test` runs 0 failures; `stamp_uids.gd --check` CLEAN;
  `git diff --check` clean; a fresh `git clone` of the branch plus `tools/bootstrap_worktree.sh` came out green
  with a clean `git status`.
- **Not done here (later steps):** content and fixtures (`objects/actors`, tilemaps, `scenes/rooms`,
  `scenes/zones`, `resources/*`, the 12 tracked sprites), `CLAUDE.md` amendments and the prose docs (they still
  describe the old layout), `test_sidecars_tracked` ENFORCING (clean today: 96 `.gd`, 0 missing sidecars),
  `task_plan.md` M1b row.

## M1b step 3 - the content moves - 2026-10-12

Third of four M1b steps, branch `base/m1b-3` from `base/m1b-2`. No gameplay change, no scene changed except the
`path=` text of `ext_resource` lines, no `ResourceSaver` re-save, no uid changed.

- **What moved.** Everything under `resources/`, `objects/` and `scenes/`, the 12 tracked sprites of
  `assets/sprites/generated/`, the three tile atlases of `assets/tiles/` and `assets/art/pieces/`. The six Stage 1
  rooms are `content/rooms/<id>/room.tscn`; the seven enemies are `content/enemies/<id>/enemy.tres` with their own
  sub-resources beside them and the shared pawn pieces in `content/enemies/_shared/`; the world graph is
  `content/world/world.tres`; the Book pages are `content/rules/<id>/page.tres`; the difficulty profile is
  `content/difficulty/`; the player's pictures are `content/player/{body,icon}.png`; the sword and pencil attack
  profiles are `content/skills/<id>/`; the floor weapons are `content/pickups/<id>/`; the tile kits are
  `content/tilesets/{kingdom,playground}/` with atlases in `assets/tiles/<kit>/atlas.svg`; the five actor scenes are
  `presentation/views/actors/` (not collapsed: M2); the kingdom and first_encounter are fixtures under
  `tests/fixtures/` with their parts; the hand-drawn bedroom pieces are `assets/map_pieces/`. The old folders are
  gone. The old-to-new tables and every judgement call are in `docs/migration-notes.md`; the exact list is
  `tools/move_res_log.tsv`.
- **One commit per folder or coherent group** (29 commits: 21 moves, one cleanup, three guard commits, one
  notes commit, one sidecar repair and its guard, one record update), the strict runner after every one. Two groups had to be one commit because a test lists a folder
  (the seven enemy definitions, the six rooms); one attempt was thrown away and redone when the Book check turned
  out to straddle two layouts.
- **Dumps.** The six baselines changed in 101 lines in total; every change is only a `res://` path a moved file
  prints (same line count, equal line by line after replacing path tokens, checked against the step-2 baselines).
- **Guards.** `test_sidecars_tracked` and `test_dependency_edges` are ENFORCING; the dependency guard fails on any
  edge outside the table, the documented exception and an explicit report-only `UNDECIDED_EDGES` list (the 5 edges
  nobody decided), and fails when a list entry goes stale. New: `test_content_has_no_gd` (zero `.gd`, at least 40
  files, folder = id), `test_content_references` (the content row of 13.1, 137 `ext_resource` lines, 0 violations,
  1 documented exception, 6 undecided room references), `test_fixtures_present` (requirement 116) and
  `test_no_old_res_paths` (the M1b grep acceptance). Each was mutation-checked.
- **Verification.** `python3 tools/run_all_tests.py --strict` green after every commit; both `--self-test` runs
  0 failures; `git diff --check` clean; `tools/bootstrap_worktree.sh` still runs all four generators clean with the
  moved hand art; `paint_kingdom_tilemap.gd` re-run on the new paths changes only the harmless node `unique_id`.
  A fresh `git clone` plus bootstrap found one stale `.import` (the pawn body's imported-cache path, left behind when
  that move was redone after a discarded attempt); it was repaired and `test_sidecars_tracked` now fails on any
  stale or orphan sidecar.
- **Not done here (the next step):** `CLAUDE.md` amendments and the prose docs, `tools/seed_placeholders.gd`,
  `content/_placeholders.json`, `content/README.md`, `task_plan.md` M1b row; the owner decides the 5 undecided edges
  and the room-overlay reference before `allowed_edges.txt` is frozen.

## M1b step 4 - finish and document - 2026-10-12

Fourth and last M1b step, branch `base/m1b-4` from `base/m1b-3`. No gameplay change; the only scene edits are two
`ext_resource` lines (below).

- **Placeholders (plan section 12).** `tools/seed_placeholders.gd` copies a generator's picture into `content/` only
  when the target is absent and records the sha256 of every stand-in in `content/_placeholders.json`;
  `tools/list_placeholders.gd` prints the owner's TODO by kind; `tools/placeholder_manifest.gd` is the helper both
  and `tests/content/test_placeholders_manifest.gd` share. A file is a placeholder if and only if its hash still
  equals the recorded one, so overwriting it clears the flag with no extra edit; the seed tool never re-records an
  already-listed file, so running it after the owner replaced a picture cannot turn the owner's art into a
  "placeholder". 25 files are listed (3 bodies, 4 icons, 1 pickup, 2 room backgrounds, 1 tile atlas, 4 interface
  pictures, 9 sound effects, 1 music loop). Left out on purpose: `assets/map_pieces/` and `assets/tiles/playground/`
  (the owner's own art).
- **The T1 and T2 backgrounds are tracked now.** The two rooms named gitignored generator output, so the owner could
  not swap their art without fighting the generator. The seed tool copied the two pictures to
  `content/rooms/<id>/background.png` (same bytes, own `.import` uid) and the two scenes name the copies (only the
  `ext_resource` path and uid change). `dump_t1` and `dump_t2` each changed by exactly one line (the texture path);
  the other four dumps are byte-identical. No tracked scene names `assets/_generated/` any more (a test fails if one
  does), and a strict runner on a clone with `assets/_generated/` deleted is green.
- **Mutation checks.** Appending one byte to a listed file moved the TODO from 25 to 24 ("1 replaced by you"); moving
  a listed file away failed the manifest suite and made `list_placeholders.gd` exit 1 and print it as missing.
- **`CLAUDE.md` amendments A-1 to A-9 applied** (the owner approved the move and the amendment at OG0, recorded above).
  Every other rule is word for word. Where the plan's text names something that does not exist yet (`HudSnapshot`,
  `world.commands`, `ecs/schedule/`, `sound_bank.tres`, `/new-skill`, `/new-room`, `/new-beat`) the rule says which
  milestone builds it. `docs/claude-md-diff.md` is marked applied and lists each difference.
- **Prose follows the move.** `docs/ARCHITECTURE.md` (tree, layer table, system-order table with phase folders, test
  folders), `docs/coding-standards.md` (folder placement, component/system/marker rules, sidecars, move rule),
  `AGENTS.md`, `README.md`, `docs/OWNER_GUIDE.md` (section 5 with real paths; four target rows marked "available
  now"), new `content/README.md`, `tools/README.md`, `.claude/commands/{verify,new-enemy,new-sound,milestone}.md`,
  `docs/design/room-authoring-guide.md`, `docs/ecs-conversion-plan.md` (3 paths), a note in `docs/where-we-are.md`.
  `docs/room-generator*.md` already named only `tools/` and `assets/` paths and needed no edit.
- **Acceptance of plan section 15 "M1b" (measured on the final tree):**

| Acceptance line | Result |
|---|---|
| `run_all_tests.py --strict` green, every baseline label passing or renamed | 26 suites, 0 failed, 0 warnings, GREEN; 235 of 235 labels still PASS, 0 renamed (`label_renames.txt` is empty) |
| import clean (no ERROR or Parse) | the editor import pass prints no `ERROR`, `SCRIPT ERROR` or `Parse Error` line |
| `grep` for the four old folder prefixes under `res://` (scripts, objects, scenes, resources) returns 0 outside `docs/archive` | `test_no_old_res_paths` passes (200+ text files read, 0 lines). A raw `git grep` for those prefixes still finds 4 files, all on purpose and all skipped by that test: `docs/game-base-plan.md` (quotes the acceptance line), `docs/research/organisation.json` (a record of the old codebase), `tools/move_res.py` (its self-test builds a fake old-layout project) and the test itself |
| zero path-only `ext_resource` lines | `stamp_uids.gd --check` CLEAN (251 lines, 0 missing, 0 stale); `test_no_path_only_ext_resource` PASS |
| sidecars tracked | `test_sidecars_tracked` ENFORCING: 104 tracked `.gd` all with a `.gd.uid`, 37 imported assets all with an `.import`, 0 orphans, 0 stale |
| `content/` contains 0 `.gd` with a minimum file count | 0 `.gd`; 54 data/art files counted (minimum 40), 65 tracked files in total; 7 enemy, 6 room and 5 rule-page folders each hold their role file |
| the dump equals the baseline for each Stage 1 room and H1 | `test_dump_baselines` PASS (31 checks) for T1, T2, T3, T4, B1, H1. Over the whole of M1b the six baselines changed only in `res://` path strings (85 lines in step 2, 101 in step 3, 2 in step 4) |
| a fresh clone is green | `git clone` of the branch to `/tmp`, `tools/bootstrap_worktree.sh` (exit 0, the warm-up pass printed no error), the strict runner GREEN (26 suites, 235 of 235), `git status` clean, `stamp_uids.gd --check` CLEAN; again GREEN after deleting `assets/_generated/` |

- **Verification.** Both `--self-test` runs report 0 failures; `git diff --check` is clean.
- **Commits (step 4):** `a93c473` the placeholder tools, `32685a6` the room backgrounds as tracked stand-ins and the
  25-file manifest, `14ff578` `CLAUDE.md`, `40bedf8` ARCHITECTURE/coding-standards/AGENTS, `3278128` README, owner guide,
  `content/README.md`, status page and room guide, `a13299f` the slash commands and `tools/README.md`, `6e6b344` the
  ECS conversion plan, then this record commit (tagged `m1b-done`).
- **Not done, and why:** `content/audio/` (`sound_bank.tres`, `music_cues.tres` do not exist yet: the
  `SfxManager` registry is Inspector exports, M4/M6); `ContentDb`, `actor_view_base.tscn` and the thin inherited actor
  scenes (M2); `/new-skill` (M7a), `/new-room` and `/new-beat` (M14); `tests/architecture/allowed_edges.txt` is not
  frozen (five dependency edges and six room references wait for the owner); the tile and animation-frame assembly
  tools the owner's one-file-per-thing direction implies (the tree leaves room: `assets/tiles/<district>/<tile_id>.png`,
  `content/<kind>/<id>/anim/<clip>/<NN>.png`); `docs/design/*` specs and the production checklists still name old
  paths in prose (planning documents, not rewritten); other kinds of placeholder (prose, tuning numbers) are not
  covered by a file hash.

## M2 step 1 - the content registry and the player definition - 2026-10-13

First of three M2 steps ("Content registry and actor collapse", `docs/game-base-plan.md` 15), branch `base/m2-1` from
`game-base` (`8731597`). Steps 2 and 3 (the one actor view, the in-cell piece sizes, the previews) are not in this
branch. No gameplay rule changed: movement, combat timings and AI are untouched.

- **`PlayerDefinition` (`schema/entity/`) and `content/player/player.tres`.** Courage (`max_courage`), invulnerability,
  step time, hold-repeat delay, skill cooldown, `starts_with_sword`, the two attack profiles and `piece_name` were
  Inspector values on four `EntityComponent` nodes inside the player scene. They are one resource now; the player view
  names it (`ActorView.player_definition`) and `EcsBoot` bakes it (`EcsActorFactory.spawn_player_from_definition`),
  then applies any `EntityComponent` node on the instance, so a node still wins field by field. The player scene lost
  its four component nodes (text edit, uids untouched) because they would otherwise always beat the file. A view that
  names no definition plays on the class defaults, which equal the old values. `EcsActorFactory.spawn_player` is
  unchanged. The `"Pawn Hero"` string literal in `EcsBoot` is now `PlayerDefinition.piece_name`.
- **`ContentDb` (`shell/content/content_db.gd`, `content_kind.gd`).** A static class, no autoload, lazy id cache per
  kind, ids from folder names (file names for `difficulty`; an underscore folder is not an id). `ids`, `has_id`,
  `fetch`, `all`, `path_of`, `player()`, `world()`, `validate()`, `validate_cross_refs()`, plus `configure_root()` and
  `clear_cache()` for tests. Nine kinds: `player`, `world`, `enemies`, `rooms`, `rules`, `skills`, `pickups`,
  `difficulty`, `tilesets` (28 entries today). The method is `fetch`, not the plan's `get`, because a static `get`
  would override `Object.get` and GDScript rejects that. Not built: the `content/_index.json` fallback for an exported
  build (plan 14.1); `ResourceLoader.list_directory` lists folders inside a `.pck`, and there is no export here to try.
- **`validate()` added to `AttackProfile`, `EnemyWeapon`, `DifficultyProfile`** so that every definition class answers it
  (the registry flags a script class without one).
- **One real inconsistency found by the registry:** `content/pickups/toy_weapon/` held only the shared pickup sprite, so
  the folder was an id with no definition. It now has `toy_weapon.tres` (the `EnemyWeapon` class defaults written out).
  Nothing places it, so no room, dump or behaviour changes.
- **`tools/world_dumper.gd`** asks `ContentDb.world()` instead of keeping its own copy of the `world.tres` path.
- **Deterministic dumps.** `[entities at boot]` is byte-identical in all six (`t1 t2 t3 t4 b1 h1`): the player still has
  Courage 3/3, invulnerability 0.7, step 0.18, hold 0.22, cooldown 1.25, sword unlocked, the same two profiles. The only
  change is the intended one: each baseline loses the four `PawnHero/{Combat,Health,Input,Movement}Component` lines and
  its `[nodes] N` header drops by 4 (t1 35 to 31, t2 35 to 31, t3 43 to 39, t4 80 to 76, b1 80 to 76, h1 28 to 24).
  Mutation check: setting `max_courage = 4` makes `test_dump_baselines` fail on exactly the `health:` and the summary
  line, so the baselines are the byte-for-byte proof.
- **Tests added (4 suites, 26 to 30).** `test_content_db_in_init` (registry inside `_init()` with no autoload; asserts
  that premise), `test_validate_all` (110 checks: minimum count per kind, ids equal folders through a plain folder
  listing, no id claimed twice, `validate()` called on at least 20 definitions, both validators empty),
  `test_content_db_detects_problems` (a throwaway tree under `user://`, one named defect per entry, each required to be
  reported with its exact sentence, a clean control entry required to stay silent, the lazy cache), and
  `test_player_definition` (every field bakes, a retuned definition changes the entity, a node on the instance wins, a
  view with no definition uses the defaults, the old factory call still works, `validate()` names each broken field).
  Mutation checks on the real content: `step_duration = 0` fails `test_validate_all`; a Book page with
  `piece_id = ghost` fails it through `validate_cross_refs()`.
- **Baseline labels.** Three `tests/run_tests.gd` checks looked for the four nodes; they now look at the definition and
  the three renames are in `tests/label_renames.txt`. 235 of 235 still PASS (3 through renames).
- **Docs.** `docs/ARCHITECTURE.md` (ActorView, EntityComponent, EcsBoot, EcsActorFactory, ContentDb rows),
  `docs/OWNER_GUIDE.md` (the pawn row is "available now"), `docs/coding-standards.md` (look content up by id, no
  tuning on the player scene), `content/README.md`, `AGENTS.md`, `CLAUDE.md` (one rule: content by id through
  `ContentDb`), `.claude/commands/new-enemy.md`. `task_plan.md` gets its M2 row from the integrator once the three
  steps are merged, as for M1a and M1b.
- **Verification.** Both `--self-test` runs report 0 failures; `run_all_tests.py --strict`: 30 suites, 0 failed, 0
  warnings, GREEN, 235 of 235 labels; `stamp_uids.gd --check` CLEAN; `git diff --check` clean. Every commit of the
  step was verified green on its own.
- **Not done here (steps 2 and 3, and later):** the single `actor_view_base.tscn` with thin inherited scenes and
  `test_actor_collapse_golden`; `VisualDefinition` body texture and anchor; the in-cell piece size table, the scene
  geometry for the owner's 2026-10-12 decision (a piece is smaller than its cell), the chess placeholder bodies and
  `tools/render_actor_preview.gd`; the `/new-enemy` rewrite; the exported-build index.


## M2 step 2 - one actor view, and the pieces inside their cells - 2026-10-13

Second of three M2 steps, branch `base/m2-2` from `base/m2-1`. Implements the collapse of the actor scenes AND the
owner's decision of 2026-10-12 ("a piece is smaller than its cell"; `docs/owner-decisions.md`), which reverses
`task_plan.md` phase 66 (pieces 1.5 cells tall, the top half in the row above). No gameplay rule changed: movement,
combat timings and AI are untouched; the six deterministic dumps still say the same about every entity and cell.

- **The golden oracle comes first** (`tools/actor_dumper.gd`, `tools/dump_actor_golden.gd`,
  `tests/baselines/actor_collapse_golden.txt`, `tests/architecture/test_actor_collapse_golden.gd`): how every old
  actor scene looked (nodes with class, script, visibility, transform, texture; every ActorView value; clips; graph
  states and transitions; the entity `EcsBoot` bakes) captured from `base/m2-1` before anything moved, plus a
  fingerprint of the head of each world dump. `--write` refuses to overwrite it. Mutation checks: a telegraph colour off
  by 0.01 and `max_courage = 4` each fail it by name.
- **One actor view.** `presentation/views/actors/actor_view_base.tscn` holds the nodes, the union of the hero's and the
  enemies' clips (idle, step, hurt, telegraph, attack, defeat, wake) and one graph. `player`, `black_pawn`,
  `knight_enemy` and `bishop_enemy` are thin inherited scenes (13 to 20 lines each; `test_one_actor_view` holds that and
  that they own no sub-resource). `enemy_base.tscn` was `black_pawn.tscn` byte for byte and is deleted (its six labels
  continue as black_pawn's, in `tests/label_renames.txt`). Two `Start` edges wait for a scene-set condition: the base
  boots awake, the hero's scene boots asleep into `wake`. Clip differences between pieces are data:
  `VisualDefinition.clip_speed_scales`, applied by `ViewSyncSystem` to a `TimeScale` node that every graph state plays
  its clip through (`AnimationPlayer.speed_scale` does nothing under an `AnimationTree`; measured). Knight and bishop:
  idle 1.25, step 0.9, telegraph 1.1667; hero idle 1.125.
- **The golden's intended differences, line for line:** `Start -> idle` (pawn, knight, bishop) and `Start -> wake`
  (hero) gain their `boots_awake` / `boots_asleep` condition; the hero's `show_facing_mark` and `show_health` go true to
  false and its two pip textures null to the pip pictures (it inherits the arrow and pips and shows neither); six new
  hidden hero nodes (`TelegraphAura`, `FacingArrow`, `HealthPips`, `Pip0..2`); the bishop's body texture is its own;
  geometry (below). Every baked component field of every actor is identical.
- **Dump baselines.** Only the hero's six new nodes and five texture lines in all six rooms (`[nodes]` 31 to 37,
  31 to 37, 39 to 45, 76 to 82, 76 to 82, 24 to 30; `[textures]` plus 5 each); nothing before `[nodes]` moved (the golden
  fingerprints that head: the per-room entity set and cells equal the pre-port dump). The in-cell commit changed none.
- **In-cell size table** (`schema/feel/piece_size_table.gd`, `piece_size.gd`; `content/feel/piece_sizes.tres`): per kind
  a body box, a base line and a footprint in cells. Pawn 18 x 22, knight, bishop and rook 20 x 24, queen 22 x 26, king
  22 x 28, every base line 14 px below the cell centre, 2 px margin on the 32 px cell (a king reaches exactly 2 px from the
  top). `validate()` holds the margin, a kind listed once and pawn < knight, bishop, rook < queen < king. A boss is a row
  with a bigger footprint. `ContentDb.piece_sizes()`; a kind may live in a folder with another name (`ContentKind`).
- **Geometry.** Body pictures drawn at scale 1 from the table (`PieceSizeTable.body_top_left`; `ViewSyncSystem` writes it
  from `VisualDefinition.piece_type/body_texture/anchor_offset`). Pips (4 px) along the top edge, arrow (6 px) on the
  facing side 10 px out, held weapon at 0.16 scale from the cell centre, aura 22 to 27 px (the clip owns its size now),
  hops and shakes capped at 2 px, the wake clip re-authored to turn about the body's middle. Everything an actor draws is
  within 14 px of the cell centre. Row-based depth kept.
- **Art.** `tools/generate_chess_sprites.gd`: one block is one world pixel; it reads the size table and refuses a piece
  that does not fit; added the black pawn (the pawn's rows in obsidian) and the bishop (placeholder shape). The knight
  could not honour its 20 x 24 box (26 x 32 at one pixel per block, and no whole-number scaling fits) so the SAME glyph was
  retraced on 15 rows with `tools/trace_knight_glyph.py --rows 15` (`--rows 21` still reproduces the approved arrays,
  kept in a comment). That is an edit to an owner-approved shape, recorded in `THIRD_PARTY_NOTICES.md` and the commit.
  `tools/seed_placeholders.gd` may now replace an earlier stand-in (never the owner's file; `PlaceholderManifest.
  seed_decision` is tested): the three M1b bodies were replaced in place (hero 18 x 20, black pawn 18 x 20, knight 20 x 24)
  and the bishop got its own (18 x 22); `content/_placeholders.json` has 26 entries.
- **Measured.** Every actor, facing every way, armed (spear, ruler, sword, pencil) and telegraphing, at every key and every
  25 ms of every clip it plays (599 poses): drawn inside the cell, 2.0 px from the edge at the narrowest at rest (the base
  line), at least 0.6 px in motion. Hero and black pawn bodies are 14 x 20 drawn pixels, bishop 14 x 22, knight 18 x 24.
- **The preview** `tools/render_actor_preview.gd` (headless, CPU compositing, no renderer):
  `assets/_generated/previews/pieces_in_cells.png`, 1336 x 568, four rows by nine cells at 4x, grid lines and the margin
  square; the bootstrap script draws it. A real-renderer boot of T1 and T4 (windowed, `root.get_texture()`) confirmed the
  same picture in the running game: pieces stand inside their 64 px cells (2x window), the hero lying in `wake` for its
  first 1.25 s.
- **Tests added** (35 suites, was 30): `test_actor_collapse_golden`, `test_one_actor_view`, `test_piece_size_table`,
  `test_pieces_inside_cell`, `test_actor_preview_tool`. `test_audio_buses` now expects the one actor AudioPlayer.
  `test_content_db_detects_problems` also proves the visual cross-reference check. Mutation checks: an arrow 14 px out
  fails `test_pieces_inside_cell` by name.
- **Baseline labels:** 235 of 235 still PASS (9 through `label_renames.txt`: the 3 of step 1 and the 6 of `enemy_base`).
- **Verification.** Both `--self-test` runs 0 failures; `run_all_tests.py --strict` 35 suites, 0 failed, 0 warnings,
  GREEN; `stamp_uids.gd --check` CLEAN; `git diff --check` clean. Every commit was green on its own.
- **Not done.** Step 3 (and the integrator): `task_plan.md`, the rest of the M2 acceptance sweep, merging. A bishop or
  knight redrawn by the owner replaces the placeholders by overwriting the PNGs. The other black pawn definitions
  (armed, backstep, charging, captain) share `pawn_recruit/body.png` through `pawn_compatibility.tres`: one picture per
  enemy is a visual.tres edit away. Rook, queen, king and boss bodies do not exist yet (rows of the table, not art).


## M2 step 3 - docs, commands and records - 2026-10-13

Third of three M2 steps, branch `base/m2-3` from `base/m2-2`. No code changed except one comment (`content_kind.gd` named a
function `_build_kinds` that does not exist; it is `_ensure_kinds`). The step is the prose, the commands and the records,
plus one real walk of `/new-enemy`.

- **`/new-enemy` walked for real** on a scratch clone of the branch (bootstrapped, nothing committed, everything deleted
  afterwards, the strict runner GREEN on a clean tree at the end). `test_pawn`, 5 health, reusing the shared pawn pieces:
  - `content/enemies/test_pawn/enemy.tres` alone (a text copy of `pawn_recruit`'s with the header uid removed, `id`,
    `display_name`, `max_health = 5`) and `stamp_uids.gd`: `test_validate_all` finds 8 enemies (was 7), four `enemies/test_pawn`
    lines PASS, `TEST VALIDATE ALL: PASS`. **1 file** for a re-skin.
  - Spawned from a throwaway room scene in the project root with `tools/dump_world.gd --room=res://<scene>`: `entity 3
    enemy:Pawn cell=(7,3) health=5/5` beside the real pawn's `health=2/2`.
  - Its own picture (`visual.tres` and `body.png`, a copy of the pawn's): **3 files** (the editor adds `body.png.import`).
    The uid recipe that works, in one order: files with no header uid and a path-only reference to files just made, import,
    `stamp_uids.gd` (it filled 2 header uids and 2 path-only lines), import again, `--check` CLEAN. Stamping before the
    import cannot fill the picture's uid; a scene that names a stamped uid before the import pass prints `invalid UID ...
    using text path instead` until it has run.
  - Where it fails, by name: in the real T3 room the strict runner went red on exactly `test_dump_baselines` (t3's dump) and
    `test_bridge_travel` ("T3 holds its single living pawn"); a scratch room under `content/rooms/` went red on four suites
    (not in `world.tres`; names `presentation/board/`), so a throwaway scene belongs in the project root; a 26 x 32 picture
    failed `test_validate_all` ("its body picture is 26 x 32 px but a pawn may be drawn at most 18 x 22 px") and
    `test_pieces_inside_cell` (17 FAIL lines, narrowest margin -2.00 px).
  - Placeholder flag: an `ADOPTED_PLACEHOLDERS` row moved `_placeholders.json` from 26 to 27 entries; overwriting the
    picture gave "27 recorded, 26 still to replace, 1 replaced by you" and both suites went green.
  - What the walk corrected in the command: the uid order, the real-room failures, that a throwaway scene boots with the dump
    tool, that `dev_sandbox` does not exist (M6), and that the preview picture does not show a definition-only enemy.
- **Docs.** `docs/OWNER_GUIDE.md`: rows for retuning an enemy, a variant enemy (1 file), an enemy with its own picture (3),
  retuning the pawn (1, `content/player/player.tres`, with its three Inspector groups), swapping a sprite (1 or 2) now give
  exact paths and file counts; **section 6 is new, in Vietnamese** (the owner's sentence, the rule, where the size table lives
  and each field, the margins that follow from it, how to draw a body, how to read `assets/_generated/previews/
  pieces_in_cells.png`, what is still missing); the glossary moved to 7 and gained `ContentDb`, the one actor view,
  `PlayerDefinition` and the base line; placeholder count 26. `docs/ARCHITECTURE.md` has one section for the registry, the hero
  and the actor view (the ten kinds, both validators, the bake, a table of what `ViewSyncSystem` writes from which field, and
  the six readers of the size table). `docs/coding-standards.md`, `tools/README.md` (the preview, `supersedes_stand_in`),
  `content/README.md`, `README.md`, `AGENTS.md`, `docs/migration-notes.md` (an M2 section: nothing moved, one scene
  deleted, what M1b left undone) and `docs/where-we-are.md` (a dated note) follow.
- **Spec records.** `docs/game-base-plan.md` section 12 states the new rule with the numbers and cites `docs/owner-decisions.md`
  (it no longer says 32x40, 48x48, 64-96 px), the paths say `presentation/views/actors/`, the change table has the row for the
  size of a kind of piece, and section 15's M2 says what else was built and where it differs from its text.
  `docs/design/pixel-art-bible.md` section 6 and `docs/design/gdd.md` carry a dated "superseded" note. `task_plan.md`: phase 66
  is marked superseded and row 81 is M2, `human_review`.
- **Loose ends found, none changed (they are not M2's to decide).** `VisualDefinition.telegraph_color`, `impact_color` and
  `weapon_anchor` are read by nothing (the tint is `ActorView.telegraph_modulate`, the hand is `ActorView.weapon_anchor`), and
  the actor scenes and the `.tres` disagree about the tint: wire them or delete them, later. The preview picture draws the
  hero and the three thin scenes, so an enemy that is only a `definition` is measured by `test_pieces_inside_cell` but is not a
  row of the picture. `test_bridge_travel` asserts T3's pawn count, so adding an enemy to a real room means touching it.
  `docs/research/*` and the older design specs still carry the old sizes (the two the owner reads, the GDD and the pixel-art
  bible, now say so).
- **Commits** (trailer `Co-Authored-By: Claude Sonnet 5.5`, as in steps 1 and 2, following the session's attribution rather than
  the Opus line of the task text): the walked `/new-enemy`; the owner guide with the Vietnamese section; the architecture,
  standards, tools and content docs; the plan and design-doc amendments with the task-plan row; the records (this entry,
  `findings.md`, `where-we-are.md`).

### M2 as a whole - 2026-10-13

Branches `base/m2-1`, `base/m2-2`, `base/m2-3` (each from the one before; 15 commits, nothing pushed), tag `m2-done` on the last. No
gameplay rule changed: movement, combat timings and AI are untouched; every entity and cell of the six deterministic dumps equals
the pre-port dump (the golden fingerprints the head of each), and the only dump lines that moved are the hero's six new view
nodes and five textures (the collapse) per room.

| M2 acceptance (plan section 15) | Where it is proved |
|---|---|
| per actor, node paths and every baked component field equal the old scene's; per-room entity set and cells equal the pre-port dump | `tests/architecture/test_actor_collapse_golden.gd` against `tests/baselines/actor_collapse_golden.txt` (captured from `base/m2-1` before the collapse); `test_dump_baselines` |
| every definition passes `validate()`, ids equal folders, no duplicates, a minimum count | `tests/content/test_validate_all.gd` (116 checks) and `test_content_db_detects_problems` (each defect named) |
| the registry works inside a `_init`-time suite with no autoloads | `tests/content/test_content_db_in_init.gd` |
| baseline labels intact | 235 of 235 PASS, 9 through `tests/label_renames.txt` |
| the owner's size decision: a piece inside its cell with at least 2 px margin | `tests/architecture/test_pieces_inside_cell.gd` (the hero, the three thin scenes and all seven enemies; every facing, armed, telegraphing, about 600 clip poses; narrowest margin at rest exactly 2.0 px); `tests/content/test_piece_size_table.gd`; `tests/architecture/test_actor_preview_tool.gd` |
| the owner can try: a variant enemy, swap `body.png` | walked on a scratch copy (above); `dev_sandbox` is M6, so the walk uses a room |

- **Final verification.** `python3 tools/run_all_tests.py --self-test` and `python3 tools/move_res.py --self-test`: 0 failures
  each. `python3 tools/run_all_tests.py --strict` on the worktree and on a **fresh `git clone` of the branch into `/tmp` plus
  `tools/bootstrap_worktree.sh`**: 35 suites (was 30 at the end of step 1 and 26 at M1b), 1,284 PASS lines, 0 failed, 0
  warnings, GREEN; baseline labels 235 recorded, 235 still PASS; `stamp_uids.gd -- --check` CLEAN; `git diff --check` clean;
  the clone's `git status` is clean after bootstrap and the run, and the bootstrap drew `pieces_in_cells.png`.
- **What the owner should look at (Open / Tune / Goal / Try / Tell me).**
  - Open: `assets/_generated/previews/pieces_in_cells.png` (made by `tools/bootstrap_worktree.sh`, or run
    `tools/render_actor_preview.gd`), then `content/feel/piece_sizes.tres` in the Inspector, then play T1 to H1.
  - Tune: each kind's `body_box` and `base_offset_y` in `piece_sizes.tres` if a piece should be smaller or stand lower; the
    four stand-in bodies (`content/player/body.png`, `content/enemies/{pawn_recruit,knight_tracker,bishop_zoner}/body.png`).
  - Goal: pieces that read as chess pieces standing in their squares, heights like a real set, nothing reaching into the row
    above; the pawn and the knight still readable at 32 px.
  - Try: a room with a knight and a bishop beside black pawns; the hero's wake clip; an armed pawn facing every way.
  - Tell me: are the sizes right (pawn 18 x 22 up to king 22 x 28, base line 14 px below the centre), do you want the
    retraced knight kept or redrawn, do the black pawn and bishop stand-ins read, and which of rook, queen, king and the
    first boss should get pictures next.
- **Not done, and why.** Rook, queen, king and boss bodies do not exist (table rows only; no such actor exists and the art is the
  owner's). The exported-build fallback `content/_index.json` (no export to try). The sprite-sheet block and sound ids in
  `VisualDefinition` (Tier B). The preview picture's rows are fixed (hero, black pawn, knight, bishop). The five dependency edges
  and six room references of M1b are still the owner's to decide.

## M2 fix round after the review - 2026-10-13

The independent review of `base/m2-3` accepted M2 with fixes: two majors and six minors. Branch `base/m2-fix` (from `base/m2-3`),
ten commits (the last is this record), the strict runner green after each.

- **Major: the one scaled actor.** The B1 Black Pawn Captain at 1.18x drew 0.52 px past its cell, and nothing could see it (the
  test booted enemies on the base scene at scale 1; the probe measured in the view's own frame, which cancels a scale).
  `ActorCellProbe` now measures in the cell's frame, `ActorStage.boot_placed` boots a room's actor as placed, and
  `test_pieces_inside_cell` measures every actor of every room (7 today) and asserts scale 1 / unturned by room and name: before the
  fix it failed 17 times, all on the captain. The captain lost its scale (`dump_b1.txt`: that node line loses `scale=(1.18,1.18)`,
  nothing else moved).
- **Major: the owner's PNG convention.** `docs/assets` (game-base, merged cleanly by `git merge-tree`) asks for 32 x 32 canvases,
  base rim on row 30, bodies of 18 x 22 to 22 x 28 inside; M2 counted the whole PNG against the box and would have failed the
  owner's first file (and stood it 2 px too high). The table gained `cell_canvas_base_row` (30), `box_on_cell_canvas`,
  `picture_problems`; a canvas is accepted when its drawn pixels lie inside the box on it and is placed exactly on the cell; a tight
  picture still works. The generator writes the four stand-ins as canvases (same pixels, same screen pixels, the preview is
  unchanged), `BodySprite` is (-16,-16) in the base scene and the knight and bishop thin scenes lost their position override,
  `seed_placeholders` rows take a `revision` so a redrawn stand-in replaces the first drawing once (never an owner's file).
  Tried by hand first: a real spec canvas as `pawn_recruit/body.png` passed `validate_all` and every drawn-margin check, and only the
  thin scene's static position went red, which is why that number was removed from the scenes.
- **Minor, fixed.** Hit shove limited to the margin (137 failures without it); the preview has a gutter, lines under the pieces, magenta
  for crossings, a count, a `--stretch` demo and a second picture of the placed actors; the pip row is held against every kind's head
  and names queen and king as overlapping; five unread `VisualDefinition` fields deleted and the scene's repeated numbers held
  equal by the test; `ContentDb.validate()` reports a reference of the wrong class.
- **Minor, not changed (a design call or an owner's yes).** Bishop 22 px against knight 24 px on one rung of the ladder. The retraced
  knight and the new black pawn and bishop need the owner's approval. The aura, arrow and pip sizes of `docs/assets` against the scene
  (see `findings.md`). The trailer on every commit is `Co-Authored-By: Claude Sonnet 5.5` (the session's attribution), not the
  `Opus 5.5` line the task text named.
- **Verification.** `python3 tools/run_all_tests.py --strict`: 35 suites, 0 failed, 0 warnings, GREEN, baseline labels 235 of 235
  (9 through `label_renames.txt`); `--self-test` and `move_res.py --self-test` 0 failures; `stamp_uids.gd -- --check` CLEAN;
  `git diff --check` clean. Tag `m2-done` moved to the last commit of this branch.

## M3a step 1 - the runtime seams: schedule, events, commands, world fields - 2026-10-19

Branch `base/m3a-1` (from `game-base`), seven code commits and this record, the strict runner green after each. M3a is "L"
in the plan and is built in three steps; this is the first. Nothing the player can feel changed.

- **The schedule.** `ecs/schedule/` holds one file per stage (`command`, `input`, `decide`, `cell_effects`, `move`, `act`,
  `resolve`, `react`, `progress`, `view`; `SchedulePhase` is their base) and `schedule.gd` (`Schedule.populate(world)`,
  `system_scripts()`, `build_systems()`). The plan names phases after folders, but its own order (13.4) visits the `world` folder
  three times, so a stage is named for when it runs and each system carries `const PHASE` naming its stage. `game_root.gd` and
  `tools/world_dumper.gd` lost their copies of the list. `test_schedule_order` holds the whole planned order (18 systems, the
  ones that exist and the ones later milestones add) and proves its own check can fail; `test_schedule_complete` fails on an
  unlisted, doubly listed or misfiled `*_system.gd`, and on a list reappearing in `game_root` or the dumper.
- **Events.** `ecs/events/events.gd`: a const per event, a row per event (status, what happened, every payload key with its
  type and meaning) in banner tables, so lanes append inside their own. The 19 types the plan counted are `emitted`; the 27 the
  plan adds are reserved as `future`; `healed`, `flag_set` and `command_rejected` are new and emitted. `EcsWorld.emit_event`
  asserts the declaration in debug builds (a bad emit is a `SCRIPT ERROR`, which the runner fails); producers say
  `Events.STEP_STARTED`. `test_events_declared` reads the code for every emitted name, both ways.
- **Damage and heals.** `Events.emit_damage(world, target, amount, direction, source, tags)` is the only way to queue damage;
  `CombatSystem` (source: the player) and `EnemyAISystem` (source: the enemy; tags: the held weapon's tags, empty for an unarmed
  pattern) call it, and so do the tests that used to build the dictionary by hand. `HealthSystem` carries `source`, `tags` and
  `direction` into `damaged` and `source`, `tags` into `defeated` (what R8, R10 and R14 read). `Events.emit_heal` and
  `world.heal_events` are served by `HealthSystem` after the damage of the same tick, clamped to the maximum, never reviving.
  `test_emit_damage`, `test_heal_queue`.
- **The world's fields.** All eight in one commit: `frozen`, `flags` (`WorldFlags`), `tuning` (`Tuning`, neutral defaults,
  nothing reads it yet), `input_snapshot` (`InputSnapshot`), `hud_snapshot` (`HudSnapshot`, a revision counter for now),
  `commands` (+ `command_handler_by_type`), `view_commands`, `heal_events`. `EcsSystem.runs_while_frozen()` (false by default);
  a frozen world ticks only `CommandSystem` and `ViewSyncSystem`, checked before each system. `test_world_fields`,
  `test_frozen_world` (nine of its checks fail if the freeze check is removed).
- **Commands.** `ecs/events/commands.gd` declares the requests like events.gd declares events. `CommandSystem` (first in the
  schedule, runs while frozen) drains `world.commands` in push order, validates each against its row, calls the handler
  registered for its type and emits `command_rejected` with the reason for anything malformed, unhandled or refused. Four
  requests are handled (`freeze_requested`, `unfreeze_requested`, `set_flag`, `tuning_set`); `actor_command` (M6) and
  `equip_page` (M7c) are reserved. A system that owns the state a command changes registers its handler with
  `world.register_command_handler()`, so a lane adds a command without editing `CommandSystem`. `ViewSyncSystem` plays
  `world.view_commands` (`play_state` travels the actor's graph; it works while frozen). `test_commands_channel`,
  `test_view_commands`.
- **The pins.** `systems.size() == 6` (`encounter_hud_runtime_test`, `test_bridge_travel`) now asks the live world for exactly
  the schedule's list in its order; its baseline label is renamed in `label_renames.txt`. The `EcsBoot` call sites the plan
  names (and the other ten) moved to `EcsBoot.boot(world, EcsBootOptions)`; `test_boot_options`.
- **One dump-tool fix.** The first run of the dump baselines after the schedule went in failed in all six rooms: the
  dumper printed an entity's components `sort()`ed by StringName, which sorts by memory address, so loading scripts in a
  different order (the schedule does) moved lines with nothing changed. The order the M1a baselines recorded is now an explicit
  list, `COMPONENT_DUMP_ORDER` in `tools/world_dumper.gd`; no baseline line changed.
- **Verification.** `python3 tools/run_all_tests.py --strict`: 45 suites (35 at the end of M2), 0 failed, 0 warnings, GREEN, baseline labels 235 of 235
  (10 through `label_renames.txt`); `--self-test` and `move_res.py --self-test` 0 failures; `stamp_uids.gd -- --check` CLEAN;
  import pass clean; `git diff --check` clean. The six room dumps equal their baselines byte for byte.
- **Not done in this step (the rest of M3a).** `InputPoller` and `PlayerInputSystem` reading only the snapshot; the grid
  (`cell_kind_by_cell`, the TileSet `kind` layer and paint-tool support, `begin_leap`, `ray_cells`, `layout_version` with a cached
  `AStarGrid2D`, the bounded attack-setup search, per-room centred `grid_origin`); the `CameraRig` clamp; `PlayerSnapshot`;
  `HudSnapshot` fields and `HudSnapshotSystem`; `tests/perf/test_room_tick_budget.gd`. Nothing pushes on `world.commands` or
  `view_commands` yet, and the bridge still reads components directly (the listed deviation).

## M3a step 2 - input, the HUD and player snapshots, room origin - 2026-10-19

Branch `base/m3a-2` (from `base/m3a-1`), five code commits and this record, the strict runner green after each. Nothing the
player can feel changed: the six room dumps are byte-identical to their baselines and all 235 baseline labels still pass.

- **The controls have one reader.** `shell/input/input_poller.gd` is the only file that calls `Input`; `game_root` polls once
  per frame, right before the world ticks, into `world.input_snapshot`, and `PlayerInputSystem` reads only that. The poller copies
  the engine's own pressed / just-pressed / just-released flags verbatim (not edges of its own), so a tick that runs several times
  inside one engine frame, the way the bridge suites pump, sees what the system saw when it asked `Input` itself; `held_time` and
  the press timestamp are new and nothing reads them yet. `game_root`'s three raw keys (F3, F11, B) are published by the poller
  as `debug_view_toggle`, `fullscreen_toggle`, `rule_book_toggle` (edges worked out there) and `restart_room` is read from the
  snapshot; M4 turns the names into `InputMap` actions and deletes the table. **Byte-identical, proved two ways:** the bridge
  suites pass unchanged, and a one-off comparison of the old system (from `git show`) against the new one with the poller ran
  7,472 ticks of random play of every control (random frame times, several ticks per engine frame, control toggled, "moving"
  toggled) and left identical state after every tick; with the poll removed the same comparison reports 2,724 differences, so it
  can fail. `test_input_snapshot` (61 checks) holds the buffer (newest wins, never expires until M7b), the chord, the tap window
  (a tap is one step, a hold repeats on the tick that reaches `held_repeat_delay`), the attack keys, a hero without control, and the
  poller against the real `Input`. `test_input_only_in_poller` is the lint.
- **The HUD and the board read a snapshot.** `HudSnapshot` holds the hero's courage, cell, facing, sword and skill cooldown, the
  attack token owner and one `EnemyBrief` (cell, committed goal, telegraph progress) per enemy; `HudSnapshotSystem` rebuilds it in
  place at the end of every tick (view stage, before `ViewSyncSystem`; not while frozen) and the shell builds it once after a boot.
  `game_root` reads courage, cell and facing, the skill length and the token owner from it; `PrototypeBoard.setup(grid, snapshot)`
  draws telegraph progress and the F3 intent paths from the briefs. **No script under `presentation/` names `EcsComponents` or
  `EcsWorld`** (`test_hud_snapshot` and the edge test both fail if one does), and the board's two undecided dependency edges are
  deleted. 13.1's presentation row names `HudSnapshot`, so `test_dependency_edges` gained `CLASS_ALLOWANCES`, an exact list like the
  other two. The cadence of the HUD is unchanged (the skill slot is still redrawn on `skill_cooldown` events), which keeps one
  pre-existing quirk: after the sword is found the slot says "find sword" until the first skill is used. The M4 widgets draw the
  snapshot every frame and end it. `test_hud_snapshot` (39), `test_board_draws_from_snapshot` (9, runs the overlay's real draw
  code on a snapshot with no world behind it); the `encounter_hud_runtime_test` pin `board.ecs == ecs` is retargeted and its
  label renamed in `label_renames.txt`.
- **`PlayerSnapshot`.** The plan's 14.2 carry table as data (`ecs/core/player_snapshot.gd`): courage current and max, Believe,
  unlocked skills and applied upgrades, equipped pages and Margin, the direction lock, the facing, the flags. The per-room rows are
  not fields, so they reset with the world. Plain data with a dictionary form (not a Resource: the save is a versioned dictionary);
  `capture(world, hero)`, `apply_to(world, hero, restore_facing)`, `to_dictionary()`/`from_dictionary()` (JSON-safe, tolerant of a
  damaged or older save, null for a newer one). Rows whose component does not exist yet have fields and round-trip now. The facing
  is captured but restored only on request (a room change leaves it to the entry marker). `EcsBootOptions.player_snapshot` and
  `restore_player_facing`; `EcsBoot.boot` applies it right after the hero. Nothing in the shell passes one yet (M3b's zone swap).
  `test_player_snapshot_roundtrip` (52): dictionary, JSON string and JSON file; damaged, partial and newer saves; capture and apply
  between two worlds; two room changes through JSON; no aliasing; the boot. Two mutations turn it red in 8 places.
- **Per-room centred origin and the camera.** `EcsBoot.shape_grid` gives every room its bounds and the origin that centres its
  board (`EcsGrid.centred_origin`: x 64 for 16 wide, 32 for 18 wide, y 36 for 9 rows; a board larger than the picture keeps the
  fixed anchor on that axis, which keeps the 72x40 kingdom fixture where it was). The picture size is read from `project.godot`,
  once. The shell shapes the grid before reading the entry marker as a cell. `CameraRig.limits_for_board` makes "a room that fits
  the picture is held still, centred, every cell on screen" a contract instead of an accident of Godot's limit handling, and a
  larger world scrolls and stops at its edges; the limits are redone on zoom, on a viewport change and on `setup()` for the next
  room. `test_room_origin` (30) and `test_camera_frames` (37, ledger req 118, measured with a real `Camera2D` in a 640x360
  `SubViewport`). Every shipped room is 16x9, so no dump moved.
- **Verification.** `python3 tools/run_all_tests.py --strict`: 52 suites (45 at the end of step 1), 0 failed, 0 warnings, GREEN,
  baseline labels 235 of 235 (11 through `label_renames.txt`; the new one is the board overlay's wiring); `--self-test` and
  `move_res.py --self-test` 0 failures; the import pass clean; `stamp_uids.gd -- --check` CLEAN; `git diff --check` clean; every
  new `.gd` has its `.gd.uid` committed. The six room dumps equal their baselines byte for byte (no baseline line changed).
- **Not done in this step (the rest of M3a, step 3).** The grid: `cell_kind_by_cell`, the TileSet `kind` layer and the paint tool,
  `begin_leap`, `ray_cells`, `layout_version` with a cached `AStarGrid2D`, the bounded attack-setup search, and
  `tests/perf/test_room_tick_budget.gd`. `game_root` still WRITES `PlayerTag.control_enabled`, `PlayerCombat.sword_unlocked`, the
  health carry and `VIEW_REF` (M3b moves them to commands and the `PlayerSnapshot`); nothing pushes on `world.commands` or
  `view_commands` yet.

## M3a step 3 - the grid: cell kinds, leaps, rays, cached paths, the tick budget - 2026-10-19

Branch `base/m3a-3` (from `base/m3a-2`), six code commits and this record, the strict runner green after each. The first attempt of
this step was cut off by a network error after four commits; this run re-verified them (strict runner, the six dumps, and a replay
across two checkouts, below), found nothing wrong, added the paint-tool commit and finished the docs. Nothing the player can feel
changed: the six room dumps are byte-identical to their baselines and all 235 baseline labels still pass.

- **A cell knows what it is made of.** `CellKinds` (`ecs/core/cell_kinds.gd`) is the plan's 5.11 vocabulary as one table: floor,
  wall, gap, leapable_block, chalk, corruption, each with three rules (walkable, stops a ray, a leap may cross) and the one reading
  of a tile (`kind` when filled in, else `solid` is a wall, else floor; a kind nobody declared is an error). `EcsGrid` stores
  `cell_kind_by_cell` (floor is the absence of an entry), `set_cell_kind` is the only writer of the terrain, `blocked_cells` is
  derived from it, `layout_version` counts every real change (and a change of `bounds`), and `cell_effect_by_cell` is the empty,
  documented store the M10 `CellEffectSystem` will own, so that milestone does not edit the hot file. A wall is refused under a
  piece or a reservation, as `add_block` always did. The kingdom TileSet and the fixture's gained a `kind` custom-data layer (text,
  next to `solid`, added as text so no uid moved); no shipped tile fills it in, because the art for a gap, a block, chalk and
  corruption belongs to the milestones that use them. `EcsBoot.apply_solid_tiles` became `apply_tile_kinds`. **Paint tools:**
  `tools/cell_kind_painter.gd` is the part of a paint tool that knows kinds (a tool states what a cell IS beside the art it picked and
  the helper refuses a tile that does not read as that kind); `paint_kingdom_tilemap.gd` and, in the last code commit of this step,
  `paint_zone_tilemaps.gd` paint through it. Rerun, both tools write byte-identical `tile_map_data` (only the node's random
  `unique_id` and an `ext_resource` id differ, as documented), so no scene was touched. The world dumper prints a `cell_kinds:` line
  and names the new kinds in the board legend only when a room has a kind besides floor and wall, so no baseline line moved.
  `test_grid_cell_kinds` (110): in all six rooms and the 72x40 fixture the blocked cells are exactly the cells a `solid` tile was
  painted on; `blocked_cells` stays derived through 4,000 random changes; a lint fails on any script but `ecs_grid.gd` that writes the
  terrain. Two mutations turn it red.
- **A leap lets go of its origin; a ray stops at what stops it.** `begin_leap(entity, from, to)` / `finish_leap(entity)`: a step
  holds both its cells until it lands, a leap does not. At takeoff the origin is released and the landing cell reserved; in the air
  the entity stands on no cell (`leap_by_entity` records from and to), so anything aimed at a cell finds nobody, and `HealthSystem`
  ignores damage to an airborne entity (untargetable in flight). Takeoff is refused for a wall, a gap, a block, an occupied or
  reserved cell, the outside, the same cell, a piece not standing on `from`, and a piece mid-step or already airborne; a refusal
  changes nothing. `can_leap_over(cell)` is the table's third rule (never a door). `ray_cells(origin, direction, max_cells,
  stop_kinds, stop_before_occupied)` covers any non-zero step and stops before the board's edge or the first stopping kind (walls
  and blocks by default, never gaps); pieces are not terrain. No skill or attack uses either yet (Rule Step M7a, the Knight M8a).
  `test_leap_occupancy` (67, including 3,000 random operations after each of which the books balance) and
  `test_ray_stops_at_blockers` (45, including 400 random boards checked cell by cell). Three mutations turn them red.
- **The pathfinder is built once per layout; the attack search looks near the hero.** `get_grid_path` keeps one `AStarGrid2D` per
  `layout_version`, marks the pieces and reservations in the way solid for the length of one question and puts it back as it found it
  (`pathfinder_build_count` lets a test count builds). `EnemyAISystem._find_attack_setup_goal` looks only at the cells within the
  attack shape's reach of the hero, the reach measured from the shape itself, walked row by row as the board was so a tie keeps the
  same cell. **Identical decisions, proved four ways:** (1) the old bodies are kept in `tests/support/reference_pathing.gd` and
  `test_path_cache` (27) holds 5,000 random questions on 40 random boards cell for cell equal to them; (2) `test_attack_setup_search`
  (23) holds 2,278 random searches equal to the whole-board scan and ticks whole runs side by side on the new code and the old, 6,900
  ticks (an arena, the same arena strewn with walls, gaps, blocks and chalk, the six Stage 1 rooms and the kingdom), comparing every
  entity, timer, goal, memory and event after every tick, and an enemy whose search is one cell too narrow is caught by the same
  comparison; (3) the six dumps and the actor-collapse golden are untouched; (4) **re-verification in this run, across checkouts:** a
  throwaway script (kept outside the repository) played the same scripted games on a fresh clone of `base/m3a-2` and on this
  branch, 18,000 ticks in all (three seeded arenas of 2,500 ticks, two of them with walls appearing mid-run so the pathfinder
  rebuilds, and the seven shipped zone scenes of 1,500 ticks, with a hero put on a random cell every 25 to 30 ticks), hashing the
  whole state and every event after every tick. The two outputs were identical, line for line.
- **A room's tick has a budget.** `tests/perf/test_room_tick_budget.gd` ticks an 18x9 room with the hero and eight enemies (every
  shipped kind), every system of the schedule and a real view for each piece, 120 ticks to warm up and 1,800 timed. The hero keeps
  changing place so no enemy sleeps (the run shows 259 decisions, 159 steps, 17 telegraphs and 17 strikes every time: no random
  numbers). It asserts a mean and a median of 2 ms or less, a 99th percentile of 8 ms or less, and that the grid built ONE
  pathfinder for the whole run, which does not depend on the clock. **Measured here** (Apple M5, Godot 4.6.3 headless): mean
  0.15 ms, median 0.12 ms, 99th percentile 0.45 ms, slowest 0.5 to 1.0 ms on a quiet machine (three runs, this run); mean 0.49 to
  0.55 ms, 99th percentile 1.7 to 2.0 ms on the busier machine of the first attempt; mean 0.8 to 1.2 ms and 99th percentile 7 to 10 ms
  before the two changes. On a board this small nearly all of the gain is the bounded search; the cached pathfinder pays on big
  boards (400 short questions on the 72x40 kingdom: 3.5 ms instead of 43 ms).
- **Docs.** `docs/ARCHITECTURE.md` (the cell kinds, leaps and rays, pathing and its cost, the footprint note, the test folders),
  `docs/coding-standards.md` (a section "The board answers, systems ask", the `tests/perf/` folder, the built-in table), `CLAUDE.md` (a
  rule for the board; its "arrives in M3a" lines were already rewritten in steps 1 and 2), `AGENTS.md` (status and next milestone),
  `tools/README.md` (the painter and both paint tools), `docs/OWNER_GUIDE.md` (a row for tagging a tile's `kind` in the TileSet
  editor; the two rows that said "available after M3a" now say available now, with what is still missing), `task_plan.md` (row 82 is
  `human_review`), `findings.md`.
- **Verification.** `python3 tools/run_all_tests.py --strict`: 58 suites (52 at the end of step 2), 0 failed, 0 warnings, GREEN, baseline
  labels 235 of 235 (11 through `label_renames.txt`); `--self-test` and `move_res.py --self-test` 0 failures; the import pass clean;
  `stamp_uids.gd -- --check` CLEAN; `git diff --check` clean; every new `.gd` has its `.gd.uid`. The six room dumps equal their
  baselines byte for byte. A fresh `git clone` of the branch plus `bootstrap_worktree.sh` is green too and its `git status` is clean
  (see the final report of the run). Tag `m3a-done`.
- **Not done (M3a is complete; these belong to M3b).** `game_root` still WRITES `PlayerTag.control_enabled`,
  `PlayerCombat.sword_unlocked`, the health carry and `VIEW_REF`, and nothing pushes on `world.commands` or `view_commands` yet; the
  shell does not pass a `PlayerSnapshot` to `EcsBoot` yet. Multi-cell footprints are M8b's. No tile of the shipped TileSets says `gap`,
  `leapable_block`, `chalk` or `corruption`: the art comes with the milestones that use them.
