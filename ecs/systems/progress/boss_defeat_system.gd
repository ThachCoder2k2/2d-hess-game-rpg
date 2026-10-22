class_name BossDefeatSystem
extends EcsSystem

## Tells the world a boss has fallen (docs/game-base-plan.md 5.4, 7.3, M5): a piece whose definition names a
## `defeat_flag` (EnemyDefinition, `boss.knight_captain`) sets that flag in the world's WorldFlags the first tick it
## is down, and says `boss_defeated` once. The flag is what the hub's doors wait for (a flag lock in
## content/world/world.tres, enforced by MovementSystem), what the save keeps (the run takes the world's flags,
## SaveBridge) and what a hub prop's StateVariantMarker reads. The system holds no list of bosses and names no
## room: a piece is a boss because its definition says so, which is why a new boss is data (docs/ARCHITECTURE.md).
##
## A piece is down when its Courage is 0 or its AI says defeated, the same test ObjectiveSystem uses. When the hero
## fell in the same tick the fall wins (ObjectiveSystem's rule for a clear): the boss is not credited, so a death
## that rebuilds the room never leaves the flag set over a boss who stands again. The flag already being set (the
## boss fell on an earlier visit and the room was cleared, D-17) changes nothing and says nothing: the return of
## WorldFlags.set_flag() is the "once".
##
## Reads: ENEMY_AI (its definition), HEALTH, PLAYER_TAG. Writes: the world's flags. Emits: `boss_defeated`.
## It is the seed of the boss framework of M8b, which adds phases beside it (BossPhaseSystem runs before it).

## The schedule stage this system is listed in (ecs/schedule/progress.gd).
const PHASE := &"progress"


func tick(_delta: float) -> void:
	if _hero_has_fallen():
		return
	for enemy_entity in world.query([EcsComponents.ENEMY_AI, EcsComponents.HEALTH]):
		var ai: EcsComponents.EnemyAI = world.get_component(enemy_entity, EcsComponents.ENEMY_AI)
		if ai.definition == null or ai.definition.defeat_flag == &"":
			continue
		var health: EcsComponents.Health = world.get_component(enemy_entity, EcsComponents.HEALTH)
		if health.current > 0 and ai.state != EcsComponents.EnemyAI.STATE_DEFEATED:
			continue
		if world.flags.set_flag(ai.definition.defeat_flag, true):
			world.emit_event({
				"type": Events.BOSS_DEFEATED,
				"entity": enemy_entity,
				"boss": ai.definition.id,
				"flag": ai.definition.defeat_flag,
			})


func _hero_has_fallen() -> bool:
	for hero in world.query([EcsComponents.PLAYER_TAG, EcsComponents.HEALTH]):
		var health: EcsComponents.Health = world.get_component(hero, EcsComponents.HEALTH)
		if health.current <= 0:
			return true
	return false
