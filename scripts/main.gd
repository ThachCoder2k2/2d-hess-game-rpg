extends Node2D

const FIRST_ENCOUNTER_SCENE := preload("res://scenes/rooms/first_encounter.tscn")

var grid_world: GridWorld
var director: EncounterDirector
var board: PrototypeBoard
var hero: PawnHero
var current_room: Node
var status_label: Label
var courage_label: Label
var skill_label: Label
var skill_fill: ColorRect
var encounter_label: Label
var objective_label: Label
var token_label: Label
var damage_flash: ColorRect
var result_panel: ColorRect
var result_label: Label
var remaining_enemies := 0
var total_enemies := 0
var room_ending := false
var debug_enabled := true
var enemies: Array[FreeEnemy] = []
var shake_time := 0.0
var shake_duration := 0.0
var shake_strength := 0.0
var damage_flash_time := 0.0


func _ready() -> void:
	grid_world = GridWorld.new()
	add_child(grid_world)

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
	hero.attack_landed.connect(_on_player_attack_landed)
	hero.courage_changed.connect(_update_courage)
	hero.damaged.connect(_on_hero_damaged)
	hero.skill_cooldown_changed.connect(_update_skill_cooldown)
	hero.defeated.connect(_on_hero_defeated)

	_load_room(FIRST_ENCOUNTER_SCENE)

	_build_hud()
	var room_message := "Break the black line."
	if current_room != null:
		room_message = String(current_room.call("get_start_message"))
	_update_status(room_message)


func _process(delta: float) -> void:
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
	_update_shake(delta)
	_update_damage_flash(delta)


func _load_room(room_scene: PackedScene) -> void:
	current_room = room_scene.instantiate()
	if current_room == null or not current_room.has_method("setup"):
		push_error("Room scene must instantiate a RoomEncounter.")
		return
	add_child(current_room)
	current_room.connect("enemy_spawned", Callable(self, "_on_room_enemy_spawned"))
	current_room.connect("enemy_defeated", Callable(self, "_on_enemy_defeated"))
	current_room.connect("enemy_weapon_changed", Callable(self, "_on_enemy_weapon_changed"))
	current_room.connect("room_completed", Callable(self, "_on_room_completed"))
	current_room.call("setup", grid_world, hero, director, board, debug_enabled)


func _on_room_enemy_spawned(enemy: FreeEnemy) -> void:
	remaining_enemies += 1
	total_enemies += 1
	enemies.append(enemy)
	_update_encounter_count()


func _on_enemy_weapon_changed(enemy: FreeEnemy, weapon: EnemyWeapon) -> void:
	if objective_label == null or weapon == null:
		return
	var piece_name := "Knight" if enemy is KnightEnemy else "Pawn"
	_update_status("%s picked up %s. Its chess attack has been replaced." % [piece_name, weapon.display_name])


func _on_player_attack_landed(cells: Array[Vector2i], hit_count: int, profile: AttackProfile) -> void:
	board.show_player_attack(cells, hit_count, profile)
	if hit_count > 0:
		_start_screen_shake(0.10, 2.6)
		_update_status("%s connects. Keep pressing the broken line." % profile.display_name)


func _on_enemy_defeated(enemy: FreeEnemy) -> void:
	if enemy not in enemies:
		return
	enemies.erase(enemy)
	board.clear_enemy_debug(enemy)
	remaining_enemies = maxi(0, remaining_enemies - 1)
	_update_encounter_count()


func _on_room_completed(room: Node) -> void:
	if room_ending:
		return
	room_ending = true
	director.set_paused(true)
	hero.control_enabled = false
	var clear_message := "ROOM CLEARED"
	var clear_subtitle := "PRESS R TO RESET"
	if room != null:
		clear_message = String(room.call("get_clear_message"))
		clear_subtitle = String(room.call("get_clear_subtitle"))
	_update_status(clear_message)
	_show_result(clear_message, clear_subtitle)


var _debug_key_was_pressed := false


func _set_debug_enabled(value: bool) -> void:
	debug_enabled = value
	board.set_debug_enabled(value)
	if current_room != null and current_room.has_method("set_debug_enabled"):
		current_room.call("set_debug_enabled", value)
	else:
		for enemy in enemies:
			if is_instance_valid(enemy):
				enemy.set_debug_enabled(value)
	_update_status("DEBUG VIEW ON: boundaries, paths, and behavior labels." if value else "DEBUG VIEW OFF.")


func _on_hero_defeated() -> void:
	if room_ending:
		return
	room_ending = true
	director.set_paused(true)
	var defeat_message := "THE PAWN FALLS"
	var defeat_subtitle := "THE CHILD RESETS THE BOARD"
	if current_room != null:
		defeat_message = String(current_room.call("get_defeat_message"))
		defeat_subtitle = String(current_room.call("get_defeat_subtitle"))
	_update_status(defeat_message)
	_show_result(defeat_message, defeat_subtitle)
	var tree := get_tree()
	if tree == null:
		return
	await tree.create_timer(0.85).timeout
	if is_inside_tree():
		tree.reload_current_scene()


func _on_hero_damaged(amount: int, remaining: int) -> void:
	_start_screen_shake(0.16, 4.2 + float(amount))
	damage_flash_time = 0.22
	if damage_flash != null:
		damage_flash.visible = true
	if remaining == 1:
		_update_status("One courage left. Wait for the warning, then cut through.")
	elif remaining > 1:
		_update_status("The pawn is hit. Move out before the next strike.")


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

	damage_flash = ColorRect.new()
	damage_flash.position = Vector2.ZERO
	damage_flash.size = Vector2(640, 360)
	damage_flash.color = Color("#d84a3a", 0.0)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_flash.visible = false
	layer.add_child(damage_flash)

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
		var color := Color("#d84a3a") if value <= 1 else Color("#ff9a75")
		courage_label.add_theme_color_override("font_color", color)


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


func _start_screen_shake(duration: float, strength: float) -> void:
	shake_duration = maxf(shake_duration, duration)
	shake_time = maxf(shake_time, duration)
	shake_strength = maxf(shake_strength, strength)


func _update_shake(delta: float) -> void:
	if shake_time <= 0.0:
		position = Vector2.ZERO
		shake_strength = 0.0
		return
	shake_time = maxf(0.0, shake_time - delta)
	var progress := shake_time / maxf(shake_duration, 0.001)
	var amount := shake_strength * progress
	var tick := Time.get_ticks_msec() / 1000.0
	position = Vector2(sin(tick * 91.0), cos(tick * 77.0)) * amount


func _update_damage_flash(delta: float) -> void:
	if damage_flash_time <= 0.0:
		if damage_flash != null:
			damage_flash.visible = false
		return
	damage_flash_time = maxf(0.0, damage_flash_time - delta)
	if damage_flash != null:
		var alpha := 0.20 * damage_flash_time / 0.22
		damage_flash.color = Color("#d84a3a", alpha)


func _facing_name(direction: Vector2i) -> String:
	if direction == Vector2i.UP:
		return "N"
	if direction == Vector2i.DOWN:
		return "S"
	if direction == Vector2i.LEFT:
		return "W"
	return "E"
