# T1_WhiteKingsFall - Production Spec

**Status:** approved for initial build on 2026-09-30  
**Unlocked by:** approved Batch 1 - Foundation  
**Room type:** opening story / movement tutorial  
**Implementation allowed:** yes, initial editable scene build approved on 2026-09-30  

This spec defines the first production room as an editable Godot scene. It is
not a build task yet.

---

## Room Purpose

`T1_WhiteKingsFall` is the first playable room.

It must teach:

- the pawn is alive after the battle,
- the White side has lost,
- the player can move one grid cell at a time,
- holding a direction keeps stepping,
- the Black army has retreated somewhere dangerous,
- and the only immediate choice is to walk forward.

It must not teach:

- sword combat,
- enemy telegraphs,
- skills,
- child intervention,
- inventory,
- boss mechanics.

Target feeling:

```text
quiet, small, defeated, curious, readable
```

The room should feel like the aftermath of a child's imagined war on a chess
rug, not a normal fantasy castle.

---

## Approved Foundation Constraints

This room must obey Batch 1:

| Constraint | T1 Interpretation |
|---|---|
| One-cell real-time movement is the identity | Player only learns moving and holding movement |
| Chess rug is the opening location | Floor uses chess-rug / kingdom-board language |
| Bedroom reality matters | Props must imply rug, toys, paper, or room materials |
| Combat readability beats decoration | Fallen pieces cannot hide the grid or exit |
| Pawn stays a pawn | No promotion fantasy, no heroic chosen-one staging |
| Rooms are editable scenes | Room content should be visible in Godot, not hidden construction |

---

## Player Experience Beat

```text
1. Fade in on a silent board.
2. The White King is already dead.
3. The pawn lies near the lower-left / lower-middle area.
4. Fallen white pieces show that running or regrouping failed.
5. Black retreat marks point toward the next room.
6. The player moves for the first time.
7. The exit is obvious and calm.
8. Leaving the room begins the search for agency.
```

No enemy should threaten the player in this room.

---

## Board Layout

Recommended board size:

```text
16 x 9 cells
```

This matches the current first encounter scale and the 640x360 target.

Cell map:

```text
Legend:
  P = player start
  K = fallen White King focal prop
  w = fallen white piece / debris prop
  b = black retreat mark / scorched clue
  . = walkable chess-rug tile
  # = soft visual boundary or solid edge
  E = exit to T2_FallenSwordTile

    00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
00  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
01  #  .  .  b  b  .  .  .  .  .  b  b  .  .  E  #
02  #  .  w  .  .  .  .  K  K  .  .  .  w  .  .  #
03  #  .  .  .  .  w  .  K  K  .  w  .  .  .  .  #
04  #  .  .  .  .  .  .  .  .  .  .  .  .  b  .  #
05  #  .  P  .  .  .  w  .  .  .  .  .  .  b  .  #
06  #  .  .  .  .  .  .  .  .  .  w  .  .  .  .  #
07  #  .  .  .  .  .  .  .  .  .  .  .  .  .  .  #
08  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
```

Walkable path:

```text
P -> open space -> White King focal area -> black retreat marks -> E
```

The player can wander, but the composition should naturally pull rightward
toward the exit.

---

## Camera And Framing

Opening frame should show:

- pawn start,
- fallen White King,
- enough empty space to understand movement,
- exit direction or retreat marks.

Preferred framing:

```text
camera centered slightly between pawn and White King
exit visible near right edge
no large prop covering player
```

If camera constraints make that hard, prioritize player visibility and White
King visibility over showing the whole exit immediately.

---

## Scene Structure Target

Preferred scene path:

```text
scenes/rooms/t1_white_kings_fall.tscn
```

Preferred editable tree:

```text
T1_WhiteKingsFall
  RoomArt
    TileMap
    GridLines
    SetDressing
      FallenWhiteKing
      FallenPieces
      BlackRetreatMarks
      RugDamage
  Entries
    Entry_Start
    Entry_From_T2
  Exits
    Exit_To_T2
  Props
    FallenWhiteKing
    FallenWhitePawns
    BrokenCrown
  Objective
  AudioHints
```

If the current runtime requires a flatter structure, the final scene must still
be readable in the editor and must not hide the core room content in code.

---

## Required Editable Objects

