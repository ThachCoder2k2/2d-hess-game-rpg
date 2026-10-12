extends UnboundTest

## A piece is smaller than its cell (docs/owner-decisions.md, 2026-10-12): "a chess piece must be
## smaller than its cell: not exactly cell-sized, and not bigger", and everything it shows with it
## stays in the same cell. content/feel/piece_sizes.tres says how big; this suite measures what the
## game really draws and fails when anything crosses the margin.
##
## It measures the real nodes (tools/actor_cell_probe.gd: the opaque pixels of every visible sprite,
## in pixels from the cell's centre), after the real ViewSyncSystem has written them (tools/
## actor_stage.gd boots an actor into a throwaway world), for the hero and for every enemy, facing
## every direction, holding every weapon, telegraphing, and at every keyframe of every clip:
##   - at rest, the whole actor (body, health pips, facing arrow, held weapon, telegraph aura) lies
##     inside its cell with at least `minimum_margin` pixels to every edge;
##   - at every keyframe of every clip it stays inside the cell (the margin is spent on the motion);
##   - every body picture is no larger than its kind's box, and the pieces are as tall as a real
##     chess set says: a pawn is lower than a bishop and a knight;
##   - the static scene shows what the game will draw (the editor and the game agree);
##   - every actor a ROOM scene places is measured as placed, with the room's own scale, rotation and
##     exports: a captain a room scene stretched to 1.18x would cross the cell edge and fails here
##     by room and name (the owner's rule holds for every actor the game ships, not only the four
##     thin scenes at their defaults).

const ActorStage := preload("res://tools/actor_stage.gd")
const ActorCellProbe := preload("res://tools/actor_cell_probe.gd")

const PLAYER_SCENE_PATH := "res://presentation/views/actors/player.tscn"
const BASE_SCENE_PATH := "res://presentation/views/actors/actor_view_base.tscn"
## The thin enemy scenes and the enemy each one is for.
const ENEMY_SCENE_PATHS := {
	"res://presentation/views/actors/black_pawn.tscn": &"pawn_recruit",
	"res://presentation/views/actors/knight_enemy.tscn": &"knight_tracker",
	"res://presentation/views/actors/bishop_enemy.tscn": &"bishop_zoner",
}
## A fresh actor counts as a real measurement only if it drew at least these parts.
const MINIMUM_PARTS_AT_REST := 1
## Seconds between the extra samples taken along every clip (besides its keys).
const SAMPLE_INTERVAL := 0.025

var probe := ActorCellProbe.new()
var table: PieceSizeTable
var cell_size := 32
var margin := 2.0


func _init() -> void:
	suite_title = "PIECES INSIDE THEIR CELL TEST"
	watchdog_seconds = 50.0
	table = ContentDb.piece_sizes()
	if not _expect(table != null, "the piece size table loads"):
		finish()
		return
	cell_size = table.cell_size
	margin = float(table.minimum_margin)

	_check_pictures_fit_their_boxes()
	_check_static_scenes_show_what_the_game_draws()
	# The tree is not running while _init() is on the stack, and a sprite is only "visible in the
	# tree" (and has a global transform) once it is: wait one frame before booting actors.
	await wait_frames(1)
	var hero_height := _check_actor_at_rest(PLAYER_SCENE_PATH, ActorStage.ROLE_PLAYER, null, "the hero")
	var heights_by_piece_type := {&"pawn": hero_height}
	for scene_path: String in ENEMY_SCENE_PATHS:
		var enemy := ContentDb.fetch(&"enemies", ENEMY_SCENE_PATHS[scene_path]) as EnemyDefinition
		var piece_type := enemy.visual.piece_type
		heights_by_piece_type[piece_type] = _check_actor_at_rest(scene_path, ActorStage.ROLE_ENEMY, null, scene_path.get_file())
	# Every enemy of the game on the one base scene (the owner's way to make a new enemy).
	for enemy_id in ContentDb.ids(&"enemies"):
		var enemy_definition := ContentDb.fetch(&"enemies", enemy_id) as EnemyDefinition
		_check_actor_at_rest(BASE_SCENE_PATH, ActorStage.ROLE_ENEMY, enemy_definition, "%s on actor_view_base.tscn" % enemy_id)
	_check_chess_heights(heights_by_piece_type)
	await _check_every_actor_placed_in_a_room()
	await _check_every_clip()
	finish()


