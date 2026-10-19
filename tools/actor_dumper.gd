extends RefCounted

## Describes one actor scene as plain, sorted text (docs/game-base-plan.md 15 M2, risk 6): the
## oracle behind tests/architecture/test_actor_collapse_golden.gd. Two actor scenes that print the
## same text look the same to the rest of the game: same nodes, same values on them, same
## clips and graph, and the same entity once EcsBoot has baked it.
##
## What one description holds, in this order:
##   node <path> <Class> [script=..] [visible=false] position=.. [rotation=..] scale=.. z=..
##        [texture=..] [centered=..] [offset=..] [bus=..] ...   every node of the instanced scene
##   view <name>=<value>                    every script variable of the ActorView root
##   tree_condition <name>=<value>          the AnimationTree's initial conditions
##   clip <name>                            every clip of the AnimationPlayer
##   state <name> clip=<clip>               every state of the graph, and the clip it plays
##   transition <from> -> <to> switch=.. advance=.. condition=.. xfade=..
##   entity <id> <label> cell=..            what EcsBoot bakes from this scene: the "[entities at boot]"
##     <component>: <field>=<value> ...     lines of the world dump, header then one indented line
##                                          per component
##
## The scene is only instanced and added to a tree. Nothing ticks, so the numbers are the scene's
## own, not what an animation or a ViewSyncSystem wrote afterwards.
##
## There is no class_name on purpose: callers preload() this script, which keeps it usable on a
## fresh checkout before the editor import pass has run. Shared by tools/dump_actor_golden.gd (the
## command line) and the tests.

const WorldDumper := preload("res://tools/world_dumper.gd")

## actor id -> { "path": the scene, "role": "player" or "enemy" }. The id is what the golden file
## calls the actor. Every scene under presentation/views/actors/ that the game instances is here.
const ACTOR_SCENES := {
	"player": {"path": "res://presentation/views/actors/player.tscn", "role": "player"},
	"black_pawn": {"path": "res://presentation/views/actors/black_pawn.tscn", "role": "enemy"},
	"knight_enemy": {"path": "res://presentation/views/actors/knight_enemy.tscn", "role": "enemy"},
	"bishop_enemy": {"path": "res://presentation/views/actors/bishop_enemy.tscn", "role": "enemy"},
	"enemy_base": {"path": "res://presentation/views/actors/enemy_base.tscn", "role": "enemy"},
}
const ROLE_PLAYER := "player"
## Where the actor stands in the throwaway world: a cell of the default 16x9 board.
const ACTOR_POSITION := Vector2(112, 212)
const ACTOR_NODE_NAME := "Actor"

const FLOAT_STEP := 0.0001


## Every actor in ACTOR_SCENES whose scene still exists, as the golden file prints it: one
## "[actor <id>] ..." heading, then that actor's description.
func golden_text(tree: SceneTree, header_lines: PackedStringArray) -> String:
	var text := "\n".join(header_lines) + "\n"
	text += "\n[rooms]\n" + "\n".join(room_head_lines()) + "\n"
	for actor_id: String in ACTOR_SCENES:
		var description := describe_actor(tree, actor_id)
		if description.is_empty():
			continue
		var row: Dictionary = ACTOR_SCENES[actor_id]
		text += "\n[actor %s] scene=%s role=%s\n" % [actor_id, row["path"], row["role"]]
		text += description
	return text


## One "room <id> head_sha256=<hash> lines=<n>" line per baseline room: a fingerprint of everything
## the world dump says before its "[nodes]" section (the grid, the ASCII board, every entity and
## every component field at boot and after 120 ticks). That head is "the per-room entity set and
## cells", and a collapse of the actor scenes must not move a byte of it.
func room_head_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	for room_id in WorldDumper.BASELINE_ROOM_IDS:
		var baseline_text := FileAccess.get_file_as_string(WorldDumper.BASELINE_DIRECTORY.path_join("dump_%s.txt" % room_id))
		var head_text := room_head_of(baseline_text)
		lines.append("room %s head_sha256=%s lines=%d" % [room_id, head_text.sha256_text(), head_text.count("\n")])
	return lines


