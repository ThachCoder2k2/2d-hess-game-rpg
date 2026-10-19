extends UnboundTest

## ObjectiveSystem (ecs/systems/react/objective_system.gd, docs/game-base-plan.md 13.4, M3b): the room
## clear and the hero's fall, judged in the simulation instead of by the in-game scene. Driven on a hand-built
## world (HealthSystem and ObjectiveSystem only, nothing else acts), with real damage requests, so the
## judgement is held against the same path a sword blow takes. What the bridges do with the verdicts is
## the business of test_bridge_room_outcome; this suite holds the verdicts.

const ZONE := &"test_zone"


func _init() -> void:
	suite_title = "OBJECTIVE SYSTEM TEST"
	_check_a_world_with_no_room_is_left_alone()
	_check_the_counts_follow_the_defeats()
	_check_the_default_objective_clears_the_room_once()
	_check_a_room_that_began_empty_is_never_cleared()
	_check_a_count_objective_clears_before_the_last_enemy()
	_check_a_room_cleared_on_an_earlier_visit_stays_quiet()
	_check_the_fall_is_judged_and_a_failed_room_is_never_cleared()
	_check_a_fall_after_the_clear_is_still_judged()
	_check_the_counts_never_go_backwards()
	_check_a_frozen_world_is_not_judged()
	_check_ecs_boot_gives_a_played_room_its_entity()
	finish()


func _make_world() -> EcsWorld:
	var world := EcsWorld.new()
	world.manual_tick = true
	root.add_child(world)
	world.add_system(HealthSystem.new())
	world.add_system(ObjectiveSystem.new())
	return world


func _spawn_hero(world: EcsWorld) -> int:
	var sword := ContentDb.fetch(&"skills", &"wooden_sword") as AttackProfile
	var thrust := ContentDb.fetch(&"skills", &"pencil_thrust") as AttackProfile
	return EcsActorFactory.spawn_player(world, Vector2i(1, 1), sword, thrust, 3)


func _spawn_enemies(world: EcsWorld, count: int) -> Array[int]:
	var enemies: Array[int] = []
	for index in count:
		enemies.append(EcsActorFactory.spawn_enemy(world, ContentDb.fetch(&"enemies", &"pawn_recruit") as EnemyDefinition, Vector2i(5 + index, 4)))
	return enemies


## A room entity the way EcsBoot makes one, for `enemy_count` enemies.
func _add_room(world: EcsWorld, enemy_count: int, objective: RoomObjective = null) -> RoomObjectiveState:
	var state := RoomObjectiveState.new()
	state.zone_id = ZONE
	state.objective = objective
	state.enemies_total = enemy_count
	state.enemies_remaining = enemy_count
	world.add_component(world.create_entity(), RoomObjectiveState.KEY, state)
	return state


## Kills `enemy` with a damage request, the way a sword blow does, and ticks once.
func _strike_down(world: EcsWorld, hero: int, enemy: int) -> void:
	Events.emit_damage(world, enemy, 99, Vector2i.ZERO, hero)
	world.tick(0.016)


func _events_of(world: EcsWorld, event_type: StringName) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for event in world.drain_events():
		if event["type"] == event_type:
			found.append(event)
	return found


func _check_a_world_with_no_room_is_left_alone() -> void:
	var world := _make_world()
	var hero := _spawn_hero(world)
	var enemies := _spawn_enemies(world, 1)
	_strike_down(world, hero, enemies[0])
	_expect(_events_of(world, Events.ROOM_CLEARED).is_empty(), "a world with no room entity judges nothing: the last enemy falls and no room is cleared")
	world.queue_free()


func _check_the_counts_follow_the_defeats() -> void:
	var world := _make_world()
	var hero := _spawn_hero(world)
	var enemies := _spawn_enemies(world, 3)
	var state := _add_room(world, 3)
	world.tick(0.016)
	_expect(state.enemies_total == 3 and state.enemies_remaining == 3 and state.enemies_defeated == 0, "a room with three enemies counts three standing and none down")
	_strike_down(world, hero, enemies[0])
	_expect(state.enemies_total == 3 and state.enemies_remaining == 2 and state.enemies_defeated == 1, "one falls: two standing, one down, three began")
	_expect(_events_of(world, Events.ROOM_CLEARED).is_empty() and not state.cleared, "and the room is not cleared while two stand")
	world.queue_free()


