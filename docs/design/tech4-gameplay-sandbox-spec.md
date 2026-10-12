# TECH.4 Spec - Gameplay Sandbox

**Status:** draft for owner review  
**Linked lane:** Technical Architecture  
**Checklist gate:** `TECH.4`

## Purpose

Create a test room where movement, sword, enemy telegraphs, HUD, audio, and VFX
can be tuned without waiting for final story rooms.

## Sandbox Scope

The sandbox is not a production room. It is a tuning lab.

It should include:

- open grid area,
- one pawn enemy,
- one pickup/weapon test position,
- safe restart,
- visible debug toggle,
- optional telegraph test,
- enough space to test movement feel.

## Sandbox Must Not

- replace the first room chain,
- become the final tutorial,
- carry story-critical content,
- or hide implementation decisions from editor review.

## Completion Requirements

`TECH.4` can be approved only if:

- the sandbox purpose is accepted,
- it is editor-owned enough to modify quickly,
- it can test GP.2 and GP.3,
- it can test EN.1 and FX.1,
- and it does not distract from production rooms.

## Cannot Approve If

- the sandbox becomes a substitute for real room design,
- it requires custom code for every experiment,
- it cannot isolate movement/combat feel,
- or the owner cannot use it to review mechanics.

