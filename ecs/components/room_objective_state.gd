class_name RoomObjectiveState
extends RefCounted

## What the room asks of the pawn and how far the pawn has got (docs/game-base-plan.md 13.4,
## ObjectiveSystem). Pure data: ObjectiveSystem counts the enemies and judges the room, and everything
## that wants to know how the room is going reads it from here (HudSnapshotSystem copies the counts for
## the HUD, CheckpointSystem answers a fall). It sits on the room's own entity, which EcsBoot makes for a
## room the shell plays (EcsBootOptions.with_room_rules); a world without one has no room to judge.

## Every component carries its store key (docs/coding-standards.md).
const KEY := &"room_objective_state"

## The zone this room is (RoomEncounter.zone_id); &"" for a room outside the world graph.
var zone_id: StringName = &""

## The room's own win condition (RoomEncounter.objective), or null for the default: the room is
## cleared when every enemy it began with has fallen.
var objective: RoomObjective = null

## Enemies the room began with, how many have fallen, how many still stand. ObjectiveSystem keeps them
## true every tick; EcsBoot writes the first and the last so the HUD is right before the first tick.
var enemies_total := 0
var enemies_defeated := 0
var enemies_remaining := 0

## True once the room has been judged cleared (ObjectiveSystem announced `room_cleared`), or when the
## run says it was cleared on an earlier visit and its enemies were not spawned (D-17).
var cleared := false

## True once the pawn has fallen in this room. ObjectiveSystem judges it from the hero's Courage;
## CheckpointSystem answers it with `respawn_requested`. A room that is failed is never cleared.
var failed := false
