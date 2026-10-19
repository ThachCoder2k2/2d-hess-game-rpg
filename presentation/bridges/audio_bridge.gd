class_name AudioBridge
extends EventBridge

## The sound responsibility: the event sounds that belong to no animation clip (layer 3 of the sound
## structure, CLAUDE.md). Motion sounds are tracks inside the actors' clips and need no bridge; the
## sounds here are the pickup chime and the gate, plus the jingles of a cleared room and a fallen
## pawn, which the room outcome asks for with play(). The streams live in the SfxManager autoload's
## Inspector registry (presentation/audio/sfx_manager.tscn); this bridge only names the sound.
## Systems never play audio, and nothing but this bridge calls the SfxManager.
## Reads: events. Writes: the SfxManager. Decides: nothing.

## The registry key of the chime for a floor weapon taken and for a verb unlocked.
const PICKUP_SOUND := &"pickup"
## The registry key of a shortcut gate unbarring.
const GATE_OPEN_SOUND := &"gate_open"
## The registry key of a room cleared.
const ROOM_CLEAR_SOUND := &"room_clear"
## The registry key of the pawn falling.
const DEFEAT_JINGLE_SOUND := &"defeat_jingle"
## Where the SfxManager autoload lives in the tree.
const SFX_MANAGER_PATH := "/root/SfxManager"

## Any node in the tree: the bridge is a RefCounted and finds the autoload through it.
var tree_anchor: Node


func attach(anchor: Node) -> void:
	tree_anchor = anchor


func register(router: EventRouter) -> void:
	router.on(Events.PICKUP_TAKEN, _on_pickup_taken)
	router.on(Events.PLAYER_UNLOCK, _on_player_unlock)
	router.on(Events.GATE_OPENED, _on_gate_opened)


## Plays the registry sound `sound_name`. Looked up by path on every call so a headless test without
## autoloads stays silent instead of crashing.
func play(sound_name: StringName) -> void:
	if tree_anchor == null:
		return
	var sfx := tree_anchor.get_node_or_null(SFX_MANAGER_PATH)
	if sfx != null:
		sfx.call("play", sound_name)


func _on_pickup_taken(_event: Dictionary) -> void:
	play(PICKUP_SOUND)


## An unlock with no id is ignored altogether, here as in the save and the status line.
func _on_player_unlock(event: Dictionary) -> void:
	if StringName(event.get("id", &"")) != &"":
		play(PICKUP_SOUND)


func _on_gate_opened(_event: Dictionary) -> void:
	play(GATE_OPEN_SOUND)
