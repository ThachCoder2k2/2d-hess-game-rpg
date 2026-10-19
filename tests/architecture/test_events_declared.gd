extends UnboundTest

## Architecture guard (docs/game-base-plan.md 14.3 and 15 M3a): every event the simulation emits is
## declared in ecs/events/events.gd with its payload keys documented, and every event declared as
## EMITTED really is emitted somewhere. Presentation reads events by name and key, so an
## undeclared event or an undocumented key is a contract nobody can read.
##
## "Emitted" is found by reading the code, the way the plan's lint does: every
## `"type": Events.SOME_NAME` or `"type": &"some_name"` inside `emit_event({...})` in ecs/, authoring/,
## presentation/ and shell/; and no producer there queues damage or a heal except through Events.emit_damage
## and Events.emit_heal.
## The runtime half is EcsWorld.emit_event(), which asserts the same
## thing about the event it is handed (declared, status EMITTED, exactly the documented keys),
## so a producer that builds an event some other way is stopped by the first test that runs it.

const ProjectFiles := preload("res://tests/architecture/project_files.gd")

## The 19 event types the plan counted in the code when M3a began (14.3). They never go away.
const EVENT_TYPES_BEFORE_M3A: Array[StringName] = [
	&"step_started", &"step_finished", &"step_blocked", &"intent_changed", &"attack_started",
	&"attack_locked", &"attack_landed", &"attack_resolved", &"telegraph_started", &"telegraph_finished",
	&"damaged", &"defeated", &"pickup_taken", &"weapon_changed", &"skill_cooldown", &"player_unlock",
	&"gate_opened", &"zone_exit", &"zone_exit_locked",
]
## The plan's list of events later milestones add (14.3 "New"), reserved so the names cannot collide.
const PLANNED_NEW_EVENT_TYPES: Array[StringName] = [
	&"attack_progress", &"skill_cast_started", &"skill_unlocked", &"believe_changed", &"page_equipped",
	&"rank_changed", &"milestone_reached", &"story_trigger", &"flag_set", &"boss_engaged",
	&"boss_phase_changed", &"boss_defeated", &"cell_effect_started", &"cell_effect_ended",
	&"child_intervened", &"child_help_disrupted", &"direction_locked", &"direction_restored", &"healed",
	&"knocked_back", &"rescue_completed", &"checkpoint_set", &"room_cleared", &"perfect_rub",
	&"guard_blocked", &"respawn_requested", &"ending_reached",
]
## A scan that finds fewer source files than this walked the wrong folders.
const MINIMUM_SOURCE_FILES := 20

var emitted_type_by_source: Dictionary = {}


