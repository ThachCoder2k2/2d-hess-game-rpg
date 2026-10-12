# GP.3 Spec - Basic Sword Combat

**Status:** draft for owner review  
**Linked lane:** Gameplay  
**Checklist gate:** `GP.3`

## Purpose

Define the first attack verb: a simple facing-based sword strike that gives the
pawn agency without making it overpowered.

## Sword Identity

```text
fast
close-range
one-cell
directional
brave
punishes enemy recovery
```

## Starting Combat Targets

| Property | Target |
|---|---|
| Range | one adjacent cell in facing direction |
| Startup | short but visible |
| Impact | clear hit frame |
| Recovery | enough to prevent spam |
| Movement lock | only during meaningful swing window |
| Hit feedback | flash/chip/small shake |

## First-Chain Uses

| Room | Sword Role |
|---|---|
| T2 | safe pickup and test swing |
| T3 | punish pawn after telegraph/commit |
| H1 | confirms player is armed while exploring |

## Completion Requirements

`GP.3` can be approved only after playable testing confirms:

- range is understandable,
- attack direction follows facing,
- the sword feels responsive,
- hit feedback is satisfying,
- and spamming the sword is not better than reading danger.

## Cannot Approve If

- sword range is unclear,
- hit timing feels disconnected from animation,
- attack can solve fights without positioning,
- or recovery feels unfairly long or meaninglessly short.

