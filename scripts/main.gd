extends Node2D

## Boots the ECS world from the editor-authored scene and bridges its events to
## the presentation (docs/ecs-conversion-plan.md): parked views become entities
## (EcsBoot), systems run the whole game, and this script only translates the
## event queue into HUD text, board overlay calls, camera shake, and view
## despawns. No gameplay decision lives here.

@export var hero_path: NodePath = ^"PawnHero"
@export var room_path: NodePath = ^"FirstEncounter"
@export var board_path: NodePath = ^"PrototypeBoard"
@export var hud_path: NodePath = ^"HUD"
@export var hero_start_cell := Vector2i(3, 7)
## Draw board boundaries, paths, and behavior labels. F3 still toggles at runtime.
@export var debug_enabled := false
## The world as data: zone id -> scene. Assigned = world mode (zone travel on
## door cells, no clear-all win screen unless a zone carries an objective).
@export var world_graph: WorldGraph
@export var fade_rect_path: NodePath = ^"FadeLayer/FadeRect"

var ecs: EcsWorld
var cast: Dictionary = {}
var player_id := 0
var current_room: Node
var board: PrototypeBoard
var hud: GameHud
var camera_rig: CameraRig
var remaining_enemies := 0
var total_enemies := 0
var defeated_enemies := 0
var room_ending := false
var player_view: ActorView
var current_zone_id: StringName = &""
var travel_in_progress := false
var _debug_key_was_pressed := false
var _fullscreen_key_was_pressed := false
var _book_key_was_pressed := false
var _last_token_owner := 0


func _ready() -> void:
	current_room = get_node_or_null(room_path)
	player_view = get_node_or_null(hero_path) as ActorView
	board = get_node_or_null(board_path) as PrototypeBoard
	hud = get_node_or_null(hud_path) as GameHud
	if player_view != null:
		camera_rig = player_view.get_node_or_null("Camera2D") as CameraRig

	# Death and R both reload this scene; WorldState (autoload) remembers
	# which zone the run is in, so the reload boots there, not the default.
	var entry_id: StringName = &"start"
	var world_state := _world_state()
	if world_state != null:
		entry_id = world_state.last_entry_id
		if world_graph != null and world_state.current_zone_id != &"" \
			and world_state.current_zone_id != _zone_id_of(current_room):
			current_room = _swap_zone_node(world_state.current_zone_id)
	_boot_zone(entry_id)


## Builds a fresh EcsWorld from the current zone node. Called at scene start
## and again after every zone swap — the whole simulation is rebuilt, only
## the player view node and WorldState persist.
func _boot_zone(entry_id: StringName) -> void:
	if ecs != null:
		remove_child(ecs)
		ecs.queue_free()
	ecs = _make_world()
	var entry_cell := _find_entry_cell(current_room, entry_id)
	if player_view != null and entry_cell != Vector2i(-1, -1):
		player_view.position = ecs.grid.cell_to_world(entry_cell)

	cast = EcsBoot.boot(ecs, player_view, current_room, hero_start_cell, _taken_pickup_names(), _opened_gate_ids())
	_hide_opened_gate_visuals()
	_unlock_met_rules()
	player_id = int(cast.get("player", 0))
	total_enemies = cast.get("enemies", []).size()
	remaining_enemies = total_enemies
	defeated_enemies = 0
	room_ending = false
	_last_token_owner = 0
	current_zone_id = _zone_id_of(current_room)

	var world_state := _world_state()
	if world_state != null:
		if current_zone_id != &"":
			world_state.current_zone_id = current_zone_id
		if world_state.player_health_carry > 0:
			var health: EcsComponents.Health = ecs.get_component(player_id, EcsComponents.HEALTH)
			if health != null:
				health.current = mini(world_state.player_health_carry, health.max_health)
		world_state.player_health_carry = -1

	if board != null:
		board.z_index = -5
		board.setup(ecs.grid, ecs)
		board.set_debug_enabled(debug_enabled)
	if camera_rig != null:
		camera_rig.setup(ecs.grid)
	_setup_hud()


