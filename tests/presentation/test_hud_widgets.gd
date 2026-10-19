extends UnboundTest

## The widgets of the production HUD (docs/game-base-plan.md D-29, 15 M4), each driven alone through its own scene with a
## HudSnapshot and nothing else: Courage pips, the Rank badge, the skill slot, the enemy count, the status line, the two
## reserved slots, the control hints, the debug readout and the damage flash. What they show is what the snapshot says; they
## draw again only when it changes; no script of them reaches into the simulation or writes to it.
##
## The control hints are built from the InputMap and the last input device: the glyph finder here reads a folder that has no
## pictures, so what is on show is the words ("[Space]", "[A]") whatever the owner has put in assets/ui/glyphs.

const WIDGET_FOLDER := "res://presentation/ui/hud/widgets"
const NO_PICTURES_FOLDER := "res://tests/fixtures/no_glyph_pictures_here"

var paths := TestPaths.new(self)


func _init() -> void:
	suite_title = "HUD WIDGETS TEST"
	await process_frame
	var hud := paths.load_scene(paths.hud_scene()).instantiate() as GameHud
	root.add_child(hud)
	await process_frame
	_courage_pips(hud)
	_rank_badge(hud)
	_skill_slot(hud)
	_enemy_count(hud)
	_status_line(hud)
	_reserved_slots(hud)
	_debug_readout(hud)
	await _control_prompts(hud)
	await _damage_flash(hud)
	_no_widget_touches_the_simulation()
	hud.queue_free()
	finish()


func _snapshot(courage_current := 3, courage_max := 3) -> HudSnapshot:
	var snapshot := HudSnapshot.new()
	snapshot.player_entity = 1
	snapshot.player_courage_current = courage_current
	snapshot.player_courage_max = courage_max
	return snapshot


func _courage_pips(hud: GameHud) -> void:
	var pips := hud.courage_pips
	pips.refresh(_snapshot(3, 3))
	_expect(pips.pip_count() == 3 and pips.filled_count() == 3, "Courage 3 of 3: three full pips")
	pips.refresh(_snapshot(1, 3))
	_expect(pips.pip_count() == 3 and pips.filled_count() == 1 and pips.empty_count() == 2, "Courage 1 of 3: one full pip and two empty")
	pips.refresh(_snapshot(0, 3))
	_expect(pips.filled_count() == 0 and pips.empty_count() == 3, "no Courage left: three empty pips")
	pips.refresh(_snapshot(5, 5))
	_expect(pips.pip_count() == 5 and pips.filled_count() == 5, "the extra Courage assist (+2) draws five pips")
	pips.refresh(_snapshot(9, 9))
	_expect(pips.pip_count() == CouragePips.MOST_PIPS, "and the row never draws more than %d: that is what the plate of the asset list holds" % CouragePips.MOST_PIPS)
	pips.refresh(_snapshot(2, 3))
	var steady := pips.pip_row.get_child(0) as CouragePip
	steady.show_filled(false)
	pips.refresh(_snapshot(2, 3))
	_expect(not steady.is_filled, "a frame that changes nothing draws nothing (a pip touched from outside stays as it was)")
	var no_hero := HudSnapshot.new()
	pips.refresh(no_hero)
	_expect(pips.pip_count() == 3 and pips.filled_count() == 3, "a world with no hero shows full Courage, not a defeat")
	pips.forget_drawn()
	pips.refresh(_snapshot(2, 3))
	_expect(pips.filled_count() == 2 and (pips.pip_row.get_child(0) as CouragePip).is_filled, "forgetting what was drawn makes the next frame draw it all again")


func _rank_badge(hud: GameHud) -> void:
	var badge := hud.rank_badge
	var snapshot := _snapshot()
	badge.refresh(snapshot)
	_expect(not badge.visible and badge.mark_count() == 0, "the Rank badge is hidden while the snapshot has no Rank label (0)")
	snapshot.rank_label = 2
	badge.refresh(snapshot)
	_expect(badge.visible and badge.mark_count() == 2, "Rank 2: the badge shows two blue tally marks")
	snapshot.rank_label = 8
	badge.refresh(snapshot)
	_expect(badge.mark_count() == 8, "Rank 8, the Last Rank: eight marks")
	snapshot.rank_label = 40
	badge.refresh(snapshot)
	_expect(badge.mark_count() == RankBadge.MOST_MARKS, "a label past the last rank draws no more than the eight")
	snapshot.rank_label = 0
	badge.refresh(snapshot)
	_expect(not badge.visible and badge.mark_count() == 0, "and the badge hides again when the label goes")


