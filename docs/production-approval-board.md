# The Unbound Pawn - Production Approval Board

**Purpose:** track owner approval separately from implementation progress.  
**Rule:** a batch or task is not approved until the owner explicitly says it is
approved.

This board exists so planning can move in parallel without accidentally turning
drafts into production commitments.

Use this review form when giving feedback:

```text
docs/owner-review-template.md
```

---

## Approval States

| State | Meaning |
|---|---|
| `draft` | Written by Codex, not accepted yet |
| `needs_revision` | Owner reviewed and requested changes |
| `approved` | Owner accepted the plan; implementation planning may start |
| `implementation_planning` | Turning approved plan into specific build tasks |
| `in_progress` | Being built in Godot |
| `owner_review` | Built and waiting for editor/playtest review |
| `accepted` | Owner accepted the result |

---

## Batch Approval Matrix

All batches can be reviewed independently, but implementation should respect
the dependencies listed below.

| Batch | Review File | State | Depends On | Unlocks |
|---|---|---|---|---|
| Batch 1 - Foundation | `docs/review-batch-1-foundation.md` | approved | none | `T1_WhiteKingsFall` production spec, first chain direction |
| Batch 2 - First Playable Feel | `docs/review-batch-2-first-playable-feel.md` | draft | none for review; Batch 1 for build | movement sandbox, sword tuning, Pawn Recruit combat |
| Batch 3 - First Chain Production Rules | `docs/review-batch-3-first-chain-production-rules.md` | draft | none for review; Batch 1 for build | room template, TileMap workflow, QA checklist |
| Batch 4 - Vertical Slice Expansion | `docs/review-batch-4-vertical-slice-expansion.md` | draft | Batch 1 for story/world consistency | Toybox district plan, Knight boss plan, Rule Step plan |
| Batch 5 - Full Game Expansion | `docs/review-batch-5-full-game-expansion.md` | draft | Batch 1 for fantasy; Batch 4 for slice direction | later districts, full skill arc, full art/animation/narrative/release plans |

---

## Current Recommended Review Order

This is a review order, not a production order.

```text
Batch 1 -> Batch 2 -> Batch 3 -> Batch 4 -> Batch 5
```

Reason:

- Batch 1 locks the fantasy, map premise, first chain, and technical room model.
- Batch 2 locks the moment-to-moment feel.
- Batch 3 locks how rooms should be built and reviewed in Godot.
- Batch 4 locks the first demo expansion.
- Batch 5 locks the long-term game guardrails.

Parallel rule:

```text
While one batch is under owner review, another lane can still draft or revise
specs. No specific implementation starts until its own approval gate is passed.
```

---

## Owner Review Questions

Use these when reviewing any batch.

| Question | Pass Condition |
|---|---|
| Does this match the game fantasy? | It still feels like a pawn in a child's imagined chess war |
| Is the scope small enough? | It can be built, tested, and reviewed without becoming vague |
| Is the gameplay readable? | A player can understand danger before being hit |
| Is the editor workflow clear? | The result can become editable Godot scenes/resources |
| Is there a clear definition of done? | Codex knows exactly what must be true before acceptance |
| Is anything missing? | Missing art, sound, UI, animation, QA, or narrative work is named |

For detailed notes, use:

```text
docs/owner-review-template.md
```

---

## Approval Command Format

When the owner is ready, use simple wording like:

```text
approve Batch 1
revise Batch 2: sword range should be more flexible
approve Batch 3 except TOOL.4
```

Codex should then:

1. update this board,
2. update the related review package,
3. update `progress.md`,
4. create the next implementation-planning task only for approved items.

---

## First Implementation Candidate

If Batch 1 is approved, the first buildable production task should be:

```text
T1_WhiteKingsFall production spec
```

That task should define one editable Godot room:

- room purpose,
- TileMap layout,
- player start,
- visible story props,
- White King death staging,
- Black army exit direction,
- camera framing,
- sound/mood notes,
- review screenshots,
- acceptance checklist.

Only after that one-room spec is approved should Codex build the room.

---

## Current State

Batch 1 is approved.

The next task is owner review of:

```text
docs/production/act-1-opening-to-first-boss-flow-map.md
docs/production/t1-white-kings-fall-production-spec.md
```

No new implementation should start from these specs until the owner approves
the relevant room or act plan.