func _make_world() -> EcsWorld:
	var world := EcsWorld.new()
	world.name = "EcsWorld"
	world.manual_tick = true
	add_child(world)
	world.add_system(PlayerInputSystem.new())
	world.add_system(EnemyAISystem.new())
	world.add_system(MovementSystem.new())
	world.add_system(CombatSystem.new())
	world.add_system(HealthSystem.new())
	world.add_system(ViewSyncSystem.new())
	return world


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart_room"):
		get_tree().reload_current_scene()
	if Input.is_key_pressed(KEY_F3) and not _debug_key_was_pressed:
		_set_debug_enabled(not debug_enabled)
	_debug_key_was_pressed = Input.is_key_pressed(KEY_F3)
	if Input.is_key_pressed(KEY_F11) and not _fullscreen_key_was_pressed:
		var window := get_window()
		window.mode = Window.MODE_WINDOWED if window.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
	_fullscreen_key_was_pressed = Input.is_key_pressed(KEY_F11)
	if Input.is_key_pressed(KEY_B) and not _book_key_was_pressed:
		_toggle_rule_book()
	_book_key_was_pressed = Input.is_key_pressed(KEY_B)

	if not room_ending:
		ecs.tick(delta)
	_handle_events(ecs.drain_events())
	_update_token_hud()
	_update_cell_status()


func _setup_hud() -> void:
	if hud == null:
		return
	var player_health: EcsComponents.Health = ecs.get_component(player_id, EcsComponents.HEALTH)
	hud.setup(player_health.current if player_health != null else 3)
	hud.set_encounter_count(remaining_enemies, total_enemies)
	var room_message := "Break the black line."
	if current_room != null and current_room.has_method("get_start_message"):
		room_message = String(current_room.call("get_start_message"))
	hud.set_status(room_message)


func _handle_events(events: Array[Dictionary]) -> void:
	for event in events:
		var entity := int(event.get("entity", 0))
		match event.get("type"):
			&"telegraph_started":
				if board != null:
					board.set_telegraph(entity, event.get("cells", []))
			&"telegraph_finished":
				if board != null:
					board.clear_telegraph(entity)
			&"attack_resolved":
				if board != null:
					board.show_enemy_attack(event.get("cells", []))
			&"attack_landed":
				_on_player_attack_landed(event)
			&"intent_changed":
				if board != null and event.get("intent") is EnemyIntent:
					board.set_enemy_intent(entity, event.get("intent"))
			&"damaged":
				_on_damaged(entity, event)
			&"skill_cooldown":
				_update_skill_cooldown(float(event.get("time_left", 0.0)))
			&"weapon_changed":
				_on_enemy_weapon_changed(entity, event.get("weapon"))
			&"pickup_taken":
				_record_pickup_taken(int(event.get("item", 0)))
				_play_sfx(&"pickup")
				_free_pickup_view(int(event.get("item", 0)))
			&"defeated":
				_on_defeated(entity)
			&"zone_exit":
				_travel_to(StringName(event.get("zone", &"")), StringName(event.get("entry", &"start")))
			&"gate_opened":
				_on_gate_opened(StringName(event.get("gate", &"")))


func _on_player_attack_landed(event: Dictionary) -> void:
	var profile := event.get("profile") as AttackProfile
	if board != null and profile != null:
		board.show_player_attack(event.get("cells", []), int(event.get("hit_count", 0)), profile)
	if int(event.get("hit_count", 0)) > 0:
		_start_screen_shake(0.10, 2.6)
		if profile != null:
			_update_status("%s connects. Keep pressing the broken line." % profile.display_name)


func _on_damaged(entity: int, event: Dictionary) -> void:
	if entity != player_id:
		return
	var remaining := int(event.get("remaining", 0))
	_start_screen_shake(0.16, 4.2 + float(event.get("amount", 1)))
	if hud != null:
		hud.flash_damage()
		hud.set_courage(remaining)
	if remaining == 1:
		_update_status("One courage left. Wait for the warning, then cut through.")
	elif remaining > 1:
		_update_status("The pawn is hit. Move out before the next strike.")


