extends UnboundTest

## What the pawn carries across a room change and into a save (docs/game-base-plan.md 14.2, 15 M3a):
## the PlayerSnapshot. The shell rebuilds the whole world for every room, and until now only an integer
## of health survived. M3b uses the snapshot in the zone swap and the save; this step only defines it,
## so this suite holds the contract by itself:
##   - it carries exactly the rows the plan marks persistent, and none of the per-room rows;
##   - it survives the save: a dictionary, a JSON string and a JSON file give back the same snapshot;
##   - capturing a live world and applying the snapshot to a fresh one carries the right rows and
##     leaves every per-room row at the value the boot gave it;
##   - two room changes in a row, through JSON each time, lose nothing;
##   - EcsBootOptions.player_snapshot makes EcsBoot apply it to the booted hero.

## The keys to_dictionary() writes: the format version, then one per persistent row of the plan's 14.2 table.
const CARRIED_KEYS: Array[String] = [
	"format_version", "courage_current", "courage_max", "believe_current", "unlocked_skill_ids",
	"applied_upgrade_ids", "equipped_page_ids", "margin", "locked_directions", "facing", "flags",
]

## Rows the plan marks per-room or per-encounter, by the name a field for them would have. None may be a key.
const PER_ROOM_ROW_NAMES: Array[String] = [
	"skill_cooldowns", "skill_cooldown_left", "status", "invulnerable_left", "stagger_left", "guard_left",
	"untargetable_left", "in_check_left", "help_disrupted_left", "skill_cast", "attack_lock", "attack_token",
	"attack_token_owner", "telegraphs", "hit_progress", "floor_weapon", "weapon", "cell_effects", "raised_block",
]


func _init() -> void:
	suite_title = "PLAYER SNAPSHOT ROUNDTRIP TEST"
	_check_it_carries_the_persistent_rows_and_no_others()
	_check_a_full_snapshot_survives_the_save()
	_check_a_damaged_or_older_save_still_loads()
	_check_capture_and_apply_between_two_worlds()
	_check_two_room_changes_through_the_save()
	_check_the_snapshot_never_shares_state_with_a_world()
	_check_the_boot_applies_it()
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


## A snapshot with every field set to something other than its neutral value.
func _full_snapshot() -> PlayerSnapshot:
	var snapshot := PlayerSnapshot.new()
	snapshot.courage_current = 2
	snapshot.courage_max = 5
	snapshot.believe_current = 1
	snapshot.unlocked_skill_ids = [&"wooden_sword", &"pencil_thrust", &"rule_step"]
	snapshot.applied_upgrade_ids = [&"lead_tip"]
	snapshot.equipped_page_ids = [&"page_pawn", &"page_bishop"]
	snapshot.margin = 4
	snapshot.locked_directions = [Vector2i.LEFT, Vector2i.DOWN]
	snapshot.facing = Vector2i.RIGHT
	snapshot.flags = {"met_the_child": true, "child_calls_used": 3, "courage_shards": 2, "deaths": 0, "left_alone": false}
	return snapshot


func _check_it_carries_the_persistent_rows_and_no_others() -> void:
	var saved := PlayerSnapshot.new().to_dictionary()
	var keys: Array[String] = []
	for key: Variant in saved:
		keys.append(String(key))
	_expect(keys == CARRIED_KEYS, "a snapshot writes the format version and one key per persistent row of the plan's table: %s" % ", ".join(PackedStringArray(CARRIED_KEYS)))
	var leaked: Array[String] = []
	for row_name in PER_ROOM_ROW_NAMES:
		if row_name in keys:
			leaked.append(row_name)
	_expect(leaked.is_empty(), "and none of the per-room or per-encounter rows (cooldowns, status, cast, attack lock and token, telegraphs, hit progress, floor weapon, cell effects, raised block): leaked %s" % ", ".join(PackedStringArray(leaked)))
	_expect(saved["format_version"] == PlayerSnapshot.FORMAT_VERSION, "the dictionary names its format version")
	var fresh := PlayerSnapshot.new()
	_expect(fresh.courage_current == 3 and fresh.courage_max == 3 and fresh.believe_current == 0 and fresh.unlocked_skill_ids.is_empty() and fresh.margin == 0 and fresh.locked_directions.is_empty() and fresh.flags.is_empty(), "a fresh snapshot is neutral: full default courage, no Believe, no unlocks, no Margin, no lock, no flags")


