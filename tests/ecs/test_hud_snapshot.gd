extends UnboundTest

## The HUD's one way into the simulation (docs/game-base-plan.md 13.4 step 17, 14.3, D-38,
## 15 M3a): HudSnapshotSystem rebuilds world.hud_snapshot at the end of every tick, and the HUD and
## the board overlay read that data object and drained events, never a component. This suite holds
## what the snapshot says (every field equals the component it was copied from, tick after tick),
## how it behaves (rebuilt in place, counted, not rebuilt while frozen, decides nothing), and the
## rule it exists for: no script under presentation/ names EcsComponents or EcsWorld any more.

const ProjectFiles := preload("res://tests/architecture/project_files.gd")


func _init() -> void:
	suite_title = "HUD SNAPSHOT TEST"
	_check_a_world_with_no_hero()
	_check_the_hero_fields_follow_the_components()
	_check_the_skill_slot()
	_check_enemy_briefs_and_telegraph_progress()
	_check_the_token_owner()
	_check_the_room_enemy_counts()
	_check_the_door_briefs()
	_check_it_is_rebuilt_in_place_counted_and_not_while_frozen()
	_check_it_only_reads()
	_check_presentation_names_no_component()
	finish()


func _make_world() -> EcsWorld:
	var world := EcsWorld.new()
	world.manual_tick = true
	root.add_child(world)
	return world


func _spawn_hero(world: EcsWorld, cell: Vector2i, courage := 3) -> int:
	var sword := ContentDb.fetch(&"skills", &"wooden_sword") as AttackProfile
	var thrust := ContentDb.fetch(&"skills", &"pencil_thrust") as AttackProfile
	return EcsActorFactory.spawn_player(world, cell, sword, thrust, courage)


func _spawn_pawn(world: EcsWorld, cell: Vector2i) -> int:
	return EcsActorFactory.spawn_enemy(world, ContentDb.fetch(&"enemies", &"pawn_recruit") as EnemyDefinition, cell)


func _check_a_world_with_no_hero() -> void:
	var world := _make_world()
	var snapshot := world.hud_snapshot
	_expect(snapshot.revision == 0 and snapshot.player_entity == 0 and snapshot.enemy_brief_by_entity.is_empty(), "a fresh world's snapshot was never built: revision 0, no hero, no enemies")
	HudSnapshotSystem.build(world)
	_expect(snapshot.revision == 1, "building it counts one revision")
	_expect(snapshot.player_entity == 0 and snapshot.player_courage_current == 0 and snapshot.player_courage_max == 0 and not snapshot.sword_unlocked, "a world with no hero builds a snapshot that says so: entity 0, no courage, no sword")
	_expect(is_zero_approx(snapshot.skill_cooldown_left) and is_equal_approx(snapshot.skill_cooldown_duration, 1.0) and snapshot.attack_token_owner == 0 and snapshot.enemy_brief_by_entity.is_empty(), "and a skill slot that reads ready over a one-second cooldown, a free token and no enemies")
	world.queue_free()


func _check_the_hero_fields_follow_the_components() -> void:
	var world := _make_world()
	Schedule.populate(world)
	var hero := _spawn_hero(world, Vector2i(3, 7), 3)
	world.tick(0.016)
	var snapshot := world.hud_snapshot
	_expect(snapshot.player_entity == hero, "the snapshot names the hero entity")
	_expect(snapshot.player_courage_current == 3 and snapshot.player_courage_max == 3, "it carries the hero's courage and its maximum")
	_expect(snapshot.player_cell == Vector2i(3, 7), "it carries the hero's cell")
	var facing: EcsComponents.Facing = world.get_component(hero, EcsComponents.FACING)
	_expect(snapshot.player_facing == facing.direction, "it carries the hero's facing")

	# A blow: HealthSystem runs before the snapshot in the same tick, so the picture is the new courage.
	Events.emit_damage(world, hero, 1, Vector2i.LEFT, 0)
	world.tick(0.016)
	_expect(snapshot.player_courage_current == 2 and snapshot.player_courage_max == 3, "courage drops in the very tick the blow lands (the snapshot is built after HealthSystem)")
	world.drain_events()

	# A step: the snapshot shows the cell once the step lands, and the turn at once.
	var intent: EcsComponents.MoveIntent = world.get_component(hero, EcsComponents.MOVE_INTENT)
	facing.direction = Vector2i.RIGHT
	intent.direction = Vector2i.RIGHT
	for _tick in range(30):
		world.tick(0.016)
	_expect(snapshot.player_cell == Vector2i(4, 7) and snapshot.player_facing == Vector2i.RIGHT, "after the step lands the snapshot shows the new cell and the facing")

	# Healing restores up to the maximum, never past it.
	Events.emit_heal(world, hero, 5, 0)
	world.tick(0.016)
	_expect(snapshot.player_courage_current == 3, "a heal shows up, clamped to the maximum")
	world.queue_free()


