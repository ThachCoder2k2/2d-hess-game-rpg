extends UnboundTest

## Bridge characterization (M1a, ported to the SaveService in M3b): what the world remembers.
## SaveBridge (shell/bridges/save_bridge.gd) translates three kinds of simulation events into writes to the run held by
## the SaveService (pickup_taken, gate_opened, player_unlock) and feeds the run back into
## every boot_zone (taken pickups never respawn, opened gates boot as floor,
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
## Every reason the run was saved for, in order (the service's autosaved signal).
var saved_reasons: Array[StringName] = []
## How many player_unlock events the scene's router has handed out.
var unlock_events_seen := 0
## The world graph's own T4 scene, kept while a test swaps in a copy whose spear is a persistent pickup.
var original_t4_scene: PackedScene
## The world graph that was edited, held so that it is not unloaded (and reloaded unedited) when a scene is freed.
var edited_world_graph: WorldGraph


func _init() -> void:
	suite_title = "BRIDGE PERSISTENCE TEST"
	call_deferred("_run")


func _run() -> void:
	save_service = Support.install_isolated_save_service(self, SUITE_NAME)
	save_service.autosaved.connect(func(_slot: int, reason: StringName) -> void: saved_reasons.append(reason))
	var main := await Support.boot_main(self)
	_add_the_kingdom_fixture_to(main.get("world_graph"))
	(main.get("router") as EventRouter).on(Events.PLAYER_UNLOCK, func(_event: Dictionary) -> void: unlock_events_seen += 1)

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
	_expect(String((main.get("hud") as GameHud).objective_line.text_label.text).begins_with("The child whispers"), "unlock: the HUD shows the marker's message")
	_expect(_saved_list("player", "unlocked_skill_ids").has("wooden_sword"), "unlock: the unlock is written to the save file immediately")
	_expect(saved_reasons.count(&"unlock_gained") == 1 and unlock_events_seen == 1, "unlock: the first step onto the cell raised one event and saved once, for unlock_gained (%s)" % [saved_reasons])

	# The cell stays a trigger after it was taken (the marker is hidden, not removed): stepping off and on
	# again raises the event again, and that is no success event, so nothing is saved a second time.
	var saves_before_the_second_step := saved_reasons.size()
	Support.step_player(main, Vector2i.LEFT)
	Support.step_player(main, Vector2i.RIGHT)
	_expect(Support.player_cell(main) == unlock_cell and unlock_events_seen == 2, "unlock: stepping back onto the taken cell raises the event again (%d events)" % unlock_events_seen)
	_expect(saved_reasons.size() == saves_before_the_second_step, "unlock: and saves nothing, the unlock was already the run's (%s)" % [saved_reasons])
	_expect(Support.player_combat(main).sword_unlocked and Support.run_of(save_service).player.unlocked_skill_ids.count(&"wooden_sword") == 1, "unlock: the sword is still in the hand and is listed once in the run")

	# Persists across a re-boot of the zone (the same path every travel and death uses).
	await Support.travel_to(main, T2, &"west_entry")
	_expect(Support.player_combat(main).sword_unlocked, "unlock: the sword survives re-entering the zone")
	_expect(not _first_unlock_marker(main).visible, "unlock: the taken marker stays hidden after re-entering")
	Support.reboot_zone(main, &"west_entry")
	_expect(Support.player_combat(main).sword_unlocked, "unlock: the sword survives a bare boot_zone")

	# Persists across a save/load round trip; and the lock really is save-driven.
	Support.write_the_run(save_service)
	Support.forget_the_run(save_service)
	_expect(not Support.run_of(save_service).has_unlock(&"wooden_sword"), "unlock: reset clears the flag (the check below is meaningful)")
	save_service.call("load_slot")
	_expect(Support.run_of(save_service).has_unlock(&"wooden_sword"), "unlock: load_state restores the flag from disk")
	await Support.travel_to(main, T2, &"west_entry")
	_expect(Support.player_combat(main).sword_unlocked and not _first_unlock_marker(main).visible, "unlock: a boot after the round trip is armed with the marker hidden")


