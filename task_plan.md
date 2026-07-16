# The Unbound Pawn - Implementation Plan

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
| 67. Redundancy cleanup (scene data + board) | complete | Killed the triple-defined blocker cells (markers stay the sole truth; removed the stale `blocked_cells` array from `first_encounter.tscn` and the board's `editor_blocked_cells` copy), deleted `PrototypeBoard`'s dead pre-TileMap floor path (`draw_base_layer`, base-layer colors, playground border, `@tool` editor preview — 309→216 lines; now a pure combat overlay), and dropped the never-read `telegraph_style` field from `AttackPattern` + its 3 `.tres` lines. Suite green, overlay frame verified |
| 66. Chess-piece proportions | complete | Researched the top-down convention (1 tile wide × 1.5–2 tiles tall, feet-anchored, top-half overlaps the row above, lower rows draw on top). Pieces scaled from ~34px icons to ~48px (1.5-cell) figures with feet anchors (BodySprite at (0,−8)); facing arrow/health pips/weapon anchor raised to match; row-based depth added (`GridActor.update_depth_from_row`: `z_index = 2 + cell.y`) so lower pieces overlap upper ones. Pickups stay flat/cell-sized. Presentation-only; suite green + frame verified |
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
- Player, enemies, base enemy, and weapon pickups own editable `Visual` scene children for placeholder presentation.
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
- Gameplay actors and pickups should not own production `_draw()` methods directly; presentation belongs in visible `Visual` child scenes such as `pawn_hero_visual.tscn`, `black_pawn_visual.tscn`, `knight_enemy_visual.tscn`, and `weapon_pickup_visual.tscn`.
- Enemy identity in runtime UI/status should come from `EnemyDefinition` data rather than class checks. Legacy `BlackPawn` and `KnightEnemy` classes remain only as direct-test compatibility until they are deleted.
- `EnemyActor.take_damage()` delegates to `HealthComponent`; legacy `FreeEnemy.take_damage()` remains only for old direct-test compatibility.
- Room floor, grid-line, boundary, and set-dressing presentation should live in the room scene under `RoomArt`; `PrototypeBoard` should stay responsible for telegraph cells, hit flashes, and debug path overlays.
- Gameplay placement should be represented by marker nodes, not parallel art plus hidden arrays. `RoomEncounter` should read markers first and keep exported arrays only as compatibility fallbacks.
- Board floor art should use TileMapLayer and TileSet assets. Avoid adding one Polygon2D node per floor tile.
- Keep reusable object `.tscn` templates under `objects/`; keep `scenes/` limited to playable/editor entry scenes, rooms, and UI.
- Actor and pickup bodies should be real sprite/animation scene nodes. Do not reintroduce `_draw()` body rendering in `scripts/visuals/piece_visual.gd` or `scripts/visuals/pickup_visual.gd`.

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
