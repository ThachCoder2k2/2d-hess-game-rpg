class_name InputSnapshot
extends RefCounted

## What the player's controls looked like at one simulation tick (docs/game-base-plan.md 9.4): for
## every InputMap action, whether it is held, was just pressed, was just released, for how long it
## has been held and when it was last pressed. The shell fills it once per tick from the real
## input; PlayerInputSystem reads only this, so the buffer, the chord and the tap window are
## tested by injecting snapshots, the way every other ECS test injects components, and the
## simulation never touches the Input singleton.
##
## EcsWorld.input_snapshot holds the current one. An action nobody set reads as not pressed.


## One action's state at the tick.
class ActionState:
	## The action is held down right now.
	var pressed := false
	## It went down during this tick.
	var just_pressed := false
	## It went up during this tick.
	var just_released := false
	## Seconds the action has been held down, 0.0 while it is not held.
	var held_time := 0.0
	## Engine time in milliseconds of the most recent press (Time.get_ticks_msec()), -1 if it was never pressed.
	var timestamp_msec := -1


## InputMap action name (StringName) -> that action's ActionState. Holds only actions that were set.
var state_by_action: Dictionary = {}


func set_state(action: StringName, state: ActionState) -> void:
	state_by_action[action] = state


## Sets one action's whole state in one call and returns it. This is how a test (or a tool) injects
## a press: `snapshot.set_action(&"move_left", true, true)` is a fresh tap of the left key.
func set_action(action: StringName, pressed: bool, just_pressed := false, just_released := false, held_time := 0.0, timestamp_msec := -1) -> ActionState:
	var state := ActionState.new()
	state.pressed = pressed
	state.just_pressed = just_pressed
	state.just_released = just_released
	state.held_time = held_time
	state.timestamp_msec = timestamp_msec
	state_by_action[action] = state
	return state


## The action's state; a fresh released state for an action nobody set.
func state_of(action: StringName) -> ActionState:
	var state: ActionState = state_by_action.get(action)
	return state if state != null else ActionState.new()


func is_pressed(action: StringName) -> bool:
	return state_of(action).pressed


func is_just_pressed(action: StringName) -> bool:
	return state_of(action).just_pressed


func is_just_released(action: StringName) -> bool:
	return state_of(action).just_released


## Seconds the action has been held down, 0.0 when it is not.
func held_time_of(action: StringName) -> float:
	return state_of(action).held_time


## Forgets every action: all released.
func clear() -> void:
	state_by_action.clear()
