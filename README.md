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
- TileMapLayer-based board floor with reusable TileSet assets.
- Editor-authored first encounter art, blockers, spawn previews, and pickup previews.
- Draggable room authoring markers for hero start, blockers, enemy spawns, and pickups.
- Real PNG sprite placeholders and AnimationPlayer clips for the hero, Pawns, Knight, pickups, and toy weapons.
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
For editing the current room in Godot, use `docs/design/room-authoring-guide.md`.

## Project Structure

- `scenes/`: main playable scenes, authored rooms, and UI scenes.
- `objects/`: reusable editable object templates such as actors, pickups, markers, components, visuals, and helper world nodes.
- `scripts/`: reusable behavior only; avoid putting room content directly in scripts.
- `resources/`: Inspector-tunable data for attacks, enemies, movement, weapons, objectives, visuals, and tiles.
