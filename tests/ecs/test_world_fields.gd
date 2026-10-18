extends UnboundTest

## Every shared field of EcsWorld lands once, in M3a (docs/game-base-plan.md 14.1, 14.5): frozen,
## flags, tuning, input_snapshot, hud_snapshot, commands, view_commands, the heal queue. This suite
## holds what a fresh world looks like (every field present, empty or neutral, so a world that
## never touches them plays exactly as before M3a) and the small data classes the fields hold.
## What the fields DO is in test_frozen_world, test_commands_channel and test_heal_queue.


func _init() -> void:
	suite_title = "WORLD FIELDS TEST"
	_check_a_fresh_world()
	_check_worlds_do_not_share_state()
	_check_world_flags()
	_check_tuning_is_neutral()
	_check_input_snapshot()
	finish()


func _check_a_fresh_world() -> void:
	var world := EcsWorld.new()
	_expect(world.frozen == false, "a fresh world is not frozen")
	_expect(world.flags is WorldFlags and world.flags.value_by_flag_id.is_empty(), "a fresh world has an empty WorldFlags")
	_expect(world.tuning is Tuning, "a fresh world has a Tuning")
	_expect(world.input_snapshot is InputSnapshot and world.input_snapshot.state_by_action.is_empty(), "a fresh world has an empty InputSnapshot")
	_expect(world.hud_snapshot is HudSnapshot and world.hud_snapshot.revision == 0, "a fresh world has a HudSnapshot that was never built (revision 0)")
	_expect(world.commands.is_empty() and world.view_commands.is_empty(), "a fresh world has no commands and no view commands")
	_expect(world.damage_events.is_empty() and world.heal_events.is_empty() and world.pending_events.is_empty(), "a fresh world has empty damage, heal and event queues")
	_expect(world.command_handler_by_type.is_empty(), "a fresh world has no command handlers until a system registers them")
	world.free()


func _check_worlds_do_not_share_state() -> void:
	var first := EcsWorld.new()
	var second := EcsWorld.new()
	first.flags.set_flag(&"seen_intro", true)
	first.tuning.extra_courage = 2
	first.input_snapshot.set_state(&"attack", InputSnapshot.ActionState.new())
	first.hud_snapshot.revision = 4
	first.commands.append({"type": &"anything"})
	_expect(not second.flags.has_flag(&"seen_intro") and second.tuning.extra_courage == 0 and second.input_snapshot.state_by_action.is_empty() and second.hud_snapshot.revision == 0 and second.commands.is_empty(), "two worlds never share flags, tuning, snapshots or queues (the shell rebuilds the world for every room)")
	first.free()
	second.free()


func _check_world_flags() -> void:
	var flags := WorldFlags.new()
	_expect(not flags.has_flag(&"met_the_child") and flags.get_flag(&"met_the_child") == false, "a flag never set is absent and reads false")
	_expect(flags.get_flag(&"child_calls_used", 0) == 0, "a flag never set reads the default the caller gives")
	_expect(flags.set_flag(&"met_the_child", true), "setting a flag to a new value says it changed")
	_expect(not flags.set_flag(&"met_the_child", true), "setting it to the value it has says nothing changed")
	_expect(flags.set_flag(&"met_the_child", false) and flags.get_flag(&"met_the_child") == false and flags.has_flag(&"met_the_child"), "a flag set back to false is still a flag that exists")
	_expect(flags.set_flag(&"count", 0) and not flags.set_flag(&"count", 0), "a counter set to 0 is a change once")
	_expect(flags.add_to_counter(&"child_calls_used") == 1 and flags.add_to_counter(&"child_calls_used", 2) == 3, "a counter counts from 0 and adds what it is given")
	var saved := flags.to_dictionary()
	_expect(saved.keys().all(func(key: Variant) -> bool: return key is String) and saved["child_calls_used"] == 3, "the saved form is plain data with String keys")
	var restored := WorldFlags.new()
	restored.set_flag(&"left_over", true)
	restored.load_dictionary(saved)
	_expect(restored.to_dictionary() == saved and not restored.has_flag(&"left_over"), "loading the saved form replaces every flag, and nothing is left over")
	flags.clear()
	_expect(flags.value_by_flag_id.is_empty(), "clear forgets every flag")


func _check_tuning_is_neutral() -> void:
	var tuning := Tuning.new()
	_expect(is_equal_approx(tuning.telegraph_time_scale, 1.0) and is_equal_approx(tuning.enemy_pace_scale, 1.0), "a fresh Tuning scales telegraphs and enemy pace by 1.0, the standard game")
	_expect(is_zero_approx(tuning.input_buffer_window), "a fresh Tuning leaves the input buffer unexpiring (0.0), as the game plays today until M7b")
	_expect(tuning.extra_courage == 0, "a fresh Tuning adds no courage")
	_expect(Tuning.KEY == &"tuning", "Tuning carries its store key like every component")


func _check_input_snapshot() -> void:
	var snapshot := InputSnapshot.new()
	_expect(not snapshot.is_pressed(&"attack") and not snapshot.is_just_pressed(&"attack") and not snapshot.is_just_released(&"attack") and is_zero_approx(snapshot.held_time_of(&"attack")), "an action nobody set reads as not pressed, not just pressed, not just released, held for 0 s")
	_expect(snapshot.state_of(&"attack").timestamp_msec == -1, "an unset action was never pressed (timestamp -1)")
	var state := InputSnapshot.ActionState.new()
	state.pressed = true
	state.just_pressed = true
	state.held_time = 0.25
	state.timestamp_msec = 1200
	snapshot.set_state(&"move_left", state)
	_expect(snapshot.is_pressed(&"move_left") and snapshot.is_just_pressed(&"move_left") and not snapshot.is_just_released(&"move_left") and is_equal_approx(snapshot.held_time_of(&"move_left"), 0.25), "a set action reads back as it was given")
	_expect(not snapshot.is_pressed(&"move_right"), "setting one action leaves the others released")
	snapshot.clear()
	_expect(not snapshot.is_pressed(&"move_left"), "clear releases every action")
