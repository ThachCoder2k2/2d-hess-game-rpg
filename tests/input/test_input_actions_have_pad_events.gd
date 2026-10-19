extends UnboundTest

## The InputMap of docs/game-base-plan.md 9.4 (M4 step 2, D-18): every action the game uses has a keyboard event AND a
## gamepad event, so the whole game is playable on either, and the actions are the ones the plan names. An unused or
## keyboard-only action is listed here WITH THE REASON; an action in the InputMap that this test does not know fails the
## suite, so a new action cannot slip in without a pad binding or a reason.
##
## Also pinned: R is Call child and nothing restarts the room (restart_room is gone, it is a pause menu command),
## the old skill_1 is skill_slot_1, the left stick and the d-pad both move with a dead zone of 0.35, the menu
## navigation actions the pause menu and the title use (ui_accept, ui_cancel, ui_up/down/left/right) answer a pad, and
## the shell keys (pause, the Book, F3, F11) are InputMap actions and not raw key polls.

## Actions that need both a keyboard and a gamepad event. action -> what it is.
const PLAYED_ACTIONS := {
	&"move_up": "step up",
	&"move_down": "step down",
	&"move_left": "step left",
	&"move_right": "step right",
	&"turn_mode": "turn in place (hold or toggle)",
	&"attack": "Strike",
	&"skill_slot_1": "the Pencil",
	&"skill_slot_2": "Rule Step",
	&"guard": "Guard (hold or toggle)",
	&"call_child": "call the child (D-18: R)",
	&"help_next": "select the next help",
	&"focus": "Focus (hold or toggle)",
	&"interact": "interact",
	&"rule_book_toggle": "open and close the Book",
	&"pause": "pause",
	&"dialogue_advance": "advance dialogue",
}

## Actions that are declared with a keyboard event only, each with the reason. A pad event is not required of them.
const KEYBOARD_ONLY_ACTIONS := {
	&"skill_slot_3": "declared and unused: the HUD hides empty slots (9.4: pad 'unbound')",
	&"skill_slot_4": "declared and unused: the HUD hides empty slots (9.4: pad 'unbound')",
	&"free_step": "the Free Step modifier: its pad input is the stick's diagonal cone, worked out by the poller when the verb exists (9.4), not an InputMap event",
	&"debug_view_toggle": "F3, a developer's switch: 9.4 gives it no pad input",
	&"fullscreen_toggle": "F11: 9.4 gives it no pad input; Settings has a Fullscreen option for a player on a pad",
}

## The engine's own menu navigation, which the title, the pause menu and the settings screen are driven by.
const MENU_ACTIONS: Array[StringName] = [&"ui_accept", &"ui_cancel", &"ui_up", &"ui_down", &"ui_left", &"ui_right"]

## Actions that existed before M4 and must be gone. The old skill action is spelled in two parts on purpose:
## tools/move_res.py --rename-action rewrites a quoted "skill_1" wherever it finds one, this line included.
const OLD_SKILL_ACTION := "skill_" + "1"
const REMOVED_ACTIONS: Array[StringName] = [&"restart_room", StringName(OLD_SKILL_ACTION)]


func _init() -> void:
	suite_title = "INPUT ACTIONS HAVE PAD EVENTS TEST"
	_check_every_played_action_has_both()
	_check_the_rest_is_listed_with_a_reason()
	_check_the_menu_navigation_answers_a_pad()
	_check_the_named_bindings()
	_check_the_stick_and_the_dpad_move()
	finish()


func _check_every_played_action_has_both() -> void:
	for action: StringName in PLAYED_ACTIONS:
		if not _expect(InputMap.has_action(action), "%s (%s) is an InputMap action" % [action, PLAYED_ACTIONS[action]]):
			continue
		_expect(_has_event_of(action, InputEventKey), "%s has a keyboard event" % action)
		_expect(_has_pad_event(action), "%s has a gamepad event" % action)


func _check_the_rest_is_listed_with_a_reason() -> void:
	for action: StringName in KEYBOARD_ONLY_ACTIONS:
		_expect(InputMap.has_action(action) and _has_event_of(action, InputEventKey), "%s is declared, with a keyboard event (%s)" % [action, KEYBOARD_ONLY_ACTIONS[action]])
	var unknown: Array[String] = []
	for action in InputMap.get_actions():
		if String(action).begins_with(InputPoller.ENGINE_ACTION_PREFIX):
			continue
		if not PLAYED_ACTIONS.has(action) and not KEYBOARD_ONLY_ACTIONS.has(action):
			unknown.append(String(action))
	_expect(unknown.is_empty(), "every InputMap action is either played with a pad binding or listed with a reason (unknown: %s)" % ", ".join(PackedStringArray(unknown)))
	for removed in REMOVED_ACTIONS:
		_expect(not InputMap.has_action(removed), "%s is gone from the InputMap (D-18 and the skill_slot rename)" % removed)


func _check_the_menu_navigation_answers_a_pad() -> void:
	for action in MENU_ACTIONS:
		_expect(InputMap.has_action(action) and _has_pad_event(action), "%s, which the menus are driven by, answers a gamepad" % action)


