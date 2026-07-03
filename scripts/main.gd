extends Node2D

var grid_world: GridWorld
var director: EncounterDirector
var board: PrototypeBoard
var hero: PawnHero
var status_label: Label
var courage_label: Label
var skill_label: Label
var skill_fill: ColorRect
var encounter_label: Label
var objective_label: Label
var token_label: Label
var result_panel: ColorRect
var result_label: Label
var remaining_enemies := 0
var total_enemies := 0
var room_ending := false
var debug_enabled := true
var enemies: Array[FreeEnemy] = []


func _ready() -> void:
	grid_world = GridWorld.new()
	add_child(grid_world)
	grid_world.add_block(Vector2i(7, 2))
	grid_world.add_block(Vector2i(7, 3))
	grid_world.add_block(Vector2i(7, 5))
	grid_world.add_block(Vector2i(7, 6))

	director = EncounterDirector.new()
	add_child(director)
	director.token_changed.connect(_update_token_owner)

	board = PrototypeBoard.new()
	board.z_index = -5
	add_child(board)
	board.setup(grid_world)

	hero = PawnHero.new()
	hero.z_index = 3
	add_child(hero)
	hero.setup(grid_world, Vector2i(3, 7))
	hero.attack_landed.connect(board.show_player_attack)
	hero.courage_changed.connect(_update_courage)
	hero.skill_cooldown_changed.connect(_update_skill_cooldown)
	hero.defeated.connect(_on_hero_defeated)

	_spawn_weapon(Vector2i(5, 5), EnemyWeapon.pencil_spear())
	_spawn_weapon(Vector2i(11, 6), EnemyWeapon.ruler_blade())
	_spawn_enemy(BlackPawn.new(), Vector2i(4, 1))
	var armed_pawn := BlackPawn.new()
	armed_pawn.definition = load("res://resources/enemies/pawn_armed.tres") as EnemyDefinition
	_spawn_enemy(armed_pawn, Vector2i(10, 1))
	_spawn_enemy(KnightEnemy.new(), Vector2i(13, 2))

	_build_hud()
	_update_status("First clash: read the warning cells, deny the weapons, break the black line.")


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart_room"):
		get_tree().reload_current_scene()
	if Input.is_key_pressed(KEY_F3) and not _debug_key_was_pressed:
		_set_debug_enabled(not debug_enabled)
	_debug_key_was_pressed = Input.is_key_pressed(KEY_F3)
	if hero != null and status_label != null:
		status_label.text = "CELL %02d,%02d  FACE %s" % [
			hero.current_cell.x,
			hero.current_cell.y,
			_facing_name(hero.facing),
		]


func _spawn_weapon(cell: Vector2i, weapon: EnemyWeapon) -> void:
	var pickup := WeaponPickup.new()
	pickup.z_index = 1
	add_child(pickup)
	if not pickup.setup(grid_world, cell, weapon):
		pickup.queue_free()


func _spawn_enemy(enemy: FreeEnemy, cell: Vector2i, starting_weapon: EnemyWeapon = null) -> void:
	enemy.z_index = 2
	add_child(enemy)
	if not enemy.setup(grid_world, cell):
		enemy.queue_free()
		return
	remaining_enemies += 1
	total_enemies += 1
	enemies.append(enemy)
	enemy.telegraph_started.connect(board.set_telegraph)
	enemy.telegraph_finished.connect(board.clear_telegraph)
	enemy.attack_resolved.connect(board.show_enemy_attack)
	enemy.weapon_changed.connect(_on_enemy_weapon_changed)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.intent_changed.connect(board.set_enemy_intent)
	if starting_weapon != null:
		enemy.equip(starting_weapon)
	elif enemy.definition != null and enemy.definition.default_weapon != null:
		enemy.equip(enemy.definition.default_weapon.duplicate(true))
	enemy.activate(hero, director)
	enemy.set_debug_enabled(debug_enabled)


