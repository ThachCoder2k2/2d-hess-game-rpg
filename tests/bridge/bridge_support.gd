extends RefCounted

## Shared fixture for the test_bridge_* characterization suites. NOT a test
## (the runner only collects test_*.gd) and deliberately without a class_name,
## so it needs no import pass and registers no global. Suites load it with
##   const Support := preload("res://tests/bridge/bridge_support.gd")
##
## The suites pin what the in-game scene (shell/game_root.gd and its bridges) does, so
## the split of game_root.gd into an EventRouter and bridges (M3b step 2) could not silently change
## travel, death, carry, persistence or Book behaviour. Nothing in here may change gameplay.
##
## Design notes shared by every suite:
## - The real shell/game_root.tscn is instantiated and made the tree's current
##   scene (a death or the restart key rebuilds its room through GameFlow, which used to
##   reload the whole scene).
## - game_root.gd's own _process is switched off after boot and driven by hand in
##   fixed steps (pump), so a run is deterministic and has no real-time races.
##   Only the fade tweens and the death timer use real engine time.
## - The SaveService autoload is replaced by a fresh instance of the same script,
##   pointed at a throwaway folder (user://test_saves/<suite>_<process>/) and
##   starting empty, so no suite writes the player's real save or inherits state
##   from it (tests/architecture/test_suites_isolate_the_save.gd holds that).
##
## Every suite extends UnboundTest, which supplies the checks, the 30 s watchdog
## (a script error inside a coroutine otherwise leaves Godot waiting forever) and
## the verdict line. The main scene's path comes from TestPaths, so the folder
## migration edits it in tests/support/paths.gd only.

const SaveSupport := preload("res://tests/support/save_test_support.gd")

## Delta handed to each manual main._process call. Smaller than a 0.18 s step.
const SIM_STEP_SECONDS := 0.05
## Real-time ceiling for waits that depend on tweens or timers.
const REAL_TIME_WAIT_CAP_MSEC := 6000

const MOVE_ACTIONS: Array[StringName] = [&"move_up", &"move_down", &"move_left", &"move_right"]


## Swaps the SaveService autoload for a fresh instance of its script that saves to a throwaway folder,
## and returns it. The real autoload node is only renamed and left idle (game_root.gd finds the service
## by node path, so the new node named SaveService is the one it uses).
static func install_isolated_save_service(tree: SceneTree, suite_name: String) -> Node:
	var real_autoload := tree.root.get_node_or_null("SaveService")
	if real_autoload != null:
		real_autoload.name = "SaveServiceBypassedByBridgeTest"
	var save_service := SaveSupport.new_service(SaveSupport.make_root("bridge_" + suite_name))
	save_service.name = "SaveService"
	tree.root.add_child(save_service)
	return save_service


## Deletes the throwaway save folder (every file the service wrote). Call once at the end of a suite,
## or to start a test over with no save at all.
static func remove_isolated_save(save_service: Node) -> void:
	SaveSupport.remove_root(String(save_service.call("root_directory")))


## The last call of a bridge suite: lets go of any held input action, deletes the
## throwaway saves, then prints the verdict and quits through UnboundTest.finish().
static func end_suite(suite: UnboundTest, save_service: Node) -> void:
	release_all_actions()
	remove_isolated_save(save_service)
	suite.finish()


## The run the save service holds in memory right now. Read it through here each time: the service
## replaces it (new game, load) rather than editing it.
static func run_of(save_service: Node) -> SaveData:
	return save_service.get("state")


## What a process that was quit and relaunched has: nothing in memory. The next game_root (or
## load_slot) reads the disk.
static func forget_the_run(save_service: Node) -> void:
	save_service.call("configure", save_service.call("root_directory"))


## Writes the active slot with the run as it is in memory, as a success event would (the file is the
## one the next relaunch reads).
static func write_the_run(save_service: Node) -> Error:
	return save_service.call("write_slot", save_service.get("active_slot"), save_service.get("state"))


## Instantiates the main scene under the root, makes it the current scene and
## switches its automatic _process off (see the design notes above).
static func boot_main(suite: UnboundTest) -> Node:
	var paths := TestPaths.new(suite)
	var main := paths.load_scene(paths.main_scene()).instantiate()
	var tree: SceneTree = suite
	tree.root.add_child(main)
	tree.current_scene = main
	# Two frames: the engine's frame counter only starts advancing after the
	# first one, and the input helpers rely on it to age "just pressed" flags.
	await tree.process_frame
	await tree.process_frame
	main.set_process(false)
	return main


