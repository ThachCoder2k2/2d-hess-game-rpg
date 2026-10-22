extends UnboundTest

## Each room centres its own board (docs/game-base-plan.md D-02, D-30, 15 M3a): the grid origin used to
## be fixed at (64, 36), which only centres a 16x9 board in the 640x360 picture. An 18x9 arena from that
## origin runs flush against the right edge. Now EcsBoot.shape_grid() gives every room the origin that
## centres ITS board (x 64 for 16 wide, x 32 for 18 wide, y 36 for 9 rows), and a board larger than the
## view, which scrolls, keeps the fixed anchor on that axis. The six shipped rooms are all 16x9, so their
## origin did not move and every dump baseline is unchanged; this suite pins that as well.


func _init() -> void:
	suite_title = "ROOM ORIGIN TEST"
	_check_the_centred_origin()
	_check_the_view_size_comes_from_the_project()
	_check_shape_grid()
	_check_every_shipped_room_keeps_its_origin()
	_check_a_hero_is_placed_with_the_rooms_own_origin()
	finish()


func _check_the_centred_origin() -> void:
	var view := Vector2(640, 360)
	_expect(EcsGrid.centred_origin(Vector2i(16, 9), 32, view) == Vector2(64, 36), "a 16x9 board is centred at (64, 36): the origin the game always had")
	_expect(EcsGrid.centred_origin(Vector2i(18, 9), 32, view) == Vector2(32, 36), "an 18x9 arena is centred at (32, 36)")
	_expect(EcsGrid.centred_origin(Vector2i(18, 10), 32, view) == Vector2(32, 20), "an 18x10 board is centred at (32, 20)")
	_expect(EcsGrid.centred_origin(Vector2i(15, 9), 32, view) == Vector2(80, 36), "a 15x9 board is centred at (80, 36)")
	_expect(EcsGrid.centred_origin(Vector2i(20, 9), 32, view) == Vector2(0, 36), "a board exactly as wide as the view starts at x 0")
	_expect(EcsGrid.centred_origin(Vector2i(16, 9), 16, view) == Vector2(192, 108), "the cell size is a parameter: 16x9 cells of 16 px are centred at (192, 108)")
	_expect(EcsGrid.centred_origin(Vector2i(72, 40), 32, view) == EcsGrid.FALLBACK_ORIGIN, "a board larger than the view in both directions keeps the fixed anchor")
	_expect(EcsGrid.centred_origin(Vector2i(24, 9), 32, view) == Vector2(64, 36), "a board wider than the view keeps the anchor in x and is centred in y")
	_expect(EcsGrid.centred_origin(Vector2i(16, 12), 32, view) == Vector2(64, 36), "a board taller than the view keeps the anchor in y and is centred in x")
	_expect(EcsGrid.centred_origin(Vector2i(10, 12), 32, view) == Vector2(160, 36), "a narrow tall board keeps y at the anchor and is centred in x (160)")
	var every_fit_is_centred := true
	for columns in range(4, 21):
		for rows in range(3, 12):
			var origin := EcsGrid.centred_origin(Vector2i(columns, rows), 32, view)
			var board_centre := origin + Vector2(columns * 32, rows * 32) * 0.5
			if not board_centre.is_equal_approx(view * 0.5) or origin != origin.floor():
				every_fit_is_centred = false
	_expect(every_fit_is_centred, "every board from 4x3 to 20x11 cells that fits the view has its centre on the view's centre and a whole-pixel origin")
	_expect(EcsGrid.new().grid_origin == EcsGrid.FALLBACK_ORIGIN and EcsGrid.FALLBACK_ORIGIN == Vector2(64, 36), "a grid nobody shaped still has the origin it always had")


func _check_the_view_size_comes_from_the_project() -> void:
	var from_project := EcsBoot.project_view_size()
	_expect(from_project == Vector2(float(ProjectSettings.get_setting("display/window/size/viewport_width")), float(ProjectSettings.get_setting("display/window/size/viewport_height"))), "the view size is the base size in project.godot, read, not repeated in code")
	_expect(from_project.x > 0.0 and from_project.y > 0.0, "and is a real size (%s)" % from_project)
	_expect(EcsBootOptions.new().view_size == Vector2.ZERO, "boot options leave the view size at zero, meaning the project's own")


func _room(columns: int, rows: int) -> RoomEncounter:
	var room := RoomEncounter.new()
	room.board_size = Vector2i(columns, rows)
	return room


