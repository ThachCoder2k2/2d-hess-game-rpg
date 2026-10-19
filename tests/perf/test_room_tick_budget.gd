extends UnboundTest

## The cost of a room (docs/game-base-plan.md 5.11, risk 15, 15 M3a): an 18x9 board with 8 enemies and
## the hero, every system of the schedule and a real puppet view for every piece, ticked the way the game
## ticks, must average 2 ms or less per tick (`MEAN_TICK_BUDGET_MSEC`, the plan's start value). A frame at
## 60 FPS is 16.7 ms, and the simulation is not the only thing in it: the budget keeps the simulation to a
## small share of the frame, so a later milestone that makes a system slower is caught here, not by an
## owner who notices the game stutter.
##
## The scene is built to keep the enemies busy for the whole run, because an idle enemy costs nothing and
## a budget measured on a sleeping room proves nothing: the hero stands in the middle of the board with
## courage that does not run out, and every `HERO_MOVES_EVERY_TICKS` ticks it is put on the next cell of a
## fixed round, so every enemy keeps pursuing, re-planning its attack position, telegraphing and
## recovering. No random numbers, so every run does the same work. What it measures is printed (`PERF:`
## lines), so the number can be quoted and compared from run to run.
##
## The machine may be noisy, so the budget is asserted on the mean AND on the median of a long run (1800
## ticks, 30 seconds of play), the 99th percentile has a bound several times above what it measures, and the
## slowest tick is only printed: a garbage-collection pause or another process on the machine can cost one
## tick tens of milliseconds (88 ms was seen) without the room being slow. Noise cannot hide the thing the
## budget is for, though, so one check does not depend on the clock at all: the grid must have built ONE
## pathfinder for the whole run (the hero changing place is not a change of the terrain), which is what
## keeps an enemy's decision cheap. Measured on this machine at M3a (Apple M5, Godot 4.6.3 headless):
## mean 0.5 ms, median 0.4 ms, 99th percentile 2.1 ms with the cached pathfinder and the bounded search;
## mean 0.8 to 1.2 ms, median 0.4 ms, 99th percentile 6.9 to 9.8 ms before them.

const BOARD_COLUMNS := 18
const BOARD_ROWS := 9
const TICK_SECONDS := 1.0 / 60.0
const WARM_UP_TICKS := 120
const MEASURED_TICKS := 1800
const HERO_MOVES_EVERY_TICKS := 30
## The room must have been busy: at least this many enemy decisions, steps and telegraphs (strikes) in the
## measured ticks, or the run measured a sleeping room.
const MINIMUM_DECISIONS := 200
const MINIMUM_STEPS := 100
const MINIMUM_TELEGRAPHS := 10
## Ticks of the second pass that times every system on its own (information, printed, not asserted).
const BREAKDOWN_TICKS := 600
## The budget of the plan, in milliseconds, for the mean tick and for the median tick.
const MEAN_TICK_BUDGET_MSEC := 2.0
## One tick in a hundred may cost more (the enemies decide in the same tick now and then); this is the bound
## on the 99th percentile, four times the budget and about four times what it measures.
const NINETY_NINTH_PERCENTILE_BUDGET_MSEC := 8.0

## The eight enemies: content ids (content/enemies/<id>/) and the cell each one starts on.
const ENEMY_ROSTER: Array[Dictionary] = [
	{"id": &"pawn_recruit", "cell": Vector2i(2, 1)},
	{"id": &"pawn_recruit", "cell": Vector2i(15, 1)},
	{"id": &"pawn_armed", "cell": Vector2i(2, 7)},
	{"id": &"pawn_armed", "cell": Vector2i(15, 7)},
	{"id": &"knight_tracker", "cell": Vector2i(9, 1)},
	{"id": &"knight_tracker", "cell": Vector2i(9, 7)},
	{"id": &"bishop_zoner", "cell": Vector2i(1, 4)},
	{"id": &"charging_pawn", "cell": Vector2i(16, 4)},
]
## The cells the hero is put on, one after the other, over and over.
const HERO_ROUND: Array[Vector2i] = [Vector2i(9, 4), Vector2i(5, 3), Vector2i(12, 5), Vector2i(8, 6), Vector2i(10, 2), Vector2i(4, 5)]
const HERO_START_CELL := Vector2i(9, 4)
## The hero must survive the whole run, so the enemies stay busy.
const HERO_COURAGE := 100000

