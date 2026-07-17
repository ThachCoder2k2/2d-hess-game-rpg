# Player

**File:** `scripts/actors/pawn_hero.gd` · **Class:** `PawnHero` (extends [[Movement|GridActor]])
**Scene:** `objects/actors/player.tscn` (PawnHero + its own sprites/AnimationPlayer + Camera2D + two attack `.tres`)
The white pawn you control.

Back to [[Home]] · related: [[Movement]] · [[Combat and Telegraph]] · [[Data Resources]] · [[Presentation]]

## Input (in `_process`)
- **WASD / arrows** → move one cell (`try_step`).
- **Shift + direction** → turn without moving (`try_turn`).
- **Space** → Wooden Sword (`try_attack(wooden_sword)`).
- **Q** → Pencil Thrust skill (2-cell), on a cooldown.
- Held direction repeats after `held_repeat_delay`; a direction pressed mid-move is
  **buffered** and fires on `step_finished`.

## Tunable exports (Inspector)
`courage` (HP), `held_repeat_delay`, `invulnerability_duration`,
`pencil_thrust_cooldown`, and the two attack profiles `wooden_sword` / `pencil_thrust`
(assigned in the scene; loaded from `.tres` as a fallback — never hardcoded).

## Attacking (`try_attack`)
A coroutine, driven by the [[Data Resources|AttackProfile]]:
1. Set cooldown, compute target cells (`profile.get_target_cells(cell, facing)`).
2. `await` `impact_delay` → damage every actor on a target cell (`take_damage`).
3. `emit_signal("attack_landed")` → [[World and Rooms|Main]] shakes the screen + the
   board flashes the hit.
4. `await` recovery → free to act; consume any buffered move.
Guards re-check `is_inside_tree()` after each `await` (safe if the scene reloads mid-attack).

## Taking damage (`take_damage`)
If invulnerable or already at 0 courage → ignored. Else lose courage, emit `damaged`
+ `courage_changed` (HUD reacts), then either `defeated` (→ reset) or start
invulnerability. `is_invulnerable` is set *synchronously* before the `await`, so two
hits on the same frame can't double-damage.

## What it does NOT do
No `_draw()` — it updates its own Sprite2D children through typed references
(`_update_appearance`, [[Presentation]]). No collision — movement legality is all
[[Grid World]] cells.
