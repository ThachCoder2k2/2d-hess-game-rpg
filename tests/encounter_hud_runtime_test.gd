extends SceneTree

## Full main-scene boot: main.gd builds the EcsWorld from the authored scene,
## binds HUD/board/camera, and the bridge answers events. Drives main._process
## by hand (headless _init has no frame loop).

var failures := 0


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)


func _init() -> void:
	call_deferred("_run")


## _ready only fires once the tree loop starts, so boot checks wait one frame.
func _run() -> void:
	# Autoloads DO load in -s script mode, so use the real WorldState and
	# plant a pending health carry — the boot must apply and consume it
	# (the live travel path that shipped broken once).
	var world_state: Node = root.get_node_or_null("/root/WorldState")
	if world_state == null:
		world_state = load("res://scripts/world/world_state.gd").new()
		world_state.name = "WorldState"
		root.add_child(world_state)
	world_state.set("current_zone_id", &"")
	world_state.set("last_entry_id", &"start")
	world_state.set("player_health_carry", 2)

	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame

	var ecs: EcsWorld = main.get("ecs")
	_expect(ecs != null and ecs.systems.size() == 6, "main boots the world with all six systems")
	var player_id := int(main.get("player_id"))
	_expect(player_id != 0, "main spawns the player entity")
	var player_pos: EcsComponents.GridPos = ecs.get_component(player_id, EcsComponents.GRID_POS)
	_expect(player_pos != null and player_pos.cell == _parked_cell(ecs, main), "player entity stands on the parked view's cell")
	_expect(int(main.get("total_enemies")) == 5, "main counts the Toybox Yard's five enemies")
	var player_health: EcsComponents.Health = ecs.get_component(player_id, EcsComponents.HEALTH)
	_expect(player_health != null and player_health.current == 2, "a pending health carry applies to the booted player")
	_expect(int(world_state.get("player_health_carry")) == -1, "the health carry is consumed by the boot")

	var hud := main.get("hud") as GameHud
	_expect(hud != null and hud.courage_label.text.begins_with("COURAGE"), "HUD binds and shows courage")
	_expect(String(hud.objective_label.text).begins_with("The Toybox Yard"), "HUD shows the zone's start message")

	var board := main.get("board") as PrototypeBoard
	_expect(board != null and board.grid_world == ecs.grid and board.ecs == ecs, "board overlay reads the ECS world")

	var camera := main.get("camera_rig") as CameraRig
	_expect(camera != null and camera.grid_world == ecs.grid, "camera rig clamps to the ECS board")

	for _i in range(10):
		main._process(0.016)
	_expect(String(hud.status_label.text).begins_with("CELL"), "bridge feeds the cell status line each frame")

	var enemies: Array = main.get("cast")["enemies"]
	ecs.damage_events.append({"target": int(enemies[0]), "amount": 99, "direction": Vector2i.LEFT})
	main._process(0.016)
	main._process(0.016)
	_expect(int(main.get("remaining_enemies")) == 4, "a defeat event updates the encounter count")
	_expect(hud.encounter_label.text == "ENEMIES 4/5", "HUD shows the updated enemy count")

	var succeeded := failures == 0
	print("ENCOUNTER HUD TEST: %s" % ["PASS" if succeeded else "FAIL (%d)" % failures])
	quit(0 if succeeded else 1)


func _parked_cell(ecs: EcsWorld, main: Node) -> Vector2i:
	var view := main.get_node_or_null("PawnHero") as Node2D
	return ecs.grid.world_to_cell(view.position) if view != null else Vector2i(-1, -1)
