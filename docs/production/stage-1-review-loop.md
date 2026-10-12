# Stage 1 Review Loop

**Date:** 2026-10-05  
**Status:** active self-review loop complete for structural gameplay  
**Purpose:** review Stage 1 like a first-stage production pass, add the
highest-impact missing features, verify, then repeat until remaining work is
mainly tuning/art judgment.

---

## Review Pass 1 - Boss Cannot Be Skipped

Finding:

- The Stage 1 spine reached `B1_BlackPawnCaptain`, but the player could leave
  to `H1_ChessRugHub` without defeating the captain.
- That breaks the commercial tutorial pattern: the first boss must prove the
  player learned the opening mechanics.

Implemented:

- Added `requires_room_clear` to `ZoneExitMarker`.
- Movement now emits `zone_exit_locked` instead of travelling when a locked
  exit is touched while enemies are alive.
- `main.gd` gives feedback when the captain gate is still locked.
- `B1_BlackPawnCaptain/Exit_To_Hub` requires room clear.
- Tests verify locked exits block while enemies live and unlock after defeat.

Result:

- The Pawn Captain is now a real tutorial gate.

---

## Review Pass 2 - Sword Moment Must Be Real

Finding:

- The story says the pawn becomes free after grabbing the fallen sword, but
  the runtime still let the pawn attack from the start.

Implemented:

- Added `PlayerUnlockMarker`, an editor-visible marker for player progression
  unlocks.
- Added a `FallenSwordUnlock` marker in `T2_FallenSwordTile`.
- Added `wooden_sword` persistence to `WorldState`.
- In world mode, player combat starts locked until `wooden_sword` is unlocked.
- Pressing attack before the sword gives HUD feedback instead of swinging.
- Tests verify locked sword attacks are refused and the unlock persists.

Result:

- T1 is now movement-only.
- T2 is now the real moment where the pawn gains the sword.

---

## Review Pass 3 - Tutorial Rooms Cannot Be Skipped

Finding:

- The first duel and rule-break escalation rooms could be skipped by walking
  straight to the forward exit.

Implemented:

- `T3_FirstPawnClash/Exit_To_T4` requires room clear.
- `T4_BrokenRuleYard/Exit_To_B1` requires room clear.
- Backtracking exits remain open.
- Tests verify these forward tutorial exits require room clear.

Result:

- Stage 1 now has real teach/test gates:

```text
move -> sword -> duel -> rule-break escalation -> boss -> hub
```

---

## Review Pass 4 - Old Saves Must Not Skip The New Start

Finding:

- `WorldState` persists the current zone across launches. After changing the
  project start from the old kingdom map to the new T1 opening, an obsolete
  development save could boot the player into the wrong place.

Implemented:

- Added a `WorldState` save version.
- Loading an older save now resets to the current authored start.

Result:

- The new Stage 1 opening is the reliable starting point for this pass.

---

## Remaining Review Items

These should not be brute-forced without editor/player judgment:

- exact enemy positions in T3, T4, and B1,
- whether the boss has enough health/pressure,
- whether T2 sword pickup is visually obvious enough,
- whether room art reads well at 640x360,
- whether child narration tone feels right,
- whether the hub clearly points toward Toybox as Act 2.

The next best pass is an in-editor play review, then tune placements and
messages based on what feels confusing or weak.
