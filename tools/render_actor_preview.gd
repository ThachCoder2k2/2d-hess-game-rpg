extends SceneTree

## Draws every actor in its 32 x 32 cell and writes the pictures, so the owner can see "a piece is
## smaller than its cell" (docs/owner-decisions.md, 2026-10-12) without opening the editor:
##
##   assets/_generated/previews/pieces_in_cells.png         the hero and the three enemy scenes
##   assets/_generated/previews/pieces_placed_in_rooms.png  every actor a room scene places, as placed
##
## One row per actor, one 32 x 32 cell per pose: at rest facing down, right, up and left; armed (an
## enemy holds the pencil spear, the hero thrusts with the pencil) facing each way; and an enemy
## telegraphing. Whatever the game draws is drawn: the body, the health pips, the facing arrow, the
## held weapon and the telegraph aura, at the offsets the real ViewSyncSystem wrote into the real
## nodes (tools/actor_stage.gd), measured and rasterised from their opaque pixels
## (tools/actor_cell_probe.gd). Everything is shown at 4x, whole-number, nearest-neighbour.
##
## The pictures cannot hide an overflow:
##   - every cell has a gutter of empty pixels around it, so a piece that crosses its cell's edge is
##     drawn crossing it, not cut off at it;
##   - thin grid lines mark the cell edge and a red square marks the margin the pieces must keep (the
##     size table's minimum_margin); both are drawn UNDER the pieces, never over their pixels;
##   - any piece pixel inside the margin band or beyond the cell is painted loud magenta, and the tool
##     prints how many there are (0 when all is well).
## `-- --stretch=1.4` draws the four canonical actors stretched by that factor into
## overflow_demo.png, to show what an overflow looks like (a test runs it).
##
## Headless: no renderer is needed. The pictures are composed on the CPU with Image, the same way
## the generators work, so it runs in the agent sandbox and on a machine without a display.
##
##   godot --headless --path . -s tools/render_actor_preview.gd
##
## The output folder is gitignored (generated, never hand-edited). The pictures are the owner's
## review artefact; tests/architecture/test_pieces_inside_cell.gd is the gate.
## Exit code: 0 = written, 1 = a scene or the output could not be handled.

const ActorStage := preload("res://tools/actor_stage.gd")
const ActorCellProbe := preload("res://tools/actor_cell_probe.gd")

const OUTPUT_DIRECTORY := "res://assets/_generated/previews"
const OUTPUT_PATH := "res://assets/_generated/previews/pieces_in_cells.png"
const PLACED_OUTPUT_PATH := "res://assets/_generated/previews/pieces_placed_in_rooms.png"
const OVERFLOW_DEMO_PATH := "res://assets/_generated/previews/overflow_demo.png"
## Whole-number zoom of the finished picture.
const ZOOM := 4
## Empty pixels (before zoom) around every cell, so what crosses a cell's edge can be seen.
const CELL_GUTTER := 6
## Pixels (before zoom) left of the cells for the row names, and above them for the column names.
const NAME_STRIP_WIDTH := 46
const PLACED_NAME_STRIP_WIDTH := 78
const HEADER_HEIGHT := 14

const BACKGROUND_COLOR := Color("#1d1d24")
const CELL_COLORS: Array[Color] = [Color("#33333f"), Color("#2a2a35")]
const TEXT_COLOR := Color("#c8c8d4")
const GRID_COLOR := Color("#8a8a9c")
const MARGIN_COLOR := Color("#7a3a3a")
## Any piece pixel inside the margin band or outside the cell.
const OVERFLOW_COLOR := Color("#ff2bd6")

## The rows of the first picture: which scene, in which role, under which name.
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

