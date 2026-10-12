# ART.1 Spec - Visual Target Lock

**Status:** approved by owner on 2026-09-30  
**Linked lane:** Art Direction  
**Checklist gate:** `ART.1`  
**Implementation allowed after approval:** no. This approves the visual target;
individual assets, tiles, sprites, and room art passes still need their own specs.

## Visual Target Statement

The game should look like:

> A polished top-down pixel-art action game where a child's bedroom becomes a
> chess battlefield. The room is charming and physical, but combat readability
> always wins over decoration.

The target is inspired by the readability and energy of *Enter the Gungeon*,
but the identity is not guns, dungeon rooms, or generic fantasy. The identity is:

```text
chess pieces + bedroom toys + paper + crayons + child imagination
```

---

## Visual Pillars

| Pillar | Requirement |
|---|---|
| Readable Combat First | Player, enemies, danger cells, and interactables must be visible at gameplay zoom |
| Bedroom Reality | Every district must be recognizable as part of a child's room |
| Imagined Kingdom Layer | Toys and room objects should imply forts, roads, castles, bridges, and courts |
| Physical Materials | Wood, paper, cloth, cardboard, plastic, books, crayon, graphite, and toy blocks |
| Chess Identity | The board, pieces, rules, and silhouettes must remain present |
| Warm But Dangerous | Cozy child-room lighting with dramatic black-king shadows |

---

## Global Art Rules

```text
Tile size: 32x32
Internal canvas: 640x360
Perspective: top-down floor, short front faces for tall objects
Sprites: feet/base anchored to grid cell center
Filtering: nearest-neighbor pixel art
```

Do not make decoration that hides grid state.

---

## Color Language

| Meaning | Color Direction |
|---|---|
| Player / White side | warm ivory, pale blue shadow |
| Black pieces | charcoal, cool blue-black, red cracks |
| Immediate danger | coral red |
| Anticipation | dark orange |
| Child help | crayon blue |
| Interactable/reward | golden yellow |
| Safe/rest/heal | mint green |
| Final castle corruption | deep purple, red, near-black |

Pure white and pure black should be rare impact colors, not normal material colors.

---

## District Art Targets

| Area | Real Object | Imagined Role | Main Materials | Shape Language |
|---|---|---|---|---|
| Opening / Chess Rug | chess rug on bedroom floor | fallen battlefield | fabric, board squares, wood floor | broken squares, fallen pieces |
| Toybox Knight | toybox and toys | cavalry yard | plastic toys, tracks, toy chest | ramps, L-paths, wheels |
| Bookshelf Bishop | books and papers | chapel/library fort | pages, bookmarks, book spines | diagonal folds, tall aisles |
| Block Tower Rook | blocks and rulers | ramparts / fortress | wood blocks, ruler bridges | straight rows, columns, gates |
| Dollhouse Queen | dollhouse | royal court | wallpaper, toy furniture, lamps | ornate but readable symmetry |
| Under-Bed King | bed underside / chess box | shadow castle | blanket, felt, box clasps, dust | heavy silhouettes, red rule cracks |
| Desk / Child | drawing table | fourth-wall source | crayons, paper, lamp light | blue marks, hand-scale objects |

---

## First-Chain Art Target

The first playable chain should establish the entire visual thesis at small scale.

```text
T1 = aftermath on chess rug
T2 = fallen sword among torn paper and broken board squares
T3 = first readable pawn combat on the rug
H1 = chess rug hub with visible routes toward bedroom districts
```

### T1 Visual Requirements

- Dead White King must be the focal point.
- Fallen white pieces should read as tragedy, not clutter.
- Black retreat marks should point toward future danger.
- The player pawn must be easy to find.
- Exit must be clear without UI arrows if possible.

### T2 Visual Requirements

- Sword pickup must glow or contrast enough to invite interaction.
- Safe turning area must be visually open.
- Broken board/paper should suggest the rules are damaged.

### T3 Visual Requirements

- Pawn enemy silhouette must be readable against board tiles.
- Danger telegraph must be visible on both light and dark squares.
- Low cover must look physical but not hide the pawn.

### H1 Visual Requirements

- Must feel like "this is the center of the bedroom war."
- Locked paths should be visible but understandable as not ready yet.
- Child/desk foreshadow must be present but not overwhelming.

---

## Visual Drawing

```text
                    BOOKS / PAPER CHAPEL
                         diagonal folds

        TOYBOX FORT       CHESS RUG HUB       BLOCK TOWER
        tracks, toys      fallen kingdom       rulers, rows

             DESK / CHILD MARKS        DOLLHOUSE COURT
             blue crayon help          royal toy symmetry

                         UNDER-BED CASTLE
                         shadow, red rule cracks
```

---

## Acceptance Requirements

`ART.1` can be marked `approved` only if the owner agrees that:

- the visual target is top-down pixel-art bedroom chess war,
- combat readability beats decoration,
- the first chain should use the chess rug as the visual foundation,
- districts should be recognizable as bedroom objects,
- child help should be visually marked with crayon-blue physical actions,
- and future art assets must pass the readability rules in the pixel art bible.

## Cannot Approve If

- the owner wants a normal fantasy kingdom instead of bedroom reality,
- the owner wants concept-art painting over tile-based readability,
- the owner wants a different primary art style than top-down pixel art,
- the owner does not accept that props may be simplified for gameplay clarity,
- or the first chain's art target does not feel like the right opening mood.

## Parallel Next Tasks After Approval

| Lane | Next Task |
|---|---|
| Art | `ART.2` tile palette list |
| Level | first-chain room art notes |
| Animation | first-chain animation needs |
| VFX | danger telegraph visual test |
| Technical | asset import and TileMap workflow |
