class_name GameFlow
extends RefCounted

## The state of the run as the player lives it, in its smallest form (docs/game-base-plan.md 9.1, M3b
## step 2). It handles the one request the in-game scene can make of its flow today: START THE ROOM
## AGAIN, which a death and the R key both raise. Before this class both reloaded the whole scene
## (`get_tree().reload_current_scene()`), which would reload the title once AppRoot is the main scene
## (M4), restarted the music, and threw away the hero's view and every node with it. Now the scene
## stays, the run (the SaveService autoload) stays, and GameRoot.respawn() rebuilds the zone from the
## run's checkpoint.
##
##   PLAYING -> RESPAWNING -> PLAYING          a death or the restart key (`request_respawn`)
##
## M4 grows this into AppRoot's state machine (BOOT, TITLE, PLAYING, PAUSED, RESPAWNING, ENDING,
## CREDITS) and puts the transition layer on `respawn_requested` and `respawned`. The scene stays
## testable alone: it makes its own GameFlow when no AppRoot gave it one.
##
## A request is served at the end of the frame (like the scene reload it replaces was), once, and
## after a zone trip that is under way has ended: the trip already moved the checkpoint to its
## destination, so the room is rebuilt there, exactly where the reload used to land.

enum State {
	## The room is live.
	PLAYING,
	## The zone is being rebuilt at the checkpoint (inside one frame, never across frames).
	RESPAWNING,
}

## A death asked: the hero fell and the defeat beat is over.
const REASON_DEFEATED := &"defeated"
## The restart key (R) asked. M4 moves it to the pause menu's Restart Room.
const REASON_RESTART_KEY := &"restart_key"

## A request was accepted; the rebuild follows at the end of the frame. `reason` is one of REASON_*.
signal respawn_requested(reason: StringName)
## The zone was rebuilt at the checkpoint and the hero stands on its entry with full Courage.
signal respawned(reason: StringName)

var state := State.PLAYING
## The reason of the latest accepted request, &"" before the first.
var last_respawn_reason: StringName = &""
## How many times the room has been rebuilt by a request. A caller that waits (the defeat beat) compares it
## before and after to learn whether somebody else already started the room again.
var respawn_count := 0

var _root: GameRoot
var _respawn_pending := false


## Binds the flow to the in-game scene it rebuilds.
func attach(game_root: GameRoot) -> void:
	_root = game_root


## The hero fell or the restart key was pressed: start the room again at the run's checkpoint. Ignored
## while a request is already waiting (a held key or a death beat and a key in the same frame
## rebuilds once).
func request_respawn(reason: StringName) -> void:
	if _respawn_pending or _root == null:
		return
	_respawn_pending = true
	last_respawn_reason = reason
	respawn_requested.emit(reason)
	_serve_respawn.call_deferred(reason)


## True from the accepted request until the room is rebuilt.
func respawn_is_pending() -> bool:
	return _respawn_pending


func _serve_respawn(reason: StringName) -> void:
	# A trip in flight finishes first: it is mid-fade and about to swap the zone itself.
	while is_instance_valid(_root) and _root.zone_travel_bridge.travel_in_progress and _root.is_inside_tree():
		await _root.get_tree().process_frame
	if is_instance_valid(_root) and _root.is_inside_tree():
		state = State.RESPAWNING
		_root.respawn()
		respawn_count += 1
		state = State.PLAYING
		respawned.emit(reason)
	_respawn_pending = false