## A 3 x 5 pixel font for the labels: '#' is a lit pixel. Letters, digits and a few signs; anything
## else (a space) is a gap.
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
	"J": ["..#", "..#", "..#", "#.#", ".#."],
	"K": ["#.#", "#.#", "##.", "#.#", "#.#"],
	"L": ["#..", "#..", "#..", "#..", "###"],
	"M": ["#.#", "###", "###", "#.#", "#.#"],
	"N": ["##.", "#.#", "#.#", "#.#", "#.#"],
	"O": [".#.", "#.#", "#.#", "#.#", ".#."],
	"P": ["##.", "#.#", "##.", "#..", "#.."],
	"Q": [".#.", "#.#", "#.#", "##.", ".##"],
	"R": ["##.", "#.#", "##.", "#.#", "#.#"],
	"S": [".##", "#..", ".#.", "..#", "##."],
	"T": ["###", ".#.", ".#.", ".#.", ".#."],
	"U": ["#.#", "#.#", "#.#", "#.#", "###"],
	"V": ["#.#", "#.#", "#.#", "#.#", ".#."],
	"W": ["#.#", "#.#", "###", "###", "#.#"],
	"X": ["#.#", "#.#", ".#.", "#.#", "#.#"],
	"Y": ["#.#", "#.#", ".#.", ".#.", ".#."],
	"Z": ["###", "..#", ".#.", "#..", "###"],
	"0": ["###", "#.#", "#.#", "#.#", "###"],
	"1": [".#.", "##.", ".#.", ".#.", "###"],
	"2": ["##.", "..#", ".#.", "#..", "###"],
	"3": ["##.", "..#", ".#.", "..#", "##."],
	"4": ["#.#", "#.#", "###", "..#", "..#"],
	"5": ["###", "#..", "##.", "..#", "##."],
	"6": [".##", "#..", "###", "#.#", "###"],
	"7": ["###", "..#", ".#.", ".#.", ".#."],
	"8": ["###", "#.#", "###", "#.#", "###"],
	"9": ["###", "#.#", "###", "..#", "##."],
	"-": ["...", "...", "###", "...", "..."],
}
const GLYPH_WIDTH := 3
const GLYPH_HEIGHT := 5
const GLYPH_ADVANCE := 4

var probe := ActorCellProbe.new()
## Texture -> its pixels as a readable RGBA8 image, read once.
var image_by_texture: Dictionary[Texture2D, Image] = {}
var cell_size := 32
var margin := 2
## The factor `--stretch=` asked for; 1.0 draws the actors as the game does.
var stretch_factor := 1.0
## Room scenes instanced for the second picture. Their actors are taken out one by one as rows are
## drawn; the rooms themselves are freed at the end.
var rooms_in_use: Array[Node] = []


func _init() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--stretch="):
			stretch_factor = argument.trim_prefix("--stretch=").to_float()
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
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY)) != OK:
		printerr("RENDER ACTOR PREVIEW: cannot create %s" % OUTPUT_DIRECTORY)
		quit(1)
		return

	var canonical_rows := _canonical_rows()
	if stretch_factor != 1.0:
		if not _render_sheet(canonical_rows, NAME_STRIP_WIDTH, OVERFLOW_DEMO_PATH):
			quit(1)
			return
		quit(0)
		return
	if not _render_sheet(canonical_rows, NAME_STRIP_WIDTH, OUTPUT_PATH):
		quit(1)
		return
	var placed_rows := _placed_rows()
	var placed_ok := _render_sheet(placed_rows, PLACED_NAME_STRIP_WIDTH, PLACED_OUTPUT_PATH)
	for room in rooms_in_use:
		room.free()
	rooms_in_use.clear()
	quit(0 if placed_ok else 1)


# --------------------------------------------------------------------------- rows
## The hero and the three enemy scenes, each at the scale the scene has.
func _canonical_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for actor in ACTORS:
		rows.append({"name": String(actor["name"]), "second_name": "", "role": String(actor["role"]), "scene_path": String(actor["scene"]), "view": null})
	return rows


## Every actor a room scene parks, as the room scene placed it (its scale and exports kept), one
## row each: the room's short name over the actor's node name.
func _placed_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for room_id in ContentDb.ids(&"rooms"):
		var room_scene := ContentDb.fetch(&"rooms", room_id) as PackedScene
		if room_scene == null or not room_scene.can_instantiate():
			continue
		var room := room_scene.instantiate()
		rooms_in_use.append(room)
		for child in room.get_children():
			var view := child as ActorView
			if view == null or view.definition == null:
				continue
			rows.append({"name": String(room_id).get_slice("_", 0).to_upper(), "second_name": String(view.name).to_upper(), "role": ActorStage.ROLE_ENEMY, "scene_path": "", "view": view})
	return rows


