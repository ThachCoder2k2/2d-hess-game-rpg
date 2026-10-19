extends UnboundTest

## Cell kinds (docs/game-base-plan.md 5.11, 15 M3a): the grid knows what each cell is made of
## (EcsGrid.cell_kind_by_cell, the vocabulary in CellKinds), blocked_cells is derived from it, the
## TileSets' `kind` custom-data layer authors it next to `solid`, EcsBoot reads it, and a paint tool
## writes it. The promise of the milestone is that nothing changed for the rooms that exist: every wall
## of the six shipped rooms is still exactly the cell a `solid` tile painted, and so is every cell of the
## 72x40 fixture. This suite holds that promise and the rules of the new vocabulary.

const ProjectFiles := preload("res://tests/architecture/project_files.gd")
const CellKindPainter := preload("res://tools/cell_kind_painter.gd")
const WorldDumper := preload("res://tools/world_dumper.gd")

## The tiles of the TileSet the suite builds in memory, by name -> atlas column.
const TILE_FLOOR := 0
const TILE_WALL_BY_SOLID := 1
const TILE_WALL_BY_KIND := 2
const TILE_GAP := 3
const TILE_LEAPABLE_BLOCK := 4
const TILE_CHALK := 5
const TILE_CORRUPTION := 6
const TILE_SOLID_BUT_CHALK := 7
const TILE_COUNT := 8


func _init() -> void:
	suite_title = "GRID CELL KINDS TEST"
	_check_the_vocabulary()
	_check_a_fresh_grid()
	_check_set_cell_kind()
	_check_blocked_cells_is_always_derived()
	_check_what_a_wall_does_to_a_piece()
	_check_gates_and_add_block()
	_check_the_layout_version()
	_check_cells_of_kind()
	_check_how_a_tile_says_its_kind()
	_check_booting_a_painted_room()
	_check_the_painter_tool()
	_check_the_shipped_tilesets()
	_check_every_shipped_room_keeps_its_walls()
	_check_the_world_dump()
	_check_only_the_grid_writes_the_terrain()
	finish()


# --------------------------------------------------------------------------- the vocabulary
func _check_the_vocabulary() -> void:
	var expected_kinds: Array[StringName] = [&"floor", &"wall", &"gap", &"leapable_block", &"chalk", &"corruption"]
	var listed_kinds: Array[StringName] = []
	listed_kinds.assign(CellKinds.RULES_BY_KIND.keys())
	_expect(listed_kinds == expected_kinds, "the kinds are floor, wall, gap, leapable_block, chalk and corruption, in that order (plan 5.11)")
	var every_row_is_complete := true
	for kind: StringName in CellKinds.RULES_BY_KIND:
		var rules: Dictionary = CellKinds.RULES_BY_KIND[kind]
		if not (rules.get("walkable") is bool and rules.get("stops_rays") is bool and rules.get("leapable") is bool and rules.get("about") is String and not String(rules["about"]).is_empty()):
			every_row_is_complete = false
	_expect(every_row_is_complete, "every kind has the three rules (walkable, stops_rays, leapable) and a sentence saying what it is")
	_expect(CellKinds.FLOOR == &"floor" and CellKinds.WALL == &"wall" and CellKinds.GAP == &"gap" and CellKinds.LEAPABLE_BLOCK == &"leapable_block" and CellKinds.CHALK == &"chalk" and CellKinds.CORRUPTION == &"corruption", "the constants carry the ids the plan names")

	# The rules, as the plan states them.
	_expect(CellKinds.is_walkable(CellKinds.FLOOR) and CellKinds.is_walkable(CellKinds.CHALK) and CellKinds.is_walkable(CellKinds.CORRUPTION), "floor, chalk and corruption can be walked on")
	_expect(not CellKinds.is_walkable(CellKinds.WALL) and not CellKinds.is_walkable(CellKinds.GAP) and not CellKinds.is_walkable(CellKinds.LEAPABLE_BLOCK), "a wall, a gap and a leapable block cannot")
	_expect(CellKinds.stops_rays(CellKinds.WALL) and CellKinds.stops_rays(CellKinds.LEAPABLE_BLOCK), "a wall and a leapable block stop a ray (a block is cover)")
	_expect(not CellKinds.stops_rays(CellKinds.GAP) and not CellKinds.stops_rays(CellKinds.FLOOR) and not CellKinds.stops_rays(CellKinds.CHALK) and not CellKinds.stops_rays(CellKinds.CORRUPTION), "a ray flies over a gap, chalk, corruption and floor")
	_expect(not CellKinds.is_leapable(CellKinds.WALL), "a leap cannot cross a wall")
	_expect(CellKinds.is_leapable(CellKinds.GAP) and CellKinds.is_leapable(CellKinds.LEAPABLE_BLOCK) and CellKinds.is_leapable(CellKinds.FLOOR), "a leap crosses a gap, a leapable block and floor")
	_expect(not CellKinds.is_known(&"lava") and not CellKinds.is_walkable(&"lava") and CellKinds.stops_rays(&"lava") and not CellKinds.is_leapable(&"lava"), "a kind nobody declared is not known, cannot be walked on or leapt, and stops rays: the safe answer on every count")
	var stopping := CellKinds.default_ray_stop_kinds()
	_expect(stopping == [CellKinds.WALL, CellKinds.LEAPABLE_BLOCK], "the kinds that stop a ray by default are read from the table: the wall and the leapable block (%s)" % [stopping])


