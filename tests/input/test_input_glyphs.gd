extends UnboundTest

## The glyph lookup (docs/game-base-plan.md 9.4, M4; the owner's rule: the Kenney pack is dropped in by the owner, nothing is
## downloaded). Four things:
##   1. PATHS. Every file the lookup can name is one the asset list asks the owner for (docs/assets/spec/ui_story.json, group
##      `glyphs_kenney`, folder `assets/ui/glyphs`), and every control the InputMap binds has such a file: a key or a pad
##      button the game uses can never be left without a picture slot.
##   2. FALLBACK. With no file there the glyph is words the player can read: "[Space]", "[A]", "[Left Stick Up]".
##   3. PICTURES. With a file there (a 16x16 PNG in a throwaway folder) the glyph is that picture and keeps its words.
##   4. THE DEVICE. LastInputDevice follows the hand (a key, a pad button, a stick pushed past the drift), and an
##      ActionPrompt shows the keyboard's glyph or the pad's accordingly, in the language in use.

const ASSET_LIST_PATH := "res://docs/assets/spec/ui_story.json"
const GLYPH_GROUP_ID := "glyphs_kenney"

var glyphs := InputGlyphs.new()


func _init() -> void:
	suite_title = "INPUT GLYPHS TEST"
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_paths_are_the_asset_lists()
	_every_bound_control_has_a_slot()
	_words_stand_in_for_missing_files()
	_pictures_are_used_when_the_files_are_there()
	await _the_prompt_follows_the_last_device()
	finish()


# --------------------------------------------------------------------------- 1. paths

func _paths_are_the_asset_lists() -> void:
	var group := _asset_list_group()
	if not _expect(not group.is_empty(), "setup: the asset list has the group '%s'" % GLYPH_GROUP_ID):
		return
	_expect(InputGlyphs.GLYPH_FOLDER == "res://" + String(group["folder"]), "the glyph folder is the group's folder (%s)" % group["folder"])
	var listed := {}
	for entry: Dictionary in group["files"]:
		listed[InputGlyphs.GLYPH_FOLDER.path_join(String(entry["name"]))] = true
	var unknown := PackedStringArray()
	for path in glyphs.all_paths():
		if not listed.has(path):
			unknown.append(path)
	_expect(unknown.is_empty(), "every path the lookup names is a file the asset list asks for (unknown: %s)" % ", ".join(unknown))
	_expect(glyphs.all_paths().size() >= 30, "and the lookup names a real number of them (%d)" % glyphs.all_paths().size())


func _every_bound_control_has_a_slot() -> void:
	var without_slot := PackedStringArray()
	var checked := 0
	for action in InputMap.get_actions():
		if String(action).begins_with("ui_"):
			continue
		for event in InputMap.action_get_events(action):
			var glyph := glyphs.glyph_of_event(event)
			checked += 1
			if glyph == null or glyph.file_path.is_empty():
				without_slot.append("%s: %s" % [action, event.as_text()])
	_expect(checked > 30, "setup: the InputMap binds %d controls to look at" % checked)
	_expect(without_slot.is_empty(), "every control the InputMap binds has a glyph file slot (without: %s)" % "; ".join(without_slot))


# --------------------------------------------------------------------------- 2. the words

