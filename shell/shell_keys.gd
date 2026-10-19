class_name ShellKeys
extends RefCounted

## The keys that belong to the game and not to the hero, answered once per frame from the controls the
## InputPoller copied into the world's InputSnapshot (only the poller reads the Input singleton). Each is an
## InputMap action (docs/game-base-plan.md 9.4):
##   pause               Esc, Start: close the Book when it is open, otherwise ask the flow to pause (the pause menu
##                       itself closes on the same key, see PauseMenu, because a paused tree does not tick this)
##   debug_view_toggle   F3: the debug layer on the board: boundaries, paths and behaviour labels
##   fullscreen_toggle   F11: fullscreen and windowed
##   rule_book_toggle    B, L3: open and close the Book of House Rules
## R is not here: it is Call child (D-18), and restarting the room is a command of the pause menu.
##
## Each key acts on the poll that first finds it DOWN. The engine's own "just pressed" is true for the rest of the
## frame the press happened in, so a scene polled several times in one frame (the bridge suites pump that way) would
## open and close the Book on one press; the keys here work out their own edge from the polls.

## What the status line says when the debug layer is switched.
const DEBUG_VIEW_ON_MESSAGE := "DEBUG VIEW ON: boundaries, paths, and behavior labels."
const DEBUG_VIEW_OFF_MESSAGE := "DEBUG VIEW OFF."

var _root: GameRoot
## action -> whether the key was down at the previous handle().
var _was_down_by_action: Dictionary[StringName, bool] = {}


func attach(game_root: GameRoot) -> void:
	_root = game_root


func handle(controls: InputSnapshot) -> void:
	if _is_fresh(controls, &"pause"):
		if _root.book_bridge.is_open():
			_root.book_bridge.dismiss()
		elif _root.game_flow.pause_menu_available:
			_root.game_flow.request_pause()
	if _is_fresh(controls, &"debug_view_toggle"):
		_root.debug_enabled = not _root.debug_enabled
		_root.board_bridge.set_debug_view(_root.debug_enabled)
		_root.message_bridge.say(DEBUG_VIEW_ON_MESSAGE if _root.debug_enabled else DEBUG_VIEW_OFF_MESSAGE)
	if _is_fresh(controls, &"fullscreen_toggle"):
		var window := _root.get_window()
		window.mode = Window.MODE_WINDOWED if window.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
	if _is_fresh(controls, &"rule_book_toggle"):
		_root.book_bridge.toggle()


## Whether `action` is down now and was not at the previous poll. Call it once per action per handle().
func _is_fresh(controls: InputSnapshot, action: StringName) -> bool:
	var down := controls.is_pressed(action)
	var was_down: bool = _was_down_by_action.get(action, false)
	var fresh := down and not was_down
	_was_down_by_action[action] = down
	return fresh
