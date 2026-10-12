extends SceneTree

## The audio bus contract (docs/game-base-plan.md section 11 and M1a item 5).
##
## default_bus_layout.tres once named bus 0 "SFX" and had no Master entry, so
## Godot renamed index 0 to Master and the SFX bus did not exist at runtime:
## get_bus_index(&"SFX") was -1, and every AudioStreamPlayer that asked for
## "SFX" silently fell back to Master. This test pins the fixed layout (Master
## first, then SFX / Music / UI / Voice, each sending to Master) and proves
## that no player in a scene names a bus the AudioServer does not have.
##
## Players are read from each PackedScene's SceneState, so nothing is added to
## the tree and no sound plays. Run: godot --headless --path . -s tests/audio/test_audio_buses.gd

## Every bus the project mixes through. Master is the root, the rest feed it.
const REQUIRED_BUS_NAMES: Array[StringName] = [&"Master", &"SFX", &"Music", &"UI", &"Voice"]
const ROOT_BUS_NAME := &"Master"
const ROOT_BUS_INDEX := 0

## Folders whose scenes can hold audio players: scenes/ (entry, rooms, ui) and
## objects/ (reusable prefabs, including every actor). Scanned recursively so
## a new actor or room is covered without touching this test.
const SCENE_FOLDERS: Array[String] = ["res://objects", "res://scenes"]
const SFX_MANAGER_SCENE_PATH := "res://objects/audio/sfx_manager.tscn"
const BUS_LAYOUT_SETTING := "audio/buses/default_bus_layout"

## The scenes known today hold five actor AudioPlayers and main's MusicPlayer.
## Finding fewer means the scan went blind (a moved folder), not that audio is gone.
const MIN_AUDIO_PLAYERS_EXPECTED := 6
const MIN_ACTOR_SCENES_EXPECTED := 5
const ACTOR_SCENE_FOLDER := "res://objects/actors"
const MAIN_SCENE_PATH := "res://scenes/main.tscn"

## Matches the 30 s watchdog every UnboundTest suite gets (plan section 13.7).
const WATCHDOG_SECONDS := 30.0

## Node types that play audio and therefore carry a `bus` property.
const AUDIO_PLAYER_TYPES: Array[StringName] = [&"AudioStreamPlayer", &"AudioStreamPlayer2D", &"AudioStreamPlayer3D"]
## What an audio player routes to when its scene never sets `bus`.
const ENGINE_DEFAULT_PLAYER_BUS := &"Master"

var failures := 0


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)


## A script error in _init would otherwise hang the process forever and a gate
## would never finish; the watchdog turns a hang into a loud failure.
func _arm_watchdog() -> void:
	create_timer(WATCHDOG_SECONDS).timeout.connect(func() -> void:
		printerr("FAIL: audio bus test exceeded its %d s watchdog" % int(WATCHDOG_SECONDS))
		quit(1))


## Appends the res:// path of every .tscn under folder_path, recursively.
func _collect_scene_paths(folder_path: String, scene_paths: Array[String]) -> void:
	var folder := DirAccess.open(folder_path)
	if folder == null:
		return
	for subfolder_name in folder.get_directories():
		_collect_scene_paths(folder_path.path_join(subfolder_name), scene_paths)
	for file_name in folder.get_files():
		if file_name.ends_with(".tscn"):
			scene_paths.append(folder_path.path_join(file_name))


## One entry per audio player the scene itself declares: {"node_name", "bus"}.
## A node counts when it is an audio player type or overrides a `bus` property
## (an inheriting scene reports its overridden nodes with no type). A player
## that never sets `bus` plays on the engine default, Master.
func _audio_players_declared_in(scene: PackedScene) -> Array[Dictionary]:
	var players: Array[Dictionary] = []
	var scene_state := scene.get_state()
	for node_index in scene_state.get_node_count():
		var declared_bus := ENGINE_DEFAULT_PLAYER_BUS
		var declares_bus_property := false
		for property_index in scene_state.get_node_property_count(node_index):
			if scene_state.get_node_property_name(node_index, property_index) == &"bus":
				declared_bus = StringName(scene_state.get_node_property_value(node_index, property_index))
				declares_bus_property = true
		var is_audio_player := scene_state.get_node_type(node_index) in AUDIO_PLAYER_TYPES
		if is_audio_player or declares_bus_property:
			players.append({"node_name": scene_state.get_node_name(node_index), "bus": declared_bus})
	return players


