# Review Batch 4 - Vertical Slice Expansion

**Status:** draft for owner review  
**Purpose:** approve or revise the first demo-sized expansion beyond the opening
chain.  
**Batch source:** `docs/production-review-dashboard.md`

This batch defines the first vertical slice direction: the Chess Rug Hub, the
Toybox Knight district, the first boss, and the short-demo test path.

Approving this batch does not build the slice. It approves what the first slice
should become after the opening chain.

---

## Included Gates

| Gate | Spec |
|---|---|
| `LD.4` | `docs/design/ld4-room-formula-spec.md` |
| `LD.5` | `docs/design/ld5-chess-rug-hub-spec.md` |
| `LD.6` | `docs/design/ld6-district-layout-plans-spec.md` |
| `LD.7` | `docs/design/ld7-shortcuts-locks-spec.md` |
| `EN.2` | `docs/design/en2-knight-behavior-spec.md` |
| `GP.7` | `docs/design/gp7-progression-pacing-spec.md` |
| `QA.5` | `docs/design/qa5-vertical-slice-test-plan-spec.md` |

---

## Vertical Slice Direction Summary

## 1. Room Formula

Approved structure:

```text
Rest / reveal -> Teach -> Test -> Twist -> Boss or Reward -> Shortcut / return
```

Room types:

```text
story
teach
test
twist
reward
boss
rest
```

Rule:

```text
No filler rooms.
Every room needs gameplay, story, route, or pacing purpose.
```

## 2. Chess Rug Hub

Approved direction:

```text
central orientation room
safe enough to breathe
visible routes to future districts
Toybox route most available first
Bookshelf / Block Tower / Dollhouse / Under-Bed visible but blocked
Desk/child foreshadow visible near edge
```

## 3. District Structure

Approved compact district loop:

```text
Entrance -> Teach -> Test -> Twist -> Boss -> Reward -> Shortcut back
```

Full district plan:

| District | Rooms | Boss | Reward |
|---|---|---|---|
| Toybox Knight | 3 normal + boss | Knight Captain | Rule Step |
| Bookshelf Bishop | 3 normal + boss | Bishop Oracle | Chalk Path |
| Block Tower Rook | 3 normal + boss | Rook Warden | Eraser Guard |
| Dollhouse Queen | 3 normal + boss | Queen of Tricks | Black Castle access |
| Under-Bed King | 3 final rooms + boss | Black King | Ending |

## 4. Shortcuts And Locks

Approved lock language:

```text
toy blocks
paper gaps
ruler gates
story seals
one-way shortcuts
```

Rules:

```text
locked routes should be visible before opening
blocked paths should visually explain why they are blocked
shortcuts should reduce repeat travel
locks should connect to skill, story, or district completion
```

## 5. Knight District

Approved Knight combat question:

```text
Which L-shaped cell is about to become unsafe, and can I punish after the leap?
```

Knight district teaches:

```text
L-shaped danger
delayed target preview
recovery punish
Rule Step as escape/reposition tool
```

Knight Captain boss:

```text
Phase 1: one marked L target
Phase 2: chained or delayed L pressure
Phase 3: toy-track or arena pressure
Reward: Rule Step
```

## 6. Vertical Slice Test Path

Approved slice path:

```text
launch game
opening room
sword pickup
first combat
hub orientation
Toybox district
Knight boss
Rule Step reward
return to hub
```

Target slice length:

```text
12-18 minutes
```

---

## Approval Questions

| Question | Recommended Answer |
|---|---|
| Should the first vertical slice end after Knight Captain? | yes |
| Should Toybox be the first district after the hub? | yes |
| Should district structure use teach-test-twist-boss-reward? | yes |
| Should Knight boss reward Rule Step? | yes |
| Should routes/locks be visible before opening? | yes |
| Should vertical slice test include return to hub? | yes |

---

## If Approved

If this batch is approved, these implementation-planning tasks may begin:

```text
Toybox Knight district production spec
Knight Captain boss production spec
Rule Step gameplay spec
vertical slice content lock
vertical slice QA route
```

Recommended timing:

```text
Do not build Toybox until first-chain production is accepted,
but planning can continue in parallel.
```

## If Not Approved

Revise the specific expansion decision.

Possible revision areas:

- first district choice,
- vertical slice endpoint,
- Knight reward,
- district room count,
- shortcut/lock style,
- demo length.

---

## Approval State

Current state:

```text
draft
```

Owner decision:

```text
pending
```

