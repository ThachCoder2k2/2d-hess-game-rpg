extends UnboundTest

## The title screen on its own (shell/title/title_screen.tscn, docs/game-base-plan.md 9.2): what it shows for a
## summary, which signal each button raises, the New Game question over a used slot, the post-game board, and that a
## choice that leaves the title cannot be made twice. AppRoot's use of it is pinned by test_app_flow.gd.

var heard: Array[String] = []


func _init() -> void:
	suite_title = "TITLE SCREEN TEST"
	call_deferred("_run")


func _run() -> void:
	var paths := TestPaths.new(self)
	var scene := paths.load_scene(paths.title_scene())
	if scene == null:
		finish()
		return

	# --- A first launch: New Game first, no Continue, Settings disabled, nothing on the card ---
	var fresh_summary := TitleSummary.new()
	fresh_summary.version_text = "v1.2.3"
	var screen := _show(scene, fresh_summary, false)
	await process_frame
	_expect(screen.new_game_button.visible and screen.credits_button.visible and screen.quit_button.visible and screen.settings_button.visible, "New Game, Settings, Credits and Quit are on the menu")
	_expect(not screen.continue_button.visible and not screen.card_label.visible and not screen.notice_label.visible, "Continue, the card and the notice are hidden when there is no save")
	_expect(screen.settings_button.disabled, "Settings is disabled while no settings screen is wired in")
	_expect(screen.new_game_button.has_focus(), "New Game takes the focus")
	_expect(screen.version_label.text == "v1.2.3", "the version string is shown")
	_expect(screen.emptied_square.visible, "the board has all its squares")

	# --- Without a save, New Game chooses at once ---
	screen.new_game_button.pressed.emit()
	_expect(heard == ["new_game"] and not screen.is_confirming(), "with nothing to lose New Game just chooses")
	_expect(screen.menu.process_mode == Node.PROCESS_MODE_DISABLED, "and the menu goes quiet, so a second press cannot choose again")
	screen.queue_free()
	heard.clear()

	# --- A used slot: Continue is first, the card and the notice show, New Game asks ---
	var used_summary := TitleSummary.new()
	used_summary.can_continue = true
	used_summary.card_text = "Broken Rule Yard  |  1h 02m played"
	used_summary.notice_text = "Your latest save was damaged. The save before it is loaded instead."
	used_summary.completed = true
	var used := _show(scene, used_summary, true)
	await process_frame
	_expect(used.continue_button.visible and used.continue_button.has_focus(), "Continue is on the menu and has the focus")
	_expect(used.card_label.visible and used.card_label.text == used_summary.card_text, "the card shows the run")
	_expect(used.notice_label.visible and used.notice_label.text == used_summary.notice_text, "and the notice its sentence")
	_expect(not used.settings_button.disabled, "Settings is enabled once a settings screen exists")
	_expect(not used.emptied_square.visible, "after the ending one square of the board is empty")

	used.new_game_button.pressed.emit()
	_expect(used.is_confirming() and heard.is_empty(), "New Game over a used slot asks first and chooses nothing yet")
	_expect(used.confirm_panel.cancel_button.has_focus(), "the safe answer has the focus")
	_expect(used.menu.process_mode == Node.PROCESS_MODE_DISABLED, "and the menu behind the question is off")
	used.confirm_panel.cancel_button.pressed.emit()
	_expect(not used.is_confirming() and heard.is_empty() and used.menu.process_mode != Node.PROCESS_MODE_DISABLED and used.new_game_button.has_focus(), "keeping the save closes the question, wakes the menu and gives New Game the focus back")
	used.new_game_button.pressed.emit()
	used.confirm_panel.confirm_button.pressed.emit()
	_expect(heard == ["new_game"], "starting over chooses New Game once")

	# --- The other buttons raise their own signals ---
	heard.clear()
	used.menu.process_mode = Node.PROCESS_MODE_INHERIT
	used.settings_button.pressed.emit()
	_expect(heard == ["settings"] and used.menu.process_mode != Node.PROCESS_MODE_DISABLED, "Settings raises its signal and leaves the menu awake (it opens over the title)")
	used.credits_button.pressed.emit()
	_expect(heard == ["settings", "credits"], "Credits raises its signal")
	used.menu.process_mode = Node.PROCESS_MODE_INHERIT
	used.continue_button.pressed.emit()
	_expect(heard == ["settings", "credits", "continue"], "Continue raises its signal")
	used.menu.process_mode = Node.PROCESS_MODE_INHERIT
	used.quit_button.pressed.emit()
	_expect(heard == ["settings", "credits", "continue", "quit"], "Quit raises its signal")

	# --- Configured again while on screen (a Continue that found the save gone) ---
	used.configure(fresh_summary, false)
	_expect(not used.continue_button.visible and used.settings_button.disabled and used.emptied_square.visible, "configure() refreshes a screen that is already up")
	used.queue_free()
	finish()


func _show(scene: PackedScene, summary: TitleSummary, settings_available: bool) -> TitleScreen:
	var screen := scene.instantiate() as TitleScreen
	screen.configure(summary, settings_available)
	screen.new_game_chosen.connect(func() -> void: heard.append("new_game"))
	screen.continue_chosen.connect(func() -> void: heard.append("continue"))
	screen.settings_chosen.connect(func() -> void: heard.append("settings"))
	screen.credits_chosen.connect(func() -> void: heard.append("credits"))
	screen.quit_chosen.connect(func() -> void: heard.append("quit"))
	root.add_child(screen)
	return screen