func _check_the_default_objective_clears_the_room_once() -> void:
	var world := _make_world()
	var hero := _spawn_hero(world)
	var enemies := _spawn_enemies(world, 2)
	var state := _add_room(world, 2)
	_strike_down(world, hero, enemies[0])
	world.drain_events()
	_strike_down(world, hero, enemies[1])
	var cleared_events := _events_of(world, Events.ROOM_CLEARED)
	_expect(cleared_events.size() == 1, "the last enemy falls and the room says it is cleared, once")
	_expect(cleared_events.size() == 1 and cleared_events[0]["zone"] == ZONE and cleared_events[0]["defeated"] == 2 and cleared_events[0]["total"] == 2, "naming its zone and how many fell of how many began")
	_expect(cleared_events.size() == 1 and cleared_events[0]["has_objective"] == false, "a room with no objective of its own says so")
	_expect(state.cleared and not state.failed, "the room is marked cleared, not failed")
	for _tick in 5:
		world.tick(0.016)
	_expect(_events_of(world, Events.ROOM_CLEARED).is_empty(), "later ticks do not say it again")
	world.queue_free()


func _check_a_room_that_began_empty_is_never_cleared() -> void:
	var world := _make_world()
	_spawn_hero(world)
	var state := _add_room(world, 0)
	for _tick in 5:
		world.tick(0.016)
	_expect(not state.cleared and _events_of(world, Events.ROOM_CLEARED).is_empty(), "a room that began with no enemies is not 'cleared' by standing in it")
	world.queue_free()


func _check_a_count_objective_clears_before_the_last_enemy() -> void:
	var world := _make_world()
	var hero := _spawn_hero(world)
	var enemies := _spawn_enemies(world, 3)
	var objective := RoomObjective.new()
	objective.win_condition = RoomObjective.WinCondition.DEFEAT_COUNT
	objective.required_defeats = 2
	var state := _add_room(world, 3, objective)
	_strike_down(world, hero, enemies[0])
	_expect(not state.cleared, "one down of the two the objective asks for is not enough")
	_strike_down(world, hero, enemies[1])
	var cleared_events := _events_of(world, Events.ROOM_CLEARED)
	_expect(cleared_events.size() == 1 and state.cleared and state.enemies_remaining == 1, "the second defeat meets the objective while an enemy still stands")
	_expect(cleared_events.size() == 1 and cleared_events[0]["has_objective"] == true and cleared_events[0]["defeated"] == 2 and cleared_events[0]["total"] == 3, "and the verdict says the room carries an objective")
	world.queue_free()


func _check_a_room_cleared_on_an_earlier_visit_stays_quiet() -> void:
	var world := _make_world()
	_spawn_hero(world)
	var state := _add_room(world, 0)
	state.cleared = true
	for _tick in 3:
		world.tick(0.016)
	_expect(_events_of(world, Events.ROOM_CLEARED).is_empty(), "a room the run already cleared (its enemies not spawned) says nothing")
	world.queue_free()


func _check_the_fall_is_judged_and_a_failed_room_is_never_cleared() -> void:
	var world := _make_world()
	var hero := _spawn_hero(world)
	var enemies := _spawn_enemies(world, 1)
	var state := _add_room(world, 1)
	world.tick(0.016)
	_expect(not state.failed, "a hero with Courage left has not failed the room")
	# The last enemy and the hero fall in the same tick: the fall wins, the room is not cleared.
	Events.emit_damage(world, enemies[0], 99, Vector2i.ZERO, hero)
	Events.emit_damage(world, hero, 99, Vector2i.LEFT, enemies[0])
	world.tick(0.016)
	_expect(state.failed, "the hero at 0 Courage fails the room")
	_expect(not state.cleared and _events_of(world, Events.ROOM_CLEARED).is_empty(), "and a room that is failed is not cleared, even when its last enemy fell in the same tick")
	world.queue_free()