func _words_stand_in_for_missing_files() -> void:
	var missing := InputGlyphs.new("user://glyphs_that_are_not_there")
	var attack_keys := _words_of(missing.glyphs_of_action(&"attack", InputGlyphs.Device.KEYBOARD))
	_expect(attack_keys == ["[Space]", "[K]"], "with no files the keyboard glyphs of Strike read [Space] and [K] (got %s)" % [attack_keys])
	var attack_pad := _words_of(missing.glyphs_of_action(&"attack", InputGlyphs.Device.GAMEPAD))
	_expect(attack_pad == ["[A]"], "and the pad's read [A] (got %s)" % [attack_pad])
	_expect(_words_of(missing.glyphs_of_action(&"call_child", InputGlyphs.Device.KEYBOARD)) == ["[R]"], "the child's key reads [R]")
	_expect(_words_of(missing.glyphs_of_action(&"call_child", InputGlyphs.Device.GAMEPAD)) == ["[RB]"], "and the child's button [RB]")
	_expect(_words_of(missing.glyphs_of_action(&"guard", InputGlyphs.Device.GAMEPAD)) == ["[LT]"], "a trigger is a button to a player: [LT]")
	_expect(_words_of(missing.glyphs_of_action(&"pause", InputGlyphs.Device.GAMEPAD)) == ["[Start]"], "Start reads [Start]")
	_expect(_words_of(missing.glyphs_of_action(&"pause", InputGlyphs.Device.KEYBOARD)) == ["[Esc]"], "and Escape reads [Esc]")
	_expect(_words_of(missing.glyphs_of_action(&"move_up", InputGlyphs.Device.KEYBOARD)) == ["[W]", "[Up]"], "the move keys read [W] and [Up]")
	_expect(_words_of(missing.glyphs_of_action(&"move_up", InputGlyphs.Device.GAMEPAD)) == ["[Left Stick Up]", "[D-pad Up]"], "the pad's move controls read [Left Stick Up] and [D-pad Up]")
	_expect(_words_of(missing.glyphs_of_action(&"turn_mode", InputGlyphs.Device.KEYBOARD)) == ["[Shift]"], "Shift reads [Shift]")
	_expect(_words_of(missing.glyphs_of_action(&"free_step", InputGlyphs.Device.GAMEPAD)).is_empty(), "an action with no event on a device has no glyph there (Free Step has no pad event)")
	_expect(missing.glyphs_of_action(&"no_such_action", InputGlyphs.Device.KEYBOARD).is_empty(), "an action the InputMap does not have has no glyphs")
	var strike := missing.glyphs_of_action(&"attack", InputGlyphs.Device.KEYBOARD)[0]
	_expect(not strike.has_picture() and strike.file_path == "user://glyphs_that_are_not_there/keyboard/key_space.png", "the glyph still says where the owner's file belongs (%s)" % strike.file_path)
	_expect(glyphs.glyph_of_event(InputEventMouseButton.new()) == null, "a mouse click is not a control the prompts show")
	_expect(InputGlyphs.device_of(InputEventMouseMotion.new()) == InputGlyphs.NO_DEVICE, "and it belongs to no device")


# --------------------------------------------------------------------------- 3. the pictures

func _pictures_are_used_when_the_files_are_there() -> void:
	var folder := "user://glyphs_test_%d" % OS.get_process_id()
	var space_path := folder.path_join("keyboard/key_space.png")
	DirAccess.make_dir_recursive_absolute(space_path.get_base_dir())
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	_expect(image.save_png(space_path) == OK, "setup: a 16x16 picture written where the Space glyph belongs")
	var with_file := InputGlyphs.new(folder)
	var strike_keys := with_file.glyphs_of_action(&"attack", InputGlyphs.Device.KEYBOARD)
	_expect(strike_keys[0].has_picture() and strike_keys[0].texture.get_size() == Vector2(16, 16), "with the file there the Space glyph is that 16x16 picture")
	_expect(strike_keys[0].text == "[Space]", "and it keeps its words")
	_expect(not strike_keys[1].has_picture() and strike_keys[1].text == "[K]", "while a glyph whose file is not there stays words (K)")
	var strip := GlyphStrip.new()
	strip.show_glyphs(strike_keys)
	_expect(strip.picture_count() == 1 and strip.words_on_show() == "[K]", "a strip shows the picture and the words that have none")
	strip.free()
	DirAccess.remove_absolute(space_path)
	DirAccess.remove_absolute(space_path.get_base_dir())
	DirAccess.remove_absolute(folder)
	with_file.forget_pictures()
	_expect(not with_file.glyphs_of_action(&"attack", InputGlyphs.Device.KEYBOARD)[0].has_picture(), "take the file away and, once the finder forgets what it read, the words are back")


# --------------------------------------------------------------------------- 4. the device

