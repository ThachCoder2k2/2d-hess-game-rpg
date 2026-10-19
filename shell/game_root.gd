class_name GameRoot
extends Node2D

## The in-game scene (docs/game-base-plan.md 13.2): boots the ECS world from the editor-authored room
## (EcsBoot; the systems come from ecs/schedule/), ticks it once per frame and routes what it says to one
## bridge per responsibility (presentation/bridges: drawn, said, played; shell/bridges: saved, carried,
## ended). No game rule lives here: tests/architecture/test_game_root_is_thin.gd keeps it that way.

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
var current_zone_id: StringName = &""
var board: PrototypeBoard
var hud: GameHud
var camera_rig: CameraRig
var player_view: ActorView
## Where the authored scene parks the hero's view; a respawn parks its fresh view here.
var hero_parked_position := Vector2.ZERO
## The only reader of the Input singleton: copies the controls into ecs.input_snapshot once per frame.
var input_poller := InputPoller.new()
var router := EventRouter.new()
## The flow this scene belongs to: starts the room again after a death or the restart key, without reloading
## the scene. AppRoot gives the scene its own flow before adding it; a scene run alone makes one that is
## already PLAYING.
var game_flow := GameFlow.new(GameFlow.State.PLAYING)
var shell_keys := ShellKeys.new()
# One bridge per responsibility; the header of each file says what it owns.
var board_bridge := BoardBridge.new()
var camera_bridge := CameraBridge.new()
var hud_bridge := HudBridge.new()
var message_bridge := MessageBridge.new()
var audio_bridge := AudioBridge.new()
var save_bridge := SaveBridge.new()
var despawn_bridge := DespawnBridge.new()
var outcome_bridge := RoomOutcomeBridge.new()
var zone_travel_bridge := ZoneTravelBridge.new()
var book_bridge := BookBridge.new()


func _ready() -> void:
	current_room = get_node_or_null(room_path)
	board = get_node_or_null(board_path) as PrototypeBoard
	hud = get_node_or_null(hud_path) as GameHud
	_attach_hero_view(get_node_or_null(hero_path) as ActorView)
	hero_parked_position = player_view.position if player_view != null else Vector2.ZERO
	board_bridge.attach(board)
	hud_bridge.attach(hud)
	message_bridge.attach(hud)
	audio_bridge.attach(self)
	game_flow.attach(self)
	shell_keys.attach(self)
	for bridge: ShellBridge in [save_bridge, despawn_bridge, outcome_bridge, zone_travel_bridge, book_bridge]:
		bridge.attach(self)
	for bridge in _bridges():
		bridge.register(router)

	# The run (the SaveService autoload) says which zone and entry to boot on, not the authored default.
	save_bridge.begin()
	var resume_zone := save_bridge.room_zone_id()
	if world_graph != null and resume_zone != &"" and resume_zone != ZoneStage.zone_id_of(current_room):
		swap_zone(resume_zone)
	boot_zone(save_bridge.room_entry_id())


## Builds a fresh EcsWorld from the current zone node. Called at scene start, after every zone swap and
## after a respawn: the whole simulation is rebuilt, only the hero's view and the run persist.
## `entered_by_door` is true for a zone trip: coming through a door can be a checkpoint, a launch and a
## respawn cannot.
func boot_zone(entry_id: StringName, entered_by_door := false) -> void:
	if ecs != null:
		remove_child(ecs)
		ecs.queue_free()
	ecs = ZoneStage.make_world(self)
	# The room's own grid origin first: the entry cell below is read off the marker's position with it.
	EcsBoot.shape_grid(ecs, current_room)
	var entry_cell := ZoneStage.find_entry_cell(ecs.grid, current_room, entry_id)
	if player_view != null and entry_cell != ZoneStage.NO_ENTRY_CELL:
		player_view.position = ecs.grid.cell_to_world(entry_cell)
	var boot_options := EcsBootOptions.for_scene(player_view, current_room)
	boot_options.fallback_player_cell = hero_start_cell
	boot_options.with_room_rules = true
	boot_options.entry_id = entry_id
	boot_options.entered_by_door = entered_by_door
	boot_options.player_snapshot = zone_travel_bridge.take_carried_snapshot()
	save_bridge.fill_boot_options(boot_options, current_room)
	cast = EcsBoot.boot(ecs, boot_options)
	player_id = int(cast.get("player", 0))
	current_zone_id = ZoneStage.zone_id_of(current_room)
	for bridge in _bridges():
		bridge.bind_world(ecs.hud_snapshot, cast)
	save_bridge.restore_run(current_zone_id, entry_id)
	book_bridge.meet_pieces()
	save_bridge.apply_unlocks()
	outcome_bridge.begin_room()
	# The HUD and the board draw from the snapshot, so it must hold the booted room (with the carried
	# pawn and the unlocks written above) before the first tick builds it again.
	HudSnapshotSystem.build(ecs)
	board_bridge.show_room(ecs.grid, debug_enabled)
	camera_bridge.show_room(ecs.grid)
	hud_bridge.show_room()
	message_bridge.say(ZoneStage.room_text(current_room, "get_start_message", RoomObjective.STOCK_START_KEY))


