extends SceneTree

## Draws every actor in its 32 x 32 cell and writes the picture, so the owner can see "a piece is
## smaller than its cell" (docs/owner-decisions.md, 2026-10-12) without opening the editor:
##
##   assets/_generated/previews/pieces_in_cells.png
##
## One row per actor (the hero, a black pawn, a knight, a bishop), one 32 x 32 cell per pose: at
## rest facing down, right, up and left; armed (an enemy holds the pencil spear, the hero thrusts
## with the pencil) facing each way; and an enemy telegraphing. Grid lines mark the cell edges and
## a faint red square marks the margin the pieces must keep (the size table's minimum_margin).
## Whatever the game draws is drawn: the body, the health pips, the facing arrow, the held
## weapon and the telegraph aura, at the offsets the real ViewSyncSystem wrote into the real
## nodes (tools/actor_stage.gd), measured and rasterised from their opaque pixels
## (tools/actor_cell_probe.gd). Everything is shown at 4x, whole-number, nearest-neighbour.
##
## Headless: no renderer is needed. The pictures are composed on the CPU with Image, the same way
## the generators work, so it runs in the agent sandbox and on a machine without a display.
##
##   godot --headless --path . -s tools/render_actor_preview.gd
##
## The output folder is gitignored (generated, never hand-edited). The picture is the owner's
## review artefact; tests/architecture/test_pieces_inside_cell.gd is the gate.
## Exit code: 0 = written, 1 = a scene or the output could not be handled.

const ActorStage := preload("res://tools/actor_stage.gd")
const ActorCellProbe := preload("res://tools/actor_cell_probe.gd")

const OUTPUT_DIRECTORY := "res://assets/_generated/previews"
const OUTPUT_PATH := "res://assets/_generated/previews/pieces_in_cells.png"
## Whole-number zoom of the finished picture.
const ZOOM := 4
## Pixels (before zoom) left of the cells for the row names, and above them for the column names.
const NAME_STRIP_WIDTH := 46
const HEADER_HEIGHT := 14

const BACKGROUND_COLOR := Color("#1d1d24")
const CELL_COLORS: Array[Color] = [Color("#33333f"), Color("#2a2a35")]
const TEXT_COLOR := Color("#c8c8d4")
const GRID_COLOR := Color("#8a8a9c")
const MARGIN_COLOR := Color("#7a3a3a")

## The rows: which scene, in which role, under which name.
const ACTORS: Array[Dictionary] = [
	{"name": "HERO", "scene": "res://presentation/views/actors/player.tscn", "role": "player"},
	{"name": "BLACK PAWN", "scene": "res://presentation/views/actors/black_pawn.tscn", "role": "enemy"},
	{"name": "KNIGHT", "scene": "res://presentation/views/actors/knight_enemy.tscn", "role": "enemy"},
	{"name": "BISHOP", "scene": "res://presentation/views/actors/bishop_enemy.tscn", "role": "enemy"},
]
const POSE_REST := "rest"
const POSE_ARMED := "armed"
const POSE_ALERT := "alert"
## The columns: a pose and a way of facing, left to right, with the group name printed over the first.
const COLUMNS: Array[Dictionary] = [
	{"group": "AT REST", "pose": POSE_REST, "facing": Vector2i.DOWN, "name": "DOWN"},
	{"group": "", "pose": POSE_REST, "facing": Vector2i.RIGHT, "name": "RIGHT"},
	{"group": "", "pose": POSE_REST, "facing": Vector2i.UP, "name": "UP"},
	{"group": "", "pose": POSE_REST, "facing": Vector2i.LEFT, "name": "LEFT"},
	{"group": "ARMED", "pose": POSE_ARMED, "facing": Vector2i.DOWN, "name": "DOWN"},
	{"group": "", "pose": POSE_ARMED, "facing": Vector2i.RIGHT, "name": "RIGHT"},
	{"group": "", "pose": POSE_ARMED, "facing": Vector2i.UP, "name": "UP"},
	{"group": "", "pose": POSE_ARMED, "facing": Vector2i.LEFT, "name": "LEFT"},
	{"group": "ALERT", "pose": POSE_ALERT, "facing": Vector2i.DOWN, "name": "DOWN"},
]

