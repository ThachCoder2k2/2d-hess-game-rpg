extends UnboundTest

## The two controls rules the InputPoller applies before the simulation sees the controls (docs/game-base-plan.md 9.4, 5.8):
##   - the left stick's DOMINANT AXIS: a diagonal push presses two move actions, and only the one the stick leans on most
##     is published pressed; keys and the d-pad, which press with full strength, are published exactly as before;
##   - HOLD OR TOGGLE: an action switched to toggle is published as a switch that each fresh press flips;
##   - A FRESH PRESS FOR A NEW ROOM (M5 fix): a walking key that was down when a room began is published released until
##     it is let go, so a key held through a door does not carry the pawn back out of the door it arrived beside.
## Both are driven through the real Input singleton (events parsed as the OS would), polled by hand.

var poller := InputPoller.new()
var snapshot := InputSnapshot.new()


func _init() -> void:
	suite_title = "INPUT POLLER RULES TEST"
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	await _check_the_dominant_axis()
	await _check_keys_and_the_dpad_are_untouched()
	await _check_hold_or_toggle()
	await _check_a_held_key_needs_a_fresh_press_in_a_new_room()
	_release_everything()
	finish()


func _check_the_dominant_axis() -> void:
	_stick(0.8, 0.6)
	poller.poll(0.016, snapshot)
	_expect(snapshot.is_pressed(&"move_right") and not snapshot.is_pressed(&"move_down"), "a stick pushed right and a little down presses right only: the stronger axis wins")
	_expect(snapshot.is_just_pressed(&"move_right") and not snapshot.is_just_pressed(&"move_down"), "and only the major axis has a press edge")

	await process_frame
	_stick(0.5, 0.9)
	poller.poll(0.016, snapshot)
	_expect(snapshot.is_pressed(&"move_down") and not snapshot.is_pressed(&"move_right"), "leaning further down makes down the one that is pressed")
	_expect(snapshot.is_just_pressed(&"move_down") and snapshot.is_just_released(&"move_right"), "right is released and down is pressed on the same poll")

	await process_frame
	_stick(0.9, 0.9)
	poller.poll(0.016, snapshot)
	_expect(snapshot.is_pressed(&"move_down") and snapshot.is_pressed(&"move_right"), "an exact diagonal ties, and both are published (PlayerInputSystem picks by its own order)")

	await process_frame
	_stick(0.2, 0.2)
	poller.poll(0.016, snapshot)
	_expect(not snapshot.is_pressed(&"move_down") and not snapshot.is_pressed(&"move_right"), "inside the dead zone of 0.35 nothing is pressed")
	_stick(0.0, 0.0)
	await process_frame
	poller.poll(0.016, snapshot)
	_expect(not snapshot.is_pressed(&"move_down") and not snapshot.is_pressed(&"move_right") and not snapshot.is_pressed(&"move_up") and not snapshot.is_pressed(&"move_left"), "and with the stick centred the move actions are released")

	# A push that gets stronger on the minor axis lets the held-back action through with a fresh edge.
	_stick(0.9, 0.5)
	await process_frame
	poller.poll(0.016, snapshot)
	_expect(snapshot.is_pressed(&"move_right") and not snapshot.is_pressed(&"move_down"), "setup: right leads, down is held back")
	await process_frame
	_stick(0.4, 0.9)
	poller.poll(0.016, snapshot)
	_expect(snapshot.is_just_pressed(&"move_down") and snapshot.is_pressed(&"move_down"), "the action that was held back is pressed the poll it takes the lead")
	_stick(0.0, 0.0)
	await process_frame
	poller.poll(0.016, snapshot)