# --------------------------------------------------------------------------- data
## Every body picture is within its kind's box, and its kind has a row.
func _check_pictures_fit_their_boxes() -> void:
	var visuals: Array[VisualDefinition] = [ContentDb.player().visual]
	for enemy_id in ContentDb.ids(&"enemies"):
		var visual := (ContentDb.fetch(&"enemies", enemy_id) as EnemyDefinition).visual
		if not visuals.has(visual):
			visuals.append(visual)
	for visual in visuals:
		var label := "visual '%s' (%s)" % [visual.id, visual.piece_type]
		var row := table.row_for(visual.piece_type)
		if not _expect(row != null, "%s: the size table has a row for its piece type" % label):
			continue
		if not _expect(visual.body_texture != null, "%s: it has a body picture" % label):
			continue
		var picture := Vector2i(visual.body_texture.get_size())
		_expect(picture.x <= row.body_box.x and picture.y <= row.body_box.y,
			"%s: the body picture is %s, no larger than the %s box" % [label, picture, row.body_box])
		var opaque := probe.opaque_rect_of(visual.body_texture)
		_expect(opaque.size.x <= row.body_box.x and opaque.size.y <= row.body_box.y,
			"%s: its drawn pixels are %s, no larger than the %s box" % [label, opaque.size, row.body_box])
		_expect(picture.x < cell_size and picture.y < cell_size, "%s: the picture is smaller than the %d px cell in both directions" % [label, cell_size])


## The scene file the editor shows is what the game draws: the body's static position, picture and
## alignment equal what ViewSyncSystem will write from the definition and the size table.
func _check_static_scenes_show_what_the_game_draws() -> void:
	var scene_definitions := {PLAYER_SCENE_PATH: ContentDb.player().visual}
	for scene_path: String in ENEMY_SCENE_PATHS:
		scene_definitions[scene_path] = (ContentDb.fetch(&"enemies", ENEMY_SCENE_PATHS[scene_path]) as EnemyDefinition).visual
	for scene_path: String in scene_definitions:
		var visual: VisualDefinition = scene_definitions[scene_path]
		var view := (load(scene_path) as PackedScene).instantiate() as ActorView
		var body := view.get_node("MotionRoot/SpriteRoot/BodySprite") as Sprite2D
		var expected_position := table.body_top_left(visual.piece_type, visual.body_texture.get_size(), visual.anchor_offset)
		_expect(body.texture == visual.body_texture, "%s: the editor shows the definition's body picture" % scene_path.get_file())
		_expect(body.position == expected_position and not body.centered and body.scale == Vector2.ONE,
			"%s: the editor draws the body where the game will (position %s, got %s)" % [scene_path.get_file(), expected_position, body.position])
		view.free()


# --------------------------------------------------------------------------- at rest
## Boots the actor and measures it in every state a player can see it in. Returns the body's
## drawn height in pixels (the pawn family's first pose, facing down).
func _check_actor_at_rest(scene_path: String, role: String, definition: EnemyDefinition, label: String, placed_view: ActorView = null) -> int:
	var stage: Dictionary
	if placed_view != null:
		stage = ActorStage.boot_placed(self, placed_view)
	else:
		stage = ActorStage.boot(self, load(scene_path) as PackedScene, role, definition)
	var view := stage["view"] as ActorView
	var body_height := 0

	for facing in ActorStage.FACINGS:
		ActorStage.set_facing(stage, facing)
		ActorStage.tick(stage)
		var parts := probe.drawn_parts(view)
		_expect(parts.size() >= MINIMUM_PARTS_AT_REST, "%s facing %s: something is drawn" % [label, facing])
		_expect_inside_cell(parts, margin, "%s facing %s" % [label, facing])
		if facing == Vector2i.DOWN:
			for part in parts:
				if part["part"] == ActorCellProbe.PART_BODY:
					body_height = int((part["rect"] as Rect2).size.y)
					_check_body_in_box(part["rect"], view, label)

	if role == ActorStage.ROLE_ENEMY:
		for weapon_id: StringName in [&"pencil_spear", &"ruler_blade"]:
			ActorStage.give_enemy_weapon(stage, ContentDb.fetch(&"pickups", weapon_id) as EnemyWeapon)
			for facing in ActorStage.FACINGS:
				ActorStage.set_facing(stage, facing)
				ActorStage.tick(stage)
				var parts := probe.drawn_parts(view)
				_expect(_has_part(parts, ActorCellProbe.PART_WEAPON), "%s holding the %s facing %s: the weapon is drawn" % [label, weapon_id, facing])
				_expect_inside_cell(parts, margin, "%s holding the %s facing %s" % [label, weapon_id, facing])
		ActorStage.start_enemy_telegraph(stage)
		ActorStage.tick(stage)
		var telegraph_parts := probe.drawn_parts(view)
		_expect(_has_part(telegraph_parts, ActorCellProbe.PART_AURA), "%s telegraphing: the aura is drawn" % label)
		_expect_inside_cell(telegraph_parts, margin, "%s telegraphing" % label)
	else:
		var hero := ContentDb.player()
		for profile: AttackProfile in [hero.wooden_sword, hero.pencil_thrust]:
			ActorStage.start_player_attack(stage, profile)
			for facing in ActorStage.FACINGS:
				ActorStage.set_facing(stage, facing)
				ActorStage.tick(stage)
				var parts := probe.drawn_parts(view)
				_expect(_has_part(parts, ActorCellProbe.PART_WEAPON), "%s attacking with the %s facing %s: the weapon is drawn" % [label, profile.resource_path.get_file().get_basename(), facing])
				_expect_inside_cell(parts, margin, "%s attacking with the %s facing %s" % [label, profile.resource_path.get_file().get_basename(), facing])
	ActorStage.free_stage(self, stage)
	return body_height


