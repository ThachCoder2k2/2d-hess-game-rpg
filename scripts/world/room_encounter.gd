class_name RoomEncounter
extends Node2D

signal enemy_spawned(enemy: FreeEnemy)
signal enemy_defeated(enemy: FreeEnemy)
signal enemy_weapon_changed(enemy: FreeEnemy, weapon: EnemyWeapon)

@export var room_message := ""
@export var blocked_cells: Array[Vector2i] = []
@export var auto_activate_enemies := true

var grid_world: GridWorld
var hero: PawnHero
var director: EncounterDirector
var board: PrototypeBoard
var debug_enabled := true
var spawned_enemies: Array[FreeEnemy] = []
var spawned_pickups: Array[WeaponPickup] = []


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


func _apply_blockers() -> void:
	if grid_world == null:
		return
	for cell in blocked_cells:
		grid_world.add_block(cell)


func _spawn_pickups() -> void:
	if grid_world == null:
		return
	for marker in _pickup_markers():
		var weapon := marker.call("create_weapon") as EnemyWeapon
		if weapon == null:
			continue
		var cell: Vector2i = marker.get("grid_cell")
		var pickup := WeaponPickup.new()
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
	emit_signal("enemy_defeated", enemy)


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
