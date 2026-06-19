extends Node2D

var grid_world: GridWorld
var board: PrototypeBoard
var hero: PawnHero
var status_label: Label
var courage_label: Label
var skill_label: Label
var objective_label: Label
var remaining_enemies := 0
var room_ending := false


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
	hero.setup(grid_world, Vector2i(3, 7))
	hero.attack_landed.connect(board.show_player_attack)
	hero.courage_changed.connect(_update_courage)
	hero.skill_cooldown_changed.connect(_update_skill_cooldown)
	hero.defeated.connect(_on_hero_defeated)

	for cell in [Vector2i(4, 1), Vector2i(10, 1), Vector2i(13, 2)]:
		_spawn_black_pawn(cell)

	_build_hud()
	_update_status("Read the red diagonals. Break all three black pawns.")


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart_room"):
		get_tree().reload_current_scene()
	if hero != null and status_label != null:
		status_label.text = "CELL %02d,%02d   FACING %s   ENEMIES %d" % [
			hero.current_cell.x,
			hero.current_cell.y,
			_facing_name(hero.facing),
			remaining_enemies,
		]


func _spawn_black_pawn(cell: Vector2i) -> void:
	var pawn := BlackPawn.new()
	pawn.z_index = 1
	add_child(pawn)
	if pawn.setup(grid_world, cell):
		remaining_enemies += 1
		pawn.telegraph_started.connect(board.set_telegraph)
		pawn.telegraph_finished.connect(board.clear_telegraph)
		pawn.attack_resolved.connect(board.show_enemy_attack)
		pawn.defeated.connect(_on_enemy_defeated)
		pawn.activate(hero)
	else:
		pawn.queue_free()


func _on_enemy_defeated(_pawn: BlackPawn) -> void:
	remaining_enemies -= 1
	if remaining_enemies <= 0 and not room_ending:
		room_ending = true
		hero.control_enabled = false
		_update_status("THE PAWN IS UNBOUND. Pawn Ambush complete.")


func _on_hero_defeated() -> void:
	if room_ending:
		return
	room_ending = true
	_update_status("The pawn falls. The child resets the board...")
	await get_tree().create_timer(0.85).timeout
	get_tree().reload_current_scene()


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

	skill_label = Label.new()
	skill_label.position = Vector2(278, 7)
	skill_label.size = Vector2(115, 16)
	skill_label.add_theme_font_size_override("font_size", 8)
	skill_label.add_theme_color_override("font_color", Color("#8ec8e8"))
	layer.add_child(skill_label)
	_update_skill_cooldown(0.0)

	status_label = Label.new()
	status_label.position = Vector2(392, 7)
	status_label.size = Vector2(234, 20)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.add_theme_font_size_override("font_size", 8)
	status_label.add_theme_color_override("font_color", Color("#fff4d6"))
	layer.add_child(status_label)

	var help := Label.new()
	help.position = Vector2(14, 338)
	help.text = "MOVE WASD   TURN SHIFT+DIR   SWORD SPACE   THRUST Q   RESET R"
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


func _update_skill_cooldown(time_left: float) -> void:
	if skill_label == null:
		return
	skill_label.text = "Q THRUST  READY" if time_left <= 0.0 else "Q THRUST  %.1f" % time_left


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
