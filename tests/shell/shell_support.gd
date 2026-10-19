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
