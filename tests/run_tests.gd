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

	var path_world := GridWorld.new()
	root.add_child(path_world)
	var path_actor := Node.new()
	root.add_child(path_actor)
	_expect(path_world.register_actor(path_actor, Vector2i(1, 1)), "pathfinding actor registers")
	path_world.add_block(Vector2i(2, 1))
	var routed_path := path_world.get_grid_path(path_actor, Vector2i(1, 1), Vector2i(3, 1))
	_expect(routed_path.size() > 3 and Vector2i(2, 1) not in routed_path, "A* path routes around blocked cells")
	_expect(path_world.get_next_path_cell(path_actor, Vector2i(1, 1), Vector2i(3, 1)) != Vector2i(2, 1), "next path cell never enters a blocker")

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

	var player_scene := load("res://objects/actors/player.tscn") as PackedScene
	var scene_hero := player_scene.instantiate() as PawnHero
	root.add_child(scene_hero)
	scene_hero._ensure_attack_profiles()
	_expect(scene_hero.wooden_sword != null and scene_hero.wooden_sword.resource_path.ends_with("wooden_sword.tres"), "player scene owns Wooden Sword attack Resource")
	_expect(scene_hero.pencil_thrust != null and scene_hero.pencil_thrust.resource_path.ends_with("pencil_thrust.tres"), "player scene owns Pencil Thrust attack Resource")
	_expect(_piece_visual_is_sprite_animated(scene_hero.get_node_or_null("Visual"), "sync_from_hero"), "player scene owns a sprite-based animated visual child")
	_expect(_visual_has_clip(scene_hero.get_node_or_null("Visual"), &"step"), "player visual owns a walk/step animation clip")
	var piece_visual_source := FileAccess.get_file_as_string("res://scripts/visuals/piece_visual.gd")
	var pickup_visual_source := FileAccess.get_file_as_string("res://scripts/visuals/pickup_visual.gd")
	_expect(not piece_visual_source.contains("func _draw") and not piece_visual_source.contains("draw_"), "piece visuals use Sprite2D nodes instead of script drawing")
	_expect(not pickup_visual_source.contains("func _draw") and not pickup_visual_source.contains("draw_"), "pickup visuals use Sprite2D nodes instead of script drawing")
	scene_hero.free()

	var objective_script := load("res://scripts/data/room_objective.gd")
	var clear_objective: Resource = objective_script.new()
	_expect(not bool(clear_objective.call("is_complete", 1, 3, 2)), "clear-all objective waits while enemies remain")
	_expect(bool(clear_objective.call("is_complete", 3, 3, 0)), "clear-all objective completes when all enemies fall")
	var count_objective: Resource = objective_script.new()
	count_objective.win_condition = 1
	count_objective.required_defeats = 2
	_expect(not bool(count_objective.call("is_complete", 1, 3, 2)), "defeat-count objective waits for its configured count")
	_expect(bool(count_objective.call("is_complete", 2, 3, 1)), "defeat-count objective can complete before all enemies fall")

	var black_pawn := BlackPawn.new()
	root.add_child(black_pawn)
	black_pawn.current_cell = Vector2i(6, 3)
	_expect(black_pawn.get_attack_cells() == [Vector2i(5, 4), Vector2i(7, 4)], "black pawn attacks both forward diagonals")
	_expect(black_pawn.definition != null and black_pawn.definition.id == &"pawn_recruit", "black pawn loads its editor definition")
	_expect(black_pawn.definition.validate().is_empty(), "pawn definition has no missing configuration")
	_expect(black_pawn.think_time == 0.42 and black_pawn.move_recovery_time == 0.18, "pawn runtime timing comes from Resources")
	black_pawn.facing = Vector2i.RIGHT
	_expect(black_pawn.get_attack_cells() == [Vector2i(7, 4), Vector2i(7, 2)], "black pawn diagonal attack rotates with facing")

	var spear := EnemyWeapon.pencil_spear()
	var second_spear := EnemyWeapon.pencil_spear()
	_expect(spear.resource_path.is_empty() and spear != second_spear, "weapon factory returns independent instances from the editor asset")
	_expect(spear.range_cells == 2 and spear.telegraph_time == 0.62, "Pencil Spear values load from its Resource")
	black_pawn.equip(spear)
	_expect(black_pawn.get_attack_cells() == [Vector2i(7, 3), Vector2i(8, 3)], "armed pawn replaces diagonals with weapon cells")
	_expect(not Vector2i(7, 4) in black_pawn.get_attack_cells(), "armed attack does not combine with chess attack")

	var knight := KnightEnemy.new()
	root.add_child(knight)
	knight.current_cell = Vector2i(8, 4)
	_expect(knight.get_unarmed_attack_cells().size() == 8, "unarmed knight threatens eight L-shaped cells")
	_expect(Vector2i(10, 5) in knight.get_unarmed_attack_cells(), "knight includes a legal L-shaped target")
	_expect(knight.definition != null and knight.definition.id == &"knight_tracker", "knight loads its editor definition")
	_expect(knight.definition.validate().is_empty() and knight.archetype.role == &"flanker", "knight definition configures a valid flanker")
	_expect(knight.definition.movement.allowed_directions.size() == 8, "knight movement config exposes eight L-shaped offsets")
	_expect(Vector2i(2, 1) in knight.definition.movement.allowed_directions and Vector2i.RIGHT not in knight.definition.movement.allowed_directions, "knight movement config does not fall back to one-cell cardinal steps")

	var armed_definition := load("res://resources/enemies/pawn_armed.tres") as EnemyDefinition
	_expect(armed_definition.validate().is_empty(), "armed Pawn definition has no missing configuration")
	_expect(armed_definition.default_weapon != null and armed_definition.default_weapon.display_name == "Pencil Spear", "armed Pawn default weapon is Inspector-configured")

	var pawn_variant_scene := load("res://objects/actors/black_pawn.tscn") as PackedScene
	var pawn_variant := pawn_variant_scene.instantiate() as EnemyActor
	root.add_child(pawn_variant)
	pawn_variant._ensure_ai_data()
	pawn_variant._configure_components()
	_expect(pawn_variant != null and pawn_variant.definition.id == &"pawn_recruit", "Pawn scene variant uses generic EnemyActor with Pawn definition")
	_expect(_piece_visual_is_sprite_animated(pawn_variant.get_node_or_null("Visual"), "sync_from_enemy") and pawn_variant.movement_component != null and pawn_variant.equipment_component != null, "Pawn scene variant owns sprite visual and components")
	_expect(_visual_has_clip(pawn_variant.get_node_or_null("Visual"), &"step"), "Pawn visual owns a walk/step animation clip")
	_expect(pawn_variant.get_piece_display_name() == "Pawn", "Pawn scene variant names itself from definition data")

	var knight_variant_scene := load("res://objects/actors/knight_enemy.tscn") as PackedScene
	var knight_variant := knight_variant_scene.instantiate() as EnemyActor
	root.add_child(knight_variant)
	knight_variant._ensure_ai_data()
	knight_variant._configure_components()
	_expect(knight_variant != null and knight_variant.definition.id == &"knight_tracker", "Knight scene variant uses generic EnemyActor with Knight definition")
	_expect(_piece_visual_is_sprite_animated(knight_variant.get_node_or_null("Visual"), "sync_from_enemy") and knight_variant.movement_component != null and knight_variant.equipment_component != null, "Knight scene variant owns sprite visual and components")
	_expect(_visual_has_clip(knight_variant.get_node_or_null("Visual"), &"step"), "Knight visual owns a walk/step animation clip")
	_expect(knight_variant.get_piece_display_name() == "Knight", "Knight scene variant names itself from definition data")

	var enemy_base_scene := load("res://objects/actors/enemy_base.tscn") as PackedScene
	var pawn_shell := enemy_base_scene.instantiate() as EnemyActor
	root.add_child(pawn_shell)
	pawn_shell._ensure_ai_data()
	pawn_shell._configure_components()
	_expect(pawn_shell.definition.id == &"pawn_recruit", "base enemy scene exposes its default Pawn definition")
	_expect(pawn_shell._get_configuration_warnings().is_empty(), "complete base enemy scene has no editor configuration warnings")
	_expect(_piece_visual_is_sprite_animated(pawn_shell.get_node_or_null("Visual"), "sync_from_enemy"), "base enemy scene owns a sprite-based animated visual child")
	_expect(pawn_shell.movement_component.actor == pawn_shell and pawn_shell.brain_component.actor == pawn_shell, "movement and brain component nodes bind to the host")
	_expect(pawn_shell.attack_component.actor == pawn_shell and pawn_shell.health_component.actor == pawn_shell, "attack and health component nodes bind to the host")
	_expect(pawn_shell.equipment_component.actor == pawn_shell and pawn_shell.enemy_debug_component.actor == pawn_shell, "equipment and debug component nodes bind to the host")
	var health_feedback_player := pawn_shell.health_component.get_node_or_null("AnimationPlayer") as AnimationPlayer
	_expect(health_feedback_player != null and health_feedback_player.has_animation("hurt") and health_feedback_player.has_animation("defeat"), "health component owns editor feedback animations")
	var component_world := GridWorld.new()
	root.add_child(component_world)
	_expect(pawn_shell.setup(component_world, Vector2i(2, 2)), "movement component registers the base enemy")
	_expect(pawn_shell.get_cardinal_move_options().size() == 4, "base enemy legal moves come from movement component")
	_expect(pawn_shell.try_step(Vector2i.RIGHT), "base enemy step delegates to movement component")
	_expect(component_world.get_reserved_cell(pawn_shell) == Vector2i(3, 2) and pawn_shell.is_moving, "movement component owns reservation and moving state")
	var incompatible_weapon := EnemyWeapon.new()
	incompatible_weapon.id = &"marble_launcher"
	incompatible_weapon.tags = [&"projectile"]
	_expect(not pawn_shell.equipment_component.can_equip(incompatible_weapon), "equipment component rejects disallowed weapon tags")
	_expect(not pawn_shell.equipment_component.try_equip(incompatible_weapon) and pawn_shell.weapon == null, "rejected equipment does not change host weapon state")
	var shell_ruler := EnemyWeapon.ruler_blade()
	_expect(pawn_shell.equipment_component.try_equip(shell_ruler), "equipment component accepts a compatible weapon")
	_expect(pawn_shell.equipment_component.get_weapon() == shell_ruler and pawn_shell.weapon == shell_ruler, "equipment component mirrors weapon state for compatibility")
	_expect(pawn_shell.get_attack_cells(Vector2i(4, 4), Vector2i.RIGHT).size() == 3, "equipment component supplies replacement attack geometry")
	_expect(pawn_shell.get_attack_telegraph_time() == 0.56 and pawn_shell.get_attack_recovery_time() == 0.62, "equipment component supplies weapon attack timing")

	var health_world := GridWorld.new()
	root.add_child(health_world)
	var health_director := EncounterDirector.new()
	root.add_child(health_director)
	var health_shell := enemy_base_scene.instantiate() as EnemyActor
	root.add_child(health_shell)
	var health_defeats := {"count": 0}
	health_shell.defeated.connect(func(_enemy: FreeEnemy) -> void: health_defeats["count"] += 1)
	_expect(health_shell.setup(health_world, Vector2i(1, 1)), "health component test enemy registers")
	health_shell.director = health_director
	_expect(health_director.request_attack(health_shell), "health component test enemy receives attack token")
	health_shell.take_damage(1, Vector2i.RIGHT)
	_expect(health_shell.health == health_shell.get_max_health() - 1 and health_shell.flash_time > 0.0 and health_shell.recoil == Vector2(4, 0), "health component applies hurt feedback")
	health_shell.take_damage(99, Vector2i.RIGHT)
	_expect(health_shell.state == FreeEnemy.State.DEFEATED and health_defeats["count"] == 1 and health_world.actor_at(Vector2i(1, 1)) == null and health_director.attack_owner == null, "health component owns defeat cleanup")

	var armed_shell := enemy_base_scene.instantiate() as EnemyActor
	armed_shell.definition = armed_definition
	root.add_child(armed_shell)
	armed_shell._ensure_ai_data()
	armed_shell._configure_components()
	_expect(armed_shell.equipment_component.is_armed() and armed_shell.weapon.display_name == "Pencil Spear", "armed definition equips its default weapon through component")

	var pickup_shell := enemy_base_scene.instantiate() as EnemyActor
	root.add_child(pickup_shell)
	var equipment_world := GridWorld.new()
	root.add_child(equipment_world)
	_expect(pickup_shell.setup(equipment_world, Vector2i(6, 6)), "equipment test enemy registers")
	var component_pickup := WeaponPickup.new()
	root.add_child(component_pickup)
	_expect(component_pickup.setup(equipment_world, Vector2i(6, 6), EnemyWeapon.pencil_spear()), "component weapon pickup registers")
	_expect(pickup_shell.collect_weapon_pickup(component_pickup), "equipment component collects a compatible pickup")
	_expect(pickup_shell.equipment_component.is_armed() and equipment_world.item_at(Vector2i(6, 6)) == null, "component owns collected weapon and clears item layer")
	var rejection_shell := enemy_base_scene.instantiate() as EnemyActor
	root.add_child(rejection_shell)
	var rejection_world := GridWorld.new()
	root.add_child(rejection_world)
	_expect(rejection_shell.setup(rejection_world, Vector2i(7, 7)), "equipment rejection enemy registers")
	var rejected_pickup := WeaponPickup.new()
	root.add_child(rejected_pickup)
	_expect(rejected_pickup.setup(rejection_world, Vector2i(7, 7), incompatible_weapon), "incompatible pickup registers")
	_expect(not rejection_shell.collect_weapon_pickup(rejected_pickup), "equipment component rejects incompatible pickup")
	_expect(rejection_world.item_at(Vector2i(7, 7)) == rejected_pickup and rejected_pickup.weapon == incompatible_weapon, "rejected pickup remains available on item layer")

	var knight_shell := enemy_base_scene.instantiate() as EnemyActor
	knight_shell.definition = load("res://resources/enemies/knight_tracker.tres") as EnemyDefinition
	root.add_child(knight_shell)
	knight_shell._ensure_ai_data()
	knight_shell._configure_components()
	_expect(knight_shell.get_unarmed_attack_cells(Vector2i(8, 4)).size() == 8, "same base scene loads Knight attack configuration")
	var optional_debug := knight_shell.get_node("DebugComponent")
	knight_shell.remove_child(optional_debug)
	optional_debug.queue_free()
	knight_shell._configure_components()
	_expect(knight_shell.enemy_debug_component == null and knight_shell.get_unarmed_attack_cells(Vector2i(8, 4)).size() == 8, "removing optional debug component does not affect combat data")

	var main_scene := load("res://scenes/main.tscn") as PackedScene
	var main_game := main_scene.instantiate()
	root.add_child(main_game)
	var main_board := main_game.get_node_or_null("PrototypeBoard") as PrototypeBoard
	var main_room_art := main_game.get_node_or_null("FirstEncounter/RoomArt")
	var main_room := main_game.get_node_or_null("FirstEncounter")
	var main_hero := main_game.get_node_or_null("PawnHero") as PawnHero
	var main_hero_start_marker := main_game.get_node_or_null("FirstEncounter/HeroStart")
	var main_hero_start_cell := Vector2i.ZERO
	if main_room != null and main_room.has_method("get_hero_start_cell"):
		main_hero_start_cell = main_room.call("get_hero_start_cell")
	var main_children_ok: bool = (
		main_game.get_node_or_null("GridWorld") is GridWorld
		and main_game.get_node_or_null("EncounterDirector") is EncounterDirector
		and main_board != null
		and main_hero != null
		and main_room != null
		and main_room_art != null
		and main_game.get_node_or_null("HUD") != null
	)
	_expect(main_children_ok, "main scene owns editor-visible world, combat, board, player, room, and HUD nodes")
	_expect(main_board != null and main_board.editor_preview_enabled and Vector2i(7, 2) in main_board.editor_blocked_cells, "main board owns an editor room preview")
	_expect(main_board != null and not main_board.draw_base_layer, "main board leaves floor art to the editor-authored room")
	_expect(main_room_art != null and main_room_art.get_node_or_null("TileMap") is TileMapLayer and main_room_art.get_node_or_null("GridLines/Vertical_00") != null, "first room owns editable TileMap board art nodes")
	_expect(main_room != null and main_room.get_node_or_null("Blocker_07_02") != null and main_room.get_node("Blocker_07_02").has_method("get_blocked_cell"), "first room owns draggable blocker markers")
	_expect(main_hero_start_marker != null and main_hero_start_marker.get("grid_cell") == main_hero_start_cell, "first room owns an editable hero start marker")
	main_game.free()

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
	var knight_move_world := GridWorld.new()
	root.add_child(knight_move_world)
	var knight_mover := KnightEnemy.new()
	root.add_child(knight_mover)
	_expect(knight_mover.setup(knight_move_world, Vector2i(8, 4)), "knight mover registers")
	var knight_move_options := knight_mover.get_cardinal_move_options()
	_expect(Vector2i(10, 5) in knight_move_options and Vector2i(9, 4) not in knight_move_options, "knight legal moves use L-shaped destinations instead of pawn steps")
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

	var occupied_pickup := WeaponPickup.new()
	root.add_child(occupied_pickup)
	_expect(occupied_pickup.setup(ai_world, ai_hero.current_cell, EnemyWeapon.pencil_spear()), "occupied weapon objective registers")
	_expect(thinking_pawn._nearest_item_cell([ai_hero.current_cell]) == Vector2i(-999, -999), "enemy rejects an occupied weapon as a movement goal")
	var setup_goal := thinking_pawn._find_attack_setup_goal(turn_context)
	_expect(setup_goal != ai_hero.current_cell and ai_world.is_plannable_cell(thinking_pawn, setup_goal), "enemy chooses a reachable attack-setup cell around the player")

	_expect(ai_director.can_request_attack(thinking_pawn), "director reports an available attack token")
	ai_director.request_attack(thinking_pawn)
	_expect(not ai_director.can_request_attack(knight), "director exposes token denial to other enemy decisions")

	var attack_world := GridWorld.new()
	root.add_child(attack_world)
	var attack_board := PrototypeBoard.new()
	root.add_child(attack_board)
	attack_board.setup(attack_world)
	var attack_hero := PawnHero.new()
	root.add_child(attack_hero)
	_expect(attack_hero.setup(attack_world, Vector2i(5, 5)), "attack lifecycle hero registers")
	var attacking_pawn := BlackPawn.new()
	root.add_child(attacking_pawn)
	_expect(attacking_pawn.setup(attack_world, Vector2i(4, 4)), "attack lifecycle enemy registers")
	attacking_pawn.facing = Vector2i.DOWN
	var attack_director := EncounterDirector.new()
	root.add_child(attack_director)
	attacking_pawn.telegraph_started.connect(attack_board.set_telegraph)
	attacking_pawn.telegraph_finished.connect(attack_board.clear_telegraph)
	attacking_pawn.attack_resolved.connect(attack_board.show_enemy_attack)
	attacking_pawn.intent_changed.connect(attack_board.set_enemy_intent)
	attacking_pawn.activate(attack_hero, attack_director)
	attacking_pawn._choose_action()
	_expect(attacking_pawn.state == FreeEnemy.State.TELEGRAPH and attack_board.telegraphs.has(attacking_pawn), "enemy attack enters telegraph with board signals connected")
	var damage_events := {"count": 0}
	attack_hero.damaged.connect(func(_amount: int, _remaining: int) -> void: damage_events["count"] += 1)
	attacking_pawn._resolve_attack()
	_expect(attack_hero.courage == 2, "enemy attack resolves damage once")
	_expect(damage_events["count"] == 1, "hero damage emits one feedback event")
	_expect(not attack_board.telegraphs.has(attacking_pawn) and attack_director.attack_owner == null, "attack resolution clears telegraph and token")

	attacking_pawn.state = FreeEnemy.State.OBSERVE
	attacking_pawn.action_memory.clear()
	attacking_pawn._choose_action()
	_expect(attack_board.telegraphs.has(attacking_pawn), "second attack telegraph begins")
	attacking_pawn.take_damage(2)
	_expect(not attack_board.telegraphs.has(attacking_pawn) and attack_director.attack_owner == null, "defeat during attack safely clears telegraph and token")

	print("TESTS COMPLETE: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)


func _piece_visual_is_sprite_animated(visual: Node, sync_method: StringName) -> bool:
	if visual == null or not visual.has_method(sync_method):
		return false
	return visual.get_node_or_null("MotionRoot/SpriteRoot/BodySprite") is Sprite2D \
		and visual.get_node_or_null("AnimationPlayer") is AnimationPlayer


func _visual_has_clip(visual: Node, clip: StringName) -> bool:
	if visual == null:
		return false
	var player := visual.get_node_or_null("AnimationPlayer") as AnimationPlayer
	return player != null and player.has_animation(clip)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)
