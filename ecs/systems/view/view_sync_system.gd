class_name ViewSyncSystem
extends EcsSystem

## The one sanctioned data -> node bridge. Positions puppet views from
## GridPos/MoveState (quad-eased slide like the old step tween), row-based
## depth (z_index = 2 + row), and drives the full appearance ported from the
## node-era actors: body tint, recoil/bob on MotionRoot, telegraph aura,
## facing arrow, weapon sprite, health pips, and edge-detected clips.
## No other system may touch a node; no view reads game state.

## Metadata key on a view: the VisualDefinition whose values were last written into its nodes.
const APPLIED_VISUAL_META := &"applied_visual_definition"
## The AnimationTree parameter that scales one state's clip speed: every state of the graph is a
## small blend tree (Animation -> TimeScale -> output), so the scale is a parameter of the state.
const CLIP_SPEED_PARAMETER_FORMAT := "parameters/%s/TimeScale/scale"


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

		var appearance := view.node as ActorView
		if appearance == null:
			_play_clip(view.node, &"step" if moving else &"idle")
			continue
		_sync_appearance(entity_id, view, appearance, moving)


func _sync_appearance(entity_id: int, view: EcsComponents.ViewRef, appearance: ActorView, moving: bool) -> void:
	_apply_visual_definition(appearance)
	var health: EcsComponents.Health = world.get_component(entity_id, EcsComponents.HEALTH)
	var ai: EcsComponents.EnemyAI = world.get_component(entity_id, EcsComponents.ENEMY_AI)
	var combat: EcsComponents.PlayerCombat = world.get_component(entity_id, EcsComponents.PLAYER_COMBAT)
	var facing: EcsComponents.Facing = world.get_component(entity_id, EcsComponents.FACING)
	var facing_direction := facing.direction if facing != null else Vector2i.ZERO
	var telegraphing := ai != null and ai.state == EcsComponents.EnemyAI.STATE_TELEGRAPH
	var hurt := health != null and health.hurt_visual_time > 0.0
	var attacking := combat != null and combat.attack_visual_time > 0.0
	var dead := health != null and health.current <= 0

	var body_sprite := appearance.get_node_or_null("MotionRoot/SpriteRoot/BodySprite") as Sprite2D
	if body_sprite != null:
		var tint := Color.WHITE
		if telegraphing:
			tint = appearance.telegraph_modulate
		elif hurt and combat != null:
			tint = appearance.hurt_modulate
		if health != null and health.invulnerable_left > 0.0 and int(Time.get_ticks_msec() / 70.0) % 2 == 0:
			tint.a = 0.35
		body_sprite.modulate = tint

	var motion_root := appearance.get_node_or_null("MotionRoot") as Node2D
	if motion_root != null:
		var offset := health.recoil if health != null else Vector2.ZERO
		if combat != null and moving:
			offset += Vector2(0.0, -1.0)
		motion_root.position = _limited_to_margin(appearance, offset)

	var aura := appearance.get_node_or_null("TelegraphAura") as Sprite2D
	if aura != null:
		aura.visible = telegraphing
		if telegraphing:
			# The telegraph clip owns the aura's size (it pulses inside the cell); this only fades it in.
			var progress := clampf(1.0 - ai.state_time_left / maxf(ai.telegraph_duration, 0.001), 0.0, 1.0)
			aura.modulate.a = 0.55 + progress * 0.35

	var arrow := appearance.get_node_or_null("MotionRoot/SpriteRoot/FacingArrow") as Sprite2D
	if arrow != null:
		arrow.visible = appearance.show_facing_mark and facing_direction != Vector2i.ZERO
		if arrow.visible:
			arrow.rotation = Vector2(facing_direction).angle() + PI / 2.0
			# On the facing side, inside the cell: the mark that used to float above a tall piece.
			arrow.position = Vector2(facing_direction).normalized() * appearance.facing_mark_distance

	_sync_weapon(entity_id, appearance, combat, facing_direction, attacking)
	_sync_health_pips(appearance, health)

	_drive_clips(view, appearance, moving, hurt, attacking, telegraphing, dead)
	view.was_hurt = hurt
	view.was_attacking = attacking
	view.was_telegraphing = telegraphing


