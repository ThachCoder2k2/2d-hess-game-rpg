extends UnboundTest

## The hero's tuning is data (docs/game-base-plan.md 15 M2, 13.5 "Change how the pawn
## feels -> content/player/player.tres"): EcsBoot bakes the player's PlayerDefinition into
## the entity, a value set on an EntityComponent node of the instance still wins, and
## editing the definition changes the baked entity with no code. The deterministic dumps
## (tests/baselines) already prove the shipped definition bakes byte-for-byte what the
## four component nodes used to; this suite proves the mechanism around it.

const PLAYER_DEFINITION_PATH := "res://content/player/player.tres"

var paths: TestPaths


func _init() -> void:
	suite_title = "TEST PLAYER DEFINITION"
	paths = TestPaths.new(self)

	var definition := load(PLAYER_DEFINITION_PATH) as PlayerDefinition
	_expect(definition != null, "content/player/player.tres loads as a PlayerDefinition")
	if definition == null:
		finish()
		return
	_expect(definition.validate().is_empty(), "the shipped PlayerDefinition passes its own validate()")

	# The scene names the file; nothing about the hero's feel is left on the scene itself.
	var player_scene := paths.load_scene(paths.actor_scene(&"player"))
	var scene_view := player_scene.instantiate() as ActorView
	_expect(scene_view != null and scene_view.player_definition == definition, "the player view's player_definition is that same resource")
	var component_names: Array[String] = []
	for child in scene_view.get_children():
		if child is EntityComponent:
			component_names.append(String(child.name))
	_expect(component_names.is_empty(), "the player scene carries no EntityComponent node, so player.tres is the only source (found: %s)" % ", ".join(component_names))
	scene_view.free()

	# Bake: every field of the definition lands in the entity.
	var baked := _boot_player(definition, [])
	_expect_baked_fields_equal(baked["world"], baked["player_id"], definition, "the shipped definition")
	_expect(String(baked["cast"]["piece_name_by_entity"][baked["player_id"]]) == definition.piece_name, "the cast names the hero by the definition's piece_name")
	_expect(baked["world"].grid.entity_at(Vector2i(3, 3)) == baked["player_id"], "the hero spawns on the cell its view is parked on")
	_free_boot(baked)

	# Retune: a different definition gives a different entity, no code involved.
	var tuned := definition.duplicate() as PlayerDefinition
	tuned.max_courage = 7
	tuned.invulnerability_duration = 1.5
	tuned.step_duration = 0.31
	tuned.held_repeat_delay = 0.4
	tuned.skill_cooldown_duration = 2.5
	tuned.starts_with_sword = false
	tuned.piece_name = "Tuned Pawn"
	var tuned_boot := _boot_player(tuned, [])
	_expect_baked_fields_equal(tuned_boot["world"], tuned_boot["player_id"], tuned, "a retuned definition")
	_expect(String(tuned_boot["cast"]["piece_name_by_entity"][tuned_boot["player_id"]]) == "Tuned Pawn", "a retuned piece_name reaches the cast")
	_free_boot(tuned_boot)

	# A view with no definition plays on the class defaults (the values the hero had before the class existed).
	var bare := _boot_player(null, [])
	var defaults := PlayerDefinition.new()
	var bare_health: EcsComponents.Health = bare["world"].get_component(bare["player_id"], EcsComponents.HEALTH)
	var bare_move: EcsComponents.MoveState = bare["world"].get_component(bare["player_id"], EcsComponents.MOVE_STATE)
	_expect(bare_health.max_value == defaults.max_courage and is_equal_approx(bare_move.duration, defaults.step_duration), "a player view with no definition boots on the PlayerDefinition defaults")
	_free_boot(bare)

	# Override rule: a node on the instance beats the definition, field by field.
	var health_override := HealthComponent.new()
	health_override.max_health = 5
	health_override.invulnerability_duration = 0.2
	var movement_override := MovementComponent.new()
	movement_override.step_duration = 0.33
	var overridden := _boot_player(definition, [health_override, movement_override])
	var overridden_world: EcsWorld = overridden["world"]
	var overridden_id: int = overridden["player_id"]
	var overridden_health: EcsComponents.Health = overridden_world.get_component(overridden_id, EcsComponents.HEALTH)
	var overridden_move: EcsComponents.MoveState = overridden_world.get_component(overridden_id, EcsComponents.MOVE_STATE)
	var overridden_input: EcsComponents.PlayerInput = overridden_world.get_component(overridden_id, EcsComponents.PLAYER_INPUT)
	var overridden_combat: EcsComponents.PlayerCombat = overridden_world.get_component(overridden_id, EcsComponents.PLAYER_COMBAT)
	_expect(overridden_health.max_value == 5 and overridden_health.current == 5 and is_equal_approx(overridden_health.invulnerability_duration, 0.2), "a HealthComponent node on the view beats the definition's courage and invulnerability")
	_expect(is_equal_approx(overridden_move.duration, 0.33), "a MovementComponent node on the view beats the definition's step_duration")
	_expect(is_equal_approx(overridden_input.held_repeat_delay, definition.held_repeat_delay), "a field no node sets still comes from the definition (held_repeat_delay)")
	_expect(overridden_combat.wooden_sword == definition.wooden_sword and overridden_combat.pencil_thrust == definition.pencil_thrust, "the attack loadout still comes from the definition")
	_free_boot(overridden)

	# The old factory entry point keeps working.
	var legacy_world := EcsWorld.new()
	legacy_world.manual_tick = true
	root.add_child(legacy_world)
	var legacy_id := EcsActorFactory.spawn_player(legacy_world, Vector2i(2, 2), definition.wooden_sword, definition.pencil_thrust)
	var legacy_health: EcsComponents.Health = legacy_world.get_component(legacy_id, EcsComponents.HEALTH)
	var legacy_combat: EcsComponents.PlayerCombat = legacy_world.get_component(legacy_id, EcsComponents.PLAYER_COMBAT)
	_expect(legacy_health.max_value == 3 and legacy_health.current == 3 and legacy_combat.wooden_sword == definition.wooden_sword, "EcsActorFactory.spawn_player(world, cell, sword, pencil) still builds a hero")
	legacy_world.free()

	# validate() complains about each thing that would break the hero.
	var broken := PlayerDefinition.new()
	broken.max_courage = 0
	broken.step_duration = 0.0
	broken.held_repeat_delay = 0.0
	broken.skill_cooldown_duration = 0.0
	broken.piece_name = ""
	var broken_text := "\n".join(broken.validate())
	for fragment in ["piece_name", "max_courage", "step_duration", "held_repeat_delay", "skill_cooldown_duration", "wooden_sword", "pencil_thrust"]:
		_expect(broken_text.contains(fragment), "PlayerDefinition.validate() names %s when it is wrong" % fragment)
	finish()


