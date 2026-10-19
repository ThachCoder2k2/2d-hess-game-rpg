class_name ShellKeys
extends RefCounted

## The keys that belong to the game and not to the hero, answered once per frame from the controls the
## InputPoller copied into the world's InputSnapshot (only the poller reads the Input singleton):
##   R    start the room again, as after a death (a GameFlow request; M4 moves it to the pause menu)
##   F3   the debug layer on the board: boundaries, paths and behaviour labels
##   F11  fullscreen and windowed
##   B    open and close the Book of House Rules
## M4 turns F3, F11 and B into InputMap actions under these names and the pause menu takes R.

## What the status line says when the debug layer is switched.
const DEBUG_VIEW_ON_MESSAGE := "DEBUG VIEW ON: boundaries, paths, and behavior labels."
const DEBUG_VIEW_OFF_MESSAGE := "DEBUG VIEW OFF."

var _root: GameRoot


func attach(game_root: GameRoot) -> void:
	_root = game_root


func handle(controls: InputSnapshot) -> void:
	if controls.is_just_pressed(&"restart_room"):
		_root.game_flow.request_respawn(GameFlow.REASON_RESTART_KEY)
	if controls.is_just_pressed(&"debug_view_toggle"):
		_root.debug_enabled = not _root.debug_enabled
		_root.board_bridge.set_debug_view(_root.debug_enabled)
		_root.message_bridge.say(DEBUG_VIEW_ON_MESSAGE if _root.debug_enabled else DEBUG_VIEW_OFF_MESSAGE)
	if controls.is_just_pressed(&"fullscreen_toggle"):
		var window := _root.get_window()
		window.mode = Window.MODE_WINDOWED if window.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
	if controls.is_just_pressed(&"rule_book_toggle"):
		_root.book_bridge.toggle()
