extends UnboundTest

## Bridge characterization (M1a): the Book of House Rules and player control.
## main._toggle_rule_book flips the Book's visibility and sets
## PlayerTag.control_enabled to the opposite, nothing more. This suite drives it
## with a real B key event and real input actions, and pins what the Book does
## and does NOT do today:
## - it blocks the hero's keys (moves, attacks) while open;
## - it does NOT pause the simulation (steps in flight land, damage applies);
## - it cannot be toggled during a zone trip;
## - a zone trip that ends while it is open hands control back under the open
##   Book. Those last two-sided facts are labelled CHARACTERIZATION: they pin
##   current behaviour, they do not endorse it.

const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "book"

const T1 := &"t1_white_kings_fall"
const T2 := &"t2_fallen_sword_tile"
const SENTINEL_STATUS := "sentinel: nothing has reacted to input"

func _init() -> void:
	suite_title = "BRIDGE BOOK TEST"
	call_deferred("_run")


func _run() -> void:
	var world_state := Support.install_isolated_world_state(self, SUITE_NAME)
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
	_expect(String(hud.objective_label.text).begins_with("The pawn has no weapon yet"), "control group: the attack key reaches the combat system with the Book closed")
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
	await Support.hold_action(self, main, &"skill_1", 0.1)
	_expect(String(hud.objective_label.text) == SENTINEL_STATUS, "attack and skill keys do nothing while the Book is open")

	# --- CHARACTERIZATION: the Book does not pause the simulation ---
	var health_before := Support.player_health(main).current
	Support.damage_player(main, 1)
	_expect(Support.player_health(main).current == health_before - 1, "CHARACTERIZATION: damage still lands while the Book is open (the world is not paused)")
	_expect(Support.hud_courage_pips(main) == health_before - 1, "CHARACTERIZATION: the HUD still reacts to that damage under the open Book")
	Support.wait_out_invulnerability(main)

	# Close it with the key again; control must come back.
	Support.send_key(KEY_B, true)
	Support.pump(main, 0.05)
	Support.send_key(KEY_B, false)
	Support.pump(main, 0.05)
	_expect(not book.visible and Support.player_tag(main).control_enabled, "pressing B again closes the Book and returns control")
	var cell_after_close := Support.player_cell(main)
	await Support.hold_action(self, main, &"move_right", 0.45)
	Support.pump(main, 0.3)
	_expect(Support.player_cell(main).x > cell_after_close.x, "the hero walks again once the Book is closed")
	_reset_hero(main, home_cell)

	# CHARACTERIZATION: a step already in flight when the Book opens still lands.
	var intent: EcsComponents.MoveIntent = Support.ecs_of(main).get_component(Support.player_id_of(main), EcsComponents.MOVE_INTENT)
	intent.direction = Vector2i.RIGHT
	Support.pump(main, 0.05)
	_expect(Support.player_move_state(main).moving, "setup: a step is in flight")
	main._toggle_rule_book()
	_expect(book.visible, "setup: the Book opens mid-step")
	Support.pump(main, 0.4)
	_expect(Support.player_cell(main) == home_cell + Vector2i.RIGHT and not Support.player_move_state(main).moving, "CHARACTERIZATION: a step in flight when the Book opens still completes")
	main._toggle_rule_book()
	_expect(not book.visible and Support.player_tag(main).control_enabled, "the direct toggle closes the Book and returns control too")
	_reset_hero(main, home_cell)

	# --- The Book cannot be toggled during a zone trip ---
	main._travel_to(T2, &"west_entry")
	_expect(bool(main.get("travel_in_progress")), "setup: a zone trip is under way")
	main._toggle_rule_book()
	_expect(not book.visible and not Support.player_tag(main).control_enabled, "toggling during a trip changes nothing (Book stays closed, control stays off)")
	await Support.wait_for_travel(self, main)
	_expect(main.get("current_zone_id") == T2 and Support.player_tag(main).control_enabled and not book.visible, "the trip ends with control on and the Book closed")

	# --- CHARACTERIZATION: a trip that ends under an open Book re-enables control ---
	# A step already landing on the exit when the Book opens still triggers the
	# trip (see the in-flight step above); the rebuilt hero starts with control
	# on, and nothing re-asserts the Book. Likely a defect for the pause work
	# (plan milestone M4); update this block when it is fixed.
	var door := Support.exit_cell(main, main.get("current_room"), &"t3_first_pawn_clash")
	Support.teleport_player(main, door + Vector2i.LEFT)
	var door_intent: EcsComponents.MoveIntent = Support.ecs_of(main).get_component(Support.player_id_of(main), EcsComponents.MOVE_INTENT)
	door_intent.direction = Vector2i.RIGHT
	Support.pump(main, 0.05)
	main._toggle_rule_book()
	_expect(book.visible and not Support.player_tag(main).control_enabled, "setup: the Book is open with the hero stepping onto the exit")
	Support.pump_until(main, func() -> bool: return bool(main.get("travel_in_progress")), 1.0)
	_expect(bool(main.get("travel_in_progress")), "CHARACTERIZATION: the open Book does not stop a trip already triggered by an in-flight step")
	await Support.wait_for_travel(self, main)
	_expect(book.visible, "CHARACTERIZATION: the Book is still open after the trip")
	_expect(Support.player_tag(main).control_enabled, "CHARACTERIZATION: control is back on under the still-open Book (the trip's last step re-enables it)")
	var cell_under_open_book := Support.player_cell(main)
	await Support.hold_action(self, main, &"move_right", 0.45)
	_expect(Support.player_cell(main).x > cell_under_open_book.x, "CHARACTERIZATION: the hero can walk while the Book is open after such a trip")
	main._toggle_rule_book()
	_expect(not book.visible and Support.player_tag(main).control_enabled, "the Book closes normally afterwards")

	Support.end_suite(self, world_state)


## Puts the hero back at rest on a known cell with no queued input.
func _reset_hero(main: Node, cell: Vector2i) -> void:
	Support.pump(main, 0.3)
	Support.teleport_player(main, cell)
	Support.reset_player_input(main)