func _check_the_skill_slot() -> void:
	var world := _make_world()
	Schedule.populate(world)
	var hero := _spawn_hero(world, Vector2i(3, 3))
	var combat: EcsComponents.PlayerCombat = world.get_component(hero, EcsComponents.PLAYER_COMBAT)
	var snapshot := world.hud_snapshot
	combat.sword_unlocked = false
	world.tick(0.016)
	_expect(not snapshot.sword_unlocked, "the skill slot knows the sword is still to be found")
	combat.sword_unlocked = true
	world.tick(0.016)
	_expect(snapshot.sword_unlocked and is_zero_approx(snapshot.skill_cooldown_left), "and knows when it has been found; the skill is ready")
	_expect(is_equal_approx(snapshot.skill_cooldown_duration, combat.skill_cooldown_duration), "the cooldown length is the hero's own")
	var attack_intent: EcsComponents.AttackIntent = world.get_component(hero, EcsComponents.ATTACK_INTENT)
	attack_intent.kind = &"skill"
	world.tick(0.016)
	_expect(snapshot.skill_cooldown_left > 0.0 and is_equal_approx(snapshot.skill_cooldown_left, combat.skill_cooldown_left), "using the skill starts a cooldown the snapshot shows")
	var first_reading := snapshot.skill_cooldown_left
	world.tick(0.1)
	_expect(snapshot.skill_cooldown_left < first_reading and is_equal_approx(snapshot.skill_cooldown_left, combat.skill_cooldown_left), "and counts it down with the simulation")
	world.queue_free()


func _check_enemy_briefs_and_telegraph_progress() -> void:
	var world := _make_world()
	var hero := _spawn_hero(world, Vector2i(2, 2))
	var pawn := _spawn_pawn(world, Vector2i(8, 4))
	var snapshot := world.hud_snapshot
	HudSnapshotSystem.build(world)
	_expect(snapshot.enemy_brief_by_entity.size() == 1 and snapshot.enemy_brief_by_entity.has(pawn) and not snapshot.enemy_brief_by_entity.has(hero), "the snapshot briefs every enemy, and only enemies (not the hero)")
	var brief: HudSnapshot.EnemyBrief = snapshot.enemy_brief_by_entity[pawn]
	var ai: EcsComponents.EnemyAI = world.get_component(pawn, EcsComponents.ENEMY_AI)
	_expect(brief.cell == Vector2i(8, 4) and brief.committed_goal == ai.committed_goal, "a brief carries the enemy's cell and the cell it committed to")
	_expect(is_zero_approx(brief.telegraph_progress), "an enemy that is not telegraphing has progress 0.0")

	ai.state = EcsComponents.EnemyAI.STATE_TELEGRAPH
	ai.telegraph_duration = 0.5
	ai.state_time_left = 0.5
	HudSnapshotSystem.build(world)
	_expect(is_zero_approx(brief.telegraph_progress), "a telegraph that just started is 0.0 of the way")
	ai.state_time_left = 0.2
	HudSnapshotSystem.build(world)
	_expect(is_equal_approx(brief.telegraph_progress, 0.6), "a telegraph with 0.2 s of 0.5 s left is 0.6 of the way")
	ai.state_time_left = -1.0
	HudSnapshotSystem.build(world)
	_expect(is_equal_approx(brief.telegraph_progress, 1.0), "progress is clamped to 1.0 when the timer runs past the end")
	ai.telegraph_duration = 0.0
	ai.state_time_left = 0.0
	HudSnapshotSystem.build(world)
	_expect(is_equal_approx(brief.telegraph_progress, 1.0), "a telegraph of no length is already complete (1.0) and never divides by zero, as the board always drew it")

	_expect(snapshot.enemy_brief_by_entity[pawn] == brief, "the brief of a steady enemy is the same object rebuild after rebuild (nothing allocated per tick)")
	ai.state = EcsComponents.EnemyAI.STATE_DEFEATED
	HudSnapshotSystem.build(world)
	_expect(snapshot.enemy_brief_by_entity.has(pawn) and is_zero_approx(brief.telegraph_progress), "a defeated enemy keeps its brief (it still has its AI) and is no longer telegraphing")

	var second := _spawn_pawn(world, Vector2i(10, 6))
	HudSnapshotSystem.build(world)
	_expect(snapshot.enemy_brief_by_entity.size() == 2 and snapshot.enemy_brief_by_entity.has(second), "a new enemy gets a brief")
	world.destroy_entity(pawn)
	HudSnapshotSystem.build(world)
	_expect(snapshot.enemy_brief_by_entity.size() == 1 and not snapshot.enemy_brief_by_entity.has(pawn), "an enemy that is destroyed loses its brief")
	world.queue_free()


