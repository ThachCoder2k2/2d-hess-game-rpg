extends SceneTree

## Phase A of the ECS conversion (docs/ecs-conversion-plan.md): entity movement
## through the reserve -> commit grid protocol, driven by manual ticks, with a
## puppet view following. Input system is exercised indirectly (headless has no
## keys) by writing MoveIntent — exactly what PlayerInputSystem produces.

var failures := 0


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)


func _init() -> void:
	var world := EcsWorld.new()
	world.manual_tick = true
	root.add_child(world)
	world.add_system(MovementSystem.new())
	world.add_system(ViewSyncSystem.new())

	var pawn := world.create_entity()
	var pawn_pos: EcsComponents.GridPos = world.add_component(pawn, EcsComponents.GRID_POS, EcsComponents.GridPos.new())
	pawn_pos.cell = Vector2i(3, 7)
	world.add_component(pawn, EcsComponents.FACING, EcsComponents.Facing.new())
	var pawn_intent: EcsComponents.MoveIntent = world.add_component(pawn, EcsComponents.MOVE_INTENT, EcsComponents.MoveIntent.new())
	var pawn_move: EcsComponents.MoveState = world.add_component(pawn, EcsComponents.MOVE_STATE, EcsComponents.MoveState.new())
	var view_node := Node2D.new()
	root.add_child(view_node)
	var pawn_view: EcsComponents.ViewRef = world.add_component(pawn, EcsComponents.VIEW_REF, EcsComponents.ViewRef.new())
	pawn_view.node = view_node

	_expect(world.grid.register_entity(pawn, pawn_pos.cell), "entity registers on its cell")
	_expect(world.grid.entity_at(Vector2i(3, 7)) == pawn, "grid resolves the entity by cell")

	_expect(world.grid.add_block(Vector2i(3, 6)), "empty cell accepts a block")
	pawn_intent.direction = Vector2i.UP
	world.tick(0.016)
	var blocked_events := world.drain_events()
	_expect(not pawn_move.moving and pawn_pos.cell == Vector2i(3, 7), "blocked cell rejects the step")
	var saw_blocked := false
	for event in blocked_events:
		if event.get("type") == &"step_blocked" and event.get("entity") == pawn:
			saw_blocked = true
	_expect(saw_blocked, "blocked step emits a step_blocked event")

	pawn_intent.direction = Vector2i.RIGHT
	world.tick(0.016)
	_expect(pawn_move.moving and pawn_move.to_cell == Vector2i(4, 7), "free step starts a reserve -> commit move")
	var intruder := world.create_entity()
	_expect(not world.grid.register_entity(intruder, Vector2i(4, 7)), "reserved destination rejects a spawner mid-move")
	_expect(world.grid.entity_at(Vector2i(3, 7)) == pawn, "origin stays occupied while sliding")

	for _i in range(20):
		world.tick(0.016)
	_expect(pawn_pos.cell == Vector2i(4, 7) and not pawn_move.moving, "move commits at the destination cell")
	_expect(world.grid.entity_at(Vector2i(3, 7)) == 0 and world.grid.entity_at(Vector2i(4, 7)) == pawn, "occupancy transfers origin -> destination")
	_expect(view_node.position == world.grid.cell_to_world(Vector2i(4, 7)), "puppet view lands on the destination cell center")
	_expect(view_node.z_index == 2 + 7, "view depth follows the row")
	var finish_events := world.drain_events()
	var saw_finished := false
	for event in finish_events:
		if event.get("type") == &"step_finished" and event.get("cell") == Vector2i(4, 7):
			saw_finished = true
	_expect(saw_finished, "committed move emits step_finished")

	var rival := world.create_entity()
	var rival_pos: EcsComponents.GridPos = world.add_component(rival, EcsComponents.GRID_POS, EcsComponents.GridPos.new())
	rival_pos.cell = Vector2i(5, 7)
	world.add_component(rival, EcsComponents.MOVE_STATE, EcsComponents.MoveState.new())
	_expect(world.grid.register_entity(rival, rival_pos.cell), "second entity registers")
	pawn_intent.direction = Vector2i.RIGHT
	world.tick(0.016)
	_expect(not pawn_move.moving and pawn_pos.cell == Vector2i(4, 7), "occupied cell rejects the step")

	world.destroy_entity(rival)
	_expect(world.grid.entity_at(Vector2i(5, 7)) == 0, "destroying an entity frees its cell")
	pawn_intent.direction = Vector2i.RIGHT
	world.tick(0.016)
	_expect(pawn_move.moving, "freed cell accepts the step")

	var succeeded := failures == 0
	print("ECS RUNTIME TEST: %s" % ["PASS" if succeeded else "FAIL (%d)" % failures])
	quit(0 if succeeded else 1)
