extends UnboundTest

## Bridge characterization (M1a, ported in M3b step 2, CHANGED in M4 step 2): the Book of House Rules, player
## control and the freeze. BookBridge (shell/bridges/book_bridge.gd; it was main._toggle_rule_book) flips the
## Book's visibility, sets PlayerTag.control_enabled to the opposite and, since M4, FREEZES THE WORLD while the Book
## is open (plan 4.7: "The world freezes while the Book is open"; a freeze_requested / unfreeze_requested command).
## This suite drives it with a real B key event and real input actions, and pins what the Book does:
## - it blocks the hero's keys (moves, attacks) while open;
## - CHANGED: it freezes the simulation (a step in flight waits, damage waits, nothing is lost: all of it
##   resumes when the Book closes). Until M4 the world kept running under the open Book;
## - it cannot be toggled during a zone trip;
## - CHANGED: a step that would have taken the hero through a door does not start a trip while the Book is open
##   (the world is frozen), so there is no longer a trip that ends under an open Book.

const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "book"

const T1 := &"t1_white_kings_fall"
const T2 := &"t2_fallen_sword_tile"
const SENTINEL_STATUS := "sentinel: nothing has reacted to input"

func _init() -> void:
	suite_title = "BRIDGE BOOK TEST"
	call_deferred("_run")