## A hit shoves a piece a few pixels and a step lifts the hero one; neither may carry it out of its
## cell (the owner's rule, docs/owner-decisions.md 2026-10-12: everything a piece draws stays inside
## its own cell). Each axis is limited to the size table's minimum margin, the room a piece keeps
## on every side at rest: at the worst moment of a shove it touches the cell's edge and never
## crosses it. Only the drawn offset is limited; Health.recoil itself is untouched.
func _limited_to_margin(appearance: ActorView, offset: Vector2) -> Vector2:
	var piece_sizes := appearance.piece_sizes if appearance.piece_sizes != null else PieceSizeTable.new()
	var limit := float(piece_sizes.minimum_margin)
	return Vector2(clampf(offset.x, -limit, limit), clampf(offset.y, -limit, limit))


## Writes what the actor's VisualDefinition says into the view's nodes. It happens once per
## definition, not every tick: the view remembers which definition it last applied, so giving
## a view another definition applies that one and nothing repeats.
func _apply_visual_definition(appearance: ActorView) -> void:
	var visual := _visual_of(appearance)
	if visual == null or (appearance.has_meta(APPLIED_VISUAL_META) and appearance.get_meta(APPLIED_VISUAL_META) == visual):
		return
	appearance.set_meta(APPLIED_VISUAL_META, visual)
	_apply_body(appearance, visual)
	_apply_clip_speed_scales(appearance, visual)


## Stands the definition's body picture on its kind's base line (content/feel/piece_sizes.tres):
## centred sideways, its bottom edge `base_offset_y` below the cell's centre, plus the definition's
## own anchor_offset. The picture is drawn at scale 1, so what the owner draws is what is shown.
## A definition without a picture leaves the view's stand-in body alone.
func _apply_body(appearance: ActorView, visual: VisualDefinition) -> void:
	var body_sprite := appearance.get_node_or_null("MotionRoot/SpriteRoot/BodySprite") as Sprite2D
	if body_sprite == null or visual.body_texture == null:
		return
	body_sprite.texture = visual.body_texture
	body_sprite.centered = false
	body_sprite.scale = Vector2.ONE
	var piece_sizes := appearance.piece_sizes if appearance.piece_sizes != null else PieceSizeTable.new()
	body_sprite.position = piece_sizes.body_top_left(visual.piece_type, visual.body_texture.get_size(), visual.anchor_offset)


## An enemy view names its EnemyDefinition, the hero's view its PlayerDefinition; either may
## carry the VisualDefinition (null when the view names no definition).
func _visual_of(appearance: ActorView) -> VisualDefinition:
	if appearance.definition != null:
		return appearance.definition.visual
	if appearance.player_definition != null:
		return appearance.player_definition.visual
	return null


## Every state of the actor's graph plays its clip through a TimeScale node (see
## actor_view_base.tscn); this sets each one from the definition, 1.0 where it names no scale.
func _apply_clip_speed_scales(appearance: ActorView, visual: VisualDefinition) -> void:
	var tree := appearance.get_node_or_null("AnimationTree") as AnimationTree
	if tree == null:
		return
	var state_machine := tree.tree_root as AnimationNodeStateMachine
	if state_machine == null:
		return
	for state_name in state_machine.get_node_list():
		if state_name == &"Start" or state_name == &"End":
			continue
		tree.set(CLIP_SPEED_PARAMETER_FORMAT % state_name, visual.clip_speed_scales.get(state_name, 1.0))


