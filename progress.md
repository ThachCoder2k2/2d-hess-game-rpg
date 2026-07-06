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

- Added gameplay templates `scenes/actors/black_pawn.tscn`, `scenes/actors/knight_enemy.tscn`, and `scenes/world/weapon_pickup.tscn`.
- Updated `EnemySpawnPoint` and `PickupSpawnPoint` to instantiate editor-assigned PackedScenes first, with script constructors kept only as compatibility fallbacks.
- Updated `first_encounter.tscn` so its enemy and pickup markers reference those PackedScene templates.
- Added `resources/attacks/wooden_sword.tres` and `resources/attacks/pencil_thrust.tres`, then assigned them to `player.tscn`.
- Updated `PawnHero` to use exported attack profiles from the scene while preserving default profiles for bare script tests.
- Exposed `PrototypeBoard` board, telegraph, impact, and debug colors as Inspector-editable theme fields.
- Expanded tests to verify player attack Resource ownership and scene-backed room spawns.
- Verified `run_tests.gd`, `attack_runtime_test.gd`, component movement/equipment/Knight tests, room encounter runtime, encounter HUD runtime, 1,200-frame headless launch, editor import, MCP project info, and `git diff --check`.

## Editor-Owned Actor Visuals - 2026-07-06

- Added reusable visual scenes for the hero pawn, black pawn, knight, and weapon pickup.
- Updated player, enemy, base enemy, and pickup scenes so each owns an editable `Visual` child instance.
- Moved actor and pickup body/weapon/health/telegraph drawing out of `PawnHero`, `BlackPawn`, `KnightEnemy`, and `WeaponPickup`; gameplay scripts now sync state into visual child nodes.
- Linked `VisualDefinition` Resources to the new pawn and knight visual scenes.
- Added tests proving player, base enemy, and room-spawned enemies/pickups own visual children.
- Fixed one Godot import-order issue by using dynamic visual child calls from older gameplay scripts.
- Verified `run_tests.gd`, `attack_runtime_test.gd`, component movement/equipment/Knight tests, `room_encounter_runtime_test.gd`, `encounter_hud_runtime_test.gd`, 1,200-frame headless launch, editor import, and `git diff --check`.

## Generic Enemy Scene Variants - 2026-07-06

- Changed `scenes/actors/black_pawn.tscn` and `scenes/actors/knight_enemy.tscn` so both use `EnemyActor` as the root script.
- Added movement, brain, attack, health, equipment, and debug component children directly to those gameplay enemy templates.
- Kept old `BlackPawn` and `KnightEnemy` scripts only as temporary legacy/test compatibility paths.
- Moved Knight flanker positioning behavior into `EnemyActor` when its archetype role is `flanker`.
- Updated HUD and main-scene status copy to read enemy display names from `EnemyDefinition` data instead of class checks.
- Updated room and main tests to verify scene-spawned enemies are generic `EnemyActor` variants with Pawn/Knight definitions.
- Verified `run_tests.gd`, `attack_runtime_test.gd`, component movement/equipment/Knight tests, `room_encounter_runtime_test.gd`, `encounter_hud_runtime_test.gd`, 1,200-frame headless launch, editor import, and `git diff --check`.

## Health Component Extraction - 2026-07-06

- Updated `EnemyActor.take_damage()` to delegate damage and defeat handling to `HealthComponent`.
- Expanded `HealthComponent` so it owns health reduction, hurt flash/recoil values, attack-token release, grid unregistering, defeat signal emission, and delayed cleanup.
- Added an editor-visible `AnimationPlayer` inside `scenes/components/health_component.tscn` with `hurt` and `defeat` animations targeting the enemy actor root.
- Kept `FreeEnemy.take_damage()` as the legacy direct-test fallback while scene-spawned enemies use the component path.
- Added tests proving the health component owns feedback animations, hurt feedback state, and defeat cleanup.
- Verified `run_tests.gd`, `attack_runtime_test.gd`, component movement/equipment/Knight tests, `room_encounter_runtime_test.gd`, `encounter_hud_runtime_test.gd`, 1,200-frame headless launch, editor import, and `git diff --check`.