# --------------------------------------------------------------------------- a fresh grid
func _check_a_fresh_grid() -> void:
	var grid := EcsGrid.new()
	_expect(grid.cell_kind_by_cell.is_empty() and grid.blocked_cells.is_empty() and grid.cell_effect_by_cell.is_empty(), "a fresh grid lists no kinds, no blocked cells and no cell effects")
	_expect(grid.layout_version == 0, "a fresh grid is at layout version 0")
	_expect(grid.kind_at(Vector2i(3, 3)) == CellKinds.FLOOR and grid.kind_at(Vector2i(-5, 40)) == CellKinds.FLOOR, "a cell the grid lists nothing about is floor, on the board or off it")
	_expect(grid.is_walkable(Vector2i(3, 3)) and not grid.is_walkable(Vector2i(-1, 0)), "floor is walkable and the outside of the board is not")
	var other := EcsGrid.new()
	grid.set_cell_kind(Vector2i(2, 2), CellKinds.GAP)
	grid.cell_effect_by_cell[Vector2i(2, 2)] = {"effect": &"chalk", "kind_before": CellKinds.GAP, "time_left": 12.0}
	_expect(other.cell_kind_by_cell.is_empty() and other.cell_effect_by_cell.is_empty() and other.layout_version == 0, "two grids never share their kinds, effects or version")


# --------------------------------------------------------------------------- set_cell_kind
func _check_set_cell_kind() -> void:
	var grid := EcsGrid.new()
	var cell := Vector2i(4, 4)
	for kind: StringName in CellKinds.RULES_BY_KIND:
		var fresh := EcsGrid.new()
		_expect(fresh.set_cell_kind(cell, kind), "setting a %s cell is accepted" % kind)
		var wants_blocked := not CellKinds.is_walkable(kind)
		_expect(fresh.kind_at(cell) == kind and fresh.blocked_cells.has(cell) == wants_blocked and fresh.is_walkable(cell) == not wants_blocked, "a %s cell reads back as %s and is %s" % [kind, kind, "blocked" if wants_blocked else "walkable"])
		_expect(fresh.cell_kind_by_cell.has(cell) == (kind != CellKinds.FLOOR), "floor is stored as the absence of an entry, any other kind as an entry (%s)" % kind)

	_expect(grid.set_cell_kind(cell, CellKinds.WALL) and grid.blocked_cells.has(cell), "a wall blocks its cell")
	_expect(grid.set_cell_kind(cell, CellKinds.GAP) and grid.blocked_cells.has(cell) and grid.kind_at(cell) == CellKinds.GAP, "a wall that becomes a gap stays blocked, as a gap")
	_expect(grid.set_cell_kind(cell, CellKinds.CHALK) and not grid.blocked_cells.has(cell) and grid.kind_at(cell) == CellKinds.CHALK, "a gap that becomes chalk is walkable again (Chalk Path)")
	_expect(grid.set_cell_kind(cell, CellKinds.FLOOR) and not grid.cell_kind_by_cell.has(cell) and not grid.blocked_cells.has(cell), "chalk that becomes floor leaves no entry behind")

	_expect(not grid.set_cell_kind(Vector2i(16, 4), CellKinds.WALL) and not grid.set_cell_kind(Vector2i(-1, 0), CellKinds.GAP), "a cell off the board takes no kind")
	_expect(not grid.set_cell_kind(cell, &"lava") and grid.kind_at(cell) == CellKinds.FLOOR, "a kind nobody declared is refused and changes nothing")
	_expect(grid.cell_kind_by_cell.is_empty() and grid.blocked_cells.is_empty(), "and the refused calls left no trace")


