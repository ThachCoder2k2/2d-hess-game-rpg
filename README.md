# The Unbound Pawn

A Godot 4 top-down grid action adventure about a white pawn that breaks free from the rules of chess.

## Current Milestone

The first playable foundation includes:

- 640x360 pixel-perfect 2D presentation.
- One-cell cardinal movement.
- Buffered and held movement.
- Four-direction facing.
- One-cell sword attacks.
- Damageable training enemies.
- A styled playground test board.
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

## Design

The approved GDD, pixel-art bible, and vertical-slice design live in `docs/design/`.

