extends SceneTree

## Zone travel at the simulation level: a zone scene boots with its own board
## size and door cells, and the player's step onto a door emits the zone_exit
## event with the right destination. The bridge's fade/swap is presentation;
## the decision tested here is the system's.

var failures := 0


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)


func _boot_zone(scene_path: String, player_cell: Vector2i, skipped_pickups: Array = []) -> Dictionary:
	var zone := (load(scene_path) as PackedScene).instantiate()
	root.add_child(zone)
	var world := EcsWorld.new()
	world.manual_tick = true
	root.add_child(world)
	world.add_system(MovementSystem.new())
	var player_view := (load("res://objects/actors/player.tscn") as PackedScene).instantiate() as ActorView
	root.add_child(player_view)
	player_view.position = world.grid.cell_to_world(player_cell)
	var cast := EcsBoot.boot(world, player_view, zone, player_cell, skipped_pickups)
	return {"world": world, "cast": cast, "zone": zone}


func _init() -> void:
	# --- The Toybox Yard boots as a 20x11 board with a north door ---
	var booted := _boot_zone("res://scenes/zones/toybox_yard.tscn", Vector2i(16, 1))
	var world: EcsWorld = booted["world"]
	_expect(world.grid.bounds.size == Vector2i(20, 11), "toybox yard sizes the grid from its board_size export")
	var door: Dictionary = world.grid.exit_by_cell.get(Vector2i(16, 0), {})
	_expect(door.get("zone") == &"chalk_gardens" and door.get("entry") == &"from_yard", "the north door cell targets the Chalk Gardens")
	_expect(booted["cast"]["enemies"].size() == 5, "toybox yard spawns its five teaching enemies")
	_expect(not booted["cast"]["pickup_name_by_entity"].is_empty(), "the spear pickup spawns with a stable marker name")

	# --- Stepping onto the door emits zone_exit with the destination ---
	var player_id := int(booted["cast"]["player"])
	var intent: EcsComponents.MoveIntent = world.get_component(player_id, EcsComponents.MOVE_INTENT)
	intent.direction = Vector2i.UP
	for _i in range(20):
		world.tick(0.05)
	var travel_events := world.drain_events().filter(func(event: Dictionary) -> bool: return event.get("type") == &"zone_exit")
	_expect(travel_events.size() == 1, "landing on the door emits exactly one zone_exit event")
	if not travel_events.is_empty():
		_expect(travel_events[0].get("zone") == &"chalk_gardens" and travel_events[0].get("entry") == &"from_yard", "the zone_exit event carries the door's destination")

	# --- Taken pickups never respawn ---
	var rebooted := _boot_zone("res://scenes/zones/toybox_yard.tscn", Vector2i(1, 9), ["PencilSpearPickup"])
	_expect(rebooted["cast"]["pickup_name_by_entity"].is_empty(), "a taken pickup is skipped on the next zone boot")

	# --- The Chalk Gardens boots and doors back south ---
	var gardens := _boot_zone("res://scenes/zones/chalk_gardens.tscn", Vector2i(16, 10))
	var gardens_world: EcsWorld = gardens["world"]
	_expect(gardens_world.grid.bounds.size == Vector2i(24, 12), "chalk gardens sizes its own larger board")
	var south_door: Dictionary = gardens_world.grid.exit_by_cell.get(Vector2i(16, 11), {})
	_expect(south_door.get("zone") == &"toybox_yard" and south_door.get("entry") == &"from_gardens", "the south door loops back to the Toybox Yard")

	var succeeded := failures == 0
	print("ZONE TRAVEL TEST: %s" % ["PASS" if succeeded else "FAIL (%d)" % failures])
	quit(0 if succeeded else 1)