func _on_enemy_weapon_changed(entity: int, weapon) -> void:
	if weapon == null:
		return
	var piece_name := String(cast.get("piece_name_by_entity", {}).get(entity, "Enemy"))
	_update_status("%s picked up %s. Its chess attack has been replaced." % [piece_name, weapon.display_name])


func _free_pickup_view(item_id: int) -> void:
	var pickup_views: Dictionary = cast.get("pickup_view_by_entity", {})
	var view := pickup_views.get(item_id) as Node2D
	if view != null and is_instance_valid(view):
		view.queue_free()
	pickup_views.erase(item_id)


func _on_defeated(entity: int) -> void:
	if entity == player_id:
		_on_player_defeated()
		return
	if board != null:
		board.clear_telegraph(entity)
		board.clear_enemy_debug(entity)
	remaining_enemies = maxi(0, remaining_enemies - 1)
	defeated_enemies += 1
	if hud != null:
		hud.set_encounter_count(remaining_enemies, total_enemies)
	_play_defeat_animation(entity)
	_check_completion()


## Death visuals are editor-owned now: ViewSyncSystem travels the view's
## AnimationTree to the defeat clip (squash + crumple sound). The bridge only
## schedules the despawn after the clip has had its moment.
func _play_defeat_animation(entity: int) -> void:
	var view := cast.get("view_by_entity", {}).get(entity) as Node2D
	if view == null or not is_instance_valid(view):
		return
	var tween := create_tween()
	tween.tween_interval(0.6)
	tween.tween_callback(func() -> void:
		ecs.remove_component(entity, EcsComponents.VIEW_REF)
		if is_instance_valid(view):
			view.queue_free())


func _check_completion() -> void:
	if room_ending:
		return
	# World mode: clearing a zone is quiet — only an explicit objective (boss
	# arenas, later) can end the run with a result screen.
	if world_graph != null and (current_room == null or current_room.get("objective") == null):
		return
	var complete := total_enemies > 0 and remaining_enemies <= 0
	var objective: Resource = current_room.get("objective") if current_room != null else null
	if objective != null and objective.has_method("is_complete"):
		complete = bool(objective.call("is_complete", defeated_enemies, total_enemies, remaining_enemies))
	if not complete:
		return
	room_ending = true
	_set_player_control(false)
	_play_sfx(&"room_clear")
	var clear_message := _room_text("get_clear_message", "ROOM CLEARED")
	_update_status(clear_message)
	_show_result(clear_message, _room_text("get_clear_subtitle", "PRESS R TO RESET"))


func _on_player_defeated() -> void:
	if room_ending:
		return
	room_ending = true
	var world_state := _world_state()
	if world_state != null:
		world_state.player_health_carry = -1
		world_state.save_state()
	_play_sfx(&"defeat_jingle")
	var defeat_message := _room_text("get_defeat_message", "THE PAWN FALLS")
	_update_status(defeat_message)
	_show_result(defeat_message, _room_text("get_defeat_subtitle", "THE CHILD RESETS THE BOARD"))
	var tree := get_tree()
	if tree == null:
		return
	await tree.create_timer(0.85).timeout
	if is_inside_tree():
		tree.reload_current_scene()


func _update_token_hud() -> void:
	if hud == null or ecs.attack_token_owner == _last_token_owner:
		return
	_last_token_owner = ecs.attack_token_owner
	if _last_token_owner == 0:
		hud.set_token_owner("")
	else:
		hud.set_token_owner(String(cast.get("piece_name_by_entity", {}).get(_last_token_owner, "Enemy")))


func _update_cell_status() -> void:
	if hud == null:
		return
	var grid_pos: EcsComponents.GridPos = ecs.get_component(player_id, EcsComponents.GRID_POS)
	var facing: EcsComponents.Facing = ecs.get_component(player_id, EcsComponents.FACING)
	if grid_pos != null and facing != null:
		hud.set_cell_status(grid_pos.cell, _facing_name(facing.direction))


