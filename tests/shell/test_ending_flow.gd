extends UnboundTest

## The ending (docs/game-base-plan.md 8.8, 9.1, M5 step 2): the Desk's one door that ends the run -> GameFlow's ending state ->
## the ending cards -> the credits -> the title with the completed mark. Three parts:
##   1. the data: content/story/endings/ending.tres (an Ending of EndingCards) validates, every card has an English row, and
##      a broken ending is named;
##   2. the screen alone: a card fades in, holds and fades out; Confirm moves it on; the screen says `finished` once, after the last;
##   3. the whole way through the real scene: the hero walks across the Desk of e1_morning_desk onto the door at its far end,
##      the flow reaches the ending (the `completed` mark is written), the cards play, the credits roll, the title shows the mark.

const Support := preload("res://tests/bridge/bridge_support.gd")
const ShellSupport := preload("res://tests/shell/shell_support.gd")
const SUITE_NAME := "ending_flow"
const E1 := &"e1_morning_desk"
const ENDING_SCREEN_SCENE := "res://shell/ending/ending_screen.tscn"

## The fade the suite uses after the boot, in seconds.
const QUICK_FADE_SECONDS := 0.04

var finished_count := 0


func _init() -> void:
	suite_title = "ENDING FLOW TEST"
	watchdog_seconds = 55.0
	call_deferred("_run")


func _run() -> void:
	_check_the_data()
	await _check_the_screen_alone()
	await _check_the_whole_way_through()


# --------------------------------------------------------------------------- 1. the data
func _check_the_data() -> void:
	var ending := ContentDb.ending()
	_expect(ending != null and ending.validate().is_empty(), "content/story/endings/ending.tres is an Ending that passes its own validate()")
	if ending == null:
		return
	_expect(ending.cards.size() >= 3 and ending.total_seconds() >= 10.0, "it has at least three cards and holds the image for ten seconds or more (%d cards, %.1f s): the plan's held ending, as cards" % [ending.cards.size(), ending.total_seconds()])
	var every_card_has_words := true
	for card in ending.cards:
		every_card_has_words = every_card_has_words and TextService.has_key(card.text_key) and TextService.t(card.text_key) != card.text_key
	_expect(every_card_has_words, "every card's key has an English row (an END_ row of story.po)")
	_expect(ContentDb.world().has_zone(ending.post_game_zone), "post_game_zone names a room of the world (%s)" % ending.post_game_zone)
	_expect(ContentDb.validate_cross_refs().is_empty(), "ContentDb.validate_cross_refs() finds nothing wrong with the ending or any other content")

	var empty_ending := Ending.new()
	_expect(_any_contains(empty_ending.validate(), "The ending has no cards"), "an ending with no cards is reported")
	var broken := Ending.new()
	var card_without_key := EndingCard.new()
	card_without_key.text_key = "Morning."
	var short_card := EndingCard.new()
	short_card.text_key = "END_CARD_X"
	short_card.hold_seconds = 0.2
	broken.cards = [card_without_key, short_card, null]
	broken.post_game_zone = &"Not A Room"
	var problems := broken.validate()
	_expect(_any_contains(problems, "needs a text key that starts with END_") and _any_contains(problems, "is on screen at least a second") and _any_contains(problems, "empty card slot") and _any_contains(problems, "must be a room id"), "a card whose key is words, a card that is on screen under a second, an empty slot and a post-game room that is no room id are each reported")
	var unknown_words := Ending.new()
	var unknown_card := EndingCard.new()
	unknown_card.text_key = "END_CARD_NOBODY_WROTE_THIS"
	unknown_words.cards = [unknown_card]
	_expect(unknown_words.validate().is_empty() and not TextService.has_key(unknown_card.text_key), "(a card key nobody wrote passes the data's own check; the cross-reference check above is what catches it)")


