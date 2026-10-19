extends UnboundTest

## ShellKeys (shell/shell_keys.gd, M3b step 2): the keys that belong to the game and not to the hero,
## answered from the frame's InputSnapshot. B (the Book) is pinned by test_bridge_book and the pause menu's
## Restart Room (R is Call child since M4, D-18) by test_bridge_death_respawn and test_game_flow; this suite pins
## F3, which only the scene's own code answered and no suite drove: it flips the exported debug flag, tells the
## board overlay and says so on the status line, and a second press undoes all three. F11 changes the window
## mode, which a headless run has no window to show, so it is not pressed here. The pause key is pinned by
## test_pause_freezes_tick and test_book_freezes_world (shell).

const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "shell_keys"


func _init() -> void:
	suite_title = "BRIDGE SHELL KEYS TEST"
	call_deferred("_run")


func _run() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	var main := await Support.boot_main(self)
	var board := main.get("board") as PrototypeBoard
	var hud := main.get("hud") as GameHud
	_expect(not main.get("debug_enabled") and not board.debug_enabled, "the debug layer ships off, on the scene and on the board")

	_press(main, KEY_F3)
	_expect(main.get("debug_enabled") and board.debug_enabled, "F3 switches the debug layer on, in the scene's flag and on the board")
	_expect(hud.objective_label.text == TextService.t(ShellKeys.DEBUG_VIEW_ON_KEY), "and says so on the status line")

	_press(main, KEY_F3)
	_expect(not main.get("debug_enabled") and not board.debug_enabled, "a second press switches it off again")
	_expect(hud.objective_label.text == TextService.t(ShellKeys.DEBUG_VIEW_OFF_KEY), "and says so")

	# The switch is the scene's, not a room's: a trip rebuilds the room and keeps it.
	_press(main, KEY_F3)
	await Support.travel_to(main, &"t2_fallen_sword_tile", &"west_entry")
	_expect(main.get("debug_enabled") and board.debug_enabled, "the debug layer survives a zone trip")

	Support.end_suite(self, save_service)


## One key press and release, with the simulation pumped across both so the poller sees each edge.
func _press(main: Node, keycode: Key) -> void:
	Support.send_key(keycode, true)
	Support.pump(main, 0.05)
	Support.send_key(keycode, false)
	Support.pump(main, 0.05)
