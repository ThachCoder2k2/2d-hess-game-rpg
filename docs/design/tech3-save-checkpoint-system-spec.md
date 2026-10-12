# TECH.3 Spec - Save And Checkpoint System

**Status:** draft for owner review  
**Linked lane:** Technical Architecture  
**Checklist gate:** `TECH.3`

## Purpose

Define persistence and retry behavior so players can experiment without losing
meaningful progress.

## Required Behavior

- Checkpoint at hub/room entry/boss entry.
- Room death reloads latest checkpoint.
- Major unlocks persist.
- Boss retries are fast.
- Save format can grow later.

## Completion Requirements

`TECH.3` can be approved only if reset, death, travel, and unlock persistence
rules are predictable and documented.

## Cannot Approve If

- death loses unclear progress,
- saves depend on scene-specific hacks,
- or checkpoints are invisible to future room authors.

