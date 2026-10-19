extends UnboundTest

## DespawnBridge (shell/bridges/despawn_bridge.gd, M3b step 2): what happens to a view when its entity
## leaves the room. A defeated enemy keeps its view for the defeat clip (0.6 s of real time, the clip
## is editor-owned and ViewSyncSystem plays it) and is then freed with its VIEW_REF dropped; the taken
## floor weapon's view goes at once (test_bridge_persistence pins that one end to end). Driven through
## the real scene and the real damage path: the pawn of T3 is killed the way the hero's sword would.

const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "despawn"

const T3 := &"t3_first_pawn_clash"


func _init() -> void:
	suite_title = "BRIDGE DESPAWN TEST"
	call_deferred("_run")


func _run() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	var main := await Support.boot_main(self)
	await Support.travel_to(main, T3, &"west_entry")
	Support.remove_enemy_ai(main)
	var ecs := Support.ecs_of(main)
	var cast: Dictionary = main.get("cast")
	var enemy_id: int = cast["enemies"][0]
	var enemy_view := cast["view_by_entity"][enemy_id] as Node2D
	_expect(enemy_view != null and ecs.get_component(enemy_id, EcsComponents.VIEW_REF) != null, "setup: T3's pawn has a view bound to it")

	# --- The blow lands: the defeat event is handled, the view stays for its clip ---
	# A damage request on purpose, not the sword: this suite is about what happens to a view when its entity
	# leaves the room, not about reaching the pawn. The suites that follow a player (test_owner_guide_steps,
	# test_cleared_rooms, test_bridge_room_outcome) bring pawns down with the sword.
	Events.emit_damage(ecs, enemy_id, 99, Vector2i.ZERO, Support.player_id_of(main))
	Support.pump(main, Support.SIM_STEP_SECONDS)
	_expect(ecs.get_component(enemy_id, EcsComponents.HEALTH).current == 0, "setup: the pawn is down")
	_expect(is_instance_valid(enemy_view) and not enemy_view.is_queued_for_deletion(), "a defeated enemy's view stays while its defeat clip plays")
	_expect(ecs.get_component(enemy_id, EcsComponents.VIEW_REF) != null, "and is still bound to its entity")

	# --- After the clip's moment the view is let go ---
	await create_timer(DespawnBridge.DEFEAT_CLIP_SECONDS + 0.25).timeout
	_expect(not is_instance_valid(enemy_view) or enemy_view.is_queued_for_deletion(), "the view is freed once the clip has had its moment")
	_expect(ecs.get_component(enemy_id, EcsComponents.VIEW_REF) == null, "and the entity no longer points at it")
	_expect(is_instance_valid(main.get("player_view")) and not (main.get("player_view") as Node).is_queued_for_deletion(), "the hero's own view is never despawned")

	Support.end_suite(self, save_service)