func _check_keys_and_the_dpad_are_untouched() -> void:
	await process_frame
	Input.action_press(&"move_up")
	Input.action_press(&"move_right")
	poller.poll(0.016, snapshot)
	_expect(snapshot.is_pressed(&"move_up") and snapshot.is_pressed(&"move_right"), "two keys at once are both published, as they always were")
	_expect(snapshot.is_just_pressed(&"move_up") and snapshot.is_just_pressed(&"move_right"), "each with the engine's own press edge")
	Input.action_release(&"move_up")
	Input.action_release(&"move_right")
	await process_frame
	poller.poll(0.016, snapshot)
	_expect(not snapshot.is_pressed(&"move_up") and not snapshot.is_pressed(&"move_right"), "and released when the keys are")


func _check_hold_or_toggle() -> void:
	var toggle_poller := InputPoller.new()
	var toggle_snapshot := InputSnapshot.new()
	toggle_poller.action_names = [&"turn_mode", &"guard"]
	await process_frame

	# Held (the default): down only while the key is.
	Input.action_press(&"turn_mode")
	toggle_poller.poll(0.1, toggle_snapshot)
	_expect(toggle_snapshot.is_pressed(&"turn_mode"), "held: the action is down while its key is")
	Input.action_release(&"turn_mode")
	await process_frame
	toggle_poller.poll(0.1, toggle_snapshot)
	_expect(not toggle_snapshot.is_pressed(&"turn_mode"), "held: and up when the key is up")

	# Toggle: a press switches it on and it stays on.
	toggle_poller.set_toggle_mode(&"turn_mode", true)
	await process_frame
	Input.action_press(&"turn_mode")
	toggle_poller.poll(0.1, toggle_snapshot)
	_expect(toggle_snapshot.is_pressed(&"turn_mode") and toggle_snapshot.is_just_pressed(&"turn_mode"), "toggle: the first press switches the action on, with a press edge")
	Input.action_release(&"turn_mode")
	await process_frame
	toggle_poller.poll(0.1, toggle_snapshot)
	_expect(toggle_snapshot.is_pressed(&"turn_mode") and not toggle_snapshot.is_just_pressed(&"turn_mode"), "toggle: letting go of the key leaves it on")
	toggle_poller.poll(0.4, toggle_snapshot)
	_expect(is_equal_approx(toggle_snapshot.held_time_of(&"turn_mode"), 0.5), "and its held time keeps counting while it is on (0.1 + 0.4)")
	await process_frame
	Input.action_press(&"turn_mode")
	toggle_poller.poll(0.1, toggle_snapshot)
	_expect(not toggle_snapshot.is_pressed(&"turn_mode") and toggle_snapshot.is_just_released(&"turn_mode"), "toggle: the second press switches it off, with a release edge")
	toggle_poller.poll(0.1, toggle_snapshot)
	_expect(not toggle_snapshot.is_pressed(&"turn_mode"), "toggle: holding the key through the next polls does not flip it again")
	Input.action_release(&"turn_mode")
	await process_frame
	toggle_poller.poll(0.1, toggle_snapshot)
	_expect(not toggle_snapshot.is_pressed(&"turn_mode"), "toggle: and releasing it changes nothing")

	# Other actions are unaffected.
	Input.action_press(&"guard")
	toggle_poller.poll(0.1, toggle_snapshot)
	Input.action_release(&"guard")
	await process_frame
	toggle_poller.poll(0.1, toggle_snapshot)
	_expect(not toggle_snapshot.is_pressed(&"guard"), "an action that was not switched to toggle is still held")

	# Back to held while the switch is on: the action does not stay stuck down.
	await process_frame
	Input.action_press(&"turn_mode")
	toggle_poller.poll(0.1, toggle_snapshot)
	Input.action_release(&"turn_mode")
	await process_frame
	toggle_poller.poll(0.1, toggle_snapshot)
	_expect(toggle_snapshot.is_pressed(&"turn_mode"), "setup: the switch is on")
	toggle_poller.set_toggle_mode(&"turn_mode", false)
	toggle_poller.poll(0.1, toggle_snapshot)
	_expect(not toggle_snapshot.is_pressed(&"turn_mode") and toggle_snapshot.is_just_released(&"turn_mode"), "turning toggle mode off lets go of a switch that was on, with a release edge")


