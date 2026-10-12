# LD.1 Spec - Bedroom World Layout

**Status:** approved by owner on 2026-09-30  
**Linked lane:** Level And World Design  
**Checklist gate:** `LD.1`

## Purpose

Define the physical bedroom arrangement that the imagined chess kingdom is built
on. This is the world map logic, not final room art.

## Bedroom Layout

```text
+--------------------------------------------------------------------+
| WINDOW / MOONLIGHT                    BOOKSHELF / BISHOP DISTRICT  |
|                                                                    |
| DESK / CHILD DRAWING AREA          BLOCK TOWER / ROOK DISTRICT     |
|                                                                    |
| TOYBOX / KNIGHT DISTRICT       CHESS RUG / MAIN HUB                |
|                                                                    |
| DOLLHOUSE / QUEEN DISTRICT          BED / UNDER-BED KING DISTRICT  |
+--------------------------------------------------------------------+
```

## District Identity

| District | Real Object | Gameplay Identity |
|---|---|---|
| Chess Rug | board/rug | opening, hub, fallen battlefield |
| Toybox | toy chest, tracks, figures | Knight movement and L-threats |
| Bookshelf | books, papers, bookmarks | Bishop diagonals and paper paths |
| Block Tower | toy blocks, ruler bridge | Rook lines, cover, breakable walls |
| Dollhouse | toy house/furniture | Queen mixed patterns and control |
| Under-Bed | bed shadow/chess box | King final, rule corruption |
| Desk | paper, crayons, lamp | child intervention source |

## Route Logic

The chess rug is the main hub. Districts are visible as bedroom objects, but
routes open over time.

```text
Opening -> Chess Rug Hub
Chess Rug Hub -> Toybox first
Toybox reward -> more hub routes readable
Bookshelf / Block Tower -> midgame expansion
Dollhouse -> late-game test
Under-Bed -> final route
Desk -> child help source, not a normal combat district first
```

## Completion Requirements

`LD.1` can be approved only if:

- the bedroom arrangement feels believable,
- each district has both real-object identity and gameplay identity,
- the chess rug as hub is accepted,
- the desk/child area is a support space rather than a normal first combat zone,
- and the route logic supports a 90-120 minute game.

## Cannot Approve If

- the map feels like a generic fantasy kingdom,
- the bedroom objects do not suggest gameplay,
- the hub location is unclear,
- or the route order makes the player travel illogically across the room.