func _skill_slot(hud: GameHud) -> void:
	var slot := hud.skill_slots.first_slot
	var snapshot := _snapshot()
	snapshot.sword_unlocked = false
	hud.skill_slots.refresh(snapshot)
	_expect(slot.name_label.text == "FIND SWORD" and slot.fill.size.y == 0.0 and slot.fill.color == SkillSlot.LOCKED_FILL, "before the sword is found the slot reads FIND SWORD, with an empty, grey frame")
	snapshot.sword_unlocked = true
	hud.skill_slots.refresh(snapshot)
	_expect(slot.name_label.text == "THRUST READY" and is_equal_approx(slot.fill.size.y, SkillSlot.FILL_HEIGHT) and slot.fill.color == SkillSlot.READY_FILL, "with the sword it reads THRUST READY and the frame is full and blue")
	snapshot.skill_cooldown_duration = 2.0
	snapshot.skill_cooldown_left = 1.5
	hud.skill_slots.refresh(snapshot)
	_expect(slot.name_label.text == "THRUST 1.5" and is_equal_approx(slot.fill.size.y, SkillSlot.FILL_HEIGHT * 0.25) and slot.fill.color == SkillSlot.COOLING_FILL, "cooling down it reads the seconds left, and the amber frame has filled a quarter of the way")
	_expect(is_equal_approx(slot.fill.position.y + slot.fill.size.y, SkillSlot.FILL_INSET + SkillSlot.FILL_HEIGHT), "the frame fills from the bottom")
	_expect(hud.skill_slots.size.x >= 4 * 24 and hud.skill_slots.size.y == 24, "the widget's own rectangle holds four 24 px slots, so the other three arrive without moving anything")


func _enemy_count(hud: GameHud) -> void:
	var snapshot := _snapshot()
	snapshot.room_enemies_remaining = 2
	snapshot.room_enemies_total = 5
	hud.enemy_count.refresh(snapshot)
	_expect(hud.enemy_count.count_label.text == "ENEMIES 2/5", "the enemy count reads remaining over total")
	snapshot.room_enemies_remaining = 0
	snapshot.room_enemies_total = 0
	hud.enemy_count.refresh(snapshot)
	_expect(hud.enemy_count.count_label.text == "ENEMIES 0/0", "and says 0/0 in a room with no enemies")


func _status_line(hud: GameHud) -> void:
	hud.objective_line.say("MSG_ENEMY_PICKED_UP", {"piece": TextKey.of("ENEMY_PAWN_ARMED_PIECE"), "weapon": TextKey.of("ITEM_PENCIL_SPEAR_NAME")})
	_expect(hud.objective_line.text_label.text.begins_with("Pawn picked up"), "the status line says the sentence of its key, with the names put in")
	hud.objective_line.say("")
	_expect(hud.objective_line.text_label.text == "", "an empty key empties it")
	hud.objective_line.say("MSG_GATE_UNBARS")
	hud.objective_line.clear()
	_expect(hud.objective_line.text_label.text == "", "and so does clear()")


func _reserved_slots(hud: GameHud) -> void:
	var snapshot := _snapshot()
	snapshot.rank_label = 5
	snapshot.sword_unlocked = true
	hud.refresh(snapshot)
	_expect(not hud.believe_slot.visible and not hud.boss_bar_slot.visible, "a snapshot full of numbers does not show the reserved Believe slot or boss bar: nothing reads for them before M10 and M8b")
	_expect(hud.believe_slot.get_child_count() == 0 and hud.boss_bar_slot.get_child_count() == 0, "and they hold nothing yet")
	hud.refresh(_snapshot())


func _debug_readout(hud: GameHud) -> void:
	_expect(not hud.debug_readout.visible and hud.control_prompts.visible, "the debug readout is hidden and the control hints are up when the HUD is made")
	hud.set_debug_visible(true)
	_expect(hud.debug_readout.visible and not hud.control_prompts.visible, "F3 puts the debug readout in the place of the control hints")
	hud.set_debug_visible(false)
	_expect(not hud.debug_readout.visible and hud.control_prompts.visible, "and gives them back")
	var snapshot := _snapshot()
	snapshot.player_cell = Vector2i(4, 9)
	snapshot.player_facing = Vector2i.RIGHT
	hud.refresh(snapshot)
	_expect(hud.debug_readout.cell_label.text == "CELL 04,09  FACE E", "the cell line is kept up to date while the readout is hidden, so F3 shows the right numbers at once")


