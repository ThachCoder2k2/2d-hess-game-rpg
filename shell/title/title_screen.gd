class_name TitleScreen
extends Control

## The title screen (docs/game-base-plan.md 9.2): the game's name over a small rug board with one standing pawn,
## and the menu: New Game, Continue (only when the slot holds a readable save), Settings, Credits, Quit. It shows
## what AppRoot hands it (a TitleSummary and whether a settings screen exists) and says which button was chosen
## through a signal; it opens no screen and writes no save itself. Both the buttons and the keyboard or pad
## (the engine's ui_up, ui_down and ui_accept) work, and the first button takes focus.
##
## New Game over a used slot asks first, through the shared ConfirmPanel: the old run is replaced. After the
## game was finished one square of the board is empty (the profile's `completed` mark, which a New Game keeps).
## The picture is a stand-in drawn from nodes of the scene and the hero's body picture at its own size, so
## the owner restyles it in the editor or replaces the pieces it is made of; nothing here is scaled.
##
## The words are keys (docs/game-base-plan.md 8.9). The buttons and the logo hold theirs in the scene and the engine
## translates them; the card, the notice and the version come from the TitleSummary in the language of the moment and
## are written again when the language changes.

## The player chose New Game (and confirmed it, when a save would be replaced).
signal new_game_chosen
## The player chose Continue.
signal continue_chosen
## The player chose Settings.
signal settings_chosen
## The player chose Credits.
signal credits_chosen
## The player chose Quit.
signal quit_chosen

## The text keys of what the New Game confirm says and offers.
const CONFIRM_MESSAGE_KEY := "UI_TITLE_CONFIRM_NEW_GAME"
const CONFIRM_YES_KEY := "UI_TITLE_CONFIRM_NEW_GAME_YES"
const CONFIRM_NO_KEY := "UI_TITLE_CONFIRM_NEW_GAME_NO"

@export var new_game_button: Button
@export var continue_button: Button
@export var settings_button: Button
@export var credits_button: Button
@export var quit_button: Button
## The container of the five buttons; it is switched off while the confirm is up and after a choice.
@export var menu: Control
## The slot card under the menu ("Broken Rule Yard | 1h 05m played").
@export var card_label: Label
## The one-line notice (a damaged or newer save).
@export var notice_label: Label
@export var version_label: Label
@export var confirm_panel: ConfirmPanel
## The board square that is left empty once the game was finished.
@export var emptied_square: CanvasItem

var _summary := TitleSummary.new()
var _settings_available := false


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(func() -> void: _choose(continue_chosen))
	settings_button.pressed.connect(func() -> void: settings_chosen.emit())
	credits_button.pressed.connect(func() -> void: _choose(credits_chosen))
	quit_button.pressed.connect(func() -> void: _choose(quit_chosen))
	confirm_panel.confirmed.connect(func() -> void: _choose(new_game_chosen))
	confirm_panel.cancelled.connect(_on_confirm_cancelled)
	var live_text := LiveText.new()
	add_child(live_text)
	live_text.on_language_change(_on_language_changed)
	_show_summary()
	_focus_first_button()


## Hands the screen what it shows. Call it before the screen is added to the tree, or again later to refresh it.
## `settings_available` is false until a settings screen exists: the button is then shown disabled.
func configure(summary: TitleSummary, settings_available: bool) -> void:
	_summary = summary
	_settings_available = settings_available
	if is_node_ready():
		_show_summary()


## Whether the New Game question is on screen.
func is_confirming() -> bool:
	return confirm_panel.is_asking()


func _on_language_changed() -> void:
	_summary.refresh_texts()
	_show_summary()


func _show_summary() -> void:
	continue_button.visible = _summary.can_continue
	settings_button.disabled = not _settings_available
	card_label.text = _summary.card_text
	card_label.visible = _summary.can_continue
	notice_label.text = _summary.notice_text
	notice_label.visible = not _summary.notice_text.is_empty()
	version_label.text = _summary.version_text
	emptied_square.visible = not _summary.completed


func _focus_first_button() -> void:
	(continue_button if continue_button.visible else new_game_button).grab_focus()


func _on_new_game_pressed() -> void:
	if not _summary.can_continue:
		_choose(new_game_chosen)
		return
	menu.process_mode = Node.PROCESS_MODE_DISABLED
	confirm_panel.ask(CONFIRM_MESSAGE_KEY, CONFIRM_YES_KEY, CONFIRM_NO_KEY)


func _on_confirm_cancelled() -> void:
	menu.process_mode = Node.PROCESS_MODE_INHERIT
	new_game_button.grab_focus()


## A choice that leaves the title was made: the menu goes quiet (a second press cannot choose again while the
## screen fades) and the screen's owner is told. Settings opens over the title and so does not go through here.
func _choose(chosen: Signal) -> void:
	menu.process_mode = Node.PROCESS_MODE_DISABLED
	chosen.emit()