# --------------------------------------------------------------------------- 2. the screen alone
func _check_the_screen_alone() -> void:
	var screen := (load(ENDING_SCREEN_SCENE) as PackedScene).instantiate() as EndingScreen
	screen.set_process(false)
	root.add_child(screen)
	await process_frame
	var ending := ContentDb.ending()
	var first := ending.cards[0]
	_expect(screen.definition == ending and screen.card_index() == 0, "the screen reads the ending and shows card 0")
	_expect(screen.card_label.text == TextService.t(first.text_key) and screen.card_alpha() == 0.0, "the line is the card's words, not yet visible")
	screen.finished.connect(func() -> void: finished_count += 1)

	screen.advance(first.fade_seconds * 0.5)
	_expect(is_equal_approx(screen.card_alpha(), 0.5), "halfway through the fade-in the line is half visible (%.2f)" % screen.card_alpha())
	screen.advance(first.fade_seconds * 0.5 + first.hold_seconds * 0.5)
	_expect(screen.card_alpha() == 1.0, "during the hold it is fully visible")
	screen.advance(first.hold_seconds * 0.5 + first.fade_seconds * 0.5)
	_expect(is_equal_approx(screen.card_alpha(), 0.5) and screen.card_index() == 0, "halfway through the fade-out it is half visible, still the same card")
	screen.advance(first.fade_seconds * 0.5 + 0.01)
	_expect(screen.card_index() == 1 and screen.card_alpha() == 0.0 and screen.card_label.text == TextService.t(ending.cards[1].text_key), "when the fade-out is over the next card begins")

	# Confirm: the first press ends the hold, the second moves to the next card.
	screen.advance(ending.cards[1].fade_seconds)
	screen.skip_card()
	_expect(screen.card_index() == 1 and screen.card_alpha() == 1.0 and not screen.is_finished(), "Confirm during the hold starts the fade-out (the card is still on screen)")
	screen.skip_card()
	_expect(screen.card_index() == 2, "Confirm during the fade-out shows the next card at once")
	var press := InputEventAction.new()
	press.action = &"ui_accept"
	press.pressed = true
	screen._unhandled_input(press)
	screen._unhandled_input(press)
	_expect(screen.card_index() == 3, "the engine's ui_accept press is what skips (two presses: the hold, then the fade-out)")

	_expect(finished_count == 0, "the screen has not finished while a card remains")
	screen.skip_card()
	screen.skip_card()
	_expect(screen.is_finished() and finished_count == 1 and screen.card_index() == -1, "after the last card the screen is finished, and has said so once")
	screen.advance(100.0)
	screen.skip_card()
	_expect(finished_count == 1, "nothing more is said once it is finished")
	screen.queue_free()

	# An ending with no card ends at once rather than hanging on a black screen.
	var empty_screen := (load(ENDING_SCREEN_SCENE) as PackedScene).instantiate() as EndingScreen
	empty_screen.definition = Ending.new()
	empty_screen.set_process(false)
	var empty_finishes := [0]
	empty_screen.finished.connect(func() -> void: empty_finishes[0] += 1)
	root.add_child(empty_screen)
	await process_frame
	_expect(empty_screen.is_finished() and empty_finishes[0] == 1, "an ending with no cards finishes at once")
	empty_screen.queue_free()


# --------------------------------------------------------------------------- 3. the whole way through
func _check_the_whole_way_through() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	var app := await ShellSupport.boot_app(self)
	var flow := app.game_flow
	app.transition.default_fade_seconds = QUICK_FADE_SECONDS
	var title := ShellSupport.title_of(app)
	title.new_game_button.pressed.emit()
	await app.until_settled()
	var game := ShellSupport.game_of(app)
	if not _expect(game != null, "setup: New Game starts the game"):
		Support.end_suite(self, save_service)
		return
	ShellSupport.hold_the_game_still(app)
	_expect(not save_service.call("is_completed"), "setup: the game is not completed yet")

	# The hero comes into the Desk (the way in is the Black King's door; here the trip is asked for directly).
	await Support.travel_to(game, E1, &"from_ubb")
	_expect(game.get("current_zone_id") == E1 and flow.state == GameFlow.State.PLAYING, "the hero stands on the Desk and the game is still playing")
	var room: Node = game.get("current_room")
	var door := Support.exit_cell(game, room, &"")
	_expect(door != Vector2i(-999, -999) and Support.ecs_of(game).grid.exit_by_cell[door].get("ends_run", false) == true, "the Desk has one door that ends the run, baked on the far side of the board")
	_expect(Support.entry_cell(game, room, &"from_ubb") != Vector2i(-999, -999) and Support.exit_cell(game, room, &"h1_chess_rug_hub") == Vector2i(-999, -999), "and no door back: the way in is a one-way edge")

	# Walking onto it, on foot, ends the run.
	var walked := await Support.walk_to_cell(self, game, door)
	_expect(walked and flow.state == GameFlow.State.ENDING, "the hero walks across the Desk onto the door and the flow reaches the ending")
	_expect(save_service.call("is_completed"), "reaching the ending writes the completed mark")
	_expect(not Support.player_tag(game).control_enabled, "the hero's control goes off")
	await app.until_settled()
	var ending_screen := app.screen as EndingScreen
	_expect(ending_screen != null and ending_screen.definition == ContentDb.ending(), "AppRoot shows the ending cards in place of the room")
	if ending_screen == null:
		Support.end_suite(self, save_service)
		return

	# The cards play; the flow goes on to the credits.
	var cards_seen: Array[int] = []
	var guard := 0
	while not ending_screen.is_finished() and guard < 200:
		if ending_screen.card_index() not in cards_seen:
			cards_seen.append(ending_screen.card_index())
		ending_screen.advance(0.5)
		guard += 1
	_expect(cards_seen == range(ContentDb.ending().cards.size()), "every card was shown, in order (%s)" % [cards_seen])
	_expect(flow.state == GameFlow.State.CREDITS, "after the last card the flow goes on to the credits")
	await app.until_settled()
	var credits := app.screen as CreditsScreen
	_expect(credits != null, "and the credits roll")
	if credits != null:
		credits.finished.emit()
		await app.until_settled()
	var finished_title := ShellSupport.title_of(app)
	_expect(flow.state == GameFlow.State.TITLE and finished_title != null and not finished_title.emptied_square.visible, "the roll ends on the title, which shows the post-game board: one square is empty")
	_expect(save_service.call("is_completed"), "and the completed mark is still written")
	Support.end_suite(self, save_service)


func _any_contains(sentences: PackedStringArray, fragment: String) -> bool:
	for sentence in sentences:
		if sentence.contains(fragment):
			return true
	return false