# --------------------------------------------------------------------------- derived, always
## blocked_cells is derived from cell_kind_by_cell: after any sequence of changes it is exactly the set of
## cells whose kind cannot be walked on. A fixed random sequence of 4000 changes (a seed, so every run is
## the same) checks that after every one of them.
func _check_blocked_cells_is_always_derived() -> void:
	var grid := EcsGrid.new()
	var generator := RandomNumberGenerator.new()
	generator.seed = 20261019
	var kinds: Array = CellKinds.RULES_BY_KIND.keys()
	var always_derived := true
	var version_always_follows := true
	for _step in range(4000):
		var cell := Vector2i(generator.randi_range(0, 15), generator.randi_range(0, 8))
		var kind: StringName = kinds[generator.randi_range(0, kinds.size() - 1)]
		var kind_before := grid.kind_at(cell)
		var version_before := grid.layout_version
		grid.set_cell_kind(cell, kind)
		if (grid.layout_version != version_before) != (kind_before != kind):
			version_always_follows = false
		var derived: Dictionary = {}
		for listed_cell: Vector2i in grid.cell_kind_by_cell:
			if not CellKinds.is_walkable(grid.cell_kind_by_cell[listed_cell]):
				derived[listed_cell] = true
		if derived != grid.blocked_cells or grid.cell_kind_by_cell.values().has(CellKinds.FLOOR):
			always_derived = false
			break
	_expect(always_derived, "after each of 4000 random changes blocked_cells equals the cells whose kind cannot be walked on, and floor is never stored")
	_expect(version_always_follows, "and the layout version moved on exactly the changes that changed a kind")


# --------------------------------------------------------------------------- pieces and walls
func _check_what_a_wall_does_to_a_piece() -> void:
	var grid := EcsGrid.new()
	grid.register_entity(1, Vector2i(2, 2))
	grid.set_cell_kind(Vector2i(3, 2), CellKinds.GAP)
	grid.set_cell_kind(Vector2i(2, 3), CellKinds.LEAPABLE_BLOCK)
	grid.set_cell_kind(Vector2i(1, 2), CellKinds.CHALK)
	_expect(not grid.can_begin_move(1, Vector2i(3, 2)), "a piece cannot step into a gap")
	_expect(not grid.can_begin_move(1, Vector2i(2, 3)), "a piece cannot step onto a leapable block")
	_expect(grid.can_begin_move(1, Vector2i(1, 2)) and grid.begin_move(1, Vector2i(1, 2)), "a piece can step onto chalk")
	grid.finish_move(1, Vector2i(1, 2))
	_expect(not grid.register_entity(2, Vector2i(3, 2)), "nothing is placed in a gap")

	var around := grid.get_grid_path(1, Vector2i(1, 2), Vector2i(4, 2))
	_expect(not around.is_empty() and Vector2i(3, 2) not in around, "the pathfinder goes round a gap (%s)" % [around])
	grid.set_cell_kind(Vector2i(3, 2), CellKinds.CHALK)
	var across := grid.get_grid_path(1, Vector2i(1, 2), Vector2i(4, 2))
	_expect(across.size() == 4 and Vector2i(3, 2) in across, "and over the same cell once it is chalk: the shortest way is straight across (%s)" % [across])

	# A wall never grows under a piece or under a piece about to arrive; chalk may.
	var crowded := EcsGrid.new()
	crowded.register_entity(1, Vector2i(5, 5))
	crowded.register_entity(2, Vector2i(8, 5))
	crowded.begin_move(2, Vector2i(8, 6))
	_expect(not crowded.set_cell_kind(Vector2i(5, 5), CellKinds.GAP) and not crowded.add_block(Vector2i(5, 5)), "a gap or a wall cannot be put under a piece")
	_expect(not crowded.set_cell_kind(Vector2i(8, 6), CellKinds.WALL), "or on the cell a piece has reserved")
	_expect(crowded.kind_at(Vector2i(5, 5)) == CellKinds.FLOOR and crowded.blocked_cells.is_empty(), "and the refusals changed nothing")
	_expect(crowded.set_cell_kind(Vector2i(5, 5), CellKinds.CHALK) and crowded.set_cell_kind(Vector2i(8, 6), CellKinds.CORRUPTION), "chalk and corruption can be laid under a piece, because they do not take its cell away")


func _check_gates_and_add_block() -> void:
	var grid := EcsGrid.new()
	_expect(grid.add_block(Vector2i(6, 6)) and grid.kind_at(Vector2i(6, 6)) == CellKinds.WALL, "add_block makes a wall (the older name for the same thing)")
	_expect(grid.add_block(Vector2i(6, 6)), "and says yes again for a cell that already is a wall, as it always did")
	grid.gate_by_cell[Vector2i(6, 6)] = {"id": &"shortcut", "opens_from": Vector2i.LEFT}
	var version_before := grid.layout_version
	grid.open_gate(Vector2i(6, 6))
	_expect(grid.kind_at(Vector2i(6, 6)) == CellKinds.FLOOR and grid.is_walkable(Vector2i(6, 6)) and not grid.gate_by_cell.has(Vector2i(6, 6)), "an opened gate is floor, walkable and no longer a gate")
	_expect(grid.layout_version == version_before + 1, "and opening it is a change of the layout")


