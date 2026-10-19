class_name WorldEdge
extends Resource

## One way through the world: the door `door` of room `from_room` leads to entry `to_entry` of room `to_room`
## (docs/game-base-plan.md 7.1, 7.2). The door itself is a ZoneExitMarker in the room scene, found by its node
## name; this record is the world's account of it, so the whole route can be read, drawn (tools/print_world_map.gd)
## and checked in one file. `tests/content/test_world_graph.gd` holds the two together: every door of every room is
## declared here, every edge here has its door, and both name the same target.

## The room the door is in (a WorldRoom.room_id).
@export var from_room: StringName = &""
## The node name of the ZoneExitMarker in `from_room` (for example `Exit_To_T2`).
@export var door: StringName = &""
## The room the door leads to (a WorldRoom.room_id).
@export var to_room: StringName = &""
## The ZoneEntryMarker.entry_id in `to_room` where the pawn arrives.
@export var to_entry: StringName = &""
## True when the way is not meant to be walked back: a shortcut home that has no door in the other direction.
## Every other edge needs the reverse edge (tests/content/test_world_graph.gd), so a corridor is never a trap.
@export var one_way := false
## The WorldLock that holds this door shut, empty for a door that is always open. Locks are listed once, in
## WorldGraph.locks, and may hold several doors.
@export var lock_id: StringName = &""
