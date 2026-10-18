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