## Boots one row's actor on a stage; an empty dictionary when its scene cannot be loaded.
func _boot_row(row: Dictionary) -> Dictionary:
	var role := String(row["role"])
	var placed_view := row["view"] as ActorView
	var stage: Dictionary
	if placed_view != null:
		stage = ActorStage.boot_placed(self, placed_view)
	else:
		var scene := load(String(row["scene_path"])) as PackedScene
		if scene == null:
			printerr("RENDER ACTOR PREVIEW: cannot load %s" % row["scene_path"])
			return {}
		stage = ActorStage.boot(self, scene, role)
	if stretch_factor != 1.0:
		(stage["view"] as Node2D).scale = Vector2.ONE * stretch_factor
	return stage


# --------------------------------------------------------------------------- a sheet
## One picture: a row per actor, a cell per pose, and the file. False when something failed.
func _render_sheet(rows: Array[Dictionary], name_strip_width: int, output_path: String) -> bool:
	var pitch := cell_size + 2 * CELL_GUTTER
	var canvas := Image.create_empty(name_strip_width + COLUMNS.size() * pitch, HEADER_HEIGHT + rows.size() * pitch, false, Image.FORMAT_RGBA8)
	canvas.fill(BACKGROUND_COLOR)

	for column_index in COLUMNS.size():
		var column: Dictionary = COLUMNS[column_index]
		var cell_left := name_strip_width + column_index * pitch + CELL_GUTTER
		if not String(column["group"]).is_empty():
			_draw_text(canvas, String(column["group"]), Vector2i(cell_left + 1, 1))
		_draw_text(canvas, String(column["name"]), Vector2i(cell_left + 1, 8))

	var maximum_characters := (name_strip_width - 2) / (GLYPH_ADVANCE)
	for row_index in rows.size():
		var row: Dictionary = rows[row_index]
		var row_top := HEADER_HEIGHT + row_index * pitch
		var middle := row_top + pitch / 2
		if String(row["second_name"]).is_empty():
			_draw_text(canvas, String(row["name"]), Vector2i(1, middle - 2))
		else:
			_draw_text(canvas, String(row["name"]), Vector2i(1, middle - 6))
			_draw_text(canvas, String(row["second_name"]).left(maximum_characters), Vector2i(1, middle + 1))
		var stage := _boot_row(row)
		if stage.is_empty():
			return false
		for column_index in COLUMNS.size():
			var cell := _render_cell(stage, COLUMNS[column_index], String(row["role"]), row_index + column_index)
			canvas.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(name_strip_width + column_index * pitch, row_top))
		ActorStage.free_stage(self, stage)

	var overflow_pixels := _count_pixels_of(canvas, OVERFLOW_COLOR)
	canvas.resize(canvas.get_width() * ZOOM, canvas.get_height() * ZOOM, Image.INTERPOLATE_NEAREST)
	_draw_grid_and_margins(canvas, rows.size(), name_strip_width)

	var save_error := canvas.save_png(ProjectSettings.globalize_path(output_path))
	if save_error != OK:
		printerr("RENDER ACTOR PREVIEW: cannot write %s (error %d)" % [output_path, save_error])
		return false
	print("RENDER ACTOR PREVIEW: wrote %s (%d x %d px: %d rows x %d cells of %d px at %dx, margin %d px, gutter %d px); %d pixel(s) outside the margin" % [output_path, canvas.get_width(), canvas.get_height(), rows.size(), COLUMNS.size(), cell_size, ZOOM, margin, CELL_GUTTER, overflow_pixels])
	if overflow_pixels > 0:
		printerr("RENDER ACTOR PREVIEW: %s: %d piece pixel(s) are inside the margin band or outside their cell; they are drawn in magenta" % [output_path.get_file(), overflow_pixels])
	return true