func _check_the_layout_version() -> void:
	var grid := EcsGrid.new()
	grid.set_cell_kind(Vector2i(1, 1), CellKinds.WALL)
	_expect(grid.layout_version == 1, "the first wall is layout version 1")
	grid.set_cell_kind(Vector2i(1, 1), CellKinds.WALL)
	_expect(grid.layout_version == 1, "putting the same kind where it already is changes nothing, and counts for nothing")
	grid.set_cell_kind(Vector2i(2, 2), CellKinds.CHALK)
	_expect(grid.layout_version == 2, "a change of kind that keeps a cell walkable counts too: the kind is part of the layout")
	grid.set_cell_kind(Vector2i(40, 40), CellKinds.WALL)
	grid.set_cell_kind(Vector2i(2, 2), &"lava")
	_expect(grid.layout_version == 2, "a refused change does not count")
	grid.bounds = Rect2i(0, 0, 18, 9)
	_expect(grid.layout_version == 3, "a new board size is a change of the layout (the cached pathfinder covers the board)")
	grid.bounds = Rect2i(0, 0, 18, 9)
	_expect(grid.layout_version == 3, "the same board size again is not")
	grid.register_entity(1, Vector2i(5, 5))
	grid.begin_move(1, Vector2i(5, 6))
	grid.finish_move(1, Vector2i(5, 6))
	_expect(grid.layout_version == 3, "pieces moving about is not a change of the layout: only terrain is")


func _check_cells_of_kind() -> void:
	var grid := EcsGrid.new()
	grid.bounds = Rect2i(0, 0, 4, 3)
	for cell: Vector2i in [Vector2i(3, 2), Vector2i(0, 1), Vector2i(2, 1), Vector2i(1, 0)]:
		grid.set_cell_kind(cell, CellKinds.GAP)
	grid.set_cell_kind(Vector2i(0, 0), CellKinds.WALL)
	_expect(grid.cells_of_kind(CellKinds.GAP) == [Vector2i(1, 0), Vector2i(0, 1), Vector2i(2, 1), Vector2i(3, 2)], "the gaps, row by row and left to right: %s" % [grid.cells_of_kind(CellKinds.GAP)])
	_expect(grid.cells_of_kind(CellKinds.WALL) == [Vector2i(0, 0)] and grid.cells_of_kind(CellKinds.CHALK).is_empty(), "the walls, and no chalk")
	_expect(grid.cells_of_kind(CellKinds.FLOOR).size() == 12 - 5 and Vector2i(0, 0) not in grid.cells_of_kind(CellKinds.FLOOR), "the floor is every cell of the 4x3 board the grid lists nothing for (7)")


# --------------------------------------------------------------------------- how a tile says it
## A TileSet with the two layers of the kingdom TileSet (`solid`, bool; `kind`, String) and eight tiles,
## one atlas column each: floor, a wall by `solid`, a wall by `kind`, a gap, a leapable block, chalk,
## corruption, and a tile that contradicts itself (solid, but kind chalk).
func _kinded_tile_set(with_kind_layer := true) -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(32, 32)
	tile_set.add_custom_data_layer()
	tile_set.set_custom_data_layer_name(0, CellKinds.TILE_SOLID_LAYER)
	tile_set.set_custom_data_layer_type(0, TYPE_BOOL)
	if with_kind_layer:
		tile_set.add_custom_data_layer()
		tile_set.set_custom_data_layer_name(1, CellKinds.TILE_KIND_LAYER)
		tile_set.set_custom_data_layer_type(1, TYPE_STRING)
	var atlas_source := TileSetAtlasSource.new()
	atlas_source.texture = ImageTexture.create_from_image(Image.create(32 * TILE_COUNT, 32, false, Image.FORMAT_RGBA8))
	atlas_source.texture_region_size = Vector2i(32, 32)
	for column in range(TILE_COUNT):
		atlas_source.create_tile(Vector2i(column, 0))
	tile_set.add_source(atlas_source)
	_tile(atlas_source, TILE_WALL_BY_SOLID).set_custom_data(CellKinds.TILE_SOLID_LAYER, true)
	_tile(atlas_source, TILE_SOLID_BUT_CHALK).set_custom_data(CellKinds.TILE_SOLID_LAYER, true)
	if with_kind_layer:
		_tile(atlas_source, TILE_WALL_BY_KIND).set_custom_data(CellKinds.TILE_KIND_LAYER, "wall")
		_tile(atlas_source, TILE_GAP).set_custom_data(CellKinds.TILE_KIND_LAYER, "gap")
		_tile(atlas_source, TILE_LEAPABLE_BLOCK).set_custom_data(CellKinds.TILE_KIND_LAYER, "leapable_block")
		_tile(atlas_source, TILE_CHALK).set_custom_data(CellKinds.TILE_KIND_LAYER, "chalk")
		_tile(atlas_source, TILE_CORRUPTION).set_custom_data(CellKinds.TILE_KIND_LAYER, "corruption")
		_tile(atlas_source, TILE_SOLID_BUT_CHALK).set_custom_data(CellKinds.TILE_KIND_LAYER, "chalk")
	return tile_set


func _tile(atlas_source: TileSetAtlasSource, column: int) -> TileData:
	return atlas_source.get_tile_data(Vector2i(column, 0), 0)


