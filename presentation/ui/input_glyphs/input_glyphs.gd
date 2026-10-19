class_name InputGlyphs
extends RefCounted

## The glyph lookup (docs/game-base-plan.md 9.4: "control hints are generated from the InputMap, never hard-coded; two
## glyph sets ship, keyboard and generic gamepad, chosen by the last input device"). Given an InputMap action and a
## device it answers with the glyph of every event the action has on that device, one InputGlyph each: the picture the
## owner put at the path the asset list gives (group `glyphs_kenney`, folder `assets/ui/glyphs`, files such as
## `keyboard/key_w.png` and `gamepad/btn_a.png`) and, always, the words for the control. NOTHING IS DOWNLOADED: the owner
## copies Kenney's CC0 pack 'Input Prompts Pixel' to those paths later (docs/assets/README.md); until a file is there a
## prompt reads "[Space]" or "[A]" instead of a picture, and dropping the file in swaps it, with no other change.
##
## Which file belongs to which control is the tables below. They name only files that the asset list names
## (tests/input/test_input_glyphs.gd reads the list and fails on a name it does not know), so a path here is a path
## the owner was asked to fill. A control with no entry (a key the asset list has no file for) gets no picture and the
## words the engine gives the key.
##
## The device is the CALLER's choice: the Controls panel shows both, a prompt asks LastInputDevice which one the
## player used last.

enum Device {
	KEYBOARD,
	GAMEPAD,
}

## The folder the glyph files live in: the `folder` of the asset list's glyphs_kenney group.
const GLYPH_FOLDER := "res://assets/ui/glyphs"
const KEYBOARD_SUBFOLDER := "keyboard"
const GAMEPAD_SUBFOLDER := "gamepad"
const FILE_EXTENSION := "png"
## The text key of the brackets around the words of a control that has no picture: "[{name}]".
const FALLBACK_FORMAT_KEY := "PROMPT_GLYPH_FALLBACK"
## The device value of an event that is neither a key nor a pad control.
const NO_DEVICE := -1

## keycode -> the file name (no folder, no extension) of the keyboard glyph. A key not here has no picture.
const KEYBOARD_FILE_BY_KEYCODE := {
	KEY_W: "key_w", KEY_A: "key_a", KEY_S: "key_s", KEY_D: "key_d",
	KEY_Q: "key_q", KEY_F: "key_f", KEY_G: "key_g", KEY_R: "key_r", KEY_E: "key_e", KEY_B: "key_b",
	KEY_K: "key_k", KEY_C: "key_c", KEY_V: "key_v",
	KEY_UP: "key_arrow_up", KEY_DOWN: "key_arrow_down", KEY_LEFT: "key_arrow_left", KEY_RIGHT: "key_arrow_right",
	KEY_TAB: "key_tab", KEY_CTRL: "key_ctrl", KEY_ALT: "key_alt", KEY_ESCAPE: "key_esc", KEY_F3: "key_f3",
	KEY_F11: "key_f11", KEY_SHIFT: "key_shift", KEY_ENTER: "key_enter", KEY_SPACE: "key_space",
}

## keycode -> the text key of the key's name. A key not here is named by the engine (a letter, an F key, a digit).
const KEY_NAME_KEY_BY_KEYCODE := {
	KEY_SPACE: "PROMPT_KEY_SPACE", KEY_ENTER: "PROMPT_KEY_ENTER", KEY_KP_ENTER: "PROMPT_KEY_ENTER",
	KEY_TAB: "PROMPT_KEY_TAB", KEY_SHIFT: "PROMPT_KEY_SHIFT", KEY_CTRL: "PROMPT_KEY_CTRL",
	KEY_ALT: "PROMPT_KEY_ALT", KEY_ESCAPE: "PROMPT_KEY_ESC",
	KEY_UP: "PROMPT_KEY_UP", KEY_DOWN: "PROMPT_KEY_DOWN", KEY_LEFT: "PROMPT_KEY_LEFT", KEY_RIGHT: "PROMPT_KEY_RIGHT",
}