func _check_body_in_box(body_rect: Rect2, view: ActorView, label: String) -> void:
	var visual := _visual_of(view)
	var row := table.row_for(visual.piece_type)
	if row == null:
		return
	_expect(body_rect.size.x <= row.body_box.x and body_rect.size.y <= row.body_box.y,
		"%s: the body is drawn %s px, inside its %s box" % [label, body_rect.size, row.body_box])
	_expect(is_equal_approx(body_rect.end.y, float(row.base_offset_y)) or body_rect.end.y <= float(row.base_offset_y),
		"%s: the body stands on or above its base line (%d px below the centre; its lowest pixel is at %s)" % [label, row.base_offset_y, body_rect.end.y])


func _check_chess_heights(heights_by_piece_type: Dictionary) -> void:
	var pawn_height := int(heights_by_piece_type.get(&"pawn", 0))
	_expect(pawn_height > 0, "the pawns were measured (%d px tall)" % pawn_height)
	for piece_type: StringName in [&"knight", &"bishop"]:
		var height := int(heights_by_piece_type.get(piece_type, 0))
		_expect(height > pawn_height, "a %s is drawn taller than a pawn (%d px against %d), as in a real chess set" % [piece_type, height, pawn_height])
	_expect(pawn_height < int(table.row_for(&"pawn").body_box.y) + 1, "the pawn is drawn within its box")


# --------------------------------------------------------------------------- rooms
## Every enemy a room scene parks is booted as placed (its instance scale, rotation, definition and
## exports kept) and measured like the actors above. The static facts are asserted by name first,
## so a stretched or turned instance says what is wrong and where.
func _check_every_actor_placed_in_a_room() -> void:
	var placed_actors := 0
	for room_id in ContentDb.ids(&"rooms"):
		var room_scene := ContentDb.fetch(&"rooms", room_id) as PackedScene
		if not _expect(room_scene != null and room_scene.can_instantiate(), "room %s loads" % room_id):
			continue
		var room := room_scene.instantiate()
		for child in room.get_children():
			var view := child as ActorView
			if view == null or view.definition == null:
				continue
			var label := "room %s, %s (%s)" % [room_id, view.name, view.definition.id]
			placed_actors += 1
			_expect(view.scale == Vector2.ONE and is_zero_approx(view.rotation) and is_zero_approx(view.skew),
				"%s: placed at scale 1 and unturned (it is scale %s, rotation %.2f): a piece is smaller than its cell, so a room never stretches one" % [label, view.scale, view.rotation])
			_check_actor_at_rest("", ActorStage.ROLE_ENEMY, null, label, view)
		room.free()
		await wait_frames(1)
	_expect(placed_actors >= 5, "the actors the rooms place were really measured (%d of them)" % placed_actors)


