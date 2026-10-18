extends UnboundTest

## world.view_commands (docs/game-base-plan.md 8.4, 14.1): the cosmetic instructions a cutscene
## beat uses to stage the pawn ("wake", "bow", "hesitate"). They are pushed by whoever stages the
## scene and played only by ViewSyncSystem, the one system that touches nodes; they never change
## the simulation, and they work while the world is frozen, which is when a cutscene needs them.
## The state they play is a state of the actor's AnimationTree graph (editor-owned).

const FRAMES_BEFORE_READING_GRAPH := 4
const PLAYER_SCENE_PATH := "res://presentation/views/actors/player.tscn"


func _init() -> void:
	suite_title = "VIEW COMMANDS TEST"
	await _check_a_view_command_sends_the_graph_to_a_state()
	await _check_a_frozen_world_still_plays_view_commands()
	_check_what_cannot_be_played_is_dropped_with_its_reason()
	finish()


## Boots the hero's real view into a world that only draws (ViewSyncSystem), as a cutscene sees it.
func _boot_hero() -> Dictionary:
	var host := Node2D.new()
	host.name = "Main"
	root.add_child(host)
	var view := (load(PLAYER_SCENE_PATH) as PackedScene).instantiate() as ActorView
	view.position = Vector2(112, 212)
	host.add_child(view)
	var world := EcsWorld.new()
	world.manual_tick = true
	host.add_child(world)
	world.add_system(ViewSyncSystem.new())
	var cast := EcsBoot.boot(world, EcsBootOptions.for_scene(view, null))
	world.tick(0.016)
	return {"host": host, "view": view, "world": world, "hero": int(cast["player"])}


func _current_state(actor: Dictionary) -> StringName:
	var tree := (actor["view"] as Node).get_node("AnimationTree") as AnimationTree
	var playback: AnimationNodeStateMachinePlayback = tree.get("parameters/playback")
	return playback.get_current_node()


func _check_a_view_command_sends_the_graph_to_a_state() -> void:
	var actor := _boot_hero()
	var world := actor["world"] as EcsWorld
	await wait_frames(FRAMES_BEFORE_READING_GRAPH)
	_expect(_current_state(actor) == &"wake", "setup: the hero's graph boots into its wake state")
	world.push_view_command(Commands.play_state(actor["hero"], &"defeat"))
	_expect(world.view_commands.size() == 1, "a view command is only queued when it is pushed")
	world.tick(0.016)
	_expect(world.view_commands.is_empty(), "ViewSyncSystem takes the queue on its next tick")
	await wait_frames(FRAMES_BEFORE_READING_GRAPH)
	_expect(_current_state(actor) == &"defeat", "and the actor's graph travels to the named state (it is in '%s')" % _current_state(actor))
	_expect(world.drain_events().is_empty(), "playing a state says nothing: it is cosmetic")
	(actor["host"] as Node).queue_free()
	await wait_frames(2)


func _check_a_frozen_world_still_plays_view_commands() -> void:
	var actor := _boot_hero()
	var world := actor["world"] as EcsWorld
	await wait_frames(FRAMES_BEFORE_READING_GRAPH)
	world.frozen = true
	world.push_view_command(Commands.play_state(actor["hero"], &"defeat"))
	world.tick(0.016)
	await wait_frames(FRAMES_BEFORE_READING_GRAPH)
	_expect(world.view_commands.is_empty() and _current_state(actor) == &"defeat", "a frozen world plays a view command: that is how a cutscene stages the pawn while the game is held")
	(actor["host"] as Node).queue_free()
	await wait_frames(2)


func _check_what_cannot_be_played_is_dropped_with_its_reason() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var world := EcsWorld.new()
	world.manual_tick = true
	host.add_child(world)
	world.add_system(ViewSyncSystem.new())

	var graphless := world.create_entity()
	var bare_view := Node2D.new()
	host.add_child(bare_view)
	var view_ref: EcsComponents.ViewRef = world.add_component(graphless, EcsComponents.VIEW_REF, EcsComponents.ViewRef.new())
	view_ref.node = bare_view
	world.push_view_command(Commands.play_state(graphless, &"wake"))
	world.tick(0.016)
	var refused := _events_of_type(world.drain_events(), Events.COMMAND_REJECTED)
	_expect(refused.size() == 1 and refused[0]["command"] == Commands.PLAY_STATE and String(refused[0]["reason"]).contains("no animation graph"), "a view without an animation graph cannot play a state, and the refusal says so")

	world.push_view_command(Commands.play_state(world.create_entity(), &"wake"))
	world.tick(0.016)
	_expect(world.drain_events().is_empty(), "a command for an entity that has no view any more (it was despawned) is dropped without a word")

	var hero_view := (load(PLAYER_SCENE_PATH) as PackedScene).instantiate() as ActorView
	host.add_child(hero_view)
	var hero := world.create_entity()
	var hero_ref: EcsComponents.ViewRef = world.add_component(hero, EcsComponents.VIEW_REF, EcsComponents.ViewRef.new())
	hero_ref.node = hero_view
	world.push_view_command(Commands.play_state(hero, &"bow"))
	world.tick(0.016)
	refused = _events_of_type(world.drain_events(), Events.COMMAND_REJECTED)
	_expect(refused.size() == 1 and String(refused[0]["reason"]).contains("no state 'bow'"), "a state the graph does not have (bow has no clip yet) is refused with its name")

	world.view_commands.append({"type": Commands.PLAY_STATE, "entity": hero})
	world.view_commands.append({"type": &"made_up"})
	world.tick(0.016)
	refused = _events_of_type(world.drain_events(), Events.COMMAND_REJECTED)
	_expect(refused.size() == 2 and String(refused[0]["reason"]).contains("missing the documented key 'state'") and String(refused[1]["reason"]).contains("not declared"), "a malformed view command is refused, each with its reason")
	_expect(world.view_commands.is_empty(), "and nothing is retried")
	host.queue_free()


func _events_of_type(events: Array[Dictionary], event_type: StringName) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for event in events:
		if event.get("type") == event_type:
			found.append(event)
	return found
