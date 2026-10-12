# AN.6 Spec - AnimationTree QA

**Status:** draft for owner review  
**Linked lane:** Animation  
**Checklist gate:** `AN.6`

## Purpose

Ensure animation remains editor-owned, tunable, and synchronized with gameplay.

## QA Requirements

- Animation clips exist for required states.
- AnimationTree transitions are visible in editor.
- Attack impact timing matches gameplay event.
- Hurt/defeat states cannot be skipped accidentally.
- RESET restores clean editor pose.
- No animation changes logical grid anchor.

## Completion Requirements

`AN.6` can be approved only if:

- editor ownership is preserved,
- animations are testable in Godot,
- and basic state transitions can be verified.

## Cannot Approve If

- animation logic is hidden only in script,
- transitions are uninspectable,
- or animation and gameplay timing drift silently.