func _check_a_full_snapshot_survives_the_save() -> void:
	var original := _full_snapshot()
	var saved := original.to_dictionary()

	# 1. The dictionary, the form the save service will hold.
	var from_dictionary := PlayerSnapshot.from_dictionary(saved)
	_expect(from_dictionary != null and from_dictionary.to_dictionary() == saved, "a dictionary round trip gives back the same snapshot")
	saved["flags"]["added_after"] = true
	saved["unlocked_skill_ids"].append("sneaky")
	_expect(not from_dictionary.flags.has("added_after") and from_dictionary.unlocked_skill_ids.size() == 3, "and the copy is independent of the dictionary it was read from")

	# 2. A JSON string: ints come back as floats, StringNames as Strings, Vector2i as arrays.
	var as_text := JSON.stringify(original.to_dictionary())
	var parsed: Variant = JSON.parse_string(as_text)
	_expect(parsed is Dictionary, "the snapshot is valid JSON")
	var from_text := PlayerSnapshot.from_dictionary(parsed)
	_expect(from_text != null and from_text.to_dictionary() == original.to_dictionary(), "a JSON string round trip gives back the same snapshot, every row")
	_expect(from_text.courage_current == 2 and typeof(from_text.courage_current) == TYPE_INT and typeof(from_text.margin) == TYPE_INT, "numbers come back as ints, though JSON hands them over as floats")
	_expect(from_text.locked_directions == ([Vector2i.LEFT, Vector2i.DOWN] as Array[Vector2i]) and from_text.facing == Vector2i.RIGHT, "directions come back as Vector2i")
	_expect(from_text.unlocked_skill_ids == ([&"wooden_sword", &"pencil_thrust", &"rule_step"] as Array[StringName]) and from_text.equipped_page_ids == ([&"page_pawn", &"page_bishop"] as Array[StringName]), "ids come back as StringNames, in order")
	_expect(from_text.flags["met_the_child"] == true and typeof(from_text.flags["met_the_child"]) == TYPE_BOOL and from_text.flags["child_calls_used"] == 3 and typeof(from_text.flags["child_calls_used"]) == TYPE_INT and from_text.flags["left_alone"] == false, "switches stay bool and counters stay int")

	# 3. A JSON file on disk, the way a save is written.
	var save_path := OS.get_temp_dir().path_join("unbound_pawn_player_snapshot_%d.json" % OS.get_process_id())
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	_expect(file != null, "setup: a temporary save file can be written")
	if file != null:
		file.store_string(JSON.stringify(original.to_dictionary(), "\t"))
		file.close()
		var reread: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
		var from_file := PlayerSnapshot.from_dictionary(reread) if reread is Dictionary else null
		_expect(from_file != null and from_file.to_dictionary() == original.to_dictionary(), "a JSON file written and read back gives back the same snapshot")
		DirAccess.remove_absolute(save_path)


func _check_a_damaged_or_older_save_still_loads() -> void:
	var empty := PlayerSnapshot.from_dictionary({})
	_expect(empty != null and empty.to_dictionary() == PlayerSnapshot.new().to_dictionary(), "an empty save loads as a neutral snapshot")
	var partial := PlayerSnapshot.from_dictionary({"courage_current": 1.0, "unknown_future_key": [1, 2, 3]})
	_expect(partial != null and partial.courage_current == 1 and partial.courage_max == 3 and partial.flags.is_empty(), "a save with a few keys keeps them, defaults the rest and ignores keys it does not know")
	var damaged := PlayerSnapshot.from_dictionary({
		"courage_current": "three", "courage_max": null, "unlocked_skill_ids": "wooden_sword", "facing": [1],
		"locked_directions": [[0, 1], "left", [1]], "flags": {"ok": true, "count": 4.0, "bad": "text", "worse": [1]},
	})
	_expect(damaged != null and damaged.courage_current == 3 and damaged.courage_max == 3 and damaged.unlocked_skill_ids.is_empty() and damaged.facing == Vector2i.UP, "values of the wrong type fall back to their neutral value instead of failing the load")
	_expect(damaged.locked_directions == ([Vector2i.DOWN] as Array[Vector2i]) and damaged.flags == {"ok": true, "count": 4}, "and the usable entries of a list or of the flags are kept")
	_expect(PlayerSnapshot.from_dictionary({"format_version": PlayerSnapshot.FORMAT_VERSION + 1}) == null, "a save from a newer format is refused (null) rather than half understood")
	_expect(PlayerSnapshot.from_dictionary({"format_version": PlayerSnapshot.FORMAT_VERSION}) != null, "a save of this format loads")


