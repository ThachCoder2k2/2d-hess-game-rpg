# Movement

How a body steps from one cell to the next. The actor side of the [[Grid World]]
reserve → commit protocol.

Back to [[Home]] · related: [[Grid World]] · [[Player]] · [[Enemy Composition]]

## GridActor (base)
**File:** `scripts/actors/grid_actor.gd` · **Class:** `GridActor` (extends Node2D)
The shared base of the [[Player]] and enemies. Owns:
- `current_cell`, `facing`, `is_moving`, `step_duration`.
- signals `step_started(origin, dest)`, `step_finished(dest)`.
- `try_step(direction)` — the one entry point: asks [[Grid World]] `begin_move`, and if
  granted, tweens `position` to the destination's world point, then on finish calls
  `finish_move` and emits `step_finished`.

The **tween** is Godot's built-in `Tween` (built-in-first rule) — the sprite slides
smoothly while the *logic* already knows the destination cell.

## GridMovementComponent
**File:** `scripts/components/grid_movement_component.gd`
The [[Enemy Composition|component]] version of the same thing, so enemies get movement
without inheriting a big base. `EnemyActor.try_step` delegates here → `request_step` →
`begin_move` → tween → `_finish_step` → `finish_move`. It guards with
`cell_by_actor.has(actor)` so a freed/unregistered actor can't finish a stale move.

## The lifecycle of one step
```
try_step(dir)
  └─ GridWorld.begin_move(actor, dest)   reserve dest (fail → bump, no move)
       emit step_started
       Tween: position → cell_to_world(dest)   (~0.18s, presentation only)
  └─ on tween finish:
       GridWorld.finish_move(actor, dest)  free origin, occupy dest
       current_cell = dest
       emit step_finished
```

Key idea: **logic is instant, animation is cosmetic.** The cell is claimed the moment
you press a key; the slide is just the eye catching up. This is what makes the
[[Combat and Telegraph|dodge]] and honest AI targeting work.
