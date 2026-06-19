extends SceneTree

var failures := 0


func _init() -> void:
	var world := GridWorld.new()
	root.add_child(world)

	_expect(world.cell_to_world(Vector2i.ZERO) == Vector2(80, 52), "cell_to_world returns cell center")
	_expect(world.world_to_cell(Vector2(80, 52)) == Vector2i.ZERO, "world_to_cell reverses cell center")
	_expect(world.is_walkable(Vector2i(3, 4)), "interior cell is walkable")
	_expect(not world.is_walkable(Vector2i(-1, 4)), "outside cell is rejected")

	var actor_a := Node.new()
	var actor_b := Node.new()
	root.add_child(actor_a)
	root.add_child(actor_b)
	_expect(world.register_actor(actor_a, Vector2i(2, 2)), "first actor registers")
	_expect(not world.register_actor(actor_b, Vector2i(2, 2)), "occupied registration is rejected")
	_expect(world.register_actor(actor_b, Vector2i(4, 2)), "second actor registers elsewhere")
	_expect(world.begin_move(actor_a, Vector2i(3, 2)), "valid destination reserves")
	_expect(not world.begin_move(actor_b, Vector2i(3, 2)), "reserved destination rejects another actor")
	world.finish_move(actor_a, Vector2i(3, 2))
	_expect(world.actor_at(Vector2i(3, 2)) == actor_a, "finish_move updates occupancy")
	_expect(world.actor_at(Vector2i(2, 2)) == null, "finish_move releases origin")
	_expect(world.add_block(Vector2i(6, 4)), "empty cell accepts a block")
	_expect(not world.can_begin_move(actor_a, Vector2i(6, 4)), "blocked cell rejects movement")
	_expect(not world.add_block(Vector2i(4, 2)), "occupied cell rejects a block")

	var hero := PawnHero.new()
	root.add_child(hero)
	hero.current_cell = Vector2i(8, 5)
	hero.facing = Vector2i.LEFT
	_expect(hero.get_attack_cell() == Vector2i(7, 5), "sword targets one adjacent facing cell")
	_expect(hero.try_turn(Vector2i.UP), "turn-in-place accepts a cardinal direction")
	_expect(hero.current_cell == Vector2i(8, 5), "turn-in-place does not move the pawn")
	_expect(hero.facing == Vector2i.UP, "turn-in-place updates facing")

	var thrust := AttackProfile.new()
	thrust.range_cells = 2
	_expect(thrust.get_target_cells(Vector2i(4, 4), Vector2i.RIGHT) == [Vector2i(5, 4), Vector2i(6, 4)], "attack profile produces ordered range cells")

	var black_pawn := BlackPawn.new()
	root.add_child(black_pawn)
	black_pawn.current_cell = Vector2i(6, 3)
	_expect(black_pawn.get_attack_cells() == [Vector2i(5, 4), Vector2i(7, 4)], "black pawn attacks both forward diagonals")
	var turn_events := InputMap.action_get_events("turn_mode")
	_expect(turn_events.size() == 1 and turn_events[0].as_text() == "Shift", "turn modifier is bound only to Shift")

	print("TESTS COMPLETE: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)
