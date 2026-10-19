extends Node2D

## Boots the ECS world from the editor-authored scene and bridges its events to
## the presentation (docs/ecs-conversion-plan.md): parked views become entities
## (EcsBoot), systems run the whole game, and this script only translates the
## event queue into HUD text, board overlay calls, camera shake, and view
## despawns. No gameplay decision lives here.

## The save service autoload has no class_name (an autoload's name is a global), so its script is the type.
const SaveServiceScript := preload("res://shell/save/save_service.gd")

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
## Courage carried across a zone travel: the hero's health when the trip started, applied to the next
## world's hero by _boot_zone and consumed there. -1 = no carry (a fresh boot, or a death). Never saved:
## every launch starts the room with full Courage. The PlayerSnapshot (M3b) replaces it.
var player_health_carry := -1
## The only reader of the Input singleton: copies the controls into ecs.input_snapshot once per frame.
var input_poller := InputPoller.new()
## Hands the events the world drains each frame to the code that reacts to them.
var router := EventRouter.new()
## What the combat events draw on the board overlay (telegraphs, strike flashes, the F3 layer).
var board_bridge := BoardBridge.new()
## When the screen shakes, and framing each room that boots.
var camera_bridge := CameraBridge.new()
var _last_token_owner := 0


func _ready() -> void:
	current_room = get_node_or_null(room_path)
	player_view = get_node_or_null(hero_path) as ActorView
	board = get_node_or_null(board_path) as PrototypeBoard
	board_bridge.attach(board)
	hud = get_node_or_null(hud_path) as GameHud
	if player_view != null:
		camera_rig = player_view.get_node_or_null("Camera2D") as CameraRig
	camera_bridge.attach(camera_rig)

	# Death and R both reload this scene; the SaveService (autoload) holds the run, so the
	# reload boots in the zone the run is in, not the default. A game that has just launched
	# has no run yet: ensure_session() continues the saved one.
	var entry_id: StringName = &"start"
	var save := _save_service()
	if save != null:
		save.ensure_session()
		# A save asks the shell for the facts only the live world knows (its flags) before it writes.
		save.saving.connect(_on_save_service_saving)
		entry_id = save.state.checkpoint_entry_id
		if world_graph != null and save.state.checkpoint_zone_id != &"" \
			and save.state.checkpoint_zone_id != _zone_id_of(current_room):
			current_room = _swap_zone_node(save.state.checkpoint_zone_id)
	_register_event_handlers()
	_boot_zone(entry_id)


## Builds a fresh EcsWorld from the current zone node. Called at scene start
## and again after every zone swap — the whole simulation is rebuilt, only
## the player view node and the SaveService persist.
func _boot_zone(entry_id: StringName) -> void:
	if ecs != null:
		remove_child(ecs)
		ecs.queue_free()
	ecs = _make_world()
	# The room's own grid origin first: the entry cell below is read off the marker's position with it.
	EcsBoot.shape_grid(ecs, current_room)
	var entry_cell := _find_entry_cell(current_room, entry_id)
	if player_view != null and entry_cell != Vector2i(-1, -1):
		player_view.position = ecs.grid.cell_to_world(entry_cell)

	var boot_options := EcsBootOptions.for_scene(player_view, current_room)
	boot_options.fallback_player_cell = hero_start_cell
	boot_options.skipped_pickup_names = _taken_pickup_names()
	boot_options.opened_gate_ids = _opened_gate_ids()
	cast = EcsBoot.boot(ecs, boot_options)
	board_bridge.bind_world(ecs.hud_snapshot, cast)
	camera_bridge.bind_world(ecs.hud_snapshot, cast)
	current_zone_id = _zone_id_of(current_room)
	# The run's facts enter the new world before anything can ask for a save: the world's flags are
	# the saved ones, and the save knows which zone this is.
	var save := _save_service()
	if save != null:
		ecs.flags.load_dictionary(save.state.player.flags)
		if current_zone_id != &"":
			save.state.checkpoint_zone_id = current_zone_id
			save.current_room_id = current_zone_id
	_hide_opened_gate_visuals()
	_unlock_met_rules()
	player_id = int(cast.get("player", 0))
	_apply_player_unlocks()
	total_enemies = cast.get("enemies", []).size()
	remaining_enemies = total_enemies
	defeated_enemies = 0
	room_ending = false
	_last_token_owner = -1

	if player_health_carry > 0:
		var health: EcsComponents.Health = ecs.get_component(player_id, EcsComponents.HEALTH)
		if health != null:
			health.current = mini(player_health_carry, health.max_value)
	player_health_carry = -1

	# The HUD and the board draw from the snapshot, so it must hold the booted room (with the carried
	# health and the unlocks written above) before the first tick builds it again.
	HudSnapshotSystem.build(ecs)
	board_bridge.show_room(ecs.grid, debug_enabled)
	camera_bridge.show_room(ecs.grid)
	_setup_hud()


