extends RefCounted

## Shared fixture for the suites that boot AppRoot, the project's main scene (M4). NOT a test (the runner only
## collects test_*.gd) and deliberately without a class_name, so it needs no import pass. Suites load it with
##   const ShellSupport := preload("res://tests/shell/shell_support.gd")
## and isolate the save first, exactly as the bridge suites do (Support.install_isolated_save_service):
## tests/architecture/test_suites_isolate_the_save.gd holds that for boot_app() too.
##
## AppRoot is booted with its quit switched off and the real transition layer on, so a suite sees the same
## fades the player sees. A suite that does not care about the fade sets `app.transition.default_fade_seconds`
## to 0 after booting.

const Support := preload("res://tests/bridge/bridge_support.gd")
const SaveSupport := preload("res://tests/support/save_test_support.gd")

const T1 := &"t1_white_kings_fall"
const T4 := &"t4_broken_rule_yard"
const B1 := &"b1_black_pawn_captain"

## Real-time ceiling for waits that depend on fades and tweens.
const REAL_TIME_WAIT_CAP_MSEC := 8000


## Instantiates AppRoot under the root as the current scene and returns it once the title is on screen.
static func boot_app(suite: UnboundTest) -> AppRoot:
	var paths := TestPaths.new(suite)
	var app := paths.load_scene(paths.main_scene()).instantiate() as AppRoot
	app.quits_the_tree = false
	var tree: SceneTree = suite
	tree.root.add_child(app)
	tree.current_scene = app
	await app.until_settled()
	return app


## Waits (real engine frames) until `condition` is true or the cap passes. Returns whether it became true.
static func wait_until(tree: SceneTree, condition: Callable) -> bool:
	var started := Time.get_ticks_msec()
	while not condition.call() and Time.get_ticks_msec() - started < REAL_TIME_WAIT_CAP_MSEC:
		await tree.process_frame
	return bool(condition.call())


## The screen AppRoot shows, as a GameRoot (null when it is another screen).
static func game_of(app: AppRoot) -> GameRoot:
	return app.screen as GameRoot


## The title screen AppRoot shows (null when it is another screen).
static func title_of(app: AppRoot) -> TitleScreen:
	return app.screen as TitleScreen


## Stops the game screen ticking by itself, so a suite drives it with Support.pump (the bridge suites' way).
static func hold_the_game_still(app: AppRoot) -> void:
	var game := game_of(app)
	if game != null:
		game.set_process(false)


## Writes `data` to the isolated service's slot as a success event would, so a relaunch can read it.
static func plant_run(save_service: Node, data: SaveData) -> void:
	save_service.call("new_game", 0)
	save_service.set("state", data)
	save_service.call("write_slot", 0, data)
	save_service.call("configure", save_service.call("root_directory"))


## A run that is in T4 on the `from_b1` entry, whose checkpoint is B1, with T3 cleared and the sword in hand:
## where the owner guide's step 5 leaves the player. Its saved room and its checkpoint differ on purpose.
static func run_in_t4_with_b1_checkpoint() -> SaveData:
	var data := SaveData.new()
	data.room_id = T4
	data.room_entry_id = &"from_b1"
	data.checkpoint_zone_id = B1
	data.checkpoint_entry_id = &"west_entry"
	data.cleared_room_ids = {"t3_first_pawn_clash": true}
	data.play_time_seconds = 3725.0
	data.saved_at_unix = 1760000000
	data.add_unlock(&"wooden_sword")
	return data


## A system that counts the ticks the world gives it. A frozen world skips every system that does not answer
## runs_while_frozen(), so the count is exactly how many ticks the rules of the game got.
class TickCounter extends EcsSystem:
	var ticks := 0

	func tick(_delta: float) -> void:
		ticks += 1


## Adds a TickCounter to the game's live world (the next room's world is a new one, and has none).
static func count_ticks_of(game: GameRoot) -> TickCounter:
	var counter := TickCounter.new()
	Support.ecs_of(game).add_system(counter)
	return counter


## What every enemy of the room is doing, as text: its cell, its AI state and how long it has been in it. Two
## readings differ when any enemy moved or its AI clock ran.
static func enemy_picture(game: GameRoot) -> String:
	var ecs := Support.ecs_of(game)
	var lines: Array[String] = []
	for enemy_id in ecs.query([EcsComponents.ENEMY_AI]):
		var ai: EcsComponents.EnemyAI = ecs.get_component(enemy_id, EcsComponents.ENEMY_AI)
		lines.append("%d|%s|%d|%.3f" % [enemy_id, str(ecs.grid.cell_by_entity.get(enemy_id, Vector2i.ZERO)), ai.state, ai.state_time_left])
	lines.sort()
	return ";".join(PackedStringArray(lines))


## Presses a key the way a player does: down for `frames_down` frames, then up. The press is sent at the START of a
## frame, before the nodes' _process, as the OS delivers input: the engine's "just pressed" is only true for the
## rest of the frame the press happened in, and a suite that resumes after a timer is resumed at the END of a frame.
static func tap_key(tree: SceneTree, keycode: Key, frames_down := 2) -> void:
	await tree.process_frame
	Support.send_key(keycode, true)
	for _frame in frames_down:
		await tree.process_frame
	Support.send_key(keycode, false)
	await tree.process_frame


## Waits `seconds` of real time with the tree paused or not (the timer ignores the pause).
static func wait_real_seconds(tree: SceneTree, seconds: float) -> void:
	await tree.create_timer(seconds, true, false, true).timeout


## Plants the run of run_in_t4_with_b1_checkpoint, boots the app, Continues into T4 and returns the app with the game
## on screen (fades shortened). The game is left ticking on its own.
static func boot_into_t4(suite: UnboundTest, save_service: Node) -> AppRoot:
	plant_run(save_service, run_in_t4_with_b1_checkpoint())
	var app := await boot_app(suite)
	app.transition.default_fade_seconds = 0.04
	var title := title_of(app)
	if title != null:
		title.continue_button.pressed.emit()
		await app.until_settled()
	return app
