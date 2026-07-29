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
