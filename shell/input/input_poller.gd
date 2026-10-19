class_name InputPoller
extends RefCounted

## The one place in the project that reads the Input singleton (docs/game-base-plan.md 9.4, 13.1).
## game_root.gd owns one and calls poll() once per frame, right before the world ticks: it copies
## what the controls look like into the world's InputSnapshot, and PlayerInputSystem (and every
## input rule that follows) reads only that snapshot. The simulation never touches Input, so the
## buffer, the chord and the tap window are tested by injecting snapshots, the way every other ECS
## test injects components (test_input_snapshot), and a test_input_only_in_poller lint fails if
## another file calls the singleton.
##
## What it copies, per action: pressed, just_pressed, just_released exactly as the engine reports
## them for this frame (so a tick that runs several times inside one engine frame, the way the
## bridge suites pump, sees the same edges the system saw when it called Input itself), the seconds
## the action has been held and the engine time of its latest press.
##
## The poller keeps its own ActionState per action and lends it to every snapshot it fills, so the
## time an action has been held carries over a room change, when the shell builds a new world with
## a new snapshot, and a poll allocates nothing after the first.

## Keys the shell reads that are not InputMap actions yet. Each is published to the snapshot under
## the name given here, as if it were an action, with edges worked out by the poller (the engine has
## no "just pressed" for a raw key). docs/game-base-plan.md 9.4 says "no raw KEY_ polling": M4 adds
## these three to the InputMap under the same names and deletes this table, and no reader changes.
const RAW_KEY_BY_ACTION := {
	&"debug_view_toggle": KEY_F3,
	&"fullscreen_toggle": KEY_F11,
	&"rule_book_toggle": KEY_B,
}

## InputMap actions with this prefix are the engine's own menu navigation (ui_accept, ui_cancel...):
## the Control nodes handle them, and the simulation has no use for them.
const ENGINE_ACTION_PREFIX := "ui_"

## The InputMap actions copied each poll. Empty until the first poll, which fills it from the
## InputMap (every action but the engine's own); refresh_actions() reads it again, and a caller that
## wants a fixed set assigns it before the first poll.
var action_names: Array[StringName] = []

## action name (StringName) -> the ActionState this poller keeps for it between polls. The same
## objects are placed in each snapshot, so what a snapshot holds is only valid until the next poll.
var _state_by_action: Dictionary = {}


## Reads the controls once and writes the result into `snapshot`. `delta` is the seconds since the
## previous poll (the frame time the world is about to tick with); it only feeds held_time.
func poll(delta: float, snapshot: InputSnapshot) -> void:
	if action_names.is_empty():
		refresh_actions()
	for action in action_names:
		var state := _state_of(action)
		_advance(state, delta, Input.is_action_pressed(action), Input.is_action_just_pressed(action), Input.is_action_just_released(action))
		snapshot.set_state(action, state)
	for raw_action: StringName in RAW_KEY_BY_ACTION:
		var state := _state_of(raw_action)
		var key_down := Input.is_key_pressed(RAW_KEY_BY_ACTION[raw_action])
		_advance(state, delta, key_down, key_down and not state.pressed, not key_down and state.pressed)
		snapshot.set_state(raw_action, state)


## Reads the InputMap again: the actions the project defines, without the engine's own ui_ ones.
func refresh_actions() -> void:
	action_names.clear()
	for action in InputMap.get_actions():
		if not String(action).begins_with(ENGINE_ACTION_PREFIX):
			action_names.append(action)


func _state_of(action: StringName) -> InputSnapshot.ActionState:
	var state: InputSnapshot.ActionState = _state_by_action.get(action)
	if state == null:
		state = InputSnapshot.ActionState.new()
		_state_by_action[action] = state
	return state


## Updates `state` for one poll. held_time counts up only while the action stays down across polls,
## so the poll that sees the press reads 0.0 and the next one reads one delta.
func _advance(state: InputSnapshot.ActionState, delta: float, pressed: bool, just_pressed: bool, just_released: bool) -> void:
	state.held_time = state.held_time + delta if pressed and state.pressed else 0.0
	state.pressed = pressed
	state.just_pressed = just_pressed
	state.just_released = just_released
	if just_pressed:
		state.timestamp_msec = Time.get_ticks_msec()
