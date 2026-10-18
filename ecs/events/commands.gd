class_name Commands
extends RefCounted

## Every request presentation and settings may send INTO the simulation, declared once
## (docs/game-base-plan.md D-38, 8.1): the mirror of Events. A command is a Dictionary with a
## "type", built by a function here and pushed with `world.push_command(Commands.set_flag(...))`;
## CommandSystem, at the head of the next tick, finds the handler registered for its type and
## applies it. It is the ONLY channel from presentation into the simulation: presentation reads
## events and the HudSnapshot, and when it wants something to change it asks here, so a decision
## (a flag, a freeze, a setting) never happens inside a bridge or a beat player.
##
## Like events, each command has a const for its name, a row in a banner table (status, what it
## asks, every payload key with its type and meaning) and a builder. EcsWorld.push_command() asserts
## in debug builds that a command matches its row; CommandSystem checks it again in every build and
## drops a request that does not (the `command_rejected` event says why).
##
## To add commands: append them inside your own banner with their consts and builders, and register
## a handler for each in the system that owns the state it changes. A FUTURE command is a reserved
## name nobody can push yet; the milestone that handles it flips it to HANDLED and writes its payload.
##
## World-level view instructions (world.view_commands) are declared here too, in VIEW_COMMANDS.

## A system registers a handler for it.
const STATUS_HANDLED := &"handled"
## The name is reserved for a later milestone; nothing handles it yet.
const STATUS_FUTURE := &"future"

# ------------------------------------------------------------------- the world itself (M3a, CommandSystem)
const FREEZE_REQUESTED := &"freeze_requested"
const UNFREEZE_REQUESTED := &"unfreeze_requested"
const SET_FLAG := &"set_flag"
const TUNING_SET := &"tuning_set"

const WORLD_COMMANDS: Dictionary = {
	FREEZE_REQUESTED: {
		"status": STATUS_HANDLED,
		"about": "Hold the simulation still (a cutscene beat, a pause); only the command and view systems keep ticking.",
		"payload": {
			"reason": "StringName: who asks and why, for the log (&\"beat\", &\"pause\")",
		},
	},
	UNFREEZE_REQUESTED: {
		"status": STATUS_HANDLED,
		"about": "Let the simulation run again.",
		"payload": {
			"reason": "StringName: who asks and why, for the log",
		},
	},
	SET_FLAG: {
		"status": STATUS_HANDLED,
		"about": "Set a world flag (a beat's `seen` mark, a counter). Says `flag_set` when the value changed.",
		"payload": {
			"flag": "StringName: the flag's id",
			"value": "Variant: a bool for a switch or an int for a counter; anything else is refused",
		},
	},
	TUNING_SET: {
		"status": STATUS_HANDLED,
		"about": "Change one assist or setting in world.tuning (see Tuning for the keys and their meanings).",
		"payload": {
			"key": "StringName: the name of a Tuning field",
			"value": "Variant: its new value, of the field's own type (a float field also takes an int)",
		},
	},
}

# ------------------------------------------------------------------- story (M6)
const ACTOR_COMMAND := &"actor_command"

const STORY_COMMANDS: Dictionary = {
	ACTOR_COMMAND: {"status": STATUS_FUTURE, "about": "M6: a beat tells an actor to walk, turn or wait.", "payload": {}},
}

# ------------------------------------------------------------------- progression (M7c)
const EQUIP_PAGE := &"equip_page"

const PROGRESSION_COMMANDS: Dictionary = {
	EQUIP_PAGE: {"status": STATUS_FUTURE, "about": "M7c: the Book equips or removes a page.", "payload": {}},
}

# ------------------------------------------------------------------- view commands (world.view_commands)
const PLAY_STATE := &"play_state"

## The cosmetic instructions for the puppet views. They never change the simulation, so they are
## not requests: ViewSyncSystem plays them as they come and drops one it cannot (a view that is
## gone, a state the actor's graph does not have).
const VIEW_COMMANDS: Dictionary = {
	PLAY_STATE: {
		"status": STATUS_HANDLED,
		"about": "Send an actor's animation graph to a state, or play that clip on a view that has no graph (wake, bow, hesitate).",
		"payload": {
			"entity": "int: the entity whose view plays it",
			"state": "StringName: the graph state or clip name",
		},
	},
}

## command type (StringName) -> its declaration ({status, about, payload}); built once from the banners.
static var _declaration_by_type: Dictionary = {}


## The declaration of every command for world.commands: command type -> {status, about, payload}.
static func declaration_by_type() -> Dictionary:
	if _declaration_by_type.is_empty():
		for banner: Dictionary in [WORLD_COMMANDS, STORY_COMMANDS, PROGRESSION_COMMANDS]:
			_declaration_by_type.merge(banner)
	return _declaration_by_type


static func is_declared(command_type: StringName) -> bool:
	return declaration_by_type().has(command_type)


## Every command type for world.commands whose status is `status`, sorted by name.
static func types_with_status(status: StringName) -> Array[StringName]:
	var found: Array[StringName] = []
	for command_type: StringName in declaration_by_type():
		if declaration_by_type()[command_type]["status"] == status:
			found.append(command_type)
	found.sort_custom(func(first: StringName, second: StringName) -> bool: return String(first) < String(second))
	return found


## Why this request for world.commands does not match its declaration, in words; "" when it does.
static func problem_with(command: Dictionary) -> String:
	return _problem_against(command, declaration_by_type())


## Why this instruction for world.view_commands does not match its declaration; "" when it does.
static func view_command_problem_with(view_command: Dictionary) -> String:
	return _problem_against(view_command, VIEW_COMMANDS)


static func _problem_against(command: Dictionary, table: Dictionary) -> String:
	if not command.has("type") or not (command["type"] is StringName):
		return "a command needs a StringName under \"type\": %s" % str(command)
	var command_type: StringName = command["type"]
	var declaration: Dictionary = table.get(command_type, {})
	if declaration.is_empty():
		return "command '%s' is not declared in ecs/events/commands.gd" % command_type
	if declaration["status"] != STATUS_HANDLED:
		return "command '%s' is declared FUTURE; nothing handles it yet" % command_type
	var payload_docs: Dictionary = declaration["payload"]
	for key: String in payload_docs:
		if not command.has(key):
			return "command '%s' is missing the documented key '%s'" % [command_type, key]
	for key: Variant in command:
		if key != "type" and not payload_docs.has(key):
			return "command '%s' carries the undocumented key '%s'" % [command_type, key]
	return ""


static func freeze_requested(reason: StringName) -> Dictionary:
	return {"type": FREEZE_REQUESTED, "reason": reason}


static func unfreeze_requested(reason: StringName) -> Dictionary:
	return {"type": UNFREEZE_REQUESTED, "reason": reason}


static func set_flag(flag: StringName, value: Variant) -> Dictionary:
	return {"type": SET_FLAG, "flag": flag, "value": value}


static func tuning_set(key: StringName, value: Variant) -> Dictionary:
	return {"type": TUNING_SET, "key": key, "value": value}


static func play_state(entity: int, state: StringName) -> Dictionary:
	return {"type": PLAY_STATE, "entity": entity, "state": state}