func _control_prompts(hud: GameHud) -> void:
	var prompts := hud.control_prompts
	var glyphs := InputGlyphs.new(NO_PICTURES_FOLDER)
	var device := LastInputDevice.new()
	root.add_child(device)
	prompts.configure(glyphs, device)
	_expect(prompts.hint_count() == 4 and prompts.hint_words() == PackedStringArray(["MOVE", "SWORD", "THRUST", "PAUSE"]), "the control hints are Move, Sword, Thrust and Pause")
	_expect(prompts.strip_of_hint(0).words_on_show() == "[W] [A] [S] [D]" and prompts.strip_of_hint(1).words_on_show() == "[Space]" and prompts.strip_of_hint(2).words_on_show() == "[Q]" and prompts.strip_of_hint(3).words_on_show() == "[Esc]", "on the keyboard they show the keys of the InputMap: [W] [A] [S] [D], [Space], [Q], [Esc] (the words stand in for pictures that are not there)")
	device.note_event(_pad_button(JOY_BUTTON_A))
	_expect(device.device == InputGlyphs.Device.GAMEPAD and prompts.strip_of_hint(1).words_on_show() == "[A]" and prompts.strip_of_hint(2).words_on_show() == "[X]" and prompts.strip_of_hint(3).words_on_show() == "[Start]", "the moment the pad is touched they show the pad's buttons: [A], [X], [Start]")
	_expect(prompts.strip_of_hint(0).glyphs_on_show.size() == 1, "and the four move keys become one hint of the pad (a stick), not four")
	device.note_event(_key(KEY_Q))
	_expect(prompts.strip_of_hint(1).words_on_show() == "[Space]", "a key press brings the keyboard back")
	# Built from the live InputMap: a rebound key shows with no other change.
	var attack_events := InputMap.action_get_events(&"attack")
	InputMap.action_erase_events(&"attack")
	var rebound := InputEventKey.new()
	rebound.physical_keycode = KEY_J
	InputMap.action_add_event(&"attack", rebound)
	prompts.rebuild()
	_expect(prompts.strip_of_hint(1).words_on_show() == "[J]", "the hints are read from the InputMap: attack moved to J and the hint says [J]")
	InputMap.action_erase_events(&"attack")
	for original in attack_events:
		InputMap.action_add_event(&"attack", original)
	prompts.rebuild()
	_expect(prompts.strip_of_hint(1).words_on_show() == "[Space]", "(restored)")
	TextService.install_pseudo_language()
	TextService.set_language(&"qps")
	await process_frame
	_expect(prompts.hint_words()[0] != "MOVE" and prompts.hint_count() == 4, "a language switch changes the words of the hints")
	TextService.set_language(&"en")
	await process_frame
	_expect(prompts.hint_words()[0] == "MOVE", "and back")
	device.queue_free()


func _damage_flash(hud: GameHud) -> void:
	var flash := hud.damage_flash
	flash.flash()
	_expect(flash.visible and is_equal_approx(flash.color.a, DamageFlash.PEAK_ALPHA), "a hit flashes the screen red at once")
	await create_timer(DamageFlash.FADE_SECONDS + 0.15).timeout
	_expect(not flash.visible, "and the flash ends by itself")
	hud.reduce_flash = true
	flash.flash()
	_expect(not flash.visible, "with Reduce flashing on it does not appear")
	hud.reduce_flash = false
	flash.flash()
	_expect(flash.visible, "and comes back with the setting off")
	hud.reduce_flash = true
	_expect(not flash.visible, "turning Reduce flashing on cuts a flash in progress")
	hud.reduce_flash = false


func _no_widget_touches_the_simulation() -> void:
	var offenders: Array[String] = []
	var checked := 0
	for file_name in DirAccess.get_files_at(WIDGET_FOLDER):
		if not file_name.ends_with(".gd"):
			continue
		checked += 1
		var source := paths.read_text("%s/%s" % [WIDGET_FOLDER, file_name])
		for forbidden in ["push_command", "push_view_command", "get_component", "add_component", "EcsWorld", "EcsComponents", "Input.is_", "Input.get_"]:
			if source.contains(forbidden):
				offenders.append("%s names %s" % [file_name, forbidden])
	_expect(checked >= 12 and offenders.is_empty(), "no widget script reads or writes the simulation or polls the controls: %d scripts checked (%s)" % [checked, ", ".join(offenders)])


func _pad_button(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	return event


func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = true
	return event
