class_name ActionPrompt
extends HBoxContainer

## One control hint, generated from the InputMap: the glyph of an action for the device the player used last, then
## what it does ("[Esc] Back", or the pad's B). It is the prompt the plan describes in 9.4: never typed by hand, and
## it follows the hand: when LastInputDevice says the player picked up the pad it shows the pad's glyph, when the
## keyboard is touched again it shows the key, and when the language changes the words follow.
##
##     prompt.bind(&"ui_cancel", "UI_CONTROLS_BACK", glyphs, last_input_device)
##
## An action the device has no binding for shows the empty cell (GlyphStrip).

## The action the prompt shows.
var action: StringName = &""
## The text key of what the action does.
var label_key := ""

var _glyphs: InputGlyphs = null
var _last_input_device: LastInputDevice = null
var _strip := GlyphStrip.new()
var _words := Label.new()
var _live_text := LiveText.new()


func _init() -> void:
	add_theme_constant_override("separation", 4)
	_words.add_theme_font_size_override(&"font_size", GlyphStrip.WORDS_FONT_SIZE)
	add_child(_strip)
	add_child(_words)
	add_child(_live_text)
	_live_text.on_language_change(refresh)


## Shows `action_name` with the words of `words_key`, choosing the glyph set by `last_input_device` (which may be null:
## the keyboard's set). `glyph_source` finds the pictures and is shared with the other prompts of the screen.
func bind(action_name: StringName, words_key: String, glyph_source: InputGlyphs, last_input_device: LastInputDevice) -> void:
	action = action_name
	label_key = words_key
	_glyphs = glyph_source
	if _last_input_device != null and _last_input_device.changed.is_connected(_on_device_changed):
		_last_input_device.changed.disconnect(_on_device_changed)
	_last_input_device = last_input_device
	if _last_input_device != null:
		_last_input_device.changed.connect(_on_device_changed)
	_live_text.set_text(_words, words_key)
	refresh()


## The device whose glyphs the prompt shows now.
func device_on_show() -> int:
	return _last_input_device.device if _last_input_device != null else InputGlyphs.Device.KEYBOARD


## Shows the first control of the action on the device in use. An action with a second control (Space and K) shows
## the first only: a prompt is a hint, the Controls panel lists them all.
func refresh() -> void:
	if _glyphs == null:
		return
	var glyphs := _glyphs.glyphs_of_action(action, device_on_show())
	var first_only: Array[InputGlyph] = []
	if not glyphs.is_empty():
		first_only.append(glyphs[0])
	_strip.show_glyphs(first_only)


## The strip, for a test to read what is on show.
func strip() -> GlyphStrip:
	return _strip


func _on_device_changed(_device: int) -> void:
	refresh()
