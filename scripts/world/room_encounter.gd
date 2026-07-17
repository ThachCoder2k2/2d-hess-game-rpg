class_name RoomEncounter
extends Node2D

signal enemy_spawned(enemy: FreeEnemy)
signal enemy_defeated(enemy: FreeEnemy)
signal enemy_weapon_changed(enemy: FreeEnemy, weapon: EnemyWeapon)
signal room_completed(room: Node)

@export var room_message := ""
@export var objective: Resource
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
	_setup_enemies()


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
	_apply_solid_tiles()


## Paint-once walls: every TileMap cell whose tile carries solid=true custom data
## (walls, thrones, banners in the kingdom TileSet) blocks movement and pathing.
## Painting the room IS the collision — art and logic cannot disagree.
func _apply_solid_tiles() -> void:
	var tilemap := get_node_or_null("RoomArt/TileMap") as TileMapLayer
	if tilemap == null:
		return
	for cell in tilemap.get_used_cells():
		var tile_data := tilemap.get_cell_tile_data(cell)
		if tile_data != null and bool(tile_data.get_custom_data("solid")):
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


## Enemies are real scene children parked where they fight — like the hero, each
## is its own spawn marker (drag the enemy in the editor to move its start).
## Setup registers each one on the cell containing its parked position, wires its
## signals, and activates it. Armed enemies equip definition.default_weapon.
func _setup_enemies() -> void:
	if grid_world == null:
		return
	for child in get_children():
		var enemy := child as FreeEnemy
		if enemy == null:
			continue
		var start_cell := grid_world.world_to_cell(enemy.position)
		if not enemy.setup(grid_world, start_cell):
			push_warning("Enemy '%s' could not register at its parked cell %s." % [enemy.name, start_cell])
			continue
		spawned_enemies.append(enemy)
		_connect_enemy(enemy)
		if enemy.weapon == null and enemy.definition != null and enemy.definition.default_weapon != null:
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
