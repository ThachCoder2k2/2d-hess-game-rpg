# TOOL.2 Spec - Room Authoring Guide Update

**Status:** draft for owner review  
**Linked lane:** Tools And Editor Workflow  
**Checklist gate:** `TOOL.2`

## Purpose

The owner should be able to open a room scene and understand what can be safely
edited without asking which script secretly owns the content.

## Required Guide Topics

- Standard room scene tree.
- Which nodes are art-only.
- Which nodes affect gameplay.
- How to move player/enemies/pickups.
- How to paint solid tiles.
- How exits and entries work.
- How to run and review a room.
- What not to edit directly.

## Required Room Scene Explanation

The guide should explain this target structure:

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
```

If current implementation differs, the guide must say so clearly.

## Completion Requirements

`TOOL.2` can be approved only if:

- the owner can open a room and identify editable content,
- TileMap editing rules are clear,
- enemy/pickup placement rules are clear,
- exits/entries are explained,
- and review steps are documented.

## Cannot Approve If

- room editing still requires guessing,
- script-owned and editor-owned content are not distinguished,
- the owner cannot tell what affects gameplay,
- or new room creation remains undocumented.

