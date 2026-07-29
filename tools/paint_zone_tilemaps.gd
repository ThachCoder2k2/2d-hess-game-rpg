extends SceneTree

## Build tool: carves THE KINGDOM — one continuous 72x40 semi-open board
## (Hyper Light Drifter / Dark Souls structure, docs/soulslike-world-plan.md)
## — and saves it as objects/world/kingdom_world_tilemap.tscn.
##
## The world starts as solid rock. Two kinds of space are carved out of it:
## organic bowls (the village, the hills, the gardens) and straight halls
## (the muster yard, the keep, the library), so nature reads round and
## architecture reads built. Winding roads join them under one camera.
##
## DISTRICTS is what stops the kingdom looking like one texture: every cell on
## the board — carved or not — belongs to its nearest district, and a district
## names BOTH the floor its open cells wear AND the rock its walls wear. The
## village is toy blocks around wood-and-sand, the gardens are hedges around
## lawn, the library is bookshelves around boards, the keep is banners around
## marble. On top of that, castle architecture (curtain walls, tower studs, the
## moat ring) is painted over rock only, so it can never seal a road.
##
## The tool validates itself twice: a BFS from the spawn must reach every
## carved cell, and every cell the zone scene spawns something on must be open.
##   Godot --headless --path . -s tools/paint_zone_tilemaps.gd

const SIZE := Vector2i(72, 40)
const START_CELL := Vector2i(4, 35)

const TILE_WOOD := Vector2i(0, 0)
const TILE_SAND := Vector2i(1, 0)
const TILE_CHALK := Vector2i(2, 0)
const TILE_GRASS := Vector2i(3, 0)
const TILE_BLOCK := Vector2i(4, 0)      # solid
const TILE_LANDMARK := Vector2i(5, 0)   # solid
const TILE_COBBLE := Vector2i(6, 0)
const TILE_CARPET := Vector2i(7, 0)
const TILE_MARBLE := Vector2i(8, 0)
const TILE_BOARDS := Vector2i(9, 0)
const TILE_RAMPART := Vector2i(10, 0)   # solid
const TILE_TOWER := Vector2i(11, 0)     # solid
const TILE_HEDGE := Vector2i(12, 0)     # solid
const TILE_BOOKSHELF := Vector2i(13, 0) # solid
const TILE_WATER := Vector2i(14, 0)     # solid
const TILE_BANNER := Vector2i(15, 0)    # solid
const TILE_COTTAGE := Vector2i(16, 0)   # solid
const TILE_BLOCK_ALT := Vector2i(17, 0) # solid
const TILE_BLOCK_SPILL := Vector2i(18, 0) # solid

## The three stackings of raw toy block, mixed by cell so the deep fields far
## from any road never show a visible tiling repeat.
const DEEP_ROCK_MIX := [TILE_BLOCK, TILE_BLOCK_ALT, TILE_BLOCK, TILE_BLOCK_SPILL, TILE_BLOCK_ALT]

## Every cell belongs to the district whose anchor is nearest. `floor` is what
## its open cells wear (with `floor_alt`, the two alternate in a checker) and
## `rock` is what its uncarved cells wear.
const DISTRICTS := [
	{"name": "village", "anchor": Vector2(11, 33), "floor": TILE_WOOD, "floor_alt": TILE_SAND, "rock": TILE_BLOCK},
	{"name": "hills", "anchor": Vector2(4, 25), "floor": TILE_GRASS, "rock": TILE_HEDGE},
	{"name": "pocket", "anchor": Vector2(21, 38), "floor": TILE_SAND, "floor_alt": TILE_WOOD, "rock": TILE_BLOCK},
	{"name": "muster_yard", "anchor": Vector2(29, 20), "floor": TILE_COBBLE, "rock": TILE_RAMPART},
	{"name": "keep", "anchor": Vector2(39, 13), "floor": TILE_MARBLE, "rock": TILE_BANNER},
	{"name": "garden_west", "anchor": Vector2(31, 5), "floor": TILE_GRASS, "rock": TILE_HEDGE},
	{"name": "garden_east", "anchor": Vector2(42, 4), "floor": TILE_GRASS, "rock": TILE_HEDGE},
	{"name": "library_south", "anchor": Vector2(54, 18), "floor": TILE_BOARDS, "rock": TILE_BOOKSHELF},
	{"name": "library_north", "anchor": Vector2(60, 10), "floor": TILE_BOARDS, "rock": TILE_BOOKSHELF},
	{"name": "high_tower", "anchor": Vector2(68, 5), "floor": TILE_MARBLE, "rock": TILE_RAMPART},
]

