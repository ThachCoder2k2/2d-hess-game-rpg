# The Unbound Pawn

A Godot 4 top-down grid action adventure about a white pawn that breaks free from the rules of chess.

## Current Milestone

The first playable foundation includes:

- 640x360 pixel-perfect 2D presentation.
- One-cell cardinal movement.
- Buffered and held movement.
- `Shift + direction` turning without movement.
- One-cell Wooden Sword attacks.
- Two-cell Pencil Thrust skill on `Q`.
- Black Pawn AI with diagonal attack telegraphs.
- Free cardinal enemy movement.
- Knight enemy with L-shaped unarmed attacks.
- Enemy weapon pickups and pre-armed variants.
- Pencil Spear and Ruler Blade replacement attack patterns.
- Encounter attack token preventing simultaneous strikes.
- Player damage, invulnerability, defeat, and room reset.
- A styled Pawn Ambush playground room.
- Headless grid-logic tests.

## Run

Open `project.godot` in Godot 4.6 or run:

```bash
../Godot.app/Contents/MacOS/Godot --path .
```

## Test

```bash
../Godot.app/Contents/MacOS/Godot --headless --path . -s tests/run_tests.gd
```

## Controls

- `WASD` or arrows: move one cell.
- `Shift + direction`: turn without moving.
- `Space` or `K`: Wooden Sword.
- `Q`: Pencil Thrust.
- `R`: reset the room.

## Design

The approved GDD, pixel-art bible, and vertical-slice design live in `docs/design/`.