func _check_a_fall_after_the_clear_is_still_judged() -> void:
	var world := _make_world()
	var hero := _spawn_hero(world)
	var enemies := _spawn_enemies(world, 1)
	var state := _add_room(world, 1)
	_strike_down(world, hero, enemies[0])
	_expect(state.cleared and not state.failed, "setup: the room is cleared")
	world.drain_events()
	Events.emit_damage(world, hero, 99, Vector2i.LEFT, 0)
	world.tick(0.016)
	_expect(state.cleared and state.failed and _events_of(world, Events.ROOM_CLEARED).is_empty(), "a hero who falls in a cleared room fails it too, and the clear is not announced again")
	world.queue_free()


func _check_the_counts_never_go_backwards() -> void:
	var world := _make_world()
	var hero := _spawn_hero(world)
	var enemies := _spawn_enemies(world, 2)
	var state := _add_room(world, 2)
	_strike_down(world, hero, enemies[0])
	world.destroy_entity(enemies[0])
	world.tick(0.016)
	_expect(state.enemies_defeated == 1 and state.enemies_remaining == 1 and state.enemies_total == 2, "a fallen enemy whose entity is cleared away is still counted as down")
	world.queue_free()


func _check_a_frozen_world_is_not_judged() -> void:
	var world := _make_world()
	_spawn_hero(world)
	var enemies := _spawn_enemies(world, 1)
	var state := _add_room(world, 1)
	var health: EcsComponents.Health = world.get_component(enemies[0], EcsComponents.HEALTH)
	health.current = 0
	world.frozen = true
	world.tick(0.016)
	_expect(not state.cleared and _events_of(world, Events.ROOM_CLEARED).is_empty(), "the objective is a rule of the game: while the world is held still it judges nothing")
	world.frozen = false
	world.tick(0.016)
	_expect(state.cleared and _events_of(world, Events.ROOM_CLEARED).size() == 1, "and judges the moment the world runs again")
	world.queue_free()


## EcsBoot gives a played room its entity (and only when asked), from the room scene's own data.
func _check_ecs_boot_gives_a_played_room_its_entity() -> void:
	var room_scene := ContentDb.fetch(&"rooms", &"t4_broken_rule_yard") as PackedScene
	var room := room_scene.instantiate()
	root.add_child(room)
	var world := EcsWorld.new()
	world.manual_tick = true
	root.add_child(world)
	var plain_cast := EcsBoot.boot(world, EcsBootOptions.for_scene(null, room))
	_expect(plain_cast["room"] == 0 and world.query([RoomObjectiveState.KEY]).is_empty(), "a room booted without room rules has no entity of its own (the world dump stays what it was)")
	var played_world := EcsWorld.new()
	played_world.manual_tick = true
	root.add_child(played_world)
	var options := EcsBootOptions.for_scene(null, room)
	options.with_room_rules = true
	var played_cast := EcsBoot.boot(played_world, options)
	var room_entity := int(played_cast["room"])
	var state: RoomObjectiveState = played_world.get_component(room_entity, RoomObjectiveState.KEY)
	_expect(room_entity != 0 and state != null, "a room booted with room rules has its own entity")
	_expect(state != null and state.zone_id == &"t4_broken_rule_yard", "that carries the zone id the room scene names")
	_expect(state != null and state.enemies_total == played_cast["enemies"].size() and state.enemies_remaining == state.enemies_total and state.enemies_total >= 2, "and the enemies it began with (%d)" % [played_cast["enemies"].size()])
	_expect(state != null and state.objective == null and not state.cleared and not state.failed, "T4 names no objective of its own, and is neither cleared nor failed")
	_expect(room_entity > int(played_cast["player"]) and room_entity > int(played_cast["enemies"].back()), "and it is the last entity made, so every other entity keeps the number it always had")
	room.queue_free()
	world.queue_free()
	played_world.queue_free()
