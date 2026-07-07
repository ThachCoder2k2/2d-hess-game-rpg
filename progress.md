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
