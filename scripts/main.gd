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
var debug_enabled := true
var _debug_key_was_pressed := false
var _last_token_owner := 0


func _ready() -> void:
	ecs = EcsWorld.new()
	ecs.name = "EcsWorld"
	ecs.manual_tick = true
	add_child(ecs)
	ecs.add_system(PlayerInputSystem.new())
	ecs.add_system(EnemyAISystem.new())
	ecs.add_system(MovementSystem.new())
	ecs.add_system(CombatSystem.new())
	ecs.add_system(HealthSystem.new())
	ecs.add_system(ViewSyncSystem.new())

	current_room = get_node_or_null(room_path)
	var player_view := get_node_or_null(hero_path) as ActorView
	board = get_node_or_null(board_path) as PrototypeBoard
	hud = get_node_or_null(hud_path) as GameHud

	cast = EcsBoot.boot(ecs, player_view, current_room, hero_start_cell)
	player_id = int(cast.get("player", 0))
	total_enemies = cast.get("enemies", []).size()
	remaining_enemies = total_enemies

	if board != null:
		board.z_index = -5
		board.setup(ecs.grid, ecs)
	if player_view != null:
		camera_rig = player_view.get_node_or_null("Camera2D") as CameraRig
		if camera_rig != null:
			camera_rig.setup(ecs.grid)
	_setup_hud()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart_room"):
		get_tree().reload_current_scene()
	if Input.is_key_pressed(KEY_F3) and not _debug_key_was_pressed:
		_set_debug_enabled(not debug_enabled)
	_debug_key_was_pressed = Input.is_key_pressed(KEY_F3)

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
				_free_pickup_view(int(event.get("item", 0)))
			&"defeated":
				_on_defeated(entity)


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
	var complete := total_enemies > 0 and remaining_enemies <= 0
	var objective: Resource = current_room.get("objective") if current_room != null else null
	if objective != null and objective.has_method("is_complete"):
		complete = bool(objective.call("is_complete", defeated_enemies, total_enemies, remaining_enemies))
	if not complete:
		return
	room_ending = true
	_set_player_control(false)
	var clear_message := _room_text("get_clear_message", "ROOM CLEARED")
	_update_status(clear_message)
	_show_result(clear_message, _room_text("get_clear_subtitle", "PRESS R TO RESET"))


func _on_player_defeated() -> void:
	if room_ending:
		return
	room_ending = true
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


func _facing_name(direction: Vector2i) -> String:
	if direction == Vector2i.UP:
		return "N"
	if direction == Vector2i.DOWN:
		return "S"
	if direction == Vector2i.LEFT:
		return "W"
	return "E"
