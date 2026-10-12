# AN.2 Spec - Enemy Animation Set

**Status:** draft for owner review  
**Linked lane:** Animation  
**Checklist gate:** `AN.2`

## Required Enemy Animations

| Animation | Purpose |
|---|---|
| Idle | readable waiting state |
| Move | one-cell movement clarity |
| Alert | notices or prepares |
| Windup | threat is coming |
| Commit | attack resolves |
| Recover | punish window |
| Hurt | damage feedback |
| Defeat | clear removal/disable |

## Completion Requirements

`AN.2` can be approved only if:

- enemy intent is readable before impact,
- common enemies support at least idle/move/windup/commit/hurt/defeat,
- and animation timing can align with telegraph timing.

## Cannot Approve If

- attacks resolve before windup reads,
- enemy motion hides cell position,
- or enemies feel alive but unfair.

