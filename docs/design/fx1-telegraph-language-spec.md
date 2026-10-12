# FX.1 Spec - Telegraph Language

**Status:** draft for owner review  
**Linked lane:** VFX And Combat Feedback  
**Checklist gate:** `FX.1`

## Purpose

Telegraphs must make danger readable before damage. They are gameplay
communication first, visual flourish second.

## Threat Color Rules

| Meaning | Visual Direction |
|---|---|
| Anticipation | dark orange / warm warning |
| Immediate danger | coral red |
| Child help | crayon blue |
| Safe / heal | mint green |
| Interactable | golden yellow |

Red is not decoration. Red means danger.

## First Telegraph Shapes

| Threat | Shape |
|---|---|
| Pawn diagonal | corner-to-corner slash marks in diagonal cells |
| Sword attack | pale yellow front arc |
| Pencil skill | straight graphite/blue line |
| Knight later | outlined L destination and path cue |
| Rook later | row/column arrow |
| Bishop later | diagonal lane band |

## First-Chain Requirement

The first required telegraph is the Black Pawn diagonal.

It must be readable:

- on light chess squares,
- on dark chess squares,
- near fallen pieces,
- while the player is moving,
- and before damage resolves.

## Completion Requirements

`FX.1` can be approved only if:

- danger is visible before impact,
- threat colors have consistent meanings,
- first-chain pawn diagonal telegraph is the initial test case,
- and effects do not hide the grid or actors.

## Cannot Approve If

- telegraphs appear only at impact,
- danger and decoration use the same color language,
- effects cover the next decision state,
- or the player cannot tell which cells are unsafe.

