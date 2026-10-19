extends UnboundTest

## CheckpointSystem (ecs/systems/progress/checkpoint_system.gd, docs/game-base-plan.md 5.2, 13.4, D-16, M3b):
## the two things the simulation decides about checkpoints and deaths, driven on a hand-built world with the
## real HealthSystem and ObjectiveSystem in front of it (the order the schedule runs them in):
##   - ARRIVAL: coming in through the door of a checkpoint room sets the checkpoint (`checkpoint_set`), once,
##     and refills the hero's Courage through the heal queue; a launch and a respawn, and a room that is not a
##     checkpoint, do neither;
##   - FALL: the hero at 0 Courage makes the room ask to start again (`respawn_requested`), once, naming the
##     entry the pawn came in by.
## What the shell does with the two events (the run's checkpoint, the save, the defeat beat, the rebuild) is
## held by test_checkpoint_rules.

const ZONE := &"test_hub"
const ENTRY := &"from_somewhere"


func _init() -> void:
	suite_title = "CHECKPOINT SYSTEM TEST"
	_check_a_checkpoint_door_sets_the_checkpoint_and_refills_courage()
	_check_only_a_door_into_a_checkpoint_room_counts()
	_check_a_full_hero_still_reaches_the_checkpoint()
	_check_the_arrival_is_judged_on_the_first_tick_the_world_runs()
	_check_the_fall_asks_for_the_room_to_start_again_once()
	_check_a_checkpoint_room_answers_a_fall_too()
	_check_a_world_with_no_room_is_left_alone()
	_check_believe_is_a_named_seam_that_refills_nothing_yet()
	_check_ecs_boot_builds_the_room_state_from_the_scene_and_the_options()
	finish()


func _make_world() -> EcsWorld:
	var world := EcsWorld.new()
	world.manual_tick = true
	root.add_child(world)
	world.add_system(HealthSystem.new())
	world.add_system(ObjectiveSystem.new())
	world.add_system(CheckpointSystem.new())
	return world


func _spawn_hero(world: EcsWorld, courage := 3) -> int:
	var sword := ContentDb.fetch(&"skills", &"wooden_sword") as AttackProfile
	var thrust := ContentDb.fetch(&"skills", &"pencil_thrust") as AttackProfile
	return EcsActorFactory.spawn_player(world, Vector2i(1, 1), sword, thrust, courage)


## A room entity the way EcsBoot makes one: the objective state and the checkpoint data.
func _add_room(world: EcsWorld, checkpoint_on_entry: bool, entered_by_door: bool) -> RoomCheckpoint:
	var room_entity := world.create_entity()
	var objective_state := RoomObjectiveState.new()
	objective_state.zone_id = ZONE
	world.add_component(room_entity, RoomObjectiveState.KEY, objective_state)
	var checkpoint := RoomCheckpoint.new()
	checkpoint.zone_id = ZONE
	checkpoint.entry_id = ENTRY
	checkpoint.checkpoint_on_entry = checkpoint_on_entry
	checkpoint.entered_by_door = entered_by_door
	world.add_component(room_entity, RoomCheckpoint.KEY, checkpoint)
	return checkpoint


func _events_of(world: EcsWorld, event_type: StringName) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for event in world.pending_events:
		if event["type"] == event_type:
			found.append(event)
	return found


func _wound(world: EcsWorld, hero: int, amount: int) -> void:
	Events.emit_damage(world, hero, amount, Vector2i.LEFT, 0)
	world.tick(0.016)
	var health: EcsComponents.Health = world.get_component(hero, EcsComponents.HEALTH)
	health.invulnerable_left = 0.0
	world.pending_events.clear()


