extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := GridWorld.new()
	root.add_child(world)
	var scene := load("res://scenes/actors/enemy_base.tscn") as PackedScene
	var enemy := scene.instantiate() as EnemyActor
	enemy.definition = load("res://resources/enemies/knight_tracker.tres") as EnemyDefinition
	root.add_child(enemy)
	var setup_ok := enemy.setup(world, Vector2i(5, 5))
	var legal_moves := enemy.get_cardinal_move_options()
	var expected_destination := Vector2i(7, 6)
	var adjacent_destination := Vector2i(6, 5)
	var step_ok := enemy.try_step(Vector2i(2, 1))
	await enemy.step_finished
	var succeeded := (
		setup_ok
		and expected_destination in legal_moves
		and adjacent_destination not in legal_moves
		and step_ok
		and enemy.current_cell == expected_destination
		and not enemy.is_moving
		and world.actor_at(expected_destination) == enemy
		and world.get_reservation_cells().is_empty()
		and enemy.position == world.cell_to_world(expected_destination).round()
	)
	print("COMPONENT KNIGHT MOVEMENT TEST: %s" % ["PASS" if succeeded else "FAIL"])
	quit(0 if succeeded else 1)