func _check_the_named_bindings() -> void:
	_expect(_binds_key(&"call_child", KEY_R), "R is Call child")
	var actions_on_r: Array[String] = []
	for action in InputMap.get_actions():
		if _binds_key(action, KEY_R):
			actions_on_r.append(String(action))
	_expect(actions_on_r == ["call_child"], "R is bound to Call child and to nothing else (found: %s)" % ", ".join(PackedStringArray(actions_on_r)))
	_expect(_binds_key(&"skill_slot_1", KEY_Q) and _binds_key(&"skill_slot_2", KEY_F) and _binds_key(&"skill_slot_3", KEY_C) and _binds_key(&"skill_slot_4", KEY_V), "the four skill slots are Q, F, C and V")
	_expect(_binds_key(&"attack", KEY_SPACE) and _binds_key(&"attack", KEY_K), "Strike is Space and K")
	_expect(_binds_key(&"pause", KEY_ESCAPE) and _binds_button(&"pause", JOY_BUTTON_START), "Pause is Esc and Start")
	_expect(_binds_key(&"rule_book_toggle", KEY_B) and _binds_button(&"rule_book_toggle", JOY_BUTTON_LEFT_STICK), "the Book is B and L3")
	_expect(_binds_button(&"attack", JOY_BUTTON_A) and _binds_button(&"skill_slot_1", JOY_BUTTON_X) and _binds_button(&"skill_slot_2", JOY_BUTTON_B) and _binds_button(&"interact", JOY_BUTTON_Y), "on the pad A strikes, X is the Pencil, B is Rule Step and Y interacts")
	_expect(_binds_button(&"call_child", JOY_BUTTON_RIGHT_SHOULDER) and _binds_button(&"turn_mode", JOY_BUTTON_LEFT_SHOULDER) and _binds_button(&"help_next", JOY_BUTTON_RIGHT_STICK), "RB calls the child, LB turns in place and R3 selects the next help")
	_expect(_binds_axis(&"guard", JOY_AXIS_TRIGGER_LEFT) and _binds_axis(&"focus", JOY_AXIS_TRIGGER_RIGHT), "LT is Guard and RT is Focus")
	_expect(_binds_key(&"dialogue_advance", KEY_SPACE) and _binds_key(&"dialogue_advance", KEY_ENTER) and _binds_key(&"dialogue_advance", KEY_E) and _binds_button(&"dialogue_advance", JOY_BUTTON_A), "dialogue advances on Space, Enter, E and A")


func _check_the_stick_and_the_dpad_move() -> void:
	var directions := {
		&"move_up": [JOY_AXIS_LEFT_Y, -1.0, JOY_BUTTON_DPAD_UP],
		&"move_down": [JOY_AXIS_LEFT_Y, 1.0, JOY_BUTTON_DPAD_DOWN],
		&"move_left": [JOY_AXIS_LEFT_X, -1.0, JOY_BUTTON_DPAD_LEFT],
		&"move_right": [JOY_AXIS_LEFT_X, 1.0, JOY_BUTTON_DPAD_RIGHT],
	}
	for action: StringName in directions:
		var expected: Array = directions[action]
		_expect(_binds_stick(action, expected[0], expected[1]) and _binds_button(action, expected[2]), "%s answers the left stick and the d-pad" % action)
		_expect(is_equal_approx(InputMap.action_get_deadzone(action), 0.35), "%s has the stick's dead zone of 0.35" % action)


func _has_event_of(action: StringName, event_class: Variant) -> bool:
	for event in InputMap.action_get_events(action):
		if is_instance_of(event, event_class):
			return true
	return false


func _has_pad_event(action: StringName) -> bool:
	return _has_event_of(action, InputEventJoypadButton) or _has_event_of(action, InputEventJoypadMotion)


func _binds_key(action: StringName, keycode: Key) -> bool:
	if not InputMap.has_action(action):
		return false
	for event in InputMap.action_get_events(action):
		var key_event := event as InputEventKey
		if key_event != null and (key_event.physical_keycode == keycode or key_event.keycode == keycode):
			return true
	return false


func _binds_button(action: StringName, button: JoyButton) -> bool:
	if not InputMap.has_action(action):
		return false
	for event in InputMap.action_get_events(action):
		var button_event := event as InputEventJoypadButton
		if button_event != null and button_event.button_index == button:
			return true
	return false


func _binds_axis(action: StringName, axis: JoyAxis) -> bool:
	if not InputMap.has_action(action):
		return false
	for event in InputMap.action_get_events(action):
		var motion_event := event as InputEventJoypadMotion
		if motion_event != null and motion_event.axis == axis:
			return true
	return false


func _binds_stick(action: StringName, axis: JoyAxis, direction: float) -> bool:
	if not InputMap.has_action(action):
		return false
	for event in InputMap.action_get_events(action):
		var motion_event := event as InputEventJoypadMotion
		if motion_event != null and motion_event.axis == axis and signf(motion_event.axis_value) == signf(direction):
			return true
	return false
