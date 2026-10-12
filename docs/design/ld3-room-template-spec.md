# LD.3 Spec - Room Template

**Status:** draft for owner review  
**Linked lane:** Level And World Design  
**Checklist gate:** `LD.3`

## Purpose

Define a standard room structure so every room can be opened, understood, edited,
tested, and reviewed in Godot.

## Target Scene Tree

```text
RoomName
  RoomArt
    TileMap
    GridLines
    SetDressing
  Entries
    Entry_*
  Exits
    Exit_*
  Enemies
  Pickups
  Props
  RoomLogic
```

If runtime constraints require flatter child nodes, the visual organization must
still be documented and understandable.

## Required Room Metadata

| Field | Purpose |
|---|---|
| `zone_id` | Unique room/world id |
| `board_size` | Grid dimensions |
| `room_message` | Initial prompt/mood |
| `objective` | Optional room clear rule |
| entry marker names | Spawn points |
| exit marker data | Destination links |

## Authoring Rules

- Paint floor and solid blockers through TileMap where possible.
- Place enemies as real scene instances, not invisible spawn data.
- Place pickups as visible editor objects.
- Keep props separate from gameplay blockers unless intentionally solid.
- Name exits by destination.
- Keep combat grid readable before decoration.

## Completion Requirements

`LD.3` can be approved only if:

- the owner can inspect the scene tree and understand each group,
- gameplay-affecting nodes are distinguishable from decoration,
- room metadata is standardized,
- and the template supports first-chain rooms without custom per-room code.

## Cannot Approve If

- rooms are mostly generated in script,
- exits/enemies/pickups are hidden from editor review,
- art and collision can disagree silently,
- or new rooms require reinventing structure each time.

