class_name EndingScreen
extends Control

## The ending, as the player meets it between the last boss and the credits (docs/game-base-plan.md 8.8, 9.1): the
## cards of `content/story/endings/ending.tres` (an Ending), one line at a time on a dark screen, each fading in,
## holding and fading out. Confirm moves a card on (the first press ends the hold, a press during the fade-out goes
## to the next card at once). It ends after the last card and says so through `finished`; whoever owns the screen
## (AppRoot, through GameFlow) goes on to the credits. It shows data and decides nothing.
##
## The timeline is a clock that `_process` advances by the frame time and that `advance()` advances by any amount,
## so a suite walks the whole ending in a moment. The Confirm press is read from the events the screen receives
## (the engine's ui_accept), not from the Input singleton: only the InputPoller reads that. The lines are TEXT KEYS
## (`END_` rows of story.po) and follow a language change.

## The last card has faded out.
signal finished

## The width of the column of text.
@export_range(200, 600, 10, "suffix:px") var column_width := 440
## The line that is on screen.
@export var card_label: Label
## "Confirm to go on", at the bottom.
@export var skip_hint_label: Label

## The cards to show. Null reads content/story/endings/ending.tres when the screen starts.
var definition: Ending = null

## Keeps the line in the player's language.
var _live_text: LiveText = null
## Which card is on screen (an index into definition.cards), -1 before the first.
var _card_index := -1
## Seconds since the card on screen began to fade in.
var _card_seconds := 0.0
var _is_finished := false


func _ready() -> void:
	if definition == null:
		definition = ContentDb.ending()
	_live_text = LiveText.new()
	add_child(_live_text)
	card_label.custom_minimum_size = Vector2(column_width, 0)
	card_label.modulate.a = 0.0
	if definition == null or definition.cards.is_empty():
		_finish()
		return
	_show_next_card()


## True once the last card has faded out.
func is_finished() -> bool:
	return _is_finished


## The index of the card on screen, -1 before the first and after the last.
func card_index() -> int:
	return _card_index


## The opacity of the line right now: 0 to 1 over the card's fade-in, 1 while it holds, back to 0 over its fade-out.
func card_alpha() -> float:
	return card_label.modulate.a


func _process(delta: float) -> void:
	advance(delta)


## Moves the clock of the card on screen on by `seconds`, and on to the next card (or the end) when its time is up.
func advance(seconds: float) -> void:
	if _is_finished or definition == null or _card_index < 0:
		return
	var card := definition.cards[_card_index]
	_card_seconds += seconds
	if _card_seconds >= card.total_seconds():
		_show_next_card()
		return
	card_label.modulate.a = _alpha_at(card, _card_seconds)


## Confirm: the first press ends the hold of the card (it starts to fade out), a press while it fades out shows the next
## card at once.
func skip_card() -> void:
	if _is_finished or definition == null or _card_index < 0:
		return
	var card := definition.cards[_card_index]
	var fade_out_starts_at := card.fade_seconds + card.hold_seconds
	if _card_seconds < fade_out_starts_at:
		_card_seconds = fade_out_starts_at
		card_label.modulate.a = _alpha_at(card, _card_seconds)
	else:
		_show_next_card()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_accept", false):
		skip_card()


func _show_next_card() -> void:
	_card_index += 1
	_card_seconds = 0.0
	if _card_index >= definition.cards.size():
		_card_index = -1
		card_label.modulate.a = 0.0
		_finish()
		return
	_live_text.set_text(card_label, definition.cards[_card_index].text_key)
	card_label.modulate.a = _alpha_at(definition.cards[_card_index], 0.0)


func _finish() -> void:
	if _is_finished:
		return
	_is_finished = true
	finished.emit()


static func _alpha_at(card: EndingCard, seconds: float) -> float:
	var fade := maxf(card.fade_seconds, 0.001)
	if seconds < card.fade_seconds:
		return clampf(seconds / fade, 0.0, 1.0)
	var fade_out_starts_at := card.fade_seconds + card.hold_seconds
	if seconds <= fade_out_starts_at:
		return 1.0
	return clampf(1.0 - (seconds - fade_out_starts_at) / fade, 0.0, 1.0)
