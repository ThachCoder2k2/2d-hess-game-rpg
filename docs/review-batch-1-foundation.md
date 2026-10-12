# Review Batch 1 - Foundation Approval

**Status:** approved by owner on 2026-09-30  
**Purpose:** approve or revise the game's foundation before implementation plans.  
**Batch source:** `docs/production-review-dashboard.md`

This batch combines the foundation decisions that must agree with each other:

- `GP.1` core gameplay loop
- `LD.2` first room chain
- `LD.1` bedroom world layout
- `ART.1` visual target
- `NAR.1` story outline
- `TECH.2` room transition model

Approving this batch does not approve implementation directly. It allows Codex
to create the first concrete production specs and implementation plans.

---

## Foundation Decision Summary

## 1. Game Identity

The game is:

```text
A top-down real-time grid action adventure about a pawn crossing a child's
bedroom chess war, where chess rules, toys, paper, and imagination become
the combat system.
```

The game is not:

```text
a normal fantasy kingdom
a pure chess puzzle game
a free-movement action RPG
a generic roguelike
```

## 2. Core Gameplay Loop

Approved direction:

```text
Enter readable room
read danger
step one grid cell
turn / strike / wait / reposition
solve the room's board-state problem
receive route, story, reward, or pressure toward the next room
```

First-chain verbs:

```text
move
hold movement
turn without moving
pick up sword
strike
read pawn telegraph
```

Not first-chain full systems:

```text
full child intervention
full skill loadout
boss mechanics
complex weapon switching
```

## 3. First Playable Room Chain

Approved direction:

```text
T1_WhiteKingsFall
  -> T2_FallenSwordTile
  -> T3_ChessRugBattlefield
  -> H1_ChessRugHub
```

Purpose:

| Room | Purpose |
|---|---|
| T1 | movement, mood, White King's fall |
| T2 | sword pickup, turning, safe attack |
| T3 | first pawn combat and telegraph reading |
| H1 | hub reveal and future bedroom routes |

## 4. Bedroom World Layout

Approved direction:

```text
Chess Rug = opening battlefield and main hub
Toybox = Knight district
Bookshelf = Bishop district
Block Tower = Rook district
Dollhouse = Queen district
Under-Bed = Black King final
Desk = child/fourth-wall source
```

The player should feel the game is a bedroom first, imagined kingdom second.

## 5. Visual Target

Approved direction:

```text
top-down pixel art
Enter-the-Gungeon-level combat readability
child's bedroom materials
chess silhouettes
warm but dangerous mood
props support gameplay before decoration
```

## 6. Story Spine

Approved direction:

```text
White King falls.
Pawn wakes alone.
Pawn takes sword.
Child notices.
Pawn and child learn to trust each other.
Bosses represent old rules and authority.
Black King represents the rule engine.
Pawn wins by becoming free, not by becoming royal.
```

Recommended ending meaning:

```text
The pawn remains a pawn, but the board no longer owns it.
```

## 7. Room Transition Model

Approved direction:

```text
separate editable room scenes
visible entry markers
visible exit markers
WorldGraph or equivalent room graph data
fade transition
player spawns at target entry
future locks and shortcuts supported
```

---

## Approval Questions

Please answer these as a batch:

| Question | Recommended Answer |
|---|---|
| Is one-cell real-time grid movement still the identity? | yes |
| Is `T1 -> T2 -> T3 -> H1` the right first chain? | yes |
| Is the chess rug the correct opening/hub location? | yes |
| Is the bedroom-object district layout correct? | yes |
| Is top-down pixel art the right visual target? | yes |
| Should combat readability beat decoration? | yes |
| Should the pawn stay a pawn thematically? | yes |
| Should child intervention be foreshadowed before fully unlocked? | yes |
| Should rooms be separate editable Godot scenes? | yes |
| Should room transitions use visible exits/entries and fade-swap? | yes |

---

## If Approved

If this batch is approved, the next planning tasks are unlocked:

```text
T1_WhiteKingsFall production spec
Gameplay sandbox implementation plan
First-chain room transition implementation plan
First-chain art target breakdown
Opening script draft
```

Recommended next single task:

```text
Create T1_WhiteKingsFall production spec.
```

## If Not Approved

Revise the specific disagreement before implementation. Do not build around an
unclear foundation.

Possible revision areas:

- first room chain order,
- bedroom layout,
- art target,
- pawn ending meaning,
- child intervention timing,
- room transition model.

---

## Approval State

Current state:

```text
approved
```

Owner decision:

```text
approved 2026-09-30
```
