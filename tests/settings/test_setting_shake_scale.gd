extends UnboundTest

## The Screen shake setting scales the camera's shake (docs/game-base-plan.md 9.2, 10: "reduce-shake removes effects, never
## telegraphs"). On the real game scene: a hit on the hero kicks the rig by (4.2 + damage) pixels at full scale; at half it
## kicks it by half that, and at zero not at all. The rig, the bridge and the hit are the real ones (a damage event through
## HealthSystem and the router), only the number the setting multiplies is read off the rig.

const SettingsSupport := preload("res://tests/settings/settings_support.gd")
const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "setting_shake_scale"

## What a hit of one point shakes by at full scale: CameraBridge's base strength plus one pixel per point.
const FULL_STRENGTH_OF_ONE_POINT := CameraBridge.HIT_TAKEN_SHAKE_BASE_STRENGTH + 1.0


func _init() -> void:
	suite_title = "SETTING SHAKE SCALE TEST"
	watchdog_seconds = 40.0
	call_deferred("_run")


func _run() -> void:
	var booted := await SettingsSupport.boot_game(self, SUITE_NAME)
	var game: GameRoot = booted["game"]
	var app: AppRoot = booted["app"]
	if not _expect(game != null, "setup: the game is up in T4"):
		Support.end_suite(self, booted["save_service"])
		return
	var rig := game.camera_rig
	_expect(rig != null and is_equal_approx(game.camera_bridge.shake_scale, 1.0), "setup: the rig is there and the shake is at full scale")

	var full_scale_shake := _shake_by_one_hit(game, rig)
	_expect(is_equal_approx(full_scale_shake, FULL_STRENGTH_OF_ONE_POINT), "at full scale a hit shakes the screen by %.1f pixels (%.2f)" % [FULL_STRENGTH_OF_ONE_POINT, full_scale_shake])

	app.settings.set_value(GameSettings.SHAKE_SCALE, 0.5)
	_expect(is_equal_approx(game.camera_bridge.shake_scale, 0.5), "the setting reaches the camera bridge")
	var half_scale_shake := _shake_by_one_hit(game, rig)
	_expect(is_equal_approx(half_scale_shake, FULL_STRENGTH_OF_ONE_POINT * 0.5), "at half scale the same hit shakes half as hard (%.2f)" % half_scale_shake)

	app.settings.set_value(GameSettings.SHAKE_SCALE, 0.0)
	_expect(is_zero_approx(_shake_by_one_hit(game, rig)), "at zero a hit does not shake the screen at all")
	_expect(is_zero_approx(rig.shake_time_left), "and no shake is left running")

	game.camera_bridge.shake(0.1, 3.0)
	_expect(is_zero_approx(rig.shake_strength), "nor does any other caller of shake()")

	app.settings.set_value(GameSettings.SHAKE_SCALE, 1.0)
	_expect(is_equal_approx(_shake_by_one_hit(game, rig), FULL_STRENGTH_OF_ONE_POINT), "put back to full, the shake is back")
	Support.end_suite(self, booted["save_service"])


## One point of damage to the hero through the real health system (its Courage refilled first, so a run of hits never
## ends the room); returns the strength the rig was kicked by.
func _shake_by_one_hit(game: GameRoot, rig: CameraRig) -> float:
	var health := Support.player_health(game)
	health.current = health.max_value
	rig.shake_strength = 0.0
	rig.shake_time_left = 0.0
	rig.shake_duration = 0.0
	Support.wait_out_invulnerability(game)
	Support.damage_player(game, 1)
	return rig.shake_strength