func _check_how_a_tile_says_its_kind() -> void:
	var tile_set := _kinded_tile_set()
	var atlas_source := tile_set.get_source(0) as TileSetAtlasSource
	var expected: Dictionary = {
		TILE_FLOOR: CellKinds.FLOOR,
		TILE_WALL_BY_SOLID: CellKinds.WALL,
		TILE_WALL_BY_KIND: CellKinds.WALL,
		TILE_GAP: CellKinds.GAP,
		TILE_LEAPABLE_BLOCK: CellKinds.LEAPABLE_BLOCK,
		TILE_CHALK: CellKinds.CHALK,
		TILE_CORRUPTION: CellKinds.CORRUPTION,
		TILE_SOLID_BUT_CHALK: CellKinds.CHALK,
	}
	var all_read_right := true
	for column: int in expected:
		var read := CellKinds.kind_of_tile(tile_set, _tile(atlas_source, column))
		if read != expected[column]:
			all_read_right = false
			printerr("  tile %d reads as %s, expected %s" % [column, read, expected[column]])
	_expect(all_read_right, "a tile says what its cell is: `kind` when filled in, else `solid` makes a wall, else floor (8 tiles)")
	_expect(CellKinds.kind_of_tile(tile_set, _tile(atlas_source, TILE_SOLID_BUT_CHALK)) == CellKinds.CHALK, "when `kind` and `solid` disagree, `kind` wins")

	# A TileSet that only knows `solid` (every TileSet before M3a) reads exactly as it always did.
	var old_style := _kinded_tile_set(false)
	var old_source := old_style.get_source(0) as TileSetAtlasSource
	_expect(not old_style.has_custom_data_layer_by_name(CellKinds.TILE_KIND_LAYER), "setup: this TileSet has no kind layer")
	_expect(CellKinds.kind_of_tile(old_style, _tile(old_source, TILE_FLOOR)) == CellKinds.FLOOR and CellKinds.kind_of_tile(old_style, _tile(old_source, TILE_WALL_BY_SOLID)) == CellKinds.WALL, "without a kind layer, `solid` alone decides: wall or floor")
	var bare := TileSet.new()
	var bare_source := TileSetAtlasSource.new()
	bare_source.texture = ImageTexture.create_from_image(Image.create(32, 32, false, Image.FORMAT_RGBA8))
	bare_source.texture_region_size = Vector2i(32, 32)
	bare_source.create_tile(Vector2i.ZERO)
	bare.add_source(bare_source)
	_expect(CellKinds.kind_of_tile(bare, bare_source.get_tile_data(Vector2i.ZERO, 0)) == CellKinds.FLOOR, "and a TileSet with no custom data at all (the playground one) is all floor")


# --------------------------------------------------------------------------- a painted room boots
func _room_with_tilemap(tile_set: TileSet, painted: Dictionary) -> Node2D:
	var room := RoomEncounter.new()
	var room_art := Node2D.new()
	room_art.name = "RoomArt"
	room.add_child(room_art)
	var tilemap := TileMapLayer.new()
	tilemap.name = "TileMap"
	tilemap.tile_set = tile_set
	room_art.add_child(tilemap)
	for cell: Vector2i in painted:
		tilemap.set_cell(cell, 0, Vector2i(int(painted[cell]), 0))
	return room


func _check_booting_a_painted_room() -> void:
	var tile_set := _kinded_tile_set()
	var painted: Dictionary = {
		Vector2i(0, 0): TILE_WALL_BY_SOLID, Vector2i(1, 0): TILE_WALL_BY_KIND, Vector2i(2, 0): TILE_GAP,
		Vector2i(3, 0): TILE_LEAPABLE_BLOCK, Vector2i(4, 0): TILE_CHALK, Vector2i(5, 0): TILE_CORRUPTION,
		Vector2i(6, 0): TILE_FLOOR, Vector2i(7, 0): TILE_SOLID_BUT_CHALK,
	}
	var room := _room_with_tilemap(tile_set, painted)
	var world := EcsWorld.new()
	EcsBoot.shape_grid(world, room)
	EcsBoot.apply_tile_kinds(world, room)
	var grid := world.grid
	_expect(grid.kind_at(Vector2i(0, 0)) == CellKinds.WALL and grid.kind_at(Vector2i(1, 0)) == CellKinds.WALL, "a solid tile and a tile of kind wall both boot as walls")
	_expect(grid.kind_at(Vector2i(2, 0)) == CellKinds.GAP and grid.kind_at(Vector2i(3, 0)) == CellKinds.LEAPABLE_BLOCK, "a gap tile boots as a gap and a leapable-block tile as a leapable block")
	_expect(grid.kind_at(Vector2i(4, 0)) == CellKinds.CHALK and grid.kind_at(Vector2i(5, 0)) == CellKinds.CORRUPTION and grid.kind_at(Vector2i(7, 0)) == CellKinds.CHALK, "chalk and corruption boot as themselves, and the self-contradicting tile as chalk")
	_expect(not grid.cell_kind_by_cell.has(Vector2i(6, 0)) and grid.kind_at(Vector2i(6, 0)) == CellKinds.FLOOR, "a floor tile adds nothing to the grid")
	var expected_blocked: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	var blocked_sorted: Array = grid.blocked_cells.keys()
	blocked_sorted.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x)
	_expect(blocked_sorted == expected_blocked, "of the eight cells exactly the wall, the wall, the gap and the block are blocked (%s)" % [blocked_sorted])
	_expect(grid.layout_version == 7, "booting the 7 non-floor tiles moved the layout version 7 times")

	var no_tilemap := EcsWorld.new()
	var bare_room := Node2D.new()
	EcsBoot.apply_tile_kinds(no_tilemap, bare_room)
	_expect(no_tilemap.grid.cell_kind_by_cell.is_empty() and no_tilemap.grid.layout_version == 0, "a room with no tilemap boots no terrain")
	room.free()
	bare_room.free()
	world.free()
	no_tilemap.free()


