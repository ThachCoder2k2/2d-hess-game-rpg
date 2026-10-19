extends UnboundTest

## The input seam (docs/game-base-plan.md 9.4, 14.1, 15 M3a): the shell's InputPoller copies the
## controls into world.input_snapshot once per frame, and PlayerInputSystem reads ONLY that snapshot.
## So headless tests can finally drive the hero's controls: every scenario below injects snapshots
## and ticks the system, with no keyboard in the room.
##
## What is held here, all of it the behaviour the game had when the system called Input itself
## (the bridge suites and a 7,000-tick random-play comparison against the old system proved it):
##   the BUFFER   a step pressed while another is under way waits, and is taken the moment the
##                hero is free. It never expires today; the expiry is M7b (Tuning.input_buffer_window).
##   the CHORD    turn_mode held plus a direction turns the hero without stepping.
##   the TAP WINDOW  a tap shorter than held_repeat_delay is exactly one step; a key held past it
##                repeats a step every held_repeat_delay.
## and then the poller itself: that it copies the controls faithfully, and that nothing else does.

## The hero's PlayerInput.held_repeat_delay, read from the component so the number lives in one place.
var held_repeat_delay := EcsComponents.PlayerInput.new().held_repeat_delay


## A world with PlayerInputSystem and one controllable hero, plus handles on the hero's components.
class Rig:
	var world: EcsWorld
	var hero := 0
	var tag: EcsComponents.PlayerTag
	var input_memory: EcsComponents.PlayerInput
	var move: EcsComponents.MoveState
	var move_intent: EcsComponents.MoveIntent
	var facing: EcsComponents.Facing
	var attack_intent: EcsComponents.AttackIntent


func _init() -> void:
	suite_title = "INPUT SNAPSHOT TEST"
	_check_a_tap_is_one_step_and_a_hold_repeats()
	_check_the_buffer()
	_check_the_chord()
	_check_two_directions_at_once_and_the_attack_keys()
	_check_a_hero_without_control_ignores_the_controls()
	_check_the_system_reads_the_snapshot_and_not_the_keyboard()
	_check_the_snapshot_helpers()
	await _check_the_poller_copies_the_controls()
	await _check_the_poller_publishes_the_shell_keys()
	_check_the_poller_outlives_a_world()
	finish()


func _make_rig() -> Rig:
	var rig := Rig.new()
	rig.world = EcsWorld.new()
	rig.world.manual_tick = true
	root.add_child(rig.world)
	rig.world.add_system(PlayerInputSystem.new())
	rig.hero = rig.world.create_entity()
	rig.tag = rig.world.add_component(rig.hero, EcsComponents.PLAYER_TAG, EcsComponents.PlayerTag.new())
	rig.input_memory = rig.world.add_component(rig.hero, EcsComponents.PLAYER_INPUT, EcsComponents.PlayerInput.new())
	rig.move = rig.world.add_component(rig.hero, EcsComponents.MOVE_STATE, EcsComponents.MoveState.new())
	rig.move_intent = rig.world.add_component(rig.hero, EcsComponents.MOVE_INTENT, EcsComponents.MoveIntent.new())
	rig.facing = rig.world.add_component(rig.hero, EcsComponents.FACING, EcsComponents.Facing.new())
	rig.attack_intent = rig.world.add_component(rig.hero, EcsComponents.ATTACK_INTENT, EcsComponents.AttackIntent.new())
	return rig


## Ticks the world with a snapshot in which every action of `pressed` is down and every action of
## `just_pressed` went down this tick (it counts as down too).
func _tick_with(rig: Rig, delta: float, pressed: Array[StringName], just_pressed: Array[StringName] = []) -> void:
	var snapshot := InputSnapshot.new()
	for action in pressed:
		snapshot.set_action(action, true, action in just_pressed)
	for action in just_pressed:
		if action not in pressed:
			snapshot.set_action(action, true, true)
	rig.world.input_snapshot = snapshot
	rig.world.tick(delta)


## The step the system asked for since the last call (what MovementSystem would take), and clears it.
func _take_step_request(rig: Rig) -> Vector2i:
	var requested := rig.move_intent.direction
	rig.move_intent.direction = Vector2i.ZERO
	return requested


func _free(rig: Rig) -> void:
	rig.world.queue_free()


