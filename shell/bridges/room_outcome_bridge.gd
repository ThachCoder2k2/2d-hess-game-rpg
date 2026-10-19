class_name RoomOutcomeBridge
extends ShellBridge

## What the game does when a room ends. ObjectiveSystem judges the room (the old main.gd:264-302 rules
## live there now); this bridge answers its verdicts:
##   - `room_cleared`: in world mode clearing a zone is quiet, and only a zone that carries its own
##     objective (boss arenas, later) ends with a result screen; a room outside the world graph ends when
##     it is cleared. An ending switches the hero's control off, plays the clear sound and puts the room's
##     clear lines on the status line and the result panel.
##   - `respawn_requested`, the simulation's answer to the hero's fall (CheckpointSystem): the room stops
##     ticking (`room_ending`), the defeat jingle plays, the room's defeat lines go up, and after a short
##     beat of 0.85 s GameFlow is asked to start the room again on the entry the pawn came in by. A death
##     writes no save (R17, D-16): autosave is for success events only, and the run already wrote down
##     everything it learned when it learned it.
## While `room_ending` the scene stops ticking the world. The enemy counts the HUD shows are the
## HudSnapshot's (ObjectiveSystem keeps them), not this bridge's.
## Reads: events. Writes: the hero's control flag (through the scene), the HUD and status line (through
## their bridges).

## Seconds between the hero's fall and the room starting again: long enough to read the defeat lines.
const DEFEAT_BEAT_SECONDS := 0.85

## True from the moment the room is won or the hero falls until the next room boots; the scene does
## not tick the world while it is true, and a zone trip does not start.
var room_ending := false


func register(router: EventRouter) -> void:
	router.on(Events.ROOM_CLEARED, _on_room_cleared)
	router.on(Events.RESPAWN_REQUESTED, _on_respawn_requested)


## A room just booted: it is live.
func begin_room() -> void:
	room_ending = false


func _on_room_cleared(event: Dictionary) -> void:
	if room_ending:
		return
	# World mode: clearing a zone is quiet — only an explicit objective (boss
	# arenas, later) can end the run with a result screen.
	if root.world_graph != null and not bool(event.get("has_objective", false)):
		return
	room_ending = true
	root.set_player_control(false)
	root.audio_bridge.play(AudioBridge.ROOM_CLEAR_SOUND)
	var clear_message_key := ZoneStage.room_text(root.current_room, "get_clear_message", RoomObjective.STOCK_CLEAR_KEY)
	root.message_bridge.say(clear_message_key)
	root.hud_bridge.show_result(clear_message_key, ZoneStage.room_text(root.current_room, "get_clear_subtitle", RoomObjective.STOCK_CLEAR_SUBTITLE_KEY))


func _on_respawn_requested(_event: Dictionary) -> void:
	if room_ending:
		return
	room_ending = true
	root.zone_travel_bridge.forget_carry()
	root.audio_bridge.play(AudioBridge.DEFEAT_JINGLE_SOUND)
	var defeat_message_key := ZoneStage.room_text(root.current_room, "get_defeat_message", RoomObjective.STOCK_DEFEAT_KEY)
	root.message_bridge.say(defeat_message_key)
	root.hud_bridge.show_result(defeat_message_key, ZoneStage.room_text(root.current_room, "get_defeat_subtitle", RoomObjective.STOCK_DEFEAT_SUBTITLE_KEY))
	var tree := root.get_tree()
	if tree == null:
		return
	var respawns_at_fall := root.game_flow.respawn_count
	await tree.create_timer(DEFEAT_BEAT_SECONDS).timeout
	# If the restart key rebuilt the room during the beat, there is nothing left to start again. A zone trip
	# that swapped the world meanwhile is not a rebuild: the hero fell, so the room starts again regardless.
	# The player may have left for the title during the beat (Quit to Title frees the scene).
	if is_instance_valid(root) and root.is_inside_tree() and root.game_flow.respawn_count == respawns_at_fall:
		root.game_flow.request_respawn(GameFlow.REASON_DEFEATED)