func _check_capture_and_apply_between_two_worlds() -> void:
	var old_world := _make_world()
	var old_hero := _spawn_hero(old_world, Vector2i(4, 4), 3)
	var health: EcsComponents.Health = old_world.get_component(old_hero, EcsComponents.HEALTH)
	health.current = 2
	health.max_value = 4
	var combat: EcsComponents.PlayerCombat = old_world.get_component(old_hero, EcsComponents.PLAYER_COMBAT)
	combat.sword_unlocked = true
	(old_world.get_component(old_hero, EcsComponents.FACING) as EcsComponents.Facing).direction = Vector2i.LEFT
	old_world.flags.set_flag(&"met_the_child", true)
	old_world.flags.add_to_counter(&"child_calls_used", 2)
	# Everything per-room, set to a value a carried row would visibly drag along.
	combat.skill_cooldown_left = 0.9
	combat.attack_on_cooldown = true
	combat.impact_left = 0.3
	health.invulnerable_left = 0.4
	health.flash_left = 0.1
	(old_world.get_component(old_hero, EcsComponents.PLAYER_TAG) as EcsComponents.PlayerTag).control_enabled = false
	(old_world.get_component(old_hero, EcsComponents.PLAYER_INPUT) as EcsComponents.PlayerInput).buffered_direction = Vector2i.UP
	old_world.attack_token_owner = 99

	var snapshot := PlayerSnapshot.capture(old_world, old_hero)
	_expect(snapshot.courage_current == 2 and snapshot.courage_max == 4, "capture reads the courage and its maximum")
	_expect(snapshot.unlocked_skill_ids == ([PlayerSnapshot.SWORD_UNLOCK_ID] as Array[StringName]), "capture lists the sword as unlocked when the hero has it")
	_expect(snapshot.facing == Vector2i.LEFT and snapshot.flags == {"met_the_child": true, "child_calls_used": 2}, "capture reads the facing and the world's flags")
	combat.sword_unlocked = false
	_expect(PlayerSnapshot.capture(old_world, old_hero).unlocked_skill_ids.is_empty(), "capture lists nothing unlocked when the sword has not been found")
	combat.sword_unlocked = true

	# A fresh world, as a room change builds it: the hero as the boot made it.
	var new_world := _make_world()
	var new_hero := _spawn_hero(new_world, Vector2i(1, 1), 3)
	var new_health: EcsComponents.Health = new_world.get_component(new_hero, EcsComponents.HEALTH)
	var new_combat: EcsComponents.PlayerCombat = new_world.get_component(new_hero, EcsComponents.PLAYER_COMBAT)
	new_combat.sword_unlocked = false
	snapshot.apply_to(new_world, new_hero)
	_expect(new_health.current == 2 and new_health.max_value == 4, "apply puts the carried courage and maximum into the new hero")
	_expect(new_combat.sword_unlocked, "apply gives back the sword")
	_expect(new_world.flags.to_dictionary() == {"met_the_child": true, "child_calls_used": 2}, "apply gives the new world the run's flags and counters")
	var new_facing: EcsComponents.Facing = new_world.get_component(new_hero, EcsComponents.FACING)
	_expect(new_facing.direction == Vector2i.DOWN, "a room change leaves the facing to the entry marker: the new hero still faces the way the boot put it")
	snapshot.apply_to(new_world, new_hero, true)
	_expect(new_facing.direction == Vector2i.LEFT, "a checkpoint or save resume asks for the facing and gets it")

	# The per-room rows are the boot's, not the old room's.
	_expect(is_zero_approx(new_combat.skill_cooldown_left) and not new_combat.attack_on_cooldown and is_zero_approx(new_combat.impact_left), "skill cooldown, attack lock and the swing in progress do not carry over")
	_expect(is_zero_approx(new_health.invulnerable_left) and is_zero_approx(new_health.flash_left), "the invulnerability window and the hit flash do not carry over")
	_expect((new_world.get_component(new_hero, EcsComponents.PLAYER_TAG) as EcsComponents.PlayerTag).control_enabled, "the old room's control lock does not carry over")
	_expect((new_world.get_component(new_hero, EcsComponents.PLAYER_INPUT) as EcsComponents.PlayerInput).buffered_direction == Vector2i.ZERO, "a buffered step does not carry over")
	_expect(new_world.attack_token_owner == 0, "the attack token does not carry over")

	# Courage is clamped to the maximum and cannot go below zero.
	var greedy := PlayerSnapshot.new()
	greedy.courage_max = 3
	greedy.courage_current = 9
	greedy.apply_to(new_world, new_hero)
	_expect(new_health.current == 3, "a snapshot cannot give more courage than its own maximum")
	greedy.courage_current = -4
	greedy.apply_to(new_world, new_hero)
	_expect(new_health.current == 0, "nor less than none")

	# A world with no hero component skips that row without failing.
	var bare_world := _make_world()
	var bare_entity := bare_world.create_entity()
	snapshot.apply_to(bare_world, bare_entity)
	_expect(bare_world.flags.to_dictionary() == snapshot.flags, "an entity with no hero components takes nothing but the flags, and nothing fails")
	_expect(PlayerSnapshot.capture(bare_world, bare_entity).courage_current == 3, "and capturing one gives the neutral snapshot")
	for world in [old_world, new_world, bare_world]:
		world.queue_free()


