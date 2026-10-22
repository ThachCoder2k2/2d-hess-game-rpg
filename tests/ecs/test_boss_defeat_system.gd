extends UnboundTest

## BossDefeatSystem (ecs/systems/progress/boss_defeat_system.gd, docs/game-base-plan.md 5.4, 7.3, M5): a piece whose
## definition names a `defeat_flag` sets that flag when it falls, once, and says `boss_defeated`. Driven on a
## hand-built world (HealthSystem and BossDefeatSystem, nothing else acts) with real damage requests, the path a
## sword blow takes. What the shell does with the event (the save, the doors) is test_boss_flow's business.
##
## It also holds the data: every boss of docs/game-base-plan.md 5.4 is an enemy definition whose defeat flag is
## `boss.<its id>` and that stands on one cell, and only a boss names a flag.

## The six bosses of the plan (5.4), by id. The Black Pawn Captain is B1's; the others are stand-ins until M9-M13.
const BOSS_IDS: Array[StringName] = [&"black_pawn_captain", &"knight_captain", &"bishop_oracle", &"rook_warden", &"queen_of_tricks", &"black_king"]


func _init() -> void:
	suite_title = "BOSS DEFEAT SYSTEM TEST"
	_check_every_boss_of_the_plan_names_its_flag()
	_check_only_a_boss_names_a_flag()
	_check_the_fall_of_a_boss_sets_its_flag_once()
	_check_an_ordinary_piece_sets_nothing()
	_check_a_boss_that_is_still_standing_sets_nothing()
	_check_the_hero_falling_in_the_same_tick_wins()
	_check_a_flag_already_set_stays_quiet()
	_check_the_boss_is_found_by_its_definition_in_any_room()
	finish()


func _make_world() -> EcsWorld:
	var world := EcsWorld.new()
	world.manual_tick = true
	root.add_child(world)
	world.add_system(HealthSystem.new())
	world.add_system(BossDefeatSystem.new())
	return world


func _spawn_hero(world: EcsWorld) -> int:
	var sword := ContentDb.fetch(&"skills", &"wooden_sword") as AttackProfile
	var thrust := ContentDb.fetch(&"skills", &"pencil_thrust") as AttackProfile
	return EcsActorFactory.spawn_player(world, Vector2i(1, 1), sword, thrust, 3)


func _spawn(world: EcsWorld, enemy_id: StringName, cell := Vector2i(6, 4)) -> int:
	return EcsActorFactory.spawn_enemy(world, ContentDb.fetch(&"enemies", enemy_id) as EnemyDefinition, cell)


func _strike_down(world: EcsWorld, hero: int, enemy: int) -> void:
	Events.emit_damage(world, enemy, 99, Vector2i.ZERO, hero)
	world.tick(0.016)


func _events_of(world: EcsWorld, event_type: StringName) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for event in world.drain_events():
		if event["type"] == event_type:
			found.append(event)
	return found


func _check_every_boss_of_the_plan_names_its_flag() -> void:
	var all_have_the_flag := true
	var all_validate := true
	for boss_id in BOSS_IDS:
		var definition := ContentDb.fetch(&"enemies", boss_id) as EnemyDefinition
		_expect(definition != null, "the boss %s is an enemy definition" % boss_id)
		if definition == null:
			continue
		all_have_the_flag = all_have_the_flag and definition.defeat_flag == StringName("boss.%s" % boss_id)
		all_validate = all_validate and definition.validate().is_empty()
	_expect(all_have_the_flag, "each of the six bosses names the flag boss.<its id> (the doors of the hub wait for them)")
	_expect(all_validate, "every boss definition passes its own validate()")
	var piece_type_by_boss := {&"knight_captain": &"knight", &"bishop_oracle": &"bishop", &"rook_warden": &"rook", &"queen_of_tricks": &"queen", &"black_king": &"king", &"black_pawn_captain": &"pawn"}
	var pieces_are_of_their_kind := true
	for boss_id: StringName in piece_type_by_boss:
		var definition := ContentDb.fetch(&"enemies", boss_id) as EnemyDefinition
		pieces_are_of_their_kind = pieces_are_of_their_kind and definition != null and definition.visual.piece_type == piece_type_by_boss[boss_id]
	_expect(pieces_are_of_their_kind, "each boss is drawn as its own kind of piece (a knight, a bishop, a rook, a queen, a king), on one cell: multi-cell footprints are M8b")
	var healths_in_range := true
	for boss_id in BOSS_IDS:
		var definition := ContentDb.fetch(&"enemies", boss_id) as EnemyDefinition
		healths_in_range = healths_in_range and definition != null and definition.max_health >= 4 and definition.max_health <= 18
	_expect(healths_in_range, "every boss has between 4 and 18 Courage (the plan caps a boss at 18; M8b tunes the stand-ins)")


