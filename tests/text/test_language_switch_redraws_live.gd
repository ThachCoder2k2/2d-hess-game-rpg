extends UnboundTest

## A language switch redraws what is on screen at once (docs/game-base-plan.md 8.9: TextService handles
## NOTIFICATION_TRANSLATION_CHANGED). Every screen that shows words is put on screen in English, its texts are
## recorded, the game is switched to the pseudo-language (so no row can be mistaken for English), and every text
## must have changed and kept its numbers and names; switching back must give the English texts again. A text that
## stayed (a literal that skipped the pipeline) or that lost a number (a param that was resolved too early) fails.
##
## "Shown" is the text the player sees: a label the scene authored holds its key and the engine translates it,
## so Node.atr() of the key is what is drawn; a label a script set holds the words and atr() leaves them alone.

const SaveSupport := preload("res://tests/support/save_test_support.gd")

var paths := TestPaths.new(self)
var roots_to_remove: Array[String] = []


func _init() -> void:
	suite_title = "LANGUAGE SWITCH REDRAWS LIVE TEST"
	TextService.install_pseudo_language()
	await _the_hud()
	await _the_title()
	await _the_pause_menu_and_its_questions()
	await _the_book()
	await _the_credits()
	for root_to_remove in roots_to_remove:
		SaveSupport.remove_root(root_to_remove)
	finish()


# --------------------------------------------------------------------------- the screens

func _the_hud() -> void:
	var hud := paths.load_scene(paths.hud_scene()).instantiate() as GameHud
	root.add_child(hud)
	await wait_frames(1)
	var snapshot := HudSnapshot.new()
	snapshot.player_entity = 1
	snapshot.player_courage_current = 2
	snapshot.player_courage_max = 3
	snapshot.player_cell = Vector2i(3, 7)
	snapshot.player_facing = Vector2i.UP
	snapshot.sword_unlocked = true
	snapshot.skill_cooldown_left = 0.5
	snapshot.skill_cooldown_duration = 1.0
	snapshot.room_enemies_remaining = 1
	snapshot.room_enemies_total = 3
	snapshot.rank_label = 3
	hud.show_room(snapshot)
	hud.set_strike_owner(TextKey.of("ENEMY_PAWN_RECRUIT_PIECE"))
	hud.set_status("MSG_ENEMY_PICKED_UP", {"piece": TextKey.of("ENEMY_PAWN_ARMED_PIECE"), "weapon": TextKey.of("ITEM_PENCIL_SPEAR_NAME")})
	hud.show_result("UI_RESULT_DEFEATED", "UI_RESULT_DEFEATED_SUBTITLE")
	var cell_label := hud.debug_readout.cell_label
	var skill_label := hud.skill_slots.first_slot.name_label
	var count_label := hud.enemy_count.count_label
	var status_label := hud.objective_line.text_label
	var strike_label := hud.debug_readout.strike_label
	var labels: Array[Label] = [hud.courage_pips.caption_label, hud.rank_badge.get_node("Caption"), skill_label, cell_label, count_label, status_label, strike_label, hud.result_panel.text_label]
	var english := _shown_texts(labels)
	var english_hints := hud.control_prompts.hint_words()
	_expect(english[hud.courage_pips.caption_label] == "COURAGE" and english[status_label].begins_with("Pawn picked up Pencil Spear"), "setup: the HUD shows English")
	await _switch_to(&"qps")
	var pseudo := _shown_texts(labels)
	_expect(_every_text_changed(english, pseudo), "the HUD: every label changed (%s)" % _unchanged(english, pseudo))
	_expect(hud.courage_pips.filled_count() == 2 and hud.courage_pips.empty_count() == 1, "and the Courage pips are the same")
	_expect(pseudo[skill_label].contains("0.5") and pseudo[count_label].contains("1/3") and pseudo[cell_label].contains("03,07"), "and so are the numbers of the skill slot, the count and the cell")
	_expect(not pseudo[status_label].contains("Pawn") and not pseudo[status_label].contains("Spear") and not pseudo[strike_label].contains("PAWN"), "and the names inside a sentence changed with it, they were not frozen in English")
	_expect(hud.control_prompts.hint_words() != english_hints and hud.control_prompts.hint_count() == english_hints.size(), "and so are the words of the control hints (%s)" % ", ".join(hud.control_prompts.hint_words()))
	await _switch_to(&"en")
	_expect(_shown_texts(labels) == english and hud.control_prompts.hint_words() == english_hints, "back in English, the HUD says what it said")
	hud.queue_free()


