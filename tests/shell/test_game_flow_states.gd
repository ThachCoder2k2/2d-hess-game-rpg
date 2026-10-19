extends UnboundTest

## The GameFlow state machine (docs/game-base-plan.md 9.1, M4): boot -> title -> New Game / Continue -> game ->
## pause -> ending -> credits -> title, with Quit to Title from the game and Credits replayed from the title.
## Driven with no scene and no save: it is a plain object. Every request is checked against the table, a refused
## request changes nothing and says nothing, and the table itself is complete. (The rebuild of a room, the one
## request that needs a scene, is pinned by tests/bridge/test_game_flow.gd; the screens that follow the states
## by test_app_flow.gd; New Game and Continue against a real save by test_new_game_resets_slot and
## test_continue_loads_checkpoint.)

const SaveSupport := preload("res://tests/support/save_test_support.gd")

var changes: Array[String] = []


func _init() -> void:
	suite_title = "GAME FLOW STATES TEST"
	_the_table_is_complete()
	_the_happy_path()
	_every_request_is_legal_only_where_the_table_says()
	_quit_to_title_from_everywhere_in_the_game()
	_the_ending_marks_the_game_completed()
	_with_no_room_a_rebuild_request_is_ignored()
	finish()


func _flow_in(target: GameFlow.State) -> GameFlow:
	var flow := GameFlow.new()
	match target:
		GameFlow.State.BOOT:
			pass
		GameFlow.State.TITLE:
			flow.finish_boot()
		GameFlow.State.PLAYING:
			flow.finish_boot()
			flow.start_new_game()
		GameFlow.State.PAUSED:
			flow.finish_boot()
			flow.start_new_game()
			flow.request_pause()
		GameFlow.State.ENDING:
			flow.finish_boot()
			flow.start_new_game()
			flow.reach_ending()
		GameFlow.State.CREDITS:
			flow.finish_boot()
			flow.show_credits()
	return flow


func _the_table_is_complete() -> void:
	var states: Array = GameFlow.State.values()
	_expect(GameFlow.NEXT_STATES.size() == states.size(), "the table has a row for every state (%d)" % states.size())
	var every_target_is_a_state := true
	for row_state: GameFlow.State in GameFlow.NEXT_STATES:
		for next_state: GameFlow.State in GameFlow.NEXT_STATES[row_state]:
			every_target_is_a_state = every_target_is_a_state and next_state in states
	_expect(every_target_is_a_state, "and every state a row leads to exists")
	_expect(GameFlow.new().state == GameFlow.State.BOOT, "a flow starts in BOOT")
	_expect(GameFlow.new(GameFlow.State.PLAYING).state == GameFlow.State.PLAYING, "and the in-game scene makes its own flow already PLAYING")
	var nothing_leads_to_boot := true
	for row_state: GameFlow.State in GameFlow.NEXT_STATES:
		nothing_leads_to_boot = nothing_leads_to_boot and GameFlow.State.BOOT not in GameFlow.NEXT_STATES[row_state]
	_expect(nothing_leads_to_boot, "nothing leads back to BOOT")


func _the_happy_path() -> void:
	var flow := GameFlow.new()
	flow.state_changed.connect(func(previous: GameFlow.State, current: GameFlow.State) -> void:
		changes.append("%s>%s" % [GameFlow.State.keys()[previous], GameFlow.State.keys()[current]]))
	_expect(flow.finish_boot() and flow.state == GameFlow.State.TITLE, "boot opens the title")
	_expect(flow.start_new_game() and flow.state == GameFlow.State.PLAYING and flow.is_in_game(), "New Game starts playing")
	_expect(flow.request_pause() and flow.state == GameFlow.State.PAUSED and flow.is_in_game(), "a pause pauses")
	_expect(flow.request_resume() and flow.state == GameFlow.State.PLAYING, "and resumes")
	_expect(flow.reach_ending() and flow.state == GameFlow.State.ENDING, "the ending is reached from the game")
	_expect(flow.finish_ending() and flow.state == GameFlow.State.CREDITS and not flow.is_in_game(), "the credits follow the ending")
	_expect(flow.finish_credits() and flow.state == GameFlow.State.TITLE, "and the title follows the credits")
	_expect(flow.show_credits() and flow.state == GameFlow.State.CREDITS, "the credits can be replayed from the title")
	_expect(flow.finish_credits() and flow.state == GameFlow.State.TITLE, "and end at the title again")
	_expect(changes == ["BOOT>TITLE", "TITLE>PLAYING", "PLAYING>PAUSED", "PAUSED>PLAYING", "PLAYING>ENDING", "ENDING>CREDITS", "CREDITS>TITLE", "TITLE>CREDITS", "CREDITS>TITLE"], "every change was announced once, in order (%s)" % ", ".join(PackedStringArray(changes)))


