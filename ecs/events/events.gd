class_name Events
extends RefCounted

## Every event the simulation can send to presentation, declared once (docs/game-base-plan.md
## 14.3). An event is a Dictionary pushed with `world.emit_event({"type": Events.STEP_STARTED,
## ...})` and read once per frame with `world.drain_events()`; it is the ONLY channel from the
## simulation to presentation. This file is the contract:
##
##   - one const per event name, so a typo is a parse error and not a silently dead event;
##   - one entry per event in a banner table below: its status, what happened (`about`) and every
##     payload key with the type and meaning of its value (`payload`);
##   - emit_damage(), the only way to queue a damage request.
##
## EcsWorld.emit_event() asserts (in debug builds) that an event is declared, that its status is
## EMITTED and that its keys are exactly the documented ones, so an undocumented key, a missing key
## or an event nobody declared stops the first test that emits it. tests/architecture/
## test_events_declared.gd greps the code for every emitted name and checks both directions: an
## emitted name must be declared, and a declared EMITTED event must really be emitted.
##
## To add events: append them inside your own banner (the milestone names the banner) and add
## their consts above it. A FUTURE event is a reserved name with no payload yet; the milestone that
## first emits it flips it to EMITTED and writes its payload in the same commit.

## The event is emitted by code that exists.
const STATUS_EMITTED := &"emitted"
## The name is reserved for a later milestone and nothing emits it yet.
const STATUS_FUTURE := &"future"

# ------------------------------------------------------------------- movement (MovementSystem)
const STEP_STARTED := &"step_started"
const STEP_FINISHED := &"step_finished"
const STEP_BLOCKED := &"step_blocked"
const GATE_OPENED := &"gate_opened"
const ZONE_EXIT := &"zone_exit"
const ZONE_EXIT_LOCKED := &"zone_exit_locked"
const PLAYER_UNLOCK := &"player_unlock"

const MOVEMENT_EVENTS: Dictionary = {
	STEP_STARTED: {
		"status": STATUS_EMITTED,
		"about": "A step began: the destination cell is reserved and the slide starts.",
		"payload": {
			"entity": "int: the entity that began the step",
			"cell": "Vector2i: the destination cell, now reserved for it",
		},
	},
	STEP_FINISHED: {
		"status": STATUS_EMITTED,
		"about": "A step ended: the entity stands on its destination cell.",
		"payload": {
			"entity": "int: the entity that landed",
			"cell": "Vector2i: the cell it now occupies",
		},
	},
	STEP_BLOCKED: {
		"status": STATUS_EMITTED,
		"about": "A step was refused (wall, occupied or reserved cell); facing still turned.",
		"payload": {
			"entity": "int: the entity that tried to step",
			"direction": "Vector2i: the way it tried to go",
		},
	},
	GATE_OPENED: {
		"status": STATUS_EMITTED,
		"about": "The player pushed a shortcut gate open from its opening side; it is floor for good.",
		"payload": {
			"entity": "int: the player entity",
			"gate": "StringName: the gate's id (GateMarker.gate_id), the key the save remembers it by",
			"cell": "Vector2i: the gate's cell, now ordinary floor",
		},
	},
	ZONE_EXIT: {
		"status": STATUS_EMITTED,
		"about": "The player landed on a door cell that is open: the shell travels to another zone.",
		"payload": {
			"entity": "int: the player entity",
			"zone": "StringName: id of the destination zone",
			"entry": "StringName: id of the entry marker to arrive on",
		},
	},
	ZONE_EXIT_LOCKED: {
		"status": STATUS_EMITTED,
		"about": "The player landed on a door cell that needs the room cleared first; the door stays shut.",
		"payload": {
			"entity": "int: the player entity",
			"zone": "StringName: id of the zone the door leads to",
			"entry": "StringName: id of the entry marker it would arrive on",
			"cell": "Vector2i: the door cell",
		},
	},
	PLAYER_UNLOCK: {
		"status": STATUS_EMITTED,
		"about": "The player landed on a verb-unlock cell (the fallen sword).",
		"payload": {
			"entity": "int: the player entity",
			"id": "StringName: the unlock's id (PlayerUnlockMarker.unlock_id)",
			"message": "String: the line the HUD shows for it",
		},
	},
}

# ------------------------------------------------------------------- combat (CombatSystem)
const ATTACK_STARTED := &"attack_started"
const ATTACK_LOCKED := &"attack_locked"
const ATTACK_LANDED := &"attack_landed"
const SKILL_COOLDOWN := &"skill_cooldown"

