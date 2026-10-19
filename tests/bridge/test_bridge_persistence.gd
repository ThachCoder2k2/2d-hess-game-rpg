extends UnboundTest

## Bridge characterization (M1a, ported to the SaveService in M3b): what the world remembers.
## game_root.gd translates three kinds of simulation events into writes to the run held by
## the SaveService (pickup_taken, gate_opened, player_unlock) and feeds the run back into
## every _boot_zone (taken pickups never respawn, opened gates boot as floor,
## the sword unlock re-applies). This suite drives each of them through the
## real path, then proves the memory survives a re-boot of the zone, a
## save/load round trip, and a full relaunch (a brand new main continuing the
## saved run by itself).
##
## Sources of each event, all real: the hero stepping on the T2 unlock cell and
## pushing the kingdom's gates (MovementSystem), and a T4 pawn standing on the
## spear (EnemyAISystem._collect_local_item, the one place pickups are taken).

const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "persistence"

const T1 := &"t1_white_kings_fall"
const T2 := &"t2_fallen_sword_tile"
const T4 := &"t4_broken_rule_yard"
const KINGDOM := &"kingdom"
const SPEAR_KEY := "t4_broken_rule_yard/PencilSpearPickup"

var save_service: Node


func _init() -> void:
	suite_title = "BRIDGE PERSISTENCE TEST"
	call_deferred("_run")


func _run() -> void:
	save_service = Support.install_isolated_save_service(self, SUITE_NAME)
	var main := await Support.boot_main(self)

	await _check_player_unlock(main)
	await _check_taken_pickup(main)
	await _check_opened_gate(main)
	main = await _check_relaunch(main)

	Support.end_suite(self, save_service)


## --- Player unlock: the T2 wooden sword ------------------------------------


func _check_player_unlock(main: Node) -> void:
	_expect(Support.player_combat(main) != null and not Support.player_combat(main).sword_unlocked, "unlock: a fresh run starts without the sword")
	_expect(not Support.run_of(save_service).has_unlock(&"wooden_sword"), "unlock: the run starts without the wooden_sword unlock")
	_expect(await Support.walk_through_exit(self, main, T2, Vector2i.RIGHT), "unlock: the hero travels T1 -> T2 through the real exit")
	var marker := _first_unlock_marker(main)
	_expect(marker != null and marker.visible and not Support.player_combat(main).sword_unlocked, "unlock: T2 shows the sword marker and the hero is still unarmed")
	var unlock_cell := _only_unlock_cell(main)
	Support.teleport_player(main, unlock_cell + Vector2i.LEFT)
	Support.step_player(main, Vector2i.RIGHT)
	_expect(Support.player_cell(main) == unlock_cell, "unlock: the hero stands on the sword cell")

	_expect(Support.run_of(save_service).has_unlock(&"wooden_sword"), "unlock: stepping on the cell records the unlock in the run")
	_expect(Support.player_combat(main).sword_unlocked, "unlock: the live hero can use the sword at once")
	_expect(not marker.visible, "unlock: the marker is hidden once taken")
	_expect(String((main.get("hud") as GameHud).objective_label.text).begins_with("The child whispers"), "unlock: the HUD shows the marker's message")
	_expect(_saved_list("player", "unlocked_skill_ids").has("wooden_sword"), "unlock: the unlock is written to the save file immediately")

	# Persists across a re-boot of the zone (the same path every travel and death uses).
	await main._travel_to(T2, &"west_entry")
	_expect(Support.player_combat(main).sword_unlocked, "unlock: the sword survives re-entering the zone")
	_expect(not _first_unlock_marker(main).visible, "unlock: the taken marker stays hidden after re-entering")
	main._boot_zone(&"west_entry")
	_expect(Support.player_combat(main).sword_unlocked, "unlock: the sword survives a bare _boot_zone")

	# Persists across a save/load round trip; and the lock really is save-driven.
	Support.write_the_run(save_service)
	Support.forget_the_run(save_service)
	_expect(not Support.run_of(save_service).has_unlock(&"wooden_sword"), "unlock: reset clears the flag (the check below is meaningful)")
	save_service.call("load_slot")
	_expect(Support.run_of(save_service).has_unlock(&"wooden_sword"), "unlock: load_state restores the flag from disk")
	await main._travel_to(T2, &"west_entry")
	_expect(Support.player_combat(main).sword_unlocked and not _first_unlock_marker(main).visible, "unlock: a boot after the round trip is armed with the marker hidden")


