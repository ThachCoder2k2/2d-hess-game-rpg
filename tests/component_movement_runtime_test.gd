extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := GridWorld.new()
	root.add_child(world)
	var scene := load("res://scenes/actors/enemy_base.tscn") as PackedScene
	var enemy := scene.instantiate() as EnemyActor
	root.add_child(enemy)
	var setup_ok := enemy.setup(world, Vector2i(2, 2))
	var step_ok := enemy.try_step(Vector2i.RIGHT)
	await enemy.step_finished
	var destination := Vector2i(3, 2)
	var succeeded := (
		setup_ok
		and step_ok
		and enemy.current_cell == destination
		and not enemy.is_moving
		and world.actor_at(destination) == enemy
		and world.get_reservation_cells().is_empty()
		and enemy.position == world.cell_to_world(destination).round()
	)
	print("COMPONENT MOVEMENT TEST: %s" % ["PASS" if succeeded else "FAIL"])
	quit(0 if succeeded else 1)
