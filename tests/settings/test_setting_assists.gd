extends UnboundTest

## The four assists reach the world's tuning (docs/game-base-plan.md 5.8, D-22): Warning time (telegraph_time_scale), Enemy
## pace (enemy_pace_scale), Extra Courage (extra_courage) and Input forgiveness (input_buffer_window), through the
## `tuning_set` command and never by setting a component. On the real game scene:
##   - OPT-IN: a world booted with the standard settings has exactly the standard tuning, and no command was needed;
##   - each assist, set the way the settings screen sets it, lands in world.tuning at the next tick, and no command was
##     refused (a wrong key or type would say `command_rejected`);
##   - taking an assist away puts the standard value back;
##   - a room is a new world with a new Tuning: the assists are sent again after a rebuild (a death, Restart Room);
##   - nothing reads these knobs yet (the milestones are named on Tuning), so a knob reaching the world is all that can be
##     proved today.

const SettingsSupport := preload("res://tests/settings/settings_support.gd")
const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "setting_assists"

## The reason of every request the world refused (the `command_rejected` event), counted by the scene's own router.
var rejected_requests: Array[String] = []


func _init() -> void:
	suite_title = "SETTING ASSISTS TEST"
	watchdog_seconds = 40.0
	call_deferred("_run")


func _run() -> void:
	var booted := await SettingsSupport.boot_game(self, SUITE_NAME)
	var game: GameRoot = booted["game"]
	var app: AppRoot = booted["app"]
	if not _expect(game != null, "setup: the game is up in T4"):
		Support.end_suite(self, booted["save_service"])
		return
	game.router.on(Events.COMMAND_REJECTED, func(event: Dictionary) -> void: rejected_requests.append(String(event.get("reason", ""))))
	var standard := Tuning.new()
	var tuning := Support.ecs_of(game).tuning
	_expect(_same_tuning(tuning, standard), "opt-in: with the standard settings the world holds the standard tuning")

	app.settings.set_value(GameSettings.ASSIST_TELEGRAPH_TIME, 125)
	Support.pump(game, 0.05)
	_expect(is_equal_approx(tuning.telegraph_time_scale, 1.25) and is_equal_approx(tuning.enemy_pace_scale, 1.0) and tuning.extra_courage == 0, "Warning time 125 percent: telegraph_time_scale is 1.25 and nothing else moved")
	app.settings.set_value(GameSettings.ASSIST_TELEGRAPH_TIME, 150)
	Support.pump(game, 0.05)
	_expect(is_equal_approx(tuning.telegraph_time_scale, 1.5), "Warning time 150 percent: 1.5")

	app.settings.set_value(GameSettings.ASSIST_ENEMY_PACE, 85)
	Support.pump(game, 0.05)
	_expect(is_equal_approx(tuning.enemy_pace_scale, 0.85), "Enemy pace 85 percent: enemy_pace_scale is 0.85")
	app.settings.set_value(GameSettings.ASSIST_ENEMY_PACE, 70)
	Support.pump(game, 0.05)
	_expect(is_equal_approx(tuning.enemy_pace_scale, 0.70), "Enemy pace 70 percent: 0.70")

	app.settings.set_value(GameSettings.ASSIST_EXTRA_COURAGE, 2)
	Support.pump(game, 0.05)
	_expect(tuning.extra_courage == 2, "Extra Courage +2: extra_courage is 2")

	app.settings.set_value(GameSettings.ASSIST_INPUT_FORGIVENESS, true)
	Support.pump(game, 0.05)
	_expect(is_equal_approx(tuning.input_buffer_window, SettingsBridge.INPUT_FORGIVENESS_BUFFER_SECONDS) and is_equal_approx(tuning.input_buffer_window, 0.20), "Input forgiveness: the input buffer is 0.20 s")

	_expect(rejected_requests.is_empty(), "no tuning command was refused (%s)" % [rejected_requests])

	# A new room is a new world: the assists are sent again.
	game.respawn()
	var new_tuning := Support.ecs_of(game).tuning
	_expect(new_tuning != tuning, "setup: a rebuilt room has a new world and a new Tuning")
	Support.pump(game, 0.05)
	_expect(is_equal_approx(new_tuning.telegraph_time_scale, 1.5) and is_equal_approx(new_tuning.enemy_pace_scale, 0.70) and new_tuning.extra_courage == 2 and is_equal_approx(new_tuning.input_buffer_window, 0.20), "after a rebuild the new world holds all four assists")

	# Taking them away.
	app.settings.set_value(GameSettings.ASSIST_TELEGRAPH_TIME, 100)
	app.settings.set_value(GameSettings.ASSIST_ENEMY_PACE, 100)
	app.settings.set_value(GameSettings.ASSIST_EXTRA_COURAGE, 0)
	app.settings.set_value(GameSettings.ASSIST_INPUT_FORGIVENESS, false)
	Support.pump(game, 0.05)
	_expect(_same_tuning(new_tuning, standard), "taking every assist away puts the standard tuning back")
	_expect(rejected_requests.is_empty(), "and none of that was refused either (%s)" % [rejected_requests])
	Support.end_suite(self, booted["save_service"])


func _same_tuning(a: Tuning, b: Tuning) -> bool:
	return is_equal_approx(a.telegraph_time_scale, b.telegraph_time_scale) and is_equal_approx(a.enemy_pace_scale, b.enemy_pace_scale) \
		and a.extra_courage == b.extra_courage and is_equal_approx(a.input_buffer_window, b.input_buffer_window) and a.reduce_flash == b.reduce_flash