## --- Taken pickup: the T4 pencil spear ----------------------------------------


func _check_taken_pickup(main: Node) -> void:
	await main._travel_to(T4, &"west_entry")
	var ecs := Support.ecs_of(main)
	var cast: Dictionary = main.get("cast")
	var item_cells := ecs.grid.get_item_cells()
	_expect(main.get("current_zone_id") == T4 and item_cells.size() == 1, "pickup: T4 boots with its one spear on the floor")
	var item_id := ecs.grid.item_at(item_cells[0])
	_expect(String(cast["pickup_name_by_entity"].get(item_id, "")) == "PencilSpearPickup" and cast["pickup_view_by_entity"].has(item_id), "pickup: the item has a stable marker name and a view")
	_expect(not Support.run_of(save_service).taken_pickup_ids.has(SPEAR_KEY), "pickup: nothing is recorded as taken yet")
	var rule_ids: Dictionary = Support.run_of(save_service).unlocked_rule_ids
	_expect(rule_ids.size() >= 3 and rule_ids.has("pawn_recruit"), "pickup: meeting T4's pieces writes their Book pages")
	var spear_view := cast["pickup_view_by_entity"][item_id] as Node2D

	# A pawn standing on the spear takes it (real EnemyAISystem code path).
	var enemy_id: int = cast["enemies"][0]
	var enemy_ai := Support.remove_enemy_ai(main) as EnemyAISystem
	_expect(enemy_ai != null, "pickup: setup found the enemy AI system")
	var enemy_pos: EcsComponents.GridPos = ecs.get_component(enemy_id, EcsComponents.GRID_POS)
	enemy_pos.cell = item_cells[0]
	enemy_ai.call("_collect_local_item", enemy_id)
	main._handle_events(ecs.drain_events())

	_expect(Support.run_of(save_service).taken_pickup_ids.has(SPEAR_KEY), "pickup: the bridge records the pickup under zone/marker name")
	_expect(not cast["pickup_view_by_entity"].has(item_id) and spear_view.is_queued_for_deletion(), "pickup: the bridge frees the floor view")
	_expect(String((main.get("hud") as GameHud).objective_label.text).contains("picked up"), "pickup: the HUD announces the weapon change")
	_expect(_saved_list("world", "taken_pickup_ids").has(SPEAR_KEY), "pickup: the taken pickup is written to the save file immediately")
	_expect(_saved_list("world", "unlocked_rule_ids").has("pawn_recruit"), "pickup: the Book pages from meeting T4's pieces are saved too")

	# Never respawns: re-boot, bare _boot_zone, save/load.
	await main._travel_to(T4, &"west_entry")
	_expect(Support.ecs_of(main).grid.get_item_cells().is_empty() and main.get("cast")["pickup_name_by_entity"].is_empty(), "pickup: the spear does not respawn after re-entering T4")
	_expect(main.get("cast")["pickup_view_by_entity"].is_empty(), "pickup: no floor view is rebuilt for the taken spear")
	main._boot_zone(&"west_entry")
	_expect(Support.ecs_of(main).grid.get_item_cells().is_empty(), "pickup: the spear does not respawn after a bare _boot_zone")
	Support.write_the_run(save_service)
	Support.forget_the_run(save_service)
	save_service.call("load_slot")
	_expect(Support.run_of(save_service).taken_pickup_ids.has(SPEAR_KEY) and Support.run_of(save_service).unlocked_rule_ids.has("pawn_recruit"), "pickup: load_state restores the taken pickup and the Book pages")
	await main._travel_to(T4, &"west_entry")
	_expect(Support.ecs_of(main).grid.get_item_cells().is_empty(), "pickup: the spear stays gone after the save/load round trip")

	# Zone-scoped: the same marker name taken elsewhere does not hide this spear.
	Support.run_of(save_service).taken_pickup_ids.erase(SPEAR_KEY)
	Support.run_of(save_service).taken_pickup_ids["some_other_zone/PencilSpearPickup"] = true
	await main._travel_to(T4, &"west_entry")
	_expect(Support.ecs_of(main).grid.get_item_cells().size() == 1, "pickup: ids are zone-scoped (another zone's spear name does not hide this one)")
	Support.run_of(save_service).taken_pickup_ids.erase("some_other_zone/PencilSpearPickup")
	Support.run_of(save_service).taken_pickup_ids[SPEAR_KEY] = true
	Support.write_the_run(save_service)

	# The Book pages are visible in the Book after a boot.
	var book := main.get_node("RuleBookUI") as RuleBookUI
	_expect(book.unlocked_piece_ids.has(&"pawn_recruit"), "pickup: a boot feeds the unlocked pages to the Book")