func _check_a_tap_is_one_step_and_a_hold_repeats() -> void:
	var tapped := _make_rig()
	_tick_with(tapped, 0.016, [&"move_right"], [&"move_right"])
	_expect(_take_step_request(tapped) == Vector2i.RIGHT, "a fresh press of a direction while the hero is free asks for that step at once")
	_expect(tapped.input_memory.last_held_direction == Vector2i.RIGHT and is_zero_approx(tapped.input_memory.hold_time), "the press starts the hold clock at zero")
	# The tap ends before the repeat delay: released ticks add nothing.
	for _tick in range(30):
		_tick_with(tapped, 0.016, [])
	_expect(_take_step_request(tapped) == Vector2i.ZERO, "a tap shorter than the repeat delay is exactly one step: the released key asks for nothing more")
	_expect(tapped.input_memory.last_held_direction == Vector2i.ZERO and is_zero_approx(tapped.input_memory.hold_time), "releasing the key clears the hold memory")
	_free(tapped)

	var held := _make_rig()
	_tick_with(held, 0.016, [&"move_up"], [&"move_up"])
	_expect(_take_step_request(held) == Vector2i.UP, "(hold) the press itself steps")
	# Held across ticks: the clock runs on delta and the repeat fires when it reaches the delay.
	var steps_asked: Array[Vector2i] = []
	var elapsed := 0.0
	var first_repeat_at := -1.0
	for _tick in range(40):
		_tick_with(held, 0.05, [&"move_up"])
		elapsed += 0.05
		var asked := _take_step_request(held)
		if asked != Vector2i.ZERO:
			steps_asked.append(asked)
			if first_repeat_at < 0.0:
				first_repeat_at = elapsed
	_expect(first_repeat_at >= held_repeat_delay - 0.0001 and first_repeat_at < held_repeat_delay + 0.05 + 0.0001, "a key held past the repeat delay (%.2f s) asks for a repeat step on the first tick that reaches it (at %.2f s)" % [held_repeat_delay, first_repeat_at])
	_expect(steps_asked.size() == 8 and steps_asked.all(func(step: Vector2i) -> bool: return step == Vector2i.UP), "held for 2 s of 0.05 s ticks it repeats on every fifth tick (the first that reaches the delay), 8 steps up (got %d)" % steps_asked.size())
	_free(held)

	# A repeat is only asked for when the hero is free; the clock keeps running while a step is under way.
	var busy := _make_rig()
	_tick_with(busy, 0.016, [&"move_left"], [&"move_left"])
	_take_step_request(busy)
	busy.move.moving = true
	for _tick in range(10):
		_tick_with(busy, 0.05, [&"move_left"])
	_expect(_take_step_request(busy) == Vector2i.ZERO, "a held key does not repeat while the hero is mid-step")
	busy.move.moving = false
	_tick_with(busy, 0.016, [&"move_left"])
	_expect(_take_step_request(busy) == Vector2i.LEFT, "the repeat that came due during the step fires on the first free tick")
	_free(busy)

	# Changing the held direction restarts the clock instead of repeating.
	var changed := _make_rig()
	_tick_with(changed, 0.016, [&"move_up"], [&"move_up"])
	_take_step_request(changed)
	for _tick in range(3):
		_tick_with(changed, 0.05, [&"move_up"])
	_take_step_request(changed)
	_tick_with(changed, 0.05, [&"move_down"])
	_expect(changed.input_memory.last_held_direction == Vector2i.DOWN and is_zero_approx(changed.input_memory.hold_time), "holding another direction restarts the hold clock on it")
	_expect(_take_step_request(changed) == Vector2i.ZERO, "and does not repeat a step yet")
	_free(changed)


