extends SceneTree

## The data + structure suite: EcsGrid cell rules, the actor scenes as pure
## views (ActorView + sprites + AnimationPlayer, no gameplay scripts), and the
## editor-authored .tres content every entity spawns from. Simulation behavior
## lives in ecs_runtime / ecs_combat / ecs_enemy tests.

var failures := 0


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)


func _actor_is_sprite_animated(actor: Node) -> bool:
	if actor == null:
		return false
	return actor.get_node_or_null("MotionRoot/SpriteRoot/BodySprite") is Sprite2D \
		and actor.get_node_or_null("AnimationPlayer") is AnimationPlayer


func _actor_has_clip(actor: Node, clip: StringName) -> bool:
	if actor == null:
		return false
	var player := actor.get_node_or_null("AnimationPlayer") as AnimationPlayer
	return player != null and player.has_animation(clip)


## The editor-owned animation state graph: an active AnimationTree whose state
## machine drives the sibling AnimationPlayer.
func _actor_has_state_graph(actor: Node) -> bool:
	if actor == null:
		return false
	var tree := actor.get_node_or_null("AnimationTree") as AnimationTree
	return tree != null and tree.active and tree.tree_root is AnimationNodeStateMachine


func _view(scene_path: String) -> ActorView:
	var view := (load(scene_path) as PackedScene).instantiate() as ActorView
	root.add_child(view)
	return view


