class_name RoomOutcomeBridge
extends ShellBridge

## How a room ends (the old main.gd:264-302; ObjectiveSystem and the checkpoint rules of D-16 replace
## the rules in this file in step 3). It counts the enemies the room began with as they fall, decides
## when the room is won, and answers the hero's own defeat:
##   - a win: the room's objective says it is complete (every enemy down by default, or a count the
##     room names). In world mode clearing a zone is quiet, and only a zone that carries an objective
##     ends with a result screen (boss arenas, later). A win switches the hero's control off, plays the
##     clear sound and puts the room's clear lines on the status line and the result panel.
##   - a defeat: the hero fell. The room stops ticking (`room_ending`), the defeat jingle plays, the
##     room's defeat lines go up, and after a short beat of 0.85 s GameFlow is asked to start the
##     room again at the checkpoint. A death writes no save (R17, D-16): autosave is for success events
##     only, and the run already wrote down everything it learned when it learned it.
## While `room_ending` the scene stops ticking the world.
## Reads: events, the room's objective. Writes: the hero's control flag (through the scene), the HUD
## and status line (through their bridges).

## Seconds between the hero's fall and the room starting again: long enough to read the defeat lines.
const DEFEAT_BEAT_SECONDS := 0.85

## How many enemies the room began with, how many still stand, how many fell.
var enemies_total := 0
var enemies_remaining := 0
var enemies_defeated := 0
## True from the moment the room is won or the hero falls until the next room boots; the scene does
## not tick the world while it is true, and a zone trip does not start.
var room_ending := false


func register(router: EventRouter) -> void:
	router.on(Events.DEFEATED, _on_defeated)


## A room just booted with `enemy_count` enemies: the counts start over and the room is live.
func begin_room(enemy_count: int) -> void:
	enemies_total = enemy_count
	enemies_remaining = enemy_count
	enemies_defeated = 0
	room_ending = false


func _on_defeated(event: Dictionary) -> void:
	if is_player(int(event.get("entity", 0))):
		_on_player_defeated()
		return
	enemies_remaining = maxi(0, enemies_remaining - 1)
	enemies_defeated += 1
	root.hud_bridge.show_encounter_count(enemies_remaining, enemies_total)
	_check_completion()


func _check_completion() -> void:
	if room_ending:
		return
	# World mode: clearing a zone is quiet — only an explicit objective (boss
	# arenas, later) can end the run with a result screen.
	var room := root.current_room
	if root.world_graph != null and (room == null or room.get("objective") == null):
		return
	var complete := enemies_total > 0 and enemies_remaining <= 0
	var objective: Resource = room.get("objective") if room != null else null
	if objective != null and objective.has_method("is_complete"):
		complete = bool(objective.call("is_complete", enemies_defeated, enemies_total, enemies_remaining))
	if not complete:
		return
	room_ending = true
	root.set_player_control(false)
	root.audio_bridge.play(AudioBridge.ROOM_CLEAR_SOUND)
	var clear_message := root.room_text("get_clear_message", "ROOM CLEARED")
	root.message_bridge.say(clear_message)
	root.hud_bridge.show_result(clear_message, root.room_text("get_clear_subtitle", "PRESS R TO RESET"))


func _on_player_defeated() -> void:
	if room_ending:
		return
	room_ending = true
	root.zone_travel_bridge.forget_health_carry()
	root.audio_bridge.play(AudioBridge.DEFEAT_JINGLE_SOUND)
	var defeat_message := root.room_text("get_defeat_message", "THE PAWN FALLS")
	root.message_bridge.say(defeat_message)
	root.hud_bridge.show_result(defeat_message, root.room_text("get_defeat_subtitle", "THE CHILD RESETS THE BOARD"))
	var tree := root.get_tree()
	if tree == null:
		return
	var world_that_fell := root.ecs
	await tree.create_timer(DEFEAT_BEAT_SECONDS).timeout
	# If the restart key rebuilt the room during the beat, there is nothing left to start again.
	if root.is_inside_tree() and root.ecs == world_that_fell:
		root.game_flow.request_respawn(GameFlow.REASON_DEFEATED)
