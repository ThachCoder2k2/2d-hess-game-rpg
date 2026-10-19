extends UnboundTest

## world.commands is the only channel from presentation and settings into the simulation
## (docs/game-base-plan.md D-38, 15 M3a): typed requests, declared once in ecs/events/commands.gd,
## drained by CommandSystem at the head of every tick in the order they were pushed, applied by a
## handler registered per type, and dropped with a `command_rejected` event when they do not match
## their declaration, have no handler or are refused. This suite drives the channel through the real
## CommandSystem: the order and timing, the four world commands (freeze, thaw, flag, tuning), the
## rejections and the handler registry.

## Sits after CommandSystem in the tick and records what it saw of the world there.
class Watcher:
	extends EcsSystem

	var ticks := 0
	var flag_seen_this_tick: Variant = null
	var command_to_push_on_first_tick: Dictionary = {}

	func tick(_delta: float) -> void:
		ticks += 1
		flag_seen_this_tick = world.flags.get_flag(&"x", null)
		if ticks == 1 and not command_to_push_on_first_tick.is_empty():
			world.push_command(command_to_push_on_first_tick)


func _init() -> void:
	suite_title = "COMMANDS CHANNEL TEST"
	_check_the_declarations()
	_check_commands_apply_at_the_head_of_the_next_tick_in_order()
	_check_set_flag()
	_check_tuning_set()
	_check_freeze_and_thaw()
	_check_a_bad_request_is_dropped_with_its_reason()
	_check_the_handler_registry()
	_check_the_queue_reference_stays_live()
	_check_every_handled_command_has_a_handler_in_the_schedule()
	finish()


func _make_world_with_command_system() -> EcsWorld:
	var world := EcsWorld.new()
	world.manual_tick = true
	root.add_child(world)
	world.add_system(CommandSystem.new())
	return world


func _events_of_type(events: Array[Dictionary], event_type: StringName) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for event in events:
		if event.get("type") == event_type:
			found.append(event)
	return found


func _check_the_declarations() -> void:
	var plan_names: Array[StringName] = [&"set_flag", &"freeze_requested", &"unfreeze_requested", &"tuning_set", &"actor_command", &"equip_page"]
	var all_declared := true
	for command_type in plan_names:
		all_declared = all_declared and Commands.is_declared(command_type)
	_expect(all_declared, "the six requests the plan names (set_flag, freeze_requested, unfreeze_requested, tuning_set, actor_command, equip_page) are declared")
	var handled := Commands.types_with_status(Commands.STATUS_HANDLED)
	var expected_handled: Array[StringName] = [&"freeze_requested", &"set_flag", &"tuning_set", &"unfreeze_requested"]
	_expect(handled == expected_handled, "four requests are handled today: %s" % ", ".join(PackedStringArray(handled)))
	var expected_future: Array[StringName] = [&"actor_command", &"equip_page"]
	_expect(Commands.types_with_status(Commands.STATUS_FUTURE) == expected_future, "two are reserved for later milestones (actor_command, equip_page)")

	_expect(Commands.problem_with(Commands.freeze_requested(&"beat")).is_empty(), "the freeze builder makes a request that matches its declaration")
	_expect(Commands.problem_with(Commands.unfreeze_requested(&"beat")).is_empty(), "the thaw builder makes a request that matches its declaration")
	_expect(Commands.problem_with(Commands.set_flag(&"seen", true)).is_empty(), "the set_flag builder makes a request that matches its declaration")
	_expect(Commands.problem_with(Commands.tuning_set(&"extra_courage", 1)).is_empty(), "the tuning_set builder makes a request that matches its declaration")
	_expect(Commands.view_command_problem_with(Commands.play_state(3, &"wake")).is_empty(), "the play_state builder makes a view command that matches its declaration")

	_expect(Commands.problem_with({"flag": &"x"}).contains("needs a StringName"), "a request with no type is refused")
	_expect(Commands.problem_with({"type": "set_flag", "flag": &"x", "value": true}).contains("needs a StringName"), "a request whose type is a plain String is refused")
	_expect(Commands.problem_with({"type": &"made_up"}).contains("not declared"), "an undeclared request is refused")
	_expect(Commands.problem_with({"type": Commands.SET_FLAG, "flag": &"x"}).contains("missing the documented key 'value'"), "a request missing a documented key is refused")
	_expect(Commands.problem_with({"type": Commands.SET_FLAG, "flag": &"x", "value": true, "extra": 1}).contains("undocumented key 'extra'"), "a request with an undocumented key is refused")
	_expect(Commands.problem_with({"type": Commands.ACTOR_COMMAND}).contains("FUTURE"), "a request reserved for a later milestone is refused until it is handled")

	var every_row_complete := true
	for banner: Dictionary in [Commands.WORLD_COMMANDS, Commands.STORY_COMMANDS, Commands.PROGRESSION_COMMANDS, Commands.VIEW_COMMANDS]:
		for command_type: StringName in banner:
			var declaration: Dictionary = banner[command_type]
			var payload: Dictionary = declaration["payload"]
			var complete: bool = String(declaration.get("about", "")).length() > 10
			if declaration["status"] == Commands.STATUS_HANDLED:
				complete = complete and not payload.is_empty()
			for key: String in payload:
				complete = complete and String(payload[key]).length() > 5
			every_row_complete = every_row_complete and complete
	_expect(every_row_complete, "every command says what it asks and documents each payload key")