## A 3 x 5 pixel font for the labels: '#' is a lit pixel. Only the letters the labels use.
const GLYPHS := {
	"A": [".#.", "#.#", "###", "#.#", "#.#"],
	"B": ["##.", "#.#", "##.", "#.#", "##."],
	"C": [".##", "#..", "#..", "#..", ".##"],
	"D": ["##.", "#.#", "#.#", "#.#", "##."],
	"E": ["###", "#..", "##.", "#..", "###"],
	"F": ["###", "#..", "##.", "#..", "#.."],
	"G": [".##", "#..", "#.#", "#.#", ".##"],
	"H": ["#.#", "#.#", "###", "#.#", "#.#"],
	"I": ["###", ".#.", ".#.", ".#.", "###"],
	"K": ["#.#", "#.#", "##.", "#.#", "#.#"],
	"L": ["#..", "#..", "#..", "#..", "###"],
	"M": ["#.#", "###", "###", "#.#", "#.#"],
	"N": ["##.", "#.#", "#.#", "#.#", "#.#"],
	"O": [".#.", "#.#", "#.#", "#.#", ".#."],
	"P": ["##.", "#.#", "##.", "#..", "#.."],
	"R": ["##.", "#.#", "##.", "#.#", "#.#"],
	"S": [".##", "#..", ".#.", "..#", "##."],
	"T": ["###", ".#.", ".#.", ".#.", ".#."],
	"U": ["#.#", "#.#", "#.#", "#.#", "###"],
	"W": ["#.#", "#.#", "###", "###", "#.#"],
}
const GLYPH_WIDTH := 3
const GLYPH_HEIGHT := 5
const GLYPH_ADVANCE := 4

var probe := ActorCellProbe.new()
## Texture -> its pixels as a readable RGBA8 image, read once.
var image_by_texture: Dictionary[Texture2D, Image] = {}
var cell_size := 32
var margin := 2


func _init() -> void:
	# The tree is not running while _init() is on the stack, and a sprite only has a global
	# transform once it is: wait one frame, then draw.
	_render.call_deferred()


func _render() -> void:
	await process_frame
	var table := ContentDb.piece_sizes()
	if table == null:
		printerr("RENDER ACTOR PREVIEW: content/feel/piece_sizes.tres does not load; run the editor import pass first")
		quit(1)
		return
	cell_size = table.cell_size
	margin = table.minimum_margin

	var cells_width := COLUMNS.size() * cell_size
	var cells_height := ACTORS.size() * cell_size
	var canvas := Image.create_empty(NAME_STRIP_WIDTH + cells_width, HEADER_HEIGHT + cells_height, false, Image.FORMAT_RGBA8)
	canvas.fill(BACKGROUND_COLOR)

	for column_index in COLUMNS.size():
		var column: Dictionary = COLUMNS[column_index]
		var cell_left := NAME_STRIP_WIDTH + column_index * cell_size
		if not String(column["group"]).is_empty():
			_draw_text(canvas, String(column["group"]), Vector2i(cell_left + 1, 1))
		_draw_text(canvas, String(column["name"]), Vector2i(cell_left + 1, 8))

	for row_index in ACTORS.size():
		var actor: Dictionary = ACTORS[row_index]
		_draw_text(canvas, String(actor["name"]), Vector2i(1, HEADER_HEIGHT + row_index * cell_size + cell_size / 2 - 2))
		var scene := load(String(actor["scene"])) as PackedScene
		if scene == null:
			printerr("RENDER ACTOR PREVIEW: cannot load %s" % actor["scene"])
			quit(1)
			return
		var stage := ActorStage.boot(self, scene, String(actor["role"]))
		for column_index in COLUMNS.size():
			var cell := _render_cell(stage, COLUMNS[column_index], String(actor["role"]), row_index + column_index)
			canvas.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(NAME_STRIP_WIDTH + column_index * cell_size, HEADER_HEIGHT + row_index * cell_size))
		ActorStage.free_stage(self, stage)

	canvas.resize(canvas.get_width() * ZOOM, canvas.get_height() * ZOOM, Image.INTERPOLATE_NEAREST)
	_draw_grid_and_margins(canvas)

	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY)) != OK:
		printerr("RENDER ACTOR PREVIEW: cannot create %s" % OUTPUT_DIRECTORY)
		quit(1)
		return
	var save_error := canvas.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if save_error != OK:
		printerr("RENDER ACTOR PREVIEW: cannot write %s (error %d)" % [OUTPUT_PATH, save_error])
		quit(1)
		return
	print("RENDER ACTOR PREVIEW: wrote %s (%d x %d px: %d rows x %d cells of %d px at %dx, margin %d px)" % [OUTPUT_PATH, canvas.get_width(), canvas.get_height(), ACTORS.size(), COLUMNS.size(), cell_size, ZOOM, margin])
	quit(0)


