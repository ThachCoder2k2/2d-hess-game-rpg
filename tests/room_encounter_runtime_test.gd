extends SceneTree

## The room as spawn data: EcsBoot reads the authored first_encounter scene +
## a parked player view and produces the whole cast — enemies at their parked
## cells, the armed pawn already carrying its definition's weapon, pickups
## registered, painted walls solid, and the objective completing when the
## defeated events say so.

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
	world.add_system(EnemyAISystem.new())
	world.add_system(MovementSystem.new())
	world.add_system(HealthSystem.new())
	world.add_system(ViewSyncSystem.new())

	var room := (load("res://scenes/rooms/first_encounter.tscn") as PackedScene).instantiate()
	root.add_child(room)
	var player_view := (load("res://objects/actors/player.tscn") as PackedScene).instantiate() as ActorView
	player_view.position = Vector2(110, 229)
	root.add_child(player_view)

	var cast := EcsBoot.boot(world, player_view, room)
	var player_id := int(cast["player"])
	var enemies: Array = cast["enemies"]

	_expect(player_id != 0 and world.grid.entity_at(Vector2i(1, 6)) == player_id, "parked player spawns on its containing cell")
	_expect(enemies.size() == 3, "all three parked enemies spawn")
	_expect(world.grid.entity_at(Vector2i(4, 1)) != 0, "PawnRecruit spawns at its parked cell")
	_expect(world.grid.entity_at(Vector2i(10, 1)) != 0, "ArmedPawn spawns at its parked cell")
	_expect(world.grid.entity_at(Vector2i(13, 2)) != 0, "KnightTracker spawns at its parked cell")

	var armed_id := world.grid.entity_at(Vector2i(10, 1))
	var armed_slot: EcsComponents.WeaponSlot = world.get_component(armed_id, EcsComponents.WEAPON_SLOT)
	_expect(armed_slot != null and armed_slot.weapon != null and armed_slot.weapon.display_name == "Pencil Spear", "armed pawn carries its definition's default weapon")

	var knight_id := world.grid.entity_at(Vector2i(13, 2))
	var knight_ai: EcsComponents.EnemyAI = world.get_component(knight_id, EcsComponents.ENEMY_AI)
	_expect(knight_ai != null and knight_ai.allowed_directions.size() == 8, "knight entity moves by its L-shaped MovementConfig")

	_expect(world.grid.item_at(Vector2i(5, 5)) != 0 and world.grid.item_at(Vector2i(11, 6)) != 0, "both pickup markers register floor weapons")
	_expect(cast["pickup_view_by_entity"].size() == 2, "pickups get floating views")
	_expect(world.grid.blocked_cells.has(Vector2i(0, 0)) and world.grid.blocked_cells.has(Vector2i(7, 0)), "painted solid tiles block the border and thrones")
	_expect(not world.grid.blocked_cells.has(Vector2i(5, 4)), "open floor stays walkable")

	var piece_names: Dictionary = cast["piece_name_by_entity"]
	_expect(String(piece_names.get(armed_id, "")) == "Pawn", "cast knows each entity's piece name")

	_expect(String(room.call("get_start_message")).begins_with("First clash"), "room start message comes from the objective data")
	_expect(String(room.call("get_clear_message")) == "ROOM CLEARED", "room clear message resolves")

	var defeated_count := 0
	for enemy_id: int in enemies:
		world.damage_events.append({"target": enemy_id, "amount": 99, "direction": Vector2i.LEFT})
	world.tick(0.016)
	for event in world.drain_events():
		if event.get("type") == &"defeated":
			defeated_count += 1
	_expect(defeated_count == 3, "lethal damage defeats every enemy with an event each")
	var objective: Resource = room.get("objective")
	_expect(objective != null and bool(objective.call("is_complete", 3, 3, 0)), "objective completes when the whole cast falls")

	# Editor-draggable ECS components: spec nodes under a view bake into the
	# entity at boot (nodes in the dock, tables at runtime).
	var spec_world := EcsWorld.new()
	spec_world.manual_tick = true
	root.add_child(spec_world)
	var spec_view := ActorView.new()
	spec_view.definition = load("res://resources/enemies/pawn_recruit.tres")
	spec_view.position = spec_world.grid.cell_to_world(Vector2i(3, 3))
	var health_spec := HealthSpec.new()
	health_spec.max_health = 5
	spec_view.add_child(health_spec)
	var weapon_spec := WeaponSpec.new()
	weapon_spec.weapon = load("res://resources/weapons/ruler_blade.tres")
	spec_view.add_child(weapon_spec)
	var spec_room := Node2D.new()
	spec_room.add_child(spec_view)
	root.add_child(spec_room)
	var spec_cast := EcsBoot.boot(spec_world, null, spec_room)
	var spec_id: int = spec_cast["enemies"][0]
	var spec_health: EcsComponents.Health = spec_world.get_component(spec_id, EcsComponents.HEALTH)
	_expect(spec_health != null and spec_health.max_value == 5 and spec_health.current == 5, "HealthSpec node overrides the definition's health at boot")
	var spec_slot: EcsComponents.WeaponSlot = spec_world.get_component(spec_id, EcsComponents.WEAPON_SLOT)
	_expect(spec_slot != null and spec_slot.weapon != null and spec_slot.weapon.id == &"ruler_blade", "WeaponSpec node arms the entity at boot")

	var succeeded := failures == 0
	print("ROOM ENCOUNTER TEST: %s" % ["PASS" if succeeded else "FAIL (%d)" % failures])
	quit(0 if succeeded else 1)
