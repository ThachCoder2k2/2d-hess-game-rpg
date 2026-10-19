extends UnboundTest

## CameraBridge (presentation/bridges/camera_bridge.gd, M3b step 2): which events kick the screen and
## the framing of every room that boots. The numbers are the ones game_root.gd used before the split
## (a landed hit: 0.10 s at 2.6; a hit taken: 0.16 s at 4.2 plus the damage); this suite pins them
## through a real router and a real CameraRig, with a snapshot and no world.

const HERO := 1
const PAWN := 7


func _init() -> void:
	suite_title = "CAMERA BRIDGE TEST"
	# A camera can only become current once it is in the tree, which a suite's _init() is not yet.
	await process_frame
	_check_a_landed_hit_shakes_lightly()
	_check_a_hit_taken_shakes_harder_with_the_damage()
	_check_only_the_heroes_hurt_shakes_the_screen()
	_check_show_room_frames_the_grid()
	_check_a_bridge_without_a_rig_is_silent()
	finish()


func _make_bridge() -> Array:
	var rig := CameraRig.new()
	root.add_child(rig)
	var snapshot := HudSnapshot.new()
	snapshot.player_entity = HERO
	var bridge := CameraBridge.new()
	bridge.attach(rig)
	bridge.bind_world(snapshot, {})
	var router := EventRouter.new()
	bridge.register(router)
	return [bridge, rig, router]


func _check_a_landed_hit_shakes_lightly() -> void:
	var parts := _make_bridge()
	var rig: CameraRig = parts[1]
	var router: EventRouter = parts[2]
	var profile := AttackProfile.new()
	var cells: Array[Vector2i] = [Vector2i(2, 2)]
	router.route([{"type": Events.ATTACK_LANDED, "entity": HERO, "cells": cells, "hit_count": 1, "profile": profile}])
	_expect(is_equal_approx(rig.shake_duration, 0.10) and is_equal_approx(rig.shake_strength, 2.6), "a swing that struck something shakes the screen for 0.10 s at strength 2.6")
	var quiet := _make_bridge()
	var quiet_rig: CameraRig = quiet[1]
	var quiet_router: EventRouter = quiet[2]
	quiet_router.route([{"type": Events.ATTACK_LANDED, "entity": HERO, "cells": cells, "hit_count": 0, "profile": profile}])
	_expect(is_zero_approx(quiet_rig.shake_time_left), "a swing that struck nothing does not shake it")


func _check_a_hit_taken_shakes_harder_with_the_damage() -> void:
	var parts := _make_bridge()
	var rig: CameraRig = parts[1]
	var router: EventRouter = parts[2]
	router.route([{"type": Events.DAMAGED, "entity": HERO, "amount": 1, "remaining": 2, "direction": Vector2i.LEFT, "source": PAWN, "tags": []}])
	_expect(is_equal_approx(rig.shake_duration, 0.16) and is_equal_approx(rig.shake_strength, 5.2), "a hit of 1 shakes the screen for 0.16 s at strength 5.2")
	var heavy := _make_bridge()
	var heavy_rig: CameraRig = heavy[1]
	var heavy_router: EventRouter = heavy[2]
	heavy_router.route([{"type": Events.DAMAGED, "entity": HERO, "amount": 3, "remaining": 0, "direction": Vector2i.ZERO, "source": 0, "tags": []}])
	_expect(is_equal_approx(heavy_rig.shake_strength, 7.2), "each point of damage adds a pixel of shake")


func _check_only_the_heroes_hurt_shakes_the_screen() -> void:
	var parts := _make_bridge()
	var rig: CameraRig = parts[1]
	var router: EventRouter = parts[2]
	router.route([{"type": Events.DAMAGED, "entity": PAWN, "amount": 2, "remaining": 1, "direction": Vector2i.UP, "source": HERO, "tags": []}])
	_expect(is_zero_approx(rig.shake_time_left), "an enemy being hurt does not shake the screen")


func _check_show_room_frames_the_grid() -> void:
	var parts := _make_bridge()
	var bridge: CameraBridge = parts[0]
	var rig: CameraRig = parts[1]
	var grid := EcsGrid.new()
	bridge.show_room(grid)
	_expect(rig.grid_world == grid, "show_room hands the rig the room's grid, so it clamps to the new board")


func _check_a_bridge_without_a_rig_is_silent() -> void:
	var bridge := CameraBridge.new()
	bridge.bind_world(HudSnapshot.new(), {})
	var router := EventRouter.new()
	bridge.register(router)
	router.route([{"type": Events.DAMAGED, "entity": 0, "amount": 1, "remaining": 1, "direction": Vector2i.ZERO, "source": 0, "tags": []}])
	bridge.show_room(EcsGrid.new())
	bridge.shake(0.1, 1.0)
	_expect(true, "a scene with no camera rig runs the same events without a word")
