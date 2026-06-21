class_name FreeEnemy
extends GridActor

signal telegraph_started(source: Node, cells: Array[Vector2i])
signal telegraph_finished(source: Node)
signal attack_resolved(cells: Array[Vector2i])
signal weapon_changed(enemy: FreeEnemy, weapon: EnemyWeapon)
signal defeated(enemy: FreeEnemy)
signal intent_changed(enemy: FreeEnemy, intent: EnemyIntent)

enum State { OBSERVE, TELEGRAPH, COMMIT, RECOVER, DEFEATED }

@export var health := 2
@export var think_time := 0.42
@export var move_recovery_time := 0.18
@export var unarmed_telegraph_time := 0.58
@export var unarmed_recovery_time := 0.48

var target: PawnHero
var director: EncounterDirector
var weapon: EnemyWeapon
var attack_pattern: AttackPattern
var archetype: EnemyArchetype
var current_intent: EnemyIntent
var action_memory: Array[StringName] = []
var last_move_direction := Vector2i.ZERO
var state := State.OBSERVE
var state_time := 0.0
var flash_time := 0.0
var recoil := Vector2.ZERO
var locked_attack_cells: Array[Vector2i] = []
var debug_enabled := true
var debug_label: Label


func _ready() -> void:
	_ensure_ai_data()
	_create_debug_label()


func create_attack_pattern() -> AttackPattern:
	return AttackPattern.new()


func create_archetype() -> EnemyArchetype:
	return EnemyArchetype.new()


func activate(hero: PawnHero, encounter_director: EncounterDirector) -> void:
	_ensure_ai_data()
	target = hero
	director = encounter_director
	state = State.OBSERVE
	state_time = think_time
	queue_redraw()
	_update_debug_label()


func set_debug_enabled(value: bool) -> void:
	_create_debug_label()
	debug_enabled = value
	if debug_label != null:
		debug_label.visible = value


func equip(item: EnemyWeapon) -> void:
	weapon = item
	emit_signal("weapon_changed", self, weapon)
	queue_redraw()


func _process(delta: float) -> void:
	flash_time = maxf(0.0, flash_time - delta)
	recoil = recoil.move_toward(Vector2.ZERO, delta * 70.0)
	if flash_time > 0.0:
		queue_redraw()
	_update_debug_label()
	if target == null or not is_instance_valid(target) or state == State.DEFEATED or is_moving:
		return
	if director != null and director.paused:
		return
	state_time -= delta
	if state_time > 0.0:
		return
	match state:
		State.OBSERVE:
			_choose_action()
		State.TELEGRAPH:
			_resolve_attack()
		State.COMMIT:
			_resolve_attack()
		State.RECOVER:
			state = State.OBSERVE
			state_time = think_time


func get_unarmed_attack_cells(origin := current_cell, direction := facing) -> Array[Vector2i]:
	_ensure_ai_data()
	return attack_pattern.get_attack_cells(grid_world, origin, direction)


func get_attack_cells(origin := current_cell, direction := facing) -> Array[Vector2i]:
	if weapon != null:
		return weapon.get_attack_cells(origin, direction)
	return get_unarmed_attack_cells(origin, direction)


func get_cardinal_move_options() -> Array[Vector2i]:
	if grid_world == null:
		return []
	return grid_world.get_cardinal_destinations(self, current_cell)


func _choose_action() -> void:
	var context := EnemyContext.capture(self)
	var candidates := _build_intents(context)
	current_intent = _select_intent(candidates)
	emit_signal("intent_changed", self, current_intent)
	_execute_intent(current_intent)


func _build_intents(context: EnemyContext) -> Array[EnemyIntent]:
	_ensure_ai_data()
	var intents: Array[EnemyIntent] = []
	var attack_cells := get_attack_cells(context.self_cell, context.facing)
	if context.attack_available and context.hero_cell in attack_cells:
		intents.append(EnemyIntent.attack(attack_cells, archetype.attack_score))

	if weapon == null and grid_world.item_at(context.self_cell) is WeaponPickup:
		intents.append(EnemyIntent.pickup(archetype.pickup_score + 50.0))

	var pursuit_cell := context.hero_cell
	if weapon == null:
		var nearest_item := _nearest_item_cell(context.item_cells)
		if nearest_item != Vector2i(-999, -999):
			pursuit_cell = nearest_item

	for destination in context.legal_moves:
		var direction := destination - context.self_cell
		var score := _score_destination(destination, direction, pursuit_cell, context)
		intents.append(EnemyIntent.move(destination, direction, score))

	if attack_pattern.uses_facing or weapon != null:
		for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if direction == context.facing:
				continue
			var turn_score := 4.0
			if context.hero_cell in get_attack_cells(context.self_cell, direction):
				turn_score += archetype.turn_threat_score
			else:
				var old_distance := _facing_distance(context.self_cell, context.hero_cell, context.facing)
				var new_distance := _facing_distance(context.self_cell, context.hero_cell, direction)
				turn_score += float(old_distance - new_distance) * 3.0
			intents.append(EnemyIntent.turn(direction, turn_score))

	intents.append(EnemyIntent.wait(archetype.wait_score))
	for intent in intents:
		intent.score -= float(action_memory.count(intent.action_id)) * archetype.repetition_penalty
	return intents


