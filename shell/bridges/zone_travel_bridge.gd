class_name ZoneTravelBridge
extends ShellBridge

## The zone trip's responsibility (the old main.gd zone travel): the hero stepped on an open door cell,
## so the scene fades out, swaps the zone scene, rebuilds the whole simulation on the new zone and
## fades back in. The ordering is what the tests pin, so it is written out:
##
##   1. a trip does not start while another is under way, while the room is ending (a death or a result
##      screen), without a world graph (a standalone room) or toward a zone the graph does not have;
##   2. the hero's control goes off for the whole trip;
##   3. the pawn is captured as a PlayerSnapshot (docs/game-base-plan.md 14.2) NOW: a hit landing during the
##      fade-out reaches only the old world's hero, so the carry is the pawn as the trip began;
##   4. the destination room and entry are the run's from now on, and the run takes the old world's flags,
##      BEFORE the fade (in memory: a plain trip is no success event and saves nothing; a hub or a boss room
##      sets the checkpoint and saves when the pawn lands there, CheckpointSystem and SaveBridge);
##   5. fade to black, swap the zone node behind the black, boot the new world (EcsBoot applies the snapshot
##      right after the hero is built, and the bridge forgets it), fade back in;
##   6. control returns and the trip is over.
##
## The snapshot holds what plan 14.2 calls persistent and carries it across a swap: Courage (current and max),
## the unlocked sword, the world's flags. Everything the plan calls per-room is not in it and so resets with
## the world: skill cooldown, invulnerability and other status, the swing, telegraphs, hit progress, the floor
## weapon held, cell effects. The facing is per-room too: the entry marker's room sets it. The carry is never
## saved: every launch starts the room with full Courage (health never saves; a checkpoint refills it).
## Reads: the zone_exit event, the hero's components (through PlayerSnapshot.capture). Writes: the run's room and entry (through the SaveBridge),
## the hero's control and Courage, the fade layer.

## Seconds the screen takes to fade to black, and again back.
const FADE_SECONDS := 0.22

## True from the moment a trip starts until its last step.
var travel_in_progress := false
## The pawn as it left the room it is leaving, for the next world's hero: captured when a trip starts, handed
## to EcsBoot by take_carried_snapshot() and gone after it. Null = nothing is carried (a launch, a respawn).
var carried_player_snapshot: PlayerSnapshot = null


func register(router: EventRouter) -> void:
	router.on(Events.ZONE_EXIT, _on_zone_exit)


## Runs the whole trip to `zone_id`, landing on its `entry_id` marker. Called by the zone_exit event
## without waiting, and by a test that waits for it.
func travel_to(zone_id: StringName, entry_id: StringName) -> void:
	if travel_in_progress or root.outcome_bridge.room_ending or root.world_graph == null or not root.world_graph.has_zone(zone_id):
		return
	travel_in_progress = true
	root.set_player_control(false)
	carried_player_snapshot = PlayerSnapshot.capture(root.ecs, root.player_id)
	root.save_bridge.record_room(zone_id, entry_id)
	root.save_bridge.remember_world()
	await _fade_to(1.0)
	root.swap_zone(zone_id)
	root.boot_zone(entry_id, true)
	await _fade_to(0.0)
	root.set_player_control(true)
	travel_in_progress = false


## Boot step: the snapshot for the hero of the world about to be built, which the scene hands to EcsBoot
## through EcsBootOptions.player_snapshot; the bridge forgets it. Null when nothing is carried, and also when
## the pawn left with no Courage: a fallen hero is not carried into a room (the room it fell in starts again
## and the pawn begins it whole).
func take_carried_snapshot() -> PlayerSnapshot:
	var snapshot := carried_player_snapshot
	carried_player_snapshot = null
	if snapshot != null and snapshot.courage_current <= 0:
		return null
	return snapshot


## Forgets a pending carry (the hero fell: the next room starts with full Courage).
func forget_carry() -> void:
	carried_player_snapshot = null


func _on_zone_exit(event: Dictionary) -> void:
	travel_to(StringName(event.get("zone", &"")), StringName(event.get("entry", &"start")))


## The editor-owned FadeLayer rect; the bridge only tweens its alpha.
func _fade_to(target_alpha: float) -> void:
	var fade_rect := root.get_node_or_null(root.fade_rect_path) as ColorRect
	if fade_rect == null:
		return
	var tween := root.create_tween()
	tween.tween_property(fade_rect, "modulate:a", target_alpha, FADE_SECONDS)
	await tween.finished