| Object | Purpose | Editable Requirement |
|---|---|---|
| Player start | First spawn / wake location | Visible in `scenes/main.tscn` or as an entry marker |
| Fallen White King | Emotional focal point | Selectable scene node or prop instance |
| Fallen white pieces | Shows lost battle | Grouped under `FallenPieces` |
| Black retreat marks | Points to next danger | Visible props or painted tiles |
| Exit to T2 | First room transition | Visible marker with target zone/entry data |
| Room objective text | Opening prompt | Resource or Inspector field |
| TileMap | Floor and any solid edge cells | Paintable TileMapLayer/TileSet |

---

## Tile And Prop Direction

Use current available assets where possible:

- `resources/tiles/kingdom_tileset.tres`
- `objects/world/kingdom_tilemap.tscn`
- `assets/tiles/kingdom_tiles.svg`
- existing generated chess-piece sprites when available

Tile direction:

```text
marble/checker fabric base
subtle red/gold kingdom striping only as accent
damaged or scuffed board squares near the king
clear solid boundary if needed
```

Prop direction:

```text
fallen White King larger than normal pawns
small fallen white pieces as readable debris
black retreat marks as dark scuffs, cracks, or dragged footprints
broken crown or banner near the king if readable
```

Avoid:

- filling the room with many corpses,
- making the king so large that it hides grid state,
- heavy castle walls that make it feel like a normal castle,
- script-only prop drawing.

---

## Gameplay Rules

Required:

- player can step one cell,
- holding direction continues movement,
- player can walk around the White King area,
- no enemy can damage the player,
- exit to T2 works after walking to the exit cell.

Optional:

- short wake animation can play if current player scene supports it,
- one silent prompt can appear after the player moves,
- exit can remain open from the start.

Forbidden:

- forced dialogue before movement,
- combat,
- sword pickup,
- hidden timers,
- fail state.

---

## Narrative And Text

Opening should be mostly visual.

Allowed HUD/objective text:

```text
The king has fallen.
Move.
```

Alternative if too dramatic:

```text
Move.
```

Avoid long exposition.

No child voice yet, unless it is a tiny nonverbal hint such as a soft light or
offscreen room sound. The child should be foreshadowed later, not introduced as
a narrator in the first room.

---

## Audio Direction

Use sparse sound.

Suggested audio:

- low room tone or quiet music stem,
- soft wake rustle if wake animation plays,
- subtle tile step sound if available,
- no combat music,
- no victory sting.

Existing relevant assets:

- `assets/music/unbound_march.wav`
- `assets/sfx/wake_stir.wav`

If the music feels too heroic, do not use it in T1. Silence is acceptable.

---

## Transition To T2

Exit target:

```text
target_zone: t2_fallen_sword_tile
target_entry: west_entry
```

If room-transition implementation is not ready yet, this spec still requires
the exit marker to exist as an editor-visible node so the room can be connected
later.

Backtracking:

```text
T2 should eventually allow returning to T1 through west_exit -> T1 / from_t2_entry.
```

---

## Implementation Confidence

Codex can confidently plan and later build:

- an editable Godot room scene,
- TileMap-based floor using existing tiles,
- visible prop nodes or prop scene instances,
- entry/exit marker placement,
- objective text,
- simple no-combat runtime validation.

Codex should not claim final art quality unless:

- real sprite/prop assets are present or generated/approved,
- the owner reviews the room in editor,
- and the room no longer reads as placeholder.

---

## Acceptance Checklist

This room can be accepted only if:

- the scene opens directly in Godot,
- the room content is visible and selectable in the scene tree,
- the player start is obvious,
- the White King is the visual focal point,
- fallen white pieces and black retreat marks support the story without clutter,
- grid movement is easy to read,
- the exit direction is understandable,
- there is no combat or fail state,
- the room uses TileMap/scene-owned content rather than hidden script drawing,
- and the owner confirms the room feels like the opening aftermath of the game.

---

## Owner Review Questions

Please review before implementation:

| Question | Recommended Answer |
|---|---|
| Is this the right first playable room? | yes |
| Should T1 be quiet and combat-free? | yes |
| Should the fallen White King be the focal point? | yes |
| Should the player start near lower-left / lower-middle? | yes |
| Should the room use the existing 16x9 board scale? | yes |
| Should the only exit lead to T2_FallenSwordTile? | yes |
| Is the text short enough? | yes |
| Is Codex allowed to build this room after approval? | owner decision needed |

---

## Approval State

Current state:

```text
approved_for_initial_build
```

Owner decision:

```text
approved to start building on 2026-09-30
```
