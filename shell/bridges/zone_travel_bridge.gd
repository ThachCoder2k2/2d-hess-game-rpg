class_name ZoneTravelBridge
extends ShellBridge

## The zone trip's responsibility (the old main.gd zone travel): the hero stepped on an open door cell,
## so the scene fades out, swaps the zone scene, rebuilds the whole simulation on the new zone and
## fades back in. The ordering is what the tests pin, so it is written out:
##
##   1. a trip does not start while another is under way, while the room is ending (a death or a result
##      screen), without a world graph (a standalone room) or toward a zone the graph does not have;
##   2. the hero's control goes off for the whole trip;
##   3. the hero's Courage is remembered as the carry (a snapshot taken NOW: a hit landing during the
##      fade-out reaches only the old world's hero);
##   4. the destination is the run's checkpoint and is saved, BEFORE the fade (interim until D-16's
##      checkpoint rules: today every zone entry moves it);
##   5. fade to black, swap the zone node behind the black, boot the new world (which applies and
##      consumes the carry), fade back in;
##   6. control returns and the trip is over.
##
## The carry is never saved: every launch starts the room with full Courage. The PlayerSnapshot of the
## zone swap (step 3) replaces the bare integer.
## Reads: the zone_exit event, the hero's health. Writes: the run's checkpoint (through the SaveBridge),
## the hero's control and Courage, the fade layer.

## Seconds the screen takes to fade to black, and again back.
const FADE_SECONDS := 0.22

## True from the moment a trip starts until its last step.
var travel_in_progress := false
## Courage carried across a zone trip: the hero's health when the trip started, applied to the next
## world's hero by apply_health_carry() and consumed there. -1 = no carry (a fresh boot, or a death).
var player_health_carry := -1


func register(router: EventRouter) -> void:
	router.on(Events.ZONE_EXIT, _on_zone_exit)


## Runs the whole trip to `zone_id`, landing on its `entry_id` marker. Called by the zone_exit event
## without waiting, and by a test that waits for it.
func travel_to(zone_id: StringName, entry_id: StringName) -> void:
	if travel_in_progress or root.outcome_bridge.room_ending or root.world_graph == null or not root.world_graph.has_zone(zone_id):
		return
	travel_in_progress = true
	root.set_player_control(false)
	var health: EcsComponents.Health = root.ecs.get_component(root.player_id, EcsComponents.HEALTH)
	player_health_carry = health.current if health != null else -1
	root.save_bridge.record_checkpoint(zone_id, entry_id)
	await _fade_to(1.0)
	root.swap_zone(zone_id)
	root.boot_zone(entry_id)
	await _fade_to(0.0)
	root.set_player_control(true)
	travel_in_progress = false


## Boot step: gives the freshly spawned hero the Courage the trip carried, then consumes the carry. A carry
## above the hero's maximum is clamped, and a carry of 0 or less is not applied.
func apply_health_carry() -> void:
	if player_health_carry > 0:
		var health: EcsComponents.Health = root.ecs.get_component(root.player_id, EcsComponents.HEALTH)
		if health != null:
			health.current = mini(player_health_carry, health.max_value)
	player_health_carry = -1


## Forgets a pending carry (the hero fell: the next room starts with full Courage).
func forget_health_carry() -> void:
	player_health_carry = -1


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
