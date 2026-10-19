class_name AppRoot
extends Node

## The main scene (docs/game-base-plan.md 9.1, D-26): the one node that stays while the game is open. It owns the
## GameFlow state machine, the persistent transition layer, the music and the overlay that survives every
## screen (the autosave tick), and it swaps the screen under `screen_host` instead of calling change_scene, so the
## music and the fade survive a screen change. The screens are scenes the editor wires in here:
##
##   title   (shell/title)     New Game, Continue, Settings, Credits, Quit
##   game    (shell/game_root) the room; GameRoot builds the world and ticks it, and stays testable alone
##   credits (shell/credits)   the roll
##
## AppRoot shows; GameFlow decides. A button on the title calls a GameFlow request (New Game and Continue go through
## SaveService there); the flow's `state_changed` is what changes the screen: fade to black, free the old screen,
## build the new one, fade back. Screen changes run one after the other in the order they were asked, so a quick
## double request can never build two screens or leave the fade half done. A pause is not a screen change: the tree
## is paused at once and the pause menu (a later M4 step) is laid in the overlay, which keeps running.
##
## The save facts it shows: the SaveService autoload's `autosaved` signal flashes the tick; the title reads the
## slot for Continue, the card and the corrupt-save notice (TitleSummary); a Continue that had to fall back to the
## previous save says so on the status line of the room.

const SaveServiceScript := preload("res://shell/save/save_service.gd")

## The seconds of the fade to black and back around a room being rebuilt after a death.
const RESPAWN_FADE_SECONDS := 0.18

## A screen change finished and nothing else is waiting.
signal settled
## Quit was chosen on the title. The app ends unless `quits_the_tree` is off (a test).
signal quit_requested
## Settings was chosen on the title (the settings screen is wired in by a later step; with no scene assigned the
## button is shown disabled and this is never emitted).
signal settings_requested

@export var title_scene: PackedScene
@export var game_scene: PackedScene
@export var credits_scene: PackedScene
## The settings screen. Empty until it exists: the title then shows Settings disabled.
@export var settings_scene: PackedScene
## The node the current screen is a child of.
@export var screen_host: Node
@export var transition: TransitionLayer
@export var autosave_indicator: AutosaveIndicator
## Whether Quit ends the program. A test turns it off.
@export var quits_the_tree := true

var game_flow := GameFlow.new()
## The screen on show (a TitleScreen, a GameRoot or a CreditsScreen), null between two screens.
var screen: Node = null
var save_service: SaveServiceScript = null

var _queued_steps: Array[Callable] = []
var _running_steps := false


func _ready() -> void:
	save_service = get_node_or_null("/root/SaveService") as SaveServiceScript
	game_flow.save_service = save_service
	game_flow.state_changed.connect(_on_state_changed)
	game_flow.before_respawn = _fade_out_before_respawn
	game_flow.after_respawn = _fade_in_after_respawn
	if save_service != null:
		save_service.autosaved.connect(_on_autosaved)
	transition.cover()
	game_flow.finish_boot()


## True when no screen change is running or waiting.
func is_settled() -> bool:
	return not _running_steps and _queued_steps.is_empty()


## Returns when every screen change asked so far has finished.
func until_settled() -> void:
	while not is_settled():
		await settled


func _on_state_changed(previous: GameFlow.State, current: GameFlow.State) -> void:
	get_tree().paused = current == GameFlow.State.PAUSED
	match current:
		GameFlow.State.TITLE:
			_queue_step(_show_title)
		GameFlow.State.PLAYING:
			if previous == GameFlow.State.TITLE:
				_queue_step(_show_game)
		GameFlow.State.CREDITS:
			_queue_step(_show_credits)


func _queue_step(step: Callable) -> void:
	_queued_steps.append(step)
	if not _running_steps:
		_run_queued_steps()


func _run_queued_steps() -> void:
	_running_steps = true
	while not _queued_steps.is_empty():
		var step: Callable = _queued_steps.pop_front()
		await step.call()
	_running_steps = false
	settled.emit()


func _show_title() -> void:
	await transition.fade_out()
	_free_screen()
	var title := title_scene.instantiate() as TitleScreen
	title.configure(TitleSummary.from_save(save_service, _version(), game_flow.slot), settings_scene != null)
	title.new_game_chosen.connect(game_flow.start_new_game)
	title.continue_chosen.connect(_on_continue_chosen)
	title.settings_chosen.connect(settings_requested.emit)
	title.credits_chosen.connect(game_flow.show_credits)
	title.quit_chosen.connect(_on_quit_chosen)
	_put_screen(title)
	await transition.fade_in()


func _show_game() -> void:
	await transition.fade_out()
	_free_screen()
	var game := game_scene.instantiate() as GameRoot
	game.game_flow = game_flow
	_put_screen(game)
	var notice := String(TitleSummary.NOTICE_TEXT_BY_KEY.get(game_flow.load_notice_key, ""))
	if not notice.is_empty():
		game.message_bridge.say(notice)
	await transition.fade_in()


func _show_credits() -> void:
	await transition.fade_out()
	_free_screen()
	var credits := credits_scene.instantiate() as CreditsScreen
	credits.finished.connect(game_flow.finish_credits)
	_put_screen(credits)
	await transition.fade_in()


func _put_screen(new_screen: Node) -> void:
	screen = new_screen
	screen_host.add_child(new_screen)


## Takes the screen out of the tree at once (its processing stops now, not at the end of the frame) and frees it.
func _free_screen() -> void:
	if is_instance_valid(screen):
		screen.get_parent().remove_child(screen)
		screen.queue_free()
	screen = null


func _on_continue_chosen() -> void:
	if not game_flow.continue_game() and screen is TitleScreen:
		# The save went away or turned unreadable since the title was drawn: show what is really there.
		(screen as TitleScreen).configure(TitleSummary.from_save(save_service, _version(), game_flow.slot), settings_scene != null)


func _on_quit_chosen() -> void:
	quit_requested.emit()
	if quits_the_tree:
		get_tree().quit()


func _on_autosaved(_slot: int, _reason: StringName) -> void:
	autosave_indicator.flash()


## The fade to black that a room rebuild waits for (GameFlow.before_respawn).
func _fade_out_before_respawn(_reason: StringName) -> void:
	await transition.fade_out(RESPAWN_FADE_SECONDS)


## The fade back in once the room was rebuilt (GameFlow.after_respawn); not waited for.
func _fade_in_after_respawn(_reason: StringName) -> void:
	transition.fade_in(RESPAWN_FADE_SECONDS)


func _version() -> String:
	return String(ProjectSettings.get_setting("application/config/version", ""))