func _init() -> void:
	suite_title = "EVENTS DECLARED TEST"
	var paths := TestPaths.new(self)
	var declaration_by_type := Events.declaration_by_type()

	# --- The declarations themselves ---
	for event_type in EVENT_TYPES_BEFORE_M3A:
		_expect(declaration_by_type.has(event_type) and declaration_by_type[event_type]["status"] == Events.STATUS_EMITTED, "the existing event '%s' is declared and emitted" % event_type)
	var undeclared_planned: Array[String] = []
	for event_type in PLANNED_NEW_EVENT_TYPES:
		if not declaration_by_type.has(event_type):
			undeclared_planned.append(String(event_type))
	_expect(undeclared_planned.is_empty(), "all %d events the plan adds later are declared, emitted or reserved (missing: %s)" % [PLANNED_NEW_EVENT_TYPES.size(), ", ".join(PackedStringArray(undeclared_planned))])
	_expect(EVENT_TYPES_BEFORE_M3A.size() == 19, "the plan counted 19 existing event types")

	var banner_entry_count := 0
	for banner: Dictionary in [Events.MOVEMENT_EVENTS, Events.COMBAT_EVENTS, Events.ENEMY_EVENTS, Events.HEALTH_EVENTS, Events.SEAM_EVENTS, Events.ATTACK_EVENTS, Events.SKILL_EVENTS, Events.STORY_EVENTS, Events.BOSS_EVENTS, Events.CHILD_EVENTS, Events.FLOW_EVENTS]:
		banner_entry_count += banner.size()
	_expect(banner_entry_count == declaration_by_type.size(), "no event is declared in two banners (%d entries, %d distinct)" % [banner_entry_count, declaration_by_type.size()])

	var every_declaration_is_complete := true
	for event_type: StringName in declaration_by_type:
		var declaration: Dictionary = declaration_by_type[event_type]
		var is_complete: bool = String(declaration.get("about", "")).length() > 10 and declaration.get("status") in [Events.STATUS_EMITTED, Events.STATUS_FUTURE]
		var payload: Dictionary = declaration.get("payload", {})
		if declaration.get("status") == Events.STATUS_EMITTED:
			is_complete = is_complete and not payload.is_empty()
		for key: String in payload:
			is_complete = is_complete and String(payload[key]).length() > 5
		if not is_complete:
			every_declaration_is_complete = false
			printerr("  event '%s' has no `about`, a bad status, an EMITTED event with no payload, or a payload key with no description" % event_type)
	_expect(every_declaration_is_complete, "every event says what happened, and every EMITTED event documents each payload key")

	# --- What the code emits ---
	var constant_map := (Events as GDScript).get_script_constant_map()
	var emit_by_constant := RegEx.new()
	emit_by_constant.compile("\"type\"\\s*:\\s*Events\\.([A-Z][A-Z0-9_]*)")
	var emit_by_literal := RegEx.new()
	emit_by_literal.compile("\"type\"\\s*:\\s*&\"([a-z][a-z0-9_]*)\"")
	var events_path := paths.events_script()
	var source_count := 0
	var emitted_types: Dictionary = {}
	var emitted_sources: Dictionary = {}
	var hand_built_damage_files: Array[String] = []
	for directory in paths.event_producer_directories():
		for script_path in ProjectFiles.collect_files(["gd"], directory):
			if script_path == events_path:
				continue
			source_count += 1
			var text := ProjectFiles.read_text(script_path)
			if text.contains("damage_events.append") or text.contains("heal_events.append"):
				hand_built_damage_files.append(script_path)
			for emit_match in emit_by_constant.search_all(text):
				var constant_name := emit_match.get_string(1)
				if not constant_map.has(constant_name):
					_expect(false, "%s emits Events.%s, which does not exist" % [script_path, constant_name])
					continue
				emitted_types[constant_map[constant_name]] = true
				emitted_sources[constant_map[constant_name]] = script_path
			for emit_match in emit_by_literal.search_all(text):
				emitted_types[StringName(emit_match.get_string(1))] = true
				emitted_sources[StringName(emit_match.get_string(1))] = script_path
	_expect(source_count >= MINIMUM_SOURCE_FILES, "the scan read %d source files (at least %d)" % [source_count, MINIMUM_SOURCE_FILES])
	_expect(not emitted_types.is_empty(), "the scan found %d emitted event types" % emitted_types.size())

	var undeclared: Array[String] = []
	for event_type: StringName in emitted_types:
		if not Events.is_declared(event_type):
			undeclared.append("%s (in %s)" % [event_type, emitted_sources[event_type]])
	_expect(undeclared.is_empty(), "every event the code emits is declared in events.gd (undeclared: %s)" % ", ".join(PackedStringArray(undeclared)))

	var declared_but_silent: Array[String] = []
	for event_type in Events.types_with_status(Events.STATUS_EMITTED):
		if not emitted_types.has(event_type):
			declared_but_silent.append(String(event_type))
	_expect(declared_but_silent.is_empty(), "every event declared EMITTED is emitted somewhere (silent: %s)" % ", ".join(PackedStringArray(declared_but_silent)))

	var future_but_emitted: Array[String] = []
	for event_type in Events.types_with_status(Events.STATUS_FUTURE):
		if emitted_types.has(event_type):
			future_but_emitted.append(String(event_type))
	_expect(future_but_emitted.is_empty(), "no event declared FUTURE is emitted: its status flips when its emitter lands (emitted: %s)" % ", ".join(PackedStringArray(future_but_emitted)))

	_expect(hand_built_damage_files.is_empty(), "no producer builds a damage or heal request by hand: they call Events.emit_damage and Events.emit_heal (hand-built in: %s)" % ", ".join(PackedStringArray(hand_built_damage_files)))

	# --- problem_with() must be able to say no ---
	_expect(Events.problem_with({"type": Events.STEP_STARTED, "entity": 1, "cell": Vector2i.ZERO}).is_empty(), "a correct event has no problem")
	_expect(Events.problem_with({"entity": 1}).contains("needs a StringName"), "an event with no type is refused")
	_expect(Events.problem_with({"type": "step_started", "entity": 1, "cell": Vector2i.ZERO}).contains("needs a StringName"), "an event whose type is a plain String is refused")
	_expect(Events.problem_with({"type": &"not_an_event"}).contains("not declared"), "an undeclared event is refused")
	_expect(Events.problem_with({"type": Events.STEP_STARTED, "entity": 1}).contains("missing the documented key 'cell'"), "an event missing a documented key is refused")
	_expect(Events.problem_with({"type": Events.STEP_STARTED, "entity": 1, "cell": Vector2i.ZERO, "extra": 1}).contains("undocumented key 'extra'"), "an event with an undocumented key is refused")
	_expect(Events.problem_with({"type": Events.BOSS_DEFEATED}).contains("FUTURE"), "an event reserved for a later milestone is refused until its status is flipped")

	finish()
