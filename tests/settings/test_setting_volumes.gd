extends UnboundTest

## The four volume settings set their audio buses (docs/game-base-plan.md 9.2: Master, SFX, Music, UI). Driven the way the
## settings screen does it (`settings.set_value`) on the real AppRoot: the bus's own volume and mute are read back from
## the AudioServer. A volume is a number from 0 to 1: 1.0 is the level the mix was made at (0 dB), 0.5 is half the
## amplitude (about -6 dB), 0.0 is the bus muted. A volume moves ITS bus and no other. What is chosen is written to the
## profile and read back by the next start.

const SettingsSupport := preload("res://tests/settings/settings_support.gd")
const SUITE_NAME := "setting_volumes"
const BUS_NAMES: Array[StringName] = [&"Master", &"SFX", &"Music", &"UI"]


func _init() -> void:
	suite_title = "SETTING VOLUMES TEST"
	call_deferred("_run")


func _run() -> void:
	var booted := await SettingsSupport.boot_title(self, SUITE_NAME)
	var app: AppRoot = booted["app"]
	var save_service: Node = booted["save_service"]
	for key: StringName in SettingsApplier.BUS_NAME_BY_VOLUME_KEY:
		var bus_name: StringName = SettingsApplier.BUS_NAME_BY_VOLUME_KEY[key]
		_expect(AudioServer.get_bus_index(bus_name) >= 0, "setup: the project has a bus called %s for %s" % [bus_name, key])
	_expect(SettingsApplier.BUS_NAME_BY_VOLUME_KEY.size() == 4, "the four volume settings each name a bus")

	for bus_name in BUS_NAMES:
		_expect(_db_of(bus_name) == 0.0 and not _muted(bus_name), "at the start %s is at 0 dB and not muted" % bus_name)

	_expect(app.settings.set_value(GameSettings.VOLUME_MASTER, 0.5), "setup: Master set to half")
	_expect(is_equal_approx(_db_of(&"Master"), linear_to_db(0.5)), "Master at half is %.2f dB (the engine's own conversion of an amplitude of 0.5)" % _db_of(&"Master"))
	for other in [&"SFX", &"Music", &"UI"]:
		_expect(_db_of(other) == 0.0, "and %s did not move" % other)

	_expect(app.settings.set_value(GameSettings.VOLUME_SFX, 0.25), "setup: SFX set to a quarter")
	_expect(is_equal_approx(_db_of(&"SFX"), linear_to_db(0.25)) and _db_of(&"Music") == 0.0 and _db_of(&"UI") == 0.0, "SFX follows its own setting and only that bus")
	_expect(app.settings.set_value(GameSettings.VOLUME_MUSIC, 0.8), "setup: Music set to 80 percent")
	_expect(is_equal_approx(_db_of(&"Music"), linear_to_db(0.8)), "Music follows its setting")
	_expect(app.settings.set_value(GameSettings.VOLUME_UI, 0.6), "setup: UI set to 60 percent")
	_expect(is_equal_approx(_db_of(&"UI"), linear_to_db(0.6)), "UI follows its setting")

	app.settings.set_value(GameSettings.VOLUME_MUSIC, 0.0)
	_expect(_muted(&"Music") and not _muted(&"SFX") and not _muted(&"Master"), "zero mutes that bus and no other")
	app.settings.set_value(GameSettings.VOLUME_MUSIC, 1.0)
	_expect(not _muted(&"Music") and _db_of(&"Music") == 0.0, "full volume unmutes it and puts it at 0 dB")
	_expect(GameSettings.volume_in_decibels(0.0) == -80.0 and GameSettings.volume_in_decibels(1.0) == 0.0, "the conversion: silence is -80 dB and full is 0 dB")

	# The choice is kept: written to the profile, read back by the next start.
	app.settings.set_value(GameSettings.VOLUME_MASTER, 0.4)
	app.flush_settings()
	var next_start := SettingsStore.new(save_service).load_settings()
	_expect(is_equal_approx(float(next_start.value(GameSettings.VOLUME_MASTER)), 0.4) and is_equal_approx(float(next_start.value(GameSettings.VOLUME_SFX)), 0.25), "the volumes are in the profile for the next start")
	_expect(is_equal_approx(_db_of(&"Master"), linear_to_db(0.4)), "and the bus has the last one")

	# Put the buses back at full (the AudioServer is the process's, and this process ends with the suite, but a suite that
	# is later given a longer run should not inherit a quiet game).
	for key: StringName in SettingsApplier.BUS_NAME_BY_VOLUME_KEY:
		app.settings.set_value(key, 1.0)
	_end_the_suite(save_service)


func _end_the_suite(save_service: Node) -> void:
	SettingsSupport.Support.end_suite(self, save_service)


func _db_of(bus_name: StringName) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name))


func _muted(bus_name: StringName) -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(bus_name))