## One cell on its gutter: the actor in a pose, facing a way, drawn on a checkered square. The hero
## has no "alert" pose (it never telegraphs): that cell stays empty.
func _render_cell(stage: Dictionary, column: Dictionary, role: String, checker_seed: int) -> Image:
	var pitch := cell_size + 2 * CELL_GUTTER
	var cell := Image.create_empty(pitch, pitch, false, Image.FORMAT_RGBA8)
	cell.fill(BACKGROUND_COLOR)
	cell.fill_rect(Rect2i(CELL_GUTTER, CELL_GUTTER, cell_size, cell_size), CELL_COLORS[checker_seed % 2])
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
## asking, for every pixel, which picture pixel the sprite's transform puts there. Pixels are drawn
## wherever they fall, gutter included; one that lies inside the margin band or outside the cell
## is painted OVERFLOW_COLOR.
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
				var image_x := cell_x + CELL_GUTTER
				var image_y := cell_y + CELL_GUTTER
				if image_x < 0 or image_y < 0 or image_x >= cell.get_width() or image_y >= cell.get_height():
					continue
				var texel := (sprite_from_cell * Vector2(x + 0.5, y + 0.5) - local_origin).floor()
				if texel.x < 0 or texel.y < 0 or texel.x >= picture.get_width() or texel.y >= picture.get_height():
					continue
				var color := picture.get_pixel(int(texel.x), int(texel.y)) * sprite.modulate
				if color.a <= 0.0:
					continue
				var inside_margin_square := cell_x >= margin and cell_y >= margin and cell_x < cell_size - margin and cell_y < cell_size - margin
				if not inside_margin_square:
					cell.set_pixel(image_x, image_y, OVERFLOW_COLOR)
					continue
				cell.set_pixel(image_x, image_y, cell.get_pixel(image_x, image_y).blend(color))


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


func _count_pixels_of(canvas: Image, color: Color) -> int:
	var count := 0
	for y in canvas.get_height():
		for x in canvas.get_width():
			if canvas.get_pixel(x, y) == color:
				count += 1
	return count


## The cell edge and the margin square of every cell, one finished-picture pixel wide, so the zoom
## does not thicken them. A line is only laid where nothing but background is, so it can never
## cover a pixel of a piece.
func _draw_grid_and_margins(canvas: Image, row_count: int, name_strip_width: int) -> void:
	var pitch := cell_size + 2 * CELL_GUTTER
	var cell_pixels := cell_size * ZOOM
	for row_index in row_count:
		for column_index in COLUMNS.size():
			var cell_rect := Rect2i((name_strip_width + column_index * pitch + CELL_GUTTER) * ZOOM, (HEADER_HEIGHT + row_index * pitch + CELL_GUTTER) * ZOOM, cell_pixels, cell_pixels)
			_draw_rectangle_outline(canvas, cell_rect.grow(-margin * ZOOM), MARGIN_COLOR)
			_draw_rectangle_outline(canvas, cell_rect, GRID_COLOR)


func _draw_rectangle_outline(canvas: Image, rect: Rect2i, color: Color) -> void:
	_draw_line(canvas, rect.position, Vector2i(rect.end.x - 1, rect.position.y), color)
	_draw_line(canvas, Vector2i(rect.position.x, rect.end.y - 1), Vector2i(rect.end.x - 1, rect.end.y - 1), color)
	_draw_line(canvas, rect.position, Vector2i(rect.position.x, rect.end.y - 1), color)
	_draw_line(canvas, Vector2i(rect.end.x - 1, rect.position.y), Vector2i(rect.end.x - 1, rect.end.y - 1), color)


## A horizontal or vertical line, both ends included, clipped to the picture, laid only on pixels
## that are still background (a cell colour or the gutter's).
func _draw_line(canvas: Image, from_point: Vector2i, to_point: Vector2i, color: Color) -> void:
	var step := Vector2i(signi(to_point.x - from_point.x), signi(to_point.y - from_point.y))
	var point := from_point
	while true:
		if point.x >= 0 and point.y >= 0 and point.x < canvas.get_width() and point.y < canvas.get_height() and _is_background(canvas.get_pixel(point.x, point.y)):
			canvas.set_pixel(point.x, point.y, color)
		if point == to_point:
			break
		point += step


func _is_background(color: Color) -> bool:
	return color == BACKGROUND_COLOR or CELL_COLORS.has(color)


## Text in the 3 x 5 font, `top_left` in picture pixels before the zoom. Lower case is shown as
## capitals; characters it does not know are skipped as gaps.
func _draw_text(canvas: Image, text: String, top_left: Vector2i) -> void:
	var pen_x := top_left.x
	for character in text.to_upper():
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