# --------------------------------------------------------------------------- clips
## Every keyframe of every clip an actor can play leaves the piece inside its cell. The margin is
## the room a clip may spend on motion (a hop, a shake, a squash). The piece is its body, health
## pips, facing arrow and telegraph aura; the held weapon is part of the measurement in its own
## clip (the hero's attack, all four ways), and at rest above, but not while a hurt or step clip
## squashes the whole actor: a held weapon may overshoot the cell edge by a pixel for a fraction
## of a second then, as a swing does. A clip an actor never plays is skipped: the enemies never
## wake and never attack (their attack is the telegraph, req 159).
func _check_every_clip() -> void:
	var cases := [
		{"scene": PLAYER_SCENE_PATH, "role": ActorStage.ROLE_PLAYER, "label": "the hero"},
		{"scene": "res://presentation/views/actors/black_pawn.tscn", "role": ActorStage.ROLE_ENEMY, "label": "a black pawn"},
		{"scene": "res://presentation/views/actors/knight_enemy.tscn", "role": ActorStage.ROLE_ENEMY, "label": "a knight"},
		{"scene": "res://presentation/views/actors/bishop_enemy.tscn", "role": ActorStage.ROLE_ENEMY, "label": "a bishop"},
	]
	var sampled_keyframes := 0
	for case in cases:
		var is_hero: bool = case["role"] == ActorStage.ROLE_PLAYER
		var stage := ActorStage.boot(self, load(String(case["scene"])) as PackedScene, String(case["role"]))
		var view := stage["view"] as ActorView
		if not is_hero:
			ActorStage.start_enemy_telegraph(stage)
		(view.get_node("AnimationTree") as AnimationTree).active = false
		var player := view.get_node("AnimationPlayer") as AnimationPlayer
		for clip_name in player.get_animation_list():
			if clip_name == &"RESET" or (not is_hero and (clip_name == &"wake" or clip_name == &"attack")):
				continue
			var include_weapon := clip_name == &"attack"
			var facings: Array[Vector2i] = [Vector2i.RIGHT]
			if include_weapon:
				facings = ActorStage.FACINGS
			if is_hero:
				if include_weapon:
					ActorStage.start_player_attack(stage, ContentDb.player().pencil_thrust)
				else:
					ActorStage.clear_player_attack(stage)
			var worst_margin := INF
			for facing in facings:
				ActorStage.set_facing(stage, facing)
				ActorStage.tick(stage)
				for time in _keyframe_times_of(player.get_animation(clip_name)):
					player.play(clip_name)
					player.seek(time, true)
					var parts: Array[Dictionary] = []
					for part in probe.drawn_parts(view):
						if include_weapon or part["part"] != ActorCellProbe.PART_WEAPON:
							parts.append(part)
					worst_margin = minf(worst_margin, ActorCellProbe.smallest_margin(ActorCellProbe.union_of(parts), cell_size))
					sampled_keyframes += 1
				player.stop()
			_expect(worst_margin >= 0.0, "%s, clip '%s': at every sampled pose the piece%s stays inside the cell (the narrowest margin is %.2f px)" % [case["label"], clip_name, " and its weapon" if include_weapon else "", worst_margin])
		ActorStage.free_stage(self, stage)
		await wait_frames(1)
	_expect(sampled_keyframes >= 300, "the clips were really sampled (%d poses)" % sampled_keyframes)


## The times to measure a clip at: every key of every track, the end, and a sample every
## SAMPLE_INTERVAL seconds, because the pose between two keys is interpolated and can swing wider
## than either key (a body turning about its middle sweeps its corners past both).
func _keyframe_times_of(animation: Animation) -> Array[float]:
	var times: Array[float] = [0.0, animation.length]
	for track_index in animation.get_track_count():
		for key_index in animation.track_get_key_count(track_index):
			times.append(animation.track_get_key_time(track_index, key_index))
	var sample_time := SAMPLE_INTERVAL
	while sample_time < animation.length:
		times.append(sample_time)
		sample_time += SAMPLE_INTERVAL
	times.sort()
	return times


# --------------------------------------------------------------------------- helpers
func _expect_inside_cell(parts: Array[Dictionary], required_margin: float, label: String) -> void:
	var union := ActorCellProbe.union_of(parts)
	var narrowest := ActorCellProbe.smallest_margin(union, cell_size)
	_expect(narrowest >= required_margin, "%s: everything drawn is inside the cell, at least %d px from every edge (the narrowest margin is %.2f px)" % [label, int(required_margin), narrowest])


func _has_part(parts: Array[Dictionary], part_name: StringName) -> bool:
	for part in parts:
		if part["part"] == part_name:
			return true
	return false


func _visual_of(view: ActorView) -> VisualDefinition:
	if view.definition != null:
		return view.definition.visual
	return view.player_definition.visual