## --- The scene's own state and entry points -----------------------------------
## Every suite reaches game_root's state and entry points through these, so when the scene moves
## one (M3b step 2 moved the trip, the carry, the room outcome and the Book into bridges) the call
## site changes here and nowhere else.


static func travel_in_progress(main: Node) -> bool:
	return main.get("zone_travel_bridge").travel_in_progress


## The Courage the carry waits with for the next boot (-1 = nothing is carried).
static func health_carry(main: Node) -> int:
	var snapshot: PlayerSnapshot = main.get("zone_travel_bridge").carried_player_snapshot
	return snapshot.courage_current if snapshot != null else -1


## Plants a carry as a trip would have left it (the hero as it is now, with `value` Courage), for the next
## boot to apply.
static func plant_health_carry(main: Node, value: int) -> void:
	var snapshot := PlayerSnapshot.capture(ecs_of(main), player_id_of(main))
	snapshot.courage_current = value
	main.get("zone_travel_bridge").carried_player_snapshot = snapshot


static func room_ending(main: Node) -> bool:
	return main.get("outcome_bridge").room_ending


static func set_room_ending(main: Node, value: bool) -> void:
	main.get("outcome_bridge").room_ending = value


## How many enemies the room began with, as the HUD's snapshot says (ObjectiveSystem keeps the count).
static func total_enemies(main: Node) -> int:
	return ecs_of(main).hud_snapshot.room_enemies_total


## Gives the room that is running `objective` for its win condition, as if its scene had authored it:
## the objective is read from the room node when the world boots (EcsBoot), so a test that sets one on a
## room already booted puts it on the room node AND on the live world's room state.
static func set_room_objective(main: Node, objective: RoomObjective) -> void:
	main.get("current_room").set("objective", objective)
	for room_entity in ecs_of(main).query([RoomObjectiveState.KEY]):
		var state: RoomObjectiveState = ecs_of(main).get_component(room_entity, RoomObjectiveState.KEY)
		state.objective = objective


## Starts a zone trip the way the zone_exit event does and waits for it to finish. Called without
## `await` it returns at the first suspension, with the trip under way.
static func travel_to(main: Node, zone_id: StringName, entry_id: StringName) -> void:
	await main.get("zone_travel_bridge").travel_to(zone_id, entry_id)


## Rebuilds the room the hero is in without a trip (a boot with no pending travel).
static func reboot_zone(main: Node, entry_id: StringName) -> void:
	main.boot_zone(entry_id)


## The B key's handler, called directly.
static func toggle_book(main: Node) -> void:
	main.get("book_bridge").toggle()


## --- Reading the live simulation ------------------------------------------


static func ecs_of(main: Node) -> EcsWorld:
	return main.get("ecs")


## True when the world holds exactly the systems of ecs/schedule/, in the same order. This is
## what the old `systems.size() == 6` pins protected, without naming a count that every new
## system would change (docs/game-base-plan.md 14.1).
static func runs_the_schedule(world: EcsWorld) -> bool:
	var scheduled_scripts := Schedule.system_scripts()
	if world.systems.size() != scheduled_scripts.size():
		return false
	for index in scheduled_scripts.size():
		if world.systems[index].get_script() != scheduled_scripts[index]:
			return false
	return true


## Hands the events the world has queued to the scene's router, as the end of a frame does.
static func route_events(main: Node) -> void:
	main.get("router").route(ecs_of(main).drain_events())


static func player_id_of(main: Node) -> int:
	return int(main.get("player_id"))


static func player_cell(main: Node) -> Vector2i:
	var grid_pos: EcsComponents.GridPos = ecs_of(main).get_component(player_id_of(main), EcsComponents.GRID_POS)
	return grid_pos.cell


static func player_health(main: Node) -> EcsComponents.Health:
	return ecs_of(main).get_component(player_id_of(main), EcsComponents.HEALTH)


static func player_tag(main: Node) -> EcsComponents.PlayerTag:
	return ecs_of(main).get_component(player_id_of(main), EcsComponents.PLAYER_TAG)


