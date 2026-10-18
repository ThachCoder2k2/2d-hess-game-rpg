extends RefCounted

## Boots one actor view into a throwaway ECS world that has only the ViewSyncSystem, so a test or
## a preview tool can ask "what does this piece draw when it faces right, holds a spear, is
## telegraphing?" and get the answer the real game would give: the same EcsBoot bake, the same
## ViewSyncSystem writing the nodes. Nothing here decides anything; it only sets the components
## ViewSyncSystem reads and ticks once.
##
## There is no class_name on purpose: callers preload() this script, which keeps it usable on a
## fresh checkout before the editor import pass has run. Shared by tools/render_actor_preview.gd
## and tests/architecture/test_pieces_inside_cell.gd.

const ROLE_PLAYER := "player"
const ROLE_ENEMY := "enemy"
## Where the actor stands: the cell (1, 5) of the default 16 x 9 board.
const ACTOR_POSITION := Vector2(112, 212)
const TICK_SECONDS := 0.016
## Directions a piece can face, in the order a preview shows them.
const FACINGS: Array[Vector2i] = [Vector2i.DOWN, Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT]


## The tree must be running (a suite or tool that calls this from `_init()` awaits one frame first),
## because the probe reads global transforms and "visible in the tree".
##
## A booted actor: { "host": the root node of the throwaway world (free it when done),
## "view": the ActorView, "world": the EcsWorld, "entity": its entity id }.
## `definition` replaces the scene's own EnemyDefinition when given (an enemy role only).
static func boot(tree: SceneTree, scene: PackedScene, role: String, definition: EnemyDefinition = null) -> Dictionary:
	var view := scene.instantiate() as ActorView
	if role == ROLE_ENEMY and definition != null:
		view.definition = definition
	return _boot_view(tree, view, role)


## Boots an ActorView exactly as a room scene placed it: its own scale, rotation, definition and
## exports stay, and only its position is replaced by ACTOR_POSITION. The view is taken out of its
## room first (the room scene itself is never added to a tree, the way ContentDb's RoomScan reads
## it). This is how a test measures the actors the game really ships, with whatever the room
## scene did to them. An enemy role only: a room parks enemies, never the hero.
static func boot_placed(tree: SceneTree, placed_view: ActorView) -> Dictionary:
	if placed_view.get_parent() != null:
		placed_view.get_parent().remove_child(placed_view)
	placed_view.owner = null
	return _boot_view(tree, placed_view, ROLE_ENEMY)


static func _boot_view(tree: SceneTree, view: ActorView, role: String) -> Dictionary:
	var host := Node2D.new()
	host.name = "ActorStage"
	tree.root.add_child(host)
	view.position = ACTOR_POSITION
	var room: Node2D = null
	if role == ROLE_PLAYER:
		host.add_child(view)
	else:
		room = Node2D.new()
		room.name = "Room"
		host.add_child(room)
		room.add_child(view)
	var world := EcsWorld.new()
	world.name = "EcsWorld"
	world.manual_tick = true
	host.add_child(world)
	world.add_system(ViewSyncSystem.new())
	var cast := EcsBoot.boot(world, EcsBootOptions.for_scene(view if role == ROLE_PLAYER else null, room))
	var entity_id := int(cast["player"]) if role == ROLE_PLAYER else int(cast["enemies"][0])
	var stage := {"host": host, "view": view, "world": world, "entity": entity_id}
	tick(stage)
	return stage


static func free_stage(tree: SceneTree, stage: Dictionary) -> void:
	var host := stage["host"] as Node
	if host != null and is_instance_valid(host):
		tree.root.remove_child(host)
		host.free()


## One ViewSyncSystem tick: the nodes now show whatever the components say.
static func tick(stage: Dictionary) -> void:
	(stage["world"] as EcsWorld).tick(TICK_SECONDS)


static func set_facing(stage: Dictionary, direction: Vector2i) -> void:
	var facing: EcsComponents.Facing = _component(stage, EcsComponents.FACING)
	facing.direction = direction


## The actor has just been hit: Health.recoil is this offset (pixels), the shove ViewSyncSystem draws
## on MotionRoot. HealthSystem sets 4 px along the hit; a test may set more to prove the limit.
static func shove(stage: Dictionary, offset: Vector2) -> void:
	var health: EcsComponents.Health = _component(stage, EcsComponents.HEALTH)
	health.recoil = offset


## An enemy holds this weapon (a pickup's EnemyWeapon), so its weapon is drawn.
static func give_enemy_weapon(stage: Dictionary, weapon: EnemyWeapon) -> void:
	var slot: EcsComponents.WeaponSlot = _component(stage, EcsComponents.WEAPON_SLOT)
	slot.weapon = weapon


## An enemy is mid-telegraph, a quarter of the way through, so its aura is drawn.
static func start_enemy_telegraph(stage: Dictionary) -> void:
	var ai: EcsComponents.EnemyAI = _component(stage, EcsComponents.ENEMY_AI)
	ai.state = EcsComponents.EnemyAI.STATE_TELEGRAPH
	ai.telegraph_duration = 0.4
	ai.state_time_left = 0.3


## The hero is mid-attack with this profile, so its weapon is drawn.
static func start_player_attack(stage: Dictionary, profile: AttackProfile) -> void:
	var combat: EcsComponents.PlayerCombat = _component(stage, EcsComponents.PLAYER_COMBAT)
	combat.sword_unlocked = true
	combat.active_attack = profile
	combat.attack_visual_time = 0.2


static func clear_player_attack(stage: Dictionary) -> void:
	var combat: EcsComponents.PlayerCombat = _component(stage, EcsComponents.PLAYER_COMBAT)
	combat.active_attack = null
	combat.attack_visual_time = 0.0


static func _component(stage: Dictionary, component_key: StringName) -> Variant:
	return (stage["world"] as EcsWorld).get_component(int(stage["entity"]), component_key)
