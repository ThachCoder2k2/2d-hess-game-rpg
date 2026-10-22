extends SceneTree

## The data + structure suite: EcsGrid cell rules, the actor scenes as pure
## views (ActorView + sprites + AnimationPlayer, no gameplay scripts), and the
## editor-authored .tres content every entity spawns from. Simulation behavior
## lives in ecs_runtime / ecs_combat / ecs_enemy tests.

const SaveSupport := preload("res://tests/support/save_test_support.gd")

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


## True when the actor's state graph leaves its Start node into `state` — the
## boot pose is graph-owned, so nothing in script has to kick it off.
func _graph_starts_in(actor: Node, state: StringName) -> bool:
	var tree := actor.get_node_or_null("AnimationTree") as AnimationTree
	if tree == null:
		return false
	var graph := tree.tree_root as AnimationNodeStateMachine
	if graph == null:
		return false
	for index in graph.get_transition_count():
		if graph.get_transition_from(index) == &"Start" and graph.get_transition_to(index) == state:
			return true
	return false


func _view(scene_path: String) -> ActorView:
	var view := (load(scene_path) as PackedScene).instantiate() as ActorView
	root.add_child(view)
	return view


func _init() -> void:
	TextService.set_language(TextService.SOURCE_LANGUAGE)  # this suite reads the English words
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
	var hero_view := _view("res://presentation/views/actors/player.tscn")
	_expect(hero_view != null, "player scene root is an ActorView (no gameplay script)")
	_expect(_actor_is_sprite_animated(hero_view), "player view owns its sprites and AnimationPlayer")
	_expect(_actor_has_clip(hero_view, &"step") and _actor_has_clip(hero_view, &"attack"), "player view owns step/attack clips")
	_expect(_actor_has_clip(hero_view, &"defeat"), "player view owns an editor-authored defeat clip")
	_expect(_actor_has_clip(hero_view, &"wake") and _graph_starts_in(hero_view, &"wake"), "the hero boots into the wake clip, then falls through to idle")
	_expect(hero_view.get_node_or_null("AudioPlayer") is AudioStreamPlayer, "player view carries the clip-keyed audio player")
	_expect(hero_view.definition == null, "player view has no enemy definition")
	_expect(hero_view.get_node_or_null("Camera2D") is CameraRig, "player view carries the camera rig")
	# The hero's tuning is content/player/player.tres (a PlayerDefinition), not Inspector values on
	# component nodes of the scene; EntityComponent nodes are optional per-instance overrides.
	var hero_definition := hero_view.player_definition
	_expect(hero_definition != null and hero_definition.resource_path == "res://content/player/player.tres" \
		and hero_definition.max_courage >= 1 and hero_definition.invulnerability_duration > 0.0, "player view names content/player/player.tres, which carries the courage and invulnerability")
	_expect(hero_definition != null and hero_definition.wooden_sword != null \
		and hero_definition.wooden_sword.resource_path.ends_with("wooden_sword.tres") \
		and hero_definition.pencil_thrust != null, "PlayerDefinition carries the attack loadout")
	var hero_component_node_count := 0
	for hero_child in hero_view.get_children():
		if hero_child is EntityComponent:
			hero_component_node_count += 1
	_expect(hero_definition != null and hero_definition.step_duration > 0.0 and hero_definition.held_repeat_delay > 0.0 \
		and hero_component_node_count == 0, "PlayerDefinition carries the step and hold timings, so the view carries no component nodes")
	_expect(_actor_has_state_graph(hero_view), "player animation transitions live in an editor AnimationTree graph")
	var view_source := FileAccess.get_file_as_string("res://presentation/views/actor_view.gd")
	# A moved file reads as "", which would make the "does not contain" check pass for nothing.
	_expect(not view_source.is_empty() and not view_source.contains("func _draw") and not view_source.contains("func _process"), "actor views hold no logic at all")

	# --- Enemy scenes are views + definitions ---
	var expected_definitions := {
		"res://presentation/views/actors/black_pawn.tscn": &"pawn_recruit",
		"res://presentation/views/actors/knight_enemy.tscn": &"knight_tracker",
		"res://presentation/views/actors/bishop_enemy.tscn": &"bishop_zoner",
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
	var pawn_definition := load("res://content/enemies/pawn_recruit/enemy.tres") as EnemyDefinition
	var pattern_cells := pawn_definition.unarmed_attack.get_attack_cells(grid, Vector2i(6, 3), Vector2i.DOWN)
	_expect(Vector2i(5, 4) in pattern_cells and Vector2i(7, 4) in pattern_cells, "pawn pattern threatens both forward diagonals")
	pattern_cells = pawn_definition.unarmed_attack.get_attack_cells(grid, Vector2i(6, 3), Vector2i.RIGHT)
	_expect(Vector2i(7, 4) in pattern_cells and Vector2i(7, 2) in pattern_cells, "pawn diagonal attack rotates with facing")

	var armed_definition := load("res://content/enemies/pawn_armed/enemy.tres") as EnemyDefinition
	_expect(armed_definition.validate().is_empty(), "armed Pawn definition has no missing configuration")
	_expect(armed_definition.default_weapon != null and TextService.t(armed_definition.default_weapon.display_name) == "Pencil Spear", "armed Pawn default weapon is Inspector-configured")

	var knight_definition := load("res://content/enemies/knight_tracker/enemy.tres") as EnemyDefinition
	_expect(knight_definition.movement.allowed_directions.size() == 8, "knight movement config exposes eight L-shaped offsets")
	_expect(Vector2i(2, 1) in knight_definition.movement.allowed_directions and Vector2i.RIGHT not in knight_definition.movement.allowed_directions, "knight movement does not fall back to cardinal steps")
	_expect(knight_definition.decision.role_policy == &"flanker", "knight definition configures a flanker")

	var bishop_definition := load("res://content/enemies/bishop_zoner/enemy.tres") as EnemyDefinition
	_expect(bishop_definition.movement.allowed_directions.has(Vector2i(1, 1)) and not bishop_definition.movement.allowed_directions.has(Vector2i.RIGHT), "Bishop moves diagonally from its MovementConfig")
	var bishop_cells := bishop_definition.unarmed_attack.get_attack_cells(grid, Vector2i(8, 4), Vector2i.DOWN)
	_expect(bishop_cells.size() == 8 and Vector2i(10, 6) in bishop_cells and Vector2i(9, 5) in bishop_cells, "Bishop unarmed attack threatens diagonal beams from data")
	_expect(bishop_definition.decision.role_policy == &"sniper" and bishop_definition.decision.preferred_distance == 3 and is_equal_approx(bishop_definition.decision.flank_bonus, 24.0), "Bishop AI personality is a pure DecisionConfig .tres")

	var spear := EnemyWeapon.pencil_spear()
	var second_spear := EnemyWeapon.pencil_spear()
	_expect(spear.resource_path.is_empty() and spear != second_spear, "weapon factory returns independent instances from the editor asset")
	_expect(spear.range_cells == 2 and spear.telegraph_time == 0.62, "Pencil Spear values load from its Resource")
	_expect(spear.texture != null and spear.texture.resource_path.ends_with("pickups/pencil_spear/icon.png"), "Pencil Spear carries its sprite as data")

	var attack_profile := AttackProfile.new()
	attack_profile.range_cells = 2
	_expect(attack_profile.get_target_cells(Vector2i(4, 4), Vector2i.RIGHT) == [Vector2i(5, 4), Vector2i(6, 4)], "attack profile produces ordered range cells")

	var objective_script := load("res://schema/world/room_objective.gd")
	var clear_objective: Resource = objective_script.new()
	_expect(not bool(clear_objective.call("is_complete", 1, 3, 2)), "clear-all objective waits while enemies remain")
	_expect(bool(clear_objective.call("is_complete", 3, 3, 0)), "clear-all objective completes when all enemies fall")
	var count_objective: Resource = objective_script.new()
	count_objective.win_condition = 1
	count_objective.required_defeats = 2
	_expect(not bool(count_objective.call("is_complete", 1, 3, 2)), "defeat-count objective waits for its configured count")
	_expect(bool(count_objective.call("is_complete", 2, 3, 1)), "defeat-count objective can complete before all enemies fall")

	var pickup_visual_source := FileAccess.get_file_as_string("res://presentation/views/pickup_visual.gd")
	# Same guard as above: an empty read (a moved file) must fail, not pass vacuously.
	_expect(not pickup_visual_source.is_empty() and not pickup_visual_source.contains("func _draw") and not pickup_visual_source.contains("draw_"), "pickup visuals use Sprite2D nodes instead of script drawing")

	# --- The sound structure: bus layout + event-sound registry ---
	var bus_layout := load("res://default_bus_layout.tres") as AudioBusLayout
	_expect(bus_layout != null, "the audio bus layout loads")
	var sfx_scene := load("res://presentation/audio/sfx_manager.tscn") as PackedScene
	var sfx_manager := sfx_scene.instantiate()
	root.add_child(sfx_manager)
	var registry: Dictionary = sfx_manager.get("streams")
	_expect(registry.has(&"pickup") and registry.has(&"room_clear") and registry.has(&"defeat_jingle") and registry.has(&"gate_open"), "SfxManager registry carries the four event sounds")
	_expect(StringName(sfx_manager.get("bus")) == &"SFX", "SfxManager routes to the SFX bus")

	# Music: an editor-owned looping AudioStreamPlayer in the main scene, no code. The main scene is AppRoot since
	# M4 (the player moved out of the game scene so a death, a room change and a trip to the title never restart it).
	var main_scene := (load("res://shell/app_root.tscn") as PackedScene).instantiate()
	var music_player := main_scene.get_node_or_null("MusicPlayer") as AudioStreamPlayer
	_expect(music_player != null and music_player.autoplay, "main scene carries an autoplaying MusicPlayer")
	_expect(music_player != null and music_player.bus == &"Music", "MusicPlayer routes to the Music bus")
	var music_stream: AudioStreamWAV = music_player.stream as AudioStreamWAV if music_player != null else null
	_expect(music_stream != null and music_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "music track loops from its embedded WAV loop points")

	main_scene.free()

	# Demo posture: debug overlay is an Inspector checkbox that ships off (on the in-game scene),
	# and the game window ships fullscreen (F11 toggles at runtime).
	var game_scene := (load("res://shell/game_root.tscn") as PackedScene).instantiate()
	_expect(not bool(game_scene.get("debug_enabled")), "debug overlay ships off (Inspector checkbox on Main)")
	_expect(int(ProjectSettings.get_setting("display/window/size/mode", 0)) == 3, "game window ships fullscreen")
	game_scene.free()

	# --- The world graph: every zone loads, every door resolves ---
	var world_graph := load("res://content/world/world.tres") as WorldGraph
	_expect(world_graph != null and world_graph.validate().is_empty(), "the world graph loads with zones")
	var entry_ids_by_zone := {}
	var zone_roots := {}
	# M5 moved the world graph to rooms, edges, slots and locks (content/world/world.tres, tests/content/test_world_graph.gd
	# holds the rest of its rules) and took the 72x40 kingdom out of it: it is a test fixture now (plan D-02), so these
	# zone checks reach it by its fixture path and keep covering it.
	var scene_by_zone := {}
	for zone_id: StringName in world_graph.room_ids():
		scene_by_zone[zone_id] = world_graph.get_zone_scene(zone_id)
	scene_by_zone[&"kingdom"] = load("res://tests/fixtures/the_kingdom.tscn")
	for zone_id: StringName in scene_by_zone:
		var zone_root := (scene_by_zone[zone_id] as PackedScene).instantiate()
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
				if child.ends_run:
					# The one door that ends the run (the Desk, M5 step 2) leads nowhere on purpose.
					_expect(child.target_zone == &"", "door %s ends the run, so it names no zone" % exit_label)
					continue
				_expect(world_graph.has_zone(child.target_zone), "door %s targets a zone in the graph" % exit_label)
				_expect(child.target_entry in entry_ids_by_zone.get(child.target_zone, []), "door %s lands on a real entry marker" % exit_label)
				if zone_id == &"t3_first_pawn_clash" and child.name == "Exit_To_T4":
					_expect(child.requires_room_clear, "first duel forward exit requires clearing the room")
				if zone_id == &"t4_broken_rule_yard" and child.name == "Exit_To_B1":
					_expect(child.requires_room_clear, "rule-break forward exit requires clearing the room")
				if zone_id == &"b1_black_pawn_captain" and child.name == "Exit_To_Hub":
					_expect(child.requires_room_clear, "boss hub exit requires clearing the boss room")

	var t2_world := EcsWorld.new()
	EcsBoot.boot(t2_world, EcsBootOptions.for_scene(null, zone_roots[&"t2_fallen_sword_tile"]))
	var t2_unlock: Dictionary = t2_world.grid.player_unlock_by_cell.get(Vector2i(6, 5), {})
	_expect(not t2_unlock.is_empty() and t2_unlock.get("id") == &"wooden_sword", "T2 sword unlock sits on the obvious reachable sword cell")
	_expect(t2_world.grid.is_walkable(Vector2i(6, 5)), "T2 sword unlock cell is walkable")

	# --- The save survives a write/read round trip (SaveService v3; the WorldState checks of M1a) ---
	var save_root := "user://test_saves/run_tests_%d" % OS.get_process_id()
	var save_service_script := load("res://shell/save/save_service.gd")
	var saved_service: Node = save_service_script.new()
	saved_service.configure(save_root)
	saved_service.new_game(0)
	saved_service.state.checkpoint_zone_id = &"bookshelf_pass"
	saved_service.state.checkpoint_entry_id = &"from_yard"
	saved_service.state.taken_pickup_ids["toybox_yard/PencilSpearPickup"] = true
	saved_service.state.opened_gate_ids["pass_home_gate"] = true
	saved_service.request_save(&"checkpoint_reached")
	var loaded_service: Node = save_service_script.new()
	loaded_service.configure(save_root)
	loaded_service.load_slot(0)
	_expect(loaded_service.state.checkpoint_zone_id == &"bookshelf_pass" and loaded_service.state.checkpoint_entry_id == &"from_yard" \
		and loaded_service.state.taken_pickup_ids.has("toybox_yard/PencilSpearPickup") \
		and loaded_service.state.opened_gate_ids.has("pass_home_gate"), "the save survives a write/read round trip")
	loaded_service.state.add_unlock(&"wooden_sword")
	loaded_service.request_save(&"unlock_gained")
	var unlock_service: Node = save_service_script.new()
	unlock_service.configure(save_root)
	unlock_service.load_slot(0)
	_expect(unlock_service.state.has_unlock(&"wooden_sword"), "the save remembers player weapon unlocks")
	# What WorldState wrote before it had a version: no [meta] at all. It used to be wiped silently; it is
	# not read, a clean run starts, and the old file stays where it is (docs/game-base-plan.md 9.2).
	var old_save_root := save_root + "_old"
	DirAccess.make_dir_recursive_absolute(old_save_root)
	var old_file := ConfigFile.new()
	old_file.set_value("world", "current_zone_id", "kingdom")
	old_file.save(old_save_root.path_join("world_state.cfg"))
	var old_service: Node = save_service_script.new()
	old_service.configure(old_save_root)
	old_service.load_slot(0)
	_expect(old_service.state.checkpoint_zone_id == &"" and old_service.state.checkpoint_entry_id == &"start" \
		and old_service.last_load.outcome == &"new_game_obsolete_save" and FileAccess.file_exists(old_save_root.path_join("world_state.cfg")), \
		"an obsolete save version is not read and not wiped: a clean new game starts")
	for service_to_free: Node in [saved_service, loaded_service, unlock_service, old_service]:
		service_to_free.free()
	for folder_to_remove in [save_root, old_save_root]:
		SaveSupport.remove_root(folder_to_remove)

	# --- Pawn variants stay pure data ---
	var backstep := load("res://content/enemies/backstep_pawn/enemy.tres") as EnemyDefinition
	_expect(backstep != null and backstep.validate().is_empty(), "Backstep Pawn definition has no missing configuration")
	var charging := load("res://content/enemies/charging_pawn/enemy.tres") as EnemyDefinition
	_expect(charging != null and charging.validate().is_empty(), "Charging Pawn definition has no missing configuration")
	_expect(charging.movement.allowed_directions.has(Vector2i(0, 2)) and not charging.movement.allowed_directions.has(Vector2i.UP), "Charging Pawn only ever leaps two squares")

	# --- The Book of House Rules: every page names a real piece, UI renders ---
	var rule_book := load("res://content/rules/rule_book.tres") as RuleBook
	_expect(rule_book != null and rule_book.validate().is_empty(), "the rule book loads with complete pages")
	var definition_ids: Array = []
	# One folder per enemy id; a leading underscore (_shared) is not an enemy (plan 13.3).
	for folder_name in DirAccess.get_directories_at("res://content/enemies"):
		if folder_name.begins_with("_"):
			continue
		var definition := load("res://content/enemies/%s/enemy.tres" % folder_name) as EnemyDefinition
		if definition != null:
			definition_ids.append(definition.id)
	_expect(definition_ids.size() >= 7, "content/enemies holds at least seven enemy definitions (a missing folder cannot pass the book check below vacuously)")
	for entry in rule_book.entries:
		_expect(entry.piece_id in definition_ids, "book page '%s' names a real piece" % TextService.t(entry.title))
	var book_ui := (load("res://presentation/ui/codex/rule_book.tscn") as PackedScene).instantiate() as RuleBookUI
	root.add_child(book_ui)
	book_ui.refresh([&"pawn_recruit"])
	_expect(book_ui.entry_list.item_count == rule_book.entries.size(), "book UI lists every page")
	_expect(book_ui.count_label.text.begins_with("1 of"), "book UI counts known amendments")
	_expect(book_ui.entry_list.get_item_text(book_ui.entry_list.item_count - 1) == "Unread ink", "unmet pieces stay unread ink")

	print("TESTS COMPLETE: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
