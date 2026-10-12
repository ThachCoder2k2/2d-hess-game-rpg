# Review Batch 2 - First Playable Feel

**Status:** draft for owner review  
**Purpose:** approve or revise the feel targets for the first playable combat slice.  
**Batch source:** `docs/production-review-dashboard.md`

This batch defines how the game should feel in the player's hands before we
start building or tuning mechanics.

Approving this batch does not approve implementation directly. It allows Codex
to create implementation plans for the gameplay sandbox and first combat tests.

---

## Included Gates

| Gate | Spec |
|---|---|
| `GP.2` | `docs/design/gp2-player-movement-feel-spec.md` |
| `GP.3` | `docs/design/gp3-basic-sword-combat-spec.md` |
| `EN.1` | `docs/design/en1-pawn-behavior-spec.md` |
| `FX.1` | `docs/design/fx1-telegraph-language-spec.md` |
| `FX.2` | `docs/design/fx2-hit-feedback-spec.md` |
| `AU.2` | `docs/design/au2-movement-attack-sfx-spec.md` |
| `UI.1` | `docs/design/ui1-hud-scope-spec.md` |

---

## Feel Direction Summary

## 1. Movement Feel

Approved direction:

```text
one cell per step
four directions only
fast real-time response
clear commitment
hold direction to repeat movement
turn without moving
```

Starting targets:

| Feel Value | Target |
|---|---:|
| Step duration | about 0.16-0.20 seconds |
| Hold repeat delay | about 0.20-0.24 seconds |
| Input buffer | about 0.10-0.12 seconds |
| Turn without moving | immediate |

Player feeling:

```text
snappy but not slippery
committed but not sluggish
chess-like but not slow
```

## 2. Sword Feel

Approved direction:

```text
one-cell facing attack
fast startup
clear hit frame
short recovery
reward for reading enemy recovery
not a spam button
```

The sword should feel brave because the pawn must get close.

## 3. First Enemy: Pawn Recruit

Approved direction:

```text
first enemy = slow Pawn Recruit
unarmed pawn attacks forward diagonals
clear diagonal telegraph before damage
long recovery after attack
one or two pawns only in first fight
no weapon pickup in the first version unless later approved
```

The Pawn Recruit teaches:

```text
read facing
avoid diagonals
step one cell out of danger
punish after recovery
```

## 4. Telegraph Language

Approved direction:

```text
dark orange = warning
coral red = immediate danger
crayon blue = child help
gold = interact/reward
mint = safe/heal
```

First test case:

```text
Black Pawn diagonal danger must read on both light and dark chess rug tiles.
```

## 5. Hit Feedback

Approved direction:

```text
brief flash
small chip/fragment particles
small camera shake on successful hit
stronger feedback for player damage
short hit stop only if it improves clarity
```

Hit feedback should confirm contact without hiding the next threat.

## 6. Action Audio

Approved direction:

```text
pawn step = small base tap
turn = subtle tick only if needed
sword swing = quick toy/metal whoosh
sword hit = sharp chip/crack
player hurt = unmistakable but not huge
```

Repeated movement audio must not become annoying.

## 7. Minimal HUD

Approved first-chain HUD:

```text
Courage / health
current weapon
short status prompt
optional enemy count
```

Do not show:

```text
child Believe meter before child intervention matters
unused skill slots
future systems
```

---

## Approval Questions

| Question | Recommended Answer |
|---|---|
| Should movement stay one-cell and committed? | yes |
| Should held movement repeat steps? | yes |
| Should turning without moving stay immediate? | yes |
| Should sword remain one-cell facing attack at first? | yes |
| Should first enemy be Pawn Recruit only? | yes |
| Should first pawn fight avoid weapon pickups? | yes |
| Should danger use strict color/shape language? | yes |
| Should first-chain HUD stay minimal? | yes |

---

## If Approved

If this batch is approved, these implementation-planning tasks may begin:

```text
gameplay sandbox production plan
movement tuning task
sword combat tuning task
Pawn Recruit first-combat task
first telegraph VFX test
minimal HUD review task
first-chain action audio task
```

Recommended next implementation-planning task after Batch 1 and Batch 2 approval:

```text
Gameplay sandbox production spec.
```

## If Not Approved

Revise the disagreement before tuning.

Possible revision areas:

- movement speed,
- hold-to-move behavior,
- turn behavior,
- sword range,
- first enemy complexity,
- telegraph colors,
- HUD amount.

---

## Approval State

Current state:

```text
draft
```

Owner decision:

```text
pending
```