func _update_skill_cooldown(time_left: float) -> void:
	if hud == null:
		return
	var combat: EcsComponents.PlayerCombat = ecs.get_component(player_id, EcsComponents.PLAYER_COMBAT)
	hud.set_skill_cooldown(time_left, combat.skill_cooldown_duration if combat != null else 1.0)


func _set_player_control(value: bool) -> void:
	var tag: EcsComponents.PlayerTag = ecs.get_component(player_id, EcsComponents.PLAYER_TAG)
	if tag != null:
		tag.control_enabled = value


func _set_debug_enabled(value: bool) -> void:
	debug_enabled = value
	if board != null:
		board.set_debug_enabled(value)
	_update_status("DEBUG VIEW ON: boundaries, paths, and behavior labels." if value else "DEBUG VIEW OFF.")


func _room_text(getter: StringName, fallback: String) -> String:
	if current_room != null and current_room.has_method(getter):
		return String(current_room.call(getter))
	return fallback


func _update_status(text: String) -> void:
	if hud != null:
		hud.set_status(text)


func _show_result(title: String, subtitle: String) -> void:
	if hud != null:
		hud.show_result(title, subtitle)


func _start_screen_shake(duration: float, strength: float) -> void:
	if camera_rig != null:
		camera_rig.start_shake(duration, strength)


## Event sounds route through the SfxManager autoload (layer 3 of the sound
## structure). Looked up by path so headless tests without autoloads stay
## silent instead of crashing.
func _play_sfx(sound_name: StringName) -> void:
	var sfx := get_node_or_null("/root/SfxManager")
	if sfx != null:
		sfx.call("play", sound_name)


## --- Zone travel (the world map) -----------------------------------------


## The player stepped on a door cell: fade out, swap the zone scene, rebuild
## the simulation, fade back in. WorldState carries health and remembers the
## destination so death/R reloads land in the right zone.
func _travel_to(zone_id: StringName, entry_id: StringName) -> void:
	if travel_in_progress or room_ending or world_graph == null or not world_graph.has_zone(zone_id):
		return
	travel_in_progress = true
	_set_player_control(false)
	var world_state := _world_state()
	if world_state != null:
		var health: EcsComponents.Health = ecs.get_component(player_id, EcsComponents.HEALTH)
		world_state.player_health_carry = health.current if health != null else -1
		world_state.current_zone_id = zone_id
		world_state.last_entry_id = entry_id
		world_state.save_state()
	await _fade_to(1.0)
	current_room = _swap_zone_node(zone_id)
	_boot_zone(entry_id)
	await _fade_to(0.0)
	_set_player_control(true)
	travel_in_progress = false


## Replaces the current zone node with the target zone's scene, keeping the
## tree position so draw order (board below, HUD above) stays intact.
func _swap_zone_node(zone_id: StringName) -> Node:
	var zone_scene := world_graph.get_zone_scene(zone_id) if world_graph != null else null
	if zone_scene == null:
		return current_room
	var slot_index := current_room.get_index() if current_room != null else get_child_count()
	if current_room != null:
		remove_child(current_room)
		current_room.queue_free()
	var zone := zone_scene.instantiate()
	add_child(zone)
	move_child(zone, slot_index)
	return zone


func _find_entry_cell(zone_root: Node, entry_id: StringName) -> Vector2i:
	if zone_root == null:
		return Vector2i(-1, -1)
	var fallback := Vector2i(-1, -1)
	for child in zone_root.get_children():
		var entry := child as ZoneEntryMarker
		if entry == null:
			continue
		var cell := ecs.grid.world_to_cell(entry.position)
		if entry.entry_id == entry_id:
			return cell
		if fallback == Vector2i(-1, -1):
			fallback = cell
	return fallback


## The editor-owned FadeLayer rect; the bridge only tweens its alpha.
func _fade_to(target_alpha: float) -> void:
	var fade_rect := get_node_or_null(fade_rect_path) as ColorRect
	if fade_rect == null:
		return
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", target_alpha, 0.22)
	await tween.finished