func _check_commands_apply_at_the_head_of_the_next_tick_in_order() -> void:
	var world := _make_world_with_command_system()
	var watcher := Watcher.new()
	world.add_system(watcher)
	world.push_command(Commands.set_flag(&"x", 1))
	world.push_command(Commands.set_flag(&"x", 2))
	_expect(not world.flags.has_flag(&"x") and world.commands.size() == 2, "a pushed request is only queued: nothing changes until the world ticks")
	world.tick(0.016)
	_expect(watcher.flag_seen_this_tick == 2, "both requests were applied before the next system of the same tick, in push order (the later value wins)")
	var changes := _events_of_type(world.drain_events(), Events.FLAG_SET)
	_expect(changes.size() == 2 and changes[0]["value"] == 1 and changes[1]["value"] == 2, "each applied request announced itself, in order")
	_expect(world.commands.is_empty(), "the queue is empty after the tick")

	var late := _make_world_with_command_system()
	var pushing_watcher := Watcher.new()
	pushing_watcher.command_to_push_on_first_tick = Commands.set_flag(&"y", true)
	late.add_system(pushing_watcher)
	late.tick(0.016)
	_expect(not late.flags.has_flag(&"y") and late.commands.size() == 1, "a request pushed during a tick waits: it is not applied in that tick")
	late.tick(0.016)
	_expect(late.flags.get_flag(&"y") == true and late.commands.is_empty(), "and is applied at the head of the next one")
	world.queue_free()
	late.queue_free()


func _check_set_flag() -> void:
	var world := _make_world_with_command_system()
	world.push_command(Commands.set_flag(&"met_the_child", true))
	world.push_command(Commands.set_flag(&"met_the_child", true))
	world.push_command(Commands.set_flag(&"child_calls_used", 2))
	world.tick(0.016)
	_expect(world.flags.get_flag(&"met_the_child") == true and world.flags.get_flag(&"child_calls_used") == 2, "a switch and a counter are set")
	var events := world.drain_events()
	var flag_events := _events_of_type(events, Events.FLAG_SET)
	_expect(flag_events.size() == 2, "setting a flag to the value it already had says nothing: two changes, two events")
	_expect(flag_events[0]["flag"] == &"met_the_child" and flag_events[0]["value"] == true, "`flag_set` names the flag and its new value")
	world.push_command(Commands.set_flag(&"half", 0.5))
	world.push_command(Commands.set_flag(&"text", "yes"))
	world.tick(0.016)
	var refused := _events_of_type(world.drain_events(), Events.COMMAND_REJECTED)
	_expect(refused.size() == 2 and not world.flags.has_flag(&"half") and not world.flags.has_flag(&"text"), "a flag value that is not a bool or an int is refused and nothing is stored")
	_expect(refused[0]["command"] == Commands.SET_FLAG and String(refused[0]["reason"]).contains("bool"), "the refusal names the command and says what a flag holds")
	world.queue_free()


