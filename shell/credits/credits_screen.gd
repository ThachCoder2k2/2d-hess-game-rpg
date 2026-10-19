class_name CreditsScreen
extends Control

## The credits roll (docs/game-base-plan.md 8.8, 9.2): the game's title, then each block of the credits data
## (`content/story/credits.tres`, a CreditsDefinition: who made the game, what it is made with, the licences
## generated from THIRD_PARTY_NOTICES.md), scrolling up the screen at the data's speed. Holding Confirm skips it.
## It ends when the last line has left the screen or the skip is complete, and says so through `finished`; whoever
## owns the screen (AppRoot, through GameFlow) goes back to the title. It shows data and decides nothing.
##
## The Confirm hold is read from the events the screen receives (the engine's ui_accept, keyboard or pad), not
## from the Input singleton: only the InputPoller reads that. Until the text pipeline (M4) moves the words to
## `CREDIT_` keys, the data holds the English text.

## The roll ended or the player skipped it.
signal finished

const TITLE_FONT_SIZE := 28
const HEADING_FONT_SIZE := 16
const LINE_FONT_SIZE := 12
const FINE_PRINT_FONT_SIZE := 8
const HEADING_COLOR := Color(0.945098, 0.909804, 0.823529, 1)
const LINE_COLOR := Color(0.78, 0.76, 0.7, 1)
const FINE_PRINT_COLOR := Color(0.55, 0.53, 0.5, 1)
## Pixels between two lines, and the extra gap before a heading and for an empty line.
const LINE_GAP := 4
const SECTION_GAP := 28
const EMPTY_LINE_HEIGHT := 8

## The viewport clips what scrolls out of it.
@export var clip: Control
## The column the lines are put in; the roll scrolls by moving it up.
@export var roll: VBoxContainer
@export var skip_hint_label: Label
## Fills while Confirm is held; full means skipped.
@export var skip_progress_bar: ProgressBar
## The width of the column of text.
@export_range(200, 600, 10, "suffix:px") var column_width := 400
## How long Confirm is held to skip the roll.
@export_range(0.2, 5.0, 0.1, "suffix:s") var skip_hold_seconds := 1.0

## The roll to show. Null reads content/story/credits.tres when the screen starts.
var definition: CreditsDefinition = null

var _is_finished := false
var _confirm_is_held := false
var _confirm_held_seconds := 0.0
var _scroll_speed := 24.0


func _ready() -> void:
	if definition == null:
		definition = ContentDb.credits()
	_scroll_speed = definition.scroll_pixels_per_second if definition != null else 24.0
	_build_roll()
	var screen_size := get_viewport_rect().size
	roll.position = Vector2((screen_size.x - column_width) / 2.0, screen_size.y)
	skip_progress_bar.max_value = 1.0
	skip_progress_bar.value = 0.0
	skip_progress_bar.visible = false


## Whether the roll has ended or was skipped.
func is_finished() -> bool:
	return _is_finished


## 0 to 1: how far the Confirm hold has come.
func skip_progress() -> float:
	return clampf(_confirm_held_seconds / skip_hold_seconds, 0.0, 1.0)


func _process(delta: float) -> void:
	if _is_finished:
		return
	roll.position.y -= _scroll_speed * delta
	if _confirm_is_held:
		_confirm_held_seconds += delta
	skip_progress_bar.value = skip_progress()
	skip_progress_bar.visible = _confirm_held_seconds > 0.0
	if skip_progress() >= 1.0 or roll.position.y + maxf(roll.size.y, roll.get_combined_minimum_size().y) <= 0.0:
		_finish()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_accept", false):
		_confirm_is_held = true
	elif event.is_action_released(&"ui_accept"):
		_confirm_is_held = false
		_confirm_held_seconds = 0.0


func _finish() -> void:
	_is_finished = true
	finished.emit()


## Lays the data out in the column: the title, then per block its heading and lines, then the closing line.
func _build_roll() -> void:
	for child in roll.get_children():
		child.queue_free()
	if definition == null:
		return
	roll.add_theme_constant_override(&"separation", LINE_GAP)
	_add_label(definition.game_title, TITLE_FONT_SIZE, HEADING_COLOR)
	for section in definition.sections:
		if section == null:
			continue
		_add_gap(SECTION_GAP)
		_add_label(section.heading, HEADING_FONT_SIZE, HEADING_COLOR)
		for line in section.lines:
			if line.is_empty():
				_add_gap(EMPTY_LINE_HEIGHT)
			elif section.fine_print:
				_add_label(line, FINE_PRINT_FONT_SIZE, FINE_PRINT_COLOR)
			else:
				_add_label(line, LINE_FONT_SIZE, LINE_COLOR)
	if not definition.closing_line.is_empty():
		_add_gap(SECTION_GAP)
		_add_label(definition.closing_line, HEADING_FONT_SIZE, HEADING_COLOR)


func _add_label(text: String, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(column_width, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	roll.add_child(label)


func _add_gap(height: int) -> void:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(column_width, height)
	roll.add_child(gap)