## The part of a world dump before its "[nodes]" section.
static func room_head_of(dump_text: String) -> String:
	var cut := dump_text.find("\n[nodes]")
	return dump_text.left(cut + 1) if cut >= 0 else dump_text


## Splits golden-file text into actor id -> that actor's lines (blank lines dropped).
static func sections_of(golden: String) -> Dictionary:
	var sections: Dictionary = {}
	var current_id := ""
	var current_lines := PackedStringArray()
	for line in golden.split("\n"):
		if line.begins_with("[actor ") or line.begins_with("[rooms]"):
			if not current_id.is_empty():
				sections[current_id] = current_lines
			current_id = line.get_slice("]", 0).trim_prefix("[actor ") if line.begins_with("[actor ") else ""
			current_lines = PackedStringArray()
		elif not current_id.is_empty() and not line.strip_edges().is_empty():
			current_lines.append(line)
	if not current_id.is_empty():
		sections[current_id] = current_lines
	return sections


## The description of one actor id (a key of ACTOR_SCENES), or "" when its scene is gone.
## `tree` hosts the throwaway world for the length of the call and is left as it was found.
func describe_actor(tree: SceneTree, actor_id: String) -> String:
	var row: Dictionary = ACTOR_SCENES.get(actor_id, {})
	if row.is_empty() or not ResourceLoader.exists(String(row["path"])):
		return ""
	return describe_scene(tree, String(row["path"]), String(row["role"]))


## The description of any actor scene. `role` is ROLE_PLAYER for the hero's view (booted as the
## player) and anything else for a view that carries an enemy definition.
func describe_scene(tree: SceneTree, scene_path: String, role: String) -> String:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return ""
	var host := Node2D.new()
	host.name = "Main"
	tree.root.add_child(host)
	var view := packed.instantiate() as ActorView
	view.name = ACTOR_NODE_NAME
	view.position = ACTOR_POSITION

	var room: Node2D = null
	if role == ROLE_PLAYER:
		host.add_child(view)
	else:
		room = Node2D.new()
		room.name = "CurrentZone"
		host.add_child(room)
		room.add_child(view)

	var lines := PackedStringArray()
	_append_node_lines(lines, view, "")
	_append_view_lines(lines, view)
	_append_animation_lines(lines, view)

	var world := EcsWorld.new()
	world.name = "EcsWorld"
	world.manual_tick = true
	host.add_child(world)
	EcsBoot.boot(world, EcsBootOptions.for_scene(view if role == ROLE_PLAYER else null, room))
	lines.append_array(_entity_lines(world, host))

	tree.root.remove_child(host)
	host.free()
	return "\n".join(lines) + "\n"


# --------------------------------------------------------------------------- nodes
func _append_node_lines(lines: PackedStringArray, node: Node, relative_path: String) -> void:
	var parts: Array[String] = ["node", relative_path if not relative_path.is_empty() else ".", node.get_class()]
	var script := node.get_script() as Script
	if script != null:
		parts.append("script=%s" % script.resource_path)
	var canvas_item := node as CanvasItem
	if canvas_item != null and not canvas_item.visible:
		parts.append("visible=false")
	var node_2d := node as Node2D
	if node_2d != null and not (node_2d is ActorView):
		# The root's own position is where the dump put it, not part of the scene.
		parts.append("position=%s" % _vector_text(node_2d.position))
	if node_2d != null:
		if not is_zero_approx(node_2d.rotation):
			parts.append("rotation=%s" % _float_text(node_2d.rotation))
		parts.append("scale=%s" % _vector_text(node_2d.scale))
		parts.append("z=%d" % node_2d.z_index)
	var sprite := node as Sprite2D
	if sprite != null:
		parts.append("texture=%s" % _resource_text(sprite.texture))
		parts.append("centered=%s" % str(sprite.centered).to_lower())
		if sprite.offset != Vector2.ZERO:
			parts.append("offset=%s" % _vector_text(sprite.offset))
	var audio_player := node as AudioStreamPlayer
	if audio_player != null:
		parts.append("bus=%s" % audio_player.bus)
	var animation_tree := node as AnimationTree
	if animation_tree != null:
		parts.append("active=%s" % str(animation_tree.active).to_lower())
		parts.append("anim_player=%s" % animation_tree.anim_player)
	lines.append(" ".join(parts))
	for child in node.get_children():
		_append_node_lines(lines, child, (relative_path + "/" if not relative_path.is_empty() else "") + String(child.name))