func _on_enemy_weapon_changed(enemy: FreeEnemy, weapon: EnemyWeapon) -> void:
	if objective_label == null or weapon == null:
		return
	var piece_name := "Knight" if enemy is KnightEnemy else "Pawn"
	_update_status("%s picked up %s. Its chess attack has been replaced." % [piece_name, weapon.display_name])


func _on_enemy_defeated(enemy: FreeEnemy) -> void:
	enemies.erase(enemy)
	board.clear_enemy_debug(enemy)
	remaining_enemies -= 1
	_update_encounter_count()
	if remaining_enemies <= 0 and not room_ending:
		room_ending = true
		director.set_paused(true)
		hero.control_enabled = false
		_update_status("THE PAWN IS UNBOUND. The first clash is clear.")
		_show_result("ROOM CLEARED", "PRESS R TO RESET")


var _debug_key_was_pressed := false


func _set_debug_enabled(value: bool) -> void:
	debug_enabled = value
	board.set_debug_enabled(value)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.set_debug_enabled(value)
	_update_status("DEBUG VIEW ON: boundaries, paths, and behavior labels." if value else "DEBUG VIEW OFF.")


func _on_hero_defeated() -> void:
	if room_ending:
		return
	room_ending = true
	director.set_paused(true)
	_update_status("The pawn falls. The child resets the board...")
	_show_result("THE PAWN FALLS", "THE CHILD RESETS THE BOARD")
	var tree := get_tree()
	if tree == null:
		return
	await tree.create_timer(0.85).timeout
	if is_inside_tree():
		tree.reload_current_scene()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var top_panel := ColorRect.new()
	top_panel.position = Vector2(8, 4)
	top_panel.size = Vector2(624, 42)
	top_panel.color = Color("#241b22", 0.82)
	layer.add_child(top_panel)

	var title_strip := ColorRect.new()
	title_strip.position = Vector2(12, 8)
	title_strip.size = Vector2(150, 18)
	title_strip.color = Color("#493f3a", 0.72)
	layer.add_child(title_strip)

	var title := Label.new()
	title.position = Vector2(18, 9)
	title.text = "THE UNBOUND PAWN"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color("#fff4d6"))
	layer.add_child(title)

	courage_label = Label.new()
	courage_label.position = Vector2(176, 8)
	courage_label.size = Vector2(112, 16)
	courage_label.add_theme_font_size_override("font_size", 9)
	courage_label.add_theme_color_override("font_color", Color("#d84a3a"))
	layer.add_child(courage_label)
	_update_courage(hero.courage)

	var skill_back := ColorRect.new()
	skill_back.position = Vector2(300, 13)
	skill_back.size = Vector2(92, 7)
	skill_back.color = Color("#1a2730", 0.95)
	layer.add_child(skill_back)

	skill_fill = ColorRect.new()
	skill_fill.position = skill_back.position
	skill_fill.size = skill_back.size
	skill_fill.color = Color("#8ec8e8", 0.90)
	layer.add_child(skill_fill)

	skill_label = Label.new()
	skill_label.position = Vector2(300, 23)
	skill_label.size = Vector2(112, 12)
	skill_label.add_theme_font_size_override("font_size", 8)
	skill_label.add_theme_color_override("font_color", Color("#8ec8e8"))
	layer.add_child(skill_label)
	_update_skill_cooldown(0.0)

	status_label = Label.new()
	status_label.position = Vector2(438, 8)
	status_label.size = Vector2(184, 15)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.add_theme_font_size_override("font_size", 8)
	status_label.add_theme_color_override("font_color", Color("#fff4d6"))
	layer.add_child(status_label)

	encounter_label = Label.new()
	encounter_label.position = Vector2(438, 22)
	encounter_label.size = Vector2(184, 12)
	encounter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	encounter_label.add_theme_font_size_override("font_size", 8)
	encounter_label.add_theme_color_override("font_color", Color("#ff9a75"))
	layer.add_child(encounter_label)
	_update_encounter_count()

	var objective_panel := ColorRect.new()
	objective_panel.position = Vector2(130, 28)
	objective_panel.size = Vector2(494, 14)
	objective_panel.color = Color("#30242a", 0.74)
	layer.add_child(objective_panel)

	var help := Label.new()
	var help_panel := ColorRect.new()
	help_panel.position = Vector2(8, 331)
	help_panel.size = Vector2(624, 22)
	help_panel.color = Color("#241b22", 0.74)
	layer.add_child(help_panel)

	help.position = Vector2(14, 338)
	help.text = "MOVE WASD  TURN SHIFT+DIR  SWORD SPACE  THRUST Q  RESET R  DEBUG F3"
	help.add_theme_font_size_override("font_size", 8)
	help.add_theme_color_override("font_color", Color("#fff4d6"))
	layer.add_child(help)

	objective_label = Label.new()
	objective_label.position = Vector2(136, 25)
	objective_label.size = Vector2(490, 16)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	objective_label.add_theme_font_size_override("font_size", 8)
	objective_label.add_theme_color_override("font_color", Color("#e8b83f"))
	layer.add_child(objective_label)

	token_label = Label.new()
	token_label.position = Vector2(490, 326)
	token_label.size = Vector2(136, 14)
	token_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	token_label.add_theme_font_size_override("font_size", 7)
	token_label.add_theme_color_override("font_color", Color("#ff9a75"))
	layer.add_child(token_label)
	_update_token_owner(null)

	result_panel = ColorRect.new()
	result_panel.position = Vector2(170, 146)
	result_panel.size = Vector2(300, 68)
	result_panel.color = Color("#241b22", 0.84)
	result_panel.visible = false
	layer.add_child(result_panel)

	result_label = Label.new()
	result_label.position = Vector2(0, 151)
	result_label.size = Vector2(640, 58)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 16)
	result_label.add_theme_color_override("font_color", Color("#fff4d6"))
	result_label.add_theme_color_override("font_shadow_color", Color(0.04, 0.03, 0.04, 0.95))
	result_label.add_theme_constant_override("shadow_offset_x", 2)
	result_label.add_theme_constant_override("shadow_offset_y", 2)
	result_label.visible = false
	layer.add_child(result_label)


