class_name LastInputDevice
extends Node

## Which device the player used last, so a prompt can show the glyph set that matches the hand on the controls
## (docs/game-base-plan.md 9.4: "chosen by the last input device (hot-swap)"). It listens to the events the engine
## delivers (`_input`), which is not the Input singleton, so the InputPoller stays the only reader of that. A key press
## says KEYBOARD; a pad button press, or a stick or trigger pushed past STICK_NOTICE_THRESHOLD, says GAMEPAD. A resting
## stick that drifts, a mouse move and a touch say nothing, so a prompt never flips because of noise.
##
## AppRoot owns one (the app outlives every screen). It keeps processing while the tree is paused, so the prompts of
## the pause menu follow the hand too. A prompt reads `device` and listens to `changed`.

## The device changed. `device` is an InputGlyphs.Device.
signal changed(device: int)

## How far a stick or trigger must be pushed before it counts as the player using the pad. Drift stays below it.
const STICK_NOTICE_THRESHOLD := 0.5

## The device used last: an InputGlyphs.Device. The keyboard until a pad is touched.
var device: int = InputGlyphs.Device.KEYBOARD


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Takes note of one event (the engine's `_input` calls it; a test calls it with an event it built).
func note_event(event: InputEvent) -> void:
	var seen := InputGlyphs.device_of(event)
	if seen == InputGlyphs.NO_DEVICE:
		return
	if event is InputEventKey and not (event as InputEventKey).pressed:
		return
	if event is InputEventJoypadButton and not (event as InputEventJoypadButton).pressed:
		return
	if event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) < STICK_NOTICE_THRESHOLD:
		return
	if seen != device:
		device = seen
		changed.emit(device)


func _input(event: InputEvent) -> void:
	note_event(event)
