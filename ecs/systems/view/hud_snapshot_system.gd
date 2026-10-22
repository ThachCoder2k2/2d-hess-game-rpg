class_name HudSnapshotSystem
extends EcsSystem

## Publishes the simulation for the HUD and the board overlay: rebuilds world.hud_snapshot from
## the components at the end of every tick, so presentation reads a data object and never a
## component (docs/game-base-plan.md 13.4 step 17, 14.3, D-38).
## Reads: PLAYER_TAG, HEALTH, GRID_POS, FACING, PLAYER_COMBAT, ENEMY_AI, the room's RoomObjectiveState, the
## world's attack token and the grid's door cells (shut or open by DoorRules).
## Writes: world.hud_snapshot only (in place; the snapshot object never changes identity).
## Emits: nothing. It decides nothing: every number it copies was decided by another system.
##
## Runs after every rule of the tick and before ViewSyncSystem. It does not run while the world is
## frozen: a held simulation has nothing new to publish, and the HUD keeps showing what it showed.
## The shell calls build() once after booting a room, so the HUD has a picture before the first tick.

## The schedule stage this system is listed in (ecs/schedule/view.gd).
const PHASE := &"view"


func tick(_delta: float) -> void:
	build(world)


## Rebuilds world.hud_snapshot from the world as it is now and counts one more revision.
static func build(target_world: EcsWorld) -> void:
	var snapshot := target_world.hud_snapshot
	snapshot.revision += 1
	snapshot.attack_token_owner = target_world.attack_token_owner
	_fill_hero(target_world, snapshot)
	_fill_room(target_world, snapshot)
	_fill_enemies(target_world, snapshot)
	_fill_doors(target_world, snapshot)


static func _fill_hero(target_world: EcsWorld, snapshot: HudSnapshot) -> void:
	var heroes := target_world.query([EcsComponents.PLAYER_TAG])
	if heroes.is_empty():
		snapshot.player_entity = 0
		snapshot.player_courage_current = 0
		snapshot.player_courage_max = 0
		snapshot.player_cell = Vector2i.ZERO
		snapshot.player_facing = Vector2i.ZERO
		snapshot.sword_unlocked = false
		snapshot.skill_cooldown_left = 0.0
		snapshot.skill_cooldown_duration = 1.0
		return
	var hero: int = heroes[0]
	snapshot.player_entity = hero

	var health: EcsComponents.Health = target_world.get_component(hero, EcsComponents.HEALTH)
	snapshot.player_courage_current = health.current if health != null else 0
	snapshot.player_courage_max = health.max_value if health != null else 0

	var grid_pos: EcsComponents.GridPos = target_world.get_component(hero, EcsComponents.GRID_POS)
	snapshot.player_cell = grid_pos.cell if grid_pos != null else Vector2i.ZERO
	var facing: EcsComponents.Facing = target_world.get_component(hero, EcsComponents.FACING)
	snapshot.player_facing = facing.direction if facing != null else Vector2i.ZERO

	var combat: EcsComponents.PlayerCombat = target_world.get_component(hero, EcsComponents.PLAYER_COMBAT)
	snapshot.sword_unlocked = combat != null and combat.sword_unlocked
	snapshot.skill_cooldown_left = combat.skill_cooldown_left if combat != null else 0.0
	snapshot.skill_cooldown_duration = combat.skill_cooldown_duration if combat != null else 1.0


## The room's enemy counts, from the room's own entity; zeros when the world has no room entity.
static func _fill_room(target_world: EcsWorld, snapshot: HudSnapshot) -> void:
	snapshot.room_enemies_total = 0
	snapshot.room_enemies_remaining = 0
	for room_entity in target_world.query([RoomObjectiveState.KEY]):
		var state: RoomObjectiveState = target_world.get_component(room_entity, RoomObjectiveState.KEY)
		snapshot.room_enemies_total = state.enemies_total
		snapshot.room_enemies_remaining = state.enemies_remaining


## Keeps one DoorBrief per door cell of the room, updated in place: the board draws a door shut or open from it. A room
## with no door allocates nothing.
static func _fill_doors(target_world: EcsWorld, snapshot: HudSnapshot) -> void:
	var door_by_cell: Dictionary = target_world.grid.exit_by_cell
	var briefs := snapshot.door_brief_by_cell
	for cell: Vector2i in briefs.keys():
		if not door_by_cell.has(cell):
			briefs.erase(cell)
	for cell: Vector2i in door_by_cell:
		var door: Dictionary = door_by_cell[cell]
		var brief: HudSnapshot.DoorBrief = briefs.get(cell)
		if brief == null:
			brief = HudSnapshot.DoorBrief.new()
			briefs[cell] = brief
		brief.is_shut = DoorRules.is_shut(target_world, door)
		brief.ends_run = bool(door.get("ends_run", false))


## Keeps one EnemyBrief per enemy: updated in place, created for a new enemy, dropped for one that
## is gone, so a steady room allocates nothing per tick.
static func _fill_enemies(target_world: EcsWorld, snapshot: HudSnapshot) -> void:
	var enemies := target_world.query([EcsComponents.ENEMY_AI, EcsComponents.GRID_POS])
	var briefs := snapshot.enemy_brief_by_entity
	for entity_id: int in briefs.keys():
		if entity_id not in enemies:
			briefs.erase(entity_id)
	for entity_id in enemies:
		var ai: EcsComponents.EnemyAI = target_world.get_component(entity_id, EcsComponents.ENEMY_AI)
		var grid_pos: EcsComponents.GridPos = target_world.get_component(entity_id, EcsComponents.GRID_POS)
		var brief: HudSnapshot.EnemyBrief = briefs.get(entity_id)
		if brief == null:
			brief = HudSnapshot.EnemyBrief.new()
			briefs[entity_id] = brief
		brief.cell = grid_pos.cell
		brief.committed_goal = ai.committed_goal
		brief.telegraph_progress = _telegraph_progress(ai)


## 0.0 when the enemy is not telegraphing, else the share of the telegraph that has run.
static func _telegraph_progress(ai: EcsComponents.EnemyAI) -> float:
	if ai.state != EcsComponents.EnemyAI.STATE_TELEGRAPH:
		return 0.0
	return clampf(1.0 - ai.state_time_left / maxf(ai.telegraph_duration, 0.001), 0.0, 1.0)
