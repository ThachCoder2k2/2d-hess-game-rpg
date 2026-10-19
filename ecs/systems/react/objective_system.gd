class_name ObjectiveSystem
extends EcsSystem

## Judges the room the pawn is in (docs/game-base-plan.md 13.4, moved here from the rules the in-game
## scene used to hold). Every tick it counts the room's enemies, asks whether the pawn has fallen and asks
## whether the room's objective is met:
##   - the room is CLEARED when its objective says so: every enemy it began with is down (the default),
##     or the count its RoomObjective names. It says `room_cleared` once, and the run remembers the room
##     as cleared (D-17: a cleared room stays cleared);
##   - the room is FAILED when the hero's Courage is 0. It marks the room (RoomObjectiveState.failed) and
##     CheckpointSystem, which runs after it, answers the fall with `respawn_requested`. A room that is
##     failed is never cleared, so when the last enemy and the hero fall in the same tick the fall wins.
## Reads: ENEMY_AI, PLAYER_TAG, HEALTH and the room's RoomObjectiveState. Writes: that state only. Emits:
## `room_cleared`. It decides nothing about what a clear or a fall MEANS for the game (the result screen,
## the save, the next room): the shell's bridges answer the events.
##
## A world with no room entity (one booted without EcsBootOptions.with_room_rules) has nothing to judge, and
## the system is silent.

## The schedule stage this system is listed in (ecs/schedule/react.gd).
const PHASE := &"react"


func tick(_delta: float) -> void:
	for room_entity in world.query([RoomObjectiveState.KEY]):
		var state: RoomObjectiveState = world.get_component(room_entity, RoomObjectiveState.KEY)
		_count_enemies(state)
		_judge_hero(state)
		_judge_objective(state)


## Brings the counts up to date. An enemy is down when its Courage is 0 or its AI says defeated. The
## defeated count and the total never go backwards (a fallen enemy's entity may be cleared away later).
func _count_enemies(state: RoomObjectiveState) -> void:
	var defeated := 0
	var remaining := 0
	for enemy in world.query([EcsComponents.ENEMY_AI, EcsComponents.HEALTH]):
		var health: EcsComponents.Health = world.get_component(enemy, EcsComponents.HEALTH)
		var ai: EcsComponents.EnemyAI = world.get_component(enemy, EcsComponents.ENEMY_AI)
		if health.current <= 0 or ai.state == EcsComponents.EnemyAI.STATE_DEFEATED:
			defeated += 1
		else:
			remaining += 1
	state.enemies_defeated = maxi(state.enemies_defeated, defeated)
	state.enemies_remaining = remaining
	state.enemies_total = maxi(state.enemies_total, state.enemies_defeated + remaining)


func _judge_hero(state: RoomObjectiveState) -> void:
	if state.failed:
		return
	for hero in world.query([EcsComponents.PLAYER_TAG, EcsComponents.HEALTH]):
		var health: EcsComponents.Health = world.get_component(hero, EcsComponents.HEALTH)
		if health.current <= 0:
			state.failed = true


func _judge_objective(state: RoomObjectiveState) -> void:
	if state.cleared or state.failed:
		return
	var is_met := state.enemies_total > 0 and state.enemies_remaining <= 0
	if state.objective != null:
		is_met = state.objective.is_complete(state.enemies_defeated, state.enemies_total, state.enemies_remaining)
	if not is_met:
		return
	state.cleared = true
	world.emit_event({
		"type": Events.ROOM_CLEARED,
		"zone": state.zone_id,
		"defeated": state.enemies_defeated,
		"total": state.enemies_total,
		"has_objective": state.objective != null,
	})