func _record_pickup_taken(item_id: int) -> void:
	var world_state := _world_state()
	if world_state == null or current_zone_id == &"":
		return
	var marker_name := String(cast.get("pickup_name_by_entity", {}).get(item_id, ""))
	if not marker_name.is_empty():
		world_state.taken_pickup_ids[world_state.pickup_id(current_zone_id, marker_name)] = true
		world_state.save_state()


## A shortcut gate unbarred: permanent from this moment, across deaths and
## launches. The marker's closed-gate visual disappears.
func _on_gate_opened(gate_id: StringName) -> void:
	var world_state := _world_state()
	if world_state != null and gate_id != &"":
		world_state.opened_gate_ids[String(gate_id)] = true
		world_state.save_state()
	_hide_opened_gate_visuals()
	_play_sfx(&"gate_open")
	_update_status("The gate unbars. It will never close again.")


func _opened_gate_ids() -> Array:
	var world_state := _world_state()
	if world_state == null:
		return []
	var ids: Array = []
	for key in world_state.opened_gate_ids:
		ids.append(StringName(key))
	return ids


func _hide_opened_gate_visuals() -> void:
	if current_room == null:
		return
	var opened := _opened_gate_ids()
	for child in current_room.get_children():
		var gate_marker := child as GateMarker
		if gate_marker != null:
			gate_marker.visible = gate_marker.gate_id not in opened


## Pickup marker names already taken in this zone (WorldState) — EcsBoot
## skips them so grabbed weapons never respawn.
func _taken_pickup_names() -> Array:
	var world_state := _world_state()
	var zone_id := _zone_id_of(current_room)
	if world_state == null or zone_id == &"":
		return []
	var names: Array = []
	var prefix := String(zone_id) + "/"
	for key: String in world_state.taken_pickup_ids:
		if key.begins_with(prefix):
			names.append(key.substr(prefix.length()))
	return names


func _zone_id_of(zone_root: Node) -> StringName:
	if zone_root == null:
		return &""
	var value: Variant = zone_root.get("zone_id")
	return value if value is StringName else &""


## WorldState autoload, null-safe so headless tests without autoloads run.
func _world_state() -> Node:
	return get_node_or_null("/root/WorldState")


## --- The Book of House Rules -------------------------------------------


## Meeting a piece = sharing a zone with it. Every definition present in the
## freshly booted zone writes its page into the book, once, forever.
func _unlock_met_rules() -> void:
	var world_state := _world_state()
	if world_state != null and current_room != null:
		var newly_met := false
		for child in current_room.get_children():
			var view := child as ActorView
			if view == null or view.definition == null:
				continue
			var piece_id := String(view.definition.id)
			if not world_state.unlocked_rule_ids.has(piece_id):
				world_state.unlocked_rule_ids[piece_id] = true
				newly_met = true
		if newly_met:
			world_state.save_state()
			_update_status("New pieces on the board. The book writes their rules. [B]")
	var book := _rule_book_ui()
	if book != null:
		book.refresh(_unlocked_rule_ids())


func _toggle_rule_book() -> void:
	var book := _rule_book_ui()
	if book == null or travel_in_progress:
		return
	book.visible = not book.visible
	if book.visible:
		book.refresh(_unlocked_rule_ids())
	_set_player_control(not book.visible)


func _rule_book_ui() -> RuleBookUI:
	return get_node_or_null(^"RuleBookUI") as RuleBookUI


func _unlocked_rule_ids() -> Array:
	var world_state := _world_state()
	if world_state == null:
		return []
	var ids: Array = []
	for key in world_state.unlocked_rule_ids:
		ids.append(StringName(key))
	return ids


func _facing_name(direction: Vector2i) -> String:
	if direction == Vector2i.UP:
		return "N"
	if direction == Vector2i.DOWN:
		return "S"
	if direction == Vector2i.LEFT:
		return "W"
	return "E"
