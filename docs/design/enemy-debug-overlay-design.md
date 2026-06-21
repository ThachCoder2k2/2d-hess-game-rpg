# Enemy Debug Overlay

**Status:** Implemented
**Date:** 2026-06-21

## Goal

Make enemy decisions inspectable during play without changing combat behavior.

## Display

Press `F3` to toggle the complete debug layer.

Board:

- Cyan room boundary.
- White occupied-cell boundaries.
- Yellow blocked-cell boundaries.
- Blue movement-reservation boundaries.
- Green item-cell boundaries.
- Intent paths from enemies to movement or attack targets.

Enemy label:

- Piece role.
- Current state.
- Selected action and utility score.
- Equipped weapon, when present.

## Intent Colors

- Red: attack.
- Cyan: move.
- Green: pickup.
- Yellow: turn.
- Gray: wait.

## Constraints

- Debug drawing never changes AI decisions.
- Labels follow enemies during tweened movement.
- Defeated enemies and stale intent paths are removed.
- The layer is intended for development and starts enabled in the prototype.