## One cell: the actor in a pose, facing a way, drawn on a checkered square. The hero has no
## "alert" pose (it never telegraphs): that cell stays empty.
func _render_cell(stage: Dictionary, column: Dictionary, role: String, checker_seed: int) -> Image:
	var cell := Image.create_empty(cell_size, cell_size, false, Image.FORMAT_RGBA8)
	cell.fill(CELL_COLORS[checker_seed % 2])
	var pose := String(column["pose"])
	if role == ActorStage.ROLE_PLAYER:
		if pose == POSE_ALERT:
			return cell
		if pose == POSE_ARMED:
			ActorStage.start_player_attack(stage, ContentDb.player().pencil_thrust)
		else:
			ActorStage.clear_player_attack(stage)
	else:
		ActorStage.give_enemy_weapon(stage, ContentDb.fetch(&"pickups", &"pencil_spear") as EnemyWeapon if pose == POSE_ARMED else null)
		if pose == POSE_ALERT:
			ActorStage.start_enemy_telegraph(stage)
	ActorStage.set_facing(stage, column["facing"])
	ActorStage.tick(stage)
	_draw_parts(cell, stage["view"] as Node2D, probe.drawn_parts(stage["view"] as Node2D))
	return cell


# --------------------------------------------------------------------------- compositing
## Rasterises each visible sprite onto the cell, back to front (z-index, then tree order), by
## asking, for every cell pixel, which picture pixel the sprite's transform puts there.
func _draw_parts(cell: Image, view: Node2D, parts: Array[Dictionary]) -> void:
	var ordered: Array[Dictionary] = []
	for index in parts.size():
		var part := parts[index].duplicate()
		part["order"] = index
		part["z"] = _effective_z_index(part["node"] as Sprite2D)
		ordered.append(part)
	ordered.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		return first["z"] < second["z"] or (first["z"] == second["z"] and first["order"] < second["order"]))

	var cell_from_world := ActorCellProbe.cell_frame_of(view).affine_inverse()
	var half_cell := cell_size / 2
	for part in ordered:
		var sprite := part["node"] as Sprite2D
		var picture := _image_of(sprite.texture)
		var sprite_from_cell := (cell_from_world * sprite.get_global_transform()).affine_inverse()
		var local_origin := sprite.get_rect().position
		var rect: Rect2 = part["rect"]
		for y in range(floori(rect.position.y) - 1, ceili(rect.end.y) + 1):
			for x in range(floori(rect.position.x) - 1, ceili(rect.end.x) + 1):
				var cell_x := x + half_cell
				var cell_y := y + half_cell
				if cell_x < 0 or cell_y < 0 or cell_x >= cell_size or cell_y >= cell_size:
					continue
				var texel := (sprite_from_cell * Vector2(x + 0.5, y + 0.5) - local_origin).floor()
				if texel.x < 0 or texel.y < 0 or texel.x >= picture.get_width() or texel.y >= picture.get_height():
					continue
				var color := picture.get_pixel(int(texel.x), int(texel.y)) * sprite.modulate
				if color.a <= 0.0:
					continue
				cell.set_pixel(cell_x, cell_y, cell.get_pixel(cell_x, cell_y).blend(color))