## --- Opened gate: the kingdom's shortcuts -------------------------------------


func _check_opened_gate(main: Node) -> void:
	await main._travel_to(KINGDOM, &"start")
	Support.remove_enemy_ai(main)
	var ecs := Support.ecs_of(main)
	var pass_gate := _gate_marker(main, &"pass_home_gate")
	var lane_gate := _gate_marker(main, &"gardens_lane_gate")
	_expect(pass_gate != null and lane_gate != null and ecs.grid.gate_by_cell.size() == 2, "gate: both kingdom shortcut gates start closed")
	_expect(pass_gate.visible and lane_gate.visible, "gate: both closed-gate visuals are showing")
	var gate_cell := ecs.grid.world_to_cell(pass_gate.position)
	_expect(not ecs.grid.is_walkable(gate_cell), "gate: the closed gate blocks its cell")

	# Pushing from the wrong side stays a wall and records nothing.
	Support.teleport_player(main, gate_cell + pass_gate.opens_from)
	Support.step_player(main, -pass_gate.opens_from)
	_expect(Support.run_of(save_service).opened_gate_ids.is_empty() and not ecs.grid.is_walkable(gate_cell), "gate: pushing from the wrong side opens nothing")

	# Pushing from the far side opens it for good.
	_expect(Support.teleport_player(main, gate_cell - pass_gate.opens_from), "gate: setup stands the hero on the far side")
	Support.step_player(main, pass_gate.opens_from)
	_expect(Support.player_cell(main) == gate_cell, "gate: the hero walks onto the opened gate cell")
	_expect(Support.run_of(save_service).opened_gate_ids.has("pass_home_gate") and Support.run_of(save_service).opened_gate_ids.size() == 1, "gate: the bridge records exactly the opened gate id")
	_expect(not pass_gate.visible and lane_gate.visible, "gate: only the opened gate's visual disappears")
	_expect(ecs.grid.is_walkable(gate_cell) and ecs.grid.gate_by_cell.size() == 1, "gate: the opened cell is floor and the other gate is still closed")
	_expect(String((main.get("hud") as GameHud).objective_label.text).begins_with("The gate unbars"), "gate: the HUD announces the opening")
	_expect(_saved_list("world", "opened_gate_ids").has("pass_home_gate"), "gate: the opened gate is written to the save file immediately")

	# Persists across a re-boot, a bare _boot_zone and a save/load round trip.
	await main._travel_to(KINGDOM, &"start")
	ecs = Support.ecs_of(main)
	pass_gate = _gate_marker(main, &"pass_home_gate")
	lane_gate = _gate_marker(main, &"gardens_lane_gate")
	_expect(ecs.grid.is_walkable(gate_cell) and ecs.grid.gate_by_cell.size() == 1 and not pass_gate.visible and lane_gate.visible, "gate: re-entering keeps the pass gate open and the lane gate closed")
	main._boot_zone(&"start")
	_expect(Support.ecs_of(main).grid.is_walkable(gate_cell) and not _gate_marker(main, &"pass_home_gate").visible, "gate: a bare _boot_zone keeps the pass gate open")
	Support.write_the_run(save_service)
	Support.forget_the_run(save_service)
	_expect(Support.run_of(save_service).opened_gate_ids.is_empty(), "gate: reset forgets the gate (the check below is meaningful)")
	save_service.call("load_slot")
	_expect(Support.run_of(save_service).opened_gate_ids.has("pass_home_gate"), "gate: load_state restores the opened gate from disk")
	await main._travel_to(KINGDOM, &"start")
	_expect(Support.ecs_of(main).grid.is_walkable(gate_cell) and Support.ecs_of(main).grid.gate_by_cell.size() == 1, "gate: a boot after the round trip still has the pass gate open")
	Support.write_the_run(save_service)


