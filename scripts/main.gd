extends Node2D

const FIRST_ENCOUNTER_SCENE := preload("res://scenes/rooms/first_encounter.tscn")
const GRID_WORLD_SCENE := preload("res://scenes/world/grid_world.tscn")
const DIRECTOR_SCENE := preload("res://scenes/combat/encounter_director.tscn")
const BOARD_SCENE := preload("res://scenes/world/prototype_board.tscn")
const PLAYER_SCENE := preload("res://scenes/actors/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")

@export var grid_world_path: NodePath = ^"GridWorld"
@export var director_path: NodePath = ^"EncounterDirector"
@export var board_path: NodePath = ^"PrototypeBoard"
@export var hero_path: NodePath = ^"PawnHero"
@export var room_path: NodePath = ^"FirstEncounter"
@export var hud_path: NodePath = ^"HUD"
@export var hero_start_cell := Vector2i(3, 7)

var grid_world: GridWorld
var director: EncounterDirector
var board: PrototypeBoard
var hero: PawnHero
var current_room: Node
var hud: Node
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
	_setup_scene_nodes()
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
	if hero != null:
		if hud != null and hud.has_method("set_cell_status"):
			hud.call("set_cell_status", hero.current_cell, _facing_name(hero.facing))
		elif status_label != null:
			status_label.text = "CELL %02d,%02d  FACE %s" % [
				hero.current_cell.x,
				hero.current_cell.y,
				_facing_name(hero.facing),
			]
	_update_shake(delta)
	_update_damage_flash(delta)


func _setup_scene_nodes() -> void:
	grid_world = _resolve_scene_node(grid_world_path, GRID_WORLD_SCENE, GridWorld.new(), "GridWorld") as GridWorld
	director = _resolve_scene_node(director_path, DIRECTOR_SCENE, EncounterDirector.new(), "EncounterDirector") as EncounterDirector
	board = _resolve_scene_node(board_path, BOARD_SCENE, PrototypeBoard.new(), "PrototypeBoard") as PrototypeBoard
	hero = _resolve_scene_node(hero_path, PLAYER_SCENE, PawnHero.new(), "PawnHero") as PawnHero

	if director != null:
		_connect_signal_once(director, &"token_changed", Callable(self, "_update_token_owner"))
	if board != null:
		board.z_index = -5
		board.setup(grid_world)
	if hero != null:
		hero.z_index = 3
		if hero.grid_world == null and not hero.setup(grid_world, hero_start_cell):
			push_error("PawnHero could not register on the GridWorld.")
		_connect_signal_once(hero, &"attack_landed", Callable(self, "_on_player_attack_landed"))
		_connect_signal_once(hero, &"courage_changed", Callable(self, "_update_courage"))
		_connect_signal_once(hero, &"damaged", Callable(self, "_on_hero_damaged"))
		_connect_signal_once(hero, &"skill_cooldown_changed", Callable(self, "_update_skill_cooldown"))
		_connect_signal_once(hero, &"defeated", Callable(self, "_on_hero_defeated"))

	var existing_room := get_node_or_null(room_path)
	if existing_room != null:
		_setup_room_instance(existing_room)
	else:
		_load_room(FIRST_ENCOUNTER_SCENE)
	_setup_hud()


func _resolve_scene_node(node_path: NodePath, scene: PackedScene, fallback: Node, node_name: String) -> Node:
	var existing := get_node_or_null(node_path)
	if existing != null:
		return existing
	var created: Node = scene.instantiate() if scene != null else fallback
	created.name = node_name
	add_child(created)
	return created


func _connect_signal_once(source: Object, signal_name: StringName, target: Callable) -> void:
	if source != null and not source.is_connected(signal_name, target):
		source.connect(signal_name, target)


func _load_room(room_scene: PackedScene) -> void:
	var room := room_scene.instantiate()
	if room != null:
		room.name = "FirstEncounter"
		add_child(room)
	_setup_room_instance(room)


func _setup_room_instance(room: Node) -> void:
	current_room = room
	if current_room == null or not current_room.has_method("setup"):
		push_error("Room scene must instantiate a RoomEncounter.")
		return
	_connect_signal_once(current_room, &"enemy_spawned", Callable(self, "_on_room_enemy_spawned"))
	_connect_signal_once(current_room, &"enemy_defeated", Callable(self, "_on_enemy_defeated"))
	_connect_signal_once(current_room, &"enemy_weapon_changed", Callable(self, "_on_enemy_weapon_changed"))
	_connect_signal_once(current_room, &"room_completed", Callable(self, "_on_room_completed"))
	current_room.call("setup", grid_world, hero, director, board, debug_enabled)