func _make_world() -> EcsWorld:
	var world := EcsWorld.new()
	world.name = "EcsWorld"
	world.manual_tick = true
	add_child(world)
	Schedule.populate(world)
	return world


func _process(delta: float) -> void:
	var save := _save_service()
	if save != null:
		save.add_play_time(delta)
	input_poller.poll(delta, ecs.input_snapshot)
	var controls := ecs.input_snapshot
	if controls.is_just_pressed(&"restart_room"):
		get_tree().reload_current_scene()
	if controls.is_just_pressed(&"debug_view_toggle"):
		_set_debug_enabled(not debug_enabled)
	if controls.is_just_pressed(&"fullscreen_toggle"):
		var window := get_window()
		window.mode = Window.MODE_WINDOWED if window.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
	if controls.is_just_pressed(&"rule_book_toggle"):
		_toggle_rule_book()

	if not room_ending:
		ecs.tick(delta)
	router.route(ecs.drain_events())
	_update_token_hud()
	_update_cell_status()


func _setup_hud() -> void:
	if hud == null:
		return
	var snapshot := ecs.hud_snapshot
	hud.setup(snapshot.player_courage_current if snapshot.player_entity != 0 else 3)
	hud.set_encounter_count(remaining_enemies, total_enemies)
	_update_skill_cooldown(0.0)
	_update_token_hud()
	var room_message := "Break the black line."
	if current_room != null and current_room.has_method("get_start_message"):
		room_message = String(current_room.call("get_start_message"))
	hud.set_status(room_message)


## Every event type the scene reacts to, and what reacts. The router calls these in registration order.
func _register_event_handlers() -> void:
	board_bridge.register(router)
	camera_bridge.register(router)
	router.on(Events.ATTACK_LANDED, _on_player_attack_landed)
	router.on(Events.ATTACK_LOCKED, _on_attack_locked)
	router.on(Events.DAMAGED, _on_damaged)
	router.on(Events.SKILL_COOLDOWN, _on_skill_cooldown)
	router.on(Events.WEAPON_CHANGED, _on_enemy_weapon_changed)
	router.on(Events.PICKUP_TAKEN, _on_pickup_taken)
	router.on(Events.PLAYER_UNLOCK, _on_player_unlock)
	router.on(Events.DEFEATED, _on_defeated)
	router.on(Events.ZONE_EXIT, _on_zone_exit)
	router.on(Events.ZONE_EXIT_LOCKED, _on_zone_exit_locked)
	router.on(Events.GATE_OPENED, _on_gate_opened)


func _on_attack_locked(_event: Dictionary) -> void:
	_update_status("The pawn has no weapon yet. Find the fallen sword.")


func _on_skill_cooldown(event: Dictionary) -> void:
	_update_skill_cooldown(float(event.get("time_left", 0.0)))


func _on_pickup_taken(event: Dictionary) -> void:
	_record_pickup_taken(int(event.get("item", 0)))
	_play_sfx(&"pickup")
	_free_pickup_view(int(event.get("item", 0)))


func _on_zone_exit(event: Dictionary) -> void:
	_travel_to(StringName(event.get("zone", &"")), StringName(event.get("entry", &"start")))


func _on_player_attack_landed(event: Dictionary) -> void:
	var profile := event.get("profile") as AttackProfile
	if int(event.get("hit_count", 0)) > 0:
		if profile != null:
			_update_status("%s connects. Keep pressing the broken line." % profile.display_name)


