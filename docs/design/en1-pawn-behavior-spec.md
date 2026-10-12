# EN.1 Spec - Pawn Behavior

**Status:** draft for owner review  
**Linked lane:** Enemy And Boss Design  
**Checklist gate:** `EN.1`

## Purpose

The Black Pawn is the first enemy teacher. It must teach that enemies are bound
by readable chess-shaped threats while the player can break rules through free
cardinal movement.

## Pawn Combat Question

```text
Can I approach the pawn without standing in its forward diagonals?
```

## Required Behavior

| Behavior | Requirement |
|---|---|
| Movement | Moves one cardinal cell at a time |
| Facing | Faces the direction of its last movement |
| Unarmed threat | Attacks forward-left and forward-right diagonals |
| Telegraph | Shows both diagonal danger cells before impact |
| Recovery | Leaves enough time for player to step and punish |
| Weapon pickup | If armed, weapon replaces diagonal attack |
| Group role | Pressures but does not overwhelm first-chain player |

## First-Chain Pawn Variant

For `T3_ChessRugBattlefield`, use **Pawn Recruit**:

- slowest pawn telegraph,
- longest recovery,
- one or two total pawns,
- no weapon pickup in the first version unless owner approves extra complexity.

## Telegraph Drawing

```text
    [ ] [P] [ ]
    [x] [ ] [x]

P = pawn facing downward
x = threatened diagonal cells
```

## Counterplay

The player should learn:

- standing directly in front is safer than standing diagonally,
- turning matters,
- stepping one cell can avoid a threat,
- attacking after recovery is the clean punish.

## Completion Requirements

`EN.1` can be approved only if:

- the pawn teaches diagonal danger clearly,
- the first pawn does not feel unfair,
- armed pawn behavior remains a later escalation,
- telegraphs are readable on chess-rug tiles,
- and the owner agrees Pawn Recruit is the right first enemy.

## Cannot Approve If

- the pawn attacks without a visible tell,
- the first combat requires advanced skills,
- weapon behavior stacks on top of diagonal attack,
- or the pawn feels like a generic chaser instead of a chess-shaped threat.

