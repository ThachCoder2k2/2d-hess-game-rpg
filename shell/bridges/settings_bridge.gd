class_name SettingsBridge
extends ShellBridge

## The settings of the ROOM, made true in the game scene (docs/game-base-plan.md 9.2, 5.8, 10). The player's choices are one
## GameSettings object that AppRoot owns and hands to the scene (`root.settings`); this bridge listens to it and sets
## the thing each choice is about:
##
##   Screen shake         the camera bridge's shake scale (the rig shakes by that much of what the hit asked for)
##   Reduce flashing      the HUD's damage flash, the board's strike flash and pulse, and, as a tuning knob of the world,
##                        the pieces' hurt tint and the hero's invulnerability flicker
##   High-contrast danger the board draws a danger cell with a thick outline and stripes
##   Hold-or-toggle       the input poller publishes Guard, Focus and turn mode as switches instead of held keys
##   the four assists     world.tuning (telegraph time, enemy pace, extra Courage, the input buffer), through the
##                        `tuning_set` command: a setting never edits a component (CLAUDE.md), and a command lands at
##                        the head of the next tick
##
## The app-level settings (volumes, fullscreen, language, high-contrast menus) are SettingsApplier's, in AppRoot.
##
## Every room is a new world with a new Tuning, so the tuning is sent again after each boot (bind_world); the rest lives in
## nodes the scene keeps (the camera bridge, the HUD, the board, the poller) and is set when the setting moves.
## Reads: GameSettings. Writes: the nodes above and world.commands. Decides nothing about the game.

## How long a step pressed early is remembered with the Input forgiveness assist (5.8: 0.20 s; the standard window of
## M7b is 0.12 s). Without the assist the world keeps the standard of the moment.
const INPUT_FORGIVENESS_BUFFER_SECONDS := 0.20

## assist setting -> the world.tuning field it sets. The fields are named here once; Tuning says which system reads each
## and from which milestone, and `test_settings_coming_later` holds the "(coming later)" mark of a setting to whether
## one does.
const TUNING_KNOB_BY_ASSIST := {
	GameSettings.ASSIST_TELEGRAPH_TIME: &"telegraph_time_scale",
	GameSettings.ASSIST_ENEMY_PACE: &"enemy_pace_scale",
	GameSettings.ASSIST_EXTRA_COURAGE: &"extra_courage",
	GameSettings.ASSIST_INPUT_FORGIVENESS: &"input_buffer_window",
}

## hold-or-toggle setting -> the InputMap action that becomes a switch.
const TOGGLED_ACTION_BY_SETTING := {
	GameSettings.TOGGLE_TURN_MODE: &"turn_mode",
	GameSettings.TOGGLE_GUARD: &"guard",
	GameSettings.TOGGLE_FOCUS: &"focus",
}


func attach(game_root: GameRoot) -> void:
	super.attach(game_root)
	root.settings.changed.connect(apply_all)
	apply_all()


## After every boot: the new world gets the assists and Reduce flashing.
func bind_world(world_snapshot: HudSnapshot, world_cast: Dictionary) -> void:
	super.bind_world(world_snapshot, world_cast)
	apply_tuning()


## Sets every room-level setting where it belongs. Called on attach and whenever a setting moves.
func apply_all() -> void:
	if not is_instance_valid(root):
		return
	var settings := root.settings
	root.camera_bridge.shake_scale = float(settings.value(GameSettings.SHAKE_SCALE))
	if root.hud != null:
		root.hud.reduce_flash = bool(settings.value(GameSettings.REDUCE_FLASH))
	if root.board != null:
		root.board.reduce_flash = bool(settings.value(GameSettings.REDUCE_FLASH))
		root.board.high_contrast_danger = bool(settings.value(GameSettings.HIGH_CONTRAST_DANGER))
	for setting_key: StringName in TOGGLED_ACTION_BY_SETTING:
		root.input_poller.set_toggle_mode(TOGGLED_ACTION_BY_SETTING[setting_key], bool(settings.value(setting_key)))
	apply_tuning()


## Sends the world.tuning knobs the settings own, the ones that differ from what the world holds now.
func apply_tuning() -> void:
	if not is_instance_valid(root) or root.ecs == null:
		return
	var settings := root.settings
	var neutral := Tuning.new()
	var wanted := {
		TUNING_KNOB_BY_ASSIST[GameSettings.ASSIST_TELEGRAPH_TIME]: float(settings.value(GameSettings.ASSIST_TELEGRAPH_TIME)) / 100.0,
		TUNING_KNOB_BY_ASSIST[GameSettings.ASSIST_ENEMY_PACE]: float(settings.value(GameSettings.ASSIST_ENEMY_PACE)) / 100.0,
		TUNING_KNOB_BY_ASSIST[GameSettings.ASSIST_EXTRA_COURAGE]: int(settings.value(GameSettings.ASSIST_EXTRA_COURAGE)),
		TUNING_KNOB_BY_ASSIST[GameSettings.ASSIST_INPUT_FORGIVENESS]: INPUT_FORGIVENESS_BUFFER_SECONDS if bool(settings.value(GameSettings.ASSIST_INPUT_FORGIVENESS)) else neutral.input_buffer_window,
		&"reduce_flash": bool(settings.value(GameSettings.REDUCE_FLASH)),
	}
	for knob: StringName in wanted:
		if root.ecs.tuning.get(knob) != wanted[knob]:
			root.ecs.push_command(Commands.tuning_set(knob, wanted[knob]))
