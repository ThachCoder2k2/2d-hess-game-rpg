class_name ViewSyncSystem
extends EcsSystem

## The one sanctioned data -> node bridge: positions puppet views from
## GridPos/MoveState (quad-eased slide like the old step tween), row-based
## depth (z_index = 2 + row), and step/idle clips. No other system may touch
## a node; no view reads game state.


func tick(_delta: float) -> void:
	for entity_id in world.query([EcsComponents.GRID_POS, EcsComponents.VIEW_REF]):
		var view: EcsComponents.ViewRef = world.get_component(entity_id, EcsComponents.VIEW_REF)
		if view.node == null or not is_instance_valid(view.node):
			continue
		var grid_pos: EcsComponents.GridPos = world.get_component(entity_id, EcsComponents.GRID_POS)
		var move: EcsComponents.MoveState = world.get_component(entity_id, EcsComponents.MOVE_STATE)

		var moving := move != null and move.moving
		if moving:
			var eased := 1.0 - (1.0 - move.progress) * (1.0 - move.progress)
			view.node.position = world.grid.cell_to_world(move.from_cell).lerp(world.grid.cell_to_world(move.to_cell), eased)
			view.node.z_index = 2 + move.to_cell.y
		else:
			view.node.position = world.grid.cell_to_world(grid_pos.cell)
			view.node.z_index = 2 + grid_pos.cell.y

		_play_clip(view.node, &"step" if moving else &"idle")


func _play_clip(view_node: Node2D, clip: StringName) -> void:
	var animation_player := view_node.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player == null or not animation_player.has_animation(clip):
		return
	if animation_player.current_animation == clip and animation_player.is_playing():
		return
	animation_player.play(clip)
