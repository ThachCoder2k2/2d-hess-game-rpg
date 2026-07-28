extends Node

## Layer 3 of the sound structure (see CLAUDE.md): pooled one-shot playback
## for EVENT sounds that belong to no animation clip (pickups, room clear,
## jingles, UI). The registry is editor-owned — add sounds in the Inspector of
## objects/audio/sfx_manager.tscn, never in code. Only the main.gd bridge
## calls play(); systems never touch audio. Pooling means rapid sounds never
## cut each other off and never die with a freed node.

## sound name -> stream. The editor-facing registry.
@export var streams: Dictionary[StringName, AudioStream] = {}
@export_range(1, 16) var pool_size := 8
@export var bus: StringName = &"SFX"

var _idle_players: Array[AudioStreamPlayer] = []
var _queued_streams: Array[AudioStream] = []


func _ready() -> void:
	for _i in pool_size:
		var player := AudioStreamPlayer.new()
		player.bus = bus
		add_child(player)
		player.finished.connect(_on_player_finished.bind(player))
		_idle_players.append(player)


func play(sound_name: StringName) -> void:
	var stream: AudioStream = streams.get(sound_name)
	if stream == null:
		push_warning("SfxManager has no stream named '%s' — add it in the Inspector." % sound_name)
		return
	_play_stream(stream)


func _play_stream(stream: AudioStream) -> void:
	if _idle_players.is_empty():
		_queued_streams.append(stream)
		return
	var player: AudioStreamPlayer = _idle_players.pop_back()
	player.stream = stream
	player.play()


func _on_player_finished(player: AudioStreamPlayer) -> void:
	_idle_players.append(player)
	if not _queued_streams.is_empty():
		_play_stream(_queued_streams.pop_front())
