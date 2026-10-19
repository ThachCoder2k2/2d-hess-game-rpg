extends UnboundTest

## Pause and the Book freeze the world (docs/game-base-plan.md 9.2, 4.7, 15 M4 acceptance `test_pause_freezes_tick`),
## through the real keys and the real frame loop: the room is T4, with its pawns acting on their own.
##   - Esc (the `pause` action) pauses the tree and opens the pause menu; while it is up the rules of the game get no
##     tick (a counter system sees none), the pawns stand exactly where they were with their clocks unmoved, no play time is
##     counted, and the music goes on. Esc again resumes: the rules tick again and the same key press does not open the menu
##     a second time.
##   - The Book freezes the world with a command and not the tree: while it is open the tree is NOT paused, yet the rules
##     get no tick and the pawns wait; Esc closes the Book (it does not open the menu); the world thaws.
## The menu itself (its buttons, the questions) is pinned by test_pause_restart_is_menu_only and test_quit_to_title_confirm.

const Support := preload("res://tests/bridge/bridge_support.gd")
const ShellSupport := preload("res://tests/shell/shell_support.gd")
const SUITE_NAME := "pause_freezes"

## Real seconds the world is watched for while it must stand still, and while it must run.
const STILL_SECONDS := 0.5
const RUNNING_SECONDS := 1.0


func _init() -> void:
	suite_title = "PAUSE FREEZES TICK TEST"
	watchdog_seconds = 40.0
	call_deferred("_run")


func _run() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	var app := await ShellSupport.boot_into_t4(self, save_service)
	var game := ShellSupport.game_of(app)
	if game == null:
		_expect(false, "setup: Continue brought the game up in T4")
		Support.end_suite(self, save_service)
		return
	var flow := app.game_flow
	var music := app.get_node("MusicPlayer") as AudioStreamPlayer
	var counter := ShellSupport.count_ticks_of(game)
	# The pawns of T4 fight on their own for the seconds this suite watches; a hero that cannot fall keeps the room
	# from being rebuilt (a fall refuses the pause) under the test.
	Support.player_health(game).invulnerable_left = 100000.0

	# --- Control: the room runs by itself ---
	var picture_at_start := ShellSupport.enemy_picture(game)
	await ShellSupport.wait_real_seconds(self, RUNNING_SECONDS)
	_expect(counter.ticks > 10, "control: the rules got ticks while the room was being played (%d)" % counter.ticks)
	_expect(ShellSupport.enemy_picture(game) != picture_at_start, "control: and the pawns of T4 act on their own (their picture changed)")
	_expect(flow.state == GameFlow.State.PLAYING and not paused and not app.pause_menu.is_open(), "control: the game is playing, the tree is running and no menu is up")

	# --- Esc pauses ---
	await ShellSupport.tap_key(self, KEY_ESCAPE)
	_expect(flow.state == GameFlow.State.PAUSED and paused, "Esc pauses the tree")
	_expect(app.pause_menu.is_open() and app.pause_menu.resume_button.has_focus(), "and opens the pause menu, with Resume focused")
	var ticks_at_pause := counter.ticks
	var picture_at_pause := ShellSupport.enemy_picture(game)
	var play_time_at_pause: float = save_service.state.play_time_seconds
	await ShellSupport.wait_real_seconds(self, STILL_SECONDS)
	_expect(counter.ticks == ticks_at_pause, "while paused the rules get no tick")
	_expect(ShellSupport.enemy_picture(game) == picture_at_pause, "the pawns stand exactly where they were, their clocks unmoved")
	_expect(is_equal_approx(float(save_service.state.play_time_seconds), play_time_at_pause), "no play time is counted")
	_expect(music.playing, "the music goes on")
	_expect(game.process_mode == Node.PROCESS_MODE_INHERIT and app.pause_menu.process_mode == Node.PROCESS_MODE_ALWAYS, "the room is stopped by the pause and the menu is not")

	# --- Esc resumes, and does not pause again ---
	await ShellSupport.tap_key(self, KEY_ESCAPE)
	_expect(flow.state == GameFlow.State.PLAYING and not paused and not app.pause_menu.is_open(), "Esc again resumes, closes the menu, and the same press does not pause again")
	await ShellSupport.wait_real_seconds(self, RUNNING_SECONDS)
	_expect(counter.ticks > ticks_at_pause + 10, "the rules tick again after the resume (%d)" % (counter.ticks - ticks_at_pause))
	_expect(ShellSupport.enemy_picture(game) != picture_at_pause, "and the pawns carry on from where they stood")

	# --- The Book freezes the world, not the tree ---
	var book := game.get_node("RuleBookUI") as RuleBookUI
	await ShellSupport.tap_key(self, KEY_B)
	_expect(book.visible and not paused and flow.state == GameFlow.State.PLAYING, "B opens the Book and the tree keeps running")
	_expect(Support.ecs_of(game).frozen, "and the world is frozen")
	var ticks_at_book := counter.ticks
	var picture_at_book := ShellSupport.enemy_picture(game)
	await ShellSupport.wait_real_seconds(self, STILL_SECONDS)
	_expect(counter.ticks == ticks_at_book, "while the Book is open the rules get no tick")
	_expect(ShellSupport.enemy_picture(game) == picture_at_book, "and the pawns wait where they were")
	_expect(not Support.player_tag(game).control_enabled, "the hero's keys are off")

	# --- Esc closes the Book instead of opening the menu ---
	await ShellSupport.tap_key(self, KEY_ESCAPE)
	_expect(not book.visible and flow.state == GameFlow.State.PLAYING and not app.pause_menu.is_open(), "Esc with the Book open closes the Book and does not open the menu")
	_expect(not Support.ecs_of(game).frozen and Support.player_tag(game).control_enabled, "the world thaws and the hero is in control again")
	await ShellSupport.wait_real_seconds(self, STILL_SECONDS)
	_expect(counter.ticks > ticks_at_book, "the rules tick again")

	# --- The pause menu's Book entry: back to the room, Book open, world frozen ---
	_expect(flow.request_pause() and paused, "setup: paused again")
	app.pause_menu.book_button.pressed.emit()
	await process_frame
	await process_frame
	_expect(flow.state == GameFlow.State.PLAYING and not paused and book.visible and Support.ecs_of(game).frozen, "the menu's Book entry resumes the room with the Book open over it and the world frozen")
	await ShellSupport.tap_key(self, KEY_ESCAPE)
	_expect(not book.visible and not Support.ecs_of(game).frozen and flow.state == GameFlow.State.PLAYING, "and Esc closes it")

	Support.end_suite(self, save_service)