## JoyButton -> the file name of the gamepad glyph (the pack's Xbox-style set, which the asset list uses as it is).
const GAMEPAD_FILE_BY_BUTTON := {
	JOY_BUTTON_A: "btn_a", JOY_BUTTON_B: "btn_b", JOY_BUTTON_X: "btn_x", JOY_BUTTON_Y: "btn_y",
	JOY_BUTTON_LEFT_SHOULDER: "btn_lb", JOY_BUTTON_RIGHT_SHOULDER: "btn_rb",
	JOY_BUTTON_LEFT_STICK: "btn_l3", JOY_BUTTON_RIGHT_STICK: "btn_r3",
	JOY_BUTTON_START: "btn_start", JOY_BUTTON_BACK: "btn_back",
	JOY_BUTTON_DPAD_UP: "dpad_up", JOY_BUTTON_DPAD_DOWN: "dpad_down",
	JOY_BUTTON_DPAD_LEFT: "dpad_left", JOY_BUTTON_DPAD_RIGHT: "dpad_right",
}

## JoyButton -> how a person says the button. A letter or an abbreviation is the same in every language (A, LB, L3);
## a text key (PROMPT_...) is a word.
const GAMEPAD_NAME_BY_BUTTON := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_START: "PROMPT_PAD_START", JOY_BUTTON_BACK: "PROMPT_PAD_BACK",
	JOY_BUTTON_DPAD_UP: "PROMPT_PAD_DPAD_UP", JOY_BUTTON_DPAD_DOWN: "PROMPT_PAD_DPAD_DOWN",
	JOY_BUTTON_DPAD_LEFT: "PROMPT_PAD_DPAD_LEFT", JOY_BUTTON_DPAD_RIGHT: "PROMPT_PAD_DPAD_RIGHT",
}

## "<axis>:<sign>" -> the text key of a stick direction, for the words of a control that has no picture. The Y axis is
## negative upwards, so "1:-1" is the left stick pushed up.
const AXIS_NAME_KEY_BY_DIRECTION := {
	"0:-1": "PROMPT_PAD_LEFT_STICK_LEFT", "0:1": "PROMPT_PAD_LEFT_STICK_RIGHT",
	"1:-1": "PROMPT_PAD_LEFT_STICK_UP", "1:1": "PROMPT_PAD_LEFT_STICK_DOWN",
	"2:-1": "PROMPT_PAD_RIGHT_STICK", "2:1": "PROMPT_PAD_RIGHT_STICK",
	"3:-1": "PROMPT_PAD_RIGHT_STICK", "3:1": "PROMPT_PAD_RIGHT_STICK",
}
## "<axis>:<sign>" -> the file name of the gamepad glyph of a stick direction. The two triggers are buttons for a
## player (LT, RT) and are handled before this table.
const GAMEPAD_FILE_BY_AXIS_DIRECTION := {
	"0:-1": "stick_left_left", "0:1": "stick_left_right",
	"1:-1": "stick_left_up", "1:1": "stick_left_down",
	"2:-1": "stick_right_neutral", "2:1": "stick_right_neutral",
	"3:-1": "stick_right_neutral", "3:1": "stick_right_neutral",
}
## The file names of the two triggers.
const TRIGGER_FILES: Array[String] = ["btn_lt", "btn_rt"]

## The folder the files are read from. Another folder in a test.
var glyph_folder := GLYPH_FOLDER

## file path -> the Texture2D read from it, or null for a path with no file. Kept so a prompt redrawn every frame does
## not read the disk every frame; forget_pictures() empties it (the owner added a file while the game ran).
var _texture_by_path: Dictionary = {}


func _init(folder := GLYPH_FOLDER) -> void:
	glyph_folder = folder


## The device an event came from (a Device), or NO_DEVICE for an event that is neither a key nor a pad (the mouse).
static func device_of(event: InputEvent) -> int:
	if event is InputEventKey:
		return Device.KEYBOARD
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return Device.GAMEPAD
	return NO_DEVICE


## One glyph for each event `action` has on `device`, in the order the InputMap lists them. Empty for an action the
## InputMap does not have, or one with no event on that device.
func glyphs_of_action(action: StringName, device: int) -> Array[InputGlyph]:
	var glyphs: Array[InputGlyph] = []
	if not InputMap.has_action(action):
		return glyphs
	for event in InputMap.action_get_events(action):
		if device_of(event) == device:
			glyphs.append(glyph_of_event(event))
	return glyphs