func _check_the_buffer() -> void:
	var rig := _make_rig()
	rig.move.moving = true
	_tick_with(rig, 0.016, [&"move_right"], [&"move_right"])
	_expect(_take_step_request(rig) == Vector2i.ZERO and rig.input_memory.buffered_direction == Vector2i.RIGHT, "a step pressed while another is under way is buffered, not requested")
	_tick_with(rig, 0.016, [&"move_up"], [&"move_up"])
	_expect(rig.input_memory.buffered_direction == Vector2i.UP, "a later press replaces the buffered one: the newest wins")
	for _tick in range(2):
		_tick_with(rig, 0.016, [])
	_expect(rig.input_memory.buffered_direction == Vector2i.UP and _take_step_request(rig) == Vector2i.ZERO, "the buffered step waits while the hero is still moving")
	rig.move.moving = false
	_tick_with(rig, 0.016, [])
	_expect(_take_step_request(rig) == Vector2i.UP and rig.input_memory.buffered_direction == Vector2i.ZERO, "the moment the hero is free the buffered step is requested, and the buffer is emptied")
	_tick_with(rig, 0.016, [])
	_expect(_take_step_request(rig) == Vector2i.ZERO, "a buffered step is taken once")
	_free(rig)

	# It never expires today: five seconds of waiting changes nothing (M7b gives it a window).
	var patient := _make_rig()
	_expect(is_zero_approx(patient.world.tuning.input_buffer_window), "setup: the input buffer window is 0.0, meaning the buffer never expires")
	patient.move.moving = true
	_tick_with(patient, 0.016, [&"move_left"], [&"move_left"])
	for _tick in range(100):
		_tick_with(patient, 0.05, [])
	patient.move.moving = false
	_tick_with(patient, 0.016, [])
	_expect(_take_step_request(patient) == Vector2i.LEFT, "a step buffered five seconds ago is still taken: the expiry is a behaviour change that waits for M7b")
	_free(patient)

	# A press while free is not buffered, and the buffer does not outrank a fresh press.
	var fresh := _make_rig()
	fresh.input_memory.buffered_direction = Vector2i.LEFT
	_tick_with(fresh, 0.016, [&"move_down"], [&"move_down"])
	_expect(_take_step_request(fresh) == Vector2i.DOWN and fresh.input_memory.buffered_direction == Vector2i.LEFT, "a fresh press wins the tick it arrives on; the older buffered step is kept for the next free tick")
	_free(fresh)


func _check_the_chord() -> void:
	var rig := _make_rig()
	_tick_with(rig, 0.016, [&"turn_mode", &"move_left"], [&"move_left"])
	_expect(rig.facing.direction == Vector2i.LEFT and _take_step_request(rig) == Vector2i.ZERO, "turn_mode plus a fresh direction turns the hero and takes no step")
	_tick_with(rig, 0.016, [&"turn_mode", &"move_down"], [&"move_down"])
	_expect(rig.facing.direction == Vector2i.DOWN, "and turns again for each new press while turn_mode stays down")
	rig.move.moving = true
	_tick_with(rig, 0.016, [&"turn_mode", &"move_right"], [&"move_right"])
	_expect(rig.facing.direction == Vector2i.RIGHT and rig.input_memory.buffered_direction == Vector2i.ZERO, "the chord turns even while a step is under way, and buffers nothing")
	rig.move.moving = false
	# A direction held under turn_mode never repeats a step, and the clock stays at zero.
	for _tick in range(20):
		_tick_with(rig, 0.05, [&"turn_mode", &"move_up"])
	_expect(_take_step_request(rig) == Vector2i.ZERO and is_zero_approx(rig.input_memory.hold_time) and rig.input_memory.last_held_direction == Vector2i.ZERO, "a direction held under turn_mode does not repeat and does not run the hold clock")
	# Letting go of turn_mode while the direction stays down starts a hold from zero.
	_tick_with(rig, 0.05, [&"move_up"])
	_expect(rig.input_memory.last_held_direction == Vector2i.UP and is_zero_approx(rig.input_memory.hold_time) and _take_step_request(rig) == Vector2i.ZERO, "releasing turn_mode over a held direction starts a fresh hold, not an instant step")
	# Without turn_mode the same press steps and leaves the facing alone (the step system turns it).
	var plain := _make_rig()
	_tick_with(plain, 0.016, [&"move_left"], [&"move_left"])
	_expect(_take_step_request(plain) == Vector2i.LEFT and plain.facing.direction == Vector2i.UP, "without turn_mode the press steps and the input system leaves the facing alone")
	_free(plain)
	_free(rig)


func _check_two_directions_at_once_and_the_attack_keys() -> void:
	var rig := _make_rig()
	_tick_with(rig, 0.016, [&"move_right", &"move_up"], [&"move_right", &"move_up"])
	_expect(_take_step_request(rig) == Vector2i.UP, "two fresh directions on one tick: the first of up, down, left, right wins")
	_free(rig)

	var attacker := _make_rig()
	_tick_with(attacker, 0.016, [&"attack"], [&"attack"])
	_expect(attacker.attack_intent.kind == &"sword", "a fresh attack press is a sword intent")
	attacker.attack_intent.kind = &"none"
	_tick_with(attacker, 0.016, [&"skill_1"], [&"skill_1"])
	_expect(attacker.attack_intent.kind == &"skill", "a fresh skill_1 press is a skill intent")
	attacker.attack_intent.kind = &"none"
	_tick_with(attacker, 0.016, [&"attack", &"skill_1"], [&"attack", &"skill_1"])
	_expect(attacker.attack_intent.kind == &"sword", "attack and skill_1 on the same tick: the sword wins")
	attacker.attack_intent.kind = &"none"
	_tick_with(attacker, 0.016, [&"attack", &"skill_1"])
	_expect(attacker.attack_intent.kind == &"none", "a key that is merely held, not freshly pressed, makes no attack")
	_free(attacker)


