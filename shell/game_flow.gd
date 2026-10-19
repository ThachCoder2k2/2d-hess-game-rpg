class_name GameFlow
extends RefCounted

## The state of the run as the player lives it (docs/game-base-plan.md 9.1, D-26). One small state machine
## that decides which request is legal when; it builds no screen and touches no node. AppRoot (the main
## scene) listens to `state_changed` and shows the screen of the new state; the in-game scene (GameRoot)
## attaches itself so the flow can ask it to rebuild a room. The flow is a plain object so it can be
## driven by a test with no scene at all.
##
##   BOOT -> TITLE -> (New Game | Continue) -> PLAYING <-> PAUSED
##   PLAYING -> RESPAWNING -> PLAYING          a death, or Restart Room (`request_respawn`)
##   PLAYING -> ENDING -> CREDITS -> TITLE     the ending, then the credits (the `completed` mark is written)
##   TITLE -> CREDITS -> TITLE                 the credits replayed from the title menu
##   PLAYING | PAUSED | ENDING -> TITLE        Quit to Title
##
## What each request does besides changing the state:
##   - New Game starts a clean run in the slot and writes that clean run over the slot's file at once
##     (SaveService.start_new_run), so the old run cannot come back by a relaunch; the profile, and with it
##     the `completed` mark, is kept. Continue loads the slot's last save (the room and the entry it was
##     saved in) and is refused when the slot holds nothing readable. A quit, a pause and a death write
##     nothing (R17).
##   - Reaching the ending writes the `completed` mark to the profile (docs/game-base-plan.md 8.8).
##   - A pause is refused while a zone trip is under way, while a room rebuild is waiting and while the room is
##     ending (9.2: "Pause is blocked during zone travel").
##
## The room rebuild is the one request the in-game scene makes of its flow (M3b): a death and the R key
## both raise it, `GameRoot.respawn()` serves it. Before this class existed both reloaded the whole scene,
## which would reload the title now that AppRoot is the main scene, restarted the music, and threw away the
## hero's view and every node with it. The scene stays, the run (the SaveService autoload) stays, and the
## zone the run says the pawn is in is rebuilt on the entry it came by (D-16: a death resets only the room
## it happened in). A request is served at the end of the frame, once, after a zone trip that is under way has
## ended: the trip already moved the run's room to its destination, so the room is rebuilt there. When AppRoot
## supplied `before_respawn` the rebuild also waits for it (the fade to black), and `after_respawn` starts the
## fade back in.
##
## The scene stays testable alone: GameRoot makes its own flow, already PLAYING, when no AppRoot gave it one.

## The SaveService autoload has no class_name (an autoload's name is a global), so its script is the type.
const SaveServiceScript := preload("res://shell/save/save_service.gd")

enum State {
	## The app has started and shows nothing yet; the first thing it does is open the title.
	BOOT,
	## The title screen: New Game, Continue, Settings, Credits, Quit.
	TITLE,
	## The room is live.
	PLAYING,
	## The tree is paused over the room (the pause menu is up).
	PAUSED,
	## The room is being rebuilt on its entry (inside one frame, never across frames).
	RESPAWNING,
	## The ending is on screen (the playable Desk board and its hold, M13).
	ENDING,
	## The credits are rolling.
	CREDITS,
}

## How a run began, for the screen that follows it.
enum StartMode {
	## Nothing has started yet.
	NONE,
	## New Game: a clean run.
	NEW_GAME,
	## Continue: the slot's last save.
	CONTINUE,
}

## state -> the states a request may move the flow to. Anything else is refused and changes nothing.
const NEXT_STATES := {
	State.BOOT: [State.TITLE],
	State.TITLE: [State.PLAYING, State.CREDITS],
	State.PLAYING: [State.PAUSED, State.RESPAWNING, State.ENDING, State.TITLE],
	State.PAUSED: [State.PLAYING, State.TITLE],
	State.RESPAWNING: [State.PLAYING],
	State.ENDING: [State.CREDITS, State.TITLE],
	State.CREDITS: [State.TITLE],
}

## A death asked: the hero fell and the defeat beat is over.
const REASON_DEFEATED := &"defeated"
## The restart key (R) asked. M4 moves it to the pause menu's Restart Room.
const REASON_RESTART_KEY := &"restart_key"
## The pause menu's Restart Room asked (the same rebuild, no key).
const REASON_RESTART_MENU := &"restart_menu"

## The flow moved from `previous` to `current`. AppRoot shows the screen of `current`.
signal state_changed(previous: State, current: State)
## A request was accepted; the rebuild follows at the end of the frame. `reason` is one of REASON_*.
signal respawn_requested(reason: StringName)
## The room was rebuilt and the hero stands on its entry with full Courage.
signal respawned(reason: StringName)

var state := State.BOOT
## How the current run began: New Game or Continue. NONE until the first one.
var start_mode := StartMode.NONE
## The text key of the one-line notice the loader had for the run that Continue started (a save that was
## damaged and the previous one was loaded), "" for none. The title shows the same notice before Continue.
var load_notice_key: StringName = &""
## The reason of the latest accepted request, &"" before the first.
var last_respawn_reason: StringName = &""
## How many times the room has been rebuilt by a request. A caller that waits (the defeat beat) compares it
## before and after to learn whether somebody else already started the room again.
var respawn_count := 0
## The save service New Game and Continue go through. Null in a flow driven alone: those requests then only
## change the state.
var save_service: SaveServiceScript = null
## The slot New Game and Continue use.
var slot := SaveServiceScript.SINGLE_SLOT
## Coroutine called with the reason before a room is rebuilt, which the rebuild waits for (AppRoot: fade to black).
var before_respawn := Callable()
## Called with the reason right after the room was rebuilt, not waited for (AppRoot: fade back in).
var after_respawn := Callable()

