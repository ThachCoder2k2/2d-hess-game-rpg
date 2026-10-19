class_name ControlPrompts
extends HudWidget

## The one line of control hints in the bottom strip (docs/game-base-plan.md 9.4: "the control hints are generated from the
## InputMap, never hard-coded"), which replaces the static help text the HUD had. For each hint it shows the glyph of the
## action for the device the player used last (the owner's Kenney picture when the file is there, "[Space]" or "[A]" when it
## is not, see InputGlyphs) and what it does. It follows the hand: the keyboard's keys until a pad is touched, the pad's
## buttons after; and the language: the words are text keys. It is not the Controls panel, which lists every action: this is
## the few the player needs in a fight.
##
## It reads no snapshot. GameHud hands it the glyph finder and the tracker of the last input device (AppRoot owns both);
## a HUD run alone builds a finder of its own and shows the keyboard.

## The hints, in order. Each: "actions" (InputMap actions whose first glyph on the device is shown, in order), "words_key"
## (the text key of what they do), and, optionally, "gamepad_glyph_limit" (a pad shows only this many glyphs: four stick
## directions would be four glyphs for one hint).
const PROMPTS: Array[Dictionary] = [
	{"actions": [&"move_up", &"move_left", &"move_down", &"move_right"], "words_key": "UI_HUD_PROMPT_MOVE", "gamepad_glyph_limit": 1},
	{"actions": [&"attack"], "words_key": "UI_HUD_PROMPT_SWORD"},
	{"actions": [&"skill_slot_1"], "words_key": "UI_HUD_PROMPT_THRUST"},
	{"actions": [&"pause"], "words_key": "UI_HUD_PROMPT_PAUSE"},
]
## The size of the words of the hints: the HUD's own small text.
const FONT_SIZE := 8
## The space between a glyph and its words. (The space between two hints is the row's, set in the scene.)
const SPACE_WITHIN_A_HINT := 3

@onready var row: HBoxContainer = $Row

var _glyphs: InputGlyphs = null
var _last_input_device: LastInputDevice = null
## Keeps the words in the player's language and rebuilds the hints after a language change (the words of a key without a
## picture change too). Made in _ready.
var _live_text := LiveText.new()
var _words_label_by_hint: Array[Label] = []


func _ready() -> void:
	add_child(_live_text)
	_live_text.on_language_change(rebuild)
	if _glyphs == null:
		configure(InputGlyphs.new(), null)


## Says where the glyphs come from and whose hand is on the controls. `device_tracker` may be null (the keyboard's glyphs).
func configure(glyph_source: InputGlyphs, device_tracker: LastInputDevice) -> void:
	_glyphs = glyph_source
	if _last_input_device != null and _last_input_device.changed.is_connected(_on_device_changed):
		_last_input_device.changed.disconnect(_on_device_changed)
	_last_input_device = device_tracker
	if _last_input_device != null:
		_last_input_device.changed.connect(_on_device_changed)
	rebuild()


## Draws every hint again for the device in use.
func rebuild() -> void:
	if row == null or _glyphs == null:
		return
	for old_hint in row.get_children():
		row.remove_child(old_hint)
		old_hint.queue_free()
	_words_label_by_hint.clear()
	var device := device_on_show()
	for prompt in PROMPTS:
		var hint := HBoxContainer.new()
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hint.add_theme_constant_override(&"separation", SPACE_WITHIN_A_HINT)
		var strip := GlyphStrip.new()
		strip.words_font_size = FONT_SIZE
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.show_glyphs(_glyphs_of(prompt, device))
		hint.add_child(strip)
		var words := Label.new()
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		words.add_theme_font_size_override(&"font_size", FONT_SIZE)
		_live_text.set_text(words, String(prompt["words_key"]))
		hint.add_child(words)
		row.add_child(hint)
		_words_label_by_hint.append(words)


## The device whose glyphs are on show: the last one the player used, the keyboard when nothing tracks it.
func device_on_show() -> int:
	return _last_input_device.device if _last_input_device != null else InputGlyphs.Device.KEYBOARD


## The words of each hint, in order (a test reads what the player reads).
func hint_words() -> PackedStringArray:
	var words := PackedStringArray()
	for label in _words_label_by_hint:
		words.append(label.text)
	return words


## The glyph strip of the hint at `index` (a test counts its pictures and reads its words).
func strip_of_hint(index: int) -> GlyphStrip:
	return row.get_child(index).get_child(0) as GlyphStrip


## How many hints are on show.
func hint_count() -> int:
	return row.get_child_count() if row != null else 0


## The first glyph of each action of `prompt` on `device`, cut to the pad's limit for a pad.
func _glyphs_of(prompt: Dictionary, device: int) -> Array[InputGlyph]:
	var picked: Array[InputGlyph] = []
	for action: StringName in prompt["actions"]:
		var action_glyphs := _glyphs.glyphs_of_action(action, device)
		if not action_glyphs.is_empty():
			picked.append(action_glyphs[0])
	if device == InputGlyphs.Device.GAMEPAD and prompt.has("gamepad_glyph_limit"):
		picked = picked.slice(0, int(prompt["gamepad_glyph_limit"]))
	return picked


func _on_device_changed(_device: int) -> void:
	rebuild()