func _check_tuning_set() -> void:
	var world := _make_world_with_command_system()
	world.push_command(Commands.tuning_set(&"telegraph_time_scale", 1.5))
	world.push_command(Commands.tuning_set(&"enemy_pace_scale", 1))
	world.push_command(Commands.tuning_set(&"extra_courage", 2))
	world.push_command(Commands.tuning_set(&"input_buffer_window", 0.2))
	world.tick(0.016)
	_expect(is_equal_approx(world.tuning.telegraph_time_scale, 1.5) and is_equal_approx(world.tuning.input_buffer_window, 0.2) and world.tuning.extra_courage == 2, "the assists are set through the channel")
	_expect(is_equal_approx(world.tuning.enemy_pace_scale, 1.0) and typeof(world.tuning.enemy_pace_scale) == TYPE_FLOAT, "an int given for a float setting is stored as a float")
	_expect(world.drain_events().is_empty(), "applying tuning is quiet")

	world.push_command(Commands.tuning_set(&"no_such_setting", 1))
	world.push_command(Commands.tuning_set(&"script", 1))
	world.push_command(Commands.tuning_set(&"extra_courage", 1.5))
	world.push_command(Commands.tuning_set(&"telegraph_time_scale", "slow"))
	world.tick(0.016)
	var refused := _events_of_type(world.drain_events(), Events.COMMAND_REJECTED)
	_expect(refused.size() == 4, "an unknown key, an engine property, a float for an int setting and a string for a float setting are all refused")
	_expect(world.tuning.extra_courage == 2 and is_equal_approx(world.tuning.telegraph_time_scale, 1.5), "and none of them changed anything")
	_expect(String(refused[0]["reason"]).contains("no_such_setting") and String(refused[0]["reason"]).contains("extra_courage"), "the refusal names the key and lists the settings that exist")
	world.queue_free()


func _check_freeze_and_thaw() -> void:
	var world := _make_world_with_command_system()
	var watcher := Watcher.new()
	world.add_system(watcher)
	world.tick(0.016)
	_expect(watcher.ticks == 1 and not world.frozen, "setup: a thawed world ticks the system after the command system")

	world.push_command(Commands.freeze_requested(&"beat"))
	world.tick(0.016)
	_expect(world.frozen and watcher.ticks == 1, "a freeze request applied at the head of a tick stops the rest of that very tick")
	world.tick(0.016)
	_expect(watcher.ticks == 1, "and the world stays held on the next ticks")

	world.push_command(Commands.set_flag(&"x", 7))
	world.tick(0.016)
	_expect(world.flags.get_flag(&"x") == 7 and watcher.ticks == 1, "a frozen world still accepts and applies requests, while everything else waits")

	world.push_command(Commands.unfreeze_requested(&"beat"))
	world.tick(0.016)
	_expect(not world.frozen and watcher.ticks == 2, "a thaw request applied at the head of a tick lets that same tick run the rest of the systems")
	world.queue_free()