## The z-index the engine draws a sprite at: its own plus every relative ancestor's.
func _effective_z_index(sprite: Sprite2D) -> int:
	var total := 0
	var node: Node = sprite
	while node is CanvasItem:
		var item := node as CanvasItem
		total += item.z_index
		if not item.z_as_relative:
			break
		node = node.get_parent()
	return total


func _image_of(texture: Texture2D) -> Image:
	if image_by_texture.has(texture):
		return image_by_texture[texture]
	var picture := texture.get_image()
	if picture.is_compressed():
		picture.decompress()
	if picture.get_format() != Image.FORMAT_RGBA8:
		picture.convert(Image.FORMAT_RGBA8)
	image_by_texture[texture] = picture
	return picture


## Grid lines on every cell edge and the margin square inside every cell, one finished-picture
## pixel wide, so the zoom does not thicken them.
func _draw_grid_and_margins(canvas: Image) -> void:
	var cell_pixels := cell_size * ZOOM
	var left := NAME_STRIP_WIDTH * ZOOM
	var top := HEADER_HEIGHT * ZOOM
	for row_index in ACTORS.size():
		for column_index in COLUMNS.size():
			var cell_rect := Rect2i(left + column_index * cell_pixels, top + row_index * cell_pixels, cell_pixels, cell_pixels)
			_draw_rectangle_outline(canvas, cell_rect.grow(-margin * ZOOM), MARGIN_COLOR)
	for column_index in range(COLUMNS.size() + 1):
		_draw_line(canvas, Vector2i(left + column_index * cell_pixels, top), Vector2i(left + column_index * cell_pixels, top + ACTORS.size() * cell_pixels), GRID_COLOR)
	for row_index in range(ACTORS.size() + 1):
		_draw_line(canvas, Vector2i(left, top + row_index * cell_pixels), Vector2i(left + COLUMNS.size() * cell_pixels, top + row_index * cell_pixels), GRID_COLOR)


func _draw_rectangle_outline(canvas: Image, rect: Rect2i, color: Color) -> void:
	_draw_line(canvas, rect.position, Vector2i(rect.end.x - 1, rect.position.y), color)
	_draw_line(canvas, Vector2i(rect.position.x, rect.end.y - 1), Vector2i(rect.end.x - 1, rect.end.y - 1), color)
	_draw_line(canvas, rect.position, Vector2i(rect.position.x, rect.end.y - 1), color)
	_draw_line(canvas, Vector2i(rect.end.x - 1, rect.position.y), Vector2i(rect.end.x - 1, rect.end.y - 1), color)


## A horizontal or vertical line, both ends included, clipped to the picture.
func _draw_line(canvas: Image, from_point: Vector2i, to_point: Vector2i, color: Color) -> void:
	var step := Vector2i(signi(to_point.x - from_point.x), signi(to_point.y - from_point.y))
	var point := from_point
	while true:
		if point.x >= 0 and point.y >= 0 and point.x < canvas.get_width() and point.y < canvas.get_height():
			canvas.set_pixel(point.x, point.y, color)
		if point == to_point:
			break
		point += step


## Text in the 3 x 5 font, `top_left` in picture pixels before the zoom. Letters it does not
## know are skipped as gaps.
func _draw_text(canvas: Image, text: String, top_left: Vector2i) -> void:
	var pen_x := top_left.x
	for character in text:
		if GLYPHS.has(character):
			var rows: Array = GLYPHS[character]
			for row in GLYPH_HEIGHT:
				var row_text: String = rows[row]
				for column in GLYPH_WIDTH:
					if row_text[column] == "#":
						var pixel := Vector2i(pen_x + column, top_left.y + row)
						if pixel.x >= 0 and pixel.y >= 0 and pixel.x < canvas.get_width() and pixel.y < canvas.get_height():
							canvas.set_pixel(pixel.x, pixel.y, TEXT_COLOR)
		pen_x += GLYPH_ADVANCE