func _process(delta: float) -> void:
	var save := save_service()
	if save != null:
		save.add_play_time(delta)
	input_poller.poll(delta, ecs.input_snapshot)
	shell_keys.handle(ecs.input_snapshot)
	if not outcome_bridge.room_ending:
		ecs.tick(delta)
	router.route(ecs.drain_events())
	hud_bridge.refresh()


## Starts the room the pawn is in again, on the entry it came by, without leaving the scene (GameFlow calls
## it for a death or the restart key; D-16: a death resets only this room): a fresh zone, a fresh hero view
## in its boot pose, the Book closed, nothing carried. What the scene keeps is the run (it takes the world's
## flags first), the music and the F3 switch.
func respawn() -> void:
	save_bridge.remember_world()
	book_bridge.close()
	zone_travel_bridge.forget_carry()
	_attach_hero_view(ZoneStage.replace_hero_view(self, player_view, hero_parked_position))
	var zone_id := save_bridge.room_zone_id()
	current_room = ZoneStage.replace_zone_node(self, current_room, _zone_scene_for(zone_id if zone_id != &"" else current_zone_id))
	boot_zone(save_bridge.room_entry_id())


## Puts the zone `zone_id` of the world graph in the place of the current one; a zone the graph does not
## have leaves the current one in place.
func swap_zone(zone_id: StringName) -> void:
	var zone_scene := world_graph.get_zone_scene(zone_id) if world_graph != null else null
	current_room = ZoneStage.replace_zone_node(self, current_room, zone_scene)


## The hero's keys: on while the room is live, off during a trip, a Book and the end of a room.
func set_player_control(value: bool) -> void:
	var tag: EcsComponents.PlayerTag = ecs.get_component(player_id, EcsComponents.PLAYER_TAG)
	if tag != null:
		tag.control_enabled = value


## The SaveService autoload, null-safe so headless tests without autoloads run.
func save_service() -> SaveServiceScript:
	return get_node_or_null("/root/SaveService") as SaveServiceScript


## The bridges in the order they react when one event has several: a pickup is saved before its sound
## plays and its view goes, a defeat clears the board before the room counts it, the status line speaks last.
func _bridges() -> Array[EventBridge]:
	return [board_bridge, camera_bridge, hud_bridge, save_bridge, audio_bridge, despawn_bridge, outcome_bridge,
		message_bridge, zone_travel_bridge, book_bridge]


## The hero's view and the camera rig that is its child: the camera bridge follows a replaced view.
func _attach_hero_view(view: ActorView) -> void:
	player_view = view
	camera_rig = view.get_node_or_null("Camera2D") as CameraRig if view != null else null
	camera_bridge.attach(camera_rig)


## The scene of zone `zone_id`: the world graph's, or for a room outside the graph (a standalone scene)
## the scene the current room was made from, so a respawn can always build a fresh one.
func _zone_scene_for(zone_id: StringName) -> PackedScene:
	var zone_scene := world_graph.get_zone_scene(zone_id) if world_graph != null else null
	if zone_scene == null and current_room != null and not current_room.scene_file_path.is_empty():
		zone_scene = load(current_room.scene_file_path) as PackedScene
	return zone_scene