func _check_a_hero_without_control_ignores_the_controls() -> void:
	var rig := _make_rig()
	rig.tag.control_enabled = false
	_tick_with(rig, 0.016, [&"move_up", &"attack", &"turn_mode"], [&"move_up", &"attack"])
	_expect(_take_step_request(rig) == Vector2i.ZERO and rig.attack_intent.kind == &"none" and rig.input_memory.buffered_direction == Vector2i.ZERO, "a hero whose control is off (the Book is open, the room ended) takes no step, no attack and buffers nothing")
	rig.tag.control_enabled = true
	_tick_with(rig, 0.016, [&"move_up"], [&"move_up"])
	_expect(_take_step_request(rig) == Vector2i.UP, "and obeys again the tick control comes back")
	_free(rig)


func _check_the_system_reads_the_snapshot_and_not_the_keyboard() -> void:
	var rig := _make_rig()
	Input.action_press(&"move_up")
	Input.action_press(&"attack")
	_tick_with(rig, 0.016, [])
	_expect(_take_step_request(rig) == Vector2i.ZERO and rig.attack_intent.kind == &"none", "a key that is down on the keyboard but not in the snapshot does nothing: the system never reads Input")
	Input.action_release(&"move_up")
	Input.action_release(&"attack")
	_free(rig)

	var untouched := _make_rig()
	untouched.world.tick(0.016)
	_expect(_take_step_request(untouched) == Vector2i.ZERO, "a world nobody polled has an empty snapshot and an idle hero")
	_free(untouched)


func _check_the_snapshot_helpers() -> void:
	var snapshot := InputSnapshot.new()
	var state := snapshot.set_action(&"attack", true, true, false, 0.5, 777)
	_expect(snapshot.state_of(&"attack") == state and snapshot.is_pressed(&"attack") and snapshot.is_just_pressed(&"attack") and not snapshot.is_just_released(&"attack"), "set_action stores the state it builds and returns it")
	_expect(is_equal_approx(snapshot.held_time_of(&"attack"), 0.5) and snapshot.state_of(&"attack").timestamp_msec == 777, "set_action carries the held time and the press timestamp")
	snapshot.set_action(&"attack", false, false, true)
	_expect(not snapshot.is_pressed(&"attack") and snapshot.is_just_released(&"attack"), "set_action again replaces the state: released this tick")