func _check_shape_grid() -> void:
	var small := EcsWorld.new()
	var small_room := _room(16, 9)
	EcsBoot.shape_grid(small, small_room)
	_expect(small.grid.bounds == Rect2i(0, 0, 16, 9) and small.grid.grid_origin == Vector2(64, 36), "a 16x9 room: bounds 16x9, origin (64, 36)")

	var arena := EcsWorld.new()
	var arena_room := _room(18, 9)
	EcsBoot.shape_grid(arena, arena_room)
	_expect(arena.grid.bounds == Rect2i(0, 0, 18, 9) and arena.grid.grid_origin == Vector2(32, 36), "an 18x9 arena: bounds 18x9, origin (32, 36)")
	EcsBoot.shape_grid(arena, arena_room)
	_expect(arena.grid.grid_origin == Vector2(32, 36), "shaping twice is the same as once (the shell shapes before boot, and boot shapes again)")
	_expect(arena.grid.world_to_cell(arena.grid.cell_to_world(Vector2i(0, 0))) == Vector2i.ZERO and arena.grid.world_to_cell(arena.grid.cell_to_world(Vector2i(17, 8))) == Vector2i(17, 8), "cells and world positions convert both ways from the new origin")
	_expect(arena.grid.cell_to_world(Vector2i.ZERO) == Vector2(48, 52), "the first cell of the arena is centred at (48, 52): origin plus half a cell")

	var wide := EcsWorld.new()
	var wide_room := _room(72, 40)
	EcsBoot.shape_grid(wide, wide_room)
	_expect(wide.grid.bounds == Rect2i(0, 0, 72, 40) and wide.grid.grid_origin == Vector2(64, 36), "a 72x40 world keeps the fixed anchor: nothing to centre when the camera scrolls")

	var generic := EcsWorld.new()
	var plain_node := Node2D.new()
	EcsBoot.shape_grid(generic, plain_node)
	_expect(generic.grid.bounds == Rect2i(0, 0, 16, 9) and generic.grid.grid_origin == Vector2(64, 36), "a room root that names no board_size keeps the default 16x9 board, centred")
	var untouched := EcsWorld.new()
	untouched.grid.grid_origin = Vector2(5, 7)
	EcsBoot.shape_grid(untouched, null)
	_expect(untouched.grid.grid_origin == Vector2(5, 7) and untouched.grid.bounds == Rect2i(0, 0, 16, 9), "no room leaves the grid exactly as it is")

	var other_view := EcsWorld.new()
	EcsBoot.shape_grid(other_view, _room(16, 9), Vector2(800, 450))
	_expect(other_view.grid.grid_origin == Vector2(144, 81), "a view of another size (800x450) centres the same board elsewhere")

	var zero_size := EcsWorld.new()
	var broken_room := _room(0, 9)
	EcsBoot.shape_grid(zero_size, broken_room)
	_expect(zero_size.grid.bounds == Rect2i(0, 0, 16, 9), "a room that asks for an empty board keeps the default one")
	for node: Node in [small_room, arena_room, wide_room, plain_node, broken_room]:
		node.free()
	for world: EcsWorld in [small, arena, wide, generic, untouched, other_view, zero_size]:
		world.free()


## Every room the shipped world graph lists gets the origin its width says (D-02): x 64 for a 16-wide room, which is
## what every room had until M5, and x 32 for an 18-wide boss arena, with y 36 for both. The kingdom fixture (no longer
## in the graph since M5) is 72x40, scrolls, and keeps (64, 36).
func _check_every_shipped_room_keeps_its_origin() -> void:
	var scene_by_zone := TestPaths.new(self).shipped_rooms_and_kingdom()
	_expect(scene_by_zone.size() >= 35, "setup: the world graph lists the plan's 34 rooms, and the kingdom fixture is added (%d scenes)" % scene_by_zone.size())
	var sixteen_by_nine := 0
	var eighteen_by_nine := 0
	var all_keep_the_origin := true
	for zone_id: StringName in scene_by_zone:
		var room := scene_by_zone[zone_id].instantiate()
		var world := EcsWorld.new()
		EcsBoot.shape_grid(world, room)
		var expected_origin := Vector2(32, 36) if world.grid.bounds == Rect2i(0, 0, 18, 9) else Vector2(64, 36)
		if world.grid.grid_origin != expected_origin:
			all_keep_the_origin = false
			printerr("  room %s starts at %s, not %s" % [zone_id, world.grid.grid_origin, expected_origin])
		if world.grid.bounds == Rect2i(0, 0, 16, 9):
			sixteen_by_nine += 1
		if world.grid.bounds == Rect2i(0, 0, 18, 9):
			eighteen_by_nine += 1
		room.free()
		world.free()
	_expect(all_keep_the_origin, "every room of the world graph starts at (64, 36) when it is 16 wide and at (32, 36) when it is 18 wide")
	_expect(sixteen_by_nine >= 28 and eighteen_by_nine == 6, "the graph holds 28 or more 16x9 rooms and the six 18x9 rooms of the plan (the five boss arenas and ub2: %d and %d)" % [sixteen_by_nine, eighteen_by_nine])


## The boot turns a hero's view position into a cell with the room's own origin, so a hero standing on the
## cell the 18x9 grid says gets that cell, and the old origin would have said another one.
func _check_a_hero_is_placed_with_the_rooms_own_origin() -> void:
	var paths := TestPaths.new(self)
	var player_scene := paths.load_scene(paths.actor_scene(&"player"))
	var arena_room := _room(18, 9)
	root.add_child(arena_room)
	var hero := player_scene.instantiate() as ActorView
	var cell := Vector2i(2, 3)
	var centred_origin := EcsGrid.centred_origin(Vector2i(18, 9), 32, EcsBoot.project_view_size())
	hero.position = centred_origin + Vector2(cell * 32) + Vector2(16, 16)
	root.add_child(hero)
	var world := EcsWorld.new()
	var cast := EcsBoot.boot(world, EcsBootOptions.for_scene(hero, arena_room))
	_expect(world.grid.grid_origin == centred_origin and world.grid.entity_at(cell) == cast["player"], "booting an 18x9 room puts a hero standing on cell (2, 3) of its centred board on that cell")
	_expect(EcsGrid.FALLBACK_ORIGIN != centred_origin and Vector2i(floor((hero.position.x - EcsGrid.FALLBACK_ORIGIN.x) / 32.0), floor((hero.position.y - EcsGrid.FALLBACK_ORIGIN.y) / 32.0)) != cell, "and the old fixed origin would have put the same view position on another cell")
	arena_room.queue_free()
	hero.queue_free()
	world.free()