func _the_prompt_follows_the_last_device() -> void:
	var tracker := LastInputDevice.new()
	root.add_child(tracker)
	var changes: Array[int] = []
	tracker.changed.connect(func(device: int) -> void: changes.append(device))
	_expect(tracker.device == InputGlyphs.Device.KEYBOARD, "the keyboard's glyphs until a pad is touched")

	tracker.note_event(_pad_button(JOY_BUTTON_A, true))
	_expect(tracker.device == InputGlyphs.Device.GAMEPAD and changes == [InputGlyphs.Device.GAMEPAD], "a pad button press says the pad, once")
	tracker.note_event(_pad_button(JOY_BUTTON_B, true))
	_expect(changes.size() == 1, "a second pad press changes nothing")
	tracker.note_event(_key(KEY_W, false))
	_expect(tracker.device == InputGlyphs.Device.GAMEPAD, "a key RELEASE says nothing (it may be the end of the press before)")
	tracker.note_event(_stick(JOY_AXIS_LEFT_X, 0.2))
	tracker.note_event(InputEventMouseMotion.new())
	_expect(tracker.device == InputGlyphs.Device.GAMEPAD, "a mouse move says nothing")
	tracker.note_event(_key(KEY_W, true))
	_expect(tracker.device == InputGlyphs.Device.KEYBOARD and changes.size() == 2, "a key press says the keyboard")
	tracker.note_event(_stick(JOY_AXIS_LEFT_X, 0.2))
	_expect(tracker.device == InputGlyphs.Device.KEYBOARD, "a stick resting a little off centre (drift) does not take the hand")
	tracker.note_event(_stick(JOY_AXIS_LEFT_X, 0.9))
	_expect(tracker.device == InputGlyphs.Device.GAMEPAD, "a stick pushed hard does")

	var prompt := ActionPrompt.new()
	root.add_child(prompt)
	var finder := InputGlyphs.new("user://glyphs_that_are_not_there")
	tracker.note_event(_key(KEY_W, true))
	prompt.bind(&"attack", "UI_CONTROLS_BACK", finder, tracker)
	_expect(prompt.strip().words_on_show() == "[Space]", "the prompt of Strike shows the key while the keyboard is in hand (%s)" % prompt.strip().words_on_show())
	tracker.note_event(_pad_button(JOY_BUTTON_Y, true))
	_expect(prompt.strip().words_on_show() == "[A]", "and the pad's button the moment the pad is picked up (%s)" % prompt.strip().words_on_show())
	tracker.note_event(_key(KEY_Q, true))
	_expect(prompt.strip().words_on_show() == "[Space]", "and back")
	_expect(prompt.get_child_count() >= 3 and prompt.label_key == "UI_CONTROLS_BACK", "the prompt carries the words of what it does")

	TextService.install_pseudo_language()
	_expect(TextService.set_language(TextService.PSEUDO_LANGUAGE), "setup: the generated test language is installed")
	prompt.refresh()
	_expect(prompt.strip().words_on_show() != "[Space]" and not prompt.strip().words_on_show().is_empty(), "in another language the key's name is that language's (%s)" % prompt.strip().words_on_show())
	TextService.set_language(TextService.SOURCE_LANGUAGE)
	prompt.refresh()
	_expect(prompt.strip().words_on_show() == "[Space]", "and English again")

	var unbound := ActionPrompt.new()
	root.add_child(unbound)
	unbound.bind(&"free_step", "UI_CONTROLS_BACK", finder, tracker)
	tracker.note_event(_pad_button(JOY_BUTTON_A, true))
	_expect(unbound.strip().words_on_show() == "-", "an action the pad has no control for shows the empty cell (%s)" % unbound.strip().words_on_show())
	prompt.free()
	unbound.free()
	tracker.free()


# --------------------------------------------------------------------------- helpers

func _words_of(found: Array[InputGlyph]) -> Array[String]:
	var words: Array[String] = []
	for glyph in found:
		words.append(glyph.text)
	return words


func _asset_list_group() -> Dictionary:
	var list: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ASSET_LIST_PATH))
	for group: Dictionary in list.get("groups", []):
		if group.get("group_id", "") == GLYPH_GROUP_ID:
			return group
	return {}


func _key(keycode: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	return event


func _pad_button(button: JoyButton, pressed: bool) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	return event


func _stick(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event
