class_name CheckpointSystem
extends EcsSystem

## The checkpoint and death rules of D-16 (docs/game-base-plan.md 5.2, 13.4), in the progress stage after
## ObjectiveSystem. Two jobs, both read off the room's own entity (RoomCheckpoint, RoomObjectiveState):
##
##   ARRIVAL. The first tick the world runs, if the pawn came in through a door of a room whose scene says
##   entering it is a checkpoint (a hub, a boss room: RoomEncounter.checkpoint_on_entry), the checkpoint is
##   set. The pawn's Courage is refilled to full, through the heal queue like any other heal (source 0 is
##   the world itself), and `checkpoint_set` says which zone and entry it is and what was refilled. Believe
##   refills here too once it exists (`_refill_believe` is its one seam; M10 fills it in). A launch and a
##   respawn are not arrivals, so they set no checkpoint.
##
##   FALL. When ObjectiveSystem has marked the room failed (the hero's Courage reached 0), the system says
##   `respawn_requested`, once, naming the zone and the entry the pawn came in through. That is the death
##   rule: a death resets only the room it happened in, and the pawn starts again on that room's entry with
##   full Courage. What stays done stays done (cleared rooms, unlocks, flags, opened gates, taken persistent
##   pickups) because none of it lives in the room: the shell holds it in the run.
##
## It decides nothing about the shell: where the run keeps the checkpoint, when to save and how the defeat
## is shown are the bridges' answers to the two events. A world with no room entity is left alone.

## The schedule stage this system is listed in (ecs/schedule/progress.gd).
const PHASE := &"progress"

## What `checkpoint_set` names a Courage refill by.
const COURAGE := &"courage"
## What it names a Believe refill by (nothing refills it until M10).
const BELIEVE := &"believe"


func tick(_delta: float) -> void:
	for room_entity in world.query([RoomCheckpoint.KEY]):
		var checkpoint: RoomCheckpoint = world.get_component(room_entity, RoomCheckpoint.KEY)
		_judge_arrival(checkpoint)
		_answer_fall(room_entity, checkpoint)


func _judge_arrival(checkpoint: RoomCheckpoint) -> void:
	if checkpoint.arrival_judged:
		return
	checkpoint.arrival_judged = true
	if not (checkpoint.checkpoint_on_entry and checkpoint.entered_by_door):
		return
	var refills: Array[StringName] = [COURAGE]
	var hero := _hero()
	if hero != 0:
		_refill_courage(hero)
		if _refill_believe(hero):
			refills.append(BELIEVE)
	world.emit_event({
		"type": Events.CHECKPOINT_SET,
		"zone": checkpoint.zone_id,
		"entry": checkpoint.entry_id,
		"refills": refills,
	})


func _answer_fall(room_entity: int, checkpoint: RoomCheckpoint) -> void:
	if checkpoint.respawn_requested:
		return
	var objective_state: RoomObjectiveState = world.get_component(room_entity, RoomObjectiveState.KEY)
	if objective_state == null or not objective_state.failed:
		return
	checkpoint.respawn_requested = true
	world.emit_event({
		"type": Events.RESPAWN_REQUESTED,
		"entity": _hero(),
		"zone": checkpoint.zone_id,
		"entry": checkpoint.entry_id,
	})


## Queues a heal for whatever Courage the hero is missing. Nothing is queued for a hero who is full or down
## (a heal never revives).
func _refill_courage(hero: int) -> void:
	var health: EcsComponents.Health = world.get_component(hero, EcsComponents.HEALTH)
	if health != null and health.current > 0 and health.current < health.max_value:
		Events.emit_heal(world, hero, health.max_value - health.current, 0)


## The seam for Believe (docs/game-base-plan.md D-41: it refills at hub entry and at any checkpoint). Believe
## has no component until M10, so there is nothing to refill: returns false. When the component exists, this
## restores it to full and returns true, and `checkpoint_set` starts naming BELIEVE with no other change.
func _refill_believe(_hero: int) -> bool:
	return false


## The hero's entity, 0 when the world has none.
func _hero() -> int:
	var heroes := world.query([EcsComponents.PLAYER_TAG])
	return heroes[0] if not heroes.is_empty() else 0
