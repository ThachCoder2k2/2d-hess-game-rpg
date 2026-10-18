extends UnboundTest

## There is ONE actor view (docs/game-base-plan.md 15 M2): presentation/views/actors/actor_view_base.tscn
## holds the nodes, the clips and the animation graph, and every actor scene is a thin scene that
## inherits it and says only what differs. test_actor_collapse_golden proves the collapse changed
## nothing it should not have; this suite proves the shape the collapse leaves behind and that the
## graph still behaves when it is actually running.

## A thin scene longer than this has started to copy the base again.
const MAXIMUM_THIN_SCENE_LINES := 40
const MINIMUM_ACTOR_SCENES := 4
## Nodes the code and the other suites find by path. A thin scene must never lose one.
const REQUIRED_NODE_PATHS: Array[String] = [
	"MotionRoot/SpriteRoot/BodySprite",
	"MotionRoot/SpriteRoot/FacingArrow",
	"MotionRoot/SpriteRoot/WeaponPivot",
	"MotionRoot/SpriteRoot/WeaponPivot/WeaponSprite",
	"MotionRoot/SpriteRoot/HealthPips",
	"MotionRoot/SpriteRoot/HealthPips/Pip0",
	"MotionRoot/SpriteRoot/HealthPips/Pip1",
	"MotionRoot/SpriteRoot/HealthPips/Pip2",
	"TelegraphAura",
	"AnimationPlayer",
	"AnimationTree",
	"AudioPlayer",
]
## The clips every actor of either role needs from the base (plan 12.1, the ones that exist today).
const REQUIRED_CLIPS: Array[StringName] = [&"idle", &"step", &"hurt", &"telegraph", &"attack", &"defeat", &"wake"]
## Frames to wait before reading the animation graph: the tree leaves Start on its first process.
const FRAMES_BEFORE_READING_GRAPH := 4


func _init() -> void:
	suite_title = "ONE ACTOR VIEW TEST"
	watchdog_seconds = 40.0
	var paths := TestPaths.new(self)
	var base_path := paths.actor_view_base_scene()
	var base_scene := paths.load_scene(base_path)
	if base_scene == null:
		finish()
		return

	_check_thin_scenes(paths, base_path)
	_check_base(base_scene)
	await _check_running_graph()
	finish()


func _check_thin_scenes(paths: TestPaths, base_path: String) -> void:
	var scene_paths := paths.list_files(paths.actors_directory(), "tscn", MINIMUM_ACTOR_SCENES + 1)
	var thin_scene_count := 0
	for scene_path in scene_paths:
		if scene_path == base_path:
			continue
		thin_scene_count += 1
		var scene_name := scene_path.get_file()
		var text := paths.read_text(scene_path)
		var line_count := text.count("\n")
		_expect(line_count <= MAXIMUM_THIN_SCENE_LINES, "%s is a thin scene (%d lines, at most %d)" % [scene_name, line_count, MAXIMUM_THIN_SCENE_LINES])
		_expect(not text.contains("[sub_resource"), "%s owns no clip, graph or other sub-resource (they live once, in the base)" % scene_name)
		var packed := load(scene_path) as PackedScene
		var parent_scene: PackedScene = packed.get_state().get_node_instance(0) if packed != null else null
		_expect(parent_scene != null and parent_scene.resource_path == base_path, "%s inherits actor_view_base.tscn" % scene_name)
		var view := packed.instantiate() if packed != null else null
		if view != null:
			var missing: Array[String] = []
			for node_path in REQUIRED_NODE_PATHS:
				if view.get_node_or_null(node_path) == null:
					missing.append(node_path)
			_expect(missing.is_empty(), "%s keeps every node path the game uses%s" % [scene_name, "" if missing.is_empty() else " (missing: %s)" % ", ".join(missing)])
			view.free()
	_expect(thin_scene_count >= MINIMUM_ACTOR_SCENES, "there are at least %d thin actor scenes (found %d)" % [MINIMUM_ACTOR_SCENES, thin_scene_count])