static func player_combat(main: Node) -> EcsComponents.PlayerCombat:
	return ecs_of(main).get_component(player_id_of(main), EcsComponents.PLAYER_COMBAT)


static func player_move_state(main: Node) -> EcsComponents.MoveState:
	return ecs_of(main).get_component(player_id_of(main), EcsComponents.MOVE_STATE)


static func player_view_position(main: Node) -> Vector2:
	return (main.get("player_view") as Node2D).position


## Courage pips currently drawn by the HUD (the filled diamonds in the label).
static func hud_courage_pips(main: Node) -> int:
	var hud := main.get("hud") as GameHud
	return String(hud.courage_label.text).count("◆")


## Cell of the ZoneEntryMarker called entry_id inside zone_root, or (-999, -999).
static func entry_cell(main: Node, zone_root: Node, entry_id: StringName) -> Vector2i:
	for child in zone_root.get_children():
		var entry := child as ZoneEntryMarker
		if entry != null and entry.entry_id == entry_id:
			return ecs_of(main).grid.world_to_cell(entry.position)
	return Vector2i(-999, -999)


## Cell of the first ZoneExitMarker in zone_root that leads to target_zone, or (-999, -999).
static func exit_cell(main: Node, zone_root: Node, target_zone: StringName) -> Vector2i:
	for child in zone_root.get_children():
		var exit_marker := child as ZoneExitMarker
		if exit_marker != null and exit_marker.target_zone == target_zone:
			return ecs_of(main).grid.world_to_cell(exit_marker.position)
	return Vector2i(-999, -999)


## --- Driving the simulation ------------------------------------------------


## Runs main._process(SIM_STEP_SECONDS) enough times to cover `seconds`.
static func pump(main: Node, seconds: float) -> void:
	var steps := maxi(1, int(ceil(seconds / SIM_STEP_SECONDS)))
	for _i in range(steps):
		main._process(SIM_STEP_SECONDS)


## Pumps until condition() is true or max_seconds of simulated time pass.
## Returns whether the condition was met.
static func pump_until(main: Node, condition: Callable, max_seconds: float) -> bool:
	var steps := maxi(1, int(ceil(max_seconds / SIM_STEP_SECONDS)))
	for _i in range(steps):
		if condition.call():
			return true
		main._process(SIM_STEP_SECONDS)
	return bool(condition.call())


## Waits (real engine frames) until main finishes its zone travel. Returns
## false if it is still travelling after the real-time cap.
static func wait_for_travel(tree: SceneTree, main: Node) -> bool:
	var started := Time.get_ticks_msec()
	while travel_in_progress(main) and Time.get_ticks_msec() - started < REAL_TIME_WAIT_CAP_MSEC:
		await tree.process_frame
	return not travel_in_progress(main)


## Puts the hero on `cell` at rest (grid, GridPos, MoveState and the puppet view).
## A test-side shortcut for "the hero walked there"; the cell must be walkable.
static func teleport_player(main: Node, cell: Vector2i) -> bool:
	var ecs := ecs_of(main)
	var player_id := player_id_of(main)
	ecs.grid.unregister_entity(player_id)
	var placed := ecs.grid.register_entity(player_id, cell)
	var grid_pos: EcsComponents.GridPos = ecs.get_component(player_id, EcsComponents.GRID_POS)
	grid_pos.cell = cell
	var move := player_move_state(main)
	move.moving = false
	move.progress = 0.0
	move.from_cell = cell
	move.to_cell = cell
	(main.get("player_view") as Node2D).position = ecs.grid.cell_to_world(cell)
	return placed


## Queues one step for the hero through MoveIntent (the same component the
## input system writes) and pumps until the step has landed.
static func step_player(main: Node, direction: Vector2i) -> void:
	var intent: EcsComponents.MoveIntent = ecs_of(main).get_component(player_id_of(main), EcsComponents.MOVE_INTENT)
	intent.direction = direction
	pump(main, 0.45)