var _hero_round_index := 0


func _init() -> void:
	suite_title = "ROOM TICK BUDGET TEST"
	watchdog_seconds = 50.0
	await _run()
	finish()


func _run() -> void:
	var paths := TestPaths.new(self)
	var room := RoomEncounter.new()
	room.board_size = Vector2i(BOARD_COLUMNS, BOARD_ROWS)
	root.add_child(room)

	var world := EcsWorld.new()
	world.manual_tick = true
	root.add_child(world)
	Schedule.populate(world)
	EcsBoot.shape_grid(world, room)

	var enemy_scene := paths.load_scene(paths.actor_view_base_scene())
	var hero_scene := paths.load_scene(paths.actor_scene(&"player"))
	for entry in ENEMY_ROSTER:
		var view := enemy_scene.instantiate() as ActorView
		view.definition = ContentDb.fetch(&"enemies", entry["id"]) as EnemyDefinition
		view.position = world.grid.cell_to_world(entry["cell"])
		room.add_child(view)
	var hero_view := hero_scene.instantiate() as ActorView
	hero_view.position = world.grid.cell_to_world(HERO_START_CELL)
	root.add_child(hero_view)
	await process_frame

	var cast := EcsBoot.boot(world, EcsBootOptions.for_scene(hero_view, room))
	var hero: int = cast["player"]
	_expect(world.grid.bounds == Rect2i(0, 0, BOARD_COLUMNS, BOARD_ROWS), "setup: the board is %d x %d cells" % [BOARD_COLUMNS, BOARD_ROWS])
	_expect(hero != 0 and cast["enemies"].size() == ENEMY_ROSTER.size() and ENEMY_ROSTER.size() == 8, "setup: the hero and eight enemies are booted")
	var hero_health: EcsComponents.Health = world.get_component(hero, EcsComponents.HEALTH)
	hero_health.max_value = HERO_COURAGE
	hero_health.current = HERO_COURAGE
	_expect(world.systems.size() == Schedule.system_scripts().size(), "setup: every system of the schedule ticks (%d)" % world.systems.size())

	# Warm up: the first ticks load resources and build caches, which a long-running game has paid for.
	for tick_index in range(WARM_UP_TICKS):
		_step(world, hero, tick_index)

	var tick_msec: Array[float] = []
	var intents_chosen := 0
	var steps_started := 0
	var telegraphs_started := 0
	var attacks_resolved := 0
	for tick_index in range(MEASURED_TICKS):
		var started_usec := Time.get_ticks_usec()
		_step(world, hero, WARM_UP_TICKS + tick_index)
		tick_msec.append(float(Time.get_ticks_usec() - started_usec) / 1000.0)
		# The shell drains the events every frame; counting them is not part of what the clock measured.
		for event in world.drain_events():
			match event["type"]:
				Events.INTENT_CHANGED:
					intents_chosen += 1
				Events.STEP_STARTED:
					steps_started += 1
				Events.TELEGRAPH_STARTED:
					telegraphs_started += 1
				Events.ATTACK_RESOLVED:
					attacks_resolved += 1

	_expect(intents_chosen >= MINIMUM_DECISIONS and steps_started >= MINIMUM_STEPS and telegraphs_started >= MINIMUM_TELEGRAPHS and attacks_resolved >= MINIMUM_TELEGRAPHS, "the enemies were busy for the whole run: %d decisions, %d steps, %d telegraphs, %d strikes in %d ticks" % [intents_chosen, steps_started, telegraphs_started, attacks_resolved, MEASURED_TICKS])
	var living_enemies := 0
	for enemy_id: int in cast["enemies"]:
		var enemy_health: EcsComponents.Health = world.get_component(enemy_id, EcsComponents.HEALTH)
		if enemy_health != null and enemy_health.current > 0:
			living_enemies += 1
	_expect(living_enemies == ENEMY_ROSTER.size(), "all eight enemies were alive for the whole run (the hero never strikes)")

	var sorted_msec := tick_msec.duplicate()
	sorted_msec.sort()
	var total_msec := 0.0
	for one_tick_msec in tick_msec:
		total_msec += one_tick_msec
	var mean_msec := total_msec / float(tick_msec.size())
	var median_msec: float = sorted_msec[sorted_msec.size() / 2]
	var ninety_ninth_msec: float = sorted_msec[int(float(sorted_msec.size()) * 0.99)]
	var slowest_msec: float = sorted_msec[sorted_msec.size() - 1]
	print("PERF: %d x %d board, %d enemies, %d measured ticks of the whole schedule with real views" % [BOARD_COLUMNS, BOARD_ROWS, ENEMY_ROSTER.size(), MEASURED_TICKS])
	print("PERF: mean %.3f ms, median %.3f ms, 99th percentile %.3f ms, slowest %.3f ms (budget: mean %.1f ms; the slowest is only printed)" % [mean_msec, median_msec, ninety_ninth_msec, slowest_msec, MEAN_TICK_BUDGET_MSEC])

	_print_the_cost_of_every_system(world, hero)

	_expect(mean_msec <= MEAN_TICK_BUDGET_MSEC, "the mean tick of the room costs %.3f ms, within the %.1f ms budget" % [mean_msec, MEAN_TICK_BUDGET_MSEC])
	_expect(median_msec <= MEAN_TICK_BUDGET_MSEC, "the median tick costs %.3f ms, within the %.1f ms budget" % [median_msec, MEAN_TICK_BUDGET_MSEC])
	_expect(ninety_ninth_msec <= NINETY_NINTH_PERCENTILE_BUDGET_MSEC, "99 ticks in 100 cost %.3f ms or less, within %.1f ms" % [ninety_ninth_msec, NINETY_NINTH_PERCENTILE_BUDGET_MSEC])
	_expect(world.grid.pathfinder_build_count == 1, "the grid built %d pathfinder for the whole run (%d decisions): the terrain never changed, so no question built another" % [world.grid.pathfinder_build_count, intents_chosen])

	room.queue_free()
	hero_view.queue_free()
	world.queue_free()


