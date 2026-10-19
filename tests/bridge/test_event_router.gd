extends UnboundTest

## EventRouter (presentation/bridges/event_router.gd, M3b step 2): the one thing the in-game scene does
## with the events the simulation drained. A handler is called with the event, for the types it
## registered for and no others; several handlers of one type run in the order they registered; a type
## nobody registered for is dropped; events run in the order they happened; and a handler that sleeps
## (a coroutine, like the zone trip) does not hold up the next event.

var calls: Array[String] = []
var last_event: Dictionary = {}


func _init() -> void:
	suite_title = "EVENT ROUTER TEST"
	_check_a_handler_gets_its_event_and_only_its_type()
	_check_handlers_of_one_type_run_in_registration_order()
	_check_events_run_in_the_order_they_happened()
	_check_a_type_nobody_registered_for_is_dropped()
	_check_a_sleeping_handler_does_not_hold_up_the_next_event()
	_check_registering_is_counted()
	finish()


func _record(label: String, event: Dictionary) -> void:
	calls.append(label)
	last_event = event


func _check_a_handler_gets_its_event_and_only_its_type() -> void:
	calls.clear()
	var router := EventRouter.new()
	router.on(Events.DAMAGED, func(event: Dictionary) -> void: _record("damaged", event))
	router.on(Events.GATE_OPENED, func(event: Dictionary) -> void: _record("gate", event))
	var damage_event := {"type": Events.DAMAGED, "entity": 4, "amount": 2, "remaining": 1,
		"direction": Vector2i.LEFT, "source": 9, "tags": []}
	router.route([damage_event])
	_expect(calls == ["damaged"], "an event reaches the handler registered for its type")
	_expect(last_event == damage_event, "and the handler receives the event itself, payload included")
	_expect(not calls.has("gate"), "the handler of another type is not called")


func _check_handlers_of_one_type_run_in_registration_order() -> void:
	calls.clear()
	var router := EventRouter.new()
	router.on(Events.PICKUP_TAKEN, func(event: Dictionary) -> void: _record("save", event))
	router.on(Events.PICKUP_TAKEN, func(event: Dictionary) -> void: _record("sound", event))
	router.on(Events.PICKUP_TAKEN, func(event: Dictionary) -> void: _record("view", event))
	router.route([{"type": Events.PICKUP_TAKEN, "item": 3, "cell": Vector2i(2, 2)}])
	_expect(calls == ["save", "sound", "view"], "several handlers of one type run in the order they registered")


func _check_events_run_in_the_order_they_happened() -> void:
	calls.clear()
	var router := EventRouter.new()
	router.on(Events.ATTACK_LOCKED, func(event: Dictionary) -> void: _record("locked%d" % event["entity"], event))
	router.on(Events.TELEGRAPH_FINISHED, func(event: Dictionary) -> void: _record("finished%d" % event["entity"], event))
	router.route([
		{"type": Events.TELEGRAPH_FINISHED, "entity": 1},
		{"type": Events.ATTACK_LOCKED, "entity": 2},
		{"type": Events.TELEGRAPH_FINISHED, "entity": 3},
	])
	_expect(calls == ["finished1", "locked2", "finished3"], "events are routed in the order they were drained, whatever their types")


func _check_a_type_nobody_registered_for_is_dropped() -> void:
	calls.clear()
	var router := EventRouter.new()
	router.on(Events.DAMAGED, func(event: Dictionary) -> void: _record("damaged", event))
	router.route([{"type": Events.STEP_STARTED, "entity": 1, "cell": Vector2i.ZERO}])
	router.route([])
	_expect(calls.is_empty(), "an event no bridge asked for is dropped without a word, and an empty batch is fine")


## A handler that awaits (the zone trip awaits its fade) returns at its first await; the router must not wait for it.
func _check_a_sleeping_handler_does_not_hold_up_the_next_event() -> void:
	calls.clear()
	var router := EventRouter.new()
	router.on(Events.ZONE_EXIT, _sleep_then_record)
	router.on(Events.ATTACK_LOCKED, func(event: Dictionary) -> void: _record("locked", event))
	router.route([
		{"type": Events.ZONE_EXIT, "entity": 1, "zone": &"t2", "entry": &"start"},
		{"type": Events.ATTACK_LOCKED, "entity": 1},
	])
	_expect(calls == ["locked"], "the event after a sleeping handler is routed at once, the sleeper has not finished")


func _sleep_then_record(event: Dictionary) -> void:
	await create_timer(0.05).timeout
	_record("slept", event)


func _check_registering_is_counted() -> void:
	var router := EventRouter.new()
	_expect(router.handler_count(Events.DAMAGED) == 0, "a router starts with no handlers")
	router.on(Events.DAMAGED, func(_event: Dictionary) -> void: pass)
	router.on(Events.DAMAGED, func(_event: Dictionary) -> void: pass)
	_expect(router.handler_count(Events.DAMAGED) == 2 and router.handler_count(Events.DEFEATED) == 0, "handler_count tells how many registered per type")