## --- Taken pickup: the T4 pencil spear ----------------------------------------
## D-16: a floor weapon is room-local, so an enemy taking it is no fact for the run and the room puts it
## back on the floor whenever it starts again. Only a PERSISTENT pickup (PickupSpawnPoint.persistent) is
## remembered, saved and never comes back. The T4 spear is a floor weapon; to drive the persistent half, the
## test marks the live room's marker persistent before the next boot, which is what the owner would do in the
## Inspector on a reward.


func _check_taken_pickup(main: Node) -> void:
	await Support.travel_to(main, T4, &"west_entry")
	var ecs := Support.ecs_of(main)
	var cast: Dictionary = main.get("cast")
	var item_cells := ecs.grid.get_item_cells()
	_expect(main.get("current_zone_id") == T4 and item_cells.size() == 1, "pickup: T4 boots with its one spear on the floor")
	var item_id := ecs.grid.item_at(item_cells[0])
	_expect(String(cast["pickup_name_by_entity"].get(item_id, "")) == "PencilSpearPickup" and cast["pickup_view_by_entity"].has(item_id), "pickup: the item has a stable marker name and a view")
	_expect(cast["persistent_pickup_by_entity"].is_empty(), "pickup: the spear is a floor weapon of its room, not a persistent reward")
	_expect(not Support.run_of(save_service).taken_pickup_ids.has(SPEAR_KEY), "pickup: nothing is recorded as taken yet")
	var rule_ids: Dictionary = Support.run_of(save_service).unlocked_rule_ids
	_expect(rule_ids.size() >= 3 and rule_ids.has("pawn_recruit"), "pickup: meeting T4's pieces writes their Book pages")
	var spear_view := cast["pickup_view_by_entity"][item_id] as Node2D

	# A pawn standing on the spear takes it (real EnemyAISystem code path).
	var enemy_id: int = cast["enemies"][0]
	var enemy_ai := Support.remove_enemy_ai(main) as EnemyAISystem
	_expect(enemy_ai != null, "pickup: setup found the enemy AI system")
	_expect(_pawn_takes_the_spear(main, enemy_ai, enemy_id, item_cells[0]), "pickup: the pawn picked the spear up")
	_expect(not Support.run_of(save_service).taken_pickup_ids.has(SPEAR_KEY), "CHANGED (D-16): a floor weapon taken by an enemy is not written into the run")
	_expect(not cast["pickup_view_by_entity"].has(item_id) and spear_view.is_queued_for_deletion(), "pickup: the bridge still frees the floor view")
	_expect(String((main.get("hud") as GameHud).objective_line.text_label.text).contains("picked up"), "pickup: the HUD announces the weapon change")
	_expect(not _saved_list("world", "taken_pickup_ids").has(SPEAR_KEY), "CHANGED (D-16, R17): and nothing is saved for it, it is not a success event")

	# Room-local: back on the floor when the room starts again (re-entering, a bare boot_zone, a relaunch).
	await Support.travel_to(main, T4, &"west_entry")
	_expect(Support.ecs_of(main).grid.get_item_cells().size() == 1 and main.get("cast")["pickup_name_by_entity"].size() == 1, "CHANGED (D-16): the spear is back on the floor after re-entering T4")
	_expect(main.get("cast")["pickup_view_by_entity"].size() == 1, "pickup: and its floor view is rebuilt")
	Support.reboot_zone(main, &"west_entry")
	_expect(Support.ecs_of(main).grid.get_item_cells().size() == 1, "CHANGED (D-16): and after a bare boot_zone")
	Support.write_the_run(save_service)
	Support.forget_the_run(save_service)
	save_service.call("load_slot")
	_expect(not Support.run_of(save_service).taken_pickup_ids.has(SPEAR_KEY) and Support.run_of(save_service).unlocked_rule_ids.has("pawn_recruit"), "pickup: a save/load round trip keeps the Book pages and no taken floor weapon")

	# A persistent pickup is remembered, saved, and never comes back.
	var spear_marker := (main.get("current_room") as Node).get_node("PencilSpearPickup") as PickupSpawnPoint
	spear_marker.persistent = true
	Support.reboot_zone(main, &"west_entry")
	ecs = Support.ecs_of(main)
	cast = main.get("cast")
	item_cells = ecs.grid.get_item_cells()
	item_id = ecs.grid.item_at(item_cells[0])
	_expect(cast["persistent_pickup_by_entity"].has(item_id), "persistent: a marker with persistent set is booted as a persistent pickup")
	enemy_id = cast["enemies"][0]
	enemy_ai = Support.remove_enemy_ai(main) as EnemyAISystem
	_expect(_pawn_takes_the_spear(main, enemy_ai, enemy_id, item_cells[0]), "persistent: the pawn picked the spear up")
	_expect(Support.run_of(save_service).taken_pickup_ids.has(SPEAR_KEY), "persistent: the bridge records the pickup under zone/marker name")
	_expect(_saved_list("world", "taken_pickup_ids").has(SPEAR_KEY), "persistent: the taken pickup is written to the save file immediately")
	_expect(_saved_list("world", "unlocked_rule_ids").has("pawn_recruit"), "persistent: the Book pages from meeting T4's pieces are saved too")

	# Never respawns: re-boot, bare boot_zone, save/load. Re-entering builds the room from its scene again, so
	# the scene must carry a persistent spear: the test swaps in a copy of T4 whose marker is persistent.
	_make_t4_spear_persistent(main, true)
	await Support.travel_to(main, T4, &"west_entry")
	_expect(Support.ecs_of(main).grid.get_item_cells().is_empty() and main.get("cast")["pickup_name_by_entity"].is_empty(), "persistent: the spear does not respawn after re-entering T4")
	_expect(main.get("cast")["pickup_view_by_entity"].is_empty(), "persistent: no floor view is rebuilt for the taken spear")
	Support.reboot_zone(main, &"west_entry")
	_expect(Support.ecs_of(main).grid.get_item_cells().is_empty(), "persistent: the spear does not respawn after a bare boot_zone")
	Support.write_the_run(save_service)
	Support.forget_the_run(save_service)
	save_service.call("load_slot")
	_expect(Support.run_of(save_service).taken_pickup_ids.has(SPEAR_KEY) and Support.run_of(save_service).unlocked_rule_ids.has("pawn_recruit"), "persistent: load_state restores the taken pickup and the Book pages")
	await Support.travel_to(main, T4, &"west_entry")
	_expect(Support.ecs_of(main).grid.get_item_cells().is_empty(), "persistent: the spear stays gone after the save/load round trip")

	# Zone-scoped: the same marker name taken elsewhere does not hide this spear.
	Support.run_of(save_service).taken_pickup_ids.erase(SPEAR_KEY)
	Support.run_of(save_service).taken_pickup_ids["some_other_zone/PencilSpearPickup"] = true
	await Support.travel_to(main, T4, &"west_entry")
	_expect(Support.ecs_of(main).grid.get_item_cells().size() == 1, "persistent: ids are zone-scoped (another zone's spear name does not hide this one)")
	Support.run_of(save_service).taken_pickup_ids.erase("some_other_zone/PencilSpearPickup")
	Support.run_of(save_service).taken_pickup_ids[SPEAR_KEY] = true
	Support.write_the_run(save_service)

	# The marker's flag is the truth: a record the run holds for a floor weapon (a save from before D-16 kept
	# every weapon an enemy took) is ignored, and the spear is on the floor again.
	_make_t4_spear_persistent(main, false)
	await Support.travel_to(main, T4, &"west_entry")
	_expect(Support.run_of(save_service).taken_pickup_ids.has(SPEAR_KEY) and Support.ecs_of(main).grid.get_item_cells().size() == 1, "CHANGED (D-16): a stale record for a floor weapon hides nothing")
	_make_t4_spear_persistent(main, true)

	# The Book pages are visible in the Book after a boot.
	var book := main.get_node("RuleBookUI") as RuleBookUI
	_expect(book.unlocked_piece_ids.has(&"pawn_recruit"), "pickup: a boot feeds the unlocked pages to the Book")


