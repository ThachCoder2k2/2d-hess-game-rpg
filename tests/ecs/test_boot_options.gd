extends UnboundTest

## EcsBoot.boot(world, options) (docs/game-base-plan.md 14.1): the baker takes one options object
## instead of three to six positional arguments, so a need that arrives later (a saved player
## snapshot, a grid origin) is a new field with a neutral default and no call site changes. This
## suite holds the object's defaults and that each field still does what its positional argument did:
## the hero's fallback cell, the pickups the save says are taken, the gates it says are open.


func _init() -> void:
	suite_title = "BOOT OPTIONS TEST"
	var paths := TestPaths.new(self)

	var options := EcsBootOptions.new()
	_expect(options.player_view == null and options.room_root == null, "a fresh options object names no hero and no room")
	_expect(options.fallback_player_cell == Vector2i(3, 7), "the hero's fallback cell defaults to (3, 7), as the positional argument did")
	_expect(options.skipped_pickup_names.is_empty() and options.opened_gate_ids.is_empty(), "no pickup is taken and no gate is open by default")

	var room_placeholder := Node2D.new()
	var scene_options := EcsBootOptions.for_scene(null, room_placeholder)
	_expect(scene_options.room_root == room_placeholder and scene_options.player_view == null and scene_options.fallback_player_cell == Vector2i(3, 7), "for_scene sets the hero and the room and leaves the rest at its defaults")
	room_placeholder.free()

	# A world with no hero and no room boots to an empty cast.
	var empty_world := EcsWorld.new()
	var empty_cast := EcsBoot.boot(empty_world, EcsBootOptions.new())
	_expect(empty_cast["player"] == 0 and empty_cast["enemies"].is_empty(), "booting with empty options spawns nothing")
	empty_world.free()

	var encounter_scene := paths.load_scene(paths.first_encounter_scene())
	var player_scene := paths.load_scene(paths.actor_scene(&"player"))

	var all_pickups_world := EcsWorld.new()
	var all_pickups_room := encounter_scene.instantiate()
	root.add_child(all_pickups_room)
	var all_pickups_cast := EcsBoot.boot(all_pickups_world, EcsBootOptions.for_scene(null, all_pickups_room))
	var pickup_marker_names: Array = all_pickups_cast["pickup_name_by_entity"].values()
	_expect(pickup_marker_names.size() == 2, "setup: the first-encounter room has two pickup markers")

	var taken_world := EcsWorld.new()
	var taken_room := encounter_scene.instantiate()
	root.add_child(taken_room)
	var taken_options := EcsBootOptions.for_scene(null, taken_room)
	taken_options.skipped_pickup_names = [pickup_marker_names[0]]
	var taken_cast := EcsBoot.boot(taken_world, taken_options)
	_expect(taken_cast["pickup_name_by_entity"].size() == 1 and pickup_marker_names[0] not in taken_cast["pickup_name_by_entity"].values(), "a pickup named in skipped_pickup_names does not respawn")

	var off_board_world := EcsWorld.new()
	var off_board_room := encounter_scene.instantiate()
	root.add_child(off_board_room)
	var stray_hero := player_scene.instantiate() as ActorView
	stray_hero.position = Vector2(-500.0, -500.0)
	root.add_child(stray_hero)
	var off_board_options := EcsBootOptions.for_scene(stray_hero, off_board_room)
	off_board_options.fallback_player_cell = Vector2i(5, 4)
	var off_board_cast := EcsBoot.boot(off_board_world, off_board_options)
	_expect(off_board_world.grid.entity_at(Vector2i(5, 4)) == off_board_cast["player"] and off_board_cast["player"] != 0, "a hero whose view stands off the board starts on fallback_player_cell")

	for node: Node in [all_pickups_room, taken_room, off_board_room, stray_hero]:
		node.queue_free()
	for world: EcsWorld in [all_pickups_world, taken_world, off_board_world]:
		world.free()
	finish()
