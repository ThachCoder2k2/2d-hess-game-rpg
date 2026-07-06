@tool
extends SceneTree

const TILESET_PATH := "res://resources/tiles/playground_tileset.tres"
const TILEMAP_SCENE_PATH := "res://objects/world/playground_tilemap.tscn"
const TILE_ATLAS_PATH := "res://assets/tiles/playground_tiles.svg"
const BOARD_SIZE := Vector2i(16, 9)
const CELL_SIZE := Vector2i(32, 32)


func _init() -> void:
	var atlas_texture := load(TILE_ATLAS_PATH) as Texture2D
	if atlas_texture == null:
		push_error("Could not load tile atlas: " + TILE_ATLAS_PATH)
		quit(1)
		return

	var atlas_source := TileSetAtlasSource.new()
	atlas_source.texture = atlas_texture
	atlas_source.texture_region_size = CELL_SIZE
	atlas_source.create_tile(Vector2i(0, 0))
	atlas_source.create_tile(Vector2i(1, 0))

	var tile_set := TileSet.new()
	tile_set.tile_size = CELL_SIZE
	tile_set.add_source(atlas_source, 0)
	var tile_save := ResourceSaver.save(tile_set, TILESET_PATH)
	if tile_save != OK:
		push_error("Could not save TileSet: " + str(tile_save))
		quit(1)
		return

	var floor_layer := TileMapLayer.new()
	floor_layer.name = "PlaygroundTileMap"
	floor_layer.tile_set = tile_set
	floor_layer.position = Vector2(64, 36)
	floor_layer.y_sort_enabled = false

	for y in BOARD_SIZE.y:
		for x in BOARD_SIZE.x:
			var atlas_coords := Vector2i(1, 0) if (x + y) % 2 == 0 else Vector2i(0, 0)
			floor_layer.set_cell(Vector2i(x, y), 0, atlas_coords)

	var scene := PackedScene.new()
	var pack_result := scene.pack(floor_layer)
	if pack_result != OK:
		push_error("Could not pack TileMap scene: " + str(pack_result))
		quit(1)
		return
	var scene_save := ResourceSaver.save(scene, TILEMAP_SCENE_PATH)
	if scene_save != OK:
		push_error("Could not save TileMap scene: " + str(scene_save))
		quit(1)
		return

	print("Generated TileMap resources.")
	quit()