func _check_the_token_owner() -> void:
	var world := _make_world()
	var pawn := _spawn_pawn(world, Vector2i(8, 4))
	HudSnapshotSystem.build(world)
	_expect(world.hud_snapshot.attack_token_owner == 0, "a free attack token reads 0")
	world.attack_token_owner = pawn
	HudSnapshotSystem.build(world)
	_expect(world.hud_snapshot.attack_token_owner == pawn, "the snapshot names the enemy that holds the token")
	world.queue_free()


func _check_the_room_enemy_counts() -> void:
	var world := _make_world()
	HudSnapshotSystem.build(world)
	_expect(world.hud_snapshot.room_enemies_total == 0 and world.hud_snapshot.room_enemies_remaining == 0, "a world with no room entity shows no enemy count")
	var state := RoomObjectiveState.new()
	state.enemies_total = 4
	state.enemies_remaining = 3
	world.add_component(world.create_entity(), RoomObjectiveState.KEY, state)
	HudSnapshotSystem.build(world)
	_expect(world.hud_snapshot.room_enemies_total == 4 and world.hud_snapshot.room_enemies_remaining == 3, "a room's count is copied from its state: three of the four it began with still stand")
	state.enemies_remaining = 0
	HudSnapshotSystem.build(world)
	_expect(world.hud_snapshot.room_enemies_total == 4 and world.hud_snapshot.room_enemies_remaining == 0, "and follows it")
	world.queue_free()


## The doors of the room (M5 fix: a door cell was plain floor, so the board drew nothing there): one brief per door
## cell, shut by the same rule MovementSystem uses (DoorRules), made once and followed in place.
func _check_the_door_briefs() -> void:
	var world := _make_world()
	Schedule.populate(world)
	var snapshot := world.hud_snapshot
	HudSnapshotSystem.build(world)
	_expect(snapshot.door_brief_by_cell.is_empty(), "a room with no door has no door brief")

	var clear_door := Vector2i(14, 4)
	var flag_door := Vector2i(1, 4)
	var open_door := Vector2i(1, 6)
	var ending_door := Vector2i(14, 6)
	world.grid.exit_by_cell[clear_door] = {"zone": &"next", "entry": &"start", "requires_room_clear": true}
	world.grid.exit_by_cell[flag_door] = {"zone": &"hub", "entry": &"start", "requires_room_clear": false, "requires_flag": &"boss.knight_captain"}
	world.grid.exit_by_cell[open_door] = {"zone": &"back", "entry": &"start", "requires_room_clear": false}
	world.grid.exit_by_cell[ending_door] = {"ends_run": true, "requires_room_clear": false}
	var pawn := _spawn_pawn(world, Vector2i(8, 4))
	HudSnapshotSystem.build(world)
	_expect(snapshot.door_brief_by_cell.size() == 4, "one brief per door cell (4)")
	var briefs := snapshot.door_brief_by_cell
	_expect(briefs[clear_door].is_shut, "a door that waits for a clear is shut while a piece stands")
	_expect(briefs[flag_door].is_shut, "a door that waits for a boss's flag is shut while the flag is not set")
	_expect(not briefs[open_door].is_shut and not briefs[open_door].ends_run, "a plain door is open")
	_expect(not briefs[ending_door].is_shut and briefs[ending_door].ends_run, "the door that ends the run is open and says so")
	var clear_brief: HudSnapshot.DoorBrief = briefs[clear_door]

	var ai: EcsComponents.EnemyAI = world.get_component(pawn, EcsComponents.ENEMY_AI)
	ai.state = EcsComponents.EnemyAI.STATE_DEFEATED
	HudSnapshotSystem.build(world)
	_expect(not briefs[clear_door].is_shut and briefs[flag_door].is_shut, "the last piece falls: the clear door opens and the flag door does not")
	_expect(briefs[clear_door] == clear_brief, "the brief is the same object, followed in place")
	world.flags.set_flag(&"boss.knight_captain", true)
	HudSnapshotSystem.build(world)
	_expect(not briefs[flag_door].is_shut, "the boss's flag is set: the flag door opens")

	# The snapshot's reading and the door's own behaviour are one rule: stepping on a door says shut exactly when the brief does.
	world.flags.set_flag(&"boss.knight_captain", false)
	ai.state = EcsComponents.EnemyAI.STATE_OBSERVE
	HudSnapshotSystem.build(world)
	for cell: Vector2i in world.grid.exit_by_cell:
		_expect(briefs[cell].is_shut == DoorRules.is_shut(world, world.grid.exit_by_cell[cell]), "%s: the brief and DoorRules agree" % cell)

	world.grid.exit_by_cell.erase(open_door)
	HudSnapshotSystem.build(world)
	_expect(snapshot.door_brief_by_cell.size() == 3 and not snapshot.door_brief_by_cell.has(open_door), "a door that is gone loses its brief")
	world.queue_free()


