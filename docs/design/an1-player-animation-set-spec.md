# AN.1 Spec - Player Animation Set

**Status:** draft for owner review  
**Linked lane:** Animation  
**Checklist gate:** `AN.1`

## Purpose

The player pawn animation set must make movement, facing, attack timing, damage,
and emotional state readable while preserving grid accuracy.

## Required First-Slice Animations

| Animation | Purpose | Required For First Chain |
|---|---|---:|
| Wake | Opening story beat | yes |
| Idle | Calm readable base state | yes |
| Step | Movement clarity | yes |
| Turn | Facing without moving | yes |
| Sword attack | Basic combat timing | yes |
| Hurt | Damage feedback | yes |
| Defeat | Failure readability | yes |
| Pickup reaction | Sword moment | preferred |

## Animation Rules

- The pawn base stays anchored to the grid cell center.
- Movement animation must not imply diagonal movement.
- Attack anticipation must appear before the hit frame.
- Attack recovery must be visible enough for feel tuning.
- Hurt should be quick but readable.
- Defeat should be toy-like or chess-piece-like, not gore.

## First Chain Animation Needs

| Room | Animation Need |
|---|---|
| T1 | wake from fallen position into upright pawn |
| T2 | pickup sword, turn, sword test swing |
| T3 | attack, hurt, recovery under real pressure |
| H1 | idle/rest state that feels safe enough |

## Completion Requirements

`AN.1` can be approved only if:

- all first-chain player states have planned animation coverage,
- timing supports gameplay readability,
- grid anchor preservation is non-negotiable,
- and the owner accepts the pawn's motion personality.

## Cannot Approve If

- movement slides off-grid,
- attack hit timing is hidden,
- turn animation is too slow for combat,
- or wake/defeat animations undermine the serious opening tone.

