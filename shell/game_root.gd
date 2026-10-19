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
var player_view: ActorView
var current_zone_id: StringName = &""
## Where the hero's view stands in the authored scene, before the first boot moves it to an entry. A
## respawn builds a fresh view and parks it here, as a reload of the scene would have.
var hero_parked_position := Vector2.ZERO
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
## How a room ends: the enemy counts, a win, the hero's fall.
var outcome_bridge := RoomOutcomeBridge.new()
## The trip between zones: fade, swap, rebuild, fade, and the Courage carried across.
var zone_travel_bridge := ZoneTravelBridge.new()
## Starting the room again after a death or the restart key, without reloading the scene.
var game_flow := GameFlow.new()


func _ready() -> void:
	current_room = get_node_or_null(room_path)
	player_view = get_node_or_null(hero_path) as ActorView
	if player_view != null:
		hero_parked_position = player_view.position
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
	outcome_bridge.attach(self)
	zone_travel_bridge.attach(self)
	game_flow.attach(self)

	# The SaveService (autoload) holds the run, so the scene boots in the zone the run is in, not the
	# authored default. A game that has just launched has no run yet: begin() continues the saved one.
	save_bridge.begin()
	var checkpoint_zone := save_bridge.checkpoint_zone_id()
	if world_graph != null and checkpoint_zone != &"" and checkpoint_zone != zone_id_of(current_room):
		swap_zone(checkpoint_zone)
	_register_event_handlers()
	boot_zone(save_bridge.checkpoint_entry_id())


## Builds a fresh EcsWorld from the current zone node. Called at scene start
## and again after every zone swap — the whole simulation is rebuilt, only
## the player view node and the SaveService persist.
func boot_zone(entry_id: StringName) -> void:
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
	outcome_bridge.bind_world(ecs.hud_snapshot, cast)
	current_zone_id = zone_id_of(current_room)
	save_bridge.restore_run(current_zone_id)
	book_bridge.meet_pieces()
	save_bridge.apply_unlocks()
	outcome_bridge.begin_room(cast.get("enemies", []).size())

	zone_travel_bridge.apply_health_carry()

	# The HUD and the board draw from the snapshot, so it must hold the booted room (with the carried
	# health and the unlocks written above) before the first tick builds it again.
	HudSnapshotSystem.build(ecs)
	board_bridge.show_room(ecs.grid, debug_enabled)
	camera_bridge.show_room(ecs.grid)
	hud_bridge.show_room(outcome_bridge.enemies_remaining, outcome_bridge.enemies_total)
	message_bridge.say(room_text("get_start_message", "Break the black line."))


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
		game_flow.request_respawn(GameFlow.REASON_RESTART_KEY)
	if controls.is_just_pressed(&"debug_view_toggle"):
		_set_debug_enabled(not debug_enabled)
	if controls.is_just_pressed(&"fullscreen_toggle"):
		var window := get_window()
		window.mode = Window.MODE_WINDOWED if window.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
	if controls.is_just_pressed(&"rule_book_toggle"):
		book_bridge.toggle()

	if not outcome_bridge.room_ending:
		ecs.tick(delta)
	router.route(ecs.drain_events())
	hud_bridge.refresh()


## Every event type the scene reacts to, and what reacts. The router calls these in registration order.
func _register_event_handlers() -> void:
	board_bridge.register(router)
	camera_bridge.register(router)
	hud_bridge.register(router)
	save_bridge.register(router)
	audio_bridge.register(router)
	despawn_bridge.register(router)
	outcome_bridge.register(router)
	message_bridge.register(router)
	zone_travel_bridge.register(router)


func set_player_control(value: bool) -> void:
	var tag: EcsComponents.PlayerTag = ecs.get_component(player_id, EcsComponents.PLAYER_TAG)
	if tag != null:
		tag.control_enabled = value