## Organic bowls: center, radius. Nature — nothing here is a rectangle.
const BOWLS := [
	[Vector2(4, 35), 2.2],    # spawn nook (treasure behind the spawn)
	[Vector2(12, 32), 6.5],   # the village common
	[Vector2(5, 26), 2.6],    # hills pocket (soft branch)
	[Vector2(21, 37), 2.6],   # warned pocket (hard branch)
	[Vector2(31, 5), 4.6],    # Chalk Gardens, west parterre
	[Vector2(42, 4), 4.4],    # Chalk Gardens, east parterre
]

## Built halls: straight rooms with corners, so architecture reads as made.
const HALLS := [
	Rect2i(25, 17, 9, 7),   # the muster yard, inside the curtain wall
	Rect2i(35, 10, 10, 7),  # the keep's great hall
	Rect2i(50, 15, 9, 6),   # Bookshelf Pass, south reading room
	Rect2i(56, 7, 9, 7),    # Bookshelf Pass, north reading room
	Rect2i(66, 4, 4, 4),    # the high tower's top room
]

## The runner down the middle of the great hall, up to the throne dais.
const CARPET_HALL := Rect2i(37, 11, 6, 5)

## Winding roads: waypoint list, carve radius. Narrow = tense, wide = safe.
const ROADS := [
	[[Vector2(4, 35), Vector2(9, 34), Vector2(11, 33)], 1.6],                     # spawn -> village
	[[Vector2(8, 29), Vector2(6, 27)], 1.2],                                      # village -> hills
	[[Vector2(15, 35), Vector2(18, 36), Vector2(20, 37)], 1.2],                   # village -> warned pocket
	[[Vector2(16, 29), Vector2(20, 26), Vector2(23, 24), Vector2(26, 22)], 1.8],  # the road to the gatehouse
	[[Vector2(30, 18), Vector2(33, 16), Vector2(36, 15)], 1.8],                   # muster yard -> keep
	[[Vector2(40, 9), Vector2(41, 6)], 1.6],                                      # keep -> gardens east
	[[Vector2(34, 5), Vector2(38, 4)], 1.8],                                      # gardens bridge west<->east
	[[Vector2(32, 9), Vector2(32, 12), Vector2(35, 13)], 1.1],                    # gardens shortcut (gated)
	[[Vector2(44, 13), Vector2(47, 14), Vector2(50, 16)], 1.8],                   # keep -> pass
	[[Vector2(56, 14), Vector2(58, 12)], 1.8],                                    # pass south<->north
	[[Vector2(63, 8), Vector2(66, 6)], 1.1],                                      # pass -> high tower
	[[Vector2(54, 20), Vector2(50, 20), Vector2(47, 19), Vector2(43, 15)], 1.1],  # pass home corridor (gated)
]

## Rock put back after carving: yard columns, garden hedges, shelf ends.
const EXTRA_ROCK := [
	Vector2i(27, 18), Vector2i(31, 18), Vector2i(27, 22), Vector2i(31, 22),
	Vector2i(36, 11), Vector2i(43, 11),
	Vector2i(29, 4), Vector2i(33, 6), Vector2i(43, 3), Vector2i(40, 6), Vector2i(31, 2),
	Vector2i(52, 16), Vector2i(53, 16), Vector2i(54, 16),
	Vector2i(58, 10), Vector2i(58, 11),
	Vector2i(61, 12), Vector2i(62, 12),
]

## Houses in the village common — solid, and drawn as houses, not as rock.
## Deliberately L-shaped and odd-sized: square blocks of them read as a grid,
## which is the look the whole kingdom is built to avoid.
const COTTAGES := [
	Vector2i(8, 29), Vector2i(9, 29), Vector2i(8, 30),
	Vector2i(16, 31), Vector2i(17, 31), Vector2i(17, 32),
	Vector2i(13, 36), Vector2i(14, 36), Vector2i(13, 37),
	Vector2i(6, 33), Vector2i(18, 34), Vector2i(10, 37),
]

## Solid flag towers, the far-sight landmarks under the scrolling camera.
const LANDMARKS := [
	Vector2i(11, 31), Vector2i(12, 31), Vector2i(11, 32), Vector2i(12, 32),
	Vector2i(38, 12), Vector2i(39, 12), Vector2i(38, 13), Vector2i(39, 13),
	Vector2i(41, 3), Vector2i(42, 3), Vector2i(41, 4), Vector2i(42, 4),
	Vector2i(59, 9), Vector2i(60, 9), Vector2i(59, 10), Vector2i(60, 10),
]

