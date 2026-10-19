extends SceneTree

## Full main-scene boot: game_root.gd builds the EcsWorld from the authored scene,
## binds HUD/board/camera, and the bridge answers events. Drives main._process
## by hand (headless _init has no frame loop).

const SaveSupport := preload("res://tests/support/save_test_support.gd")

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
	# Autoloads DO load in -s script mode, so the real SaveService node exists; it is pointed at a
	# throwaway folder so this test never reads or writes the player's own save, and begins a clean
	# run. A pending health carry is planted on the new main: the boot must apply and consume it
	# (the live travel path that shipped broken once).
	var save_root := SaveSupport.make_root("encounter_hud")
	var save_service: Node = root.get_node_or_null("/root/SaveService")
	if save_service == null:
		save_service = load("res://shell/save/save_service.gd").new()
		save_service.name = "SaveService"
		root.add_child(save_service)
	save_service.configure(save_root)
	save_service.new_game(0)

	var main := (load("res://shell/game_root.tscn") as PackedScene).instantiate()
	main.set("player_health_carry", 2)
	root.add_child(main)
	await process_frame

	var ecs: EcsWorld = main.get("ecs")
	# Was `systems.size() == 6`: a pin on the old count, not on behaviour (docs/game-base-plan.md 14.1).
	# What it protected is that the live world has every system, in the tick order; the schedule is
	# now the one list of both, and test_schedule_complete checks the list against the files.
	_expect(ecs != null and _runs_the_schedule(ecs), "main boots the world with every system the schedule lists, in order")
	var player_id := int(main.get("player_id"))
	_expect(player_id != 0, "main spawns the player entity")
	var player_pos: EcsComponents.GridPos = ecs.get_component(player_id, EcsComponents.GRID_POS)
	_expect(player_pos != null and player_pos.cell == _parked_cell(ecs, main), "player entity stands on the parked view's cell")
	_expect(int(main.get("total_enemies")) == 0, "main starts in the quiet T1 opening room")
	var player_health: EcsComponents.Health = ecs.get_component(player_id, EcsComponents.HEALTH)
	_expect(player_health != null and player_health.current == 2, "a pending health carry applies to the booted player")
	_expect(int(main.get("player_health_carry")) == -1, "the health carry is consumed by the boot")
	var player_combat: EcsComponents.PlayerCombat = ecs.get_component(player_id, EcsComponents.PLAYER_COMBAT)
	_expect(player_combat != null and not player_combat.sword_unlocked, "world-mode combat starts locked before T2 sword pickup")
	var weapon_pivot := main.get_node_or_null("PawnHero/MotionRoot/SpriteRoot/WeaponPivot") as Node2D
	_expect(weapon_pivot != null and not weapon_pivot.visible, "locked sword is not visible on the hero before pickup")

	var hud := main.get("hud") as GameHud
	_expect(hud != null and hud.courage_label.text.begins_with("COURAGE"), "HUD binds and shows courage")
	_expect(String(hud.objective_label.text).begins_with("The king has fallen"), "HUD shows the T1 start message")

	var board := main.get("board") as PrototypeBoard
	# Was `board.ecs == ecs`: the overlay no longer holds the world, it draws from the world's HudSnapshot
	# (docs/game-base-plan.md 13.1: presentation never touches ecs/components).
	_expect(board != null and board.grid_world == ecs.grid and board.hud_snapshot == ecs.hud_snapshot, "board overlay draws from the ECS grid and the world's hud snapshot")

	var camera := main.get("camera_rig") as CameraRig
	_expect(camera != null and camera.grid_world == ecs.grid, "camera rig clamps to the ECS board")

	for _i in range(10):
		main._process(0.016)
	_expect(String(hud.status_label.text).begins_with("CELL"), "bridge feeds the cell status line each frame")

	var attack_intent: EcsComponents.AttackIntent = ecs.get_component(player_id, EcsComponents.ATTACK_INTENT)
	attack_intent.kind = &"sword"
	main._process(0.016)
	main._process(0.016)
	_expect(String(hud.objective_label.text).begins_with("The pawn has no weapon yet"), "locked attack gives sword-search feedback")

	SaveSupport.remove_root(save_root)
	var succeeded := failures == 0
	print("ENCOUNTER HUD TEST: %s" % ["PASS" if succeeded else "FAIL (%d)" % failures])
	quit(0 if succeeded else 1)


## True when the world holds exactly the systems of ecs/schedule/, in the same order.
func _runs_the_schedule(world: EcsWorld) -> bool:
	var scheduled_scripts := Schedule.system_scripts()
	if world.systems.size() != scheduled_scripts.size():
		return false
	for index in scheduled_scripts.size():
		if world.systems[index].get_script() != scheduled_scripts[index]:
			return false
	return true


func _parked_cell(ecs: EcsWorld, main: Node) -> Vector2i:
	var view := main.get_node_or_null("PawnHero") as Node2D
	return ecs.grid.world_to_cell(view.position) if view != null else Vector2i(-1, -1)
