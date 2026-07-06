class_name RoomEncounter
extends Node2D

signal enemy_spawned(enemy: FreeEnemy)
signal enemy_defeated(enemy: FreeEnemy)
signal enemy_weapon_changed(enemy: FreeEnemy, weapon: EnemyWeapon)
signal room_completed(room: Node)

@export var room_message := ""
@export var objective: Resource
@export var hero_start_cell := Vector2i(3, 7)
@export var blocked_cells: Array[Vector2i] = []
@export var auto_activate_enemies := true

var grid_world: GridWorld
var hero: PawnHero
var director: EncounterDirector
var board: PrototypeBoard
var debug_enabled := true
var spawned_enemies: Array[FreeEnemy] = []
var spawned_pickups: Array[WeaponPickup] = []
var defeated_enemies := 0
var completed := false


func setup(world: GridWorld, player: PawnHero, encounter_director: EncounterDirector, board_view: PrototypeBoard, debug_view_enabled := true) -> void:
	grid_world = world
	hero = player
	director = encounter_director
	board = board_view
	debug_enabled = debug_view_enabled
	_apply_blockers()
	_spawn_pickups()
	_spawn_enemies()


func set_debug_enabled(value: bool) -> void:
	debug_enabled = value
	for enemy in spawned_enemies:
		if is_instance_valid(enemy):
			enemy.set_debug_enabled(value)


func get_remaining_enemy_count() -> int:
	var total := 0
	for enemy in spawned_enemies:
		if is_instance_valid(enemy) and enemy.state != FreeEnemy.State.DEFEATED:
			total += 1
	return total


func get_total_enemy_count() -> int:
	return spawned_enemies.size()


func get_start_message() -> String:
	if objective != null and not String(objective.get("start_message")).is_empty():
		return String(objective.get("start_message"))
	return room_message


func get_hero_start_cell() -> Vector2i:
	var marker := get_node_or_null("HeroStart")
	if marker != null and marker.has_method("get_hero_start_cell"):
		return marker.call("get_hero_start_cell")
	return hero_start_cell


func get_clear_message() -> String:
	return _objective_text("clear_message", "ROOM CLEARED")


func get_clear_subtitle() -> String:
	return _objective_text("clear_subtitle", "PRESS R TO RESET")


func get_defeat_message() -> String:
	return _objective_text("defeat_message", "THE PAWN FALLS")


func get_defeat_subtitle() -> String:
	return _objective_text("defeat_subtitle", "THE CHILD RESETS THE BOARD")


func _apply_blockers() -> void:
	if grid_world == null:
		return
	var marker_cells := _blocker_cells()
	var cells := marker_cells if not marker_cells.is_empty() else blocked_cells
	for cell in cells:
		grid_world.add_block(cell)


func _spawn_pickups() -> void:
	if grid_world == null:
		return
	for marker in _pickup_markers():
		var weapon := marker.call("create_weapon") as EnemyWeapon
		if weapon == null:
			continue
		var cell: Vector2i = marker.get("grid_cell")
		var pickup: WeaponPickup = null
		if marker.has_method("create_pickup"):
			pickup = marker.call("create_pickup") as WeaponPickup
		else:
			pickup = WeaponPickup.new()
		if pickup == null:
			continue
		pickup.z_index = 1
		add_child(pickup)
		if not pickup.setup(grid_world, cell, weapon):
			pickup.queue_free()
			continue
		spawned_pickups.append(pickup)


func _spawn_enemies() -> void:
	if grid_world == null:
		return
	for marker in _enemy_markers():
		var enemy := marker.call("create_enemy") as FreeEnemy
		if enemy == null:
			continue
		var cell: Vector2i = marker.get("grid_cell")
		enemy.z_index = 2
		add_child(enemy)
		if not enemy.setup(grid_world, cell):
			enemy.queue_free()
			continue
		spawned_enemies.append(enemy)
		_connect_enemy(enemy)
		var starting_weapon := marker.call("create_starting_weapon") as EnemyWeapon
		if starting_weapon != null:
			enemy.equip(starting_weapon)
		elif enemy.definition != null and enemy.definition.default_weapon != null:
			enemy.equip(enemy.definition.default_weapon.duplicate(true))
		if auto_activate_enemies:
			enemy.activate(hero, director)
		enemy.set_debug_enabled(debug_enabled)
		emit_signal("enemy_spawned", enemy)


func _connect_enemy(enemy: FreeEnemy) -> void:
	if board != null:
		enemy.telegraph_started.connect(board.set_telegraph)
		enemy.telegraph_finished.connect(board.clear_telegraph)
		enemy.attack_resolved.connect(board.show_enemy_attack)
		enemy.intent_changed.connect(board.set_enemy_intent)
	enemy.weapon_changed.connect(_on_enemy_weapon_changed)
	enemy.defeated.connect(_on_enemy_defeated)


func _on_enemy_weapon_changed(enemy: FreeEnemy, weapon: EnemyWeapon) -> void:
	emit_signal("enemy_weapon_changed", enemy, weapon)


func _on_enemy_defeated(enemy: FreeEnemy) -> void:
	if board != null:
		board.clear_enemy_debug(enemy)
	defeated_enemies += 1
	emit_signal("enemy_defeated", enemy)
	_check_completion()


func _check_completion() -> void:
	if completed:
		return
	var total := get_total_enemy_count()
	var remaining := get_remaining_enemy_count()
	var complete := total > 0 and remaining <= 0
	if objective != null and objective.has_method("is_complete"):
		complete = objective.call("is_complete", defeated_enemies, total, remaining)
	if not complete:
		return
	completed = true
	emit_signal("room_completed", self)


func _objective_text(property: StringName, fallback: String) -> String:
	if objective == null:
		return fallback
	var value := String(objective.get(property))
	return value if not value.is_empty() else fallback


func _enemy_markers() -> Array[Node]:
	var markers: Array[Node] = []
	for child in get_children():
		if child.has_method("create_enemy"):
			markers.append(child)
	return markers


func _pickup_markers() -> Array[Node]:
	var markers: Array[Node] = []
	for child in get_children():
		if child.has_method("create_weapon"):
			markers.append(child)
	return markers


func _blocker_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for child in get_children():
		if child.has_method("get_blocked_cell"):
			cells.append(child.call("get_blocked_cell"))
	return cells