func _check_a_checkpoint_door_sets_the_checkpoint_and_refills_courage() -> void:
	var world := _make_world()
	var hero := _spawn_hero(world)
	_wound(world, hero, 2)
	var health: EcsComponents.Health = world.get_component(hero, EcsComponents.HEALTH)
	_expect(health.current == 1, "setup: the hero arrives with 1 Courage of 3")
	_add_room(world, true, true)
	world.tick(0.016)
	var set_events := _events_of(world, Events.CHECKPOINT_SET)
	_expect(set_events.size() == 1, "the first tick in a checkpoint room entered by a door sets the checkpoint, once")
	_expect(set_events.size() == 1 and set_events[0]["zone"] == ZONE and set_events[0]["entry"] == ENTRY, "naming the room's zone and the entry the pawn came in by")
	_expect(set_events.size() == 1 and set_events[0]["refills"] == [CheckpointSystem.COURAGE], "and saying Courage was refilled (Believe has no component yet)")
	_expect(world.heal_events.size() == 1 and world.heal_events[0]["target"] == hero and world.heal_events[0]["amount"] == 2 and world.heal_events[0]["source"] == 0, "the refill is a heal request for what was missing (2), from the world itself (source 0)")
	world.tick(0.016)
	_expect(health.current == 3, "the heal queue restores the hero to full on the next tick")
	var healed_events := _events_of(world, Events.HEALED)
	_expect(healed_events.size() == 1 and healed_events[0]["amount"] == 2 and healed_events[0]["remaining"] == 3 and healed_events[0]["source"] == 0, "and says `healed`, which is how the HUD learns of it")
	world.pending_events.clear()
	for _tick in 5:
		world.tick(0.016)
	_expect(_events_of(world, Events.CHECKPOINT_SET).is_empty() and world.heal_events.is_empty(), "later ticks set nothing and heal nothing: the arrival is judged once")
	world.queue_free()


func _check_only_a_door_into_a_checkpoint_room_counts() -> void:
	var launch_world := _make_world()
	var launch_hero := _spawn_hero(launch_world)
	_wound(launch_world, launch_hero, 1)
	_add_room(launch_world, true, false)
	launch_world.tick(0.016)
	_expect(_events_of(launch_world, Events.CHECKPOINT_SET).is_empty() and launch_world.heal_events.is_empty(), "a checkpoint room the pawn was not walked into through a door (a launch, a respawn) sets no checkpoint and refills nothing")
	launch_world.queue_free()

	var plain_world := _make_world()
	var plain_hero := _spawn_hero(plain_world)
	_wound(plain_world, plain_hero, 1)
	_add_room(plain_world, false, true)
	plain_world.tick(0.016)
	_expect(_events_of(plain_world, Events.CHECKPOINT_SET).is_empty() and plain_world.heal_events.is_empty(), "a door into a room that is not a checkpoint sets none and refills nothing: travel never heals")
	plain_world.queue_free()


func _check_a_full_hero_still_reaches_the_checkpoint() -> void:
	var world := _make_world()
	_spawn_hero(world)
	_add_room(world, true, true)
	world.tick(0.016)
	_expect(_events_of(world, Events.CHECKPOINT_SET).size() == 1 and world.heal_events.is_empty(), "a hero with full Courage still reaches the checkpoint; there is nothing to heal")
	world.queue_free()


func _check_the_arrival_is_judged_on_the_first_tick_the_world_runs() -> void:
	var world := _make_world()
	var hero := _spawn_hero(world)
	_wound(world, hero, 1)
	var checkpoint := _add_room(world, true, true)
	world.frozen = true
	world.tick(0.016)
	_expect(not checkpoint.arrival_judged and _events_of(world, Events.CHECKPOINT_SET).is_empty(), "a frozen world has not arrived yet: the rule waits")
	world.frozen = false
	world.tick(0.016)
	_expect(checkpoint.arrival_judged and _events_of(world, Events.CHECKPOINT_SET).size() == 1, "and the checkpoint is set the first tick it runs")
	world.queue_free()


func _check_the_fall_asks_for_the_room_to_start_again_once() -> void:
	var world := _make_world()
	var hero := _spawn_hero(world)
	var checkpoint := _add_room(world, false, true)
	world.tick(0.016)
	_expect(_events_of(world, Events.RESPAWN_REQUESTED).is_empty(), "a hero with Courage left asks for nothing")
	Events.emit_damage(world, hero, 99, Vector2i.LEFT, 0)
	world.tick(0.016)
	var requests := _events_of(world, Events.RESPAWN_REQUESTED)
	_expect(requests.size() == 1, "the tick the hero falls, the room asks to start again")
	_expect(requests.size() == 1 and requests[0]["entity"] == hero and requests[0]["zone"] == ZONE and requests[0]["entry"] == ENTRY, "naming the hero, the room and the entry the pawn came in by (D-16: the room starts again from its own entry)")
	_expect(checkpoint.respawn_requested, "and the room is marked as answered")
	world.pending_events.clear()
	for _tick in 5:
		world.tick(0.016)
	_expect(_events_of(world, Events.RESPAWN_REQUESTED).is_empty(), "the request is made once")
	_expect(_events_of(world, Events.CHECKPOINT_SET).is_empty(), "and a fall in a plain room sets no checkpoint: a death never moves one")
	world.queue_free()


