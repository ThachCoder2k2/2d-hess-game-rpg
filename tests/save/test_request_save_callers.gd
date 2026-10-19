extends UnboundTest

## R17 (docs/game-base-plan.md 3.5, 5.2): autosave only on success events, never mid-fight, never on a death.
## The plan's verification is "the list of SaveService.request_save callers". This suite is that list:
##   - the service accepts exactly the success events of AUTOSAVE_REASONS and refuses everything else
##     (a death, a hit, a quit, a timer), writing nothing;
##   - the sources call request_save() in exactly the places EXPECTED_CALLERS names, each with a literal
##     reason that is one of those events. A new caller, a new reason at an old caller, or a reason computed
##     at run time fails here until this list is changed on purpose, which is the review R17 asks for.
## Tests and tools are not sources.

const ProjectFiles := preload("res://tests/architecture/project_files.gd")
const SaveSupport := preload("res://tests/support/save_test_support.gd")
const SaveServiceScript := preload("res://shell/save/save_service.gd")

## source file -> the reasons it may pass, exactly. Each is the success event the code sits on. Since M3b
## step 2 one bridge is the only asker (shell/bridges/save_bridge.gd, "the save requests"):
##   room_cleared        a room's objective was met (the room_cleared event, D-17)
##   pickup_taken        a PERSISTENT pickup was taken (the pickup_taken event; a floor weapon is room-local
##                       and never asks, D-16)
##   shortcut_opened     a one-way gate was unbarred (the gate_opened event)
##   unlock_gained       a verb was unlocked (the player_unlock event)
##   rule_page_unlocked  a piece was met for the first time and its Book page written
##   checkpoint_reached  the pawn came through the door of a hub or a boss room (the checkpoint_set event, D-16)
const EXPECTED_CALLERS := {
	"res://shell/bridges/save_bridge.gd": [&"checkpoint_reached", &"pickup_taken", &"room_cleared", &"rule_page_unlocked", &"shortcut_opened", &"unlock_gained"],
}

## The success events docs/game-base-plan.md 5.2 lists for autosave, each with the reason that carries it.
const PLAN_EVENT_REASONS := {
	"room clear": &"room_cleared",
	"shortcut opened": &"shortcut_opened",
	"persistent pickup": &"pickup_taken",
	"boss defeat": &"boss_defeated",
	"rescue": &"rescue_completed",
	"hub entry (a checkpoint)": &"checkpoint_reached",
	"beat flagged save_after": &"beat_save_after",
}

## Reasons that are NOT success events. The service must refuse every one.
const REFUSED_REASONS: Array[StringName] = [
	&"player_defeated", &"death", &"defeated", &"damaged", &"quit", &"timer", &"periodic", &"mid_fight", &"pickup", &"",
]
## A word in an accepted reason that would mean a failure or a danger.
const FORBIDDEN_WORDS: Array[String] = ["player_defeated", "death", "died", "fail", "damage", "quit", "timer", "periodic", "fight", "combat", "pause"]

## Fewer source files than this means the walk is broken, not clean.
const MINIMUM_SOURCE_FILES := 20

var roots_to_remove: Array[String] = []
var autosaved_reasons: Array[StringName] = []


func _init() -> void:
	suite_title = "REQUEST SAVE CALLERS TEST"
	_check_the_accepted_reasons()
	_check_the_service_refuses_everything_else()
	_check_the_callers_in_the_sources()
	_check_the_scan_can_fail()
	for root_directory in roots_to_remove:
		SaveSupport.remove_root(root_directory)
	finish()


func _check_the_accepted_reasons() -> void:
	var accepted: Array[StringName] = SaveServiceScript.AUTOSAVE_REASONS
	var plan_reasons: Array = PLAN_EVENT_REASONS.values()
	var every_plan_event_has_a_reason := true
	for plan_event: String in PLAN_EVENT_REASONS:
		every_plan_event_has_a_reason = every_plan_event_has_a_reason and PLAN_EVENT_REASONS[plan_event] in accepted
	_expect(every_plan_event_has_a_reason, "every success event the plan lists for autosave has a reason (room clear, shortcut, pickup, boss, rescue, hub entry, save_after)")
	var extra_reasons: Array[String] = []
	for reason in accepted:
		if reason not in plan_reasons:
			extra_reasons.append(String(reason))
	extra_reasons.sort()
	_expect(extra_reasons == ["rule_page_unlocked", "unlock_gained"], "the only reasons beyond the plan's list are the two unlocks (a skill, a Book page), both persistent progress: %s" % [extra_reasons])
	var words_found: Array[String] = []
	for reason in accepted:
		var reason_text := String(reason)
		_expect(reason_text == reason_text.to_snake_case() and not reason_text.is_empty(), "reason '%s' is a lower_snake_case name" % reason_text)
		for forbidden_word in FORBIDDEN_WORDS:
			if reason_text.contains(forbidden_word):
				words_found.append("%s (%s)" % [reason_text, forbidden_word])
	_expect(words_found.is_empty(), "no accepted reason names a death, a hit, a quit or a fight: %s" % ", ".join(words_found))
	_expect(accepted.size() == 9, "nine reasons exist (adding one is a review: change this count with the list above)")


