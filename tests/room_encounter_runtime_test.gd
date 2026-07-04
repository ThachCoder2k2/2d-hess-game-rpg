extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := GridWorld.new()
	root.add_child(world)
	var board := PrototypeBoard.new()
	root.add_child(board)
	board.setup(world)
	var hero := PawnHero.new()
	root.add_child(hero)
	var hero_ok := hero.setup(world, Vector2i(3, 7))
	var director := EncounterDirector.new()
	root.add_child(director)
	var room_scene := load("res://scenes/rooms/first_encounter.tscn") as PackedScene
	var room := room_scene.instantiate()
	root.add_child(room)
	var spawned: Array[FreeEnemy] = []
	var completed_count := {"value": 0}
	room.connect("enemy_spawned", func(enemy: FreeEnemy) -> void: spawned.append(enemy))
	room.connect("room_completed", func(_room: Node) -> void: completed_count["value"] += 1)
	room.call("setup", world, hero, director, board, false)
	var blockers_ok: bool = (
		not world.is_walkable(Vector2i(7, 2))
		and not world.is_walkable(Vector2i(7, 3))
		and not world.is_walkable(Vector2i(7, 5))
		and not world.is_walkable(Vector2i(7, 6))
	)
	var pickups_ok: bool = (
		world.item_at(Vector2i(5, 5)) is WeaponPickup
		and world.item_at(Vector2i(11, 6)) is WeaponPickup
	)
	var enemies_ok: bool = (
		hero_ok
		and spawned.size() == 3
		and room.call("get_total_enemy_count") == 3
		and room.call("get_remaining_enemy_count") == 3
		and world.actor_at(Vector2i(4, 1)) is BlackPawn
		and world.actor_at(Vector2i(10, 1)) is BlackPawn
		and world.actor_at(Vector2i(13, 2)) is KnightEnemy
	)
	var armed_pawn := world.actor_at(Vector2i(10, 1)) as BlackPawn
	var armed_ok := armed_pawn != null and armed_pawn.weapon != null and armed_pawn.weapon.display_name == "Pencil Spear"
	var message := String(room.call("get_start_message"))
	var message_ok: bool = message.begins_with("First clash")
	for enemy in spawned:
		enemy.state = FreeEnemy.State.DEFEATED
		room.call("_on_enemy_defeated", enemy)
	var completion_ok: bool = completed_count["value"] == 1 and String(room.call("get_clear_message")) == "ROOM CLEARED"
	var succeeded: bool = blockers_ok and pickups_ok and enemies_ok and armed_ok and message_ok and completion_ok
	print("ROOM ENCOUNTER TEST: %s" % ["PASS" if succeeded else "FAIL"])
	quit(0 if succeeded else 1)