func _check_it_is_rebuilt_in_place_counted_and_not_while_frozen() -> void:
	var world := _make_world()
	Schedule.populate(world)
	_spawn_hero(world, Vector2i(3, 3))
	var kept := world.hud_snapshot
	for _tick in range(5):
		world.tick(0.016)
	_expect(world.hud_snapshot == kept and kept.revision == 5, "a widget that kept the reference sees every rebuild: same object, one revision per tick (5)")

	world.frozen = true
	for _tick in range(5):
		world.tick(0.016)
	_expect(kept.revision == 5, "a frozen world does not rebuild it: a held simulation has nothing new to publish")
	world.frozen = false
	world.tick(0.016)
	_expect(kept.revision == 6, "and the first tick after the thaw builds it again")

	var phase_of_system := HudSnapshotSystem.PHASE
	_expect(phase_of_system == &"view", "HudSnapshotSystem is a view-stage system, listed before ViewSyncSystem")
	var view_stage_names: Array[String] = []
	for stage in Schedule.phases():
		if stage.phase_name() == &"view":
			for system_script in stage.systems():
				view_stage_names.append(system_script.get_global_name())
	_expect(view_stage_names == ["HudSnapshotSystem", "ViewSyncSystem"], "the view stage runs the snapshot first and the views last (%s)" % ", ".join(PackedStringArray(view_stage_names)))
	world.queue_free()


func _check_it_only_reads() -> void:
	var world := _make_world()
	var hero := _spawn_hero(world, Vector2i(3, 3))
	var pawn := _spawn_pawn(world, Vector2i(9, 5))
	world.attack_token_owner = pawn
	var health: EcsComponents.Health = world.get_component(hero, EcsComponents.HEALTH)
	var pawn_ai: EcsComponents.EnemyAI = world.get_component(pawn, EcsComponents.ENEMY_AI)
	pawn_ai.state = EcsComponents.EnemyAI.STATE_TELEGRAPH
	pawn_ai.telegraph_duration = 0.5
	pawn_ai.state_time_left = 0.25
	var courage_before := health.current
	var state_time_before := pawn_ai.state_time_left
	for _build in range(3):
		HudSnapshotSystem.build(world)
	_expect(health.current == courage_before and is_equal_approx(pawn_ai.state_time_left, state_time_before) and pawn_ai.state == EcsComponents.EnemyAI.STATE_TELEGRAPH and world.attack_token_owner == pawn, "building the snapshot changes no component and no world field")
	_expect(world.pending_events.is_empty() and world.commands.is_empty() and world.view_commands.is_empty() and world.damage_events.is_empty() and world.heal_events.is_empty(), "and queues no event, command, view command, damage or heal")
	world.queue_free()


## The rule the snapshot exists for. tests/architecture/test_dependency_edges.gd enforces the same
## thing through the class graph; this says it where the snapshot is tested, and by name.
func _check_presentation_names_no_component() -> void:
	var string_literal_regex := RegEx.new()
	string_literal_regex.compile("\"(?:[^\"\\\\\\n]|\\\\.)*\"|'(?:[^'\\\\\\n]|\\\\.)*'")
	var comment_regex := RegEx.new()
	comment_regex.compile("#[^\\n]*")
	var forbidden_regex := RegEx.new()
	forbidden_regex.compile("(?<![A-Za-z0-9_])(EcsComponents|EcsWorld)(?![A-Za-z0-9_])")
	var presentation_scripts := ProjectFiles.collect_files(["gd"], "res://presentation")
	var offenders: Array[String] = []
	for script_path in presentation_scripts:
		var code := comment_regex.sub(string_literal_regex.sub(ProjectFiles.read_text(script_path), "\"\"", true), "", true)
		if forbidden_regex.search(code) != null:
			offenders.append(script_path)
	_expect(presentation_scripts.size() >= 5, "the walk found %d scripts under presentation/ (at least 5)" % presentation_scripts.size())
	_expect(offenders.is_empty(), "no script under presentation/ names EcsComponents or EcsWorld (%s)" % ", ".join(PackedStringArray(offenders)))
	_expect(forbidden_regex.search("var ai: EcsComponents.EnemyAI") != null and forbidden_regex.search("var ecs: EcsWorld") != null and forbidden_regex.search("var snapshot: HudSnapshot") == null, "the check can fail: it catches both names and lets HudSnapshot through")
