extends Node2D

const FIRST_ENCOUNTER_SCENE := preload("res://scenes/rooms/first_encounter.tscn")
const GRID_WORLD_SCENE := preload("res://objects/world/grid_world.tscn")
const DIRECTOR_SCENE := preload("res://objects/combat/encounter_director.tscn")
const BOARD_SCENE := preload("res://objects/world/prototype_board.tscn")
const PLAYER_SCENE := preload("res://objects/actors/player.tscn")
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
var hud: GameHud
var camera_rig: CameraRig
var remaining_enemies := 0
var total_enemies := 0
var room_ending := false
var debug_enabled := true
var enemies: Array[FreeEnemy] = []


func _ready() -> void:
	_setup_scene_nodes()
	var room_message := "Break the black line."
	if current_room != null:
		room_message = String(current_room.call("get_start_message"))
	_update_status(room_message)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart_room"):
		get_tree().reload_current_scene()
	if Input.is_key_pressed(KEY_F3) and not _debug_key_was_pressed:
		_set_debug_enabled(not debug_enabled)
	_debug_key_was_pressed = Input.is_key_pressed(KEY_F3)
	if hero != null and hud != null:
		hud.set_cell_status(hero.current_cell, _facing_name(hero.facing))


func _setup_scene_nodes() -> void:
	grid_world = _resolve_scene_node(grid_world_path, GRID_WORLD_SCENE, GridWorld.new(), "GridWorld") as GridWorld
	director = _resolve_scene_node(director_path, DIRECTOR_SCENE, EncounterDirector.new(), "EncounterDirector") as EncounterDirector
	board = _resolve_scene_node(board_path, BOARD_SCENE, PrototypeBoard.new(), "PrototypeBoard") as PrototypeBoard
	hero = _resolve_scene_node(hero_path, PLAYER_SCENE, PawnHero.new(), "PawnHero") as PawnHero
	var existing_room := get_node_or_null(room_path)
	var resolved_hero_start := _resolve_hero_start_cell()

	if director != null:
		_connect_signal_once(director, &"token_changed", Callable(self, "_update_token_owner"))
	if board != null:
		board.z_index = -5
		board.setup(grid_world)
	if hero != null:
		hero.z_index = 3
		hero.current_cell = resolved_hero_start
		if hero.grid_world == null and not hero.setup(grid_world, resolved_hero_start):
			push_error("PawnHero could not register on the GridWorld.")
		_connect_signal_once(hero, &"attack_landed", Callable(self, "_on_player_attack_landed"))
		_connect_signal_once(hero, &"courage_changed", Callable(self, "_update_courage"))
		_connect_signal_once(hero, &"damaged", Callable(self, "_on_hero_damaged"))
		_connect_signal_once(hero, &"skill_cooldown_changed", Callable(self, "_update_skill_cooldown"))
		_connect_signal_once(hero, &"defeated", Callable(self, "_on_hero_defeated"))
		_setup_camera()

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


## Binds the hero's CameraRig to the board. The rig owns all framing behavior
## (follow, bounds clamp, zoom, smoothing) — tune it per scene on the node, or per
## situation via its runtime setters. Called again when a room changes grid_world.bounds.
func _setup_camera() -> void:
	if hero == null or grid_world == null:
		return
	camera_rig = hero.get_node_or_null("Camera2D") as CameraRig
	if camera_rig == null:
		return
	camera_rig.setup(grid_world)


func _connect_signal_once(source: Object, signal_name: StringName, target: Callable) -> void:
	if source != null and not source.is_connected(signal_name, target):
		source.connect(signal_name, target)


## The hero is its own spawn marker: wherever the PawnHero node is parked in the
## editor is where it starts — the parked pixel position floors to the cell that
## contains it, and setup() re-centers the sprite on that cell. The exported
## hero_start_cell is only the fallback when the parked spot is off the board
## (e.g. a bare-script Main in tests, where the hero sits at the origin).
func _resolve_hero_start_cell() -> Vector2i:
	if hero != null and grid_world != null:
		var parked_cell := grid_world.world_to_cell(hero.position)
		if grid_world.is_inside(parked_cell):
			return parked_cell
	return hero_start_cell


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
	hud = _resolve_scene_node(hud_path, HUD_SCENE, CanvasLayer.new(), "HUD") as GameHud
	if hud != null:
		hud.setup(hero.courage if hero != null else 3)
	if hero != null:
		_update_courage(hero.courage)
		_update_skill_cooldown(hero.skill_cooldown_left)
	_update_encounter_count()
	_update_token_owner(null)


func _on_room_enemy_spawned(enemy: FreeEnemy) -> void:
	remaining_enemies += 1
	total_enemies += 1
	enemies.append(enemy)
	_update_encounter_count()


func _on_enemy_weapon_changed(enemy: FreeEnemy, weapon: EnemyWeapon) -> void:
	if hud == null or weapon == null:
		return
	var piece_name := _enemy_piece_name(enemy)
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
	if hud != null:
		hud.flash_damage()
	if remaining == 1:
		_update_status("One courage left. Wait for the warning, then cut through.")
	elif remaining > 1:
		_update_status("The pawn is hit. Move out before the next strike.")


func _update_courage(value: int) -> void:
	if hud != null:
		hud.set_courage(value)


func _update_skill_cooldown(time_left: float) -> void:
	if hud != null:
		hud.set_skill_cooldown(time_left, hero.pencil_thrust_cooldown if hero != null else 1.0)


func _update_token_owner(token_owner: Node) -> void:
	if hud != null:
		hud.set_token_owner(token_owner)


func _update_encounter_count() -> void:
	if hud != null:
		hud.set_encounter_count(remaining_enemies, total_enemies)


func _update_status(text: String) -> void:
	if hud != null:
		hud.set_status(text)


func _show_result(title: String, subtitle: String) -> void:
	if hud != null:
		hud.show_result(title, subtitle)


func _enemy_piece_name(enemy: Node) -> String:
	if enemy != null and enemy.has_method("get_piece_display_name"):
		return String(enemy.call("get_piece_display_name"))
	return "Enemy"


## Screen shake is camera behavior: delegate to the hero's CameraRig, which
## drives the built-in Camera2D offset (Main's own position never moves).
func _start_screen_shake(duration: float, strength: float) -> void:
	if camera_rig != null:
		camera_rig.start_shake(duration, strength)


func _facing_name(direction: Vector2i) -> String:
	if direction == Vector2i.UP:
		return "N"
	if direction == Vector2i.DOWN:
		return "S"
	if direction == Vector2i.LEFT:
		return "W"
	return "E"
