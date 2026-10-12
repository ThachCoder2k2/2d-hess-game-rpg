extends UnboundTest

## Bridge characterization (M1a): zone travel through scripts/main.gd.
## zone_travel_runtime_test.gd covers the simulation side (a door cell emits
## zone_exit) but never calls main._travel_to. This suite drives the whole
## bridge path through a real exit: the hero steps onto Exit_To_T2, MovementSystem
## emits zone_exit, main._handle_events calls _travel_to, and the fade, zone
## swap, world rebuild and health-carry consumption all run for real.
## It pins CURRENT behaviour so the main.gd split cannot reorder it unnoticed.

const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "travel"

const T1 := &"t1_white_kings_fall"
const T2 := &"t2_fallen_sword_tile"
const T3 := &"t3_first_pawn_clash"

func _init() -> void:
	suite_title = "BRIDGE TRAVEL TEST"
	call_deferred("_run")


func _run() -> void:
	var world_state := Support.install_isolated_world_state(self, SUITE_NAME)
	var main := await Support.boot_main(self)

	# --- Boot baseline (what travel must change) ---
	var room_before: Node = main.get("current_room")
	var room_index_before := room_before.get_index()
	var ecs_before := Support.ecs_of(main)
	var hero_view_before: Node2D = main.get("player_view")
	_expect(main.get("current_zone_id") == T1 and world_state.get("current_zone_id") == T1, "boot starts in T1 and records it in WorldState")
	_expect(Support.player_cell(main) == Support.entry_cell(main, room_before, &"start"), "boot places the hero on T1's start entry")
	_expect(room_before.name == &"CurrentZone", "the authored zone slot is the node named CurrentZone")

	# Hurt the hero first so the carry is distinguishable from a full-health reboot.
	Support.damage_player(main, 1)
	_expect(Support.player_health(main).current == 2, "setup: the hero is down to 2 courage before the trip")
	Support.wait_out_invulnerability(main)

	# --- Walk onto the real exit cell: the whole bridge path runs from the event ---
	var t1_exit := Support.exit_cell(main, room_before, T2)
	_expect(t1_exit != Vector2i(-999, -999) and ecs_before.grid.exit_by_cell.has(t1_exit), "T1's Exit_To_T2 is baked as a door cell")
	_expect(Support.teleport_player(main, t1_exit + Vector2i.LEFT), "setup: the hero stands next to the exit")
	var intent: EcsComponents.MoveIntent = ecs_before.get_component(Support.player_id_of(main), EcsComponents.MOVE_INTENT)
	intent.direction = Vector2i.RIGHT
	var travel_started := Support.pump_until(main, func() -> bool: return bool(main.get("travel_in_progress")), 1.0)
	_expect(travel_started, "stepping onto the exit cell starts a travel through the bridge")

	# --- Ordering at the moment travel starts: persist first, swap only after the fade ---
	_expect(world_state.get("player_health_carry") == 2, "travel start records the hero's current health as the carry")
	_expect(world_state.get("current_zone_id") == T2 and world_state.get("last_entry_id") == &"west_entry", "travel start records the destination zone and entry in WorldState")
	var saved_at_start := Support.read_save_file(world_state)
	_expect(String(saved_at_start.get_value("world", "current_zone_id", "")) == String(T2), "travel start saves the destination to disk before the fade")
	_expect(not Support.player_tag(main).control_enabled, "player control is off for the whole trip")
	_expect(main.get("current_room") == room_before and main.get("ecs") == ecs_before, "the old zone and world are still live while the fade-out runs")
	var travel_ignored_zone: StringName = &"t4_broken_rule_yard"
	main._travel_to(travel_ignored_zone, &"west_entry")
	_expect(world_state.get("current_zone_id") == T2, "a second travel request during a trip is ignored")

	# Watch the fade layer frame by frame: the swap must happen behind a fully
	# black screen, between the fade-out and the fade-in.
	var fade_rect := main.get_node("FadeLayer/FadeRect") as ColorRect
	var highest_fade_alpha := 0.0
	var fade_alpha_at_swap := -1.0
	var wait_started_msec := Time.get_ticks_msec()
	while bool(main.get("travel_in_progress")) and Time.get_ticks_msec() - wait_started_msec < Support.REAL_TIME_WAIT_CAP_MSEC:
		await process_frame
		highest_fade_alpha = maxf(highest_fade_alpha, fade_rect.modulate.a)
		if fade_alpha_at_swap < 0.0 and main.get("current_room") != room_before:
			fade_alpha_at_swap = fade_rect.modulate.a
	_expect(not bool(main.get("travel_in_progress")), "the trip finishes (fade out, swap, boot, fade in)")
	_expect(highest_fade_alpha >= 0.99, "the screen fades fully to black during the trip")
	_expect(fade_alpha_at_swap >= 0.95, "the zone swap happens behind the black screen, not before the fade-out completes")

	# --- After travel: zone swapped, world rebuilt, hero on the entry cell ---
	var room_after: Node = main.get("current_room")
	_expect(room_after != room_before and room_after.get("zone_id") == T2, "CurrentZone swaps to the T2 room")
	_expect(main.get("current_zone_id") == T2, "main reports T2 as the current zone")
	_expect(not is_instance_valid(room_before), "the old T1 room is freed")
	_expect(room_after.get_index() == room_index_before, "the new zone keeps the old zone's slot in the tree")
	var board := main.get("board") as Node
	var hud := main.get("hud") as Node
	_expect(board.get_index() < room_after.get_index() and room_after.get_index() < hud.get_index(), "draw order stays board < zone < HUD after the swap")
	_expect(room_after.name == &"T2_FallenSwordTile", "CHARACTERIZATION: the swapped zone node is named after its scene root, not CurrentZone")
	_expect(main.get_node_or_null("CurrentZone") == null, "CHARACTERIZATION: no node called CurrentZone exists after a swap")
	var ecs_after := Support.ecs_of(main)
	_expect(ecs_after != ecs_before and not is_instance_valid(ecs_before), "a brand new EcsWorld replaces the old one")
	var world_count := 0
	for child in main.get_children():
		if child is EcsWorld:
			world_count += 1
	_expect(world_count == 1, "exactly one EcsWorld is parented to main")
	_expect(ecs_after.systems.size() == 6, "the rebuilt world carries all six systems")
	_expect(main.get("player_view") == hero_view_before, "the hero view node survives the swap (only the simulation is rebuilt)")
	var west_entry := Support.entry_cell(main, room_after, &"west_entry")
	_expect(Support.player_cell(main) == west_entry, "the hero lands on T2's west_entry cell")
	_expect(Support.player_view_position(main) == ecs_after.grid.cell_to_world(west_entry), "the hero view is placed on that cell's world position")
	_expect(ecs_after.grid.exit_by_cell.size() == 2, "T2's two exits are baked into the new world")
	_expect(ecs_after.grid.player_unlock_by_cell.size() == 1, "T2's sword unlock cell is baked into the new world")
	_expect(String(hud.get("objective_label").text).begins_with("A weapon waits"), "the HUD shows T2's start message")

	# --- The health carry: applied by the boot, then consumed ---
	_expect(Support.player_health(main).current == 2, "the carried health (2) is applied to the new hero")
	_expect(world_state.get("player_health_carry") == -1, "the health carry is consumed by the boot")
	_expect(Support.hud_courage_pips(main) == 2, "the HUD courage shows the carried health")
	_expect(Support.player_tag(main).control_enabled and not bool(main.get("travel_in_progress")), "control returns and the trip flag clears")
	_expect(is_zero_approx(fade_rect.modulate.a), "the fade layer is fully transparent again")
	_expect(not bool(main.get("room_ending")) and int(main.get("total_enemies")) == 0, "the new zone starts with a clean encounter state")

	# --- Backtracking: the way back lands on the matching entry marker ---
	# FINDING (content, not bridge): T2's Exit_To_T1 marker sits in the west wall
	# column, which the tilemap paints solid, so the hero cannot walk onto it today.
	# The bridge entry point is driven directly; the wall is only reported.
	var t2_exit_to_t1 := Support.exit_cell(main, room_after, T1)
	_expect(ecs_after.grid.exit_by_cell.has(t2_exit_to_t1), "T2's Exit_To_T1 is baked as a door cell")
	if not ecs_after.grid.is_walkable(t2_exit_to_t1):
		print("NOTE: T2's Exit_To_T1 at %s is a solid wall cell, so the way back is not walkable yet (content issue, not pinned)" % t2_exit_to_t1)
	await main._travel_to(T1, &"from_t2")
	var room_back: Node = main.get("current_room")
	_expect(room_back.get("zone_id") == T1 and main.get("current_zone_id") == T1, "backtracking returns to T1")
	_expect(Support.player_cell(main) == Support.entry_cell(main, room_back, &"from_t2"), "backtracking lands on T1's from_t2 entry")
	_expect(Support.player_health(main).current == 2 and world_state.get("player_health_carry") == -1, "health survives the round trip and the carry is consumed again")
	_expect(world_state.get("current_zone_id") == T1 and world_state.get("last_entry_id") == &"from_t2", "WorldState tracks the return trip")

	# --- Guards: requests the bridge must ignore ---
	var zone_before_guard: StringName = world_state.get("current_zone_id")
	var carry_before_guard: int = world_state.get("player_health_carry")
	await main._travel_to(&"no_such_zone", &"start")
	_expect(world_state.get("current_zone_id") == zone_before_guard and world_state.get("player_health_carry") == carry_before_guard, "a zone id missing from the world graph is ignored without touching WorldState")
	_expect(Support.player_tag(main).control_enabled and not bool(main.get("travel_in_progress")), "an ignored request leaves control on and the trip flag clear")
	main.set("room_ending", true)
	await main._travel_to(T2, &"west_entry")
	_expect(world_state.get("current_zone_id") == zone_before_guard and main.get("current_zone_id") == T1, "no travel starts while the room is ending (death or result screen)")
	main.set("room_ending", false)
	var graph_before: Resource = main.get("world_graph")
	main.set("world_graph", null)
	await main._travel_to(T2, &"west_entry")
	_expect(world_state.get("current_zone_id") == zone_before_guard and main.get("current_zone_id") == T1, "without a world graph (standalone room) no travel starts")
	main.set("world_graph", graph_before)

	# --- A locked door: T3's exit needs the room cleared, so the bridge only talks ---
	await main._travel_to(T3, &"west_entry")
	var room_t3: Node = main.get("current_room")
	_expect(room_t3.get("zone_id") == T3 and int(main.get("total_enemies")) == 1, "setup: T3 holds its single living pawn")
	var t3_locked_exit := Support.exit_cell(main, room_t3, &"t4_broken_rule_yard")
	Support.teleport_player(main, t3_locked_exit + Vector2i.LEFT)
	Support.step_player(main, Vector2i.RIGHT)
	_expect(not bool(main.get("travel_in_progress")) and main.get("current_zone_id") == T3, "a requires_room_clear exit does not travel while an enemy lives")
	_expect(String(hud.get("objective_label").text).begins_with("The captain still holds the rug edge"), "the bridge answers a locked door with the captain message")
	_expect(world_state.get("current_zone_id") == T3, "a locked door leaves WorldState on the current zone")

	Support.end_suite(self, world_state)