func _check_two_room_changes_through_the_save() -> void:
	var first_room := _make_world()
	var first_hero := _spawn_hero(first_room, Vector2i(2, 2), 3)
	var combat: EcsComponents.PlayerCombat = first_room.get_component(first_hero, EcsComponents.PLAYER_COMBAT)
	combat.sword_unlocked = true
	first_room.flags.set_flag(&"opened_toybox", true)
	var first_health: EcsComponents.Health = first_room.get_component(first_hero, EcsComponents.HEALTH)
	first_health.current = 2

	var second_room := _make_world()
	var second_hero := _spawn_hero(second_room, Vector2i(2, 2), 3)
	_carry(first_room, first_hero, second_room, second_hero)
	var second_health: EcsComponents.Health = second_room.get_component(second_hero, EcsComponents.HEALTH)
	_expect(second_health.current == 2 and (second_room.get_component(second_hero, EcsComponents.PLAYER_COMBAT) as EcsComponents.PlayerCombat).sword_unlocked and second_room.flags.get_flag(&"opened_toybox") == true, "after the first room change the courage, the sword and the flag are there")
	# Something happens in the second room.
	second_health.current = 1
	second_health.max_value = 4
	second_room.flags.add_to_counter(&"deaths")
	second_room.flags.set_flag(&"met_the_child", true)

	var third_room := _make_world()
	var third_hero := _spawn_hero(third_room, Vector2i(2, 2), 3)
	_carry(second_room, second_hero, third_room, third_hero)
	var third_health: EcsComponents.Health = third_room.get_component(third_hero, EcsComponents.HEALTH)
	_expect(third_health.current == 1 and third_health.max_value == 4, "after the second room change the courage and maximum of the second room are there")
	_expect((third_room.get_component(third_hero, EcsComponents.PLAYER_COMBAT) as EcsComponents.PlayerCombat).sword_unlocked, "the sword is still there")
	_expect(third_room.flags.to_dictionary() == {"opened_toybox": true, "deaths": 1, "met_the_child": true}, "and every flag and counter of both rooms is there")
	_expect(PlayerSnapshot.capture(third_room, third_hero).to_dictionary() == PlayerSnapshot.capture(second_room, second_hero).to_dictionary(), "so the third room's snapshot equals the second's, row for row")
	for world in [first_room, second_room, third_room]:
		world.queue_free()


## One room change: capture, write as JSON text, read it back, apply to the new hero.
func _carry(from_world: EcsWorld, from_hero: int, to_world: EcsWorld, to_hero: int) -> void:
	var text := JSON.stringify(PlayerSnapshot.capture(from_world, from_hero).to_dictionary())
	var read_back: Variant = JSON.parse_string(text)
	var snapshot := PlayerSnapshot.from_dictionary(read_back)
	snapshot.apply_to(to_world, to_hero)


