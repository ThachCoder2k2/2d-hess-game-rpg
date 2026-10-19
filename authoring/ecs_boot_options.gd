class_name EcsBootOptions
extends RefCounted

## Everything EcsBoot.boot() needs besides the world, in one object (docs/game-base-plan.md 14.1).
## boot() used to take three to six positional arguments, and every milestone that needed one more
## (a saved player snapshot, a grid origin, a spawn override) would have changed every call site in
## the tests and the shell. Now a new need is a new field here with a neutral default; no call site
## changes unless it wants the new thing, and boot() never grows a parameter.
##
## Build one with EcsBootOptions.for_scene() for the common case (a hero and a room) and set the
## rest by name:
##
##     var options := EcsBootOptions.for_scene(player_view, room_root)
##     options.opened_gate_ids = saved_gate_ids
##     var cast := EcsBoot.boot(world, options)

## The hero's puppet view, an ActorView whose PlayerDefinition names the kit. Null boots a room with
## no player (the editor-draggable component tests, the actor stage).
var player_view: Node2D = null

## The room scene root: its parked ActorViews become enemies, its painted solid tiles become walls and its
## markers bake themselves (exits, unlocks, gates, pickups). Null boots only the player.
var room_root: Node = null

## Where the hero starts when its view stands outside the board.
var fallback_player_cell := Vector2i(3, 7)

## Pickup marker names the save already recorded as taken: they never respawn.
var skipped_pickup_names: Array = []

## Gate ids the save already recorded as opened: they boot as floor.
var opened_gate_ids: Array = []

## True when the save already recorded this room as cleared (D-17: a cleared room stays cleared): the
## enemies parked in its scene are not spawned and their views are removed, and the room's own entity (see
## with_room_rules) starts out cleared. Pickups are not affected: a floor weapon is room-local and is back
## on the floor every time the room starts, unless the marker is persistent and the save recorded it taken.
var room_already_cleared := false

## The entry marker of the room the hero arrives on (ZoneEntryMarker.entry_id). The room's own entity records
## it: it is where a death starts the room again and what a checkpoint names. Only read with with_room_rules.
var entry_id: StringName = &"start"

## True when the hero came in through a door from another zone (a zone trip). A launch and a respawn are
## not entries, so they set no checkpoint and refill nothing. Only read with with_room_rules.
var entered_by_door := false

## The size in pixels of the picture the room is shown in, which the board is centred in. Zero means the
## project's own base size (display/window/size in project.godot); a test or a tool that frames a room
## differently sets it.
var view_size := Vector2.ZERO

## True to give the room an entity of its own (RoomObjectiveState and RoomCheckpoint), which is what
## ObjectiveSystem and CheckpointSystem judge. The shell sets it for the room it plays. A tool
## or a test that only wants to see what spawns (the world dump, the actor stage) leaves it off, so its
## world holds exactly the entities the room's scene makes and no more.
var with_room_rules := false

## What the pawn carries into this room (PlayerSnapshot, docs/game-base-plan.md 14.2): the shell
## captures it from the old world at the room exit and passes it here. boot() applies it to the hero
## right after the hero is built, so the carried courage, the sword and the flags win over the
## definition and over any EntityComponent node. Null boots the hero as the definition says.
var player_snapshot: PlayerSnapshot = null

## True to also put the hero's carried facing back (a checkpoint or a save resume). A room change leaves
## it false: the entry marker sets the facing of the new room.
var restore_player_facing := false


## The common case: a hero and a room (either may be null).
static func for_scene(hero_view: Node2D, room: Node) -> EcsBootOptions:
	var options := EcsBootOptions.new()
	options.player_view = hero_view
	options.room_root = room
	return options
