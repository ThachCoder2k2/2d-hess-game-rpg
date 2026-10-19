extends UnboundTest

## AppRoot, the project's main scene, end to end (docs/game-base-plan.md 9.1, 15 M4): boot -> title -> New Game ->
## the game in T1 -> pause -> Quit to Title -> Continue -> credits -> title, with the music and the fade surviving
## every screen change, a room rebuilt behind the fade, the autosave tick, and nothing left behind when the player
## leaves the room in the middle of a death. The save is a throwaway folder (Support.install_isolated_save_service).
## Fades are shortened after the boot so the suite is quick; test_transition_layer pins the fade itself.

const Support := preload("res://tests/bridge/bridge_support.gd")
const ShellSupport := preload("res://tests/shell/shell_support.gd")
const SUITE_NAME := "app_flow"

## The fade the suite uses after the boot, in seconds.
const QUICK_FADE_SECONDS := 0.04

var quit_requests := 0
var respawn_states: Array[String] = []


func _init() -> void:
	suite_title = "APP FLOW TEST"
	watchdog_seconds = 50.0
	call_deferred("_run")


func _run() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	var app := await ShellSupport.boot_app(self)
	var flow := app.game_flow

	# --- Boot: the title, with nothing to continue ---
	_expect(current_scene == app and app.name == "AppRoot", "the main scene is AppRoot")
	_expect(flow.state == GameFlow.State.TITLE and app.is_settled(), "boot ends on the title")
	var title := ShellSupport.title_of(app)
	_expect(title != null, "the screen is the title")
	if title == null:
		Support.end_suite(self, save_service)
		return
	_expect(app.transition.is_clear(), "the screen has faded in")
	_expect(not title.continue_button.visible and title.new_game_button.has_focus(), "with no save there is no Continue, and New Game has focus")
	_expect(title.settings_button.disabled and not title.credits_button.disabled and not title.quit_button.disabled, "Settings is disabled until a settings screen is wired in; Credits and Quit work")
	_expect(title.version_label.text == "v" + String(ProjectSettings.get_setting("application/config/version", "")) and title.version_label.text.length() > 1, "the title shows the build's version (%s)" % title.version_label.text)
	var music := app.get_node("MusicPlayer") as AudioStreamPlayer
	_expect(music.playing and music.process_mode == Node.PROCESS_MODE_ALWAYS, "the music plays on the title and keeps playing while the tree is paused")
	_expect(not paused, "the tree is not paused")
	app.transition.default_fade_seconds = QUICK_FADE_SECONDS

	# --- Quit asks the app to end, once ---
	app.quit_requested.connect(func() -> void: quit_requests += 1)
	title.quit_button.pressed.emit()
	_expect(quit_requests == 1, "Quit asks the app to quit")
	title.menu.process_mode = Node.PROCESS_MODE_INHERIT

	# --- New Game: the game in T1, the title gone ---
	title.new_game_button.pressed.emit()
	_expect(flow.state == GameFlow.State.PLAYING and flow.start_mode == GameFlow.StartMode.NEW_GAME, "New Game starts playing")
	await app.until_settled()
	var game := ShellSupport.game_of(app)
	_expect(game != null and (not is_instance_valid(title) or title.get_parent() == null), "the title is let go and the game is the screen")
	if game == null:
		Support.end_suite(self, save_service)
		return
	_expect(game.current_zone_id == ShellSupport.T1 and game.get_parent() == app.screen_host, "the game is in T1, under the screen host")
	_expect(game.game_flow == flow, "the room serves the app's flow (a death asks it, not a flow of its own)")
	_expect(game.get_node_or_null("MusicPlayer") == null and app.get_node("MusicPlayer") == music and music.playing, "the music is AppRoot's: the room has none and the player was never replaced")
	_expect(Support.player_tag(game).control_enabled and app.transition.is_clear(), "the hero is in control and the fade is clear")
	_expect(save_service.get("has_session") and FileAccess.file_exists(String(save_service.call("slot_path", 0))), "the New Game's clean run is on the disk")
	_expect(not paused and current_scene == app, "nothing paused, and the main scene is still AppRoot")

	# --- The autosave tick ---
	var indicator := app.autosave_indicator
	_expect(not indicator.is_showing(), "no tick before a save")
	save_service.state.add_unlock(&"wooden_sword")
	_expect(save_service.request_save(&"unlock_gained") and indicator.is_showing(), "a success-event save shows the tick")
	await create_timer(indicator.visible_seconds + 0.15, true, false, true).timeout
	_expect(not indicator.is_showing(), "and it goes away after its second")

	# --- Pause: the tree stops, the overlay and the music do not ---
	var played_before_pause: float = save_service.state.play_time_seconds
	_expect(flow.request_pause() and paused, "a pause pauses the tree")
	await create_timer(0.3, true, false, true).timeout
	_expect(is_equal_approx(float(save_service.state.play_time_seconds), played_before_pause), "the room does not tick while paused (no play time counted)")
	_expect(music.playing and app.process_mode == Node.PROCESS_MODE_INHERIT, "the music goes on")
	_expect(flow.request_resume() and not paused, "a resume lifts it")
	await create_timer(0.2).timeout
	_expect(float(save_service.state.play_time_seconds) > played_before_pause, "and the room ticks again")
	game.zone_travel_bridge.travel_in_progress = true
	_expect(not flow.request_pause() and not paused, "a pause is refused during a zone trip")
	game.zone_travel_bridge.travel_in_progress = false

	# --- A room rebuild goes behind the fade ---
	var world_before := Support.ecs_of(game)
	var black_when_rebuilt := [false]
	flow.respawned.connect(func(_reason: StringName) -> void: black_when_rebuilt[0] = app.transition.is_black())
	flow.state_changed.connect(func(previous: GameFlow.State, current: GameFlow.State) -> void:
		respawn_states.append("%s>%s" % [GameFlow.State.keys()[previous], GameFlow.State.keys()[current]]))
	flow.request_respawn(GameFlow.REASON_RESTART_MENU)
	_expect(flow.respawn_is_pending() and not flow.request_pause(), "a pause is refused while a rebuild waits")
	_expect(await Support.wait_for_respawn(self, game), "the restart request rebuilds the room")
	_expect(Support.ecs_of(game) != world_before and black_when_rebuilt[0], "the room was rebuilt while the screen was black")
	_expect(respawn_states == ["PLAYING>RESPAWNING", "RESPAWNING>PLAYING"], "the flow went to RESPAWNING and back (%s)" % ", ".join(PackedStringArray(respawn_states)))
	_expect(await ShellSupport.wait_until(self, func() -> bool: return app.transition.is_clear()), "and the screen came back")
	_expect(flow.last_respawn_reason == GameFlow.REASON_RESTART_MENU and flow.state == GameFlow.State.PLAYING, "the reason is kept and the flow is playing again")

	# --- Pause, then Quit to Title: the tree is released, the room is let go, the music stays ---
	var old_game := game
	_expect(flow.request_pause() and paused, "setup: paused again")
	_expect(flow.quit_to_title() and not paused, "Quit to Title lifts the pause")
	await app.until_settled()
	var title_again := ShellSupport.title_of(app)
	await process_frame
	_expect(title_again != null and not is_instance_valid(old_game), "the title is back and the room was freed")
	_expect(app.get_node("MusicPlayer") == music and music.playing, "the music was never interrupted")
	_expect(title_again != null and title_again.continue_button.visible and title_again.card_label.visible and not title_again.card_label.text.is_empty(), "the title now offers Continue, with the slot card (%s)" % (title_again.card_label.text if title_again != null else ""))
	_expect(title_again != null and title_again.emptied_square.visible, "and the board has all its squares (the game was not finished)")

	# --- A New Game over the used slot asks first ---
	if title_again != null:
		title_again.new_game_button.pressed.emit()
		_expect(title_again.is_confirming() and flow.state == GameFlow.State.TITLE, "New Game over a used slot asks to confirm and starts nothing yet")
		title_again.confirm_panel.cancel_button.pressed.emit()
		_expect(not title_again.is_confirming() and flow.state == GameFlow.State.TITLE and title_again.new_game_button.has_focus(), "keeping the save closes the question and leaves the title as it was")

	# --- Continue: the room of the last save ---
	if title_again != null:
		title_again.continue_button.pressed.emit()
	_expect(flow.state == GameFlow.State.PLAYING and flow.start_mode == GameFlow.StartMode.CONTINUE, "Continue starts playing, as a continue")
	await app.until_settled()
	var resumed := ShellSupport.game_of(app)
	_expect(resumed != null and resumed.current_zone_id == ShellSupport.T1 and Support.player_combat(resumed).sword_unlocked, "Continue resumes in T1 with the sword the save held")

	# --- A fall during the defeat beat, then Quit to Title: nothing tries to rebuild a freed room ---
	if resumed != null:
		ShellSupport.hold_the_game_still(app)
		Support.damage_player(resumed, 99)
		_expect(Support.room_ending(resumed), "setup: the hero fell and the defeat beat is running")
		_expect(not flow.request_pause() and not paused, "a pause is refused during the defeat beat")
		resumed.set_process(true)
		flow.quit_to_title()
		await app.until_settled()
		await create_timer(RoomOutcomeBridge.DEFEAT_BEAT_SECONDS + 0.4, true, false, true).timeout
		_expect(flow.state == GameFlow.State.TITLE and ShellSupport.title_of(app) != null and not flow.respawn_is_pending(), "the beat ended after the player left: no rebuild, no error, still the title")

	# --- The credits from the title, then back ---
	var title_for_credits := ShellSupport.title_of(app)
	if title_for_credits != null:
		title_for_credits.credits_button.pressed.emit()
		_expect(flow.state == GameFlow.State.CREDITS, "Credits on the title shows the credits")
		await app.until_settled()
		var credits := app.screen as CreditsScreen
		_expect(credits != null and credits.definition != null and not credits.definition.sections.is_empty(), "the credits screen reads content/story/credits.tres")
		if credits != null:
			credits.finished.emit()
			_expect(flow.state == GameFlow.State.TITLE, "the end of the roll goes back to the title")
			await app.until_settled()
			_expect(ShellSupport.title_of(app) != null, "and shows it")

	# --- The ending: game -> ending -> credits -> title, with the completed mark ---
	var title_for_ending := ShellSupport.title_of(app)
	if title_for_ending != null:
		title_for_ending.continue_button.pressed.emit()
		await app.until_settled()
		_expect(not save_service.call("is_completed"), "setup: the game is not completed yet")
		_expect(flow.reach_ending() and save_service.call("is_completed"), "reaching the ending writes the completed mark")
		_expect(flow.finish_ending() and flow.state == GameFlow.State.CREDITS, "the credits follow the ending")
		await app.until_settled()
		var ending_credits := app.screen as CreditsScreen
		_expect(ending_credits != null, "and roll")
		if ending_credits != null:
			ending_credits.finished.emit()
			await app.until_settled()
		var finished_title := ShellSupport.title_of(app)
		_expect(finished_title != null and not finished_title.emptied_square.visible, "the title shows the post-game board: one square is empty")
		if finished_title != null:
			finished_title.new_game_button.pressed.emit()
			finished_title.confirm_panel.confirm_button.pressed.emit()
			await app.until_settled()
			_expect(ShellSupport.game_of(app) != null and save_service.call("is_completed"), "a New Game after the ending keeps the completed mark")
			flow.quit_to_title()
			await app.until_settled()
			var after_new_game := ShellSupport.title_of(app)
			_expect(after_new_game != null and not after_new_game.emptied_square.visible, "and the empty square stays")

	Support.end_suite(self, save_service)