func _check_a_checkpoint_room_answers_a_fall_too() -> void:
	var world := _make_world()
	var hero := _spawn_hero(world)
	_add_room(world, true, true)
	world.tick(0.016)
	world.pending_events.clear()
	Events.emit_damage(world, hero, 99, Vector2i.LEFT, 0)
	world.tick(0.016)
	_expect(_events_of(world, Events.RESPAWN_REQUESTED).size() == 1 and _events_of(world, Events.CHECKPOINT_SET).is_empty(), "a hero who falls in a boss room asks for the same room again; the checkpoint was set once, on the way in")
	world.queue_free()


func _check_a_world_with_no_room_is_left_alone() -> void:
	var world := _make_world()
	var hero := _spawn_hero(world)
	Events.emit_damage(world, hero, 99, Vector2i.LEFT, 0)
	for _tick in 3:
		world.tick(0.016)
	_expect(_events_of(world, Events.RESPAWN_REQUESTED).is_empty() and _events_of(world, Events.CHECKPOINT_SET).is_empty(), "a world with no room entity has no checkpoint to set and no room to start again")
	world.queue_free()


func _check_believe_is_a_named_seam_that_refills_nothing_yet() -> void:
	var system := CheckpointSystem.new()
	_expect(system._refill_believe(1) == false, "the Believe seam exists and refills nothing: the component arrives in M10 (D-41)")
	_expect(CheckpointSystem.BELIEVE == &"believe" and CheckpointSystem.COURAGE == &"courage", "and a checkpoint will name what it refilled by these two words")


## EcsBoot gives the room its checkpoint data from the room scene and the options, and only with room rules.
func _check_ecs_boot_builds_the_room_state_from_the_scene_and_the_options() -> void:
	var boss_scene := ContentDb.fetch(&"rooms", &"b1_black_pawn_captain") as PackedScene
	var boss_room := boss_scene.instantiate()
	root.add_child(boss_room)
	var world := EcsWorld.new()
	world.manual_tick = true
	root.add_child(world)
	var options := EcsBootOptions.for_scene(null, boss_room)
	options.with_room_rules = true
	options.entry_id = &"from_hub"
	options.entered_by_door = true
	var cast := EcsBoot.boot(world, options)
	var checkpoint: RoomCheckpoint = world.get_component(int(cast["room"]), RoomCheckpoint.KEY)
	_expect(checkpoint != null and checkpoint.zone_id == &"b1_black_pawn_captain" and checkpoint.checkpoint_on_entry, "the boss room's scene says entering it is a checkpoint, and the room entity carries that")
	_expect(checkpoint != null and checkpoint.entry_id == &"from_hub" and checkpoint.entered_by_door, "with the entry and the door the shell passed in the options")
	_expect(checkpoint != null and not checkpoint.arrival_judged and not checkpoint.respawn_requested, "and nothing said yet")

	var yard_scene := ContentDb.fetch(&"rooms", &"t4_broken_rule_yard") as PackedScene
	var yard := yard_scene.instantiate()
	root.add_child(yard)
	var yard_world := EcsWorld.new()
	yard_world.manual_tick = true
	root.add_child(yard_world)
	var yard_options := EcsBootOptions.for_scene(null, yard)
	yard_options.with_room_rules = true
	var yard_cast := EcsBoot.boot(yard_world, yard_options)
	var yard_checkpoint: RoomCheckpoint = yard_world.get_component(int(yard_cast["room"]), RoomCheckpoint.KEY)
	_expect(yard_checkpoint != null and not yard_checkpoint.checkpoint_on_entry and not yard_checkpoint.entered_by_door and yard_checkpoint.entry_id == &"start", "an ordinary room is no checkpoint, and the options' defaults are a launch at the start entry")

	var dump_world := EcsWorld.new()
	dump_world.manual_tick = true
	root.add_child(dump_world)
	var plain_cast := EcsBoot.boot(dump_world, EcsBootOptions.for_scene(null, boss_room))
	_expect(plain_cast["room"] == 0 and dump_world.query([RoomCheckpoint.KEY]).is_empty(), "without room rules there is no room entity at all, so the world dump holds only what spawns")
	boss_room.queue_free()
	yard.queue_free()
	world.queue_free()
	yard_world.queue_free()
	dump_world.queue_free()