## Castle walls: from, to, wall tile, and how many cells between tower studs.
## These paint over ROCK ONLY — a wall can never close a carved road, so the
## gatehouse gap where a road crosses appears on its own.
const WALL_LINES := [
	[Vector2(24, 6), Vector2(24, 39), TILE_RAMPART, 5],    # the curtain wall
	[Vector2(33, 8), Vector2(46, 8), TILE_RAMPART, 6],     # keep wall, north
	[Vector2(46, 8), Vector2(46, 18), TILE_RAMPART, 5],    # keep wall, east
	[Vector2(46, 18), Vector2(33, 18), TILE_RAMPART, 6],   # keep wall, south
	[Vector2(33, 18), Vector2(33, 8), TILE_RAMPART, 5],    # keep wall, west
	[Vector2(47, 4), Vector2(65, 4), TILE_RAMPART, 6],     # library wall, north
	[Vector2(65, 4), Vector2(65, 22), TILE_RAMPART, 6],    # library wall, east
	[Vector2(65, 22), Vector2(47, 22), TILE_RAMPART, 6],   # library wall, south
	[Vector2(47, 22), Vector2(47, 4), TILE_RAMPART, 6],    # library wall, west
]

## The moat: an annulus of water around the keep, again on rock only, so the
## roads in and out read as causeways across it.
const MOAT_CENTER := Vector2(39, 13)
const MOAT_INNER := 9.0
const MOAT_OUTER := 10.4

## How deep a district dresses its own rock. Cells this close to open ground
## are the walls players actually stand next to, so they wear the district's
## material (hedge, bookshelf, banner...). Everything deeper is the raw toy
## blocks the whole playground is built from — districts are a facing, not a
## fill, which keeps the far fields from reading as one flat texture.
const DISTRICT_ROCK_DEPTH := 6

## Cells scenes/zones/the_kingdom.tscn spawns on: the player entry, every
## enemy, every pickup, both gates. Carving must leave all of them open.
const REQUIRED_OPEN := [
	Vector2i(4, 35),
	Vector2i(10, 33), Vector2i(16, 29), Vector2i(23, 23), Vector2i(29, 3), Vector2i(40, 8),
	Vector2i(20, 36), Vector2i(22, 37), Vector2i(27, 20), Vector2i(29, 20), Vector2i(66, 6),
	Vector2i(5, 26), Vector2i(39, 5), Vector2i(52, 18), Vector2i(61, 11),
	Vector2i(30, 5), Vector2i(44, 5), Vector2i(57, 12),
	Vector2i(2, 35), Vector2i(4, 25), Vector2i(22, 38), Vector2i(28, 3), Vector2i(68, 5),
	Vector2i(32, 11), Vector2i(47, 19),
]


func _init() -> void:
	var tile_set := load("res://resources/tiles/playground_world_tileset.tres") as TileSet
	if tile_set == null:
		push_error("playground_world_tileset.tres failed to load (run an editor import first).")
		quit(1)
		return

	var open := _carve_world()

	var buried := []
	for cell in REQUIRED_OPEN:
		if not open.has(cell):
			buried.append(cell)
	if not buried.is_empty():
		push_error("KINGDOM CARVE: %d spawn cells are buried in rock: %s" % [buried.size(), buried])
		quit(1)
		return

	var orphans := _validate_connectivity(open)
	if not orphans.is_empty():
		push_error("KINGDOM CARVE: %d cells unreachable from the spawn, e.g. %s" % [orphans.size(), orphans.slice(0, 6)])
		quit(1)
		return

	var success := _paint(open, tile_set)
	_print_preview()
	print("KINGDOM TILEMAP: %s (%d open cells, all reachable, %d spawn cells clear)" % [
		"OK" if success else "FAIL", open.size(), REQUIRED_OPEN.size()])
	quit(0 if success else 1)


## One character per tile, so the kingdom can be read without the editor.
const PREVIEW_GLYPHS := {
	0: ".", 1: ",", 2: "-", 3: "\"", 4: "#", 5: "!", 6: ":", 7: "=", 8: "+",
	9: ";", 10: "M", 11: "T", 12: "%", 13: "B", 14: "~", 15: "W", 16: "n",
	17: "#", 18: "#",
}


func _print_preview() -> void:
	print("KINGDOM PREVIEW  . wood  , sand  - chalk  \" grass  : cobble  = carpet  + marble  ; boards")
	print("                 # block  ! landmark  M rampart  T tower  %% hedge  B shelf  ~ moat  W banner  n cottage")
	for y in SIZE.y:
		var line := ""
		for x in SIZE.x:
			line += PREVIEW_GLYPHS.get(painted_atlas.get(Vector2i(x, y), Vector2i(4, 0)).x, "?")
		print("%2d %s" % [y, line])


## Cells a road carved but no bowl or hall did — those wear the chalk lines.
var road_only_cells: Dictionary = {}

## cell -> the atlas coord painted there, kept for the ASCII preview.
var painted_atlas: Dictionary = {}