func _append_view_lines(lines: PackedStringArray, view: ActorView) -> void:
	var names: Array[String] = []
	for property: Dictionary in view.get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			names.append(String(property["name"]))
	names.sort()
	for property_name in names:
		lines.append("view %s=%s" % [property_name, _value_text(view.get(property_name))])


# --------------------------------------------------------------------------- animation
func _append_animation_lines(lines: PackedStringArray, view: ActorView) -> void:
	var player := view.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player != null:
		var clip_names: Array[String] = []
		for clip_name in player.get_animation_list():
			clip_names.append(String(clip_name))
		clip_names.sort()
		for clip_name in clip_names:
			lines.append("clip %s" % clip_name)
	var tree := view.get_node_or_null("AnimationTree") as AnimationTree
	if tree == null:
		return
	var condition_lines: Array[String] = []
	for property: Dictionary in tree.get_property_list():
		var property_name := String(property["name"])
		if property_name.begins_with("parameters/conditions/"):
			condition_lines.append("tree_condition %s=%s" % [property_name.trim_prefix("parameters/conditions/"), _value_text(tree.get(property_name))])
	condition_lines.sort()
	lines.append_array(PackedStringArray(condition_lines))
	var machine := tree.tree_root as AnimationNodeStateMachine
	if machine == null:
		return
	var state_lines: Array[String] = []
	for state_name in machine.get_node_list():
		state_lines.append("state %s clip=%s" % [state_name, _clip_of_state(machine.get_node(state_name))])
	state_lines.sort()
	lines.append_array(PackedStringArray(state_lines))
	var transition_lines: Array[String] = []
	for index in range(machine.get_transition_count()):
		var transition := machine.get_transition(index)
		transition_lines.append("transition %s -> %s switch=%d advance=%d condition=%s xfade=%s" % [
			machine.get_transition_from(index), machine.get_transition_to(index),
			transition.switch_mode, transition.advance_mode, transition.advance_condition,
			_float_text(transition.xfade_time)])
	transition_lines.sort()
	lines.append_array(PackedStringArray(transition_lines))


## The clip a graph state plays: a state is either the clip itself or a small blend tree wrapping it.
func _clip_of_state(state_node: AnimationNode) -> String:
	var clip_node := state_node as AnimationNodeAnimation
	if clip_node != null:
		return String(clip_node.animation)
	var blend_tree := state_node as AnimationNodeBlendTree
	if blend_tree != null:
		for inner_name in blend_tree.get_node_list():
			var inner := blend_tree.get_node(inner_name) as AnimationNodeAnimation
			if inner != null:
				return String(inner.animation)
	return "?"


# --------------------------------------------------------------------------- entity
func _entity_lines(world: EcsWorld, dump_root: Node) -> PackedStringArray:
	return WorldDumper.new().describe_world_entities(world, dump_root)


# --------------------------------------------------------------------------- values
func _value_text(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return str(value).to_lower()
		TYPE_INT:
			return str(value)
		TYPE_FLOAT:
			return _float_text(value)
		TYPE_VECTOR2:
			return _vector_text(value)
		TYPE_COLOR:
			return "#" + (value as Color).to_html(true)
		TYPE_STRING, TYPE_STRING_NAME:
			return var_to_str(value)
		TYPE_OBJECT:
			return _resource_text(value as Resource)
	return var_to_str(value)


func _resource_text(resource: Resource) -> String:
	if resource == null:
		return "null"
	if resource.resource_path.is_empty():
		return "inline:%s" % resource.get_class()
	return resource.resource_path


## 4 decimals, never "-0.0000".
func _float_text(number: float) -> String:
	var rounded := snappedf(number, FLOAT_STEP)
	if is_zero_approx(rounded):
		rounded = 0.0
	return "%.4f" % rounded


func _vector_text(vector: Vector2) -> String:
	return "(%s,%s)" % [_float_text(vector.x), _float_text(vector.y)]
