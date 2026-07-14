# Combat and Telegraph

The attack lifecycle, the fairness token, and the dodge — the core Into-the-Breach-style
loop. Combat is cell-based (never physics): a hit = "is the target's cell in the locked
set".

Back to [[Home]] · related: [[Enemy AI]] · [[Player]] · [[Grid World]] · [[Data Resources]]

## The attack token — EncounterDirector
**File:** `scripts/combat/encounter_director.gd` · **Class:** `EncounterDirector`
One room-wide token. An enemy must `request_attack(self)` before telegraphing; only one
holder at a time, so enemies can't all strike the same frame. `release_attack` frees it;
`set_paused` clears it (room end). Self-heals if the holder was freed
(`is_instance_valid` check). Emits `token_changed` → HUD shows who's winding up.

## The enemy attack lifecycle ([[Enemy AI|FreeEnemy]])
```
_choose_action picks ATTACK
  └─ director.request_attack(self)   denied → RECOVER (no pile-on)
     lock target cells, state = TELEGRAPH, state_time_left = telegraph_time
     emit telegraph_started(cells)   → PrototypeBoard draws red danger cells
        ... telegraph window (the player's reaction time) ...
  └─ _resolve_attack():
     if target.current_cell in locked_attack_cells:  target.take_damage()
     emit attack_resolved  → board flashes the hit
     director.release_attack(self);  state = RECOVER
```

## The dodge (why it works)
Damage checks `current_cell`, and a [[Movement|step]] claims its destination instantly.
So if you step out of the telegraphed cells before `_resolve_attack` fires, the `in`
check fails → **no damage**. This is the whole skill of the game. Locked in by a test
("hero dodges the telegraphed strike and takes no damage").

## Attack shapes are data
Unarmed shape = an [[Data Resources|AttackPattern]] `.tres` (`cell_offsets`,
`uses_facing`, `clip_to_board`). Player weapons = `AttackProfile`; enemy toy weapons =
`EnemyWeapon` (LINE/FAN). Equipping a weapon replaces the chess attack
(`EquipmentComponent`). New attack shape = new `.tres`, no code.

## Player side
`PawnHero.try_attack` (see [[Player]]) is the mirror: telegraph-less (you're the one
reacting), impact delay → damage cells → recovery, and `attack_landed` drives screen
shake + board flash.
