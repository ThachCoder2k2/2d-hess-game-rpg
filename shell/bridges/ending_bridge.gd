class_name EndingBridge
extends ShellBridge

## What the game does when the run ends (docs/game-base-plan.md 8.8, 9.1): the pawn stepped on the door that ends it
## (MovementSystem, `ending_reached`), so the hero's control goes off and GameFlow is asked to reach the ending. GameFlow
## writes the `completed` mark to the profile and AppRoot shows the ending cards, then the credits, then the title. The
## door can be landed on again while the screen fades; the bridge takes the event once. It is refused while a zone trip or a
## room's end is under way (the trip would swap the room under the ending) and by a flow that is not PLAYING.
## Reads: the event. Writes: the hero's control flag (through the scene) and the flow's request.

## True from the moment the ending was asked for until the next room boots in this scene.
var ending_started := false


func register(router: EventRouter) -> void:
	router.on(Events.ENDING_REACHED, _on_ending_reached)


func _on_ending_reached(_event: Dictionary) -> void:
	if ending_started or root.zone_travel_bridge.travel_in_progress or root.outcome_bridge.room_ending:
		return
	if root.game_flow.reach_ending():
		ending_started = true
		root.set_player_control(false)
