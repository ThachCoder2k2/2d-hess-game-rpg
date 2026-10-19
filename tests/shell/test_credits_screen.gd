extends UnboundTest

## The credits roll (shell/credits/credits_screen.tscn, docs/game-base-plan.md 8.8, 9.2): it lays out the data it is
## given (the game's title, each block's heading and lines, the closing line, the licence text as fine print), scrolls
## it up from below the screen at the data's speed, ends when the last line has left the screen, and is skipped by
## holding Confirm (read from events, never from the Input singleton). With no data given it reads the real
## content/story/credits.tres. The scroll is driven by hand (_process with a delta) so the suite is exact (the screen's own
## frame processing is switched off after it is added).

var finished_count := 0


func _init() -> void:
	suite_title = "CREDITS SCREEN TEST"
	call_deferred("_run")


func _run() -> void:
	var paths := TestPaths.new(self)
	var scene := paths.load_scene(paths.credits_scene())
	if scene == null:
		finish()
		return

	# --- The data it is given is what it lays out ---
	var screen := _show(scene, _small_roll())
	await process_frame
	var texts := _texts_of(screen)
	_expect(texts == ["A Small Game", "Made by", "Ada", "Ben", "Fine print", "No warranty.", "Thank you for playing."], "the roll is the title, each heading and line in order, and the closing line (%s)" % " / ".join(PackedStringArray(texts)))
	var by_text := _labels_by_text(screen)
	_expect(by_text["A Small Game"].get_theme_font_size(&"font_size") > by_text["Made by"].get_theme_font_size(&"font_size") and by_text["Made by"].get_theme_font_size(&"font_size") > by_text["Ada"].get_theme_font_size(&"font_size") and by_text["Ada"].get_theme_font_size(&"font_size") > by_text["No warranty."].get_theme_font_size(&"font_size"), "the title is larger than a heading, a heading than a line, and fine print is the smallest")
	_expect(by_text["Ada"].autowrap_mode != TextServer.AUTOWRAP_OFF and by_text["Ada"].horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "lines wrap to the column and are centred")
	var screen_size := screen.get_viewport_rect().size
	_expect(is_equal_approx(screen.roll.position.y, screen_size.y), "the roll starts just below the screen (y %.0f)" % screen.roll.position.y)
	_expect(is_equal_approx(screen.roll.position.x, (screen_size.x - screen.column_width) / 2.0), "and is centred")

	# --- It scrolls at the data's speed ---
	var start_y := screen.roll.position.y
	screen._process(0.5)
	_expect(is_equal_approx(start_y - screen.roll.position.y, 0.5 * 100.0), "it moves up at the data's 100 px per second")
	_expect(not screen.is_finished() and finished_count == 0, "and has not ended")

	# --- It ends when the last line has left the screen, once ---
	var steps := 0
	while not screen.is_finished() and steps < 400:
		screen._process(0.25)
		steps += 1
	_expect(screen.is_finished() and finished_count == 1, "it ends by itself after the last line scrolled out (%d steps)" % steps)
	_expect(screen.roll.position.y + maxf(screen.roll.size.y, screen.roll.get_combined_minimum_size().y) <= 0.0, "and the whole roll is above the screen")
	screen._process(1.0)
	_expect(finished_count == 1, "ending says so once")
	screen.queue_free()

	# --- Holding Confirm skips it ---
	finished_count = 0
	var skipping := _show(scene, _small_roll())
	await process_frame
	_expect(not skipping.skip_progress_bar.visible and skipping.skip_progress() == 0.0, "no progress bar before Confirm is held")
	skipping._unhandled_input(_confirm(true))
	skipping._process(skipping.skip_hold_seconds * 0.5)
	_expect(is_equal_approx(skipping.skip_progress(), 0.5) and skipping.skip_progress_bar.visible and not skipping.is_finished(), "half the hold is half the bar")
	skipping._unhandled_input(_confirm(false))
	skipping._process(0.1)
	_expect(skipping.skip_progress() == 0.0 and not skipping.skip_progress_bar.visible, "letting go starts over")
	skipping._unhandled_input(_confirm(true))
	skipping._process(skipping.skip_hold_seconds * 0.6)
	_expect(not skipping.is_finished(), "a hold of 60 percent has not skipped")
	skipping._process(skipping.skip_hold_seconds * 0.5)
	_expect(skipping.is_finished() and finished_count == 1, "a full hold skips the roll")
	skipping.queue_free()

	# --- A tap of Confirm does not skip: it needs the hold ---
	finished_count = 0
	var tapped := _show(scene, _small_roll())
	await process_frame
	tapped._unhandled_input(_confirm(true))
	tapped._process(0.05)
	tapped._unhandled_input(_confirm(false))
	for _step in range(5):
		tapped._process(0.05)
	_expect(not tapped.is_finished(), "a tap does not skip")
	tapped.queue_free()

	# --- With no data given it shows the real credits ---
	finished_count = 0
	var real := _show(scene, null)
	await process_frame
	var real_texts := _texts_of(real)
	_expect(real.definition != null and real.definition == ContentDb.credits(), "with no data given the screen reads content/story/credits.tres")
	_expect("The Unbound Pawn" in real_texts and "Design, story and art" in real_texts and "Made with" in real_texts and "Licenses" in real_texts, "the real roll has the title, who made the game, what it is made with and the licences")
	_expect("Godot Engine 4.6" in real_texts and "Godot Engine - MIT" in real_texts, "it credits the engine, and its licence")
	_expect(real_texts.size() >= 10, "and the licence text (%d lines in all)" % real_texts.size())
	real.queue_free()
	finish()


func _show(scene: PackedScene, definition: CreditsDefinition) -> CreditsScreen:
	var screen := scene.instantiate() as CreditsScreen
	screen.definition = definition
	screen.finished.connect(func() -> void: finished_count += 1)
	root.add_child(screen)
	screen.set_process(false)
	return screen


func _small_roll() -> CreditsDefinition:
	var made_by := CreditsSection.new()
	made_by.heading = "Made by"
	made_by.lines = PackedStringArray(["Ada", "Ben"])
	var fine_print := CreditsSection.new()
	fine_print.heading = "Fine print"
	fine_print.lines = PackedStringArray(["No warranty."])
	fine_print.fine_print = true
	var roll := CreditsDefinition.new()
	roll.game_title = "A Small Game"
	roll.sections = [made_by, fine_print]
	roll.closing_line = "Thank you for playing."
	roll.scroll_pixels_per_second = 100.0
	return roll


## The texts of the labels in the roll, top to bottom.
func _texts_of(screen: CreditsScreen) -> Array[String]:
	var texts: Array[String] = []
	for child in screen.roll.get_children():
		if child is Label:
			texts.append((child as Label).text)
	return texts


func _labels_by_text(screen: CreditsScreen) -> Dictionary:
	var by_text := {}
	for child in screen.roll.get_children():
		if child is Label:
			by_text[(child as Label).text] = child
	return by_text


func _confirm(pressed: bool) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = &"ui_accept"
	event.pressed = pressed
	return event
