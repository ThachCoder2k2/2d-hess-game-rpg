# The Unbound Pawn - Production Review Dashboard

This dashboard turns the full planning set into a review process. The goal is to
avoid approving seventy-plus specs blindly.

Approval state is tracked in:

```text
docs/production-approval-board.md
```

Nothing in this file authorizes implementation by itself. A spec is approved
only when the owner explicitly accepts it or asks Codex to mark it approved.

## Review Rule

Review in batches. Each batch contains specs that depend on each other.

```text
review batch -> revise if needed -> approve batch -> create implementation tasks
```

Implementation still happens task by task.

## Batch 1 - Foundation Approval

These define the game direction and first playable route.

Review package:

```text
docs/review-batch-1-foundation.md
```

| Gate | Spec | Why It Matters | Status |
|---|---|---|---|
| `GP.1` | `docs/design/gp1-ld2-core-loop-first-chain-spec.md` | Core gameplay loop | approved |
| `LD.2` | `docs/design/gp1-ld2-core-loop-first-chain-spec.md` | First playable room chain | approved |
| `LD.1` | `docs/design/ld1-bedroom-world-layout-spec.md` | Bedroom world structure | approved |
| `ART.1` | `docs/design/art1-visual-target-spec.md` | Visual target | approved |
| `NAR.1` | `docs/design/nar1-story-outline-spec.md` | Story spine | approved |
| `TECH.2` | `docs/design/tech2-room-transition-system-spec.md` | Room travel model | approved |

### Approval Unlocks

If Batch 1 is approved, these implementation-planning tasks may begin:

```text
T1_WhiteKingsFall production spec
gameplay sandbox implementation plan
first-chain room transition implementation plan
first-chain art target breakdown
opening script draft
```

## Batch 2 - First Playable Feel

These define the feel of the first playable slice.

Review package:

```text
docs/review-batch-2-first-playable-feel.md
```

| Gate | Spec | Why It Matters | Status |
|---|---|---|---|
| `GP.2` | `docs/design/gp2-player-movement-feel-spec.md` | Pawn movement feel | draft |
| `GP.3` | `docs/design/gp3-basic-sword-combat-spec.md` | Sword combat | draft |
| `EN.1` | `docs/design/en1-pawn-behavior-spec.md` | First enemy | draft |
| `FX.1` | `docs/design/fx1-telegraph-language-spec.md` | Danger readability | draft |
| `FX.2` | `docs/design/fx2-hit-feedback-spec.md` | Hit feel | draft |
| `AU.2` | `docs/design/au2-movement-attack-sfx-spec.md` | Player action sound | draft |
| `UI.1` | `docs/design/ui1-hud-scope-spec.md` | Minimal HUD | draft |

### Approval Unlocks

If Batch 2 is approved, these implementation-planning tasks may begin:

```text
movement tuning sandbox
sword combat tuning sandbox
Pawn Recruit first-combat prototype
first telegraph visual test
first HUD review pass
```

## Batch 3 - First Chain Production Rules

These make the first rooms buildable and reviewable in Godot.

Review package:

```text
docs/review-batch-3-first-chain-production-rules.md
```

| Gate | Spec | Why It Matters | Status |
|---|---|---|---|
| `LD.3` | `docs/design/ld3-room-template-spec.md` | Standard room structure | draft |
| `ART.2` | `docs/design/art2-tile-palette-list-spec.md` | Tile needs | draft |
| `TOOL.2` | `docs/design/tool2-room-authoring-guide-update-spec.md` | Room editing guide | draft |
| `TOOL.3` | `docs/design/tool3-asset-import-rules-spec.md` | Import consistency | draft |
| `TOOL.4` | `docs/design/tool4-tile-editing-workflow-spec.md` | TileMap workflow | draft |
| `QA.1` | `docs/design/qa1-smoke-test-checklist-spec.md` | Basic stability | draft |
| `QA.2` | `docs/design/qa2-room-qa-checklist-spec.md` | Room acceptance | draft |

### Approval Unlocks

If Batch 3 is approved, these implementation-planning tasks may begin:

```text
room template creation/update
first-chain TileMap workflow
room authoring guide revision
room QA checklist file
```

## Batch 4 - Vertical Slice Expansion

These define the first district and short demo target.

Review package:

```text
docs/review-batch-4-vertical-slice-expansion.md
```

| Gate | Spec | Why It Matters | Status |
|---|---|---|---|
| `LD.4` | `docs/design/ld4-room-formula-spec.md` | District room structure | draft |
| `LD.5` | `docs/design/ld5-chess-rug-hub-spec.md` | Hub design | draft |
| `LD.6` | `docs/design/ld6-district-layout-plans-spec.md` | District loops | draft |
| `LD.7` | `docs/design/ld7-shortcuts-locks-spec.md` | Progression routes | draft |
| `EN.2` | `docs/design/en2-knight-behavior-spec.md` | Knight enemy/boss | draft |
| `GP.7` | `docs/design/gp7-progression-pacing-spec.md` | Full unlock rhythm | draft |
| `QA.5` | `docs/design/qa5-vertical-slice-test-plan-spec.md` | Slice QA path | draft |

### Approval Unlocks

If Batch 4 is approved, these implementation-planning tasks may begin:

```text
Toybox Knight district plan
Knight Captain boss production spec
vertical slice content lock
```

## Batch 5 - Full Game Expansion

These support the full 90-120 minute game.

Review package:

```text
docs/review-batch-5-full-game-expansion.md
```

| Group | Gates |
|---|---|
| Boss/enemy expansion | `EN.3`, `EN.4`, `EN.5`, `EN.6`, `EN.7` |
| Advanced skills | `GP.4`, `GP.5`, `GP.6` |
| Art production | `ART.3`, `ART.4`, `ART.5`, `ART.6`, `ART.7` |
| Animation | `AN.1` through `AN.6` |
| VFX/audio/UI | `FX.3` through `FX.6`, `AU.1` through `AU.6`, `UI.2` through `UI.6` |
| Narrative | `NAR.2` through `NAR.6` |
| Technical/QA/release | `TECH.3`, `TECH.5`, `TECH.6`, `TOOL.5`, `QA.3`, `QA.4`, `REL.1` through `REL.5` |

### Approval Unlocks

If Batch 5 is approved, these implementation-planning tasks may begin:

```text
Bishop district production spec
Rook district production spec
Queen district production spec
King finale production spec
full skill implementation plan
child intervention production plan
full art asset list
animation task sheets
rulebook UI production spec
save/checkpoint implementation plan
vertical slice packaging checklist
```

## Recommended Next Review

Batch 1 is approved. The next review is:

```text
docs/production/t1-white-kings-fall-production-spec.md
```

The most important approval question:

```text
Do we accept the T1_WhiteKingsFall room plan as specific enough to implement?
```

If yes, the next production task should be:

```text
Create the implementation plan for the editable Godot room.
```
