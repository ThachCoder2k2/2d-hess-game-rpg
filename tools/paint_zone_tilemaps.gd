extends SceneTree

## Build tool: carves THE KINGDOM — one continuous 72x40 semi-open board
## (Hyper Light Drifter / Dark Souls structure, docs/soulslike-world-plan.md)
## — and saves it as objects/world/kingdom_world_tilemap.tscn. The world
## starts as solid rock; districts are carved as organic disks and winding
## paths, so nothing is a rectangle and regions flow into each other under
## one scrolling camera. Border walls ARE the collision (solid=true tiles).
##
## The tool validates itself: a BFS from the spawn must reach every carved
## cell, so an accidentally orphaned pocket fails the build.
##   Godot --headless --path . -s tools/paint_zone_tilemaps.gd

const SIZE := Vector2i(72, 40)
const START_CELL := Vector2i(4, 35)

const TILE_WOOD := Vector2i(0, 0)
const TILE_SAND := Vector2i(1, 0)
const TILE_CHALK := Vector2i(2, 0)
const TILE_GRASS := Vector2i(3, 0)
const TILE_WALL := Vector2i(4, 0)
const TILE_LANDMARK := Vector2i(5, 0)

## DISKS indexes whose floor is the grass mat (the garden lawns).
const GRASS_DISKS := [6, 7]

## District bowls: center, radius. Carved in order; overlaps merge.
const DISKS := [
	[Vector2(4, 35), 2.2],    # spawn nook (treasure behind the spawn)
	[Vector2(12, 32), 6.5],   # the Toybox Yard bowl
	[Vector2(5, 26), 2.6],    # hills pocket (soft branch)
	[Vector2(21, 37), 2.6],   # warned pocket (hard branch)
	[Vector2(28, 20), 4.2],   # the Stable Gate arena
	[Vector2(39, 13), 5.2],   # the White Court plateau
	[Vector2(31, 5), 4.6],    # Chalk Gardens, west field
	[Vector2(42, 4), 4.4],    # Chalk Gardens, east field
	[Vector2(54, 17), 4.2],   # Bookshelf Pass, south hall
	[Vector2(60, 10), 4.6],   # Bookshelf Pass, north hall
	[Vector2(68, 5), 1.8],    # treasure nook at the world's edge
]

## Winding roads: waypoint list, carve radius. Narrow = tense, wide = safe.
const PATHS := [
	[[Vector2(4, 35), Vector2(9, 34), Vector2(11, 33)], 1.6],                     # spawn -> yard
	[[Vector2(8, 29), Vector2(6, 27)], 1.2],                                      # yard -> hills
	[[Vector2(15, 35), Vector2(18, 36), Vector2(20, 37)], 1.2],                   # yard -> warned pocket
	[[Vector2(16, 29), Vector2(20, 26), Vector2(23, 24), Vector2(26, 22)], 1.8],  # the road north
	[[Vector2(30, 18), Vector2(33, 16), Vector2(36, 15)], 1.8],                   # arena -> court
	[[Vector2(40, 9), Vector2(41, 6)], 1.6],                                      # court -> gardens east
	[[Vector2(34, 5), Vector2(38, 4)], 1.8],                                      # gardens bridge west<->east
	[[Vector2(32, 9), Vector2(32, 12), Vector2(35, 13)], 1.1],                    # gardens shortcut corridor (gated)
	[[Vector2(44, 13), Vector2(47, 14), Vector2(50, 16)], 1.8],                   # court -> pass
	[[Vector2(56, 14), Vector2(58, 12)], 1.8],                                    # pass south<->north
	[[Vector2(63, 8), Vector2(66, 6)], 1.1],                                      # pass -> treasure nook
	[[Vector2(54, 20), Vector2(50, 20), Vector2(47, 19), Vector2(43, 15)], 1.1],  # pass home corridor (gated)
]

## Rock put back AFTER carving: arena pillars, garden hedges, shelf ridges.
const EXTRA_ROCK := [
	Vector2i(26, 20), Vector2i(30, 20), Vector2i(28, 18), Vector2i(28, 22),
	Vector2i(29, 4), Vector2i(33, 6), Vector2i(43, 3), Vector2i(40, 6), Vector2i(31, 2),
	Vector2i(52, 16), Vector2i(53, 16), Vector2i(54, 16),
	Vector2i(58, 10), Vector2i(58, 11),
	Vector2i(61, 12), Vector2i(62, 12),
]