# --------------------------------------------------------------------------- the paint tool
func _check_the_painter_tool() -> void:
	var tile_set := _kinded_tile_set()
	var painter := CellKindPainter.new(tile_set)
	_expect(painter.paintable_kinds() == [CellKinds.FLOOR, CellKinds.WALL, CellKinds.GAP, CellKinds.LEAPABLE_BLOCK, CellKinds.CHALK, CellKinds.CORRUPTION], "the painter finds a tile for every kind in this TileSet (%s)" % [painter.paintable_kinds()])
	_expect(painter.tile_count_for(CellKinds.WALL) == 2 and painter.tile_count_for(CellKinds.CHALK) == 2 and painter.tile_count_for(CellKinds.GAP) == 1, "two tiles read as wall, two as chalk and one as a gap")

	var layer := TileMapLayer.new()
	layer.tile_set = tile_set
	var painted: Dictionary = {
		Vector2i(0, 0): CellKinds.FLOOR, Vector2i(1, 0): CellKinds.WALL, Vector2i(2, 0): CellKinds.GAP,
		Vector2i(3, 0): CellKinds.LEAPABLE_BLOCK, Vector2i(4, 0): CellKinds.CHALK, Vector2i(5, 0): CellKinds.CORRUPTION,
	}
	var no_problem := true
	for cell: Vector2i in painted:
		if not painter.paint(layer, cell, painted[cell]).is_empty():
			no_problem = false
	_expect(no_problem, "every kind can be painted by naming only the kind")
	_expect(painter.kinds_by_cell(layer) == painted, "and reading the layer back gives the kinds that were meant, cell for cell")

	# Painted, then booted: the kinds the tool wrote are the kinds the grid ends up with.
	var room := _room_with_tilemap(tile_set, {})
	var tilemap := room.get_node("RoomArt/TileMap") as TileMapLayer
	var painter_for_room := CellKindPainter.new(tilemap.tile_set)
	for cell: Vector2i in painted:
		painter_for_room.paint(tilemap, cell, painted[cell])
	var world := EcsWorld.new()
	EcsBoot.apply_tile_kinds(world, room)
	var booted_matches := true
	for cell: Vector2i in painted:
		if world.grid.kind_at(cell) != painted[cell]:
			booted_matches = false
	_expect(booted_matches, "a layer painted by kind boots into a grid with the same kinds")
	room.free()

	_expect(painter.paint(layer, Vector2i(9, 9), CellKinds.WALL, Vector2i(TILE_WALL_BY_KIND, 0)).is_empty() and layer.get_cell_atlas_coords(Vector2i(9, 9)) == Vector2i(TILE_WALL_BY_KIND, 0), "a preferred tile of the right kind is the one painted (the art a tool chose)")
	var wrong_tile := painter.paint(layer, Vector2i(9, 8), CellKinds.WALL, Vector2i(TILE_GAP, 0))
	_expect(not wrong_tile.is_empty() and wrong_tile.contains("gap") and not layer.get_used_cells().has(Vector2i(9, 8)), "a preferred tile that is not of the kind is refused with a sentence that names both, and nothing is painted: %s" % wrong_tile)
	var no_such_kind := painter.paint(layer, Vector2i(9, 7), &"lava")
	_expect(not no_such_kind.is_empty() and not layer.get_used_cells().has(Vector2i(9, 7)), "a kind that does not exist is refused")

	var bare_set := _kinded_tile_set(false)
	var bare_painter := CellKindPainter.new(bare_set)
	var bare_layer := TileMapLayer.new()
	bare_layer.tile_set = bare_set
	var no_art := bare_painter.paint(bare_layer, Vector2i.ZERO, CellKinds.GAP)
	_expect(not bare_painter.has_tile_for(CellKinds.GAP) and no_art.contains("no tile") and bare_layer.get_used_cells().is_empty(), "a TileSet with no gap tile cannot paint a gap, and says why: %s" % no_art)
	_expect(bare_painter.has_tile_for(CellKinds.WALL) and bare_painter.has_tile_for(CellKinds.FLOOR), "but it still paints walls (by solid) and floor")
	_expect(not painter.paint(bare_layer, Vector2i.ZERO, CellKinds.FLOOR).is_empty(), "and a painter refuses a layer that uses another TileSet than its own")
	layer.free()
	bare_layer.free()


