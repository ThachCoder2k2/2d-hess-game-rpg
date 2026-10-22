extends UnboundTest

## A walking key held through a door must not carry the pawn straight back out (the M5 review, real-input defect 2).
## The entry cell of many rooms stands one step from the door the pawn came by (14 of the world's 194 door approaches:
## the Toybox nook and tb4 stand door to door), so a key that stayed down through the trip went on walking in the new
## room and the pawn bounced between two rooms: nine trips in six seconds at the nook, and the one-way shortcut from the
## Dollhouse dropped the pawn back into the Dollhouse. InputPoller.require_fresh_press() (GameRoot calls it each time it
## builds a room's world) holds a control that was already down when the room began released until it is let go.
##
## Through the real scene and the real bridges, with the walking key held on the real Input singleton the whole way:
##   1. in tb4 the hero walks LEFT through the nook door with the key down; in tbo the key stays down for seconds and the
##      hero does not move, so no trip starts (the door back is one step ahead of the arrival cell);
##   2. letting go and pressing again is a fresh press: that one walks onto the door back, and the trip home happens;
##   3. the same hold for a respawn: the key down through the menu's Restart Room does not walk the pawn in the new room.
## Without the fix step 1 fails: the key repeat steps onto the door back 0.22 s after the room begins.

const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "held_key_through_a_door"

const TB4 := &"tb4_lid_path"
const TBO := &"tbo_crayon_cache"

## How long the key stays down in the new room: ten times the key repeat's delay of 0.22 s.
const HOLD_SECONDS := 2.2


func _init() -> void:
	suite_title = "HELD KEY THROUGH A DOOR TEST"
	watchdog_seconds = 40.0
	call_deferred("_run")


func _run() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	var main := await Support.boot_main(self)
	await Support.travel_to(main, TB4, &"from_tbb")
	_expect(main.get("current_zone_id") == TB4, "setup: the hero is in the Lid Path (tb4)")
	var nook_door := Support.exit_cell(main, main.get("current_room"), TBO)
	_expect(nook_door == Vector2i(1, 5), "setup: the nook door stands at the west end of the lower lane")
	_expect(Support.teleport_player(main, nook_door + Vector2i.RIGHT * 2), "setup: the hero stands two cells east of it")

	# 1. The key goes down and stays down through the door.
	Input.action_press(&"move_left")
	_expect(Support.pump_until(main, func() -> bool: return Support.travel_in_progress(main), 4.0), "the held key walks the hero onto the nook door and the trip starts")
	_expect(await Support.wait_for_travel(self, main) and main.get("current_zone_id") == TBO, "the trip ends in the nook (tbo), the key still down")
	var arrival := Support.entry_cell(main, main.get("current_room"), &"from_tb4")
	_expect(Support.player_cell(main) == arrival, "the hero arrives on the entry cell %s" % arrival)
	var door_back := Support.exit_cell(main, main.get("current_room"), TB4)
	_expect(door_back == arrival + Vector2i.LEFT, "setup: the door back to tb4 is one step LEFT of the arrival cell, the way the key points")
	Support.pump(main, HOLD_SECONDS)
	_expect(main.get("current_zone_id") == TBO and not Support.travel_in_progress(main), "the key stays down for %.1f s in the nook and no trip starts" % HOLD_SECONDS)
	_expect(Support.player_cell(main) == arrival and not Support.player_move_state(main).moving, "and the hero has not moved from the entry cell")

	# 2. Let go and press again: a fresh press.
	Input.action_release(&"move_left")
	await process_frame
	Support.pump(main, Support.SIM_STEP_SECONDS)
	_expect(await Support.tap_direction(self, main, Vector2i.LEFT) and Support.travel_in_progress(main), "a fresh press of the same key walks onto the door back and a trip starts")
	_expect(await Support.wait_for_travel(self, main) and main.get("current_zone_id") == TB4, "and the trip home ends in tb4")

	# 3. A respawn with the key down.
	Support.teleport_player(main, Vector2i(5, 5))
	Support.reset_player_input(main)
	Input.action_press(&"move_right")
	Support.pump(main, Support.SIM_STEP_SECONDS)
	Support.restart_room_from_the_menu(main)
	_expect(await Support.wait_for_respawn(self, main), "the pause menu's Restart Room rebuilds the room while the key is down")
	var respawn_cell := Support.player_cell(main)
	Support.pump(main, HOLD_SECONDS)
	_expect(Support.player_cell(main) == respawn_cell and not Support.player_move_state(main).moving, "the key held through the respawn does not walk the pawn in the new room")
	Input.action_release(&"move_right")
	await process_frame
	Support.pump(main, Support.SIM_STEP_SECONDS)
	_expect(await Support.tap_direction(self, main, Vector2i.RIGHT) and Support.player_cell(main) == respawn_cell + Vector2i.RIGHT, "and a fresh press steps it at once")
	Support.end_suite(self, save_service)