## The glyph of one event, null for an event that is neither a key nor a pad control.
func glyph_of_event(event: InputEvent) -> InputGlyph:
	var stem := ""
	var control_name := ""
	var subfolder := ""
	if event is InputEventKey:
		var keycode := _keycode_of(event as InputEventKey)
		stem = String(KEYBOARD_FILE_BY_KEYCODE.get(keycode, ""))
		control_name = _key_name(keycode)
		subfolder = KEYBOARD_SUBFOLDER
	elif event is InputEventJoypadButton:
		var button := (event as InputEventJoypadButton).button_index
		stem = String(GAMEPAD_FILE_BY_BUTTON.get(button, ""))
		control_name = _pad_button_name(button)
		subfolder = GAMEPAD_SUBFOLDER
	elif event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		var direction := "%d:%d" % [motion.axis, signi(roundi(motion.axis_value))]
		stem = _stem_of_axis(motion.axis, direction)
		control_name = _axis_name(motion.axis, direction)
		subfolder = GAMEPAD_SUBFOLDER
	else:
		return null
	var glyph := InputGlyph.new()
	glyph.text = TextService.t(FALLBACK_FORMAT_KEY, {"name": control_name})
	if not stem.is_empty():
		glyph.file_path = glyph_folder.path_join(subfolder).path_join("%s.%s" % [stem, FILE_EXTENSION])
		glyph.texture = texture_at(glyph.file_path)
	return glyph


## The picture at `path`, null when there is no file. An imported file is a resource (its import settings apply); a
## file dropped in while the editor was closed has no import yet and is read directly, so the owner sees it at once.
func texture_at(path: String) -> Texture2D:
	if _texture_by_path.has(path):
		return _texture_by_path[path]
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	elif FileAccess.file_exists(path):
		var image := Image.load_from_file(path)
		if image != null:
			texture = ImageTexture.create_from_image(image)
	_texture_by_path[path] = texture
	return texture


## Forgets the pictures read so far, so a file added since is found.
func forget_pictures() -> void:
	_texture_by_path.clear()


## Every path a glyph can be read from (the files the tables name), for a test and a report. Sorted.
func all_paths() -> PackedStringArray:
	var paths := PackedStringArray()
	for stem: String in KEYBOARD_FILE_BY_KEYCODE.values():
		paths.append(_path_of(KEYBOARD_SUBFOLDER, stem))
	var pad_stems: Array = GAMEPAD_FILE_BY_BUTTON.values() + GAMEPAD_FILE_BY_AXIS_DIRECTION.values() + TRIGGER_FILES
	for stem: String in pad_stems:
		var path := _path_of(GAMEPAD_SUBFOLDER, stem)
		if path not in paths:
			paths.append(path)
	paths.sort()
	return paths


func _path_of(subfolder: String, stem: String) -> String:
	return glyph_folder.path_join(subfolder).path_join("%s.%s" % [stem, FILE_EXTENSION])


## A key event's code. The project binds keys by their position on the keyboard (physical_keycode); the engine's own
## menu actions by the letter (keycode).
func _keycode_of(event: InputEventKey) -> Key:
	return event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode


func _key_name(keycode: Key) -> String:
	var name_key: String = KEY_NAME_KEY_BY_KEYCODE.get(keycode, "")
	return TextService.t(name_key) if not name_key.is_empty() else OS.get_keycode_string(keycode)


func _pad_button_name(button: JoyButton) -> String:
	var named: String = GAMEPAD_NAME_BY_BUTTON.get(button, "")
	if named.is_empty():
		return str(int(button))
	return TextService.t(named) if named.begins_with("PROMPT_") else named


func _stem_of_axis(axis: JoyAxis, direction: String) -> String:
	if axis == JOY_AXIS_TRIGGER_LEFT:
		return TRIGGER_FILES[0]
	if axis == JOY_AXIS_TRIGGER_RIGHT:
		return TRIGGER_FILES[1]
	return String(GAMEPAD_FILE_BY_AXIS_DIRECTION.get(direction, ""))


func _axis_name(axis: JoyAxis, direction: String) -> String:
	if axis == JOY_AXIS_TRIGGER_LEFT:
		return "LT"
	if axis == JOY_AXIS_TRIGGER_RIGHT:
		return "RT"
	var name_key: String = AXIS_NAME_KEY_BY_DIRECTION.get(direction, "")
	return TextService.t(name_key) if not name_key.is_empty() else str(int(axis))