func _run() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	var main := await Support.boot_main(self)
	var book := main.get_node("RuleBookUI") as RuleBookUI
	var hud := main.get("hud") as GameHud
	var home_cell := Support.player_cell(main)
	_expect(not book.visible and Support.player_tag(main).control_enabled, "the Book starts closed with control on")

	# --- Control group: with the Book closed the same inputs DO act ---
	await Support.hold_action(self, main, &"move_right", 0.45)
	Support.pump(main, 0.5)
	_expect(Support.player_cell(main).x > home_cell.x, "control group: a held move key walks the hero with the Book closed")
	_reset_hero(main, home_cell)
	hud.set_status(SENTINEL_STATUS)
	await Support.hold_action(self, main, &"attack", 0.1)
	_expect(String(hud.objective_line.text_label.text).begins_with("The pawn has no weapon yet"), "control group: the attack key reaches the combat system with the Book closed")
	_reset_hero(main, home_cell)

	# --- Opening the Book with a real B key press ---
	Support.send_key(KEY_B, true)
	Support.pump(main, 0.05)
	Support.send_key(KEY_B, false)
	Support.pump(main, 0.05)
	_expect(book.visible, "pressing B opens the Book")
	_expect(not Support.player_tag(main).control_enabled, "opening the Book switches player control off")

	# --- Input is blocked while it is open ---
	await Support.hold_action(self, main, &"move_right", 0.45)
	Support.pump(main, 0.3)
	_expect(Support.player_cell(main) == home_cell and not Support.player_move_state(main).moving, "a held move key does not move the hero while the Book is open")
	_expect(Support.player_view_position(main) == Support.ecs_of(main).grid.cell_to_world(home_cell), "the hero view does not move either")
	var input_state: EcsComponents.PlayerInput = Support.ecs_of(main).get_component(Support.player_id_of(main), EcsComponents.PLAYER_INPUT)
	_expect(input_state.buffered_direction == Vector2i.ZERO, "no step is buffered behind the open Book")
	hud.set_status(SENTINEL_STATUS)
	await Support.hold_action(self, main, &"attack", 0.1)
	await Support.hold_action(self, main, &"skill_slot_1", 0.1)
	_expect(String(hud.objective_line.text_label.text) == SENTINEL_STATUS, "attack and skill keys do nothing while the Book is open")

	# --- CHANGED (M4 step 2): the Book freezes the simulation ---
	var health_before := Support.player_health(main).current
	var open_world := Support.ecs_of(main)
	_expect(open_world.frozen, "the open Book froze the world (the command reached it on the first tick)")
	Support.damage_player(main, 1)
	_expect(Support.player_health(main).current == health_before, "CHANGED: a hit waits while the Book is open (the world is frozen)")
	_expect(Support.hud_courage_pips(main) == health_before, "CHANGED: and so does the HUD's reaction to it")

	# Close it with the key again; control must come back, the world thaws and the hit that waited lands.
	Support.send_key(KEY_B, true)
	Support.pump(main, 0.05)
	Support.send_key(KEY_B, false)
	Support.pump(main, 0.05)
	_expect(not book.visible and Support.player_tag(main).control_enabled, "pressing B again closes the Book and returns control")
	_expect(not open_world.frozen, "and thaws the world")
	_expect(Support.player_health(main).current == health_before - 1 and Support.hud_courage_pips(main) == health_before - 1, "the hit that waited under the Book lands once it is closed, and the HUD reacts to it")
	Support.wait_out_invulnerability(main)
	var cell_after_close := Support.player_cell(main)
	await Support.hold_action(self, main, &"move_right", 0.45)
	Support.pump(main, 0.3)
	_expect(Support.player_cell(main).x > cell_after_close.x, "the hero walks again once the Book is closed")
	_reset_hero(main, home_cell)

	# CHANGED: a step already in flight when the Book opens waits for it and lands after it closes.
	var intent: EcsComponents.MoveIntent = Support.ecs_of(main).get_component(Support.player_id_of(main), EcsComponents.MOVE_INTENT)
	intent.direction = Vector2i.RIGHT
	Support.pump(main, 0.05)
	_expect(Support.player_move_state(main).moving, "setup: a step is in flight")
	Support.toggle_book(main)
	_expect(book.visible, "setup: the Book opens mid-step")
	Support.pump(main, 0.4)
	_expect(Support.player_cell(main) == home_cell and Support.player_move_state(main).moving, "CHANGED: a step in flight when the Book opens does not complete while it is open")
	Support.toggle_book(main)
	_expect(not book.visible and Support.player_tag(main).control_enabled, "the direct toggle closes the Book and returns control too")
	Support.pump(main, 0.4)
	_expect(Support.player_cell(main) == home_cell + Vector2i.RIGHT and not Support.player_move_state(main).moving, "and the step lands once the Book is closed")
	_reset_hero(main, home_cell)

	# --- The Book cannot be toggled during a zone trip ---
	Support.travel_to(main, T2, &"west_entry")
	_expect(Support.travel_in_progress(main), "setup: a zone trip is under way")
	Support.toggle_book(main)
	_expect(not book.visible and not Support.player_tag(main).control_enabled, "toggling during a trip changes nothing (Book stays closed, control stays off)")
	await Support.wait_for_travel(self, main)
	_expect(main.get("current_zone_id") == T2 and Support.player_tag(main).control_enabled and not book.visible, "the trip ends with control on and the Book closed")

	# --- CHANGED: a step onto a door under an open Book starts no trip ---
	# Until M4 an in-flight step still landed on the exit when the Book opened, the trip ran, and its last step
	# gave the hero control back under the still-open Book. The world is frozen now, so the step waits.
	var door := Support.exit_cell(main, main.get("current_room"), &"t3_first_pawn_clash")
	Support.teleport_player(main, door + Vector2i.LEFT)
	var door_intent: EcsComponents.MoveIntent = Support.ecs_of(main).get_component(Support.player_id_of(main), EcsComponents.MOVE_INTENT)
	door_intent.direction = Vector2i.RIGHT
	Support.pump(main, 0.05)
	Support.toggle_book(main)
	_expect(book.visible and not Support.player_tag(main).control_enabled, "setup: the Book is open with the hero stepping onto the exit")
	Support.pump(main, 1.0)
	_expect(not Support.travel_in_progress(main) and main.get("current_zone_id") == T2, "CHANGED: the open Book lets no trip start: the step onto the door waits")
	Support.toggle_book(main)
	_expect(Support.pump_until(main, func() -> bool: return Support.travel_in_progress(main), 1.0), "and when the Book closes the step lands and the trip starts")
	await Support.wait_for_travel(self, main)
	_expect(main.get("current_zone_id") != T2 and Support.player_tag(main).control_enabled and not book.visible, "the trip ends with control on and the Book closed")

	Support.end_suite(self, save_service)


## Puts the hero back at rest on a known cell with no queued input.
func _reset_hero(main: Node, cell: Vector2i) -> void:
	Support.pump(main, 0.3)
	Support.teleport_player(main, cell)
	Support.reset_player_input(main)
