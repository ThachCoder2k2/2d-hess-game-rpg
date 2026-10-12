extends UnboundTest

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

## Scenes are scanned in scenes/ (entry, rooms, ui) and objects/ (reusable
## prefabs, including every actor), recursively, so a new actor or room is
## covered without touching this test. Where those folders are is TestPaths' job.
const BUS_LAYOUT_SETTING := "audio/buses/default_bus_layout"

## The scenes known today hold five actor AudioPlayers and main's MusicPlayer.
## Finding fewer means the scan went blind (a moved folder), not that audio is gone.
const MIN_AUDIO_PLAYERS_EXPECTED := 6
const MIN_ACTOR_SCENES_EXPECTED := 5

## Node types that play audio and therefore carry a `bus` property.
const AUDIO_PLAYER_TYPES: Array[StringName] = [&"AudioStreamPlayer", &"AudioStreamPlayer2D", &"AudioStreamPlayer3D"]
## What an audio player routes to when its scene never sets `bus`.
const ENGINE_DEFAULT_PLAYER_BUS := &"Master"


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
	suite_title = "AUDIO BUS TEST"
	var paths := TestPaths.new(self)

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
	for folder_path in [paths.objects_directory(), paths.scenes_directory()]:
		for scene_path in paths.list_files(folder_path, "tscn", 1, true):
			scene_paths.append(scene_path)
	scene_paths.sort()
	var actor_folder_prefix := paths.actors_directory() + "/"
	var main_scene_path := paths.main_scene()
	var actor_scene_count := 0
	var audio_player_count := 0
	var main_scene_scanned := false
	for scene_path in scene_paths:
		var scene := paths.load_scene(scene_path)
		if scene == null:
			continue  # TestPaths already failed the suite and named the scene
		if scene_path.begins_with(actor_folder_prefix):
			actor_scene_count += 1
		if scene_path == main_scene_path:
			main_scene_scanned = true
		for player in _audio_players_declared_in(scene):
			audio_player_count += 1
			var player_bus: StringName = player["bus"]
			_expect(AudioServer.get_bus_index(player_bus) != -1, "%s '%s' plays on existing bus '%s'" % [scene_path, player["node_name"], player_bus])
	_expect(actor_scene_count >= MIN_ACTOR_SCENES_EXPECTED, "the bus scan covered the actor scenes (%d found, at least %d expected)" % [actor_scene_count, MIN_ACTOR_SCENES_EXPECTED])
	_expect(main_scene_scanned, "the bus scan covered %s" % main_scene_path)
	_expect(audio_player_count >= MIN_AUDIO_PLAYERS_EXPECTED, "the bus scan found the audio players (%d found, at least %d expected)" % [audio_player_count, MIN_AUDIO_PLAYERS_EXPECTED])

	# --- SfxManager builds its player pool in code, so check the pool's bus too ---
	var sfx_manager_scene_path := paths.sfx_manager_scene()
	var sfx_manager_scene := paths.load_scene(sfx_manager_scene_path)
	_expect(sfx_manager_scene != null, "the SfxManager scene loads (%s)" % sfx_manager_scene_path)
	if sfx_manager_scene != null:
		var sfx_manager := sfx_manager_scene.instantiate()  # never added to the tree: _ready does not run
		var pool_bus := StringName(sfx_manager.get(&"bus"))
		_expect(AudioServer.get_bus_index(pool_bus) != -1, "SfxManager pools its players on existing bus '%s'" % pool_bus)
		sfx_manager.free()

	finish()