## Makes the T4 spear of every later T4 boot a persistent pickup (true), or the shipped floor weapon (false):
## the world graph's T4 scene is swapped for a copy whose marker has `persistent` set, or put back. A
## room's scene is what a boot builds from, so this is the way to give a whole trip a persistent marker.
func _make_t4_spear_persistent(main: Node, persistent: bool) -> void:
	var graph: WorldGraph = main.get("world_graph")
	edited_world_graph = graph
	if original_t4_scene == null:
		original_t4_scene = graph.get_zone_scene(T4)
	if not persistent:
		graph.find_room(T4).scene = original_t4_scene
		return
	var room := original_t4_scene.instantiate()
	(room.get_node("PencilSpearPickup") as PickupSpawnPoint).persistent = true
	var patched := PackedScene.new()
	_expect(patched.pack(room) == OK, "setup: a copy of T4 with a persistent spear packs")
	room.free()
	graph.find_room(T4).scene = patched


## The 72x40 kingdom is a test fixture since M5 (plan D-02) and no room of the game leads into it, so a suite that
## wants the shell to travel there adds it to the loaded world graph as one more room for the length of the process
## (the suite's own process: the runner starts every suite in a fresh Godot). The graph file is never touched.
func _add_the_kingdom_fixture_to(graph: WorldGraph) -> void:
	if graph.has_zone(KINGDOM):
		return
	var paths := TestPaths.new(self)
	var fixture_room := WorldRoom.new()
	fixture_room.room_id = KINGDOM
	fixture_room.scene = paths.load_scene(paths.kingdom_scene())
	graph.rooms.append(fixture_room)
	edited_world_graph = graph


