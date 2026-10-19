class_name CommandSystem
extends EcsSystem

## The head of every tick: drains world.commands, the only channel from presentation and settings
## into the simulation (docs/game-base-plan.md D-38), and applies each request, in the order it was
## pushed, before anything simulates. Requests pushed during a tick (by a handler, or by the shell
## after it) wait for the next one.
##
## Reads: world.commands, world.command_handler_by_type. Writes: world.frozen, world.flags,
## world.tuning (the four commands of Commands.WORLD_COMMANDS, handled here because they only touch
## world fields); every other command is applied by the handler the system that owns its state
## registered with world.register_command_handler(). Emits: `flag_set`, and `command_rejected` for
## a request that is malformed, unhandled or refused by its handler (it is dropped, never retried).
##
## It keeps ticking while the world is frozen: a freeze that could not be lifted would end the game.

## The schedule stage this system is listed in (ecs/schedule/command.gd).
const PHASE := &"command"


func setup(ecs_world: EcsWorld) -> void:
	super.setup(ecs_world)
	world.register_command_handler(Commands.FREEZE_REQUESTED, _on_freeze_requested)
	world.register_command_handler(Commands.UNFREEZE_REQUESTED, _on_unfreeze_requested)
	world.register_command_handler(Commands.SET_FLAG, _on_set_flag)
	world.register_command_handler(Commands.TUNING_SET, _on_tuning_set)


func runs_while_frozen() -> bool:
	return true


func tick(_delta: float) -> void:
	if world.commands.is_empty():
		return
	# Work on a copy and empty the queue in place, so whoever holds world.commands keeps a live
	# reference, and a request pushed while these run lands in the next tick's batch.
	var batch := world.commands.duplicate()
	world.commands.clear()
	for command in batch:
		_apply(command)


func _apply(command: Dictionary) -> void:
	var command_type: StringName = &""
	if command.get("type") is StringName:
		command_type = command["type"]
	var problem := Commands.problem_with(command)
	if not problem.is_empty():
		_reject(command_type, problem)
		return
	var handler: Callable = world.command_handler_by_type.get(command_type, Callable())
	if not handler.is_valid():
		_reject(command_type, "no system has registered a handler for '%s'" % command_type)
		return
	var verdict: Variant = handler.call(command)
	if not (verdict is String):
		_reject(command_type, "the handler of '%s' returned no verdict (it must return \"\" or the reason it refused)" % command_type)
	elif not (verdict as String).is_empty():
		_reject(command_type, verdict)


func _reject(command_type: StringName, reason: String) -> void:
	world.emit_event({"type": Events.COMMAND_REJECTED, "command": command_type, "reason": reason})


func _on_freeze_requested(_command: Dictionary) -> String:
	world.frozen = true
	return ""


func _on_unfreeze_requested(_command: Dictionary) -> String:
	world.frozen = false
	return ""


func _on_set_flag(command: Dictionary) -> String:
	var value: Variant = command["value"]
	if not (value is bool or value is int):
		return "a flag holds a bool (a switch) or an int (a counter), not a %s" % type_string(typeof(value))
	var flag_id: StringName = command["flag"]
	if world.flags.set_flag(flag_id, value):
		world.emit_event({"type": Events.FLAG_SET, "flag": flag_id, "value": value})
	return ""


func _on_tuning_set(command: Dictionary) -> String:
	var key: StringName = command["key"]
	if key not in _tuning_keys():
		return "world.tuning has no setting called '%s' (it has: %s)" % [key, ", ".join(PackedStringArray(_tuning_keys()))]
	var value: Variant = command["value"]
	var current: Variant = world.tuning.get(key)
	if current is float and (value is float or value is int):
		world.tuning.set(key, float(value))
	elif current is int and value is int:
		world.tuning.set(key, value)
	else:
		return "'%s' holds a %s, not a %s" % [key, type_string(typeof(current)), type_string(typeof(value))]
	return ""


## The names of the fields of world.tuning: the variables its script declares.
func _tuning_keys() -> Array[StringName]:
	var keys: Array[StringName] = []
	for property in world.tuning.get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			keys.append(StringName(property["name"]))
	return keys