## Boots a player view (parked on cell (3, 3)) holding `player_definition` plus the given
## EntityComponent nodes into a fresh world. Returns {world, player_id, cast, view}.
func _boot_player(player_definition: PlayerDefinition, component_nodes: Array) -> Dictionary:
	var world := EcsWorld.new()
	world.manual_tick = true
	root.add_child(world)
	var view := ActorView.new()
	view.player_definition = player_definition
	view.position = world.grid.cell_to_world(Vector2i(3, 3))
	for component_node in component_nodes:
		view.add_child(component_node)
	root.add_child(view)
	var cast := EcsBoot.boot(world, view, null)
	return {"world": world, "player_id": int(cast["player"]), "cast": cast, "view": view}


func _free_boot(booted: Dictionary) -> void:
	(booted["view"] as Node).free()
	(booted["world"] as Node).free()


## Every PlayerDefinition field that has a home in a component, read back from the entity.
func _expect_baked_fields_equal(world: EcsWorld, player_id: int, definition: PlayerDefinition, what: String) -> void:
	var health: EcsComponents.Health = world.get_component(player_id, EcsComponents.HEALTH)
	var move: EcsComponents.MoveState = world.get_component(player_id, EcsComponents.MOVE_STATE)
	var input_state: EcsComponents.PlayerInput = world.get_component(player_id, EcsComponents.PLAYER_INPUT)
	var combat: EcsComponents.PlayerCombat = world.get_component(player_id, EcsComponents.PLAYER_COMBAT)
	_expect(health.max_value == definition.max_courage and health.current == definition.max_courage, "%s: the hero spawns with full Courage (%d)" % [what, definition.max_courage])
	_expect(is_equal_approx(health.invulnerability_duration, definition.invulnerability_duration), "%s: invulnerability_duration is baked" % what)
	_expect(is_equal_approx(move.duration, definition.step_duration), "%s: step_duration is baked" % what)
	_expect(is_equal_approx(input_state.held_repeat_delay, definition.held_repeat_delay), "%s: held_repeat_delay is baked" % what)
	_expect(combat.sword_unlocked == definition.starts_with_sword, "%s: starts_with_sword is baked" % what)
	_expect(is_equal_approx(combat.skill_cooldown_duration, definition.skill_cooldown_duration), "%s: skill_cooldown_duration is baked" % what)
	_expect(combat.wooden_sword == definition.wooden_sword and combat.pencil_thrust == definition.pencil_thrust, "%s: the attack loadout is baked" % what)