## Stands the enemy on the pickup's cell and lets its AI take it (EnemyAISystem._collect_local_item, the one
## place pickups are taken), then hands the events to the router. True when the floor item is gone.
func _pawn_takes_the_spear(main: Node, enemy_ai: EnemyAISystem, enemy_id: int, item_cell: Vector2i) -> bool:
	var ecs := Support.ecs_of(main)
	var enemy_pos: EcsComponents.GridPos = ecs.get_component(enemy_id, EcsComponents.GRID_POS)
	enemy_pos.cell = item_cell
	enemy_ai.call("_collect_local_item", enemy_id)
	Support.route_events(main)
	return ecs.grid.item_at(item_cell) == 0


## --- Opened gate: the kingdom's shortcuts -------------------------------------


func _check_opened_gate(main: Node) -> void:
	await Support.travel_to(main, KINGDOM, &"start")
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
	_expect(String((main.get("hud") as GameHud).objective_line.text_label.text).begins_with("The gate unbars"), "gate: the HUD announces the opening")
	_expect(_saved_list("world", "opened_gate_ids").has("pass_home_gate"), "gate: the opened gate is written to the save file immediately")

	# Persists across a re-boot, a bare boot_zone and a save/load round trip.
	await Support.travel_to(main, KINGDOM, &"start")
	ecs = Support.ecs_of(main)
	pass_gate = _gate_marker(main, &"pass_home_gate")
	lane_gate = _gate_marker(main, &"gardens_lane_gate")
	_expect(ecs.grid.is_walkable(gate_cell) and ecs.grid.gate_by_cell.size() == 1 and not pass_gate.visible and lane_gate.visible, "gate: re-entering keeps the pass gate open and the lane gate closed")
	Support.reboot_zone(main, &"start")
	_expect(Support.ecs_of(main).grid.is_walkable(gate_cell) and not _gate_marker(main, &"pass_home_gate").visible, "gate: a bare boot_zone keeps the pass gate open")
	Support.write_the_run(save_service)
	Support.forget_the_run(save_service)
	_expect(Support.run_of(save_service).opened_gate_ids.is_empty(), "gate: reset forgets the gate (the check below is meaningful)")
	save_service.call("load_slot")
	_expect(Support.run_of(save_service).opened_gate_ids.has("pass_home_gate"), "gate: load_state restores the opened gate from disk")
	await Support.travel_to(main, KINGDOM, &"start")
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
	await Support.travel_to(main, T4, &"west_entry")
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
