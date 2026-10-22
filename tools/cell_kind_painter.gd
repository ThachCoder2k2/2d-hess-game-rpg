extends RefCounted

## Paints a TileMapLayer by what each cell is made of (a helper, not a command; no class_name, preload it:
## `const CellKindPainter := preload("res://tools/cell_kind_painter.gd")`). CLAUDE.md forbids hand-editing
## `tile_map_data`, so every room's floor and walls come from a paint tool; this is the part of a paint tool
## that knows about cell kinds (docs/game-base-plan.md 5.11), so each tool states WHAT a cell is and the
## helper finds, checks and writes the tile that says so.
##
## A tile says what its cell is made of in the TileSet's `kind` custom-data layer, or, when it leaves that
## empty, through `solid` (CellKinds.kind_of_tile reads both, and is the same reading the game does at
## boot, so a painted layer and a booted grid cannot disagree). The helper scans the TileSet once:
##
##     var painter := CellKindPainter.new(tile_set)
##     var problem := painter.paint(layer, Vector2i(5, 4), CellKinds.GAP)             # any tile of kind gap
##     var problem := painter.paint(layer, Vector2i(0, 0), CellKinds.WALL, Vector2i(4, 0))  # THIS wall tile
##
## `paint` returns "" when it painted and a sentence when it did not: the TileSet has no tile of that kind
## (the art for it does not exist yet: a tile is added in the TileSet editor with `kind` filled in), or the
## preferred tile is not of that kind (the tool's idea of the art and of the cell disagree, which is the bug
## this check exists to catch). A tool prints the sentence and quits non-zero.
##
## `kinds_by_cell` reads a layer back the way the game reads it, so a tool can print or assert what it made.

## "No preferred tile": take the first tile of the kind, in the order the TileSet lists them.
const NO_PREFERENCE := Vector2i(-1, -1)

var _tile_set: TileSet
## kind (StringName) -> Array of { "source_id": int, "atlas_coords": Vector2i, "alternative_tile": int }:
## every tile of the TileSet that says its cell is of that kind, in the order the TileSet lists them.
var _tiles_by_kind: Dictionary = {}


func _init(tile_set: TileSet) -> void:
	_tile_set = tile_set
	for source_index in tile_set.get_source_count():
		var source_id := tile_set.get_source_id(source_index)
		var atlas_source := tile_set.get_source(source_id) as TileSetAtlasSource
		if atlas_source == null:
			continue
		for tile_index in atlas_source.get_tiles_count():
			var atlas_coords := atlas_source.get_tile_id(tile_index)
			for alternative_index in atlas_source.get_alternative_tiles_count(atlas_coords):
				var alternative_tile := atlas_source.get_alternative_tile_id(atlas_coords, alternative_index)
				var kind := CellKinds.kind_of_tile(tile_set, atlas_source.get_tile_data(atlas_coords, alternative_tile))
				if not _tiles_by_kind.has(kind):
					_tiles_by_kind[kind] = []
				_tiles_by_kind[kind].append({"source_id": source_id, "atlas_coords": atlas_coords, "alternative_tile": alternative_tile})


## True when the TileSet has at least one tile that says its cell is of this kind.
func has_tile_for(kind: StringName) -> bool:
	return _tiles_by_kind.has(kind)


## How many tiles of the TileSet say their cell is of this kind.
func tile_count_for(kind: StringName) -> int:
	return _tiles_by_kind.get(kind, []).size()


## The atlas coordinates of every base tile (alternative 0) of the TileSet whose cell is of this kind, in the order
## the TileSet lists them. A tool that wants to vary the art within a kind (a checker of two floor tiles) picks
## among these and still states the kind through paint().
func atlas_coords_of_kind(kind: StringName) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for tile: Dictionary in _tiles_by_kind.get(kind, []):
		if tile["alternative_tile"] == 0 and tile["atlas_coords"] not in coords:
			coords.append(tile["atlas_coords"])
	return coords


## The kinds the TileSet can paint, in CellKinds order.
func paintable_kinds() -> Array[StringName]:
	var kinds: Array[StringName] = []
	for kind: StringName in CellKinds.RULES_BY_KIND:
		if _tiles_by_kind.has(kind):
			kinds.append(kind)
	return kinds


## Paints `cell` with a tile of `kind`: the one at `preferred_atlas_coords` when that tile is of the kind,
## else (only when no preference was given) the first tile of the kind. Returns "" or the problem.
func paint(layer: TileMapLayer, cell: Vector2i, kind: StringName, preferred_atlas_coords := NO_PREFERENCE) -> String:
	if layer.tile_set != _tile_set:
		return "the layer '%s' does not use the TileSet this painter was made for" % layer.name
	if not CellKinds.is_known(kind):
		return "'%s' is not a cell kind (kinds: %s)" % [kind, ", ".join(CellKinds.RULES_BY_KIND.keys())]
	var tiles_of_kind: Array = _tiles_by_kind.get(kind, [])
	if tiles_of_kind.is_empty():
		return "the TileSet has no tile whose kind is '%s', so cell %s cannot be painted: add one in the TileSet editor (Custom Data -> kind) when its art exists" % [kind, cell]
	var chosen: Dictionary = tiles_of_kind[0]
	if preferred_atlas_coords != NO_PREFERENCE:
		chosen = {}
		for tile: Dictionary in tiles_of_kind:
			if tile["atlas_coords"] == preferred_atlas_coords:
				chosen = tile
				break
		if chosen.is_empty():
			return "cell %s is meant to be '%s' but the tile at %s is not: it reads as '%s'" % [cell, kind, preferred_atlas_coords, kind_of_atlas_tile(preferred_atlas_coords)]
	layer.set_cell(cell, chosen["source_id"], chosen["atlas_coords"], chosen["alternative_tile"])
	return ""


## The kind of the base tile (alternative 0) at these atlas coordinates of the first source, or an empty
## name when there is no such tile.
func kind_of_atlas_tile(atlas_coords: Vector2i) -> StringName:
	for kind: StringName in _tiles_by_kind:
		for tile: Dictionary in _tiles_by_kind[kind]:
			if tile["atlas_coords"] == atlas_coords and tile["alternative_tile"] == 0:
				return kind
	return &""


## cell -> kind for every painted cell of the layer, read the way the game reads it (CellKinds.kind_of_tile),
## floor included.
func kinds_by_cell(layer: TileMapLayer) -> Dictionary:
	var kind_by_cell: Dictionary = {}
	for cell in layer.get_used_cells():
		var tile_data := layer.get_cell_tile_data(cell)
		if tile_data != null:
			kind_by_cell[cell] = CellKinds.kind_of_tile(layer.tile_set, tile_data)
	return kind_by_cell