func _on_damaged(event: Dictionary) -> void:
	if int(event.get("entity", 0)) != player_id:
		return
	var remaining := int(event.get("remaining", 0))
	if hud != null:
		hud.flash_damage()
		hud.set_courage(remaining)
	if remaining == 1:
		_update_status("One courage left. Wait for the warning, then cut through.")
	elif remaining > 1:
		_update_status("The pawn is hit. Move out before the next strike.")


func _on_enemy_weapon_changed(event: Dictionary) -> void:
	var entity := int(event.get("entity", 0))
	var weapon = event.get("weapon")
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


func _on_defeated(event: Dictionary) -> void:
	var entity := int(event.get("entity", 0))
	if entity == player_id:
		_on_player_defeated()
		return
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
	# A death writes no save: autosave is for success events only (R17, D-16), and the run already
	# wrote down everything it learned when it learned it.
	player_health_carry = -1
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
	var token_owner := ecs.hud_snapshot.attack_token_owner
	if hud == null or token_owner == _last_token_owner:
		return
	_last_token_owner = token_owner
	if total_enemies <= 0:
		hud.set_token_owner("", false)
	elif _last_token_owner == 0:
		hud.set_token_owner("")
	else:
		hud.set_token_owner(String(cast.get("piece_name_by_entity", {}).get(_last_token_owner, "Enemy")))


func _update_cell_status() -> void:
	if hud == null:
		return
	var snapshot := ecs.hud_snapshot
	if snapshot.player_entity != 0:
		hud.set_cell_status(snapshot.player_cell, _facing_name(snapshot.player_facing))


## Shows the skill slot for `time_left` seconds of cooldown. The slot is redrawn when a
## skill_cooldown event arrives (and at boot), as it always was, from the snapshot's length and
## sword flag. M4's widgets draw the snapshot every frame instead.
func _update_skill_cooldown(time_left: float) -> void:
	if hud == null:
		return
	var snapshot := ecs.hud_snapshot
	hud.set_skill_cooldown(time_left, snapshot.skill_cooldown_duration, snapshot.sword_unlocked)


func _set_player_control(value: bool) -> void:
	var tag: EcsComponents.PlayerTag = ecs.get_component(player_id, EcsComponents.PLAYER_TAG)
	if tag != null:
		tag.control_enabled = value


func _set_debug_enabled(value: bool) -> void:
	debug_enabled = value
	board_bridge.set_debug_view(value)
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


## Event sounds route through the SfxManager autoload (layer 3 of the sound
## structure). Looked up by path so headless tests without autoloads stay
## silent instead of crashing.
func _play_sfx(sound_name: StringName) -> void:
	var sfx := get_node_or_null("/root/SfxManager")
	if sfx != null:
		sfx.call("play", sound_name)


## --- Zone travel (the world map) -----------------------------------------


## The player stepped on a door cell: fade out, swap the zone scene, rebuild
## the simulation, fade back in. The shell carries health and the save remembers
## the destination (as the checkpoint) so death/R reloads land in the right zone.
func _travel_to(zone_id: StringName, entry_id: StringName) -> void:
	if travel_in_progress or room_ending or world_graph == null or not world_graph.has_zone(zone_id):
		return
	travel_in_progress = true
	_set_player_control(false)
	var health: EcsComponents.Health = ecs.get_component(player_id, EcsComponents.HEALTH)
	player_health_carry = health.current if health != null else -1
	var save := _save_service()
	if save != null:
		save.state.checkpoint_zone_id = zone_id
		save.state.checkpoint_entry_id = entry_id
		save.request_save(&"checkpoint_reached")
	await _fade_to(1.0)
	current_room = _swap_zone_node(zone_id)
	_boot_zone(entry_id)
	await _fade_to(0.0)
	_set_player_control(true)
	travel_in_progress = false


func _on_zone_exit_locked(_event: Dictionary) -> void:
	_update_status("The captain still holds the rug edge. Break the black line first.")


