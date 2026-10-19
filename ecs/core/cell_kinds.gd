class_name CellKinds
extends RefCounted

## The vocabulary of what a board cell is made of (docs/game-base-plan.md 5.11), and the three rules
## that make a kind mean something to the grid: can a piece walk on it, does a ray (a charge, a lane, a
## line of fire) stop at it, and can a leap pass over it. EcsGrid.cell_kind_by_cell stores the kind of
## every cell that is not plain floor; the TileSets paint it through their `kind` custom-data layer.
##
## A kind is a StringName id. The set is closed and lives here, in one table, so a skill, a hazard or a
## drawing routine asks the table and never repeats a list of kinds of its own (a new kind is one row
## here, and `test_grid_cell_kinds` fails if a row is missing a rule).

## Plain ground. Every cell the grid does not list is floor.
const FLOOR := &"floor"
## A wall: nothing walks on it, a ray stops at it, a leap cannot cross it. A closed gate is a wall too.
const WALL := &"wall"
## A hole in the floor (a torn page, a gap between toy tracks): nothing walks on it, a ray flies over it,
## a leap crosses it. Chalk Path (M10) turns gap cells into chalk for a while.
const GAP := &"gap"
## A block the pawn can leap but not walk through (the Chalk Block, a toy brick): nothing walks on it, a
## ray stops at it (it is cover), a leap crosses it.
const LEAPABLE_BLOCK := &"leapable_block"
## Chalk laid over a gap: it can be walked on and rays fly over it. It is a cell effect (M10) that expires.
const CHALK := &"chalk"
## Corrupted floor (the Rule Engine's rewritten tiles, M13): it can be walked on, and it is the hazard a
## cell effect acts on.
const CORRUPTION := &"corruption"

## The names of the two custom-data layers a TileSet carries. `solid` is the original one (true: a wall);
## `kind` joins it and, when a tile fills it in, wins over `solid`.
const TILE_SOLID_LAYER := "solid"
const TILE_KIND_LAYER := "kind"

## kind -> { "walkable": bool, "stops_rays": bool, "leapable": bool, "about": String }. The rules of
## each kind, in display order:
##   walkable    a piece may stand on it and step onto it (false: the cell is in EcsGrid.blocked_cells);
##   stops_rays  a ray (EcsGrid.ray_cells) ends before this cell;
##   leapable    a leap may pass over it on its way to the landing cell (EcsGrid.can_leap_over).
const RULES_BY_KIND: Dictionary = {
	FLOOR: {"walkable": true, "stops_rays": false, "leapable": true, "about": "plain ground"},
	WALL: {"walkable": false, "stops_rays": true, "leapable": false, "about": "a wall or a closed gate"},
	GAP: {"walkable": false, "stops_rays": false, "leapable": true, "about": "a hole in the floor: rays and leaps cross it, feet cannot"},
	LEAPABLE_BLOCK: {"walkable": false, "stops_rays": true, "leapable": true, "about": "a block: cover from rays, leapable"},
	CHALK: {"walkable": true, "stops_rays": false, "leapable": true, "about": "chalk laid over a gap"},
	CORRUPTION: {"walkable": true, "stops_rays": false, "leapable": true, "about": "corrupted floor"},
}

## The kinds a ray stops at when its caller does not say (EcsGrid.ray_cells), taken from the table.
static func default_ray_stop_kinds() -> Array[StringName]:
	var stopping: Array[StringName] = []
	for kind: StringName in RULES_BY_KIND:
		if RULES_BY_KIND[kind]["stops_rays"]:
			stopping.append(kind)
	return stopping


static func is_known(kind: StringName) -> bool:
	return RULES_BY_KIND.has(kind)


## True when a piece can stand on a cell of this kind. An unknown kind is not walkable.
static func is_walkable(kind: StringName) -> bool:
	return RULES_BY_KIND.get(kind, {}).get("walkable", false)


## True when a ray ends before a cell of this kind. An unknown kind stops it.
static func stops_rays(kind: StringName) -> bool:
	return RULES_BY_KIND.get(kind, {}).get("stops_rays", true)


## True when a leap may pass over a cell of this kind. An unknown kind cannot be crossed.
static func is_leapable(kind: StringName) -> bool:
	return RULES_BY_KIND.get(kind, {}).get("leapable", false)


## What a tile of `tile_set` says its cell is made of. The `kind` layer wins when the tile fills it in
## with a known kind; otherwise `solid` decides (true: wall, false: floor), which is how every tile that
## only knows `solid` kept meaning what it always meant. A kind name nobody declared is reported as an
## error and ignored, so a typo in the editor cannot silently make a cell something else.
static func kind_of_tile(tile_set: TileSet, tile_data: TileData) -> StringName:
	if tile_set.has_custom_data_layer_by_name(TILE_KIND_LAYER):
		var painted_kind := StringName(String(tile_data.get_custom_data(TILE_KIND_LAYER)).strip_edges())
		if not painted_kind.is_empty():
			if is_known(painted_kind):
				return painted_kind
			push_error("a tile of a TileSet names the cell kind '%s', which does not exist (kinds: %s); it is read by its 'solid' flag instead" % [painted_kind, ", ".join(RULES_BY_KIND.keys())])
	if tile_set.has_custom_data_layer_by_name(TILE_SOLID_LAYER) and bool(tile_data.get_custom_data(TILE_SOLID_LAYER)):
		return WALL
	return FLOOR
