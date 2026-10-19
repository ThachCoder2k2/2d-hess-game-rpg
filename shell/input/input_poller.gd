class_name InputPoller
extends RefCounted

## The one place in the project that reads the Input singleton (docs/game-base-plan.md 9.4, 13.1).
## game_root.gd owns one and calls poll() once per frame, right before the world ticks: it copies
## what the controls look like into the world's InputSnapshot, and PlayerInputSystem (and every
## input rule that follows) reads only that snapshot. The simulation never touches Input, so the
## buffer, the chord and the tap window are tested by injecting snapshots (test_input_snapshot), and
## a test_input_only_in_poller lint fails if another file calls the singleton.
##
## What it copies, per action: pressed, just_pressed, just_released exactly as the engine reports
## them for this frame (so a tick that runs several times inside one engine frame, the way the
## bridge suites pump, sees the same edges the system saw when it called Input itself), the seconds
## the action has been held and the engine time of its latest press.
##
## The poller keeps its own ActionState per action and lends it to every snapshot it fills, so the
## time an action has been held carries over a room change, when the shell builds a new world with
## a new snapshot, and a poll allocates nothing after the first.
##
## Two controls rules live here, because the simulation must never see raw hardware (9.4):
##   - The left stick's dominant axis. A stick pushed diagonally presses two of the four move actions
##     at once; only the one the stick leans on most stays pressed, so the pawn steps along the axis
##     the player means. Keys and the d-pad press with strength 1.0, so two of them at once tie and
##     are both published, exactly as before (PlayerInputSystem picks by its own order).
##   - Hold or toggle (the accessibility setting of 5.8). An action in `toggled_actions` is published
##     as a switch: each fresh press flips it on or off, instead of being down only while the
##     key is. The SettingsBridge sets it from the player's choice for Guard, Focus and turn mode.

## InputMap actions with this prefix are the engine's own menu navigation (ui_accept, ui_cancel...):
## the Control nodes handle them, and the simulation has no use for them.
const ENGINE_ACTION_PREFIX := "ui_"

## The four actions of the left stick and the d-pad, among which the dominant axis is picked.
const MOVE_ACTIONS: Array[StringName] = [&"move_up", &"move_down", &"move_left", &"move_right"]

## A move action weaker than the strongest one by more than this is the stick's minor axis.
const AXIS_TIE_MARGIN := 0.01

## The InputMap actions copied each poll. Empty until the first poll, which fills it from the
## InputMap (every action but the engine's own); refresh_actions() reads it again, and a caller that
## wants a fixed set assigns it before the first poll.
var action_names: Array[StringName] = []

## Actions published as a switch (a press flips them) instead of while held. Change it with
## set_toggle_mode(), which also lets go of a switch that was left on.
var toggled_actions: Dictionary[StringName, bool] = {}

## action name (StringName) -> the ActionState this poller keeps for it between polls. The same
## objects are placed in each snapshot, so what a snapshot holds is only valid until the next poll.
var _state_by_action: Dictionary = {}
## toggled action -> whether its switch is on right now.
var _switch_on_by_action: Dictionary[StringName, bool] = {}
## toggled action -> whether the control itself was down at the previous poll (a press is the edge up to down).
var _control_was_down_by_action: Dictionary[StringName, bool] = {}
## move action -> true while the stick's dominant axis was holding it back at the previous poll.
var _held_back_by_move_action: Dictionary[StringName, bool] = {}


## Reads the controls once and writes the result into `snapshot`. `delta` is the seconds since the
## previous poll (the frame time the world is about to tick with); it only feeds held_time.
func poll(delta: float, snapshot: InputSnapshot) -> void:
	if action_names.is_empty():
		refresh_actions()
	var strongest_move := _strongest_pressed_move_strength()
	for action in action_names:
		var state := _state_of(action)
		var pressed := Input.is_action_pressed(action)
		var just_pressed := Input.is_action_just_pressed(action)
		var just_released := Input.is_action_just_released(action)
		if action in MOVE_ACTIONS:
			var edges := _apply_dominant_axis(action, state, pressed, just_pressed, just_released, strongest_move)
			pressed = edges[0]
			just_pressed = edges[1]
			just_released = edges[2]
		if toggled_actions.has(action):
			var switched := _apply_toggle(action, pressed)
			pressed = switched[0]
			just_pressed = switched[1]
			just_released = switched[2]
		# Whatever the rules above did, an action that was published pressed and is not now was released: a switch
		# turned back into a held control while it was on ends its press here, with the edge.
		just_released = just_released or (state.pressed and not pressed)
		_advance(state, delta, pressed, just_pressed, just_released)
		snapshot.set_state(action, state)


## Makes `action` work as a switch (`enabled`) or as a held control again. Turning it off lets go of a
## switch that was left on, so the control is not stuck down.
func set_toggle_mode(action: StringName, enabled: bool) -> void:
	if enabled:
		toggled_actions[action] = true
		return
	toggled_actions.erase(action)
	_switch_on_by_action.erase(action)
	_control_was_down_by_action.erase(action)


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


## The strength of the strongest move action that is pressed now, 0.0 when none is.
func _strongest_pressed_move_strength() -> float:
	var strongest := 0.0
	for action in MOVE_ACTIONS:
		if Input.is_action_pressed(action):
			strongest = maxf(strongest, Input.get_action_strength(action))
	return strongest


## The dominant-axis rule for one move action. Returns [pressed, just_pressed, just_released] as they are to be
## published. An action the stick's major axis keeps (or any key or d-pad press) is published as the engine
## reports it. A pressed action that leans less than the strongest one is held back: published released, with the
## edge worked out from what was published before, since the engine's edge is about the physical control.
func _apply_dominant_axis(action: StringName, state: InputSnapshot.ActionState, pressed: bool, just_pressed: bool, just_released: bool, strongest_move: float) -> Array[bool]:
	var held_back_now := pressed and Input.get_action_strength(action) < strongest_move - AXIS_TIE_MARGIN
	var was_held_back: bool = _held_back_by_move_action.get(action, false)
	_held_back_by_move_action[action] = held_back_now
	if not held_back_now and not was_held_back:
		return [pressed, just_pressed, just_released]
	var published_pressed := pressed and not held_back_now
	return [published_pressed, published_pressed and not state.pressed, state.pressed and not published_pressed]


## The hold-or-toggle rule for one toggled action, given whether the control is down now. A fresh press flips
## the switch. Returns [pressed, just_pressed, just_released] of the SWITCH.
func _apply_toggle(action: StringName, control_down: bool) -> Array[bool]:
	var was_down: bool = _control_was_down_by_action.get(action, false)
	_control_was_down_by_action[action] = control_down
	var was_on: bool = _switch_on_by_action.get(action, false)
	var is_on := was_on != (control_down and not was_down)
	_switch_on_by_action[action] = is_on
	return [is_on, is_on and not was_on, was_on and not is_on]


## Updates `state` for one poll. held_time counts up only while the action stays down across polls,
## so the poll that sees the press reads 0.0 and the next one reads one delta.
func _advance(state: InputSnapshot.ActionState, delta: float, pressed: bool, just_pressed: bool, just_released: bool) -> void:
	state.held_time = state.held_time + delta if pressed and state.pressed else 0.0
	state.pressed = pressed
	state.just_pressed = just_pressed
	state.just_released = just_released
	if just_pressed:
		state.timestamp_msec = Time.get_ticks_msec()