func _update_courage(value: int) -> void:
	if courage_label != null:
		courage_label.text = "COURAGE " + "◆".repeat(value) + "◇".repeat(3 - value)


func _update_skill_cooldown(time_left: float) -> void:
	if skill_label == null:
		return
	skill_label.text = "Q THRUST READY" if time_left <= 0.0 else "Q THRUST %.1f" % time_left
	if skill_fill != null:
		var ratio := 1.0 if time_left <= 0.0 else clampf(1.0 - time_left / hero.pencil_thrust_cooldown, 0.0, 1.0)
		skill_fill.size.x = 92.0 * ratio
		skill_fill.color = Color("#8ec8e8", 0.9) if time_left <= 0.0 else Color("#e8b83f", 0.82)


func _update_token_owner(owner: Node) -> void:
	if token_label == null:
		return
	if owner == null:
		token_label.text = "ENEMY STRIKE READY"
	else:
		token_label.text = "STRIKE: " + ("KNIGHT" if owner is KnightEnemy else "PAWN")


func _update_encounter_count() -> void:
	if encounter_label != null:
		encounter_label.text = "ENEMIES %d/%d" % [remaining_enemies, total_enemies]


func _update_status(text: String) -> void:
	if objective_label != null:
		objective_label.text = text


func _show_result(title: String, subtitle: String) -> void:
	if result_label == null:
		return
	if result_panel != null:
		result_panel.visible = true
	result_label.text = title + "\n" + subtitle
	result_label.visible = true


func _facing_name(direction: Vector2i) -> String:
	if direction == Vector2i.UP:
		return "N"
	if direction == Vector2i.DOWN:
		return "S"
	if direction == Vector2i.LEFT:
		return "W"
	return "E"
