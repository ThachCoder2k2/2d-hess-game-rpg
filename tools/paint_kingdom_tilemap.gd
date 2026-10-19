extends SceneTree

## Build tool: paints the first room's floor as a throne-room kingdom and saves it
## as content/tilesets/kingdom/tilemap.tscn. Run headless:
##   Godot --headless --path . -s tools/paint_kingdom_tilemap.gd
## Rerun after changing the layout or the kingdom tileset.
## Saves through SaveKeepingUids and stamps uids last, so the scene keeps the uid
## that seven room scenes name it by (see tools/save_keeping_uids.gd).

const SaveKeepingUids := preload("res://tools/save_keeping_uids.gd")
const CellKindPainter := preload("res://tools/cell_kind_painter.gd")

const COLUMNS := 16
const ROWS := 9
const CARPET_COLUMNS := [7, 8]
const BANNER_ROWS := [2, 6]
## Interior wall cells (the old blocker layout). Wall/throne/banner tiles carry
## solid=true custom data (cell kind wall), so painting them IS the collision — no markers needed.
## Every cell is painted through CellKindPainter, which states the KIND the cell is meant to have next to
## the art chosen for it and refuses a tile that does not read as that kind (docs/game-base-plan.md 5.11).
const WALL_CELLS: Array[Vector2i] = [Vector2i(7, 2), Vector2i(7, 3), Vector2i(7, 5), Vector2i(7, 6)]

const TILE_LIGHT_MARBLE := Vector2i(0, 0)
const TILE_DARK_MARBLE := Vector2i(1, 0)
const TILE_CARPET := Vector2i(2, 0)
const TILE_WALL := Vector2i(4, 0)
const TILE_THRONE := Vector2i(5, 0)
const TILE_BANNER := Vector2i(6, 0)


func _init() -> void:
	var tile_set := load("res://content/tilesets/kingdom/tileset.tres") as TileSet
	if tile_set == null:
		push_error("kingdom_tileset.tres failed to load (run an editor import first).")
		quit(1)
		return
	var layer := TileMapLayer.new()
	layer.name = "KingdomTileMap"
	layer.position = Vector2(64, 36)
	layer.tile_set = tile_set
	var painter := CellKindPainter.new(tile_set)
	for y in ROWS:
		for x in COLUMNS:
			var on_border: bool = x == 0 or x == COLUMNS - 1 or y == 0 or y == ROWS - 1
			var atlas: Vector2i
			var kind := CellKinds.WALL
			if y == 0 and x in CARPET_COLUMNS:
				atlas = TILE_THRONE
			elif (x == 0 or x == COLUMNS - 1) and y in BANNER_ROWS:
				atlas = TILE_BANNER
			elif on_border or Vector2i(x, y) in WALL_CELLS:
				atlas = TILE_WALL
			else:
				kind = CellKinds.FLOOR
				if x in CARPET_COLUMNS:
					atlas = TILE_CARPET
				elif (x + y) % 2 == 0:
					atlas = TILE_LIGHT_MARBLE
				else:
					atlas = TILE_DARK_MARBLE
			var problem := painter.paint(layer, Vector2i(x, y), kind, atlas)
			if not problem.is_empty():
				push_error("KINGDOM TILEMAP: " + problem)
				quit(1)
				return
	var packed := PackedScene.new()
	var pack_err := packed.pack(layer)
	if pack_err != OK:
		push_error("Failed to pack kingdom tilemap: %d" % pack_err)
		quit(1)
		return
	var save_err := SaveKeepingUids.save_keeping_uid(packed, "res://content/tilesets/kingdom/tilemap.tscn")
	print("KINGDOM TILEMAP: %s (pack=%d save=%d)" % ["OK" if save_err == OK else "FAIL", pack_err, save_err])
	var stamped := save_err == OK and SaveKeepingUids.stamp_uids_last()
	quit(0 if stamped else 1)
