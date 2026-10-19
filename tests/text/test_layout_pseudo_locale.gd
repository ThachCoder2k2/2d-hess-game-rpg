extends UnboundTest

## No text overflows its box when every line is 40 percent longer (docs/game-base-plan.md 8.9, 15 M4). The screens that
## show words (the HUD, the title, the pause menu, the settings screen) are laid out for English; a translation is
## longer, and a box that only just holds the English words breaks when it is not. Each screen is built at the
## game's own size, 640 x 360, in English; every text control's rectangle and text are recorded; the game is switched
## to the pseudo-language (PseudoLocale: +40 percent, accented) and the screen is measured again. It fails when
## a text control:
##   - leaves the screen;
##   - is a fixed box (not in a container) and grew, or whose longest line needs more width than the box has (a
##     label drawn past its edge), or whose text is now taller than its box and than the English text was (a wrapped
##     label that needs another line it has no room for);
##   - now overlaps another text control of the same layer it did not overlap in English (the question a modal panel
##     asks lies on top of the menu behind it by design, so its texts are a layer of their own).
## A control in a container may grow with its container; what then matters is that it stays on the screen.
## Each screen is tried in the states that put the longest words on it: every line the status bar can say, the
## longest piece name, the longest notice, every question. The settings screen is measured when its scene exists
## (res://shell/settings/settings_screen.tscn); until then the suite says so and measures the others.
## The measuring is first run on a sample that does overflow, so it is shown to be able to fail.

const SaveSupport := preload("res://tests/support/save_test_support.gd")

const SCREEN_SIZE := Vector2i(640, 360)
const SETTINGS_SCENE_PATH := "res://shell/settings/settings_screen.tscn"
## A pixel of play is not an overflow: rectangles are compared with this much tolerance.
const TOLERANCE := 0.5
## Fewer measured states than this means the walk is broken, not clean.
const MINIMUM_STATES := 30

var paths := TestPaths.new(self)
var viewport: SubViewport
var roots_to_remove: Array[String] = []
var checked_states := 0
## A saved run for the title's card.
var saved_run_service: Node
var longest_piece_key := ""
var longest_room_key := ""
var longest_notice_text_key := ""


func _init() -> void:
	suite_title = "LAYOUT PSEUDO LOCALE TEST"
	TextService.install_pseudo_language()
	viewport = SubViewport.new()
	viewport.size = SCREEN_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	await wait_frames(1)
	_find_the_longest_words()
	await _the_measuring_can_fail()
	await _the_hud()
	await _the_title()
	await _the_pause_menu()
	await _the_settings_screen()
	_expect(checked_states >= MINIMUM_STATES, "the walk measured %d states of the screens (at least %d)" % [checked_states, MINIMUM_STATES])
	for root_to_remove in roots_to_remove:
		SaveSupport.remove_root(root_to_remove)
	finish()


# --------------------------------------------------------------------------- the screens

func _the_hud() -> void:
	var hud_path := paths.hud_scene()
	await _check_state("the HUD at rest (Courage 3, sword not found, no strike line)", hud_path, _hud_at_rest)
	await _check_state("the HUD with the sword ready", hud_path, _hud_sword_ready)
	await _check_state("the HUD with the thrust cooling down", hud_path, _hud_thrust_cooling_down)
	await _check_state("the HUD naming the piece that strikes next (the longest name)", hud_path, _hud_naming_the_longest_piece)
	await _check_state("the HUD with the strike line free", hud_path, _hud_strike_free)
	await _check_state("the HUD after a win", hud_path, _hud_after_a_win)
	await _check_state("the HUD after a fall", hud_path, _hud_after_a_fall)
	# Every line the status bar can say, one by one.
	for key in _status_line_keys():
		await _check_state("the HUD status line says %s" % key, hud_path, func(screen: Node) -> void:
			var hud := screen as GameHud
			hud.setup(3)
			hud.set_status(key, {"attack": TextKey.of("SKILL_PENCIL_THRUST_NAME"), "piece": TextKey.of(longest_piece_key), "weapon": TextKey.of("ITEM_RULER_BLADE_NAME")}))