const COMBAT_EVENTS: Dictionary = {
	ATTACK_STARTED: {
		"status": STATUS_EMITTED,
		"about": "The player's swing began; its target cells are locked from now on.",
		"payload": {
			"entity": "int: the attacking entity",
			"cells": "Array[Vector2i]: the cells the swing will hit",
		},
	},
	ATTACK_LOCKED: {
		"status": STATUS_EMITTED,
		"about": "The player pressed attack but has not unlocked a weapon yet.",
		"payload": {
			"entity": "int: the player entity",
		},
	},
	ATTACK_LANDED: {
		"status": STATUS_EMITTED,
		"about": "The player's swing reached its impact moment and damaged whatever stood in the cells.",
		"payload": {
			"entity": "int: the attacking entity",
			"cells": "Array[Vector2i]: the cells that were struck",
			"hit_count": "int: how many targets took damage",
			"profile": "AttackProfile: the attack that landed (name, color, reach)",
		},
	},
	SKILL_COOLDOWN: {
		"status": STATUS_EMITTED,
		"about": "The skill's cooldown changed; sent every tick while it counts down.",
		"payload": {
			"entity": "int: the player entity",
			"time_left": "float: seconds until the skill is ready again, 0.0 when it is ready",
		},
	},
}

# ------------------------------------------------------------------- enemies (EnemyAISystem)
const INTENT_CHANGED := &"intent_changed"
const TELEGRAPH_STARTED := &"telegraph_started"
const TELEGRAPH_FINISHED := &"telegraph_finished"
const ATTACK_RESOLVED := &"attack_resolved"
const PICKUP_TAKEN := &"pickup_taken"
const WEAPON_CHANGED := &"weapon_changed"

const ENEMY_EVENTS: Dictionary = {
	INTENT_CHANGED: {
		"status": STATUS_EMITTED,
		"about": "An enemy decided what to do next; the debug overlay draws the choice.",
		"payload": {
			"entity": "int: the deciding enemy",
			"intent": "EnemyIntent: the winning choice (type, target cells or destination, score)",
		},
	},
	TELEGRAPH_STARTED: {
		"status": STATUS_EMITTED,
		"about": "An enemy committed to a strike: its cells are locked and shown as a warning.",
		"payload": {
			"entity": "int: the enemy that will strike",
			"cells": "Array[Vector2i]: the locked cells; standing in one at resolve time is a hit",
		},
	},
	TELEGRAPH_FINISHED: {
		"status": STATUS_EMITTED,
		"about": "The warning ended and the strike resolves this tick.",
		"payload": {
			"entity": "int: the enemy whose warning ended",
		},
	},
	ATTACK_RESOLVED: {
		"status": STATUS_EMITTED,
		"about": "An enemy's strike resolved on its locked cells (damage, if any, is queued separately).",
		"payload": {
			"entity": "int: the striking enemy",
			"cells": "Array[Vector2i]: the cells that were struck",
		},
	},
	PICKUP_TAKEN: {
		"status": STATUS_EMITTED,
		"about": "An enemy picked a floor weapon up; the pickup entity is gone.",
		"payload": {
			"item": "int: the pickup's entity id (already destroyed; the shell uses it to find its view and marker)",
			"cell": "Vector2i: the cell it lay on",
		},
	},
	WEAPON_CHANGED: {
		"status": STATUS_EMITTED,
		"about": "An enemy now holds a different weapon, so its attack shape changed.",
		"payload": {
			"entity": "int: the enemy that took the weapon",
			"weapon": "EnemyWeapon: the weapon it now holds",
		},
	},
}

# ------------------------------------------------------------------- health (HealthSystem)
const DAMAGED := &"damaged"
const DEFEATED := &"defeated"
const HEALED := &"healed"

const HEALTH_EVENTS: Dictionary = {
	DAMAGED: {
		"status": STATUS_EMITTED,
		"about": "An entity lost courage. Not sent for a hit absorbed by the invulnerability window.",
		"payload": {
			"entity": "int: the entity that was hurt",
			"amount": "int: points of damage dealt",
			"remaining": "int: its health after the hit",
			"direction": "Vector2i: the way the blow travelled, ZERO when it has none",
			"source": "int: the attacking entity, 0 when nothing caused it (the death frame names the cause, R8)",
			"tags": "Array[StringName]: what kind of attack it was (the attack's own tags; empty when it has none)",
		},
	},
	DEFEATED: {
		"status": STATUS_EMITTED,
		"about": "An entity's health reached zero. Right after the `damaged` event of the blow that did it.",
		"payload": {
			"entity": "int: the entity that fell",
			"source": "int: the entity whose blow did it, 0 when nothing caused it (R14 checks it is the player)",
			"tags": "Array[StringName]: the killing attack's tags",
		},
	},
	HEALED: {"status": STATUS_FUTURE, "about": "M3a (heal queue): an entity regained courage.", "payload": {}},

}

# ------------------------------------------------------------------- world seams (M3a)
const FLAG_SET := &"flag_set"
const COMMAND_REJECTED := &"command_rejected"

