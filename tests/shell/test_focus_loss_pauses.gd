extends UnboundTest

## The game pauses when the window loses focus (docs/game-base-plan.md 9.2, 15 M4 acceptance `test_focus_loss_pauses`):
## `NOTIFICATION_APPLICATION_FOCUS_OUT`, which the engine sends to every node when the application is deactivated (the
## suite sends it the same way: propagate_notification from the root). A room being played is paused and the pause menu
## is up; nothing happens on the title or in a pause that is already up; focus coming back does NOT resume (the player
## does, with the menu); and when the flow refuses (a zone trip is under way) the pause is asked again each frame until it
## is accepted, unless the player is back first.

const Support := preload("res://tests/bridge/bridge_support.gd")
const ShellSupport := preload("res://tests/shell/shell_support.gd")
const SUITE_NAME := "focus_loss"


func _init() -> void:
	suite_title = "FOCUS LOSS PAUSES TEST"
	watchdog_seconds = 40.0
	call_deferred("_run")


func _run() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	var app := await ShellSupport.boot_app(self)
	app.transition.default_fade_seconds = 0.04
	var flow := app.game_flow

	# --- On the title there is nothing to pause ---
	_lose_focus()
	_expect(flow.state == GameFlow.State.TITLE and not paused and not app.pause_menu.is_open(), "losing focus on the title pauses nothing")

	# --- In the room it pauses ---
	flow.start_new_game()
	await app.until_settled()
	var game := ShellSupport.game_of(app)
	if game == null:
		_expect(false, "setup: New Game brought the game up")
		Support.end_suite(self, save_service)
		return
	var counter := ShellSupport.count_ticks_of(game)
	await process_frame
	_expect(flow.state == GameFlow.State.PLAYING and not paused, "setup: the room is being played")
	_lose_focus()
	_expect(flow.state == GameFlow.State.PAUSED and paused, "losing focus pauses the room")
	_expect(app.pause_menu.is_open() and app.pause_menu.resume_button.has_focus(), "and the pause menu is up, with Resume focused")
	var ticks_when_paused := counter.ticks
	await ShellSupport.wait_real_seconds(self, 0.3)
	_expect(counter.ticks == ticks_when_paused, "the world stood still from then on")

	# --- Already paused: losing focus again changes nothing; coming back does not resume ---
	var menu_shown_before := app.pause_menu.is_open()
	_lose_focus()
	_expect(flow.state == GameFlow.State.PAUSED and paused and app.pause_menu.is_open() == menu_shown_before, "losing focus again while paused changes nothing")
	_regain_focus()
	await process_frame
	_expect(flow.state == GameFlow.State.PAUSED and paused and app.pause_menu.is_open(), "coming back does not resume: the player does, from the menu")
	app.pause_menu.resume_button.pressed.emit()
	await process_frame
	_expect(flow.state == GameFlow.State.PLAYING and not paused and not app.pause_menu.is_open(), "Resume resumes")

	# --- A zone trip under way refuses the pause; it is taken the moment the trip is over ---
	game.zone_travel_bridge.travel_in_progress = true
	_lose_focus()
	_expect(flow.state == GameFlow.State.PLAYING and not paused, "during a zone trip the pause is refused")
	await process_frame
	_expect(flow.state == GameFlow.State.PLAYING, "and is still refused while the trip lasts")
	game.zone_travel_bridge.travel_in_progress = false
	await process_frame
	await process_frame
	_expect(flow.state == GameFlow.State.PAUSED and paused, "and is taken as soon as the trip is over")
	flow.request_resume()

	# --- Coming back before the refusal ends cancels it ---
	game.zone_travel_bridge.travel_in_progress = true
	_lose_focus()
	_regain_focus()
	game.zone_travel_bridge.travel_in_progress = false
	await process_frame
	await process_frame
	_expect(flow.state == GameFlow.State.PLAYING and not paused, "if the player is back before the trip ends, nothing pauses afterwards")

	# --- Leaving for the title cancels it as well ---
	game.zone_travel_bridge.travel_in_progress = true
	_lose_focus()
	game.zone_travel_bridge.travel_in_progress = false
	flow.quit_to_title()
	await app.until_settled()
	await process_frame
	_expect(flow.state == GameFlow.State.TITLE and not paused, "a pause that was waiting does not follow the player to the title")

	Support.end_suite(self, save_service)


## What the engine does when the application is deactivated.
func _lose_focus() -> void:
	root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)


func _regain_focus() -> void:
	root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