## Ticks the room for BREAKDOWN_TICKS more, timing each system on its own, and prints the mean cost of
## each: where the time goes, so a slower tick can be traced to a system without a profiler. Information
## only; it ticks the systems in the order EcsWorld.tick() does.
func _print_the_cost_of_every_system(world: EcsWorld, hero: int) -> void:
	var usec_by_system: Dictionary = {}
	for tick_index in range(BREAKDOWN_TICKS):
		var run_index := WARM_UP_TICKS + MEASURED_TICKS + tick_index
		if run_index % HERO_MOVES_EVERY_TICKS == 0:
			_move_hero_to_next_cell(world, hero)
		for system in world.systems:
			var system_started_usec := Time.get_ticks_usec()
			system.tick(TICK_SECONDS)
			var system_name: String = system.get_script().resource_path.get_file().get_basename()
			usec_by_system[system_name] = int(usec_by_system.get(system_name, 0)) + Time.get_ticks_usec() - system_started_usec
		world.drain_events()
	for system_name: String in usec_by_system:
		print("PERF:   %-22s mean %.3f ms" % [system_name, float(usec_by_system[system_name]) / 1000.0 / float(BREAKDOWN_TICKS)])


## One tick of the game: put the hero on its next cell now and then, then tick every system.
func _step(world: EcsWorld, hero: int, tick_index: int) -> void:
	if tick_index % HERO_MOVES_EVERY_TICKS == 0:
		_move_hero_to_next_cell(world, hero)
	world.tick(TICK_SECONDS)


## Puts the hero on the next cell of its round unless a piece or a reservation holds it (then it stays).
func _move_hero_to_next_cell(world: EcsWorld, hero: int) -> void:
	var cell := HERO_ROUND[_hero_round_index % HERO_ROUND.size()]
	_hero_round_index += 1
	var hero_position: EcsComponents.GridPos = world.get_component(hero, EcsComponents.GRID_POS)
	var hero_move: EcsComponents.MoveState = world.get_component(hero, EcsComponents.MOVE_STATE)
	if hero_move.moving or not world.grid.is_plannable_cell(hero, cell):
		return
	world.grid.unregister_entity(hero)
	hero_position.cell = cell
	world.grid.register_entity(hero, cell)