func _the_title() -> void:
	var root_directory := SaveSupport.make_root("language_switch_title")
	roots_to_remove.append(root_directory)
	var service := SaveSupport.new_service(root_directory)
	service.new_game(0)
	service.state.room_id = &"t4_broken_rule_yard"
	service.state.play_time_seconds = 4000.0
	service.request_save(&"room_cleared")
	var summary := TitleSummary.from_save(SaveSupport.new_service(root_directory), "1.2.3")
	summary.notice_key = SaveLoadResult.NOTICE_BACKUP_USED
	summary.refresh_texts()
	var title := paths.load_scene(paths.title_scene()).instantiate() as TitleScreen
	title.configure(summary, true)
	root.add_child(title)
	await wait_frames(1)
	var labels: Array[Control] = [title.new_game_button, title.continue_button, title.settings_button, title.credits_button, title.quit_button, title.card_label, title.notice_label, title.version_label]
	var english := _shown_texts(labels)
	_expect(english[title.new_game_button] == "New Game" and english[title.card_label].begins_with("Broken Rule Yard") and english[title.version_label] == "v1.2.3", "setup: the title shows English")
	await _switch_to(&"qps")
	var pseudo := _shown_texts(labels)
	_expect(_every_text_changed(english, pseudo), "the title: the buttons, the card, the notice and the version changed (%s)" % _unchanged(english, pseudo))
	_expect(pseudo[title.card_label].contains("1h") or pseudo[title.card_label].contains("6"), "and the card kept the time played (%s)" % pseudo[title.card_label])
	title.confirm_panel.ask(TitleScreen.CONFIRM_MESSAGE_KEY, TitleScreen.CONFIRM_YES_KEY, TitleScreen.CONFIRM_NO_KEY)
	var question := [title.confirm_panel.message_label, title.confirm_panel.confirm_button, title.confirm_panel.cancel_button]
	var pseudo_question := _shown_texts(question)
	await _switch_to(&"en")
	_expect(_shown_texts(labels) == english, "back in English, the title says what it said")
	_expect(_every_text_changed(pseudo_question, _shown_texts(question)) and _shown_texts(question)[title.confirm_panel.cancel_button] == "Keep my save", "and a question that was up when the language changed follows it")
	title.queue_free()


func _the_pause_menu_and_its_questions() -> void:
	var menu := paths.load_scene(paths.pause_menu_scene()).instantiate() as PauseMenu
	root.add_child(menu)
	await wait_frames(1)
	var summary := PauseSummary.new()
	summary.checkpoint_zone_id = &"b1_black_pawn_captain"
	menu.open(summary)
	var buttons: Array[Control] = [menu.resume_button, menu.book_button, menu.restart_button, menu.quit_button, menu.get_node("Center/Panel/Margin/Rows/TitleLabel")]
	var english := _shown_texts(buttons)
	_expect(english[menu.resume_button] == "Resume" and english[menu.restart_button] == "Restart Room", "setup: the pause menu shows English")
	menu.quit_button.pressed.emit()
	var question: Array[Control] = [menu.confirm_panel.message_label, menu.confirm_panel.confirm_button, menu.confirm_panel.cancel_button]
	var english_question := _shown_texts(question)
	_expect(english_question[menu.confirm_panel.message_label].contains("Black Pawn Captain"), "setup: the Quit question names the checkpoint")
	await _switch_to(&"qps")
	var pseudo := _shown_texts(buttons)
	var pseudo_question := _shown_texts(question)
	_expect(_every_text_changed(english, pseudo), "the pause menu: every entry changed (%s)" % _unchanged(english, pseudo))
	_expect(_every_text_changed(english_question, pseudo_question), "and the question that is up changed with its two answers (%s)" % _unchanged(english_question, pseudo_question))
	_expect(not pseudo_question[menu.confirm_panel.message_label].contains("Black Pawn Captain") and not pseudo_question[menu.confirm_panel.message_label].contains("Captain"), "the checkpoint's name inside the question changed too")
	await _switch_to(&"en")
	_expect(_shown_texts(buttons) == english and _shown_texts(question) == english_question, "back in English, the menu and the question say what they said")
	menu.queue_free()