const SEAM_EVENTS: Dictionary = {
	FLAG_SET: {"status": STATUS_FUTURE, "about": "M3a (commands): a world flag changed value.", "payload": {}},
	COMMAND_REJECTED: {"status": STATUS_FUTURE, "about": "M3a (commands): a request on world.commands could not be applied and was dropped.", "payload": {}},
}

# ------------------------------------------------------------------- attack stages (M8a)
const ATTACK_PROGRESS := &"attack_progress"

const ATTACK_EVENTS: Dictionary = {
	ATTACK_PROGRESS: {
		"status": STATUS_FUTURE,
		"about": "M8a: an attack moved through its stage (declare, telegraph, active, recover); plan 5.10 names entity, stage, progress, cells.",
		"payload": {},
	},
}

# ------------------------------------------------------------------- skills and progression (M7)
const SKILL_CAST_STARTED := &"skill_cast_started"
const SKILL_UNLOCKED := &"skill_unlocked"
const BELIEVE_CHANGED := &"believe_changed"
const PAGE_EQUIPPED := &"page_equipped"
const RANK_CHANGED := &"rank_changed"
const MILESTONE_REACHED := &"milestone_reached"
const GUARD_BLOCKED := &"guard_blocked"
const PERFECT_RUB := &"perfect_rub"

const SKILL_EVENTS: Dictionary = {
	SKILL_CAST_STARTED: {"status": STATUS_FUTURE, "about": "M7a: a skill began its cast; ViewSyncSystem travels the actor's graph to the skill's state.", "payload": {}},
	SKILL_UNLOCKED: {"status": STATUS_FUTURE, "about": "M7a: the player gained a verb.", "payload": {}},
	BELIEVE_CHANGED: {"status": STATUS_FUTURE, "about": "M7a: the child's Believe resource changed.", "payload": {}},
	PAGE_EQUIPPED: {"status": STATUS_FUTURE, "about": "M7c: a Book page was equipped or removed.", "payload": {}},
	RANK_CHANGED: {"status": STATUS_FUTURE, "about": "M7c: the Rank label (a story tally nothing reads) changed.", "payload": {}},
	MILESTONE_REACHED: {"status": STATUS_FUTURE, "about": "M7c: a progression milestone fired.", "payload": {}},
	GUARD_BLOCKED: {"status": STATUS_FUTURE, "about": "M11: Eraser Guard negated a hit.", "payload": {}},
	PERFECT_RUB: {"status": STATUS_FUTURE, "about": "M11: a guard raised just in time put the attacker In Check.", "payload": {}},
}

# ------------------------------------------------------------------- story (M6)
const STORY_TRIGGER := &"story_trigger"

const STORY_EVENTS: Dictionary = {
	STORY_TRIGGER: {"status": STATUS_FUTURE, "about": "M6: a trigger or flag condition fired a story beat (plan 8.1: beat_id).", "payload": {}},
}

# ------------------------------------------------------------------- bosses (M8b)
const BOSS_ENGAGED := &"boss_engaged"
const BOSS_PHASE_CHANGED := &"boss_phase_changed"
const BOSS_DEFEATED := &"boss_defeated"
const KNOCKED_BACK := &"knocked_back"

const BOSS_EVENTS: Dictionary = {
	BOSS_ENGAGED: {"status": STATUS_FUTURE, "about": "M8b: the player entered a boss fight.", "payload": {}},
	BOSS_PHASE_CHANGED: {"status": STATUS_FUTURE, "about": "M8b: a boss moved to its next phase.", "payload": {}},
	BOSS_DEFEATED: {"status": STATUS_FUTURE, "about": "M8b: a boss fell for good.", "payload": {}},
	KNOCKED_BACK: {"status": STATUS_FUTURE, "about": "M8c: KnockbackSystem shoved an entity.", "payload": {}},
}

# ------------------------------------------------------------------- the child and cell effects (M10)
const CELL_EFFECT_STARTED := &"cell_effect_started"
const CELL_EFFECT_ENDED := &"cell_effect_ended"
const CHILD_INTERVENED := &"child_intervened"
const CHILD_HELP_DISRUPTED := &"child_help_disrupted"

const CHILD_EVENTS: Dictionary = {
	CELL_EFFECT_STARTED: {"status": STATUS_FUTURE, "about": "M10: a cell effect (chalk, corruption) appeared.", "payload": {}},
	CELL_EFFECT_ENDED: {"status": STATUS_FUTURE, "about": "M10: a cell effect ended or was erased.", "payload": {}},
	CHILD_INTERVENED: {"status": STATUS_FUTURE, "about": "M10: the child's hand helped.", "payload": {}},
	CHILD_HELP_DISRUPTED: {"status": STATUS_FUTURE, "about": "M10: a boss rule stopped the child's help.", "payload": {}},
}