func _setup_hud() -> void:
	hud = _resolve_scene_node(hud_path, HUD_SCENE, CanvasLayer.new(), "HUD")
	_bind_hud_references()
	if hud != null and hud.has_method("setup"):
		hud.call("setup", hero.courage if hero != null else 3)
	_bind_hud_references()
	if hero != null:
		_update_courage(hero.courage)
		_update_skill_cooldown(hero.skill_cooldown_left)
	_update_encounter_count()
	_update_token_owner(null)


func _bind_hud_references() -> void:
	if hud == null:
		return
	courage_label = hud.get_node_or_null("CourageLabel") as Label
	skill_label = hud.get_node_or_null("SkillLabel") as Label
	skill_fill = hud.get_node_or_null("SkillFill") as ColorRect
	status_label = hud.get_node_or_null("StatusLabel") as Label
	encounter_label = hud.get_node_or_null("EncounterLabel") as Label
	objective_label = hud.get_node_or_null("ObjectiveLabel") as Label
	token_label = hud.get_node_or_null("TokenLabel") as Label
	damage_flash = hud.get_node_or_null("DamageFlash") as ColorRect
	result_panel = hud.get_node_or_null("ResultPanel") as ColorRect
	result_label = hud.get_node_or_null("ResultLabel") as Label


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
	if hud != null and hud.has_method("show_damage_flash"):
		hud.call("show_damage_flash")
	elif damage_flash != null:
		damage_flash.visible = true
	if remaining == 1:
		_update_status("One courage left. Wait for the warning, then cut through.")
	elif remaining > 1:
		_update_status("The pawn is hit. Move out before the next strike.")


func _update_courage(value: int) -> void:
	if hud != null and hud.has_method("set_courage"):
		hud.call("set_courage", value)
		return
	if courage_label != null:
		courage_label.text = "COURAGE " + "◆".repeat(value) + "◇".repeat(3 - value)
		var color := Color("#d84a3a") if value <= 1 else Color("#ff9a75")
		courage_label.add_theme_color_override("font_color", color)


func _update_skill_cooldown(time_left: float) -> void:
	if hud != null and hud.has_method("set_skill_cooldown"):
		hud.call("set_skill_cooldown", time_left, hero.pencil_thrust_cooldown if hero != null else 1.0)
		return
	if skill_label == null:
		return
	skill_label.text = "Q THRUST READY" if time_left <= 0.0 else "Q THRUST %.1f" % time_left
	if skill_fill != null:
		var ratio := 1.0 if time_left <= 0.0 else clampf(1.0 - time_left / hero.pencil_thrust_cooldown, 0.0, 1.0)
		skill_fill.size.x = 92.0 * ratio
		skill_fill.color = Color("#8ec8e8", 0.9) if time_left <= 0.0 else Color("#e8b83f", 0.82)


func _update_token_owner(token_owner: Node) -> void:
	if hud != null and hud.has_method("set_token_owner"):
		hud.call("set_token_owner", token_owner)
		return
	if token_label == null:
		return
	if token_owner == null:
		token_label.text = "ENEMY STRIKE READY"
	else:
		token_label.text = "STRIKE: " + ("KNIGHT" if token_owner is KnightEnemy else "PAWN")


func _update_encounter_count() -> void:
	if hud != null and hud.has_method("set_encounter_count"):
		hud.call("set_encounter_count", remaining_enemies, total_enemies)
		return
	if encounter_label != null:
		encounter_label.text = "ENEMIES %d/%d" % [remaining_enemies, total_enemies]


func _update_status(text: String) -> void:
	if hud != null and hud.has_method("set_status"):
		hud.call("set_status", text)
		return
	if objective_label != null:
		objective_label.text = text


func _show_result(title: String, subtitle: String) -> void:
	if hud != null and hud.has_method("show_result"):
		hud.call("show_result", title, subtitle)
		return
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
		if hud != null and hud.has_method("update_damage_flash"):
			hud.call("update_damage_flash", 0.0, 0.22)
		elif damage_flash != null:
			damage_flash.visible = false
		return
	damage_flash_time = maxf(0.0, damage_flash_time - delta)
	if hud != null and hud.has_method("update_damage_flash"):
		hud.call("update_damage_flash", damage_flash_time, 0.22)
	elif damage_flash != null:
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
