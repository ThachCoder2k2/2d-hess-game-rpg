extends Node2D

var grid_world: GridWorld
var board: PrototypeBoard
var hero: PawnHero
var status_label: Label
var courage_label: Label
var objective_label: Label
var remaining_dummies := 0


func _ready() -> void:
	grid_world = GridWorld.new()
	add_child(grid_world)
	grid_world.add_block(Vector2i(7, 2))
	grid_world.add_block(Vector2i(7, 3))
	grid_world.add_block(Vector2i(7, 5))
	grid_world.add_block(Vector2i(7, 6))

	board = PrototypeBoard.new()
	board.z_index = -5
	add_child(board)
	board.setup(grid_world)

	hero = PawnHero.new()
	hero.z_index = 2
	add_child(hero)
	hero.setup(grid_world, Vector2i(3, 4))
	hero.attack_landed.connect(board.show_attack)
	hero.courage_changed.connect(_update_courage)

	for cell in [Vector2i(5, 4), Vector2i(10, 2), Vector2i(11, 6)]:
		_spawn_dummy(cell)

	_build_hud()
	_update_status("Break formation. Reach and defeat all three black pawns.")


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart_room"):
		get_tree().reload_current_scene()
	if hero != null and status_label != null:
		status_label.text = "CELL %02d,%02d   FACING %s   TARGETS %d" % [
			hero.current_cell.x,
			hero.current_cell.y,
			_facing_name(hero.facing),
			remaining_dummies,
		]


func _spawn_dummy(cell: Vector2i) -> void:
	var dummy := TrainingDummy.new()
	dummy.z_index = 1
	add_child(dummy)
	if dummy.setup(grid_world, cell):
		remaining_dummies += 1
		dummy.defeated.connect(_on_dummy_defeated)
	else:
		dummy.queue_free()


func _on_dummy_defeated(_dummy: TrainingDummy) -> void:
	remaining_dummies -= 1
	if remaining_dummies <= 0:
		_update_status("THE PAWN IS UNBOUND. First combat foundation complete.")


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var title := Label.new()
	title.position = Vector2(14, 5)
	title.text = "THE UNBOUND PAWN"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color("#fff4d6"))
	layer.add_child(title)

	courage_label = Label.new()
	courage_label.position = Vector2(182, 7)
	courage_label.add_theme_font_size_override("font_size", 9)
	courage_label.add_theme_color_override("font_color", Color("#d84a3a"))
	layer.add_child(courage_label)
	_update_courage(hero.courage)

	status_label = Label.new()
	status_label.position = Vector2(350, 7)
	status_label.size = Vector2(276, 20)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.add_theme_font_size_override("font_size", 9)
	status_label.add_theme_color_override("font_color", Color("#fff4d6"))
	layer.add_child(status_label)

	var help := Label.new()
	help.position = Vector2(14, 338)
	help.text = "WASD / ARROWS  STEP     SPACE / K  STRIKE     R  RESET"
	help.add_theme_font_size_override("font_size", 8)
	help.add_theme_color_override("font_color", Color("#fff4d6"))
	layer.add_child(help)

	objective_label = Label.new()
	objective_label.position = Vector2(176, 25)
	objective_label.size = Vector2(450, 16)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	objective_label.add_theme_font_size_override("font_size", 8)
	objective_label.add_theme_color_override("font_color", Color("#e8b83f"))
	layer.add_child(objective_label)


func _update_courage(value: int) -> void:
	if courage_label != null:
		courage_label.text = "COURAGE  " + "◆".repeat(value) + "◇".repeat(3 - value)


func _update_status(text: String) -> void:
	if objective_label != null:
		objective_label.text = text


func _facing_name(direction: Vector2i) -> String:
	if direction == Vector2i.UP:
		return "NORTH"
	if direction == Vector2i.DOWN:
		return "SOUTH"
	if direction == Vector2i.LEFT:
		return "WEST"
	return "EAST"
