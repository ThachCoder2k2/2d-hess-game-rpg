class_name EventBridge
extends RefCounted

## What every bridge shares (docs/game-base-plan.md 13.2). A bridge is ONE responsibility between the
## simulation and the rest of the game: it registers for the event types it reacts to, and it reacts.
## Nothing else in the scene decides what a hit, a pickup or a defeat looks, sounds or saves like.
##
## A bridge learns about the room that is running only through the two things the scene hands it
## after every boot, because every room is a new world:
##   snapshot  the world's HudSnapshot, the read-only picture a bridge may read (it is rebuilt in place,
##             so a bridge keeps the reference for the whole room). A bridge never reads a component.
##             Until the first boot it is an empty one, so a bridge never has to ask whether it has one.
##   cast      the dictionary EcsBoot.boot() returned: the views and names of what it spawned.
## A bridge that must change the simulation does it with a typed request on world.commands; it never
## sets a component (the bridges that still write one are listed in docs/ARCHITECTURE.md).
##
## The registration order of the bridges is the order they react in when one event has several
## (game_root.gd lists it in one place).

## What a piece the cast has no name for is called.
const UNKNOWN_PIECE_KEY := "ENEMY_UNKNOWN_PIECE"

var snapshot := HudSnapshot.new()
var cast: Dictionary = {}


## Registers this bridge's handlers with `router`. A bridge that reacts to no event registers none.
func register(_router: EventRouter) -> void:
	pass


## Called by the scene after every boot, with the new world's snapshot and cast.
func bind_world(world_snapshot: HudSnapshot, world_cast: Dictionary) -> void:
	snapshot = world_snapshot
	cast = world_cast


## The entity id of the hero in the room that is running, 0 when there is none.
func player_entity() -> int:
	return snapshot.player_entity


func is_player(entity: int) -> bool:
	return entity == player_entity()


## The name the room's cast gives a piece, as a TextKey so a language switch renames it (the key of an entity the
## cast does not know is ENEMY_UNKNOWN_PIECE). The cast holds the piece's key (EnemyDefinition.piece_name).
func piece_name_of(entity: int) -> TextKey:
	return TextKey.of(String(cast.get("piece_name_by_entity", {}).get(entity, UNKNOWN_PIECE_KEY)))