func _check_the_poller_copies_the_controls() -> void:
	# The engine counts frames from the second one; the "just pressed" flag is judged against that count.
	await process_frame
	await process_frame
	var poller := InputPoller.new()
	var snapshot := InputSnapshot.new()
	poller.poll(0.016, snapshot)
	_expect(not snapshot.is_pressed(&"move_up") and not snapshot.is_pressed(&"attack"), "with nothing pressed the poller publishes every action as released")
	_expect(&"move_up" in poller.action_names and &"restart_room" in poller.action_names and &"turn_mode" in poller.action_names, "the poller covers the project's own InputMap actions (move_*, attack, skill_1, turn_mode, restart_room)")
	_expect(not poller.action_names.any(func(action: StringName) -> bool: return String(action).begins_with("ui_")), "and leaves out the engine's own ui_ actions")

	Input.action_press(&"move_up")
	poller.poll(0.016, snapshot)
	var pressed_state := snapshot.state_of(&"move_up")
	_expect(pressed_state.pressed and pressed_state.just_pressed and not pressed_state.just_released, "a key pressed this frame is pressed and just pressed")
	_expect(is_zero_approx(pressed_state.held_time), "the poll that sees the press reads a held time of 0.0")
	_expect(pressed_state.timestamp_msec >= 0 and absi(pressed_state.timestamp_msec - Time.get_ticks_msec()) < 2000, "and stamps the engine time of the press")
	var stamped := pressed_state.timestamp_msec

	await process_frame
	poller.poll(0.5, snapshot)
	_expect(snapshot.is_pressed(&"move_up") and not snapshot.is_just_pressed(&"move_up"), "a frame later the key is still pressed and no longer just pressed")
	_expect(is_equal_approx(snapshot.held_time_of(&"move_up"), 0.5) and snapshot.state_of(&"move_up").timestamp_msec == stamped, "the held time grows by the delta of each poll and the press time stays")
	poller.poll(0.25, snapshot)
	_expect(is_equal_approx(snapshot.held_time_of(&"move_up"), 0.75), "held time accumulates poll after poll (0.5 + 0.25)")

	Input.action_release(&"move_up")
	poller.poll(0.016, snapshot)
	_expect(not snapshot.is_pressed(&"move_up") and snapshot.is_just_released(&"move_up") and is_zero_approx(snapshot.held_time_of(&"move_up")), "a key released this frame is released, just released, and held for 0.0")
	await process_frame
	poller.poll(0.016, snapshot)
	_expect(not snapshot.is_pressed(&"move_up") and not snapshot.is_just_released(&"move_up"), "just released lasts one frame")

	# Several polls inside one engine frame (the way the bridge suites pump): the engine's flags repeat.
	Input.action_press(&"attack")
	poller.poll(0.05, snapshot)
	var state_after_first_poll := snapshot.state_of(&"attack")
	poller.poll(0.05, snapshot)
	_expect(snapshot.is_just_pressed(&"attack") and snapshot.is_pressed(&"attack"), "inside one engine frame every poll reports the press as fresh, exactly as the system saw it when it asked Input itself")
	_expect(snapshot.state_of(&"attack") == state_after_first_poll, "the snapshot holds the poller's own state object, reused poll after poll: a poll allocates nothing after the first")
	Input.action_release(&"attack")
	await process_frame


func _check_the_poller_publishes_the_shell_keys() -> void:
	var poller := InputPoller.new()
	var snapshot := InputSnapshot.new()
	await process_frame
	poller.poll(0.016, snapshot)
	for shell_action: StringName in InputPoller.RAW_KEY_BY_ACTION:
		_expect(snapshot.state_by_action.has(shell_action) and not snapshot.is_pressed(shell_action), "%s is published (released) next to the real actions" % shell_action)

	_send_key(KEY_B, true)
	poller.poll(0.016, snapshot)
	_expect(snapshot.is_pressed(&"rule_book_toggle") and snapshot.is_just_pressed(&"rule_book_toggle"), "a raw key is just pressed on the poll that first sees it down")
	poller.poll(0.016, snapshot)
	_expect(snapshot.is_pressed(&"rule_book_toggle") and not snapshot.is_just_pressed(&"rule_book_toggle"), "and only on that poll: the engine has no edge for a raw key, so the poller works it out")
	_expect(not snapshot.is_pressed(&"debug_view_toggle") and not snapshot.is_pressed(&"fullscreen_toggle"), "the other shell keys are unaffected")
	_send_key(KEY_B, false)
	poller.poll(0.016, snapshot)
	_expect(not snapshot.is_pressed(&"rule_book_toggle") and snapshot.is_just_released(&"rule_book_toggle"), "releasing the key is a just-released edge")
	poller.poll(0.016, snapshot)
	_expect(not snapshot.is_just_released(&"rule_book_toggle"), "which also lasts one poll")


func _check_the_poller_outlives_a_world() -> void:
	# The shell builds a new world, with a new empty snapshot, for every room; the poller carries on.
	var poller := InputPoller.new()
	poller.action_names = [&"move_up"]
	var first_snapshot := InputSnapshot.new()
	Input.action_press(&"move_up")
	poller.poll(0.1, first_snapshot)
	poller.poll(0.1, first_snapshot)
	var second_snapshot := InputSnapshot.new()
	_expect(second_snapshot.state_by_action.is_empty(), "a new world's snapshot starts empty")
	poller.poll(0.1, second_snapshot)
	_expect(second_snapshot.is_pressed(&"move_up") and is_equal_approx(second_snapshot.held_time_of(&"move_up"), 0.2), "after a room change the poller fills the new snapshot and the held time carries on (0.1 + 0.1)")
	Input.action_release(&"move_up")
	_expect(poller.action_names == [&"move_up"], "a poller given a fixed set of actions polls only those")


func _send_key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