func _set_debug_enabled(value: bool) -> void:
	debug_enabled = value
	board_bridge.set_debug_view(value)
	message_bridge.say("DEBUG VIEW ON: boundaries, paths, and behavior labels." if value else "DEBUG VIEW OFF.")


## Starts the room again at the run's checkpoint without leaving the scene (GameFlow calls it for a
## death or the restart key). The result is what a reload of the scene used to boot: the zone is a fresh
## instance (every enemy and pickup back, the cleared-room rules of D-17 arrive in step 3), the hero's
## view is a fresh one in its boot pose, the Book is closed, nothing is carried, and the HUD, board and
## camera are bound to the new room. What the scene keeps is the run, the music and the F3 switch.
func respawn() -> void:
	book_bridge.close()
	zone_travel_bridge.forget_health_carry()
	_replace_hero_view()
	var zone_id := save_bridge.checkpoint_zone_id()
	if zone_id == &"":
		zone_id = current_zone_id
	_replace_zone_node(_zone_scene_for(zone_id))
	boot_zone(save_bridge.checkpoint_entry_id())


## The room's own prose for `getter` (its start, clear or defeat line), or `fallback` when the room has none.
func room_text(getter: StringName, fallback: String) -> String:
	if current_room != null and current_room.has_method(getter):
		return String(current_room.call(getter))
	return fallback


## Replaces the current zone node with the target zone's scene, keeping the
## tree position so draw order (board below, HUD above) stays intact. A zone the graph does not have
## leaves the current one in place.
func swap_zone(zone_id: StringName) -> void:
	var zone_scene := world_graph.get_zone_scene(zone_id) if world_graph != null else null
	if zone_scene != null:
		_replace_zone_node(zone_scene)


## The scene of zone `zone_id`: the world graph's, or for a room outside the graph (a standalone scene)
## the scene the current room was made from, so a respawn can always build a fresh one.
func _zone_scene_for(zone_id: StringName) -> PackedScene:
	var zone_scene := world_graph.get_zone_scene(zone_id) if world_graph != null else null
	if zone_scene == null and current_room != null and not current_room.scene_file_path.is_empty():
		zone_scene = load(current_room.scene_file_path) as PackedScene
	return zone_scene


func _replace_zone_node(zone_scene: PackedScene) -> void:
	if zone_scene == null:
		return
	var slot_index := current_room.get_index() if current_room != null else get_child_count()
	if current_room != null:
		remove_child(current_room)
		current_room.queue_free()
	var zone := zone_scene.instantiate()
	add_child(zone)
	move_child(zone, slot_index)
	current_room = zone


## Swaps the hero's view for a fresh instance of its scene, in the same place in the tree, parked where the
## authored scene parks it. A defeated hero's view holds the end of its defeat clip; a new one boots in the
## pose its animation graph gives it (the hero gets up). A view that was not made from a scene file (a bare
## test view) cannot be rebuilt and stays.
func _replace_hero_view() -> void:
	if player_view == null or player_view.scene_file_path.is_empty():
		return
	var fresh_view := (load(player_view.scene_file_path) as PackedScene).instantiate() as ActorView
	if fresh_view == null:
		return
	var slot_index := player_view.get_index()
	var view_name := player_view.name
	remove_child(player_view)
	player_view.queue_free()
	fresh_view.name = view_name
	fresh_view.position = hero_parked_position
	add_child(fresh_view)
	move_child(fresh_view, slot_index)
	player_view = fresh_view
	camera_rig = player_view.get_node_or_null("Camera2D") as CameraRig
	camera_bridge.attach(camera_rig)


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


static func zone_id_of(zone_root: Node) -> StringName:
	if zone_root == null:
		return &""
	var value: Variant = zone_root.get("zone_id")
	return value if value is StringName else &""


## The SaveService autoload, null-safe so headless tests without autoloads run.
func save_service() -> SaveServiceScript:
	return get_node_or_null("/root/SaveService") as SaveServiceScript