func _apply_player_unlocks() -> void:
	var combat: EcsComponents.PlayerCombat = ecs.get_component(player_id, EcsComponents.PLAYER_COMBAT)
	if combat == null:
		return
	var save := _save_service()
	if world_graph != null and save != null:
		combat.sword_unlocked = save.state.has_unlock(PlayerSnapshot.SWORD_UNLOCK_ID)
		# The shell just wrote a component the snapshot copies; publish it now rather than a tick late.
		HudSnapshotSystem.build(ecs)
	_hide_taken_player_unlocks()


func _on_player_unlock(event: Dictionary) -> void:
	var unlock_id := StringName(event.get("id", &""))
	var message := String(event.get("message", ""))
	if unlock_id == &"":
		return
	var save := _save_service()
	if save != null:
		save.state.add_unlock(unlock_id)
		save.request_save(&"unlock_gained")
	_apply_player_unlocks()
	_play_sfx(&"pickup")
	_update_status(message if not message.is_empty() else "The pawn grips the sword. The rules crack.")


func _hide_taken_player_unlocks() -> void:
	var save := _save_service()
	if save == null or current_room == null:
		return
	for child in current_room.get_children():
		var marker := child as PlayerUnlockMarker
		if marker != null and save.state.has_unlock(marker.unlock_id):
			marker.visible = false


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
	var save := _save_service()
	if save == null or current_zone_id == &"":
		return
	var marker_name := String(cast.get("pickup_name_by_entity", {}).get(item_id, ""))
	if not marker_name.is_empty():
		save.state.taken_pickup_ids[SaveData.pickup_id(current_zone_id, marker_name)] = true
		save.request_save(&"pickup_taken")


## A shortcut gate unbarred: permanent from this moment, across deaths and
## launches. The marker's closed-gate visual disappears.
func _on_gate_opened(event: Dictionary) -> void:
	var gate_id := StringName(event.get("gate", &""))
	var save := _save_service()
	if save != null and gate_id != &"":
		save.state.opened_gate_ids[String(gate_id)] = true
		save.request_save(&"shortcut_opened")
	_hide_opened_gate_visuals()
	_play_sfx(&"gate_open")
	_update_status("The gate unbars. It will never close again.")


func _opened_gate_ids() -> Array:
	var save := _save_service()
	if save == null:
		return []
	var ids: Array = []
	for key in save.state.opened_gate_ids:
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


## Pickup marker names already taken in this zone (the save) — EcsBoot
## skips them so grabbed weapons never respawn.
func _taken_pickup_names() -> Array:
	var save := _save_service()
	var zone_id := _zone_id_of(current_room)
	if save == null or zone_id == &"":
		return []
	var names: Array = []
	var prefix := String(zone_id) + "/"
	for key: String in save.state.taken_pickup_ids:
		if key.begins_with(prefix):
			names.append(key.substr(prefix.length()))
	return names


func _zone_id_of(zone_root: Node) -> StringName:
	if zone_root == null:
		return &""
	var value: Variant = zone_root.get("zone_id")
	return value if value is StringName else &""


## The SaveService autoload, null-safe so headless tests without autoloads run.
func _save_service() -> SaveServiceScript:
	return get_node_or_null("/root/SaveService") as SaveServiceScript


## The save is about to be written: it learns the flags of the world that is running now, because the
## world is where they change (the save only holds them between rooms).
func _on_save_service_saving(_reason: StringName) -> void:
	var save := _save_service()
	if save != null and ecs != null:
		save.state.player.flags = ecs.flags.to_dictionary()


## --- The Book of House Rules -------------------------------------------


## Meeting a piece = sharing a zone with it. Every definition present in the
## freshly booted zone writes its page into the book, once, forever.
func _unlock_met_rules() -> void:
	var save := _save_service()
	if save != null and current_room != null:
		var newly_met := false
		for child in current_room.get_children():
			var view := child as ActorView
			if view == null or view.definition == null:
				continue
			var piece_id := String(view.definition.id)
			if not save.state.unlocked_rule_ids.has(piece_id):
				save.state.unlocked_rule_ids[piece_id] = true
				newly_met = true
		if newly_met:
			save.request_save(&"rule_page_unlocked")
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
	var save := _save_service()
	if save == null:
		return []
	var ids: Array = []
	for key in save.state.unlocked_rule_ids:
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