## Solid landmark tiles, visible from far under the scrolling camera.
const LANDMARKS := [
	Vector2i(11, 31), Vector2i(12, 31), Vector2i(11, 32), Vector2i(12, 32),
	Vector2i(38, 12), Vector2i(39, 12), Vector2i(38, 13), Vector2i(39, 13),
	Vector2i(41, 3), Vector2i(42, 3), Vector2i(41, 4), Vector2i(42, 4),
	Vector2i(59, 9), Vector2i(60, 9), Vector2i(59, 10), Vector2i(60, 10),
]


func _init() -> void:
	var tile_set := load("res://resources/tiles/playground_world_tileset.tres") as TileSet
	if tile_set == null:
		push_error("playground_world_tileset.tres failed to load (run an editor import first).")
		quit(1)
		return

	var open := _carve_world()
	var orphans := _validate_connectivity(open)
	if not orphans.is_empty():
		push_error("KINGDOM CARVE: %d cells unreachable from the spawn, e.g. %s" % [orphans.size(), orphans.slice(0, 6)])
		quit(1)
		return

	var success := _paint(open, tile_set)
	print("KINGDOM TILEMAP: %s (%d open cells, all reachable)" % ["OK" if success else "FAIL", open.size()])
	quit(0 if success else 1)


## Floors remember what carved them: disk cells are yards (checker), the
## garden disks are grass, and cells only a road touched are chalk lines.
var grass_cells: Dictionary = {}
var chalk_cells: Dictionary = {}


func _carve_world() -> Dictionary:
	var open: Dictionary = {}
	var disk_cells: Dictionary = {}
	for index in DISKS.size():
		var disk: Array = DISKS[index]
		_carve_disk(open, disk[0], disk[1])
		_carve_disk(disk_cells, disk[0], disk[1])
		if index in GRASS_DISKS:
			_carve_disk(grass_cells, disk[0], disk[1])
	for path in PATHS:
		var points: Array = path[0]
		for i in range(points.size() - 1):
			var from: Vector2 = points[i]
			var to: Vector2 = points[i + 1]
			var steps := int(from.distance_to(to) / 0.4) + 1
			for step in range(steps + 1):
				_carve_disk(open, from.lerp(to, float(step) / steps), path[1])
	for cell in open:
		if not disk_cells.has(cell):
			chalk_cells[cell] = true
	for cell in EXTRA_ROCK:
		open.erase(cell)
	for cell in LANDMARKS:
		open.erase(cell)
	# The outer ring is always rock so the board has a rim.
	for cell in open.keys():
		if cell.x <= 0 or cell.y <= 0 or cell.x >= SIZE.x - 1 or cell.y >= SIZE.y - 1:
			open.erase(cell)
	return open


func _carve_disk(open: Dictionary, center: Vector2, radius: float) -> void:
	for y in range(int(center.y - radius) - 1, int(center.y + radius) + 2):
		for x in range(int(center.x - radius) - 1, int(center.x + radius) + 2):
			if Vector2(x, y).distance_to(center) <= radius:
				open[Vector2i(x, y)] = true


## Every carved cell must be walkable from the spawn (4-directional).
func _validate_connectivity(open: Dictionary) -> Array:
	var reached: Dictionary = {}
	var frontier: Array = [START_CELL]
	reached[START_CELL] = true
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = cell + direction
			if open.has(next) and not reached.has(next):
				reached[next] = true
				frontier.append(next)
	var orphans: Array = []
	for cell in open:
		if not reached.has(cell):
			orphans.append(cell)
	return orphans


func _paint(open: Dictionary, tile_set: TileSet) -> bool:
	var layer := TileMapLayer.new()
	layer.name = "TileMap"
	layer.position = Vector2(64, 36)
	layer.tile_set = tile_set
	var landmark_cells: Dictionary = {}
	for cell in LANDMARKS:
		landmark_cells[cell] = true
	for y in SIZE.y:
		for x in SIZE.x:
			var cell := Vector2i(x, y)
			var atlas: Vector2i
			if landmark_cells.has(cell):
				atlas = TILE_LANDMARK
			elif open.has(cell):
				if grass_cells.has(cell):
					atlas = TILE_GRASS
				elif chalk_cells.has(cell):
					atlas = TILE_CHALK
				else:
					atlas = TILE_WOOD if (x + y) % 2 == 0 else TILE_SAND
			else:
				atlas = TILE_WALL
			layer.set_cell(cell, 0, atlas)
	var packed := PackedScene.new()
	if packed.pack(layer) != OK:
		return false
	return ResourceSaver.save(packed, "res://objects/world/kingdom_world_tilemap.tscn") == OK