func _the_book() -> void:
	var book := paths.load_scene(paths.rule_book_scene()).instantiate() as RuleBookUI
	root.add_child(book)
	await wait_frames(1)
	book.visible = true
	book.refresh(["pawn_recruit", "pawn_armed"])
	var labels: Array[Control] = [book.count_label, book.title_label, book.original_label, book.amendment_label, book.flavor_label, book.get_node("Panel/Margin/Layout/LeftColumn/BookTitle")]
	var english := _shown_texts(labels)
	var english_list := _list_texts(book.entry_list)
	_expect(english[book.count_label] == "2 of 5 amendments known" and english_list[0] == "The first law" and english_list[4] == "Unread ink", "setup: the Book shows English")
	await _switch_to(&"qps")
	var pseudo := _shown_texts(labels)
	var pseudo_list := _list_texts(book.entry_list)
	_expect(_every_text_changed(english, pseudo), "the Book: the count, the open page and the heading changed (%s)" % _unchanged(english, pseudo))
	_expect(pseudo[book.count_label].contains("2") and pseudo[book.count_label].contains("5"), "and the count kept its numbers")
	_expect(pseudo_list.size() == english_list.size() and pseudo_list != english_list and pseudo_list[0] != english_list[0] and pseudo_list[4] != english_list[4], "and the page list was written again in the new language")
	await _switch_to(&"en")
	_expect(_shown_texts(labels) == english and _list_texts(book.entry_list) == english_list, "back in English, the Book says what it said")
	book.queue_free()


func _the_credits() -> void:
	var credits := paths.load_scene(paths.credits_scene()).instantiate() as CreditsScreen
	root.add_child(credits)
	await wait_frames(2)
	var lines := _roll_labels(credits)
	var english := _shown_texts(lines)
	_expect(english.values().has("Design, story and art") and english.values().has("The Unbound Pawn") and english.values().has("Thank you for playing."), "setup: the roll shows English")
	await _switch_to(&"qps")
	var pseudo := _shown_texts(lines)
	var changed := 0
	var legal_text_kept := true
	for line in lines:
		if credits.definition.sections.any(func(section: CreditsSection) -> bool: return section.fine_print and line.text in Array(section.lines)):
			legal_text_kept = legal_text_kept and pseudo[line] == english[line]
		elif pseudo[line] != english[line]:
			changed += 1
	_expect(changed >= 6, "the credits: the title, the headings, the credit lines and the closing line changed (%d)" % changed)
	_expect(legal_text_kept, "and the licence texts are legal text and stayed exactly as written")
	await _switch_to(&"en")
	_expect(_shown_texts(lines) == english, "back in English, the roll says what it said")
	credits.queue_free()


# --------------------------------------------------------------------------- helpers

func _switch_to(language: StringName) -> void:
	TextService.set_language(language)
	await wait_frames(1)


## control -> the text the player sees.
func _shown_texts(controls: Array) -> Dictionary:
	var shown := {}
	for control: Control in controls:
		shown[control] = control.atr(String(control.get("text")))
	return shown


func _every_text_changed(before: Dictionary, after: Dictionary) -> bool:
	return _unchanged(before, after).is_empty()


## The texts that are the same in both, for a failure message.
func _unchanged(before: Dictionary, after: Dictionary) -> String:
	var same := PackedStringArray()
	for control: Control in before:
		if String(before[control]).strip_edges().is_empty():
			continue
		if before[control] == after.get(control, ""):
			same.append("%s=\"%s\"" % [control.name, String(before[control]).left(30)])
	return ", ".join(same)


func _list_texts(list: ItemList) -> PackedStringArray:
	var texts := PackedStringArray()
	for index in list.item_count:
		texts.append(list.get_item_text(index))
	return texts


func _roll_labels(credits: CreditsScreen) -> Array[Control]:
	var labels: Array[Control] = []
	for child in credits.roll.get_children():
		if child is Label:
			labels.append(child)
	return labels