## Each request, tried in every state: accepted exactly in the states the table and the request's own rule allow.
func _every_request_is_legal_only_where_the_table_says() -> void:
	# request name -> the states it is accepted in (the table's rows, restated per request so a mistake in either shows).
	var accepted_in := {
		&"finish_boot": [GameFlow.State.BOOT],
		&"start_new_game": [GameFlow.State.TITLE],
		&"continue_game": [GameFlow.State.TITLE],
		&"request_pause": [GameFlow.State.PLAYING],
		&"request_resume": [GameFlow.State.PAUSED],
		&"quit_to_title": [GameFlow.State.PLAYING, GameFlow.State.PAUSED, GameFlow.State.ENDING],
		&"reach_ending": [GameFlow.State.PLAYING],
		&"finish_ending": [GameFlow.State.ENDING],
		&"show_credits": [GameFlow.State.TITLE],
		&"finish_credits": [GameFlow.State.CREDITS],
	}
	var all_states: Array[GameFlow.State] = [GameFlow.State.BOOT, GameFlow.State.TITLE, GameFlow.State.PLAYING, GameFlow.State.PAUSED, GameFlow.State.ENDING, GameFlow.State.CREDITS]
	var wrong: Array[String] = []
	var refusals_that_changed_something := 0
	for request: StringName in accepted_in:
		for state in all_states:
			var flow := _flow_in(state)
			var heard := [0]
			flow.state_changed.connect(func(_previous: GameFlow.State, _current: GameFlow.State) -> void: heard[0] += 1)
			var accepted: bool = flow.call(request)
			var should_accept: bool = state in accepted_in[request]
			if accepted != should_accept:
				wrong.append("%s in %s: %s" % [request, GameFlow.State.keys()[state], "accepted" if accepted else "refused"])
			if not accepted and (flow.state != state or heard[0] != 0):
				refusals_that_changed_something += 1
	_expect(wrong.is_empty(), "each request is accepted in exactly the states it should be (wrong: %s)" % "; ".join(PackedStringArray(wrong)))
	_expect(refusals_that_changed_something == 0, "a refused request changes nothing and says nothing")
	var respawn_flow := _flow_in(GameFlow.State.TITLE)
	respawn_flow.request_respawn(GameFlow.REASON_RESTART_KEY)
	_expect(respawn_flow.state == GameFlow.State.TITLE and not respawn_flow.respawn_is_pending(), "a room rebuild is ignored when no room is live")


func _quit_to_title_from_everywhere_in_the_game() -> void:
	for state in [GameFlow.State.PLAYING, GameFlow.State.PAUSED, GameFlow.State.ENDING]:
		var flow := _flow_in(state)
		_expect(flow.quit_to_title() and flow.state == GameFlow.State.TITLE, "Quit to Title works from %s" % GameFlow.State.keys()[state])
	var flow_after_quit := _flow_in(GameFlow.State.PAUSED)
	flow_after_quit.quit_to_title()
	_expect(flow_after_quit.start_new_game() and flow_after_quit.state == GameFlow.State.PLAYING, "and a new run can start from the title afterwards")


func _the_ending_marks_the_game_completed() -> void:
	var root_directory := SaveSupport.make_root("flow_states")
	var service := SaveSupport.new_service(root_directory)
	var flow := GameFlow.new()
	flow.save_service = service
	flow.finish_boot()
	flow.start_new_game()
	_expect(not service.is_completed(), "setup: a fresh run has not been completed")
	_expect(flow.request_pause() and flow.request_resume(), "setup: pausing writes nothing")
	_expect(not service.is_completed(), "a pause does not mark the game completed")
	flow.reach_ending()
	_expect(service.is_completed(), "reaching the ending writes the `completed` mark to the profile")
	flow.finish_ending()
	flow.finish_credits()
	flow.start_new_game()
	_expect(service.is_completed(), "and a New Game afterwards keeps it")
	SaveSupport.remove_root(root_directory)


func _with_no_room_a_rebuild_request_is_ignored() -> void:
	# A rebuild needs a scene to serve it. The scene half (a pause refused during a zone trip and while a rebuild
	# waits, a rebuild behind the fade) is pinned in test_app_flow.gd.
	var flow := _flow_in(GameFlow.State.PLAYING)
	flow.request_respawn(GameFlow.REASON_DEFEATED)
	_expect(not flow.respawn_is_pending() and flow.request_pause(), "with no room attached a rebuild request is ignored and a pause is still allowed")
