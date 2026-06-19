class_name FreeEnemy
extends GridActor

signal telegraph_started(source: Node, cells: Array[Vector2i])
signal telegraph_finished(source: Node)
signal attack_resolved(cells: Array[Vector2i])
signal weapon_changed(enemy: FreeEnemy, weapon: EnemyWeapon)
signal defeated(enemy: FreeEnemy)

enum State { IDLE, TELEGRAPH, RECOVER, DEFEATED }

@export var health := 2
@export var think_time := 0.42
@export var unarmed_telegraph_time := 0.58
@export var unarmed_recovery_time := 0.48

var target: PawnHero
var director: EncounterDirector
var weapon: EnemyWeapon
var state := State.IDLE
var state_time := 0.0
var flash_time := 0.0
var recoil := Vector2.ZERO
var locked_attack_cells: Array[Vector2i] = []


func activate(hero: PawnHero, encounter_director: EncounterDirector) -> void:
	target = hero
	director = encounter_director
	state = State.IDLE
	state_time = think_time
	queue_redraw()


func equip(item: EnemyWeapon) -> void:
	weapon = item
	emit_signal("weapon_changed", self, weapon)
	queue_redraw()


func _process(delta: float) -> void:
	flash_time = maxf(0.0, flash_time - delta)
	recoil = recoil.move_toward(Vector2.ZERO, delta * 70.0)
	if flash_time > 0.0:
		queue_redraw()
	if target == null or not is_instance_valid(target) or state == State.DEFEATED or is_moving:
		return
	if director != null and director.paused:
		return
	state_time -= delta
	if state_time > 0.0:
		return
	match state:
		State.IDLE:
			_choose_action()
		State.TELEGRAPH:
			_resolve_attack()
		State.RECOVER:
			state = State.IDLE
			state_time = think_time


func get_unarmed_attack_cells(_origin := current_cell, _direction := facing) -> Array[Vector2i]:
	return []


func get_attack_cells(origin := current_cell, direction := facing) -> Array[Vector2i]:
	if weapon != null:
		return weapon.get_attack_cells(origin, direction)
	return get_unarmed_attack_cells(origin, direction)


func get_cardinal_move_options() -> Array[Vector2i]:
	if grid_world == null:
		return []
	return grid_world.get_cardinal_destinations(self, current_cell)


func _choose_action() -> void:
	_try_collect_weapon()
	var attack_cells := get_attack_cells()
	if target.current_cell in attack_cells and director.request_attack(self):
		locked_attack_cells = attack_cells.duplicate()
		state = State.TELEGRAPH
		state_time = weapon.telegraph_time if weapon != null else unarmed_telegraph_time
		emit_signal("telegraph_started", self, locked_attack_cells)
		queue_redraw()
		return
	_choose_free_move()


func _try_collect_weapon() -> bool:
	if weapon != null or grid_world == null:
		return false
	var pickup := grid_world.item_at(current_cell)
	if pickup is WeaponPickup:
		equip(pickup.take(self))
		return true
	return false


func _choose_free_move() -> void:
	var destinations := get_cardinal_move_options()
	if destinations.is_empty():
		state = State.RECOVER
		state_time = unarmed_recovery_time
		return
	var pursuit_cell := target.current_cell
	if weapon == null:
		var nearest_item := _nearest_item_cell()
		if nearest_item != Vector2i(-999, -999):
			pursuit_cell = nearest_item
	var best_destination := destinations[0]
	var best_score := -INF
	for destination in destinations:
		var direction := destination - current_cell
		var score := _score_destination(destination, direction, pursuit_cell)
		if score > best_score:
			best_score = score
			best_destination = destination
	var move_direction := best_destination - current_cell
	if try_step(move_direction):
		facing = move_direction
	state = State.RECOVER
	state_time = unarmed_recovery_time


func _score_destination(destination: Vector2i, direction: Vector2i, pursuit_cell: Vector2i) -> float:
	var old_distance := _manhattan(current_cell, pursuit_cell)
	var new_distance := _manhattan(destination, pursuit_cell)
	var score := float(old_distance - new_distance) * 10.0
	if weapon == null and grid_world.item_at(destination) is WeaponPickup:
		score += 60.0
	if target.current_cell in get_attack_cells(destination, direction):
		score += 28.0
	return score + get_positioning_bonus(destination, direction)


func get_positioning_bonus(_destination: Vector2i, _direction: Vector2i) -> float:
	return 0.0


func _nearest_item_cell() -> Vector2i:
	var result := Vector2i(-999, -999)
	var best_distance := 999999
	for cell in grid_world.get_item_cells():
		var distance := _manhattan(current_cell, cell)
		if distance < best_distance:
			best_distance = distance
			result = cell
	return result


func _resolve_attack() -> void:
	emit_signal("telegraph_finished", self)
	if target.current_cell in locked_attack_cells:
		target.take_damage(weapon.damage if weapon != null else 1, facing)
	emit_signal("attack_resolved", locked_attack_cells)
	locked_attack_cells.clear()
	director.release_attack(self)
	state = State.RECOVER
	state_time = weapon.recovery_time if weapon != null else unarmed_recovery_time
	queue_redraw()


func take_damage(amount: int, direction := Vector2i.ZERO) -> void:
	if state == State.DEFEATED:
		return
	health -= amount
	flash_time = 0.12
	recoil = Vector2(direction) * 4.0
	queue_redraw()
	if health <= 0:
		state = State.DEFEATED
		emit_signal("telegraph_finished", self)
		if director != null:
			director.release_attack(self)
		grid_world.unregister_actor(self)
		emit_signal("defeated", self)
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(1.15, 0.15), 0.18)
		tween.tween_callback(queue_free)


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
