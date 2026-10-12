# Stage 1 Commercial Tutorial Redesign

**Status:** first playable spine implemented, structural review loop complete  
**Date:** 2026-10-02  
**Goal:** make the opening act feel closer to a real commercial tutorial stage,
not just a connected prototype map.

---

## Reference Standard

The main reference is *Prince of Persia: The Lost Crown*'s opening structure:

- it starts inside an active battlefield,
- teaches movement and combat through real play,
- escalates before the world opens,
- ends the opening with a tutorial boss,
- and uses the boss as a mastery check before the wider game begins.

For this game, the same idea becomes:

```text
The pawn wakes after the war -> receives the sword -> survives one pawn ->
faces rule-breaking pawns -> defeats the captain -> the bedroom world opens.
```

---

## Stage 1 Player Promise

By the end of Stage 1, the player should understand:

1. The White kingdom has already lost.
2. The child/player is helping the pawn survive.
3. Movement is one grid cell at a time, but combat is real-time.
4. Facing matters.
5. Enemy telegraphs matter.
6. Black pieces can break chess rules with weapons.
7. The first boss tests the tutorial instead of introducing a new game.
8. The Toybox is Act 2, not the tutorial.

---

## Implemented Spine

```text
T1_WhiteKingsFall
  movement, loss, direction

T2_FallenSwordTile
  sword framing, child-help moment, next-route pull

T3_FirstPawnClash
  first single pawn duel

T4_BrokenRuleYard
  armed pawn pressure, weapon pickup, multiple threats

B1_BlackPawnCaptain
  tutorial boss/checkpoint-style mastery room

H1_ChessRugHub
  world opens, Toybox/bedroom foreshadow
```

All six rooms are editor-owned `.tscn` files, registered in the world graph,
and connected through visible `ZoneEntryMarker` and `ZoneExitMarker` nodes.

---

## What Counts As Done For This Pass

This pass is considered complete when:

- all Stage 1 rooms exist as editable scenes,
- the route can be followed from T1 to Hub,
- each room has visible art/set-dressing nodes,
- combat rooms contain editor-visible enemy actors,
- the boss room has a distinct captain Resource,
- every world-graph door resolves to a real zone and entry marker,
- Godot imports cleanly,
- automated tests pass.

The structural review loop adds three stricter requirements:

- the sword must be a real unlock in T2,
- T3 and T4 forward exits must require clearing their tutorial fights,
- the B1 boss exit must require defeating the boss room.

This pass does not yet claim:

- final art,
- final room composition,
- final cutscene timing,
- final child narration,
- final difficulty balance,
- final Stage 1 approval.

Those require owner play review in Godot.

---

## Next Polish Gates

```text
Gate S1.1 - Opening readability
Review T1/T2: does the player understand loss, sword, and route?

Gate S1.2 - First duel feel
Review T3: does one pawn teach attack timing without feeling cheap?

Gate S1.3 - Rule-break escalation
Review T4: do armed pawns feel like Black broke chess rules?

Gate S1.4 - First boss quality
Review B1: does the Pawn Captain feel like a real first boss?

Gate S1.5 - World opening
Review H1: does the room clearly say Toybox is next?
```
