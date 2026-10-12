extends SceneTree

const OUT_DIR := "res://assets/sprites/generated/rooms"
const OUT_T1 := OUT_DIR + "/t1_white_kings_fall_room.png"
const OUT_T2 := OUT_DIR + "/t2_fallen_sword_tile_room.png"

const W := 640
const H := 360
const GRID_ORIGIN := Vector2i(64, 36)
const CELL := 32
const BOARD := Vector2i(16, 9)

var image := Image.create(W, H, false, Image.FORMAT_RGBA8)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_draw_t1()
	var err := image.save_png(OUT_T1)
	if err != OK:
		printerr("Failed to save %s: %s" % [OUT_T1, err])
		quit(1)
		return
	print("Generated %s" % OUT_T1)
	image = Image.create(W, H, false, Image.FORMAT_RGBA8)
	_draw_t2()
	err = image.save_png(OUT_T2)
	if err != OK:
		printerr("Failed to save %s: %s" % [OUT_T2, err])
		quit(1)
		return
	print("Generated %s" % OUT_T2)
	quit(0)


func _draw_t1() -> void:
	_draw_room_base()

	# Royal lane and fallen king focal point.
	for y in range(1, 9):
		_rect(Rect2i(GRID_ORIGIN + Vector2i(7, y) * CELL, Vector2i(CELL * 2, CELL)), Color("#b33545", 0.78))
	_rect(Rect2i(GRID_ORIGIN + Vector2i(7, 1) * CELL, Vector2i(CELL * 2, 4)), Color("#dc5160", 0.65))
	_draw_fallen_king(Vector2i(320, 170))
	_draw_crown(Vector2i(330, 112))

	# Child-room props stay outside the combat board, so the room reads as a bedroom.
	_draw_bed(Vector2i(458, 46))
	_draw_toybox(Vector2i(42, 238))
	_draw_blocks(Vector2i(504, 256))
	_draw_crayons(Vector2i(82, 296))
	_draw_books(Vector2i(516, 294))
	_draw_exit_arrow(Vector2i(528, 84))


func _draw_t2() -> void:
	_draw_room_base()
	for y in range(1, 9):
		_rect(Rect2i(GRID_ORIGIN + Vector2i(7, y) * CELL, Vector2i(CELL * 2, CELL)), Color("#ad3444", 0.70))
	_rect(Rect2i(GRID_ORIGIN + Vector2i(0, 5) * CELL, Vector2i(CELL * 7, CELL)), Color("#ede0b8", 0.20))
	_rect(Rect2i(GRID_ORIGIN + Vector2i(1, 5) * CELL + Vector2i(0, 14), Vector2i(CELL * 5, 4)), Color("#c9ba83"))
	_rect(Rect2i(GRID_ORIGIN + Vector2i(3, 5) * CELL + Vector2i(10, 7), Vector2i(8, 8)), Color("#f2d56b"))
	_draw_broken_black_pawn(Vector2i(224, 106))
	_draw_child_light(Vector2i(284, 198))
	_draw_fallen_sword(Vector2i(288, 210))
	_draw_bed(Vector2i(456, 46))
	_draw_toybox(Vector2i(42, 238))
	_draw_blocks(Vector2i(506, 256))
	_draw_books(Vector2i(520, 294))
	_draw_exit_arrow(Vector2i(528, 84))


