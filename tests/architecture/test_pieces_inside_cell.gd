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
##   - shoved by a hit (4 px, or harder) it may touch the cell's edge and never crosses it;
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
## The kinds whose body reaches up into the pip row. The pips sit on the top margin line of the
## cell, 4 px tall; a queen (26 px) and a king (28 px) stand up to or past that line, so nothing
## above them fits inside the cell: their pips are drawn over the crown. Every other row must keep
## its head at or below the pips. A new row (a boss) that is tall enough to reach them fails the
## check below by name until it is added here, which is the owner's decision to take.
const KINDS_WHOSE_PIPS_OVERLAP_THE_CROWN: Array[StringName] = [&"queen", &"king"]
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
	_check_pips_against_every_head()
	_check_the_base_scene_agrees_with_the_view_knobs()
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
	_check_a_spec_canvas_stands_in_the_cell()
	await _check_every_actor_placed_in_a_room()
	await _check_every_clip()
	finish()


# --------------------------------------------------------------------------- data
## Every body picture fits its kind's row (a tight picture inside the box, or the art spec's
## cell-sized canvas with its drawn pixels inside the box), and its kind has a row.
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
		var problems := table.picture_problems_of_texture(visual.piece_type, visual.body_texture)
		_expect(problems.is_empty(), "%s: the body picture fits the %s row (%s)" % [label, visual.piece_type, " ".join(problems)])
		var opaque := probe.opaque_rect_of(visual.body_texture)
		_expect(opaque.size.x <= row.body_box.x and opaque.size.y <= row.body_box.y,
			"%s: its drawn pixels are %s, no larger than the %s box" % [label, opaque.size, row.body_box])
		_expect(opaque.size.x < cell_size and opaque.size.y < cell_size, "%s: the drawn pixels are smaller than the %d px cell in both directions" % [label, cell_size])


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


## The health pips sit above a piece's head, inside the margin; where a kind is too tall for that
## the table says so. Measured on the base scene's real pip nodes (the row's position and every pip's
## picture size at its scale), against the head of every row of the size table.
func _check_pips_against_every_head() -> void:
	var view := (load(BASE_SCENE_PATH) as PackedScene).instantiate() as ActorView
	var pip_row := view.get_node("MotionRoot/SpriteRoot/HealthPips") as Node2D
	var band_top := INF
	var band_bottom := -INF
	var band_left := INF
	var band_right := -INF
	for child in pip_row.get_children():
		var pip := child as Sprite2D
		var half_size := Vector2(pip.texture.get_size()) * pip.scale / 2.0
		var centre := pip_row.position + pip.position
		band_top = minf(band_top, centre.y - half_size.y)
		band_bottom = maxf(band_bottom, centre.y + half_size.y)
		band_left = minf(band_left, centre.x - half_size.x)
		band_right = maxf(band_right, centre.x + half_size.x)
	view.free()
	var half_cell := cell_size / 2.0
	_expect(band_top >= -half_cell + margin and band_left >= -half_cell + margin and band_right <= half_cell - margin,
		"the pip row (x %s to %s, y %s to %s) is inside the cell's margin" % [band_left, band_right, band_top, band_bottom])
	for row in table.rows:
		var head_top := float(row.base_offset_y - row.body_box.y)
		var overlaps := head_top < band_bottom
		var expected_to_overlap := KINDS_WHOSE_PIPS_OVERLAP_THE_CROWN.has(row.piece_type)
		_expect(overlaps == expected_to_overlap,
			"a %s's head (box top %s px from the centre) %s the pip row (down to %s px)%s" % [row.piece_type, head_top, "reaches into" if overlaps else "stays below", band_bottom, "" if overlaps == expected_to_overlap else ": decide whether its pips go over its crown (KINDS_WHOSE_PIPS_OVERLAP_THE_CROWN) or the pip row moves"])