func _check_only_a_boss_names_a_flag() -> void:
	var offenders: Array[String] = []
	for enemy_id in ContentDb.ids(&"enemies"):
		var definition := ContentDb.fetch(&"enemies", enemy_id) as EnemyDefinition
		if definition != null and definition.defeat_flag != &"" and enemy_id not in BOSS_IDS:
			offenders.append(String(enemy_id))
	_expect(offenders.is_empty(), "no ordinary piece names a defeat flag (found on: %s)" % ", ".join(PackedStringArray(offenders)))
	var wrong := EnemyDefinition.new()
	wrong.id = &"some_piece"
	wrong.defeat_flag = &"boss.another_piece"
	var problems := PackedStringArray()
	for sentence in wrong.validate():
		problems.append(sentence)
	var says_it := false
	for sentence in problems:
		says_it = says_it or sentence.contains("must end with the piece's own id")
	_expect(says_it, "a defeat flag that names another piece's id is reported by validate()")
	wrong.defeat_flag = &"Boss Flag"
	var says_not_a_flag := false
	for sentence in wrong.validate():
		says_not_a_flag = says_not_a_flag or sentence.contains("is not a flag id")
	_expect(says_not_a_flag, "a defeat flag that is not a flag id is reported by validate()")


func _check_the_fall_of_a_boss_sets_its_flag_once() -> void:
	var world := _make_world()
	var hero := _spawn_hero(world)
	var boss := _spawn(world, &"knight_captain")
	world.tick(0.016)
	_expect(not world.flags.get_flag(&"boss.knight_captain", false), "a boss that stands has set no flag")
	_strike_down(world, hero, boss)
	_expect(world.flags.get_flag(&"boss.knight_captain", false) == true, "the Knight Captain's fall sets boss.knight_captain")
	var told := _events_of(world, Events.BOSS_DEFEATED)
	_expect(told.size() == 1 and told[0]["boss"] == &"knight_captain" and told[0]["flag"] == &"boss.knight_captain" and told[0]["entity"] == boss, "boss_defeated names the boss, its flag and its entity, once")
	world.tick(0.016)
	world.tick(0.016)
	_expect(_events_of(world, Events.BOSS_DEFEATED).is_empty(), "later ticks say nothing more: the flag already being set is the once")
	world.queue_free()


func _check_an_ordinary_piece_sets_nothing() -> void:
	var world := _make_world()
	var hero := _spawn_hero(world)
	var recruit := _spawn(world, &"pawn_recruit")
	_strike_down(world, hero, recruit)
	_expect(world.flags.value_by_flag_id.is_empty() and _events_of(world, Events.BOSS_DEFEATED).is_empty(), "a Recruit's fall sets no flag and says no boss fell")
	world.queue_free()


func _check_a_boss_that_is_still_standing_sets_nothing() -> void:
	var world := _make_world()
	var hero := _spawn_hero(world)
	var boss := _spawn(world, &"black_king")
	Events.emit_damage(world, boss, 3, Vector2i.ZERO, hero)
	world.tick(0.016)
	var health: EcsComponents.Health = world.get_component(boss, EcsComponents.HEALTH)
	_expect(health.current > 0 and not world.flags.has_flag(&"boss.black_king"), "a wounded Black King (%d left) has not fallen: no flag" % health.current)
	world.queue_free()


func _check_the_hero_falling_in_the_same_tick_wins() -> void:
	var world := _make_world()
	var hero := _spawn_hero(world)
	var boss := _spawn(world, &"rook_warden")
	Events.emit_damage(world, boss, 99, Vector2i.ZERO, hero)
	Events.emit_damage(world, hero, 99, Vector2i.ZERO, boss)
	world.tick(0.016)
	_expect(not world.flags.has_flag(&"boss.rook_warden") and _events_of(world, Events.BOSS_DEFEATED).is_empty(), "when the hero falls in the same tick the boss is not credited (the fall wins, as for a room clear)")
	world.queue_free()


func _check_a_flag_already_set_stays_quiet() -> void:
	var world := _make_world()
	world.flags.set_flag(&"boss.queen_of_tricks", true)
	var hero := _spawn_hero(world)
	var boss := _spawn(world, &"queen_of_tricks")
	_strike_down(world, hero, boss)
	_expect(_events_of(world, Events.BOSS_DEFEATED).is_empty() and world.flags.get_flag(&"boss.queen_of_tricks", false) == true, "a boss whose flag the run already held says nothing new when it falls again")
	world.queue_free()


## The system names no room: the same lines are true wherever the boss stands. Only the code is read, not the
## comments that give `boss.knight_captain` as an example.
func _check_the_boss_is_found_by_its_definition_in_any_room() -> void:
	var code := PackedStringArray()
	for line in FileAccess.get_file_as_string("res://ecs/systems/progress/boss_defeat_system.gd").split("\n"):
		if not line.strip_edges().begins_with("#"):
			code.append(line)
	var code_text := "\n".join(code)
	var names_a_boss := false
	for boss_id in BOSS_IDS:
		names_a_boss = names_a_boss or code_text.contains(String(boss_id))
	_expect(not names_a_boss and not code_text.contains("boss."), "the system names no boss and no room: a boss is a boss because its definition says so")
