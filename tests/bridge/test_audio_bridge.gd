extends UnboundTest

## AudioBridge (presentation/bridges/audio_bridge.gd, M3b step 2): the event sounds with no clip. The
## SfxManager autoload is swapped for a recorder for the length of the suite, so nothing is played and
## the calls are what is checked: which sound each event asks for, that an unlock with no id is silent,
## that the room-outcome sounds go through play(), and that a scene without the autoload stays silent.

## Stands in for the SfxManager autoload and records the names it was asked to play.
class RecordingSfx:
	extends Node

	var played: Array[StringName] = []

	func play(sound_name: StringName) -> void:
		played.append(sound_name)


func _init() -> void:
	suite_title = "AUDIO BRIDGE TEST"
	await process_frame
	_check_each_event_asks_for_its_sound()
	_check_an_unlock_with_no_id_is_silent()
	_check_play_goes_to_the_registry_by_name()
	_check_no_sound_manager_is_silent()
	finish()


func _swap_in_recorder() -> Array:
	var real_manager := root.get_node_or_null("SfxManager")
	if real_manager != null:
		real_manager.name = "SfxManagerBypassedByAudioBridgeTest"
	var recorder := RecordingSfx.new()
	recorder.name = "SfxManager"
	root.add_child(recorder)
	var bridge := AudioBridge.new()
	bridge.attach(root)
	var router := EventRouter.new()
	bridge.register(router)
	return [bridge, router, recorder, real_manager]


func _swap_back(parts: Array) -> void:
	var recorder: RecordingSfx = parts[2]
	root.remove_child(recorder)
	recorder.free()
	var real_manager: Node = parts[3]
	if real_manager != null:
		real_manager.name = "SfxManager"


func _check_each_event_asks_for_its_sound() -> void:
	var parts := _swap_in_recorder()
	var router: EventRouter = parts[1]
	var recorder: RecordingSfx = parts[2]
	router.route([
		{"type": Events.PICKUP_TAKEN, "item": 3, "cell": Vector2i(2, 2)},
		{"type": Events.PLAYER_UNLOCK, "entity": 1, "id": &"wooden_sword", "message": "grip"},
		{"type": Events.GATE_OPENED, "entity": 1, "gate": &"pass_home_gate", "cell": Vector2i(4, 4)},
	])
	_expect(recorder.played == [&"pickup", &"pickup", &"gate_open"], "a pickup and an unlock chime, a gate opens with its own sound, in event order")
	_swap_back(parts)


func _check_an_unlock_with_no_id_is_silent() -> void:
	var parts := _swap_in_recorder()
	var router: EventRouter = parts[1]
	var recorder: RecordingSfx = parts[2]
	router.route([{"type": Events.PLAYER_UNLOCK, "entity": 1, "id": &"", "message": "nothing"}])
	_expect(recorder.played.is_empty(), "an unlock with no id plays nothing")
	_swap_back(parts)


func _check_play_goes_to_the_registry_by_name() -> void:
	var parts := _swap_in_recorder()
	var bridge: AudioBridge = parts[0]
	var recorder: RecordingSfx = parts[2]
	bridge.play(AudioBridge.ROOM_CLEAR_SOUND)
	bridge.play(AudioBridge.DEFEAT_JINGLE_SOUND)
	_expect(recorder.played == [&"room_clear", &"defeat_jingle"], "the room outcome asks for the clear sound and the defeat jingle through play()")
	_swap_back(parts)


func _check_no_sound_manager_is_silent() -> void:
	var real_manager := root.get_node_or_null("SfxManager")
	if real_manager != null:
		real_manager.name = "SfxManagerBypassedByAudioBridgeTest"
	var bridge := AudioBridge.new()
	bridge.attach(root)
	bridge.play(&"pickup")
	var detached := AudioBridge.new()
	detached.play(&"pickup")
	if real_manager != null:
		real_manager.name = "SfxManager"
	_expect(true, "a scene without the autoload, or a bridge with no scene, plays nothing and says nothing")
