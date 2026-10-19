class_name EventRouter
extends RefCounted

## Hands each event the simulation sent this frame to the handlers that asked for its type
## (docs/game-base-plan.md 8.1, 13.2). It is the only thing the in-game scene does with
## `world.drain_events()`: the scene routes the batch, and every responsibility (the HUD, the board
## overlay, the camera, the sounds, the status line, the save, the Book, the zone trip...) is a bridge
## that registers for the event types it cares about in its own `register()`.
##
## The router knows no event and decides nothing. A type nobody registered for is dropped, which is
## what the events that exist for tests and later milestones (`step_started`, `healed`...) need.
##
## Several bridges may register for one type. They run in the order they registered, so the order the
## scene registers its bridges in is the order they react in; the scene lists that order in one place
## and says why where one event needs it (a pickup is written to the save before its sound plays).

## event type (StringName) -> the handlers registered for it (Array[Callable]), in registration order.
## Each handler is called with the event Dictionary.
var handlers_by_event_type: Dictionary = {}


## Registers `handler` for events of `event_type` (one of the consts of ecs/events/events.gd).
func on(event_type: StringName, handler: Callable) -> void:
	assert(Events.is_declared(event_type), "EventRouter: '%s' is not an event declared in ecs/events/events.gd" % event_type)
	if not handlers_by_event_type.has(event_type):
		handlers_by_event_type[event_type] = []
	handlers_by_event_type[event_type].append(handler)


## Calls the handlers of every event in `events`, in the order the events happened. A handler that is
## a coroutine (a zone trip awaits its fade) is started and not waited for: the next event is routed
## while it sleeps, exactly as the scene always did.
func route(events: Array[Dictionary]) -> void:
	for event in events:
		var event_handlers: Array = handlers_by_event_type.get(event.get("type"), [])
		for handler: Callable in event_handlers:
			handler.call(event)


## How many handlers are registered for `event_type`.
func handler_count(event_type: StringName) -> int:
	return handlers_by_event_type.get(event_type, []).size()
