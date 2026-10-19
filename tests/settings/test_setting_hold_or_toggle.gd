extends UnboundTest

## Hold-or-toggle (docs/game-base-plan.md 5.8, 9.4): for Guard, Focus and turn mode a player who cannot hold a key can have a
## press switch the action on and off instead. The setting reaches the InputPoller of the game scene (the one reader of
## the controls), which publishes the action as a switch to the world's InputSnapshot. Driven with the real keys
## (G, Left Ctrl, Shift) sent as the OS would send them, and the poller polled by hand:
##   - off (the standard): the action is down while the key is, as it always was;
##   - on: a press turns it on, letting go leaves it on, the next press turns it off;
##   - each of the three settings moves its own action and no other;
##   - turning the setting off while the switch is on lets go of it, so the action is not stuck down.
## The rescue hold the plan also lists belongs to the rescue (M6) and has no setting yet.

const SettingsSupport := preload("res://tests/settings/settings_support.gd")
const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "setting_hold_or_toggle"
const DELTA := 0.016

## setting -> [the action, the key that presses it]
const CASES := [
	[GameSettings.TOGGLE_GUARD, &"guard", KEY_G],
	[GameSettings.TOGGLE_FOCUS, &"focus", KEY_CTRL],
	[GameSettings.TOGGLE_TURN_MODE, &"turn_mode", KEY_SHIFT],
]


func _init() -> void:
	suite_title = "SETTING HOLD OR TOGGLE TEST"
	watchdog_seconds = 40.0
	call_deferred("_run")


func _run() -> void:
	var booted := await SettingsSupport.boot_game(self, SUITE_NAME)
	var game: GameRoot = booted["game"]
	var app: AppRoot = booted["app"]
	if not _expect(game != null, "setup: the game is up in T4"):
		Support.end_suite(self, booted["save_service"])
		return
	_expect(SettingsBridge.TOGGLED_ACTION_BY_SETTING.size() == CASES.size(), "setup: three settings are wired to three actions")
	for case in CASES:
		await _check_one(game, app, case[0], case[1], case[2])
	await _check_letting_go_of_a_switch(game, app)
	Support.end_suite(self, booted["save_service"])


func _check_one(game: GameRoot, app: AppRoot, setting: StringName, action: StringName, key: Key) -> void:
	var poller := game.input_poller
	var snapshot := Support.ecs_of(game).input_snapshot
	_expect(not poller.toggled_actions.has(action), "%s: held by default" % action)
	await _press_and_release(poller, snapshot, key)
	_expect(not snapshot.is_pressed(action), "%s, held: letting go of the key lets go of the action" % action)

	app.settings.set_value(setting, true)
	_expect(poller.toggled_actions.has(action), "%s: the setting reaches the poller" % action)
	for other_case in CASES:
		if other_case[1] != action:
			_expect(not poller.toggled_actions.has(other_case[1]), "and only that action: %s is not a switch" % other_case[1])
	Support.send_key(key, true)
	poller.poll(DELTA, snapshot)
	_expect(snapshot.is_pressed(action) and snapshot.is_just_pressed(action), "%s, toggled: a press turns it on" % action)
	Support.send_key(key, false)
	poller.poll(DELTA, snapshot)
	_expect(snapshot.is_pressed(action), "letting go leaves it on")
	await process_frame
	Support.send_key(key, true)
	poller.poll(DELTA, snapshot)
	_expect(not snapshot.is_pressed(action) and snapshot.is_just_released(action), "the next press turns it off")
	Support.send_key(key, false)
	poller.poll(DELTA, snapshot)
	_expect(not snapshot.is_pressed(action), "and letting go leaves it off")

	app.settings.set_value(setting, false)
	_expect(not poller.toggled_actions.has(action), "%s: the setting off makes it a held key again" % action)
	await _press_and_release(poller, snapshot, key)
	_expect(not snapshot.is_pressed(action), "%s is down only while the key is" % action)


func _check_letting_go_of_a_switch(game: GameRoot, app: AppRoot) -> void:
	var poller := game.input_poller
	var snapshot := Support.ecs_of(game).input_snapshot
	app.settings.set_value(GameSettings.TOGGLE_GUARD, true)
	Support.send_key(KEY_G, true)
	poller.poll(DELTA, snapshot)
	Support.send_key(KEY_G, false)
	poller.poll(DELTA, snapshot)
	_expect(snapshot.is_pressed(&"guard"), "setup: Guard is switched on")
	app.settings.set_value(GameSettings.TOGGLE_GUARD, false)
	poller.poll(DELTA, snapshot)
	_expect(not snapshot.is_pressed(&"guard") and snapshot.is_just_released(&"guard"), "turning the setting off with the switch on lets go of Guard: it is not stuck down")


## The key goes down for one poll and up for the next, with a frame between, as a held key would.
func _press_and_release(poller: InputPoller, snapshot: InputSnapshot, key: Key) -> void:
	await process_frame
	Support.send_key(key, true)
	poller.poll(DELTA, snapshot)
	Support.send_key(key, false)
	poller.poll(DELTA, snapshot)
	await process_frame
