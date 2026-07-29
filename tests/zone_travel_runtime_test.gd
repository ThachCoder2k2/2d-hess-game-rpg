extends SceneTree

## The semi-open kingdom at the simulation level: one continuous board boots
## with its districts, gates, and population; the aggro leash keeps far
## districts idle; the zone-exit machinery stays covered via an injected
## door cell (the kingdom itself has no doors — it is one space).

var failures := 0


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)


func _boot_kingdom(player_cell: Vector2i, opened_gates: Array = [], with_ai := false) -> Dictionary:
	var zone := (load("res://scenes/zones/the_kingdom.tscn") as PackedScene).instantiate()
	root.add_child(zone)
	var world := EcsWorld.new()
	world.manual_tick = true
	root.add_child(world)
	if with_ai:
		world.add_system(EnemyAISystem.new())
	world.add_system(MovementSystem.new())
	var player_view := (load("res://objects/actors/player.tscn") as PackedScene).instantiate() as ActorView
	root.add_child(player_view)
	player_view.position = world.grid.cell_to_world(player_cell)
	var cast := EcsBoot.boot(world, player_view, zone, player_cell, [], opened_gates)
	return {"world": world, "cast": cast}


func _init() -> void:
	# --- One continuous board with the whole population ---
	var booted := _boot_kingdom(Vector2i(4, 35))
	var world: EcsWorld = booted["world"]
	_expect(world.grid.bounds.size == Vector2i(72, 40), "the kingdom is one 72x40 board")
	_expect(booted["cast"]["enemies"].size() == 17, "all seventeen inhabitants spawn across the districts")
	_expect(booted["cast"]["pickup_name_by_entity"].size() == 5, "all five treasures spawn with stable names")
	_expect(world.grid.gate_by_cell.size() == 2, "both shortcut gates start closed")

	# --- Zone-exit machinery stays covered (injected door; no doors in-world) ---
	var exit_probe := _boot_kingdom(Vector2i(4, 35))
	var probe_world: EcsWorld = exit_probe["world"]
	probe_world.grid.exit_by_cell[Vector2i(5, 35)] = {"zone": &"somewhere", "entry": &"there"}
	var probe_player := int(exit_probe["cast"]["player"])
	var probe_intent: EcsComponents.MoveIntent = probe_world.get_component(probe_player, EcsComponents.MOVE_INTENT)
	probe_intent.direction = Vector2i.RIGHT
	for _i in range(10):
		probe_world.tick(0.05)
	var travel_events := probe_world.drain_events().filter(func(event: Dictionary) -> bool: return event.get("type") == &"zone_exit")
	_expect(travel_events.size() == 1 and travel_events[0].get("zone") == &"somewhere", "a door cell still emits zone_exit (future interiors)")

	# --- The pass home gate: wall from the court side, opens from the pass ---
	var wrong_side := _boot_kingdom(Vector2i(46, 19))
	var wrong_world: EcsWorld = wrong_side["world"]
	_expect(not wrong_world.grid.is_walkable(Vector2i(47, 19)), "the pass gate cell starts blocked")
	var wrong_player := int(wrong_side["cast"]["player"])
	var wrong_intent: EcsComponents.MoveIntent = wrong_world.get_component(wrong_player, EcsComponents.MOVE_INTENT)
	wrong_intent.direction = Vector2i.RIGHT
	for _i in range(10):
		wrong_world.tick(0.05)
	_expect(not wrong_world.grid.is_walkable(Vector2i(47, 19)), "pushing the pass gate from the court side stays a wall")

	var opener := _boot_kingdom(Vector2i(48, 19))
	var opener_world: EcsWorld = opener["world"]
	var opener_player := int(opener["cast"]["player"])
	var opener_intent: EcsComponents.MoveIntent = opener_world.get_component(opener_player, EcsComponents.MOVE_INTENT)
	opener_intent.direction = Vector2i.LEFT
	for _i in range(10):
		opener_world.tick(0.05)
	var gate_events := opener_world.drain_events().filter(func(event: Dictionary) -> bool: return event.get("type") == &"gate_opened")
	_expect(gate_events.size() == 1 and gate_events[0].get("gate") == &"pass_home_gate", "pushing from the pass side opens the home gate")
	_expect(opener_world.grid.is_walkable(Vector2i(47, 19)), "the opened gate cell is ordinary floor")

	# --- The gardens shortcut opens from the north ---
	var gardens_opener := _boot_kingdom(Vector2i(32, 10))
	var gardens_world: EcsWorld = gardens_opener["world"]
	var gardens_player := int(gardens_opener["cast"]["player"])
	var gardens_intent: EcsComponents.MoveIntent = gardens_world.get_component(gardens_player, EcsComponents.MOVE_INTENT)
	gardens_intent.direction = Vector2i.DOWN
	for _i in range(10):
		gardens_world.tick(0.05)
	var lane_events := gardens_world.drain_events().filter(func(event: Dictionary) -> bool: return event.get("type") == &"gate_opened")
	_expect(lane_events.size() == 1 and lane_events[0].get("gate") == &"gardens_lane_gate", "the gardens shortcut opens from above")

	# --- Opened gates never respawn blocked ---
	var opened_boot := _boot_kingdom(Vector2i(4, 35), [&"pass_home_gate", &"gardens_lane_gate"])
	var opened_world: EcsWorld = opened_boot["world"]
	_expect(opened_world.grid.gate_by_cell.is_empty() and opened_world.grid.is_walkable(Vector2i(47, 19)), "opened gates stay open forever")

	# --- The aggro leash: far districts idle, near enemies wake ---
	var calm := _boot_kingdom(Vector2i(4, 35), [], true)
	var calm_world: EcsWorld = calm["world"]
	var far_enemy := calm_world.grid.entity_at(Vector2i(66, 6))
	var near_edge_enemy := calm_world.grid.entity_at(Vector2i(10, 33))
	for _i in range(40):
		calm_world.tick(0.05)
	calm_world.drain_events()
	_expect(calm_world.grid.cell_by_entity.get(far_enemy) == Vector2i(66, 6), "an enemy across the world never stirs")
	_expect(calm_world.grid.cell_by_entity.get(near_edge_enemy) == Vector2i(10, 33), "an enemy just past the aggro radius stays idle")

	var stirred := _boot_kingdom(Vector2i(24, 23), [], true)
	var stirred_world: EcsWorld = stirred["world"]
	var road_enemy := stirred_world.grid.entity_at(Vector2i(23, 23))
	for _i in range(40):
		stirred_world.tick(0.05)
	var road_ai: EcsComponents.EnemyAI = stirred_world.get_component(road_enemy, EcsComponents.ENEMY_AI)
	var woke: bool = stirred_world.grid.cell_by_entity.get(road_enemy) != Vector2i(23, 23) \
		or (road_ai != null and road_ai.state != EcsComponents.EnemyAI.STATE_OBSERVE)
	_expect(woke, "an enemy inside the aggro radius wakes and acts")

	var succeeded := failures == 0
	print("ZONE TRAVEL TEST: %s" % ["PASS" if succeeded else "FAIL (%d)" % failures])
	quit(0 if succeeded else 1)
