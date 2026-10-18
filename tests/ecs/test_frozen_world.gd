extends UnboundTest

## A frozen world (docs/game-base-plan.md 8.4, 14.1, 15 M3a): a cutscene beat or a pause holds the
## simulation still without ending it. While EcsWorld.frozen is true only the systems that answer
## yes to runs_while_frozen() tick: no step, no timer, no enemy moves, and a request that arrives
## waits its turn instead of being lost. The picture keeps being drawn (ViewSyncSystem), and
## thawing resumes exactly where the world was held. Commands while frozen are in
## test_commands_channel.

## Counts its ticks; says whether it runs while the world is frozen.
class TickCounter:
	extends EcsSystem

	var ticks := 0
	var keeps_running_while_frozen := false

	func tick(_delta: float) -> void:
		ticks += 1

	func runs_while_frozen() -> bool:
		return keeps_running_while_frozen


func _init() -> void:
	suite_title = "FROZEN WORLD TEST"
	_check_a_world_starts_thawed_and_counts_systems_by_their_answer()
	_check_a_frozen_world_holds_everything_still_and_resumes()
	_check_the_picture_keeps_being_drawn_while_frozen()
	_check_requests_wait_for_the_thaw()
	_check_every_system_of_the_schedule_answers()
	finish()


func _make_world() -> EcsWorld:
	var world := EcsWorld.new()
	world.manual_tick = true
	root.add_child(world)
	return world


func _check_a_world_starts_thawed_and_counts_systems_by_their_answer() -> void:
	var world := _make_world()
	_expect(not world.frozen, "a new world is not frozen")
	var holder := TickCounter.new()
	var keeper := TickCounter.new()
	keeper.keeps_running_while_frozen = true
	world.add_system(holder)
	world.add_system(keeper)
	world.tick(0.016)
	_expect(holder.ticks == 1 and keeper.ticks == 1, "a thawed world ticks every system")
	world.frozen = true
	world.tick(0.016)
	world.tick(0.016)
	_expect(holder.ticks == 1, "a frozen world does not tick a system that says it does not run while frozen")
	_expect(keeper.ticks == 3, "a frozen world still ticks a system that says it runs while frozen")
	world.frozen = false
	world.tick(0.016)
	_expect(holder.ticks == 2 and keeper.ticks == 4, "thawing resumes the held system on the next tick")
	world.queue_free()


func _check_a_frozen_world_holds_everything_still_and_resumes() -> void:
	var world := _make_world()
	Schedule.populate(world)
	var hero := _spawn_hero(world, Vector2i(3, 3))
	var hero_move: EcsComponents.MoveState = world.get_component(hero, EcsComponents.MOVE_STATE)
	var hero_intent: EcsComponents.MoveIntent = world.get_component(hero, EcsComponents.MOVE_INTENT)
	var hero_health: EcsComponents.Health = world.get_component(hero, EcsComponents.HEALTH)
	hero_health.invulnerable_left = 0.5
	hero_health.flash_left = 0.1

	world.frozen = true
	hero_intent.direction = Vector2i.RIGHT
	for _tick in range(30):
		world.tick(0.05)
	_expect(not hero_move.moving and world.get_component(hero, EcsComponents.GRID_POS).cell == Vector2i(3, 3), "a frozen world takes no step: the hero stays on its cell after 1.5 s of ticks")
	_expect(hero_intent.direction == Vector2i.RIGHT, "the step requested before the freeze is neither consumed nor lost")
	_expect(is_equal_approx(hero_health.invulnerable_left, 0.5) and is_equal_approx(hero_health.flash_left, 0.1), "a frozen world does not run the timers down: the invulnerability window waits")
	_expect(world.drain_events().is_empty(), "a frozen world emits no events")

	world.frozen = false
	world.tick(0.05)
	_expect(hero_move.moving and hero_intent.direction == Vector2i.ZERO, "thawing lets the held step begin on the very next tick")
	var started := world.drain_events().filter(func(event: Dictionary) -> bool: return event.get("type") == Events.STEP_STARTED)
	_expect(started.size() == 1 and started[0]["entity"] == hero, "the step announces itself as it would have, after the thaw")
	_expect(hero_health.invulnerable_left < 0.5, "thawing lets the timers run again")
	world.queue_free()


func _check_the_picture_keeps_being_drawn_while_frozen() -> void:
	var world := _make_world()
	Schedule.populate(world)
	var hero := _spawn_hero(world, Vector2i(3, 3))
	var view := Node2D.new()
	root.add_child(view)
	var view_ref: EcsComponents.ViewRef = world.add_component(hero, EcsComponents.VIEW_REF, EcsComponents.ViewRef.new())
	view_ref.node = view
	world.frozen = true
	world.tick(0.016)
	_expect(view.position == world.grid.cell_to_world(Vector2i(3, 3)), "a frozen world still draws: the view is stood on the hero's cell")
	# Something outside the simulation (a cutscene beat) moves the entity; the held world still shows it.
	var hero_pos: EcsComponents.GridPos = world.get_component(hero, EcsComponents.GRID_POS)
	hero_pos.cell = Vector2i(6, 4)
	world.tick(0.016)
	_expect(view.position == world.grid.cell_to_world(Vector2i(6, 4)), "a frozen world keeps syncing the view to the components")
	view.queue_free()
	world.queue_free()


func _check_requests_wait_for_the_thaw() -> void:
	var world := _make_world()
	Schedule.populate(world)
	var hero := _spawn_hero(world, Vector2i(3, 3))
	var hero_health: EcsComponents.Health = world.get_component(hero, EcsComponents.HEALTH)
	hero_health.current = 3
	world.frozen = true
	Events.emit_damage(world, hero, 1, Vector2i.LEFT, 0)
	Events.emit_heal(world, hero, 1, 0)
	world.tick(0.016)
	_expect(hero_health.current == 3 and world.damage_events.size() == 1 and world.heal_events.size() == 1, "a damage and a heal request made while frozen are kept, not applied and not lost")
	world.frozen = false
	world.tick(0.016)
	_expect(world.damage_events.is_empty() and world.heal_events.is_empty() and hero_health.current == 3, "after the thaw both are served on the next tick (a blow, then a heal: 3 -> 2 -> 3)")
	var kinds: Array = world.drain_events().map(func(event: Dictionary) -> StringName: return event["type"])
	_expect(kinds == [Events.DAMAGED, Events.HEALED], "and they announce themselves in that order")
	world.queue_free()


func _check_every_system_of_the_schedule_answers() -> void:
	var must_run: Array[String] = ["ViewSyncSystem"]
	var running_while_frozen: Array[String] = []
	for system in Schedule.build_systems():
		if system.runs_while_frozen():
			running_while_frozen.append((system.get_script() as GDScript).get_global_name())
	for system_name in must_run:
		_expect(system_name in running_while_frozen, "%s keeps running while the world is frozen" % system_name)
	for system_name in running_while_frozen:
		_expect(system_name in must_run or system_name == "CommandSystem", "%s is one of the systems allowed to run while frozen (only the command and view systems are)" % system_name)


func _spawn_hero(world: EcsWorld, cell: Vector2i) -> int:
	var sword := ContentDb.fetch(&"skills", &"wooden_sword") as AttackProfile
	var thrust := ContentDb.fetch(&"skills", &"pencil_thrust") as AttackProfile
	return EcsActorFactory.spawn_player(world, cell, sword, thrust)