## Walks the hero through the real door cell that leads to target_zone: the
## hero is put next to the exit, stepped onto it in `direction`, and the whole
## bridge trip (event, fade, swap, boot) is awaited. False if the exit is
## missing, the approach cell is not walkable, or the trip never finishes.
static func walk_through_exit(tree: SceneTree, main: Node, target_zone: StringName, direction: Vector2i) -> bool:
	var door := exit_cell(main, main.get("current_room"), target_zone)
	if door == Vector2i(-999, -999) or not teleport_player(main, door - direction):
		return false
	var intent: EcsComponents.MoveIntent = ecs_of(main).get_component(player_id_of(main), EcsComponents.MOVE_INTENT)
	intent.direction = direction
	if not pump_until(main, func() -> bool: return travel_in_progress(main), 1.0):
		return false
	return await wait_for_travel(tree, main)


## Real damage path: HealthSystem consumes world.damage_events (the queue the
## enemy AI writes to through Events.emit_damage), so this is exactly how an enemy strike lands.
static func damage_player(main: Node, amount: int) -> void:
	Events.emit_damage(ecs_of(main), player_id_of(main), amount, Vector2i.LEFT, 0)
	pump(main, SIM_STEP_SECONDS)


## Removes EnemyAISystem from the live world so crowded zones (the kingdom, T4)
## stay quiet while a suite pumps the simulation. Returns the removed system.
static func remove_enemy_ai(main: Node) -> EcsSystem:
	var ecs := ecs_of(main)
	for system in ecs.systems:
		if system is EnemyAISystem:
			ecs.systems.erase(system)
			return system
	return null


## Lets the hero's post-hit invulnerability window (0.70 s) run out.
static func wait_out_invulnerability(main: Node) -> void:
	pump(main, 0.8)


## Presses an input action, pumps the simulation `seconds` inside the same
## engine frame (so "just pressed" holds for every step, like a held key),
## releases it and then lets one engine frame pass. That last wait matters:
## Godot reports "just pressed" for the rest of the frame the press happened
## in, even after the release, so without it a stale press would keep walking
## the hero in the next pump. This is the real input path: PlayerInputSystem
## reads Input, honours PlayerTag.control_enabled and writes the intents.
static func hold_action(tree: SceneTree, main: Node, action: StringName, seconds: float) -> void:
	Input.action_press(action)
	pump(main, seconds)
	Input.action_release(action)
	await tree.process_frame


## Clears the hero's buffered input memory so one test step cannot leak a
## queued direction into the next.
static func reset_player_input(main: Node) -> void:
	var input_state: EcsComponents.PlayerInput = ecs_of(main).get_component(player_id_of(main), EcsComponents.PLAYER_INPUT)
	input_state.buffered_direction = Vector2i.ZERO
	input_state.hold_time = 0.0
	input_state.last_held_direction = Vector2i.ZERO
	var intent: EcsComponents.MoveIntent = ecs_of(main).get_component(player_id_of(main), EcsComponents.MOVE_INTENT)
	intent.direction = Vector2i.ZERO


## Sends a real keyboard event (as the OS would) so Input.is_key_pressed sees it.
static func send_key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


## Waits (real engine frames) until the scene has rebuilt its room from the run's checkpoint, which is
## what a death or the restart key does through GameFlow: the room's world is a new EcsWorld (the scene
## itself stays; it used to be reloaded). Returns false when nothing was rebuilt in time. When it returns
## true the old world is gone and one more frame has run, so the new room is live.
static func wait_for_respawn(tree: SceneTree, main: Node) -> bool:
	var old_world_id := ecs_of(main).get_instance_id()
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < REAL_TIME_WAIT_CAP_MSEC:
		if ecs_of(main).get_instance_id() != old_world_id:
			break
		await tree.process_frame
	if ecs_of(main).get_instance_id() == old_world_id:
		return false
	await tree.process_frame
	return true


## Releases every input action a suite may have pressed. Call before quitting.
static func release_all_actions() -> void:
	for action in MOVE_ACTIONS:
		Input.action_release(action)
	for action in [&"attack", &"skill_1", &"turn_mode", &"restart_room"]:
		Input.action_release(action)


## Reads the active slot's save file straight from disk, as a plain ConfigFile (its integrity footer is a
## comment). Empty when there is no file.
static func read_save_file(save_service: Node) -> ConfigFile:
	var file := ConfigFile.new()
	file.load(String(save_service.call("slot_path", save_service.get("active_slot"))))
	return file
