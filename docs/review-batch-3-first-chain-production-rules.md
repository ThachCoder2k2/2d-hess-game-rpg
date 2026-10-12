# Review Batch 3 - First Chain Production Rules

**Status:** draft for owner review  
**Purpose:** approve or revise the production rules for building the first chain
as real editable Godot content.  
**Batch source:** `docs/production-review-dashboard.md`

This batch defines how rooms, tiles, assets, and review workflows should work
before production starts.

Approving this batch does not build the rooms. It approves the production
standards for building them.

---

## Included Gates

| Gate | Spec |
|---|---|
| `LD.3` | `docs/design/ld3-room-template-spec.md` |
| `ART.2` | `docs/design/art2-tile-palette-list-spec.md` |
| `TOOL.2` | `docs/design/tool2-room-authoring-guide-update-spec.md` |
| `TOOL.3` | `docs/design/tool3-asset-import-rules-spec.md` |
| `TOOL.4` | `docs/design/tool4-tile-editing-workflow-spec.md` |
| `QA.1` | `docs/design/qa1-smoke-test-checklist-spec.md` |
| `QA.2` | `docs/design/qa2-room-qa-checklist-spec.md` |

---

## Production Rule Summary

## 1. Room Template

Approved target structure:

```text
RoomName
  RoomArt
    TileMap
    GridLines
    SetDressing
  Entries
  Exits
  Enemies
  Pickups
  Props
  RoomLogic
```

Rule:

```text
Rooms must be editable and understandable in Godot.
Gameplay objects should not be hidden only in scripts.
```

## 2. Tile Palette Scope

First-chain tile needs:

```text
chess rug light/dark
broken chess rug
wood floor border
torn paper
fallen piece cover
weapon pickup highlight
simple solid boundary
danger overlay compatibility
```

Rule:

```text
Do not produce full-game tile polish before first-chain readability works.
```

## 3. Room Authoring Guide

The guide must explain:

```text
what nodes are art-only
what nodes affect gameplay
how to move enemies/pickups
how to paint solid tiles
how exits and entries work
how to test a room
```

Rule:

```text
If the owner cannot understand how to edit a room, the workflow is not accepted.
```

## 4. Asset Import Rules

Approved direction:

```text
pixel textures use nearest filtering
reference/concept art is separated from production sprites
generated assets are not final until accepted
audio routes to correct buses
```

## 5. Tile Editing Workflow

Approved direction:

```text
TileMap painting should control visible floor/walls.
Solid tiles must be obvious.
Painting should not silently break exits/spawns.
```

## 6. Smoke Testing

Minimum smoke test:

```text
project opens
main scene runs
player moves
player attacks
enemies act without crash
telegraphs appear and clear
HUD updates
room restarts
imports are clean
```

## 7. Room QA

Every room must pass:

```text
opens in Godot
spawn is correct
exits work
collision matches visuals
enemy placement is fair
objective/status text is correct
art does not hide gameplay
room purpose is clear
```

---

## Approval Questions

| Question | Recommended Answer |
|---|---|
| Should rooms follow a standard scene template? | yes |
| Should first-chain tiles stay tightly scoped? | yes |
| Should generated/concept art stay separate from accepted production art? | yes |
| Should TileMap editing be owner-readable? | yes |
| Should every room require smoke and room QA checks? | yes |
| Should production stop if a room cannot be edited confidently in Godot? | yes |

---

## If Approved

If this batch is approved, these implementation-planning tasks may begin:

```text
room template creation/update plan
first-chain tile palette production plan
room authoring guide update task
TileMap editing workflow task
room QA checklist task
smoke test checklist task
```

Recommended next implementation-planning task after Batch 1-3 approval:

```text
T1_WhiteKingsFall production spec.
```

## If Not Approved

Revise the specific workflow issue before building rooms.

Possible revision areas:

- scene tree structure,
- TileMap workflow,
- asset import rules,
- QA requirements,
- owner editor workflow.

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

