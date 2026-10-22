class_name DoorRules
extends RefCounted

## The one rule of a shut door, for the two systems that ask it. MovementSystem asks it when the hero lands on a
## door cell (a shut door says why and does not travel); HudSnapshotSystem asks it every tick so the board can DRAW the
## door shut or open (the M5 review: door cells were plain floor, nobody could see where the way on was). A door is
## shut while it waits for the room to be cleared (`requires_room_clear`) or for a world flag (`requires_flag`, a boss
## fallen). The door data is one EcsGrid.exit_by_cell entry. Pure functions: nothing here writes the world.


## True while `door` (an EcsGrid.exit_by_cell value) does not let the hero through.
static func is_shut(world: EcsWorld, door: Dictionary) -> bool:
	if bool(door.get("requires_room_clear", false)) and not room_is_clear(world):
		return true
	var required_flag := StringName(door.get("requires_flag", &""))
	return required_flag != &"" and not bool(world.flags.get_flag(required_flag, false))


## True when no enemy of the room is still standing (an enemy with no health left, or in its defeated state, does not count).
static func room_is_clear(world: EcsWorld) -> bool:
	for enemy_id in world.query([EcsComponents.ENEMY_AI, EcsComponents.HEALTH]):
		var health: EcsComponents.Health = world.get_component(enemy_id, EcsComponents.HEALTH)
		var ai: EcsComponents.EnemyAI = world.get_component(enemy_id, EcsComponents.ENEMY_AI)
		if health != null and health.current > 0 and ai != null and ai.state != EcsComponents.EnemyAI.STATE_DEFEATED:
			return false
	return true
