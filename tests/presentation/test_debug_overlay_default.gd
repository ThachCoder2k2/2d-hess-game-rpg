extends UnboundTest

## Debug fields are behind F3 and off by default (requirement 181; docs/game-base-plan.md D-29: "debug fields only behind F3,
## off by default in exports"). The production HUD shows what a player decides with; the pawn's cell and facing and the enemy
## that strikes next are for a developer. Driven on the real game scene, with the real F3 key:
##   - at the start no text of the HUD names a cell or the strike token, the readout is hidden and the control hints are up;
##   - F3 puts the readout in the place of the hints, with the numbers right, and a second press undoes it;
##   - the view survives a zone trip (it is the scene's, not a room's);
##   - a release build ignores a scene saved with the view on (ShellKeys.debug_view_at_start), and a debug build keeps it.

const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "debug_overlay_default"


func _init() -> void:
	suite_title = "DEBUG OVERLAY DEFAULT TEST"
	call_deferred("_run")


func _run() -> void:
	_the_start_state_of_the_scene_flag()
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	var main := await Support.boot_main(self)
	var hud := main.get("hud") as GameHud
	var board := main.get("board") as PrototypeBoard

	_expect(not main.get("debug_enabled") and not board.debug_enabled, "the game scene starts with the debug view off")
	_expect(not hud.debug_readout.visible and hud.control_prompts.visible, "the HUD starts with the debug readout hidden and the control hints up")
	_expect(_visible_debug_texts(hud).is_empty(), "no text a player can see names a cell or the strike token (%s)" % ", ".join(_visible_debug_texts(hud)))

	_press(main, KEY_F3)
	_expect(hud.debug_readout.visible and not hud.control_prompts.visible and board.debug_enabled, "F3 shows the readout in the place of the hints, and the board's debug layer with it")
	_expect(hud.debug_readout.cell_label.text.begins_with("CELL ") and hud.debug_readout.strike_label.text.is_empty(), "the readout says where the pawn stands (a room of one pawn has no strike line: %s)" % hud.debug_readout.cell_label.text)
	_expect(_visible_debug_texts(hud).size() >= 1, "and the debug text is on screen now")

	_press(main, KEY_F3)
	_expect(not hud.debug_readout.visible and hud.control_prompts.visible and not board.debug_enabled, "a second press puts the hints back and takes the readout away")

	_press(main, KEY_F3)
	await Support.travel_to(main, &"t3_first_pawn_clash", &"west_entry")
	_expect(hud.debug_readout.visible and not hud.control_prompts.visible, "the view survives a zone trip: the new room's HUD is drawn with it on")
	_expect(hud.debug_readout.strike_label.text != "", "and in a room with enemies the readout names who strikes next (%s)" % hud.debug_readout.strike_label.text)
	_press(main, KEY_F3)
	_expect(not hud.debug_readout.visible and hud.control_prompts.visible, "and F3 takes it away again there")

	Support.end_suite(self, save_service)


## The truth table of the start state: a release export ignores the scene, a debug build keeps what it asked for.
func _the_start_state_of_the_scene_flag() -> void:
	_expect(not ShellKeys.debug_view_at_start(true, false), "a release export starts with the debug view off even if the scene was saved with it on")
	_expect(ShellKeys.debug_view_at_start(true, true), "a build that can debug keeps a scene's request")
	_expect(not ShellKeys.debug_view_at_start(false, true) and not ShellKeys.debug_view_at_start(false, false), "and nothing turns it on by itself")


## What a player would read that belongs to the debug readout: a visible label of the HUD that begins with the cell line or
## says STRIKE.
func _visible_debug_texts(hud: GameHud) -> Array[String]:
	var found: Array[String] = []
	for label in _labels_of(hud):
		if label.is_visible_in_tree() and (label.text.begins_with("CELL ") or label.text.contains("STRIKE")):
			found.append(label.text)
	return found


func _labels_of(node: Node) -> Array[Label]:
	var found: Array[Label] = []
	if node is Label:
		found.append(node)
	for child in node.get_children():
		found.append_array(_labels_of(child))
	return found


func _press(main: Node, keycode: Key) -> void:
	Support.send_key(keycode, true)
	Support.pump(main, 0.05)
	Support.send_key(keycode, false)
	Support.pump(main, 0.05)
