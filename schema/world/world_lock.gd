class_name WorldLock
extends Resource

## Why a door is shut and what it says about it (docs/game-base-plan.md 5.7): "every locked exit shows why".
## One condition and one sentence. The condition kinds are the plan's: the room is cleared, a flag is set (a boss
## defeated is the flag `boss.<id>`), an unlock was gained, a counter reached a number. There is no rank
## condition (D-13). The runtime holds a door for the first two kinds today (a `room_clear` lock is the door's
## `requires_room_clear`, a `flag` lock its `requires_flag`); the other two are DATA until the milestone named in
## `arrives_in` lands (the skill locks of M7c, `kind = "unlock"`): the door stays OPEN meanwhile, so the route
## can never dead-end on a verb that does not exist yet.
##
## The sentence is a TEXT KEY (a row of content/story/text/<language>/rooms.po), never words.

const KIND_ROOM_CLEAR := "room_clear"
const KIND_FLAG := "flag"
const KIND_UNLOCK := "unlock"
const KIND_COUNTER_AT_LEAST := "counter_at_least"
## Every kind a lock may have, in the order the Inspector offers them.
const KINDS: Array[String] = [KIND_ROOM_CLEAR, KIND_FLAG, KIND_UNLOCK, KIND_COUNTER_AT_LEAST]
## The kinds the runtime holds a door for today (MovementSystem): the others wait for a milestone (`arrives_in`).
const ENFORCED_KINDS: Array[String] = [KIND_ROOM_CLEAR, KIND_FLAG]
## A milestone as the plan writes it: M, a number, an optional letter (`M7c`).
const MILESTONE_PATTERN := "^M[0-9]+[a-z]?$"
## The spelling of a text key (UPPER_SNAKE with a prefix). Whether the row exists is checked by the tests that
## can read the .po files; a schema class names nothing outside itself.
const TEXT_KEY_PATTERN := "^[A-Z][A-Z0-9]*(_[A-Z0-9]+)+$"

## The lock's id, lowercase snake_case, unique in the world graph (WorldEdge.lock_id names it).
@export var lock_id: StringName = &""
## What opens the door: `room_clear` (every enemy of the room the door is in has fallen), `flag` (the flag `subject`
## is set), `unlock` (the pawn has gained the unlock `subject`), `counter_at_least` (the counter `subject` has
## reached `at_least`).
@export_enum("room_clear", "flag", "unlock", "counter_at_least") var kind := KIND_ROOM_CLEAR
## The flag id (`flag`, `counter_at_least`: see FlagId) or the unlock id (`unlock`) the condition asks about.
## Empty for `room_clear`, which asks about the room the door is in.
@export var subject: StringName = &""
## The number the counter must reach (`counter_at_least` only).
@export_range(1, 99) var at_least := 1
## Text key: the line the status bar says when the pawn steps on the shut door (a ROOM_ row of rooms.po).
@export var message_key := ""
## The milestone that makes the runtime hold this lock, written as the plan names it (`M7c`); empty when the
## runtime holds it already (`room_clear` and `flag`). A lock that is not held yet is only a promise on the door:
## the line it will say is already written, and the door is open until then. The two kinds the runtime does not
## hold (`unlock`, `counter_at_least`) must say when they will be.
@export var arrives_in := ""


## True when the runtime holds a door for this lock today.
func is_enforced() -> bool:
	return kind in ENFORCED_KINDS


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	var label := "Lock '%s'" % lock_id
	if lock_id == &"" or RegEx.create_from_string("^[a-z][a-z0-9_]*$").search(String(lock_id)) == null:
		problems.append("A lock needs a lock_id in lowercase snake_case (it is '%s')." % lock_id)
	if kind not in KINDS:
		problems.append("%s has the kind '%s'; the kinds are %s." % [label, kind, ", ".join(KINDS)])
	if message_key.strip_edges().is_empty():
		problems.append("%s has no message_key: every locked exit must say why it is shut." % label)
	elif RegEx.create_from_string(TEXT_KEY_PATTERN).search(message_key) == null:
		problems.append("%s has the message_key '%s', which is not a text key (UPPER_SNAKE such as ROOM_H1_CHESS_RUG_HUB_LOCKED_TOYBOX)." % [label, message_key])
	if kind in ENFORCED_KINDS:
		if arrives_in != "":
			problems.append("%s is held by the runtime already, so it arrives in no milestone (arrives_in is '%s')." % [label, arrives_in])
	elif arrives_in == "":
		problems.append("%s of kind %s is not held by the runtime yet: say in arrives_in which milestone makes it so (for example M7c), so the door stays open until then." % [label, kind])
	elif RegEx.create_from_string(MILESTONE_PATTERN).search(arrives_in) == null:
		problems.append("%s says it arrives in '%s', which is not a milestone (M7c)." % [label, arrives_in])
	match kind:
		KIND_ROOM_CLEAR:
			if subject != &"":
				problems.append("%s asks whether the room is cleared, so its subject must be empty (it is '%s')." % [label, subject])
		KIND_FLAG, KIND_COUNTER_AT_LEAST:
			if not FlagId.is_valid(subject):
				problems.append("%s needs a flag id as its subject (for example boss.knight_captain); '%s' is not one." % [label, subject])
		KIND_UNLOCK:
			if RegEx.create_from_string("^[a-z][a-z0-9_]*$").search(String(subject)) == null:
				problems.append("%s needs an unlock id as its subject (for example rule_step); '%s' is not one." % [label, subject])
	return problems