## --- Relaunch: a brand new main booting from the loaded save --------------------


func _check_relaunch(old_main: Node) -> Node:
	var ecs_before := Support.ecs_of(old_main)
	var gate_cell: Vector2i = ecs_before.grid.world_to_cell(_gate_marker(old_main, &"pass_home_gate").position)
	Support.write_the_run(save_service)
	old_main.free()
	Support.forget_the_run(save_service)
	_expect(Support.run_of(save_service).checkpoint_zone_id == &"" and Support.run_of(save_service).taken_pickup_ids.is_empty() and not save_service.get("has_session"), "relaunch: setup cleared the in-memory world (as a fresh process would start: no run has begun)")
	var main := await Support.boot_main(self)
	_expect(save_service.get("has_session") and save_service.get("last_load").outcome == SaveLoadResult.LOADED, "relaunch: the new main continues the saved run by itself (nothing loaded it for the test)")
	_expect(main.get("current_zone_id") == KINGDOM and main.get("current_room").get("zone_id") == KINGDOM, "relaunch: the new main boots straight into the saved zone")
	_expect(Support.player_cell(main) == Support.entry_cell(main, main.get("current_room"), &"start"), "relaunch: the hero stands on the saved entry")
	_expect(Support.player_combat(main).sword_unlocked, "relaunch: the sword unlock is applied to the new hero")
	_expect(Support.ecs_of(main).grid.is_walkable(gate_cell), "relaunch: the opened gate boots as floor")
	_expect(Support.ecs_of(main).grid.gate_by_cell.size() == 1, "relaunch: the other gate is still closed")
	await main._travel_to(T4, &"west_entry")
	_expect(Support.ecs_of(main).grid.get_item_cells().is_empty(), "relaunch: the taken spear is still gone")
	return main


## --- Helpers ---------------------------------------------------------------------


func _saved_list(section: String, key: String) -> Array:
	return Support.read_save_file(save_service).get_value(section, key, [])


func _first_unlock_marker(main: Node) -> PlayerUnlockMarker:
	for child in (main.get("current_room") as Node).get_children():
		var marker := child as PlayerUnlockMarker
		if marker != null:
			return marker
	return null


func _only_unlock_cell(main: Node) -> Vector2i:
	var cells: Array = Support.ecs_of(main).grid.player_unlock_by_cell.keys()
	return cells[0] if cells.size() == 1 else Vector2i(-999, -999)


func _gate_marker(main: Node, gate_id: StringName) -> GateMarker:
	for child in (main.get("current_room") as Node).get_children():
		var gate := child as GateMarker
		if gate != null and gate.gate_id == gate_id:
			return gate
	return null
