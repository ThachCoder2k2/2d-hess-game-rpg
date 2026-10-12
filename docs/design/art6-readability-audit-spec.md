# ART.6 Spec - Readability Audit

**Status:** draft for owner review  
**Linked lane:** Art Direction  
**Checklist gate:** `ART.6`

## Purpose

Define how art is judged for gameplay readability.

## Audit Checks

- Player readable on light and dark tiles.
- Enemies readable on light and dark tiles.
- Danger telegraphs visible over floor and props.
- Pickups distinguishable from hazards.
- Solid blockers visually clear.
- Important routes readable without UI arrows.
- Screenshot still works in grayscale.

## Test Views

Each room/art pass should be checked:

```text
normal zoom
debug grid on
busy combat moment
low-health HUD moment
grayscale screenshot
```

## Completion Requirements

`ART.6` can be approved only if:

- readability audit steps are accepted,
- first-chain art must pass them before owner acceptance,
- and beauty cannot override combat clarity.

## Cannot Approve If

- readability is judged only by still concept art,
- telegraphs fail on common floors,
- or actors blend into the room.