func _select_intent(candidates: Array[EnemyIntent]) -> EnemyIntent:
	var best := candidates[0]
	for candidate in candidates:
		if candidate.score > best.score:
			best = candidate
	return best


func _execute_intent(intent: EnemyIntent) -> void:
	_remember_action(intent.action_id)
	match intent.type:
		EnemyIntent.Type.ATTACK:
			if director != null and not director.request_attack(self):
				state = State.RECOVER
				state_time = 0.12
				return
			locked_attack_cells = intent.target_cells.duplicate()
			state = State.TELEGRAPH
			state_time = weapon.telegraph_time if weapon != null else unarmed_telegraph_time
			emit_signal("telegraph_started", self, locked_attack_cells)
			queue_redraw()
		EnemyIntent.Type.MOVE:
			last_move_direction = intent.direction
			try_step(intent.direction)
			state = State.RECOVER
			state_time = move_recovery_time
		EnemyIntent.Type.PICKUP:
			var pickup := grid_world.item_at(current_cell)
			if pickup is WeaponPickup:
				equip(pickup.take(self))
			state = State.RECOVER
			state_time = 0.10
		EnemyIntent.Type.TURN:
			facing = intent.direction
			queue_redraw()
			state = State.RECOVER
			state_time = 0.12
		EnemyIntent.Type.WAIT:
			state = State.RECOVER
			state_time = think_time * 0.65


func _score_destination(destination: Vector2i, direction: Vector2i, pursuit_cell: Vector2i, context: EnemyContext) -> float:
	var old_distance := _manhattan(context.self_cell, pursuit_cell)
	var new_distance := _manhattan(destination, pursuit_cell)
	var score := float(old_distance - new_distance) * archetype.distance_score
	if weapon == null and grid_world.item_at(destination) is WeaponPickup:
		score += archetype.pickup_score
	if context.hero_cell in get_attack_cells(destination, direction):
		score += archetype.future_threat_score
	var hero_distance := _manhattan(destination, context.hero_cell)
	score -= absf(float(hero_distance - archetype.preferred_distance)) * 2.0
	return score + get_positioning_bonus(destination, direction, context)


func get_positioning_bonus(_destination: Vector2i, _direction: Vector2i, _context: EnemyContext) -> float:
	return 0.0


func _nearest_item_cell(item_cells: Array[Vector2i]) -> Vector2i:
	var result := Vector2i(-999, -999)
	var best_distance := 999999
	for cell in item_cells:
		var distance := _manhattan(current_cell, cell)
		if distance < best_distance:
			best_distance = distance
			result = cell
	return result


func _resolve_attack() -> void:
	state = State.COMMIT
	emit_signal("telegraph_finished", self)
	if target.current_cell in locked_attack_cells:
		target.take_damage(weapon.damage if weapon != null else 1, facing)
	emit_signal("attack_resolved", locked_attack_cells)
	locked_attack_cells.clear()
	if director != null:
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


func _facing_distance(origin: Vector2i, destination: Vector2i, direction: Vector2i) -> int:
	var delta := destination - origin
	return absi(delta.x - direction.x) + absi(delta.y - direction.y)


func _remember_action(action_id: StringName) -> void:
	action_memory.append(action_id)
	if action_memory.size() > 3:
		action_memory.pop_front()


func _ensure_ai_data() -> void:
	if attack_pattern == null:
		attack_pattern = create_attack_pattern()
	if archetype == null:
		archetype = create_archetype()


func _create_debug_label() -> void:
	if debug_label != null:
		return
	debug_label = Label.new()
	debug_label.position = Vector2(-48, -39)
	debug_label.size = Vector2(96, 25)
	debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	debug_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	debug_label.add_theme_font_size_override("font_size", 7)
	debug_label.add_theme_color_override("font_color", Color("#fff4d6"))
	debug_label.add_theme_color_override("font_shadow_color", Color(0.04, 0.03, 0.04, 0.95))
	debug_label.add_theme_constant_override("shadow_offset_x", 1)
	debug_label.add_theme_constant_override("shadow_offset_y", 1)
	debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(debug_label)
	debug_label.visible = debug_enabled
	_update_debug_label()


func _update_debug_label() -> void:
	if debug_label == null or not debug_enabled:
		return
	_ensure_ai_data()
	var action := "NONE"
	var score := 0.0
	if current_intent != null:
		action = String(current_intent.action_id).to_upper()
		score = current_intent.score
	var equipment := "UNARMED" if weapon == null else weapon.display_name.to_upper()
	debug_label.text = "%s  %s\n%s %.0f  %s" % [
		String(archetype.role).to_upper(),
		State.keys()[state],
		action,
		score,
		equipment,
	]