func _init() -> void:
	_arm_watchdog()

	# --- The layout file the project points at is really there ---
	var layout_path := String(ProjectSettings.get_setting(BUS_LAYOUT_SETTING, ""))
	_expect(not layout_path.is_empty() and FileAccess.file_exists(layout_path), "project.godot points at a bus layout file that exists (%s)" % layout_path)

	# --- Every bus exists, Master leads, the rest feed Master ---
	for bus_name in REQUIRED_BUS_NAMES:
		_expect(AudioServer.get_bus_index(bus_name) != -1, "audio bus '%s' exists at runtime" % bus_name)
	_expect(AudioServer.get_bus_index(ROOT_BUS_NAME) == ROOT_BUS_INDEX, "Master is bus index 0")
	for bus_name in REQUIRED_BUS_NAMES:
		if bus_name == ROOT_BUS_NAME:
			continue
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index == -1:
			_expect(false, "audio bus '%s' sends to Master (bus is missing)" % bus_name)
			continue
		_expect(AudioServer.get_bus_send(bus_index) == ROOT_BUS_NAME, "audio bus '%s' sends to Master" % bus_name)

	# --- Every audio player in the scenes names a bus that exists ---
	var scene_paths: Array[String] = []
	for folder_path in SCENE_FOLDERS:
		_collect_scene_paths(folder_path, scene_paths)
	scene_paths.sort()
	var actor_scene_count := 0
	var audio_player_count := 0
	var main_scene_scanned := false
	for scene_path in scene_paths:
		var scene := load(scene_path) as PackedScene
		if scene == null:
			_expect(false, "scene loads for the audio bus scan (%s)" % scene_path)
			continue
		if scene_path.begins_with(ACTOR_SCENE_FOLDER + "/"):
			actor_scene_count += 1
		if scene_path == MAIN_SCENE_PATH:
			main_scene_scanned = true
		for player in _audio_players_declared_in(scene):
			audio_player_count += 1
			var player_bus: StringName = player["bus"]
			_expect(AudioServer.get_bus_index(player_bus) != -1, "%s '%s' plays on existing bus '%s'" % [scene_path, player["node_name"], player_bus])
	_expect(actor_scene_count >= MIN_ACTOR_SCENES_EXPECTED, "the bus scan covered the actor scenes (%d found, at least %d expected)" % [actor_scene_count, MIN_ACTOR_SCENES_EXPECTED])
	_expect(main_scene_scanned, "the bus scan covered %s" % MAIN_SCENE_PATH)
	_expect(audio_player_count >= MIN_AUDIO_PLAYERS_EXPECTED, "the bus scan found the audio players (%d found, at least %d expected)" % [audio_player_count, MIN_AUDIO_PLAYERS_EXPECTED])

	# --- SfxManager builds its player pool in code, so check the pool's bus too ---
	var sfx_manager_scene := load(SFX_MANAGER_SCENE_PATH) as PackedScene
	_expect(sfx_manager_scene != null, "the SfxManager scene loads (%s)" % SFX_MANAGER_SCENE_PATH)
	if sfx_manager_scene != null:
		var sfx_manager := sfx_manager_scene.instantiate()  # never added to the tree: _ready does not run
		var pool_bus := StringName(sfx_manager.get(&"bus"))
		_expect(AudioServer.get_bus_index(pool_bus) != -1, "SfxManager pools its players on existing bus '%s'" % pool_bus)
		sfx_manager.free()

	var succeeded := failures == 0
	print("AUDIO BUS TEST: %s" % ["PASS" if succeeded else "FAIL (%d)" % failures])
	quit(0 if succeeded else 1)
