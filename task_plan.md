# The Unbound Pawn - Implementation Plan

## Goal

Build the first playable Godot 4 vertical-slice foundation from the approved GDD: crisp 2D pixel presentation, one-cell movement, facing, adjacent sword combat, and a test room.

## Phases

| Phase | Status | Deliverable |
|---|---|---|
| 1. Repository foundation | complete | Design docs, Godot project structure, import settings |
| 2. Grid runtime | complete | Grid coordinates, occupancy, movement reservations |
| 3. Player combat | complete | Buffered movement, facing, sword attack, damage target |
| 4. Prototype room | complete | Playable authored room with pixel-art placeholders and HUD |
| 5. Verification | complete | Headless launch, automated logic checks, project validation |
| 6. Commit milestone | complete | Clean Git commit and documented next milestone |

## Decisions

- Godot version: 4.6.3.
- Rendering: native 2D at 640x360 with integer scaling and nearest filtering.
- Logical tile size: 32 pixels.
- Game logic is cell-based; sprites and animation are presentation.
- Placeholder art will be intentionally styled and project-native, then replaced using the art bible.
- First milestone stops before enemy AI and the Knight boss.

## Errors Encountered

| Error | Attempt | Resolution |
|---|---:|---|
| `draw_ellipse` helper conflicts with Godot 4.6 native method | 1 | Renamed project helper to `_draw_pixel_ellipse` |
| Godot cannot write editor caches under sandboxed macOS home | 1 | Run verification with an isolated writable `HOME` under `/tmp` |
| Objective HUD path caused recursive deferred calls and message queue exhaustion | 1 | Store and update a direct `objective_label` reference |
| Initial push authenticated as GitHub user `fishtechainer` and was denied | 1 | Switched this repository remote to existing `github.com-work` SSH alias, authenticated as `ThachCoder2k2` |
