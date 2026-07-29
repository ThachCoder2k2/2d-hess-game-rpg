extends SceneTree

## Build tool: paints the world-zone tilemaps (greybox pass — final art is
## human-owned) and saves them under objects/world/. Border walls carry the
## collision (solid=true custom data on the tile); door cells stay floor so
## the exit markers on them are walkable. Run headless:
##   Godot --headless --path . -s tools/paint_zone_tilemaps.gd
## Rerun after changing a layout below.
##
## World v2 follows Dark Souls 3's opening skeleton (docs/soulslike-world-plan.md):
## tutorial cemetery -> boss-gate arena -> hub -> dense looping level -> side
## level that loops one-way back to the hub.

const TILE_LIGHT := Vector2i(0, 0)
const TILE_DARK := Vector2i(1, 0)
const TILE_WALL := Vector2i(4, 0)
const TILE_LANDMARK := Vector2i(5, 0)

## Zone layouts: name -> {size, door cells (kept floor), interior walls,
## landmark cells (solid, drawn as throne tiles for the greybox)}.
var zone_layouts := {
	"toybox_tilemap": {
		"size": Vector2i(24, 13),
		"doors": [Vector2i(19, 0)],
		"walls": _cemetery_walls(),
		"landmark": [Vector2i(11, 6), Vector2i(12, 6), Vector2i(11, 7), Vector2i(12, 7)],
	},
	"stable_tilemap": {
		"size": Vector2i(12, 9),
		"doors": [Vector2i(6, 0), Vector2i(6, 8)],
		"walls": [Vector2i(2, 2), Vector2i(9, 2), Vector2i(2, 6), Vector2i(9, 6)],
		"landmark": [],
	},
	"court_tilemap": {
		"size": Vector2i(16, 10),
		"doors": [Vector2i(8, 0), Vector2i(8, 9), Vector2i(0, 5)],
		"walls": [],
		"landmark": [Vector2i(7, 4), Vector2i(8, 4), Vector2i(7, 5), Vector2i(8, 5)],
	},
	"chalk_tilemap": {
		"size": Vector2i(28, 14),
		"doors": [Vector2i(8, 13), Vector2i(27, 11)],
		"walls": _high_wall_walls(),
		"landmark": [Vector2i(18, 5), Vector2i(19, 5), Vector2i(18, 6), Vector2i(19, 6)],
	},
	"bookshelf_tilemap": {
		"size": Vector2i(24, 11),
		"doors": [Vector2i(0, 5), Vector2i(0, 9)],
		"walls": _shelf_walls(),
		"landmark": [Vector2i(9, 1), Vector2i(10, 1), Vector2i(9, 2), Vector2i(10, 2)],
	},
}


## Cemetery of Ash road: bottom spawn corridor (item BEHIND the spawn), a
## fountain field, a soft west "hills" branch, and a walled east pocket with
## the hard guards + treasure. The row-10 wall separates corridor from field
## (gap at x=18); col-7 walls the hills (gap row 3); col-20 walls the warned
## pocket (gap row 6).
static func _cemetery_walls() -> Array:
	var walls: Array = []
	for x in range(4, 23):
		if x != 18:
			walls.append(Vector2i(x, 10))
	for y in range(1, 9):
		if y != 3:
			walls.append(Vector2i(7, y))
	for y in range(3, 10):
		if y != 6:
			walls.append(Vector2i(20, y))
	return walls


## High Wall rooms: a central spine (gaps rows 3 and 10) splits east/west;
## horizontal walls split top/bottom on each side. The west row-9 wall has NO
## painted gap — the gap cell (6, 9) is the one-way shortcut gate.
static func _high_wall_walls() -> Array:
	var walls: Array = []
	for y in range(1, 13):
		if y != 3 and y != 10:
			walls.append(Vector2i(14, y))
	for x in range(1, 14):
		if x != 6:
			walls.append(Vector2i(x, 4))
	for x in range(1, 14):
		if x != 6:
			walls.append(Vector2i(x, 9))
	for x in range(15, 27):
		if x != 22:
			walls.append(Vector2i(x, 9))
	return walls


## Bookshelf aisles + the gated hub corridor: walls above row-9 cells 1..3
## seal the corridor; the gate marker sits at (2, 9). Shelf columns have one
## aisle gap each.
static func _shelf_walls() -> Array:
	var walls: Array = [Vector2i(1, 8), Vector2i(2, 8), Vector2i(3, 8)]
	for y in range(1, 10):
		if y != 5:
			walls.append(Vector2i(7, y))
	for y in range(1, 10):
		if y != 6:
			walls.append(Vector2i(12, y))
	for y in range(1, 10):
		if y != 3:
			walls.append(Vector2i(17, y))
	return walls


func _init() -> void:
	var tile_set := load("res://resources/tiles/kingdom_tileset.tres") as TileSet
	if tile_set == null:
		push_error("kingdom_tileset.tres failed to load (run an editor import first).")
		quit(1)
		return
	var failures := 0
	for zone_name: String in zone_layouts:
		if not _paint_zone(zone_name, zone_layouts[zone_name], tile_set):
			failures += 1
	quit(1 if failures > 0 else 0)


func _paint_zone(zone_name: String, layout: Dictionary, tile_set: TileSet) -> bool:
	var size: Vector2i = layout["size"]
	var layer := TileMapLayer.new()
	layer.name = "TileMap"
	layer.position = Vector2(64, 36)
	layer.tile_set = tile_set
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			var on_border: bool = x == 0 or x == size.x - 1 or y == 0 or y == size.y - 1
			var atlas: Vector2i
			if cell in layout["doors"]:
				atlas = TILE_LIGHT
			elif cell in layout["landmark"]:
				atlas = TILE_LANDMARK
			elif on_border or cell in layout["walls"]:
				atlas = TILE_WALL
			elif (x + y) % 2 == 0:
				atlas = TILE_LIGHT
			else:
				atlas = TILE_DARK
			layer.set_cell(cell, 0, atlas)
	var packed := PackedScene.new()
	var pack_err := packed.pack(layer)
	var path := "res://objects/world/%s.tscn" % zone_name
	var save_err := ResourceSaver.save(packed, path) if pack_err == OK else FAILED
	print("ZONE TILEMAP %s: %s" % [zone_name, "OK" if save_err == OK else "FAIL (pack=%d save=%d)" % [pack_err, save_err]])
	return save_err == OK
