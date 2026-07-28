extends SceneTree

## Build tool: paints the world-zone tilemaps (greybox pass — final art is
## human-owned) and saves them under objects/world/. Border walls carry the
## collision (solid=true custom data on the tile); door cells stay floor so
## the exit markers on them are walkable. Run headless:
##   Godot --headless --path . -s tools/paint_zone_tilemaps.gd
## Rerun after changing a layout below.

const TILE_LIGHT := Vector2i(0, 0)
const TILE_DARK := Vector2i(1, 0)
const TILE_WALL := Vector2i(4, 0)
const TILE_LANDMARK := Vector2i(5, 0)

## Zone layouts: name -> {size, door cells (kept floor), interior walls,
## landmark cells (solid, drawn as throne tiles for the greybox)}.
var zone_layouts := {
	"toybox_tilemap": {
		"size": Vector2i(20, 11),
		"doors": [Vector2i(16, 0)],
		"walls": [
			Vector2i(8, 4), Vector2i(8, 5), Vector2i(8, 6), Vector2i(9, 4), Vector2i(10, 4),
			Vector2i(15, 2), Vector2i(15, 3), Vector2i(15, 4),
			Vector2i(17, 2), Vector2i(17, 3), Vector2i(17, 4),
			Vector2i(2, 6),
		],
		"landmark": [Vector2i(3, 2), Vector2i(4, 2), Vector2i(3, 3), Vector2i(4, 3)],
	},
	"chalk_tilemap": {
		"size": Vector2i(24, 12),
		"doors": [Vector2i(16, 11)],
		"walls": _lane_walls(),
		"landmark": [Vector2i(11, 5), Vector2i(12, 5), Vector2i(11, 6), Vector2i(12, 6)],
	},
}


## Two horizontal chalk-lane walls with door gaps, per the drawn design.
static func _lane_walls() -> Array:
	var walls: Array = []
	for x in range(4, 20):
		if x != 6 and x != 17:
			walls.append(Vector2i(x, 3))
	for x in range(4, 20):
		if x != 10:
			walls.append(Vector2i(x, 7))
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