# --------------------------------------------------------------------------- shipped data
func _check_the_shipped_tilesets() -> void:
	var paths := TestPaths.new(self)
	var tilesets: Dictionary = {
		"content/tilesets/kingdom": ContentDb.fetch(&"tilesets", &"kingdom") as TileSet,
		"tests/fixtures/the_kingdom": paths.load_resource(paths.kingdom_fixture_tileset()) as TileSet,
	}
	for label: String in tilesets:
		var tile_set: TileSet = tilesets[label]
		if not _expect(tile_set != null, "setup: the TileSet %s loads" % label):
			continue
		_expect(tile_set.has_custom_data_layer_by_name(CellKinds.TILE_SOLID_LAYER) and tile_set.has_custom_data_layer_by_name(CellKinds.TILE_KIND_LAYER), "%s carries both layers: solid, and kind next to it" % label)
		var kind_layer := tile_set.get_custom_data_layer_by_name(CellKinds.TILE_KIND_LAYER)
		_expect(kind_layer >= 0 and tile_set.get_custom_data_layer_type(kind_layer) == TYPE_STRING, "%s: the kind layer holds text (the id of a kind)" % label)
		var problems := PackedStringArray()
		var tile_count := 0
		for source_index in tile_set.get_source_count():
			var atlas_source := tile_set.get_source(tile_set.get_source_id(source_index)) as TileSetAtlasSource
			for tile_index in atlas_source.get_tiles_count():
				var atlas_coords := atlas_source.get_tile_id(tile_index)
				for alternative_index in atlas_source.get_alternative_tiles_count(atlas_coords):
					var tile_data := atlas_source.get_tile_data(atlas_coords, atlas_source.get_alternative_tile_id(atlas_coords, alternative_index))
					tile_count += 1
					var painted_kind := StringName(String(tile_data.get_custom_data(CellKinds.TILE_KIND_LAYER)))
					if not painted_kind.is_empty() and not CellKinds.is_known(painted_kind):
						problems.append("tile %s names the unknown kind '%s'" % [atlas_coords, painted_kind])
					if bool(tile_data.get_custom_data(CellKinds.TILE_SOLID_LAYER)) and not painted_kind.is_empty() and CellKinds.is_walkable(painted_kind):
						problems.append("tile %s is solid but its kind '%s' can be walked on" % [atlas_coords, painted_kind])
		_expect(tile_count >= 7 and problems.is_empty(), "%s: all %d tiles name a kind that exists or none, and none is solid while walkable (%s)" % [label, tile_count, "; ".join(problems)])


## The promise of the milestone. For every room the world graph lists (the six Stage 1 rooms and the 72x40
## fixture): the cells the booted grid blocks are exactly the cells whose painted tile has solid = true,
## which is what the grid blocked before kinds existed, and each of them is a wall. Read straight from the
## tilemap here, not through CellKinds, so it can disagree.
func _check_every_shipped_room_keeps_its_walls() -> void:
	var world_graph := ContentDb.world()
	if not _expect(world_graph != null and world_graph.zone_scene_by_id.size() >= 6, "setup: the world graph lists at least the six Stage 1 rooms"):
		return
	var rooms_checked := 0
	var walls_in_all_rooms := 0
	var every_room_equal := true
	var only_walls := true
	for zone_id: StringName in world_graph.zone_scene_by_id:
		var room := world_graph.get_zone_scene(zone_id).instantiate()
		var world := EcsWorld.new()
		EcsBoot.shape_grid(world, room)
		EcsBoot.apply_tile_kinds(world, room)
		var tilemap := room.get_node_or_null("RoomArt/TileMap") as TileMapLayer
		var solid_cells: Dictionary = {}
		if tilemap != null:
			for cell in tilemap.get_used_cells():
				var tile_data := tilemap.get_cell_tile_data(cell)
				if tile_data != null and bool(tile_data.get_custom_data("solid")) and world.grid.is_inside(cell):
					solid_cells[cell] = true
		if solid_cells != world.grid.blocked_cells:
			every_room_equal = false
			printerr("  room %s: %d solid tiles, %d blocked cells" % [zone_id, solid_cells.size(), world.grid.blocked_cells.size()])
		for cell: Vector2i in world.grid.cell_kind_by_cell:
			if world.grid.cell_kind_by_cell[cell] != CellKinds.WALL:
				only_walls = false
		walls_in_all_rooms += world.grid.blocked_cells.size()
		rooms_checked += 1
		room.free()
		world.free()
	_expect(rooms_checked >= 6 and walls_in_all_rooms >= 300, "setup: %d rooms were booted and hold %d walls between them" % [rooms_checked, walls_in_all_rooms])
	_expect(every_room_equal, "in every room the blocked cells are exactly the cells a solid tile was painted on: identical walkability")
	_expect(only_walls, "and every one of them is a wall: no shipped tile uses another kind yet")