func _check_base(base_scene: PackedScene) -> void:
	var view := base_scene.instantiate() as ActorView
	_expect(view != null, "the base's root is an ActorView")
	if view == null:
		return
	var player := view.get_node("AnimationPlayer") as AnimationPlayer
	for clip_name in REQUIRED_CLIPS:
		_expect(player.has_animation(clip_name), "the base owns the '%s' clip" % clip_name)
	var tree := view.get_node("AnimationTree") as AnimationTree
	var machine := tree.tree_root as AnimationNodeStateMachine
	_expect(machine != null, "the base's AnimationTree root is a state machine")
	if machine != null:
		for clip_name in REQUIRED_CLIPS:
			var state := machine.get_node(clip_name) as AnimationNodeBlendTree
			var has_time_scale := state != null and state.has_node(&"TimeScale") and state.get_node(&"TimeScale") is AnimationNodeTimeScale
			_expect(has_time_scale, "the '%s' state plays its clip through a TimeScale node, so VisualDefinition.clip_speed_scales can speed it" % clip_name)
	_expect(tree.get("parameters/conditions/boots_awake") == true and tree.get("parameters/conditions/boots_asleep") == false, "the base boots awake: the Start edge to idle is open and the one to wake is closed")
	view.free()


## The graph on a running view: the hero starts in wake, everyone else in idle, and the clip speed
## scales of the definition reach the TimeScale nodes.
func _check_running_graph() -> void:
	var hero := _boot_actor("res://presentation/views/actors/player.tscn", true)
	var pawn := _boot_actor("res://presentation/views/actors/black_pawn.tscn", false)
	var knight := _boot_actor("res://presentation/views/actors/knight_enemy.tscn", false)
	await wait_frames(FRAMES_BEFORE_READING_GRAPH)
	_expect(_current_state(hero) == &"wake", "the hero boots into the wake clip (its scene closes the Start edge to idle and opens the one to wake); it is in '%s'" % _current_state(hero))
	_expect(_current_state(pawn) == &"idle", "a black pawn boots straight into idle; it is in '%s'" % _current_state(pawn))
	_expect(_current_state(knight) == &"idle", "a knight boots straight into idle; it is in '%s'" % _current_state(knight))

	_expect(is_equal_approx(_speed_scale(pawn, &"idle"), 1.0) and is_equal_approx(_speed_scale(pawn, &"step"), 1.0), "a black pawn plays every clip at the base's tempo")
	_expect(is_equal_approx(_speed_scale(knight, &"idle"), 1.25) and is_equal_approx(_speed_scale(knight, &"step"), 0.9) and is_equal_approx(_speed_scale(knight, &"telegraph"), 1.1667), "the knight's VisualDefinition speeds its idle, step and telegraph clips (1.25, 0.9, 1.1667)")
	_expect(is_equal_approx(_speed_scale(knight, &"hurt"), 1.0), "a clip the knight's definition does not list plays at 1.0")
	_expect(is_equal_approx(_speed_scale(hero, &"idle"), 1.125), "the hero's VisualDefinition speeds its idle clip (1.125)")

	# Another definition on the same view applies, and the old one's scales do not linger.
	var view := knight["view"] as ActorView
	view.definition = ContentDb.fetch(&"enemies", &"pawn_recruit") as EnemyDefinition
	(knight["world"] as EcsWorld).tick(0.016)
	_expect(is_equal_approx(_speed_scale(knight, &"idle"), 1.0) and is_equal_approx(_speed_scale(knight, &"telegraph"), 1.0), "giving a view another definition re-applies it: the knight's scales are gone")
	for actor: Dictionary in [hero, pawn, knight]:
		(actor["host"] as Node).queue_free()
	await wait_frames(2)


func _boot_actor(scene_path: String, as_player: bool) -> Dictionary:
	var host := Node2D.new()
	host.name = "Main"
	root.add_child(host)
	var view := (load(scene_path) as PackedScene).instantiate() as ActorView
	view.position = Vector2(112, 212)
	var room: Node2D = null
	if as_player:
		host.add_child(view)
	else:
		room = Node2D.new()
		host.add_child(room)
		room.add_child(view)
	var world := EcsWorld.new()
	world.manual_tick = true
	host.add_child(world)
	world.add_system(ViewSyncSystem.new())
	EcsBoot.boot(world, EcsBootOptions.for_scene(view if as_player else null, room))
	world.tick(0.016)
	return {"host": host, "view": view, "world": world}


func _current_state(actor: Dictionary) -> StringName:
	var tree := (actor["view"] as Node).get_node("AnimationTree") as AnimationTree
	var playback: AnimationNodeStateMachinePlayback = tree.get("parameters/playback")
	return playback.get_current_node()


func _speed_scale(actor: Dictionary, clip_name: StringName) -> float:
	var tree := (actor["view"] as Node).get_node("AnimationTree") as AnimationTree
	return float(tree.get("parameters/%s/TimeScale/scale" % clip_name))
