# QA.1 Spec - Smoke Test Checklist

**Status:** draft for owner review  
**Linked lane:** QA And Playtesting  
**Checklist gate:** `QA.1`

## Purpose

Smoke tests make sure each build opens, runs, and preserves the accepted core
behaviors before deeper playtesting.

## Minimum Smoke Test

Every production change should answer:

```text
Does the project open?
Does the main scene run?
Can the player move?
Can the player attack?
Do enemies act without crashing?
Do telegraphs appear and clear?
Does the HUD update?
Can the room restart?
Are there import errors?
```

## First-Chain Smoke Test Additions

When the first room chain exists, add:

```text
Can T1 load?
Can T1 exit to T2?
Can T2 exit to T3?
Can T3 exit to H1?
Does the player spawn at the correct entry?
Does backtracking work where expected?
Do locked H1 exits communicate they are locked?
```

## Bug Report Format

Every bug should capture:

| Field | Meaning |
|---|---|
| Area | Room/system where it happened |
| Steps | How to reproduce |
| Expected | What should happen |
| Actual | What happened |
| Severity | blocker, major, minor, polish |
| Evidence | screenshot, log, or note |

## Completion Requirements

`QA.1` can be approved only if:

- there is a short repeatable smoke checklist,
- it covers launch, movement, attack, AI, HUD, restart, and imports,
- first-chain travel checks are defined for later,
- and bug reports have a consistent format.

## Cannot Approve If

- testing means only "run it and look around",
- crashes are not reproducible,
- accepted features can regress silently,
- or owner review notes are not tracked.