# --------------------------------------------------------------------------- the dump
## The world dump (tools/world_dumper.gd) says nothing new about a board of floor and walls, which is why
## the six dump baselines did not move, and names every other kind the moment a board has one.
func _check_the_world_dump() -> void:
	var dumper := WorldDumper.new()
	var walls_only := EcsWorld.new()
	walls_only.grid.add_block(Vector2i(0, 0))
	walls_only.grid.add_block(Vector2i(1, 0))
	var plain_lines := PackedStringArray()
	dumper._append_grid_section(plain_lines, walls_only)
	dumper._append_board_section(plain_lines, walls_only)
	_expect(not "\n".join(plain_lines).contains("cell_kinds"), "a board of walls and floor gets no cell_kinds line in its dump")
	_expect(plain_lines.has("[board] P player, e enemy, i item, X exit, G gate, U unlock, # wall, . floor") and plain_lines.has("##.............."), "and its legend and its map read as they always did")

	var varied := EcsWorld.new()
	varied.grid.add_block(Vector2i(0, 0))
	varied.grid.set_cell_kind(Vector2i(1, 0), CellKinds.GAP)
	varied.grid.set_cell_kind(Vector2i(2, 0), CellKinds.GAP)
	varied.grid.set_cell_kind(Vector2i(3, 0), CellKinds.CHALK)
	varied.grid.set_cell_kind(Vector2i(4, 0), CellKinds.LEAPABLE_BLOCK)
	varied.grid.set_cell_kind(Vector2i(5, 0), CellKinds.CORRUPTION)
	var varied_lines := PackedStringArray()
	dumper._append_grid_section(varied_lines, varied)
	dumper._append_board_section(varied_lines, varied)
	_expect(varied_lines.has("cell_kinds: wall=1 gap=2 leapable_block=1 chalk=1 corruption=1"), "a board with other kinds prints how many cells of each, in the vocabulary's order")
	_expect(varied_lines.has("[board] P player, e enemy, i item, X exit, G gate, U unlock, # wall, . floor, ~ gap, b leapable block, c chalk, x corruption") and varied_lines.has("#~~cbx.........."), "and draws them: ~ gap, c chalk, b leapable block, x corruption, named in the legend")
	walls_only.free()
	varied.free()


# --------------------------------------------------------------------------- one writer
## The terrain has one writer. blocked_cells and cell_kind_by_cell are written by EcsGrid.set_cell_kind()
## and by nobody else, because a second writer would leave the two out of step and the layout version, and
## with it the cached pathfinder, behind. Reading them is free (the board draws blocked_cells).
func _check_only_the_grid_writes_the_terrain() -> void:
	var write_regex := RegEx.new()
	write_regex.compile("\\b(?:blocked_cells|cell_kind_by_cell)\\s*(?:\\[[^\\]\\n]*\\]\\s*=(?!=)|=(?!=)|\\.(?:erase|clear|merge|assign))")
	var comment_regex := RegEx.new()
	comment_regex.compile("#[^\\n]*")
	var sources := 0
	var writers: Array[String] = []
	for script_path in ProjectFiles.collect_files(["gd"]):
		if script_path.begins_with("res://tests/") or script_path == "res://ecs/core/ecs_grid.gd":
			continue
		sources += 1
		var code := comment_regex.sub(ProjectFiles.read_text(script_path), "", true)
		if write_regex.search(code) != null:
			writers.append(script_path)
	_expect(sources >= 20, "the walk found %d source scripts (at least 20)" % sources)
	_expect(writers.is_empty(), "no script but ecs_grid.gd writes blocked_cells or cell_kind_by_cell (found: %s)" % ", ".join(PackedStringArray(writers)))
	_expect(write_regex.search("grid.blocked_cells[cell] = true") != null and write_regex.search("world.grid.blocked_cells.erase(cell)") != null and write_regex.search("grid.cell_kind_by_cell = {}") != null and write_regex.search("grid.cell_kind_by_cell[cell] = &\"gap\"") != null, "the lint's pattern catches an assignment, an erase and a replacement")
	_expect(write_regex.search("if grid.blocked_cells.has(cell):") == null and write_regex.search("for cell in grid.cell_kind_by_cell:") == null and write_regex.search("if kind == grid.cell_kind_by_cell[cell]:") == null and write_regex.search("var count := grid.blocked_cells.size()") == null, "and does not mistake a read for a write")