func _check_a_held_key_needs_a_fresh_press_in_a_new_room() -> void:
	var room_poller := InputPoller.new()
	var room_snapshot := InputSnapshot.new()
	await process_frame
	Input.action_press(&"move_right")
	room_poller.poll(0.1, room_snapshot)
	_expect(room_snapshot.is_pressed(&"move_right"), "setup: the walking key is down and published")

	room_poller.require_fresh_press()
	await process_frame
	room_poller.poll(0.1, room_snapshot)
	_expect(not room_snapshot.is_pressed(&"move_right") and room_snapshot.is_just_released(&"move_right"), "a new room begins with the key still down: it is published released, with the release edge")
	for _poll in range(5):
		await process_frame
		room_poller.poll(0.1, room_snapshot)
	_expect(not room_snapshot.is_pressed(&"move_right") and not room_snapshot.is_just_pressed(&"move_right") and room_snapshot.held_time_of(&"move_right") == 0.0, "and it stays released, with no held time, however long the key stays down")

	# Another direction pressed now is a fresh press and works at once, the held one still waits.
	Input.action_press(&"move_up")
	room_poller.poll(0.1, room_snapshot)
	_expect(room_snapshot.is_pressed(&"move_up") and room_snapshot.is_just_pressed(&"move_up") and not room_snapshot.is_pressed(&"move_right"), "a different key pressed in the new room counts at once, the held one still does not")
	Input.action_release(&"move_up")

	# Letting go ends the wait: the next press of the same key is a fresh press.
	Input.action_release(&"move_right")
	await process_frame
	room_poller.poll(0.1, room_snapshot)
	_expect(not room_snapshot.is_pressed(&"move_right"), "letting go publishes it released")
	await process_frame
	Input.action_press(&"move_right")
	room_poller.poll(0.1, room_snapshot)
	_expect(room_snapshot.is_pressed(&"move_right") and room_snapshot.is_just_pressed(&"move_right"), "the next press of the same key is a fresh press and counts, with its press edge")
	Input.action_release(&"move_right")
	await process_frame

	# A key that was NOT down when the room began is not held back, and the call alone changes nothing.
	room_poller.require_fresh_press()
	await process_frame
	Input.action_press(&"move_left")
	room_poller.poll(0.1, room_snapshot)
	_expect(room_snapshot.is_pressed(&"move_left") and room_snapshot.is_just_pressed(&"move_left"), "a key that went down after the room began is a fresh press from the start")
	Input.action_release(&"move_left")
	await process_frame

	# The stick is a control too: pushed through the door, it has to be let go of (returned to the centre) first.
	_stick(1.0, 0.0)
	room_poller.poll(0.1, room_snapshot)
	room_poller.require_fresh_press()
	await process_frame
	room_poller.poll(0.1, room_snapshot)
	_expect(not room_snapshot.is_pressed(&"move_right"), "the left stick held through the door is held back like a key")
	_stick(0.0, 0.0)
	await process_frame
	room_poller.poll(0.1, room_snapshot)
	_stick(1.0, 0.0)
	room_poller.poll(0.1, room_snapshot)
	_expect(room_snapshot.is_pressed(&"move_right") and room_snapshot.is_just_pressed(&"move_right"), "and pushed again after the centre, it counts")
	_stick(0.0, 0.0)
	await process_frame


## Pushes the left stick to (x, y) as a gamepad would.
func _stick(x_value: float, y_value: float) -> void:
	for pair: Array in [[JOY_AXIS_LEFT_X, x_value], [JOY_AXIS_LEFT_Y, y_value]]:
		var motion := InputEventJoypadMotion.new()
		motion.axis = pair[0]
		motion.axis_value = pair[1]
		Input.parse_input_event(motion)
	Input.flush_buffered_events()


func _release_everything() -> void:
	_stick(0.0, 0.0)
	for action in InputMap.get_actions():
		Input.action_release(action)
