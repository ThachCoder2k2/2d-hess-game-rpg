class_name GameRoot
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
## The event sounds that belong to no clip, played through the SfxManager registry.
var audio_bridge := AudioBridge.new()
## The words on the status line that events cause (and the line the scene and other bridges write through).
var message_bridge := MessageBridge.new()
## The HUD kept true to the room: Courage, the skill slot, the enemy count, the strike and cell lines.
var hud_bridge := HudBridge.new()
## What happens to a view when its entity leaves the room (a taken floor weapon, a defeated enemy).
var despawn_bridge := DespawnBridge.new()
## What the room writes into the run and the run gives back to each room; the only asker of saves.
var save_bridge := SaveBridge.new()
## The Book of House Rules: a met piece writes its page, the B key opens the Book.
var book_bridge := BookBridge.new()


func _ready() -> void:
	current_room = get_node_or_null(room_path)
	player_view = get_node_or_null(hero_path) as ActorView
	board = get_node_or_null(board_path) as PrototypeBoard
	board_bridge.attach(board)
	hud = get_node_or_null(hud_path) as GameHud
	if player_view != null:
		camera_rig = player_view.get_node_or_null("Camera2D") as CameraRig
	camera_bridge.attach(camera_rig)
	audio_bridge.attach(self)
	message_bridge.attach(hud)
	hud_bridge.attach(hud)
	despawn_bridge.attach(self)
	save_bridge.attach(self)
	book_bridge.attach(self)

	# Death and R both reload this scene; the SaveService (autoload) holds the run, so the
	# reload boots in the zone the run is in, not the default. A game that has just launched
	# has no run yet: ensure_session() continues the saved one.
	save_bridge.begin()
	var checkpoint_zone := save_bridge.checkpoint_zone_id()
	if world_graph != null and checkpoint_zone != &"" and checkpoint_zone != zone_id_of(current_room):
		current_room = _swap_zone_node(checkpoint_zone)
	_register_event_handlers()
	_boot_zone(save_bridge.checkpoint_entry_id())


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
	save_bridge.fill_boot_options(boot_options, current_room)
	cast = EcsBoot.boot(ecs, boot_options)
	player_id = int(cast.get("player", 0))
	board_bridge.bind_world(ecs.hud_snapshot, cast)
	camera_bridge.bind_world(ecs.hud_snapshot, cast)
	message_bridge.bind_world(ecs.hud_snapshot, cast)
	hud_bridge.bind_world(ecs.hud_snapshot, cast)
	despawn_bridge.bind_world(ecs.hud_snapshot, cast)
	save_bridge.bind_world(ecs.hud_snapshot, cast)
	current_zone_id = zone_id_of(current_room)
	save_bridge.restore_run(current_zone_id)
	book_bridge.meet_pieces()
	save_bridge.apply_unlocks()
	total_enemies = cast.get("enemies", []).size()
	remaining_enemies = total_enemies
	defeated_enemies = 0
	room_ending = false

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
	hud_bridge.show_room(remaining_enemies, total_enemies)
	message_bridge.say(_room_text("get_start_message", "Break the black line."))


func _make_world() -> EcsWorld:
	var world := EcsWorld.new()
	world.name = "EcsWorld"
	world.manual_tick = true
	add_child(world)
	Schedule.populate(world)
	return world


func _process(delta: float) -> void:
	var save := save_service()
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
		book_bridge.toggle()

	if not room_ending:
		ecs.tick(delta)
	router.route(ecs.drain_events())
	hud_bridge.refresh()


## Every event type the scene reacts to, and what reacts. The router calls these in registration order.
func _register_event_handlers() -> void:
	board_bridge.register(router)
	camera_bridge.register(router)
	audio_bridge.register(router)
	hud_bridge.register(router)
	save_bridge.register(router)
	router.on(Events.DEFEATED, _on_defeated)
	router.on(Events.ZONE_EXIT, _on_zone_exit)
	despawn_bridge.register(router)
	message_bridge.register(router)


func _on_zone_exit(event: Dictionary) -> void:
	_travel_to(StringName(event.get("zone", &"")), StringName(event.get("entry", &"start")))


func _on_defeated(event: Dictionary) -> void:
	var entity := int(event.get("entity", 0))
	if entity == player_id:
		_on_player_defeated()
		return
	remaining_enemies = maxi(0, remaining_enemies - 1)
	defeated_enemies += 1
	hud_bridge.show_encounter_count(remaining_enemies, total_enemies)
	_check_completion()


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
	set_player_control(false)
	audio_bridge.play(AudioBridge.ROOM_CLEAR_SOUND)
	var clear_message := _room_text("get_clear_message", "ROOM CLEARED")
	message_bridge.say(clear_message)
	hud_bridge.show_result(clear_message, _room_text("get_clear_subtitle", "PRESS R TO RESET"))


func _on_player_defeated() -> void:
	if room_ending:
		return
	room_ending = true
	# A death writes no save: autosave is for success events only (R17, D-16), and the run already
	# wrote down everything it learned when it learned it.
	player_health_carry = -1
	audio_bridge.play(AudioBridge.DEFEAT_JINGLE_SOUND)
	var defeat_message := _room_text("get_defeat_message", "THE PAWN FALLS")
	message_bridge.say(defeat_message)
	hud_bridge.show_result(defeat_message, _room_text("get_defeat_subtitle", "THE CHILD RESETS THE BOARD"))
	var tree := get_tree()
	if tree == null:
		return
	await tree.create_timer(0.85).timeout
	if is_inside_tree():
		tree.reload_current_scene()


func set_player_control(value: bool) -> void:
	var tag: EcsComponents.PlayerTag = ecs.get_component(player_id, EcsComponents.PLAYER_TAG)
	if tag != null:
		tag.control_enabled = value


func _set_debug_enabled(value: bool) -> void:
	debug_enabled = value
	board_bridge.set_debug_view(value)
	message_bridge.say("DEBUG VIEW ON: boundaries, paths, and behavior labels." if value else "DEBUG VIEW OFF.")


func _room_text(getter: StringName, fallback: String) -> String:
	if current_room != null and current_room.has_method(getter):
		return String(current_room.call(getter))
	return fallback


## --- Zone travel (the world map) -----------------------------------------


## The player stepped on a door cell: fade out, swap the zone scene, rebuild
## the simulation, fade back in. The shell carries health and the save remembers
## the destination (as the checkpoint) so death/R reloads land in the right zone.
func _travel_to(zone_id: StringName, entry_id: StringName) -> void:
	if travel_in_progress or room_ending or world_graph == null or not world_graph.has_zone(zone_id):
		return
	travel_in_progress = true
	set_player_control(false)
	var health: EcsComponents.Health = ecs.get_component(player_id, EcsComponents.HEALTH)
	player_health_carry = health.current if health != null else -1
	save_bridge.record_checkpoint(zone_id, entry_id)
	await _fade_to(1.0)
	current_room = _swap_zone_node(zone_id)
	_boot_zone(entry_id)
	await _fade_to(0.0)
	set_player_control(true)
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


static func zone_id_of(zone_root: Node) -> StringName:
	if zone_root == null:
		return &""
	var value: Variant = zone_root.get("zone_id")
	return value if value is StringName else &""


## The SaveService autoload, null-safe so headless tests without autoloads run.
func save_service() -> SaveServiceScript:
	return get_node_or_null("/root/SaveService") as SaveServiceScript