func _check_the_snapshot_never_shares_state_with_a_world() -> void:
	var world := _make_world()
	var hero := _spawn_hero(world, Vector2i(3, 3))
	world.flags.set_flag(&"a", 1)
	var snapshot := PlayerSnapshot.capture(world, hero)
	world.flags.set_flag(&"a", 5)
	world.flags.set_flag(&"b", true)
	_expect(snapshot.flags == {"a": 1}, "a snapshot is a copy: flags changed in the world afterwards do not reach it")
	var other_world := _make_world()
	var other_hero := _spawn_hero(other_world, Vector2i(3, 3))
	snapshot.apply_to(other_world, other_hero)
	other_world.flags.set_flag(&"a", 9)
	_expect(snapshot.flags == {"a": 1}, "and applying it copies too: the new world's flags changing do not reach the snapshot")
	world.queue_free()
	other_world.queue_free()


func _check_the_boot_applies_it() -> void:
	var paths := TestPaths.new(self)
	var encounter_scene := paths.load_scene(paths.first_encounter_scene())
	var player_scene := paths.load_scene(paths.actor_scene(&"player"))

	var plain_world := EcsWorld.new()
	var plain_room := encounter_scene.instantiate()
	root.add_child(plain_room)
	var plain_hero := player_scene.instantiate() as ActorView
	root.add_child(plain_hero)
	var plain_cast := EcsBoot.boot(plain_world, EcsBootOptions.for_scene(plain_hero, plain_room))
	var plain_health: EcsComponents.Health = plain_world.get_component(plain_cast["player"], EcsComponents.HEALTH)
	var definition_courage := plain_health.current
	_expect(EcsBootOptions.new().player_snapshot == null and not EcsBootOptions.new().restore_player_facing, "by default the options carry no snapshot and do not restore the facing")
	_expect(plain_world.flags.to_dictionary().is_empty(), "booting without a snapshot leaves the hero as the definition says (courage %d) and the flags empty" % definition_courage)

	var carried_world := EcsWorld.new()
	var carried_room := encounter_scene.instantiate()
	root.add_child(carried_room)
	var carried_hero := player_scene.instantiate() as ActorView
	root.add_child(carried_hero)
	var snapshot := PlayerSnapshot.new()
	snapshot.courage_current = 1
	snapshot.courage_max = definition_courage + 2
	snapshot.facing = Vector2i.LEFT
	snapshot.flags = {"deaths": 2}
	var carried_options := EcsBootOptions.for_scene(carried_hero, carried_room)
	carried_options.player_snapshot = snapshot
	var carried_cast := EcsBoot.boot(carried_world, carried_options)
	var carried_health: EcsComponents.Health = carried_world.get_component(carried_cast["player"], EcsComponents.HEALTH)
	_expect(carried_health.current == 1 and carried_health.max_value == definition_courage + 2, "booting with a snapshot gives the hero the carried courage and maximum")
	_expect(not (carried_world.get_component(carried_cast["player"], EcsComponents.PLAYER_COMBAT) as EcsComponents.PlayerCombat).sword_unlocked, "and the carried sword state (a snapshot without the sword takes it from a definition that starts with one)")
	_expect(carried_world.flags.to_dictionary() == {"deaths": 2}, "and the carried flags")
	_expect((carried_world.get_component(carried_cast["player"], EcsComponents.FACING) as EcsComponents.Facing).direction != Vector2i.LEFT, "but not the facing, which belongs to the entry marker")

	var resumed_world := EcsWorld.new()
	var resumed_room := encounter_scene.instantiate()
	root.add_child(resumed_room)
	var resumed_hero := player_scene.instantiate() as ActorView
	root.add_child(resumed_hero)
	var resumed_options := EcsBootOptions.for_scene(resumed_hero, resumed_room)
	resumed_options.player_snapshot = snapshot
	resumed_options.restore_player_facing = true
	var resumed_cast := EcsBoot.boot(resumed_world, resumed_options)
	_expect((resumed_world.get_component(resumed_cast["player"], EcsComponents.FACING) as EcsComponents.Facing).direction == Vector2i.LEFT, "with restore_player_facing the boot puts the carried facing back")

	for node: Node in [plain_room, plain_hero, carried_room, carried_hero, resumed_room, resumed_hero]:
		node.queue_free()
	for world: EcsWorld in [plain_world, carried_world, resumed_world]:
		world.free()