func _hud_at_rest(screen: Node) -> void:
	var hud := screen as GameHud
	hud.setup(3)
	hud.set_encounter_count(3, 3)
	hud.set_cell_status(Vector2i(10, 12), TextKey.of("UI_COMPASS_NORTH"))


func _hud_sword_ready(screen: Node) -> void:
	var hud := screen as GameHud
	hud.setup(2)
	hud.set_skill_cooldown(0.0, 1.0, true)


func _hud_thrust_cooling_down(screen: Node) -> void:
	var hud := screen as GameHud
	hud.setup(1)
	hud.set_skill_cooldown(1.9, 2.0, true)


func _hud_naming_the_longest_piece(screen: Node) -> void:
	var hud := screen as GameHud
	hud.setup(3)
	hud.set_encounter_count(12, 12)
	hud.set_token_owner(TextKey.of(longest_piece_key))


func _hud_strike_free(screen: Node) -> void:
	var hud := screen as GameHud
	hud.setup(3)
	hud.set_encounter_count(1, 1)
	hud.set_token_owner(null)


func _hud_after_a_win(screen: Node) -> void:
	var hud := screen as GameHud
	hud.setup(3)
	hud.show_result(RoomObjective.STOCK_CLEAR_KEY, RoomObjective.STOCK_CLEAR_SUBTITLE_KEY)


func _hud_after_a_fall(screen: Node) -> void:
	var hud := screen as GameHud
	hud.setup(1)
	hud.show_result(RoomObjective.STOCK_DEFEAT_KEY, RoomObjective.STOCK_DEFEAT_SUBTITLE_KEY)


func _the_title() -> void:
	var root_directory := SaveSupport.make_root("layout_pseudo_title")
	roots_to_remove.append(root_directory)
	var service := SaveSupport.new_service(root_directory)
	service.new_game(0)
	service.state.room_id = &"t4_broken_rule_yard"
	service.state.play_time_seconds = 40000.0
	service.request_save(&"room_cleared")
	saved_run_service = SaveSupport.new_service(root_directory)
	var title_path := paths.title_scene()
	await _check_state("the title with no save", title_path, _title_with_no_save)
	await _check_state("the title with a save, its card and its Settings button", title_path, _title_with_a_save)
	for notice_key: StringName in TitleSummary.NOTICE_TEXT_KEY_BY_KEY:
		await _check_state("the title with the notice %s" % notice_key, title_path, func(screen: Node) -> void:
			var summary := TitleSummary.from_save(saved_run_service, "0.4.0")
			summary.notice_key = notice_key
			summary.refresh_texts()
			(screen as TitleScreen).configure(summary, true))
	await _check_state("the title asking whether to replace the save", title_path, _title_asking_to_replace)


func _title_with_no_save(screen: Node) -> void:
	(screen as TitleScreen).configure(TitleSummary.from_save(null, "0.4.0"), false)


func _title_with_a_save(screen: Node) -> void:
	(screen as TitleScreen).configure(TitleSummary.from_save(saved_run_service, "0.4.0"), true)


func _title_asking_to_replace(screen: Node) -> void:
	var title := screen as TitleScreen
	title.configure(TitleSummary.from_save(saved_run_service, "0.4.0"), true)
	title.confirm_panel.ask(TitleScreen.CONFIRM_MESSAGE_KEY, TitleScreen.CONFIRM_YES_KEY, TitleScreen.CONFIRM_NO_KEY)


func _the_pause_menu() -> void:
	var menu_path := paths.pause_menu_scene()
	await _check_state("the pause menu", menu_path, _pause_menu_open)
	await _check_state("the pause menu asking whether to restart the room", menu_path, _pause_menu_asking_to_restart)
	await _check_state("the pause menu asking whether to quit, with no checkpoint yet", menu_path, _pause_menu_asking_to_quit)
	await _check_state("the pause menu asking whether to quit, naming the longest room", menu_path, _pause_menu_asking_to_quit_from_the_longest_room)


func _pause_menu_open(screen: Node) -> void:
	(screen as PauseMenu).open(PauseSummary.new())


func _pause_menu_asking_to_restart(screen: Node) -> void:
	var menu := screen as PauseMenu
	menu.open(PauseSummary.new())
	menu.restart_button.pressed.emit()