## The animation state graph lives on each actor's AnimationTree (editor-owned:
## states, transitions, xfades, at_end recovery). This system only publishes
## facts: locomotion flows through the graph's auto conditions; one-shots
## (hurt/attack/telegraph) enter via travel() on state edges, because a state
## machine cannot express "from any state" entries. Views without a tree fall
## back to direct AnimationPlayer play() so bare test views keep working.
func _drive_clips(view: EcsComponents.ViewRef, appearance: ActorView, moving: bool, hurt: bool, attacking: bool, telegraphing: bool, dead: bool) -> void:
	var tree := appearance.get_node_or_null("AnimationTree") as AnimationTree
	# Death outranks everything: enter the defeat clip once, then hold its
	# final pose (the graph's defeat state has no exit) until the bridge
	# frees the view.
	if dead:
		if not view.was_dead:
			view.was_dead = true
			if tree != null:
				var death_playback: AnimationNodeStateMachinePlayback = tree.get("parameters/playback")
				if death_playback != null:
					death_playback.travel(&"defeat")
			else:
				_play_clip(appearance, &"defeat")
		return
	if tree == null:
		if hurt and not view.was_hurt:
			_play_clip(appearance, &"hurt")
		elif attacking and not view.was_attacking:
			_play_clip(appearance, &"attack")
		elif telegraphing and not view.was_telegraphing:
			_play_clip(appearance, &"telegraph")
		elif not hurt and not attacking and not telegraphing:
			_play_clip(appearance, &"step" if moving else &"idle")
		return
	tree.set("parameters/conditions/moving", moving)
	tree.set("parameters/conditions/not_moving", not moving)
	tree.set("parameters/conditions/not_telegraphing", not telegraphing)
	var playback: AnimationNodeStateMachinePlayback = tree.get("parameters/playback")
	if playback == null:
		return
	if hurt and not view.was_hurt:
		playback.travel(&"hurt")
	elif attacking and not view.was_attacking:
		playback.travel(&"attack")
	elif telegraphing and not view.was_telegraphing:
		playback.travel(&"telegraph")


func _sync_weapon(entity_id: int, appearance: ActorView, combat: EcsComponents.PlayerCombat, facing_direction: Vector2i, attacking: bool) -> void:
	var pivot := appearance.get_node_or_null("MotionRoot/SpriteRoot/WeaponPivot") as Node2D
	var sprite := appearance.get_node_or_null("MotionRoot/SpriteRoot/WeaponPivot/WeaponSprite") as Sprite2D
	if pivot == null or sprite == null:
		return
	var weapon_texture := appearance.default_weapon_texture
	var reach := 1.0
	var visible := false
	if combat != null:
		visible = combat.sword_unlocked and attacking and facing_direction != Vector2i.ZERO
		if combat.active_attack != null:
			if combat.active_attack.texture != null:
				weapon_texture = combat.active_attack.texture
			reach = maxf(1.0, float(combat.active_attack.range_cells))
	else:
		var slot: EcsComponents.WeaponSlot = world.get_component(entity_id, EcsComponents.WEAPON_SLOT)
		var weapon: EnemyWeapon = slot.weapon if slot != null else null
		visible = weapon != null and facing_direction != Vector2i.ZERO
		if weapon != null and weapon.texture != null:
			weapon_texture = weapon.texture
	pivot.visible = visible and weapon_texture != null
	if not pivot.visible:
		return
	sprite.texture = weapon_texture
	pivot.position = appearance.weapon_anchor + Vector2(facing_direction) * 4.0
	pivot.rotation = Vector2(facing_direction).angle() + PI / 2.0
	sprite.position = Vector2(0.0, -appearance.weapon_rest_length * (1.0 + (reach - 1.0) * 0.28))
	sprite.scale = Vector2.ONE * appearance.weapon_held_scale * (1.12 if combat != null else 1.0)


func _sync_health_pips(appearance: ActorView, health: EcsComponents.Health) -> void:
	var pips_root := appearance.get_node_or_null("MotionRoot/SpriteRoot/HealthPips") as Node2D
	if pips_root == null:
		return
	pips_root.visible = appearance.show_health and health != null and health.max_value > 1
	if not pips_root.visible:
		return
	var pips := pips_root.get_children()
	for index in pips.size():
		var pip := pips[index] as Sprite2D
		if pip == null:
			continue
		pip.visible = index < health.max_value
		pip.texture = appearance.pip_full_texture if index < health.current else appearance.pip_empty_texture


func _play_clip(view_node: Node2D, clip: StringName) -> void:
	var animation_player := view_node.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player == null or not animation_player.has_animation(clip):
		return
	if animation_player.current_animation == clip and animation_player.is_playing():
		return
	animation_player.play(clip)
