class_name RoomCheckpoint
extends RefCounted

## What CheckpointSystem needs to know about the room the pawn stands in (docs/game-base-plan.md 5.2, D-16):
## whether coming in through its door is a checkpoint, which entry the pawn came by, and what the system has
## already said about it. Pure data. It sits on the room's own entity beside RoomObjectiveState, which EcsBoot
## makes for a room the shell plays (EcsBootOptions.with_room_rules); the facts about HOW the pawn arrived
## come from the shell through EcsBootOptions, because only the shell knows whether a door, a launch or a
## respawn put the pawn here.

## Every component carries its store key (docs/coding-standards.md).
const KEY := &"room_checkpoint"

## The zone this room is (RoomEncounter.zone_id); &"" for a room outside the world graph.
var zone_id: StringName = &""

## The entry marker the pawn arrived on (a ZoneEntryMarker.entry_id of the room). It is where a death
## puts the pawn back (D-16: a death resets only this room) and what a checkpoint records.
var entry_id: StringName = &"start"

## True when stepping into this room through a door is a checkpoint (RoomEncounter.checkpoint_on_entry):
## a hub, and every boss room (D-16).
var checkpoint_on_entry := false

## True when the pawn came in through a door from another zone. A launch (New Game, Continue) and a respawn
## are not entries: the first has nothing to refill, the second already starts with full Courage and the
## checkpoint it names has not changed.
var entered_by_door := false

## True once the system has looked at the arrival (it does so on the first tick the world runs).
var arrival_judged := false

## True once the system has answered the pawn's fall with `respawn_requested`.
var respawn_requested := false
