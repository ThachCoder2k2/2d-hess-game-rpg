extends UnboundTest

## Backtracking through the real scene (found in the review of M3b): the pawn can walk BACK through every
## room of Stage 1. The way back used to be impossible on foot: the return doors stood on the wall column
## of each room (a solid cell), and the old suites reached the previous room by calling the travel function.
##
## Here nothing is called and nothing is teleported on the way: the hero arrives in a room by a door, a
## simulated player taps the arrow keys along the shortest path to the west door (Support.walk_through_door:
## the real input path, the real grid, the real MovementSystem, ZoneTravelBridge, the fade and the swap) and
## the next room has the hero on the entry that door names. Three walks are made:
##   1. the short one: arriving in T2 by its west entry, one step west is the door back to T1;
##   2. T3 -> T2, the one the review named: arriving by T3's EAST door (the far side of the room, the way a
##      pawn that has just cleared T4 comes back), across the whole room to the west door;
##   3. the whole way home, H1 -> B1 -> T4 -> T3 -> T2 -> T1, each room crossed from its east entry to its
##      west door, every arrival checked against the entry marker the door names and against the run.
## The rooms' own enemies stand still (EnemyAISystem removed after each boot): the walk is not a fight.

const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "backtracking"

const T1 := &"t1_white_kings_fall"
const T2 := &"t2_fallen_sword_tile"
const T3 := &"t3_first_pawn_clash"
const T4 := &"t4_broken_rule_yard"
const B1 := &"b1_black_pawn_captain"
const H1 := &"h1_chess_rug_hub"

## The way home: the room the pawn is in, the room its west door leads back to, and the entry marker of that
## room the door names. Each pair is one walk.
const WAY_HOME := [
	[H1, B1, &"from_hub"],
	[B1, T4, &"from_b1"],
	[T4, T3, &"from_t4"],
	[T3, T2, &"from_t3"],
	[T2, T1, &"from_t2"],
]


func _init() -> void:
	suite_title = "BRIDGE BACKTRACKING TEST"
	watchdog_seconds = 55.0
	call_deferred("_run")


func _run() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	var main := await Support.boot_main(self)

	# --- 1. The short walk: T1 -> T2 on foot, then one step west is the door back ---
	_expect(main.get("current_zone_id") == T1, "setup: the run starts in T1")
	_expect(await Support.walk_through_door(self, main, T2), "the hero walks from T1's start to its east door and through it")
	var t2_west_entry := Support.entry_cell(main, main.get("current_room"), &"west_entry")
	_expect(main.get("current_zone_id") == T2 and Support.player_cell(main) == t2_west_entry, "and stands on T2's west entry")
	var t2_door_back := Support.exit_cell(main, main.get("current_room"), T1)
	_expect(t2_door_back == t2_west_entry + Vector2i.LEFT, "T2's door back to T1 is the cell next to the west entry: one step west")
	_expect(Support.ecs_of(main).grid.is_walkable(t2_door_back), "and that cell is floor the hero can stand on")
	_expect(await Support.tap_direction(self, main, Vector2i.LEFT) and await Support.wait_for_travel(self, main), "one tap of the left arrow starts the trip back and it finishes")
	_expect_arrival(main, save_service, T1, &"from_t2", "T2 -> T1 by one step")

	# --- 2. T3 -> T2 across the whole room, from the far (east) side ---
	await Support.travel_to(main, T3, &"from_t4")
	Support.remove_enemy_ai(main)
	var t3_far_entry := Support.player_cell(main)
	var t3_door_back := Support.exit_cell(main, main.get("current_room"), T2)
	_expect(t3_far_entry == Support.entry_cell(main, main.get("current_room"), &"from_t4") and t3_far_entry.x > 8 and t3_door_back.x < 4, "setup: the hero stands at T3's east end and the door back to T2 is at the west end (%s -> %s)" % [t3_far_entry, t3_door_back])
	var steps_west := ecs_walk_length(main, t3_far_entry, t3_door_back)
	_expect(steps_west >= 12, "and the way across is a real walk (%d steps)" % steps_west)
	var t3_ecs_before := Support.ecs_of(main)
	_expect(await Support.walk_through_door(self, main, T2), "the hero walks across T3 on foot to the door back to T2 and through it")
	_expect(Support.ecs_of(main) != t3_ecs_before and main.get("current_zone_id") == T2, "the world was rebuilt: the hero is in T2")
	_expect_arrival(main, save_service, T2, &"from_t3", "T3 -> T2 on foot")

	# --- 3. The whole way home, room by room ---
	await Support.travel_to(main, H1, &"from_boss")
	Support.remove_enemy_ai(main)
	for leg: Array in WAY_HOME:
		var from_zone: StringName = leg[0]
		var to_zone: StringName = leg[1]
		var arrival_entry: StringName = leg[2]
		if not _expect(main.get("current_zone_id") == from_zone, "the hero is in %s, about to walk back to %s" % [from_zone, to_zone]):
			break
		if from_zone != H1:
			Support.remove_enemy_ai(main)
		_expect(await Support.walk_through_door(self, main, to_zone), "%s -> %s: the hero walks to the west door and through it" % [from_zone, to_zone])
		_expect_arrival(main, save_service, to_zone, arrival_entry, "%s -> %s on foot" % [from_zone, to_zone])
	_expect(main.get("current_zone_id") == T1, "the whole way home ends where the run began, in T1")

	Support.end_suite(self, save_service)


## The hero is in `zone_id`, on the entry marker `entry_id`, in control, with the run naming that room and entry.
func _expect_arrival(main: Node, save_service: Node, zone_id: StringName, entry_id: StringName, label: String) -> void:
	_expect(main.get("current_zone_id") == zone_id and not Support.travel_in_progress(main), "%s: the hero is in %s and the trip is over" % [label, zone_id])
	_expect(Support.player_cell(main) == Support.entry_cell(main, main.get("current_room"), entry_id), "%s: on the entry '%s' the door names" % [label, entry_id])
	_expect(Support.player_tag(main).control_enabled, "%s: and in control again" % label)
	_expect(Support.run_of(save_service).room_id == zone_id and Support.run_of(save_service).room_entry_id == entry_id, "%s: the run names that room and entry" % label)


## How many steps the shortest walk from `from_cell` to `to_cell` takes on the room's grid, -1 when there is none.
func ecs_walk_length(main: Node, from_cell: Vector2i, to_cell: Vector2i) -> int:
	var path := Support.ecs_of(main).grid.get_grid_path(Support.player_id_of(main), from_cell, to_cell)
	return path.size() - 1 if not path.is_empty() else -1