func _carve_world() -> Dictionary:
	var open: Dictionary = {}
	var room_cells: Dictionary = {}
	for bowl in BOWLS:
		_carve_disk(open, bowl[0], bowl[1])
		_carve_disk(room_cells, bowl[0], bowl[1])
	for hall in HALLS:
		for y in range(hall.position.y, hall.end.y):
			for x in range(hall.position.x, hall.end.x):
				open[Vector2i(x, y)] = true
				room_cells[Vector2i(x, y)] = true
	for road in ROADS:
		var points: Array = road[0]
		for index in range(points.size() - 1):
			var from: Vector2 = points[index]
			var to: Vector2 = points[index + 1]
			var steps := int(from.distance_to(to) / 0.4) + 1
			for step in range(steps + 1):
				_carve_disk(open, from.lerp(to, float(step) / steps), road[1])
	for cell in open:
		if not room_cells.has(cell):
			road_only_cells[cell] = true
	for cell in EXTRA_ROCK:
		open.erase(cell)
	for cell in COTTAGES:
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


## cell -> the DISTRICTS entry that owns it (nearest anchor wins).
func _district_at(cell: Vector2i) -> Dictionary:
	var best: Dictionary = DISTRICTS[0]
	var best_distance := INF
	for district in DISTRICTS:
		var distance: float = Vector2(cell).distance_squared_to(district["anchor"])
		if distance < best_distance:
			best_distance = distance
			best = district
	return best


## cell -> how many steps of rock lie between it and the nearest open cell.
func _measure_rock_depth(open: Dictionary) -> Dictionary:
	var depth: Dictionary = {}
	var frontier: Array = []
	for cell in open:
		depth[cell] = 0
		frontier.append(cell)
	var cursor := 0
	while cursor < frontier.size():
		var cell: Vector2i = frontier[cursor]
		cursor += 1
		for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = cell + direction
			if next.x < 0 or next.y < 0 or next.x >= SIZE.x or next.y >= SIZE.y:
				continue
			if depth.has(next):
				continue
			depth[next] = depth[cell] + 1
			frontier.append(next)
	return depth


## A stable scramble of a cell's coordinates. Deterministic on purpose: the map
## is generated data, so the same build must always paint the same field.
func _cell_hash(cell: Vector2i) -> int:
	return absi((cell.x * 73856093) ^ (cell.y * 19349663))


## Solid decoration painted over rock only: walls, tower studs, the moat.
func _build_rock_overlay() -> Dictionary:
	var overlay: Dictionary = {}
	for y in SIZE.y:
		for x in SIZE.x:
			var cell := Vector2i(x, y)
			var distance := Vector2(cell).distance_to(MOAT_CENTER)
			if distance >= MOAT_INNER and distance <= MOAT_OUTER:
				overlay[cell] = TILE_WATER
	for line in WALL_LINES:
		var from: Vector2 = line[0]
		var to: Vector2 = line[1]
		var wall_tile: Vector2i = line[2]
		var tower_every: int = line[3]
		var length := int(from.distance_to(to))
		for step in range(length + 1):
			var cell := Vector2i((from.lerp(to, float(step) / max(length, 1))).round())
			overlay[cell] = TILE_TOWER if step % tower_every == 0 else wall_tile
	return overlay


func _paint(open: Dictionary, tile_set: TileSet) -> bool:
	var layer := TileMapLayer.new()
	layer.name = "TileMap"
	layer.position = Vector2(64, 36)
	layer.tile_set = tile_set
	var rock_overlay := _build_rock_overlay()
	var rock_depth := _measure_rock_depth(open)
	var cottage_cells: Dictionary = {}
	for cell in COTTAGES:
		cottage_cells[cell] = true
	var landmark_cells: Dictionary = {}
	for cell in LANDMARKS:
		landmark_cells[cell] = true
	for y in SIZE.y:
		for x in SIZE.x:
			var cell := Vector2i(x, y)
			var district := _district_at(cell)
			var atlas: Vector2i
			if landmark_cells.has(cell):
				atlas = TILE_LANDMARK
			elif cottage_cells.has(cell):
				atlas = TILE_COTTAGE
			elif open.has(cell):
				if road_only_cells.has(cell):
					atlas = TILE_CHALK
				elif CARPET_HALL.has_point(cell):
					atlas = TILE_CARPET
				elif district.has("floor_alt") and (x + y) % 2 == 1:
					atlas = district["floor_alt"]
				else:
					atlas = district["floor"]
			elif rock_overlay.has(cell):
				atlas = rock_overlay[cell]
			elif rock_depth.get(cell, 99) <= DISTRICT_ROCK_DEPTH:
				atlas = district["rock"]
			else:
				atlas = DEEP_ROCK_MIX[_cell_hash(cell) % DEEP_ROCK_MIX.size()]
			layer.set_cell(cell, 0, atlas)
			painted_atlas[cell] = atlas
	var packed := PackedScene.new()
	if packed.pack(layer) != OK:
		return false
	return ResourceSaver.save(packed, "res://objects/world/kingdom_world_tilemap.tscn") == OK
