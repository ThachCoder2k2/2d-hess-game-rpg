# The Unbound Pawn - Implementation Plan

## Goal

Build the first playable Godot 4 vertical slice. Current milestone: free-moving enemies, weapon pickups, armed attack replacement, coordinated attacks, and Knight AI.

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
