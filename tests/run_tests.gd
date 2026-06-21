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
	_expect(Vector2i(3, 2) in world.get_reservation_cells(), "debug reservation query exposes reserved cells")
	_expect(not world.begin_move(actor_b, Vector2i(3, 2)), "reserved destination rejects another actor")
	world.finish_move(actor_a, Vector2i(3, 2))
	_expect(world.actor_at(Vector2i(3, 2)) == actor_a, "finish_move updates occupancy")
	_expect(Vector2i(3, 2) in world.get_occupied_cells(), "debug occupancy query exposes occupied cells")
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
	black_pawn.facing = Vector2i.RIGHT
	_expect(black_pawn.get_attack_cells() == [Vector2i(7, 4), Vector2i(7, 2)], "black pawn diagonal attack rotates with facing")

	var spear := EnemyWeapon.pencil_spear()
	black_pawn.equip(spear)
	_expect(black_pawn.get_attack_cells() == [Vector2i(7, 3), Vector2i(8, 3)], "armed pawn replaces diagonals with weapon cells")
	_expect(not Vector2i(7, 4) in black_pawn.get_attack_cells(), "armed attack does not combine with chess attack")

	var knight := KnightEnemy.new()
	root.add_child(knight)
	knight.current_cell = Vector2i(8, 4)
	_expect(knight.get_unarmed_attack_cells().size() == 8, "unarmed knight threatens eight L-shaped cells")
	_expect(Vector2i(10, 5) in knight.get_unarmed_attack_cells(), "knight includes a legal L-shaped target")

	var director := EncounterDirector.new()
	root.add_child(director)
	_expect(director.request_attack(black_pawn), "first enemy receives attack token")
	_expect(not director.request_attack(knight), "second enemy cannot attack while token is owned")
	director.release_attack(black_pawn)
	_expect(director.request_attack(knight), "token transfers after release")

	var pickup := WeaponPickup.new()
	root.add_child(pickup)
	_expect(pickup.setup(world, Vector2i(9, 5), EnemyWeapon.ruler_blade()), "weapon pickup registers on item layer")
	_expect(world.item_at(Vector2i(9, 5)) == pickup, "item layer returns registered weapon")
	var taken_weapon := pickup.take(knight)
	_expect(taken_weapon.display_name == "Ruler Blade", "enemy receives collected weapon data")
	_expect(world.item_at(Vector2i(9, 5)) == null, "collected weapon leaves item layer")

	var free_mover := BlackPawn.new()
	root.add_child(free_mover)
	_expect(free_mover.setup(world, Vector2i(12, 5)), "free-moving enemy registers")
	var move_options := free_mover.get_cardinal_move_options()
	_expect(move_options.size() == 4, "free-moving enemy generates four cardinal destinations")
	_expect(Vector2i(12, 4) in move_options and Vector2i(13, 5) in move_options, "cardinal movement includes vertical and horizontal cells")
	var turn_events := InputMap.action_get_events("turn_mode")
	_expect(turn_events.size() == 1 and turn_events[0].as_text() == "Shift", "turn modifier is bound only to Shift")

	var intent_cells: Array[Vector2i] = [Vector2i(3, 3)]
	var locked_intent := EnemyIntent.attack(intent_cells, 100.0)
	intent_cells[0] = Vector2i(9, 9)
	_expect(locked_intent.target_cells == [Vector2i(3, 3)], "attack intent locks a copy of telegraphed cells")
	var debug_board := PrototypeBoard.new()
	root.add_child(debug_board)
	debug_board.setup(world)
	debug_board.set_enemy_intent(black_pawn, locked_intent)
	_expect(debug_board.enemy_intents.get(black_pawn) == locked_intent, "debug board tracks enemy intent")
	debug_board.set_debug_enabled(false)
	_expect(not debug_board.debug_enabled, "debug board can be toggled off")

	var ai_world := GridWorld.new()
	root.add_child(ai_world)
	var ai_hero := PawnHero.new()
	root.add_child(ai_hero)
	_expect(ai_hero.setup(ai_world, Vector2i(5, 5)), "AI test hero registers")
	var thinking_pawn := BlackPawn.new()
	root.add_child(thinking_pawn)
	_expect(thinking_pawn.setup(ai_world, Vector2i(3, 4)), "AI test pawn registers")
	var ai_director := EncounterDirector.new()
	root.add_child(ai_director)
	thinking_pawn.activate(ai_hero, ai_director)
	thinking_pawn.set_debug_enabled(false)
	_expect(not thinking_pawn.debug_enabled and not thinking_pawn.debug_label.visible, "enemy behavior label follows debug visibility")

	_expect(ai_world.begin_move(ai_hero, Vector2i(5, 4)), "hero visible step reserves its destination")
	var reserved_context := EnemyContext.capture(thinking_pawn)
	_expect(reserved_context.hero_cell == Vector2i(5, 4), "enemy observes the hero's visibly reserved destination")

	ai_world.finish_move(ai_hero, Vector2i(5, 4))
	ai_hero.current_cell = Vector2i(5, 4)
	var decision_context := EnemyContext.capture(thinking_pawn)
	_expect(not decision_context.legal_moves.is_empty(), "enemy keeps hunting while the hero stands still")
	var first_choice := thinking_pawn._select_intent(thinking_pawn._build_intents(decision_context))
	var second_choice := thinking_pawn._select_intent(thinking_pawn._build_intents(decision_context))
	_expect(first_choice.type == second_choice.type and first_choice.destination == second_choice.destination, "identical contexts produce deterministic choices")

	thinking_pawn.facing = Vector2i.DOWN
	ai_hero.current_cell = Vector2i(2, 3)
	ai_world.finish_move(ai_hero, Vector2i(2, 3))
	var turn_context := EnemyContext.capture(thinking_pawn)
	var found_threatening_turn := false
	for intent in thinking_pawn._build_intents(turn_context):
		if intent.type == EnemyIntent.Type.TURN and intent.direction == Vector2i.UP and intent.score > 40.0:
			found_threatening_turn = true
	_expect(found_threatening_turn, "pawn recognizes a turn that creates diagonal pressure")

	_expect(ai_director.can_request_attack(thinking_pawn), "director reports an available attack token")
	ai_director.request_attack(thinking_pawn)
	_expect(not ai_director.can_request_attack(knight), "director exposes token denial to other enemy decisions")

	print("TESTS COMPLETE: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)