var _root: GameRoot
var _respawn_pending := false


## `initial_state` is BOOT for the flow AppRoot owns; the in-game scene makes its own flow already PLAYING.
func _init(initial_state := State.BOOT) -> void:
	state = initial_state


## Binds the flow to the in-game scene it rebuilds.
func attach(game_root: GameRoot) -> void:
	_root = game_root


## Whether a request to go to `next_state` would be accepted by the table (the other conditions of a request,
## a readable save for Continue, are checked by the request).
func can_go(next_state: State) -> bool:
	return next_state in NEXT_STATES[state]


## True while the room, a pause over it or the ending is the current screen.
func is_in_game() -> bool:
	return state in [State.PLAYING, State.PAUSED, State.RESPAWNING, State.ENDING]


## BOOT -> TITLE: the app has started.
func finish_boot() -> bool:
	return _go(State.TITLE) if state == State.BOOT else false


## TITLE -> PLAYING with a clean run in the slot. The slot's file becomes the clean run at once.
func start_new_game() -> bool:
	if state != State.TITLE:
		return false
	if save_service != null:
		var error := save_service.start_new_run(slot)
		if error != OK:
			push_warning("GameFlow: the new run could not be written to slot %d (error %d: %s); it starts anyway and the next success event tries again" % [slot, error, error_string(error)])
	load_notice_key = &""
	start_mode = StartMode.NEW_GAME
	return _go(State.PLAYING)


## TITLE -> PLAYING with the slot's last save. Refused (false, nothing changes) when the slot holds no readable
## progress: the title does not offer Continue then, and a file from a newer game is never read as a save.
func continue_game() -> bool:
	if state != State.TITLE:
		return false
	if save_service != null:
		if not save_service.read_slot(slot).found_progress():
			return false
		var result := save_service.load_slot(slot)
		load_notice_key = result.notice_key
	else:
		load_notice_key = &""
	start_mode = StartMode.CONTINUE
	return _go(State.PLAYING)


## PLAYING -> PAUSED. Refused while a zone trip is under way (the trip is mid-fade and swaps the zone itself), while
## a room rebuild is waiting and while the room is ending (the defeat beat, which asks for the rebuild itself).
func request_pause() -> bool:
	if state != State.PLAYING or _respawn_pending:
		return false
	if _root_is_alive() and (_root.zone_travel_bridge.travel_in_progress or _root.outcome_bridge.room_ending):
		return false
	return _go(State.PAUSED)


## PAUSED -> PLAYING.
func request_resume() -> bool:
	return _go(State.PLAYING) if state == State.PAUSED else false


## PLAYING, PAUSED or ENDING -> TITLE: Quit to Title. Nothing is saved (a quit is not a success event, R17), so
## the progress since the last save is lost, which the pause menu's confirm says. The in-game scene is let go.
func quit_to_title() -> bool:
	if state not in [State.PLAYING, State.PAUSED, State.ENDING]:
		return false
	_root = null
	_respawn_pending = false
	return _go(State.TITLE)


## PLAYING -> ENDING: the ending was reached. Writes the `completed` mark to the profile.
func reach_ending() -> bool:
	if state != State.PLAYING:
		return false
	if save_service != null:
		save_service.mark_completed()
	return _go(State.ENDING)


## ENDING -> CREDITS: the ending's hold is over.
func finish_ending() -> bool:
	return _go(State.CREDITS) if state == State.ENDING else false


## TITLE -> CREDITS: the credits replayed from the title menu.
func show_credits() -> bool:
	return _go(State.CREDITS) if state == State.TITLE else false


## CREDITS -> TITLE: the roll ended or was skipped.
func finish_credits() -> bool:
	return _go(State.TITLE) if state == State.CREDITS else false


## The hero fell or Restart Room was chosen: start the room again on the entry the pawn came by. Ignored
## while a request is already waiting (a held key or a death beat and a key in the same frame rebuilds once)
## and while no room is live. A pause is lifted first.
func request_respawn(reason: StringName) -> void:
	if _respawn_pending or not _root_is_alive():
		return
	if state == State.PAUSED:
		request_resume()
	if state != State.PLAYING:
		return
	_respawn_pending = true
	last_respawn_reason = reason
	respawn_requested.emit(reason)
	_serve_respawn.call_deferred(reason)


## True from the accepted request until the room is rebuilt.
func respawn_is_pending() -> bool:
	return _respawn_pending


func _go(next_state: State) -> bool:
	if not can_go(next_state):
		return false
	var previous := state
	state = next_state
	state_changed.emit(previous, next_state)
	return true


## False for no scene and for one that was freed (quit to title while a request was waiting).
func _root_is_alive() -> bool:
	return is_instance_valid(_root)


func _serve_respawn(reason: StringName) -> void:
	# A trip in flight finishes first: it is mid-fade and about to swap the zone itself.
	while _root_is_alive() and _root.zone_travel_bridge.travel_in_progress and _root.is_inside_tree():
		await _root.get_tree().process_frame
	if before_respawn.is_valid() and _root_is_alive():
		await before_respawn.call(reason)
	# The player may have left for the title while the screen was fading: there is no room to rebuild then.
	if _root_is_alive() and _root.is_inside_tree() and state == State.PLAYING:
		_go(State.RESPAWNING)
		_root.respawn()
		respawn_count += 1
		_go(State.PLAYING)
		respawned.emit(reason)
		if after_respawn.is_valid():
			after_respawn.call(reason)
	_respawn_pending = false