func _draw_room_base() -> void:
	image.fill(Color("#171218"))
	_rect(Rect2i(0, 0, W, H), Color("#171218"))
	_rect(Rect2i(16, 12, 608, 336), Color("#2b2026"))
	_rect(Rect2i(28, 24, 584, 312), Color("#67452d"))

	for y in range(24, 336, 24):
		_rect(Rect2i(28, y, 584, 2), Color("#7d5738"))
	for x in range(28, 612, 72):
		_rect(Rect2i(x, 24, 2, 312), Color("#563820"))
	_rect(Rect2i(36, 30, 568, 300), Color("#9b7045"))
	for y in range(42, 324, 28):
		_rect(Rect2i(36, y, 568, 1), Color("#8b623d"))
	for x in range(56, 584, 80):
		_rect(Rect2i(x, 30, 1, 300), Color("#b0814f"))

	var rug := Rect2i(GRID_ORIGIN - Vector2i(12, 12), BOARD * CELL + Vector2i(24, 24))
	_rect(rug.grow(7), Color("#3a242d"))
	_rect(rug.grow(3), Color("#8d2f3f"))
	_rect(rug, Color("#281d22"))
	_rect(Rect2i(rug.position + Vector2i(6, 6), rug.size - Vector2i(12, 12)), Color("#4a3541"))

	for y in BOARD.y:
		for x in BOARD.x:
			var c := Color("#d9d0bd") if (x + y) % 2 == 0 else Color("#6d695d")
			var cell_rect := Rect2i(GRID_ORIGIN + Vector2i(x, y) * CELL, Vector2i(CELL, CELL))
			_rect(cell_rect, c)
			_rect(Rect2i(cell_rect.position, Vector2i(CELL, 2)), Color("#3b252d"))
			_rect(Rect2i(cell_rect.position, Vector2i(2, CELL)), Color("#3b252d"))
			if (x + y) % 2 == 0:
				_rect(Rect2i(cell_rect.position + Vector2i(8, 8), Vector2i(2, 8)), Color("#ebe5d4", 0.26))
				_rect(Rect2i(cell_rect.position + Vector2i(16, 16), Vector2i(2, 7)), Color("#ebe5d4", 0.20))


func _draw_fallen_king(pos: Vector2i) -> void:
	_rect(Rect2i(pos + Vector2i(-35, 17), Vector2i(78, 10)), Color("#171218", 0.45))
	_rect(Rect2i(pos + Vector2i(-18, -36), Vector2i(38, 70)), Color("#f1e5c5"))
	_rect(Rect2i(pos + Vector2i(-26, 10), Vector2i(58, 18)), Color("#e1cfaa"))
	_rect(Rect2i(pos + Vector2i(-9, -52), Vector2i(18, 18)), Color("#f7ecd0"))
	_rect(Rect2i(pos + Vector2i(-2, -62), Vector2i(4, 18)), Color("#f7ecd0"))
	_rect(Rect2i(pos + Vector2i(-10, -56), Vector2i(20, 4)), Color("#f7ecd0"))
	_rect(Rect2i(pos + Vector2i(-28, 30), Vector2i(70, 5)), Color("#4a2c2f"))


func _draw_crown(pos: Vector2i) -> void:
	_rect(Rect2i(pos + Vector2i(-18, 9), Vector2i(42, 9)), Color("#d89d23"))
	_rect(Rect2i(pos + Vector2i(-15, -3), Vector2i(8, 16)), Color("#f5c84a"))
	_rect(Rect2i(pos + Vector2i(-2, -12), Vector2i(9, 25)), Color("#ffd65a"))
	_rect(Rect2i(pos + Vector2i(13, -5), Vector2i(8, 18)), Color("#f5c84a"))


func _draw_broken_black_pawn(pos: Vector2i) -> void:
	_rect(Rect2i(pos + Vector2i(-22, 12), Vector2i(50, 9)), Color("#171218", 0.50))
	_rect(Rect2i(pos + Vector2i(-12, -14), Vector2i(26, 30)), Color("#171218"))
	_rect(Rect2i(pos + Vector2i(-16, 10), Vector2i(36, 8)), Color("#2a2025"))
	_rect(Rect2i(pos + Vector2i(-8, -26), Vector2i(16, 16)), Color("#211920"))
	_rect(Rect2i(pos + Vector2i(10, -5), Vector2i(16, 5)), Color("#47323a"))


