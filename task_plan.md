# The Unbound Pawn - Implementation Plan

## Goal

Build the first playable Godot 4 vertical slice. Current milestone: turn-in-place, flexible attack profiles, Pencil Thrust, Black Pawn AI, telegraphs, player damage, and room reset.

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

## Decisions

- Godot version: 4.6.3.
- Rendering: native 2D at 640x360 with integer scaling and nearest filtering.
- Logical tile size: 32 pixels.
- Game logic is cell-based; sprites and animation are presentation.
- Placeholder art will be intentionally styled and project-native, then replaced using the art bible.
- First milestone stops before enemy AI and the Knight boss.
- `Shift + direction` turns the pawn without moving.
- The slice loadout is one Wooden Sword plus Pencil Thrust on `Q`.
- Pencil Thrust reaches two cells and has longer recovery.
- Pencil Thrust uses cooldown only during the slice; resource cost waits for playtesting.

## Errors Encountered

| Error | Attempt | Resolution |
|---|---:|---|
| `draw_ellipse` helper conflicts with Godot 4.6 native method | 1 | Renamed project helper to `_draw_pixel_ellipse` |
| Godot cannot write editor caches under sandboxed macOS home | 1 | Run verification with an isolated writable `HOME` under `/tmp` |
| Objective HUD path caused recursive deferred calls and message queue exhaustion | 1 | Store and update a direct `objective_label` reference |
| Initial push authenticated as GitHub user `fishtechainer` and was denied | 1 | Switched this repository remote to existing `github.com-work` SSH alias, authenticated as `ThachCoder2k2` |
| Pencil Thrust used an async attack return value inside `if` | 1 | Added synchronous `can_start_attack()` guard and launched the coroutine separately |
| Turn action accidentally included Ctrl due to keycode assumption | 1 | Inspected `InputEvent.as_text()`, removed Ctrl, and added a binding test |