## The base scene shows, in the editor, the arrow and the held weapon where ViewSyncSystem will put
## them for a piece facing down; those places also have a home in ActorView's "In the cell" knobs.
## Two homes for one number are held equal here, so editing one without the other turns this red
## and names both.
func _check_the_base_scene_agrees_with_the_view_knobs() -> void:
	var view := (load(BASE_SCENE_PATH) as PackedScene).instantiate() as ActorView
	var arrow := view.get_node("MotionRoot/SpriteRoot/FacingArrow") as Sprite2D
	_expect(arrow.position == Vector2.DOWN * view.facing_mark_distance,
		"the base scene's facing arrow stands where the game puts it for a piece facing down (scene %s, ActorView.facing_mark_distance %s)" % [arrow.position, view.facing_mark_distance])
	var weapon := view.get_node("MotionRoot/SpriteRoot/WeaponPivot/WeaponSprite") as Sprite2D
	_expect(weapon.scale == Vector2.ONE * view.weapon_held_scale,
		"the base scene's weapon is drawn at the size the game draws an enemy's (scene %s, ActorView.weapon_held_scale %s)" % [weapon.scale, view.weapon_held_scale])
	_expect(weapon.position == Vector2(0.0, -view.weapon_rest_length),
		"the base scene's weapon is held at the distance the game holds it (scene %s, ActorView.weapon_rest_length %s)" % [weapon.position, view.weapon_rest_length])
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

	# A hit shoves the piece (HealthSystem: 4 px along the hit). The shove may spend the margin and
	# touch the cell's edge, never cross it, however hard the hit: ViewSyncSystem limits the offset.
	for facing in ActorStage.FACINGS:
		for shove_pixels: float in [4.0, 12.0]:
			ActorStage.set_facing(stage, facing)
			ActorStage.shove(stage, Vector2(facing) * shove_pixels)
			ActorStage.tick(stage)
			_expect_inside_cell(probe.drawn_parts(view), 0.0, "%s shoved %d px toward %s" % [label, int(shove_pixels), facing])
	ActorStage.shove(stage, Vector2.ZERO)
	ActorStage.tick(stage)

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


# --------------------------------------------------------------------------- the art spec's canvas
## The owner will draw every piece on the art spec's cell-sized canvas (docs/assets: 32 x 32, the
## base rim on row 30, the body box inside it with 2 px of margin). Such a picture must stand
## exactly where it was drawn: canvas pixel (x, y) shows at cell pixel (x, y), so the body lands on
## the rectangle the table says, and the whole piece keeps its margin. The pictures are made here
## (a solid body filling its kind's box), so no file has to exist for the check.
func _check_a_spec_canvas_stands_in_the_cell() -> void:
	for piece_type: StringName in [&"pawn", &"knight", &"bishop", &"rook", &"queen", &"king"]:
		var row := table.row_for(piece_type)
		var canvas_image := Image.create_empty(cell_size, cell_size, false, Image.FORMAT_RGBA8)
		var body_on_canvas := table.box_on_cell_canvas(row)
		canvas_image.fill_rect(body_on_canvas, Color("#2a2a35"))
		var canvas := ImageTexture.create_from_image(canvas_image)
		var label := "a %s drawn on the %d x %d canvas of the art spec" % [piece_type, cell_size, cell_size]

		_expect(table.picture_problems_of_texture(piece_type, canvas).is_empty(), "%s fits its row" % label)
		_expect(table.body_top_left(piece_type, canvas.get_size()) == Vector2(-cell_size / 2.0, -cell_size / 2.0),
			"%s is placed exactly on the cell (its top-left corner is the cell's)" % label)

		var definition := (ContentDb.fetch(&"enemies", &"pawn_recruit") as EnemyDefinition).duplicate() as EnemyDefinition
		var visual := definition.visual.duplicate() as VisualDefinition
		visual.piece_type = piece_type
		visual.body_texture = canvas
		definition.visual = visual
		var stage := ActorStage.boot(self, load(BASE_SCENE_PATH) as PackedScene, ActorStage.ROLE_ENEMY, definition)
		ActorStage.set_facing(stage, Vector2i.DOWN)
		ActorStage.tick(stage)
		var parts := probe.drawn_parts(stage["view"] as ActorView)
		for part in parts:
			if part["part"] == ActorCellProbe.PART_BODY:
				var expected := Rect2(Vector2(body_on_canvas.position) - Vector2(cell_size, cell_size) / 2.0, Vector2(body_on_canvas.size))
				_expect((part["rect"] as Rect2).is_equal_approx(expected), "%s is drawn at %s in the cell (it is %s)" % [label, expected, part["rect"]])
		_expect_inside_cell(parts, margin, label)
		ActorStage.free_stage(self, stage)


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