func _pause_menu_asking_to_quit(screen: Node) -> void:
	var menu := screen as PauseMenu
	menu.open(PauseSummary.new())
	menu.quit_button.pressed.emit()


func _pause_menu_asking_to_quit_from_the_longest_room(screen: Node) -> void:
	var menu := screen as PauseMenu
	var summary := PauseSummary.new()
	summary.checkpoint_zone_id = StringName(longest_room_key.trim_prefix("ROOM_").trim_suffix("_NAME").to_lower())
	menu.open(summary)
	menu.quit_button.pressed.emit()


func _the_settings_screen() -> void:
	if not ResourceLoader.exists(SETTINGS_SCENE_PATH):
		print("INFO: the settings screen (%s) does not exist yet; it is measured here as soon as it does" % SETTINGS_SCENE_PATH)
		return
	await _check_state("the settings screen", SETTINGS_SCENE_PATH, func(_screen: Node) -> void: pass)


# --------------------------------------------------------------------------- the measuring

## Builds the scene `scene_path` at the game's size, lets `put_in_state` put it in a state, measures it in English and
## again in the pseudo-language, and expects the second to fit where the first did.
func _check_state(state_name: String, scene_path: String, put_in_state: Callable) -> void:
	TextService.set_language(&"en")
	var screen := (load(scene_path) as PackedScene).instantiate()
	viewport.add_child(screen)
	await wait_frames(1)
	put_in_state.call(screen)
	await wait_frames(2)
	var english := _measure(screen)
	TextService.set_language(&"qps")
	await wait_frames(2)
	var pseudo := _measure(screen)
	var problems := _overflows(english, pseudo)
	checked_states += 1
	_expect(not english["texts"].is_empty() and problems.is_empty(), "%s fits when every line is 40 percent longer%s" % [state_name, "" if problems.is_empty() else " (" + "; ".join(problems.slice(0, 10)) + ")"])
	TextService.set_language(&"en")
	viewport.remove_child(screen)
	screen.queue_free()
	await wait_frames(1)


## What the screen looks like: { "texts": control path -> entry, "panels": panel path -> Rect2 }.
## An entry is { "rect": Rect2 (the control's box, in the viewport), "extent": Rect2 (where its text is drawn),
## "shown": String, "fixed": bool (not laid out by a container), "layer": String (the name of the ConfirmPanel it is
## on, "" for the screen itself), "line_count": int, "backing": String (the path of the smallest panel that held the
## text, filled in by _overflows from the English measure) } for every visible text control under `screen`; a panel is
## a ColorRect, Panel, PanelContainer or NinePatchRect that is visible.
func _measure(screen: Node) -> Dictionary:
	var texts := {}
	for control in _text_controls(screen):
		var shown := control.atr(String(control.get("text")))
		if shown.strip_edges().is_empty():
			continue
		var line_count := (control as Label).get_line_count() if control is Label else shown.count("\n") + 1
		texts[str(screen.get_path_to(control))] = {
			"rect": control.get_global_rect(),
			"extent": _text_extent(control, shown, line_count),
			"shown": shown,
			"fixed": not (control.get_parent() is Container),
			"layer": _layer_of(control),
			"line_count": line_count,
			"backing": "",
		}
	var panels := {}
	for panel in _panels(screen):
		panels[str(screen.get_path_to(panel))] = panel.get_global_rect()
	return {"texts": texts, "panels": panels}


