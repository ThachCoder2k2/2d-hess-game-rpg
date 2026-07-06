# Room Authoring Guide

Use this when editing the first encounter in Godot Editor.

## Scene To Open

Open:

`scenes/rooms/first_encounter.tscn`

You can also open `scenes/main.tscn`; `PawnHero` and `FirstEncounter` have editable children enabled there. For room layout work, editing `first_encounter.tscn` directly is cleaner.

## Nodes You Can Move

These nodes are gameplay markers. Drag them on the grid; their `grid_cell` updates and the runtime uses that cell.

- `HeroStart`: player spawn cell.
- `Blocker_*`: blocked cells. Moving one changes collision/pathing.
- `PencilSpearPickup`, `RulerBladePickup`: weapon pickup cells.
- `PawnRecruitSpawn`, `ArmedPawnSpawn`, `KnightTrackerSpawn`: enemy spawn cells.

The markers snap to the 32px grid in editor.

## Nodes That Are Visual Only

- `RoomArt/Tiles`: board color tiles.
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
2. Drag `HeroStart`, enemy markers, pickup markers, or blocker markers.
3. Press Play from `scenes/main.tscn`.
4. If the first 10 seconds feel messy, move fewer things at once and retest.