func _check_a_bad_request_is_dropped_with_its_reason() -> void:
	var world := _make_world_with_command_system()
	# Pushed straight onto the queue: push_command() would stop a malformed request at the door.
	world.commands.append({"type": &"made_up"})
	world.commands.append({"type": Commands.SET_FLAG, "flag": &"only_flag"})
	world.commands.append({"type": Commands.ACTOR_COMMAND})
	world.commands.append({"nothing": true})
	world.commands.append({"type": "set_flag", "flag": &"x", "value": true})
	world.commands.append(Commands.set_flag(&"good", true))
	world.tick(0.016)
	var events := world.drain_events()
	var refused := _events_of_type(events, Events.COMMAND_REJECTED)
	_expect(refused.size() == 5, "five malformed requests are dropped, each with a `command_rejected` event")
	var reasons: Array[String] = []
	for event in refused:
		reasons.append(String(event["reason"]))
	_expect(reasons[0].contains("not declared") and reasons[1].contains("missing") and reasons[2].contains("FUTURE") and reasons[3].contains("needs a StringName") and reasons[4].contains("needs a StringName"), "each reason says what was wrong: undeclared, missing key, reserved, no type, type not a StringName")
	_expect(refused[0]["command"] == &"made_up" and refused[3]["command"] == &"" and refused[4]["command"] == &"", "the event names the command type, or nothing when the request had none")
	_expect(world.flags.get_flag(&"good") == true and not world.flags.has_flag(&"x") and not world.flags.has_flag(&"only_flag"), "a bad request does not stop the good one after it, and changed nothing itself")
	_expect(world.commands.is_empty(), "dropped requests are not retried")
	world.queue_free()


func _check_the_handler_registry() -> void:
	var world := _make_world_with_command_system()
	var handled: Array[Dictionary] = []
	world.register_command_handler(Commands.SET_FLAG, func(command: Dictionary) -> String:
		handled.append(command)
		return "")
	world.push_command(Commands.set_flag(&"x", true))
	world.tick(0.016)
	_expect(handled.size() == 1 and not world.flags.has_flag(&"x"), "a handler registered for a type replaces the one before it: it got the request and CommandSystem's own did not run")

	world.register_command_handler(Commands.SET_FLAG, func(_command: Dictionary) -> String: return "not today")
	world.push_command(Commands.set_flag(&"x", true))
	world.tick(0.016)
	var refused := _events_of_type(world.drain_events(), Events.COMMAND_REJECTED)
	_expect(refused.size() == 1 and refused[0]["reason"] == "not today", "a handler that returns a reason refuses the request, and that reason is reported")

	world.register_command_handler(Commands.SET_FLAG, func(_command: Dictionary) -> Variant: return null)
	world.push_command(Commands.set_flag(&"x", true))
	world.tick(0.016)
	refused = _events_of_type(world.drain_events(), Events.COMMAND_REJECTED)
	_expect(refused.size() == 1 and String(refused[0]["reason"]).contains("no verdict"), "a handler that returns nothing is a bug and is reported, not taken for success")

	world.command_handler_by_type.erase(Commands.SET_FLAG)
	world.push_command(Commands.set_flag(&"x", true))
	world.tick(0.016)
	refused = _events_of_type(world.drain_events(), Events.COMMAND_REJECTED)
	_expect(refused.size() == 1 and String(refused[0]["reason"]).contains("no system has registered a handler"), "a declared request nobody handles is dropped and says so")
	world.queue_free()


func _check_the_queue_reference_stays_live() -> void:
	var world := _make_world_with_command_system()
	var held_queue := world.commands
	held_queue.append(Commands.set_flag(&"through_held_reference", true))
	world.tick(0.016)
	_expect(world.flags.get_flag(&"through_held_reference") == true and held_queue.is_empty(), "whoever holds world.commands keeps a live queue: draining empties it in place and never swaps it")
	world.queue_free()


func _check_every_handled_command_has_a_handler_in_the_schedule() -> void:
	var world := EcsWorld.new()
	world.manual_tick = true
	root.add_child(world)
	Schedule.populate(world)
	var unhandled: Array[String] = []
	for command_type in Commands.types_with_status(Commands.STATUS_HANDLED):
		var handler: Callable = world.command_handler_by_type.get(command_type, Callable())
		if not handler.is_valid():
			unhandled.append(String(command_type))
	_expect(unhandled.is_empty(), "the full schedule registers a handler for every command declared HANDLED (without: %s)" % ", ".join(PackedStringArray(unhandled)))
	var unknown: Array[String] = []
	for command_type: StringName in world.command_handler_by_type:
		if not Commands.is_declared(command_type):
			unknown.append(String(command_type))
	_expect(unknown.is_empty(), "and no handler is registered for a command that is not declared (%s)" % ", ".join(PackedStringArray(unknown)))
	world.queue_free()
