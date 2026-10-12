# GP.2 Spec - Player Movement Feel

**Status:** draft for owner review  
**Linked lane:** Gameplay  
**Checklist gate:** `GP.2`

## Purpose

Define how the pawn should feel when moving before final tuning begins.

## Movement Identity

The pawn moves like a freed chess piece:

```text
one cell per step
four directions
fast real-time response
clear commitment
no diagonal movement
turning without moving
```

## Starting Feel Targets

| Value | Target |
|---|---:|
| Step duration | ~0.16-0.20 seconds |
| Hold repeat delay | ~0.20-0.24 seconds |
| Input buffer | ~0.10-0.12 seconds |
| Turn without moving | immediate |
| Attack movement lock | short, readable |

These are tuning targets, not permanent laws.

## Required Feel

- First tap should respond immediately.
- Holding a direction should feel steady, not slippery.
- The player should understand when a step is committed.
- Turning should solve "I need to face this way" without forcing movement.
- Movement must remain readable during telegraphs.

## Completion Requirements

`GP.2` can be approved only after a playable test confirms:

- step timing feels right to the owner,
- hold movement is comfortable,
- turning without moving is useful,
- movement matches the grid visually,
- and combat decisions remain readable at speed.

## Cannot Approve If

- the pawn feels floaty,
- the player overshoots cells often,
- turning is awkward or too slow,
- movement animation disagrees with collision,
- or the owner says the movement no longer feels like a pawn.