func _draw_child_light(pos: Vector2i) -> void:
	_rect(Rect2i(pos + Vector2i(-38, 8), Vector2i(78, 5)), Color("#f2d56b"))
	_rect(Rect2i(pos + Vector2i(-30, 0), Vector2i(58, 3)), Color("#8ec8e8"))
	_rect(Rect2i(pos + Vector2i(34, -18), Vector2i(6, 6)), Color("#8ec8e8"))
	_rect(Rect2i(pos + Vector2i(-44, -8), Vector2i(5, 5)), Color("#f2d56b"))


func _draw_fallen_sword(pos: Vector2i) -> void:
	_rect(Rect2i(pos + Vector2i(-22, 20), Vector2i(72, 6)), Color("#32242c"))
	for i in range(0, 70, 4):
		_rect(Rect2i(pos + Vector2i(-28 + i, 20 - i), Vector2i(8, 4)), Color("#9bd8f1"))
		_rect(Rect2i(pos + Vector2i(-26 + i, 20 - i), Vector2i(4, 1)), Color("#e8f7ff"))
	_rect(Rect2i(pos + Vector2i(-34, 16), Vector2i(34, 6)), Color("#d8b340"))
	_rect(Rect2i(pos + Vector2i(-46, 6), Vector2i(10, 28)), Color("#d8b340"))
	_rect(Rect2i(pos + Vector2i(-50, 16), Vector2i(18, 6)), Color("#7a5028"))


func _draw_bed(pos: Vector2i) -> void:
	_rect(Rect2i(pos, Vector2i(126, 68)), Color("#5b3927"))
	_rect(Rect2i(pos + Vector2i(8, 8), Vector2i(110, 52)), Color("#5f7fa7"))
	_rect(Rect2i(pos + Vector2i(8, 8), Vector2i(110, 20)), Color("#f0e9d7"))
	_rect(Rect2i(pos + Vector2i(8, 42), Vector2i(110, 18)), Color("#7e549d"))
	_rect(Rect2i(pos + Vector2i(18, 14), Vector2i(46, 16)), Color("#fbf3dc"))


func _draw_toybox(pos: Vector2i) -> void:
	_rect(Rect2i(pos, Vector2i(92, 54)), Color("#71451f"))
	_rect(Rect2i(pos + Vector2i(8, 8), Vector2i(76, 34)), Color("#9b6129"))
	_rect(Rect2i(pos + Vector2i(36, 18), Vector2i(20, 8)), Color("#d9b347"))


func _draw_blocks(pos: Vector2i) -> void:
	_rect(Rect2i(pos, Vector2i(22, 22)), Color("#2d7b8a"))
	_rect(Rect2i(pos + Vector2i(28, -6), Vector2i(22, 22)), Color("#db7b22"))
	_rect(Rect2i(pos + Vector2i(58, 4), Vector2i(22, 22)), Color("#3e69ad"))
	_rect(Rect2i(pos + Vector2i(6, 26), Vector2i(22, 22)), Color("#cbb14b"))


func _draw_crayons(pos: Vector2i) -> void:
	_rect(Rect2i(pos, Vector2i(34, 5)), Color("#f0dd75"))
	_rect(Rect2i(pos + Vector2i(42, -5), Vector2i(42, 5)), Color("#76b7d4"))
	_rect(Rect2i(pos + Vector2i(20, 13), Vector2i(40, 5)), Color("#e78343"))


func _draw_books(pos: Vector2i) -> void:
	_rect(Rect2i(pos, Vector2i(62, 10)), Color("#314f8d"))
	_rect(Rect2i(pos + Vector2i(-8, 12), Vector2i(72, 10)), Color("#e6dfc8"))
	_rect(Rect2i(pos + Vector2i(6, 24), Vector2i(54, 10)), Color("#7aa5a8"))


func _draw_exit_arrow(pos: Vector2i) -> void:
	_rect(Rect2i(pos + Vector2i(-10, -4), Vector2i(30, 8)), Color("#dfb84a"))
	_rect(Rect2i(pos + Vector2i(14, -10), Vector2i(8, 20)), Color("#dfb84a"))


func _rect(rect: Rect2i, color: Color) -> void:
	image.fill_rect(rect, color)