## Where the text of `control` is drawn, in the viewport: the widest line by the lines' height, placed by the
## control's alignment inside its box. A label that wraps uses the whole width of its box.
func _text_extent(control: Control, shown: String, line_count: int) -> Rect2:
	var box := control.get_global_rect()
	var font := control.get_theme_font(&"font")
	var font_size := control.get_theme_font_size(&"font_size")
	var widest := 0.0
	for text_line in shown.split("\n"):
		widest = maxf(widest, font.get_string_size(text_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	var line_height := font.get_height(font_size)
	var horizontal := HORIZONTAL_ALIGNMENT_LEFT
	var vertical := VERTICAL_ALIGNMENT_TOP
	var label := control as Label
	if label != null:
		horizontal = label.horizontal_alignment
		vertical = label.vertical_alignment
		line_height = label.get_line_height()
		if label.autowrap_mode != TextServer.AUTOWRAP_OFF:
			widest = box.size.x
	elif control is Button:
		horizontal = (control as Button).alignment
		vertical = VERTICAL_ALIGNMENT_CENTER
	var text_size := Vector2(widest, line_height * line_count)
	var origin := box.position
	match horizontal:
		HORIZONTAL_ALIGNMENT_CENTER:
			origin.x += (box.size.x - text_size.x) / 2.0
		HORIZONTAL_ALIGNMENT_RIGHT:
			origin.x += box.size.x - text_size.x
	match vertical:
		VERTICAL_ALIGNMENT_CENTER:
			origin.y += (box.size.y - text_size.y) / 2.0
		VERTICAL_ALIGNMENT_BOTTOM:
			origin.y += box.size.y - text_size.y
	return Rect2(origin, text_size)


## The name of the ConfirmPanel `control` is on, "" when it is not on one.
func _layer_of(control: Control) -> String:
	var ancestor := control.get_parent()
	while ancestor != null:
		if ancestor is ConfirmPanel:
			return str(ancestor.name)
		ancestor = ancestor.get_parent()
	return ""


func _text_controls(node: Node) -> Array[Control]:
	var found: Array[Control] = []
	var control := node as Control
	if control != null and control.is_visible_in_tree() and (control is Label or control is BaseButton or control is RichTextLabel):
		found.append(control)
	for child in node.get_children():
		found.append_array(_text_controls(child))
	return found


func _panels(node: Node) -> Array[Control]:
	var found: Array[Control] = []
	var control := node as Control
	if control != null and control.is_visible_in_tree() and (control is ColorRect or control is Panel or control is PanelContainer or control is NinePatchRect):
		found.append(control)
	for child in node.get_children():
		found.append_array(_panels(child))
	return found


## The sentences that say how the pseudo-language measurement does not fit the English one.
func _overflows(english: Dictionary, pseudo: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	var screen_rect := Rect2(Vector2.ZERO, Vector2(SCREEN_SIZE))
	var english_texts: Dictionary = english["texts"]
	var pseudo_texts: Dictionary = pseudo["texts"]
	for path: String in pseudo_texts:
		var now: Dictionary = pseudo_texts[path]
		var extent: Rect2 = now["extent"]
		var rect: Rect2 = now["rect"]
		if not screen_rect.grow(TOLERANCE).encloses(extent) or not screen_rect.grow(TOLERANCE).encloses(rect):
			problems.append("%s leaves the screen (text %s, box %s)" % [path, extent, rect])
		var before: Dictionary = english_texts.get(path, {})
		if before.is_empty():
			continue
		if now["fixed"]:
			var box: Rect2 = before["rect"]
			if not box.grow(TOLERANCE).encloses(rect):
				problems.append("%s grew out of its box %s to %s" % [path, box, rect])
			if not rect.grow(TOLERANCE).encloses(extent):
				problems.append("%s draws its text %s outside its box %s" % [path, extent, rect])
			var height_had := maxf(box.size.y, before["extent"].size.y)
			if extent.size.y > height_had + TOLERANCE:
				problems.append("%s needs %d lines, %.0f px of height, and had %.0f" % [path, now["line_count"], extent.size.y, height_had])
		var backing_path := _backing_panel_of(before["extent"], english["panels"])
		if not backing_path.is_empty() and pseudo["panels"].has(backing_path):
			var panel_rect: Rect2 = pseudo["panels"][backing_path]
			if not panel_rect.grow(TOLERANCE).encloses(extent):
				problems.append("%s draws its text %s outside the panel %s it sat on, %s" % [path, extent, backing_path, panel_rect])
	var paths_in_order: Array = pseudo_texts.keys()
	for first_index in paths_in_order.size():
		for second_index in range(first_index + 1, paths_in_order.size()):
			var first_path: String = paths_in_order[first_index]
			var second_path: String = paths_in_order[second_index]
			if not (english_texts.has(first_path) and english_texts.has(second_path)):
				continue
			if english_texts[first_path]["layer"] != english_texts[second_path]["layer"]:
				continue
			var overlapped_before := _overlap(english_texts[first_path]["extent"], english_texts[second_path]["extent"])
			if not overlapped_before and _overlap(pseudo_texts[first_path]["extent"], pseudo_texts[second_path]["extent"]):
				problems.append("%s now overlaps %s" % [first_path, second_path])
	return problems


## The path of the smallest panel that held `text_extent` in English, "" when none did.
func _backing_panel_of(text_extent: Rect2, panels: Dictionary) -> String:
	var best_path := ""
	var best_area := INF
	for panel_path: String in panels:
		var panel_rect: Rect2 = panels[panel_path]
		if panel_rect.grow(TOLERANCE).encloses(text_extent) and panel_rect.get_area() < best_area:
			best_area = panel_rect.get_area()
			best_path = panel_path
	return best_path


func _overlap(first: Rect2, second: Rect2) -> bool:
	return first.grow(-TOLERANCE).intersects(second.grow(-TOLERANCE))


## Sample screens that must be reported: a label whose box holds the English line and not the longer one, the same
## label on a panel, and two labels that meet when one of them grows.
func _the_measuring_can_fail() -> void:
	TextService.set_language(&"en")
	var sample := Control.new()
	var panel := ColorRect.new()
	panel.position = Vector2(10, 40)
	panel.size = Vector2(72, 26)
	var on_panel := Label.new()
	on_panel.text = "UI_PAUSE_RESUME"
	on_panel.position = Vector2(12, 42)
	var short_one := Label.new()
	short_one.text = "UI_TITLE_QUIT"
	short_one.position = Vector2(10, 10)
	var neighbour := Label.new()
	neighbour.text = "UI_TITLE_NEW_GAME"
	neighbour.position = Vector2(52, 10)
	for node in [panel, on_panel, short_one, neighbour]:
		sample.add_child(node)
	viewport.add_child(sample)
	await wait_frames(2)
	var english := _measure(sample)
	TextService.set_language(&"qps")
	await wait_frames(2)
	var pseudo := _measure(sample)
	var problems := "; ".join(_overflows(english, pseudo))
	_expect(english["texts"].size() == 3 and problems.contains("grew out of its box") and problems.contains("outside the panel") and problems.contains("now overlaps"), "the measuring reports a label that outgrows its box, text that leaves its panel and labels that meet (%s)" % problems)
	TextService.set_language(&"en")
	viewport.remove_child(sample)
	sample.queue_free()
	await wait_frames(1)


# --------------------------------------------------------------------------- the longest words

func _find_the_longest_words() -> void:
	longest_piece_key = _longest_key(_rows_matching(func(key: String) -> bool: return key.begins_with("ENEMY_") and key.ends_with("_PIECE")))
	longest_room_key = _longest_key(_rows_matching(func(key: String) -> bool: return key.begins_with("ROOM_") and key.ends_with("_NAME")))
	longest_notice_text_key = _longest_key(PackedStringArray(TitleSummary.NOTICE_TEXT_KEY_BY_KEY.values()))
	_expect(not longest_piece_key.is_empty() and not longest_room_key.is_empty() and not longest_notice_text_key.is_empty(), "the longest piece name (%s), room name (%s) and notice (%s) were found" % [longest_piece_key, longest_room_key, longest_notice_text_key])


## Every line the status bar can say: the MSG_ rows and the lines of the rooms (everything in rooms.po but a room's name).
func _status_line_keys() -> PackedStringArray:
	return _rows_matching(func(key: String) -> bool: return key.begins_with("MSG_") or (key.begins_with("ROOM_") and not key.ends_with("_NAME")))


func _rows_matching(predicate: Callable) -> PackedStringArray:
	var keys := PackedStringArray()
	for translation in TextService.source_translations():
		for key in translation.get_message_list():
			if predicate.call(String(key)) and String(key) not in keys:
				keys.append(String(key))
	return keys


func _longest_key(keys: PackedStringArray) -> String:
	var longest := ""
	for key in keys:
		if TextService.t(key).length() > TextService.t(longest).length():
			longest = key
	return longest
