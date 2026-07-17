# Room Authoring Guide

Use this when editing the first encounter in Godot Editor.

## Scene To Open

Open:

`scenes/rooms/first_encounter.tscn`

You can also open `scenes/main.tscn`; `PawnHero` and `FirstEncounter` have editable children enabled there. For room layout work, editing `first_encounter.tscn` directly is cleaner.

## Nodes You Can Move

These nodes are gameplay markers. Drag them on the grid; their `grid_cell` updates and the runtime uses that cell.

- `PencilSpearPickup`, `RulerBladePickup`: weapon pickup cells.
- `PawnRecruit`, `ArmedPawn`, `KnightTracker`: the real enemies — instances of their
  actor scenes, parked where they fight. Drag one to move its start; instance any
  enemy scene and park it on a cell to add one. Override `definition` on an
  instance to vary it (the armed pawn is `black_pawn.tscn` + `pawn_armed.tres`).

The markers snap to the 32px grid in editor.

The hero has no marker: drag the `PawnHero` node itself (in `scenes/main.tscn`) onto a
cell — wherever it stands is where it spawns. Any position inside a cell works; the
runtime floors it to that cell and re-centers the sprite. For click-to-cell snapping
while dragging, enable the editor's grid snap (magnet icon): grid step `32 × 32`,
offset `16 × 20`.

## Walls: paint them

Walls are painted, not placed as markers. Any tile whose TileSet custom data has
`solid = true` (the stone wall, throne, and banner tiles in the kingdom set) blocks
movement and pathing automatically. Paint a wall tile on `RoomArt/TileMap` with
Godot's TileMap tools → that cell is a wall. Erase it → the cell opens. Art and
collision are the same action and can never disagree.

## Nodes That Are Visual Only

- `RoomArt/TileMap`: TileMapLayer for board floor tiles (solid tiles also block — see above).
- `RoomArt/GridLines`: visible grid lines.
- `RoomArt/Boundary`: crayon/tape boundary art.
- `RoomArt/SetDressing`: background props.

Move these for presentation only. They do not change gameplay unless paired with a marker.

## Inspector Fields

- Enemy markers expose `enemy_scene`, `definition`, and optional `starting_weapon`.
- Pickup markers expose `pickup_scene` and `weapon`.
- `FirstEncounter.objective` controls start/clear/defeat text and win condition.
- `FirstEncounter.blocked_cells` is a legacy fallback; blocker marker nodes are preferred.

## Quick Editing Loop

1. Open `scenes/rooms/first_encounter.tscn`.
2. Drag enemy markers, pickup markers, or blocker markers (the hero: drag `PawnHero` in `scenes/main.tscn`).
3. Use Godot's TileMap tools on `RoomArt/TileMap` when changing board floor tiles.
4. Press Play from `scenes/main.tscn`.
5. If the first 10 seconds feel messy, move fewer things at once and retest.
