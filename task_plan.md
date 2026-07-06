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
| 32. Health extraction | pending | Move health, hit response, and defeat state into component |
| 33. AI workflow rules | complete | `AGENTS.md` defines editor-first rules, planning workflow, verification commands, and next-phase guidance for future AI agents |
| 34. Human editor workflow | complete | `AGENTS.md` defines AI/human ownership, editor handoff format, in-editor review checklists, and full game completion gates |
| 35. Editor-first encounter scaffolding | complete | `RoomEncounter`, enemy/pickup spawn point scenes, and `first_encounter.tscn` now own the first room's blockers, pickups, enemies, and message |
| 36. Editor-owned room objectives | complete | `RoomObjective` Resources now own room objective text, defeat text, and win-condition logic while `RoomEncounter` emits room completion |
| 37. Editor-owned main scene foundation | complete | `Main.tscn` now owns editor-visible world, director, board, player, room, and HUD scene children while `main.gd` binds to scene nodes with test fallbacks |
| 38. Scene-backed spawn templates | complete | Enemy and pickup spawn markers now instantiate editor-assigned PackedScenes, player attacks use `.tres` profiles, and board theme colors are Inspector-editable |
| 39. Editor-owned actor visuals | complete | Player, Pawn, Knight, base enemy, and weapon pickup presentation now live in scene-owned `Visual` children instead of actor/pickup `_draw()` methods |

## Editor-First Full Game Roadmap

This roadmap is the long-range production plan for making the whole game in Godot Editor first. Scripts should provide reusable behavior, but rooms, enemies, pickups, UI, animations, VFX, SFX, and narrative beats should be authored through scenes, child nodes, Resources, and Inspector fields whenever practical.

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
- `scenes/actors/player.tscn`
- `scenes/actors/black_pawn.tscn`
- `scenes/actors/knight_enemy.tscn`
- `scenes/actors/enemy_base.tscn`
- `scenes/world/weapon_pickup.tscn`
- `scenes/visuals/pawn_hero_visual.tscn`
- `scenes/visuals/black_pawn_visual.tscn`
- `scenes/visuals/knight_enemy_visual.tscn`
- `scenes/visuals/weapon_pickup_visual.tscn`
- `scenes/world/grid_world.tscn`
- `scenes/world/prototype_board.tscn`
- `scenes/combat/encounter_director.tscn`
- `scenes/ui/hud.tscn`
- Next: extract enemy health into `HealthComponent`, then move board/debug presentation and hit/telegraph feedback toward reusable VFX/SFX/AnimationPlayer scenes.

Acceptance criteria:
- `scenes/main.tscn` opens with visible child nodes for world, combat director, board, player, room, and HUD.
- `main.gd` coordinates already-authored child scenes instead of constructing the full scene tree directly.
- Direct script instantiation in tests still works through scene fallback creation.
- Enemy and pickup spawn markers instantiate editor-assigned PackedScenes for live gameplay nodes.
- Player attack profiles and board theme values are configurable through `.tres` Resources or Inspector exports.
- Player, enemies, base enemy, and weapon pickups own editable `Visual` scene children for placeholder presentation.
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
- `RoomObjective` Resources own room start/clear/defeat copy and win-condition checks; `RoomEncounter` emits `room_completed`, while `main.gd` only reacts with HUD/result flow.
- `Main.tscn` now owns editor-visible child scene instances for GridWorld, EncounterDirector, PrototypeBoard, PawnHero, FirstEncounter, and HUD; `main.gd` resolves those child nodes first and uses scene fallbacks only for tests.
- Spawn markers should prefer `PackedScene` templates (`black_pawn.tscn`, `knight_enemy.tscn`, `weapon_pickup.tscn`) and keep direct constructors only as compatibility fallbacks.
- Gameplay actors and pickups should not own production `_draw()` methods directly; presentation belongs in visible `Visual` child scenes such as `pawn_hero_visual.tscn`, `black_pawn_visual.tscn`, `knight_enemy_visual.tscn`, and `weapon_pickup_visual.tscn`.

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