func _check_the_service_refuses_everything_else() -> void:
	var root_directory := SaveSupport.make_root("callers")
	roots_to_remove.append(root_directory)
	var service := SaveSupport.new_service(root_directory)
	service.autosaved.connect(func(_slot: int, reason: StringName) -> void: autosaved_reasons.append(reason))
	service.new_game(0)
	var slot_file: String = service.slot_path(0)
	for refused in REFUSED_REASONS:
		_expect(not service.request_save(refused) and not FileAccess.file_exists(slot_file), "'%s' is not a success event: refused, nothing written" % refused)
	_expect(autosaved_reasons.is_empty(), "and none of them said it saved")
	for accepted_reason in SaveServiceScript.AUTOSAVE_REASONS:
		DirAccess.remove_absolute(slot_file)
		_expect(service.request_save(accepted_reason) and FileAccess.file_exists(slot_file), "'%s' writes the run" % accepted_reason)
	_expect(autosaved_reasons == SaveServiceScript.AUTOSAVE_REASONS, "each accepted reason said so through autosaved, in order")


func _check_the_callers_in_the_sources() -> void:
	var found := _callers_in_sources()
	_expect(found["source_count"] >= MINIMUM_SOURCE_FILES, "the walk found %d source scripts (at least %d)" % [found["source_count"], MINIMUM_SOURCE_FILES])
	var caller_files: Array = found["reasons_by_file"].keys()
	caller_files.sort()
	var expected_files: Array = EXPECTED_CALLERS.keys()
	expected_files.sort()
	_expect(caller_files == expected_files, "the files that call request_save are %s (found: %s)" % [expected_files, caller_files])
	_expect(found["non_literal_calls"].is_empty(), "every call passes its reason as a literal, so it can be read off the source (found a computed one: %s)" % ", ".join(PackedStringArray(found["non_literal_calls"])))
	for file_path: String in EXPECTED_CALLERS:
		var used: Array[String] = _sorted_names(found["reasons_by_file"].get(file_path, []))
		var allowed: Array[String] = _sorted_names(EXPECTED_CALLERS[file_path])
		_expect(used == allowed, "%s asks for a save for %s and nothing else (found: %s)" % [file_path.get_file(), allowed, used])
		var all_are_success_events := true
		for reason: StringName in used:
			all_are_success_events = all_are_success_events and reason in SaveServiceScript.AUTOSAVE_REASONS
		_expect(all_are_success_events, "%s only asks for success events" % file_path.get_file())


## The names as Strings in alphabetical order (a StringName array sorts by address, not by letters).
func _sorted_names(names: Array) -> Array[String]:
	var sorted_names: Array[String] = []
	for name_entry: Variant in names:
		sorted_names.append(String(name_entry))
	sorted_names.sort()
	return sorted_names


## The calls to request_save in the game's sources: { "source_count": int, "reasons_by_file": file ->
## Array of reasons passed as literals, "non_literal_calls": Array of "file: argument text" }.
func _callers_in_sources() -> Dictionary:
	var comment_regex := RegEx.create_from_string("#[^\\n]*")
	var triple_quoted_regex := RegEx.create_from_string("\"\"\"[\\s\\S]*?\"\"\"")
	var definition_regex := RegEx.create_from_string("(?m)^\\s*func\\s+\\w*request_save\\b[^\\n]*")
	var call_regex := RegEx.create_from_string("\\w*request_save\\s*\\(([^)]*)\\)")
	var literal_regex := RegEx.create_from_string("^&\"([a-z_]+)\"$")
	var reasons_by_file: Dictionary = {}
	var non_literal_calls: Array[String] = []
	var source_count := 0
	for script_path in ProjectFiles.collect_files(["gd"]):
		if script_path.begins_with("res://tests/") or script_path.begins_with("res://tools/"):
			continue
		source_count += 1
		var code := ProjectFiles.read_text(script_path)
		code = triple_quoted_regex.sub(code, "", true)
		code = comment_regex.sub(code, "", true)
		code = definition_regex.sub(code, "", true)
		for call_match in call_regex.search_all(code):
			var argument := call_match.get_string(1).strip_edges()
			var literal_match := literal_regex.search(argument)
			if literal_match == null:
				non_literal_calls.append("%s: request_save(%s)" % [script_path.get_file(), argument])
				continue
			if not reasons_by_file.has(script_path):
				reasons_by_file[script_path] = []
			if StringName(literal_match.get_string(1)) not in reasons_by_file[script_path]:
				reasons_by_file[script_path].append(StringName(literal_match.get_string(1)))
	return {"source_count": source_count, "reasons_by_file": reasons_by_file, "non_literal_calls": non_literal_calls}


## The lint must be able to fail: the same patterns on code that calls it wrongly.
func _check_the_scan_can_fail() -> void:
	var call_regex := RegEx.create_from_string("\\w*request_save\\s*\\(([^)]*)\\)")
	var literal_regex := RegEx.create_from_string("^&\"([a-z_]+)\"$")
	var sample := "save.request_save(&\"pickup_taken\")\n_request_save(reason)\nservice.request_save( &\"player_defeated\" )\n"
	var arguments: Array[String] = []
	for call_match in call_regex.search_all(sample):
		arguments.append(call_match.get_string(1).strip_edges())
	_expect(arguments == ["&\"pickup_taken\"", "reason", "&\"player_defeated\""], "the pattern finds a plain call, a wrapper call and a spaced call")
	_expect(literal_regex.search(arguments[0]) != null and literal_regex.search(arguments[1]) == null, "and tells a literal reason from a computed one")
	_expect(StringName(literal_regex.search(arguments[2]).get_string(1)) not in SaveServiceScript.AUTOSAVE_REASONS, "so a call for a death would be caught by the reasons check")