func _init() -> void:
	# --- EcsGrid: the cell rules every system relies on ---
	var grid := EcsGrid.new()
	_expect(grid.register_entity(1, Vector2i(1, 1)), "entity registers on an empty cell")
	_expect(not grid.register_entity(2, Vector2i(1, 1)), "occupied cell rejects a second entity")
	_expect(grid.add_block(Vector2i(2, 1)), "empty cell accepts a block")
	_expect(not grid.add_block(Vector2i(1, 1)), "occupied cell rejects a block")
	_expect(not grid.can_begin_move(1, Vector2i(2, 1)), "blocked cell rejects movement")
	_expect(grid.begin_move(1, Vector2i(1, 2)), "free cell accepts a reservation")
	_expect(not grid.register_entity(3, Vector2i(1, 2)), "reserved cell rejects a spawner")
	grid.finish_move(1, Vector2i(1, 2))
	_expect(grid.entity_at(Vector2i(1, 2)) == 1 and grid.entity_at(Vector2i(1, 1)) == 0, "finish_move transfers occupancy and releases origin")
	var routed_path := grid.get_grid_path(1, Vector2i(1, 2), Vector2i(3, 2))
	_expect(routed_path.size() > 0, "A* returns a path on the open board")
	grid.add_block(Vector2i(2, 2))
	routed_path = grid.get_grid_path(1, Vector2i(1, 2), Vector2i(3, 2))
	_expect(routed_path.size() > 3 and Vector2i(2, 2) not in routed_path, "A* path routes around blocked cells")
	_expect(grid.get_next_path_cell(1, Vector2i(1, 2), Vector2i(3, 2)) != Vector2i(2, 2), "next path cell never enters a blocker")
	_expect(grid.cell_to_world(Vector2i.ZERO) == Vector2(80, 52), "cell centers derive from grid origin + half cell")
	_expect(grid.world_to_cell(Vector2(110, 229)) == Vector2i(1, 6), "world positions floor to their containing cell")

	# --- The player scene is a pure view + spawn data ---
	var hero_view := _view("res://objects/actors/player.tscn")
	_expect(hero_view != null, "player scene root is an ActorView (no gameplay script)")
	_expect(_actor_is_sprite_animated(hero_view), "player view owns its sprites and AnimationPlayer")
	_expect(_actor_has_clip(hero_view, &"step") and _actor_has_clip(hero_view, &"attack"), "player view owns step/attack clips")
	_expect(_actor_has_clip(hero_view, &"defeat"), "player view owns an editor-authored defeat clip")
	_expect(hero_view.get_node_or_null("AudioPlayer") is AudioStreamPlayer, "player view carries the clip-keyed audio player")
	_expect(hero_view.definition == null, "player view has no enemy definition")
	_expect(hero_view.get_node_or_null("Camera2D") is CameraRig, "player view carries the camera rig")
	var hero_health_node := hero_view.get_node_or_null("HealthComponent") as HealthComponent
	_expect(hero_health_node != null and hero_health_node.max_health == 3, "player view carries an editor-tunable HealthComponent node")
	var hero_combat_node := hero_view.get_node_or_null("CombatComponent") as CombatComponent
	_expect(hero_combat_node != null and hero_combat_node.wooden_sword != null \
		and hero_combat_node.wooden_sword.resource_path.ends_with("wooden_sword.tres") \
		and hero_combat_node.pencil_thrust != null, "CombatComponent node carries the attack loadout")
	_expect(hero_view.get_node_or_null("MovementComponent") is MovementComponent \
		and hero_view.get_node_or_null("InputComponent") is InputComponent, "player view carries movement and input component nodes")
	_expect(_actor_has_state_graph(hero_view), "player animation transitions live in an editor AnimationTree graph")
	var view_source := FileAccess.get_file_as_string("res://scripts/ecs/actor_view.gd")
	_expect(not view_source.contains("func _draw") and not view_source.contains("func _process"), "actor views hold no logic at all")

	# --- Enemy scenes are views + definitions ---
	var expected_definitions := {
		"res://objects/actors/black_pawn.tscn": &"pawn_recruit",
		"res://objects/actors/knight_enemy.tscn": &"knight_tracker",
		"res://objects/actors/bishop_enemy.tscn": &"bishop_zoner",
		"res://objects/actors/enemy_base.tscn": &"pawn_recruit",
	}
	for scene_path: String in expected_definitions:
		var enemy_view := _view(scene_path)
		var scene_name := scene_path.get_file()
		_expect(enemy_view != null and enemy_view.definition != null, "%s is an ActorView with a definition" % scene_name)
		_expect(enemy_view.definition.id == expected_definitions[scene_path], "%s carries its own EnemyDefinition" % scene_name)
		_expect(enemy_view.definition.validate().is_empty(), "%s definition has no missing configuration" % scene_name)
		_expect(_actor_is_sprite_animated(enemy_view) and _actor_has_clip(enemy_view, &"telegraph"), "%s owns sprites + telegraph clip" % scene_name)
		_expect(_actor_has_clip(enemy_view, &"defeat") and enemy_view.get_node_or_null("AudioPlayer") is AudioStreamPlayer, "%s owns defeat clip + audio player" % scene_name)
		_expect(_actor_has_state_graph(enemy_view), "%s animation transitions live in an editor AnimationTree graph" % scene_name)

	# --- Editor-authored combat data (the .tres stays the truth) ---
	var pawn_definition := load("res://resources/enemies/pawn_recruit.tres") as EnemyDefinition
	var pattern_cells := pawn_definition.unarmed_attack.get_attack_cells(grid, Vector2i(6, 3), Vector2i.DOWN)
	_expect(Vector2i(5, 4) in pattern_cells and Vector2i(7, 4) in pattern_cells, "pawn pattern threatens both forward diagonals")
	pattern_cells = pawn_definition.unarmed_attack.get_attack_cells(grid, Vector2i(6, 3), Vector2i.RIGHT)
	_expect(Vector2i(7, 4) in pattern_cells and Vector2i(7, 2) in pattern_cells, "pawn diagonal attack rotates with facing")

	var armed_definition := load("res://resources/enemies/pawn_armed.tres") as EnemyDefinition
	_expect(armed_definition.validate().is_empty(), "armed Pawn definition has no missing configuration")
	_expect(armed_definition.default_weapon != null and armed_definition.default_weapon.display_name == "Pencil Spear", "armed Pawn default weapon is Inspector-configured")

	var knight_definition := load("res://resources/enemies/knight_tracker.tres") as EnemyDefinition
	_expect(knight_definition.movement.allowed_directions.size() == 8, "knight movement config exposes eight L-shaped offsets")
	_expect(Vector2i(2, 1) in knight_definition.movement.allowed_directions and Vector2i.RIGHT not in knight_definition.movement.allowed_directions, "knight movement does not fall back to cardinal steps")
	_expect(knight_definition.decision.role_policy == &"flanker", "knight definition configures a flanker")

	var bishop_definition := load("res://resources/enemies/bishop_zoner.tres") as EnemyDefinition
	_expect(bishop_definition.movement.allowed_directions.has(Vector2i(1, 1)) and not bishop_definition.movement.allowed_directions.has(Vector2i.RIGHT), "Bishop moves diagonally from its MovementConfig")
	var bishop_cells := bishop_definition.unarmed_attack.get_attack_cells(grid, Vector2i(8, 4), Vector2i.DOWN)
	_expect(bishop_cells.size() == 8 and Vector2i(10, 6) in bishop_cells and Vector2i(9, 5) in bishop_cells, "Bishop unarmed attack threatens diagonal beams from data")
	_expect(bishop_definition.decision.role_policy == &"sniper" and bishop_definition.decision.preferred_distance == 3 and is_equal_approx(bishop_definition.decision.flank_bonus, 24.0), "Bishop AI personality is a pure DecisionConfig .tres")

	var spear := EnemyWeapon.pencil_spear()
	var second_spear := EnemyWeapon.pencil_spear()
	_expect(spear.resource_path.is_empty() and spear != second_spear, "weapon factory returns independent instances from the editor asset")
	_expect(spear.range_cells == 2 and spear.telegraph_time == 0.62, "Pencil Spear values load from its Resource")
	_expect(spear.texture != null and spear.texture.resource_path.ends_with("pencil_spear.png"), "Pencil Spear carries its sprite as data")

	var attack_profile := AttackProfile.new()
	attack_profile.range_cells = 2
	_expect(attack_profile.get_target_cells(Vector2i(4, 4), Vector2i.RIGHT) == [Vector2i(5, 4), Vector2i(6, 4)], "attack profile produces ordered range cells")

	var objective_script := load("res://scripts/data/room_objective.gd")
	var clear_objective: Resource = objective_script.new()
	_expect(not bool(clear_objective.call("is_complete", 1, 3, 2)), "clear-all objective waits while enemies remain")
	_expect(bool(clear_objective.call("is_complete", 3, 3, 0)), "clear-all objective completes when all enemies fall")
	var count_objective: Resource = objective_script.new()
	count_objective.win_condition = 1
	count_objective.required_defeats = 2
	_expect(not bool(count_objective.call("is_complete", 1, 3, 2)), "defeat-count objective waits for its configured count")
	_expect(bool(count_objective.call("is_complete", 2, 3, 1)), "defeat-count objective can complete before all enemies fall")

	var pickup_visual_source := FileAccess.get_file_as_string("res://scripts/visuals/pickup_visual.gd")
	_expect(not pickup_visual_source.contains("func _draw") and not pickup_visual_source.contains("draw_"), "pickup visuals use Sprite2D nodes instead of script drawing")

	# --- The sound structure: bus layout + event-sound registry ---
	var bus_layout := load("res://default_bus_layout.tres") as AudioBusLayout
	_expect(bus_layout != null, "the audio bus layout loads")
	var sfx_scene := load("res://objects/audio/sfx_manager.tscn") as PackedScene
	var sfx_manager := sfx_scene.instantiate()
	root.add_child(sfx_manager)
	var registry: Dictionary = sfx_manager.get("streams")
	_expect(registry.has(&"pickup") and registry.has(&"room_clear") and registry.has(&"defeat_jingle") and registry.has(&"gate_open"), "SfxManager registry carries the four event sounds")
	_expect(StringName(sfx_manager.get("bus")) == &"SFX", "SfxManager routes to the SFX bus")

	# Music: an editor-owned looping AudioStreamPlayer in the main scene, no code.
	var main_scene := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	var music_player := main_scene.get_node_or_null("MusicPlayer") as AudioStreamPlayer
	_expect(music_player != null and music_player.autoplay, "main scene carries an autoplaying MusicPlayer")
	_expect(music_player != null and music_player.bus == &"Music", "MusicPlayer routes to the Music bus")
	var music_stream: AudioStreamWAV = music_player.stream as AudioStreamWAV if music_player != null else null
	_expect(music_stream != null and music_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "music track loops from its embedded WAV loop points")

	# Demo posture: debug overlay is an Inspector checkbox that ships off,
	# and the game window ships fullscreen (F11 toggles at runtime).
	_expect(not bool(main_scene.get("debug_enabled")), "debug overlay ships off (Inspector checkbox on Main)")
	_expect(int(ProjectSettings.get_setting("display/window/size/mode", 0)) == 3, "game window ships fullscreen")
	main_scene.free()

	# --- The world graph: every zone loads, every door resolves ---
	var world_graph := load("res://resources/world/world_graph.tres") as WorldGraph
	_expect(world_graph != null and world_graph.validate().is_empty(), "the world graph loads with zones")
	var entry_ids_by_zone := {}
	var zone_roots := {}
	for zone_id: StringName in world_graph.zone_scene_by_id:
		var zone_root := world_graph.get_zone_scene(zone_id).instantiate()
		root.add_child(zone_root)
		zone_roots[zone_id] = zone_root
		_expect(StringName(zone_root.get("zone_id")) == zone_id, "zone '%s' carries its own zone_id" % zone_id)
		var board: Vector2i = zone_root.get("board_size")
		_expect(board.x >= 8 and board.y >= 7, "zone '%s' board is at least an arena" % zone_id)
		var entry_ids: Array = []
		for child in zone_root.get_children():
			if child is ZoneEntryMarker:
				entry_ids.append(child.entry_id)
		entry_ids_by_zone[zone_id] = entry_ids
		_expect(not entry_ids.is_empty(), "zone '%s' has at least one entry marker" % zone_id)
	for zone_id: StringName in zone_roots:
		for child in zone_roots[zone_id].get_children():
			if child is ZoneExitMarker:
				var exit_label := "%s/%s" % [zone_id, child.name]
				_expect(world_graph.has_zone(child.target_zone), "door %s targets a zone in the graph" % exit_label)
				_expect(child.target_entry in entry_ids_by_zone.get(child.target_zone, []), "door %s lands on a real entry marker" % exit_label)

	# --- WorldState survives a save/load round trip ---
	var world_state_script := load("res://scripts/world/world_state.gd")
	var saved_state: Node = world_state_script.new()
	saved_state.current_zone_id = &"bookshelf_pass"
	saved_state.last_entry_id = &"from_yard"
	saved_state.taken_pickup_ids["toybox_yard/PencilSpearPickup"] = true
	saved_state.opened_gate_ids["pass_home_gate"] = true
	saved_state.save_state("user://test_world_state.cfg")
	var loaded_state: Node = world_state_script.new()
	loaded_state.load_state("user://test_world_state.cfg")
	_expect(loaded_state.current_zone_id == &"bookshelf_pass" and loaded_state.last_entry_id == &"from_yard" \
		and loaded_state.taken_pickup_ids.has("toybox_yard/PencilSpearPickup") \
		and loaded_state.opened_gate_ids.has("pass_home_gate"), "WorldState survives a save/load round trip")
	saved_state.free()
	loaded_state.free()

	# --- Pawn variants stay pure data ---
	var backstep := load("res://resources/enemies/backstep_pawn.tres") as EnemyDefinition
	_expect(backstep != null and backstep.validate().is_empty(), "Backstep Pawn definition has no missing configuration")
	var charging := load("res://resources/enemies/charging_pawn.tres") as EnemyDefinition
	_expect(charging != null and charging.validate().is_empty(), "Charging Pawn definition has no missing configuration")
	_expect(charging.movement.allowed_directions.has(Vector2i(0, 2)) and not charging.movement.allowed_directions.has(Vector2i.UP), "Charging Pawn only ever leaps two squares")

	# --- The Book of House Rules: every page names a real piece, UI renders ---
	var rule_book := load("res://resources/rules/rule_book.tres") as RuleBook
	_expect(rule_book != null and rule_book.validate().is_empty(), "the rule book loads with complete pages")
	var definition_ids: Array = []
	for file_name in DirAccess.get_files_at("res://resources/enemies"):
		if file_name.ends_with(".tres"):
			var definition := load("res://resources/enemies/%s" % file_name) as EnemyDefinition
			if definition != null:
				definition_ids.append(definition.id)
	for entry in rule_book.entries:
		_expect(entry.piece_id in definition_ids, "book page '%s' names a real piece" % entry.title)
	var book_ui := (load("res://scenes/ui/rule_book.tscn") as PackedScene).instantiate() as RuleBookUI
	root.add_child(book_ui)
	book_ui.refresh([&"pawn_recruit"])
	_expect(book_ui.entry_list.item_count == rule_book.entries.size(), "book UI lists every page")
	_expect(book_ui.count_label.text.begins_with("1 of"), "book UI counts known amendments")
	_expect(book_ui.entry_list.get_item_text(book_ui.entry_list.item_count - 1) == "Unread ink", "unmet pieces stay unread ink")

	print("TESTS COMPLETE: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