# ------------------------------------------------------------------- flow, checkpoints and the ending (M3b, M11, M13)
const CHECKPOINT_SET := &"checkpoint_set"
const ROOM_CLEARED := &"room_cleared"
const RESPAWN_REQUESTED := &"respawn_requested"
const RESCUE_COMPLETED := &"rescue_completed"
const DIRECTION_LOCKED := &"direction_locked"
const DIRECTION_RESTORED := &"direction_restored"
const ENDING_REACHED := &"ending_reached"

const FLOW_EVENTS: Dictionary = {
	CHECKPOINT_SET: {"status": STATUS_FUTURE, "about": "M3b: the player reached a checkpoint.", "payload": {}},
	ROOM_CLEARED: {"status": STATUS_FUTURE, "about": "M3b: ObjectiveSystem judged the room's objective complete.", "payload": {}},
	RESPAWN_REQUESTED: {"status": STATUS_FUTURE, "about": "M3b: the player fell; GameFlow rebuilds the zone at the checkpoint.", "payload": {}},
	RESCUE_COMPLETED: {"status": STATUS_FUTURE, "about": "M11: a held interaction freed a captive piece.", "payload": {}},
	DIRECTION_LOCKED: {"status": STATUS_FUTURE, "about": "M13: Act 6 locked one of the pawn's directions.", "payload": {}},
	DIRECTION_RESTORED: {"status": STATUS_FUTURE, "about": "M13: a locked direction came back.", "payload": {}},
	ENDING_REACHED: {"status": STATUS_FUTURE, "about": "M13: the player reached the ending.", "payload": {}},
}

## What a damage request carries (Events.emit_damage builds it, HealthSystem consumes it).
const DAMAGE_REQUEST_KEYS: Array[String] = ["target", "source", "amount", "direction", "tags"]

## event type (StringName) -> its declaration ({status, about, payload}); built once from the banners.
static var _declaration_by_type: Dictionary = {}


## The declaration of every event, merged from the banner tables: event type -> {status, about, payload}.
static func declaration_by_type() -> Dictionary:
	if _declaration_by_type.is_empty():
		for banner: Dictionary in [
			MOVEMENT_EVENTS, COMBAT_EVENTS, ENEMY_EVENTS, HEALTH_EVENTS, SEAM_EVENTS,
			ATTACK_EVENTS, SKILL_EVENTS, STORY_EVENTS, BOSS_EVENTS, CHILD_EVENTS, FLOW_EVENTS,
		]:
			_declaration_by_type.merge(banner)
	return _declaration_by_type


static func is_declared(event_type: StringName) -> bool:
	return declaration_by_type().has(event_type)


## Every declared event type whose status is `status` (STATUS_EMITTED or STATUS_FUTURE), sorted by name.
static func types_with_status(status: StringName) -> Array[StringName]:
	var found: Array[StringName] = []
	for event_type: StringName in declaration_by_type():
		if declaration_by_type()[event_type]["status"] == status:
			found.append(event_type)
	found.sort_custom(func(first: StringName, second: StringName) -> bool: return String(first) < String(second))
	return found


## Why this event does not match its declaration, in words; "" when it does. Checked for every
## event by EcsWorld.emit_event() in debug builds.
static func problem_with(event: Dictionary) -> String:
	if not event.has("type") or not (event["type"] is StringName):
		return "an event needs a StringName under \"type\": %s" % str(event)
	var event_type: StringName = event["type"]
	var declaration: Dictionary = declaration_by_type().get(event_type, {})
	if declaration.is_empty():
		return "event '%s' is not declared in ecs/events/events.gd" % event_type
	if declaration["status"] != STATUS_EMITTED:
		return "event '%s' is declared FUTURE; flip it to EMITTED and write its payload in ecs/events/events.gd when you start emitting it" % event_type
	var payload_docs: Dictionary = declaration["payload"]
	for key: String in payload_docs:
		if not event.has(key):
			return "event '%s' is missing the documented key '%s'" % [event_type, key]
	for key: Variant in event:
		if key != "type" and not payload_docs.has(key):
			return "event '%s' carries the undocumented key '%s'; document it in ecs/events/events.gd" % [event_type, key]
	return ""


## Queues a damage request on the world; HealthSystem applies it the same tick. The ONLY way to
## write the queue: no producer builds the dictionary by hand, so the payload cannot drift (plan
## 14.3). `source` is the attacking entity (0 when nothing caused it: a hazard, a test) and `tags`
## say what kind of attack it was; both travel on into the `damaged` and `defeated` events.
static func emit_damage(world: EcsWorld, target: int, amount: int, direction: Vector2i, source: int, tags: Array[StringName] = []) -> void:
	world.damage_events.append({
		"target": target,
		"source": source,
		"amount": amount,
		"direction": direction,
		"tags": tags.duplicate(),
	})
