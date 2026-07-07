extends SceneTree

## Build tool: paints the first room's floor as a throne-room kingdom and saves it
## as objects/world/kingdom_tilemap.tscn. Run headless:
##   Godot --headless --path . -s tools/paint_kingdom_tilemap.gd
## Rerun after changing the layout or the kingdom tileset.

const COLUMNS := 16
const ROWS := 9
const CARPET_COLUMNS := [7, 8]

const TILE_LIGHT_MARBLE := Vector2i(0, 0)
const TILE_DARK_MARBLE := Vector2i(1, 0)
const TILE_CARPET := Vector2i(2, 0)


func _init() -> void:
	var tile_set := load("res://resources/tiles/kingdom_tileset.tres") as TileSet
	if tile_set == null:
		push_error("kingdom_tileset.tres failed to load (run an editor import first).")
		quit(1)
		return
	var layer := TileMapLayer.new()
	layer.name = "KingdomTileMap"
	layer.position = Vector2(64, 36)
	layer.tile_set = tile_set
	for y in ROWS:
		for x in COLUMNS:
			var atlas: Vector2i
			if x in CARPET_COLUMNS:
				atlas = TILE_CARPET
			elif (x + y) % 2 == 0:
				atlas = TILE_LIGHT_MARBLE
			else:
				atlas = TILE_DARK_MARBLE
			layer.set_cell(Vector2i(x, y), 0, atlas)
	var packed := PackedScene.new()
	var pack_err := packed.pack(layer)
	if pack_err != OK:
		push_error("Failed to pack kingdom tilemap: %d" % pack_err)
		quit(1)
		return
	var save_err := ResourceSaver.save(packed, "res://objects/world/kingdom_tilemap.tscn")
	print("KINGDOM TILEMAP: %s (pack=%d save=%d)" % ["OK" if save_err == OK else "FAIL", pack_err, save_err])
	quit(0 if save_err == OK else 1)
