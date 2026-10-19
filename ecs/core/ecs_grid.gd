class_name EcsGrid
extends RefCounted

## The spatial-index service for entities: occupancy, blocks, and the
## reserve -> commit movement protocol, ported 1:1 from GridWorld
## (scripts/core/grid_world.gd) with int entity ids instead of Node refs.
## The flip phase (plan D) decides which of the two survives.
##
## Since M3a (docs/game-base-plan.md 5.11) it also knows what each cell is made of (cell_kind_by_cell,
## the vocabulary in CellKinds), counts the changes of that layout (layout_version) so the pathfinder is
## built once per layout and not once per question, and offers the two services the attack and skill
## frameworks stand on: a leap that frees its origin at takeoff and reserves its landing cell
## (begin_leap), and a ray that stops at blockers (ray_cells).

## Where a board's top-left corner sits when the board does not fit the view on that axis (a scrolling
## world has nothing to centre), and where every board sat before M3a: the margin that centres the
## default 16x9 board in the 640x360 view. A room that fits the view gets centred_origin() instead.
const FALLBACK_ORIGIN := Vector2(64, 36)

## The answer of "which cell?" when there is none: no reservation, no landing. Far outside any board.
const NO_CELL := Vector2i(-999, -999)

var cell_size := 32
## World position of the top-left corner of cell (0, 0). Each room sets its own (EcsBoot.shape_grid):
## the board centred in the view, so a 16x9 room starts at (64, 36) and an 18x9 arena at (32, 36).
var grid_origin := FALLBACK_ORIGIN
## The cells of the board. Changing it changes the layout (layout_version moves), because the cached
## pathfinder covers exactly this rectangle.
var bounds := Rect2i(0, 0, 16, 9):
	set(new_bounds):
		if new_bounds != bounds:
			bounds = new_bounds
			_layout_version += 1

## How many times the layout has changed: a cell's kind (set_cell_kind, add_block, open_gate) or the
## bounds. Anything that caches a fact about the terrain (the pathfinder here, a drawing of the cell
## kinds later) keeps the version it was built for and rebuilds when this one has moved. Starts at 0 and
## only grows; a change that leaves a cell as it was does not count.
var layout_version: int:
	get:
		return _layout_version

## cell -> kind (StringName, see CellKinds) for every cell that is NOT plain floor. A cell the grid does
## not list is floor. Written only by set_cell_kind(), which keeps blocked_cells and layout_version in
## step; the TileSets' `kind` layer is where the kinds are authored (EcsBoot.apply_tile_kinds).
var cell_kind_by_cell: Dictionary = {}
## cell -> true. Every cell whose kind cannot be walked on (CellKinds.is_walkable): walls, gaps, blocks.
## Derived from cell_kind_by_cell and kept by set_cell_kind(); read it, never write it.
var blocked_cells: Dictionary = {}
## cell -> {"effect": StringName, "kind_before": StringName, "time_left": float}. The temporary changes
## of a cell's kind that are in progress (chalk over a gap, a corrupted tile): the store of the
## CellEffectSystem (M10, stage 4 of the schedule), which ticks `time_left` down and gives the cell back
## its `kind_before` through set_cell_kind(). Empty until the first cell effect exists.
var cell_effect_by_cell: Dictionary = {}
## cell -> entity id. Who stands on each cell right now.
var entity_by_cell: Dictionary = {}
## entity id -> cell. Reverse of entity_by_cell, both directions O(1).
var cell_by_entity: Dictionary = {}
## destination cell -> entity id. A mover claims its destination BEFORE the
## slide starts (begin_move); the claim clears when the step lands
## (finish_move). While sliding, origin stays occupied and destination stays
## reserved — nobody can race into either.
var move_reservations: Dictionary = {}
## entity id -> {"from": Vector2i, "to": Vector2i}. Every entity that is in the air (begin_leap ...
## finish_leap): where it took off and the landing cell it has reserved. An airborne entity stands on NO
## cell (it is in neither entity_by_cell nor cell_by_entity) and holds one reservation, its landing cell.
var leap_by_entity: Dictionary = {}
## cell -> {"zone": StringName, "entry": StringName, "requires_room_clear": bool, "locked_message": String}.
## Door cells baked from ZoneExitMarkers; the player landing here triggers a zone travel, or, on a door
## that needs the room cleared first, the zone_exit_locked event carrying the door's own locked_message.
var exit_by_cell: Dictionary = {}
## cell -> {"id": StringName, "message": String}. Player-only unlock cells
## baked from PlayerUnlockMarker nodes; the player landing here gains a flag.
var player_unlock_by_cell: Dictionary = {}
## cell -> {"id": StringName, "opens_from": Vector2i}. Closed shortcut gates
## (also present in blocked_cells); the player moving in opens_from's
## direction onto the cell opens the gate permanently.
var gate_by_cell: Dictionary = {}
## marker kind (StringName) -> { cell (Vector2i) -> data (Dictionary) }. The one store for every kind of room
## marker that has no dictionary of its own above (a traversal gap, a trigger, a rescue spot, a clue prop:
## M5 and M6 add them), so a new kind of marker adds a baker and no field to the grid
## (docs/game-base-plan.md 14.1). The kind is the marker's own id and the data is what its baker copied from
## the marker's exports. Written by add_marker() and remove_marker(); read with marker_at() and marker_cells().
var marker_by_cell: Dictionary = {}

## What layout_version reads. Moved only by this class, when the terrain changes.
var _layout_version := 0
## The pathfinder for the layout whose version is _pathfinder_layout_version (see get_grid_path), or null
## before the first question.
var _pathfinder: AStarGrid2D = null
var _pathfinder_layout_version := -1
## How many pathfinders this grid has built in its life: one per layout that was asked about. Read by the
## tests and the room tick budget to prove that a question does not build one.
var pathfinder_build_count := 0


## The grid origin that centres a board of `board_cells` cells in a view of `view_size` pixels, in whole
## pixels (docs/game-base-plan.md D-02, D-30: static framing with a per-room centred origin). On an axis
## where the board is larger than the view there is nothing to centre, the camera scrolls, and the origin
## keeps FALLBACK_ORIGIN on that axis.
static func centred_origin(board_cells: Vector2i, board_cell_size: int, view_size: Vector2) -> Vector2:
	var board_pixels := Vector2(board_cells * board_cell_size)
	var origin := FALLBACK_ORIGIN
	if board_pixels.x <= view_size.x:
		origin.x = floorf((view_size.x - board_pixels.x) * 0.5)
	if board_pixels.y <= view_size.y:
		origin.y = floorf((view_size.y - board_pixels.y) * 0.5)
	return origin


## Unbars a gate: the cell becomes ordinary floor. Persistence is the
## caller's job (MovementSystem emits, the bridge asks the save service).
func open_gate(cell: Vector2i) -> void:
	gate_by_cell.erase(cell)
	set_cell_kind(cell, CellKinds.FLOOR)


## Puts a marker of `kind` on `cell` with the data its baker copied from it. False and nothing changed when the
## cell is off the board or already holds a marker of that kind (a cell holds at most one marker per kind).
func add_marker(kind: StringName, cell: Vector2i, data: Dictionary = {}) -> bool:
	if not is_inside(cell) or has_marker(kind, cell):
		return false
	if not marker_by_cell.has(kind):
		marker_by_cell[kind] = {}
	marker_by_cell[kind][cell] = data
	return true


## Takes the marker of `kind` off `cell`. True when there was one.
func remove_marker(kind: StringName, cell: Vector2i) -> bool:
	if not has_marker(kind, cell):
		return false
	marker_by_cell[kind].erase(cell)
	if marker_by_cell[kind].is_empty():
		marker_by_cell.erase(kind)
	return true


func has_marker(kind: StringName, cell: Vector2i) -> bool:
	return marker_by_cell.has(kind) and marker_by_cell[kind].has(cell)


## The data of the marker of `kind` on `cell`, or an empty dictionary when there is none.
func marker_at(kind: StringName, cell: Vector2i) -> Dictionary:
	if not has_marker(kind, cell):
		return {}
	return marker_by_cell[kind][cell]


## Every cell holding a marker of `kind`, row by row and left to right.
func marker_cells(kind: StringName) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if marker_by_cell.has(kind):
		for cell: Vector2i in marker_by_cell[kind]:
			cells.append(cell)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	return cells


func cell_to_world(cell: Vector2i) -> Vector2:
	return grid_origin + Vector2(cell * cell_size) + Vector2.ONE * cell_size * 0.5


func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(floor((world_position.x - grid_origin.x) / cell_size), floor((world_position.y - grid_origin.y) / cell_size))


func is_inside(cell: Vector2i) -> bool:
	return bounds.has_point(cell)


func is_walkable(cell: Vector2i) -> bool:
	return is_inside(cell) and not blocked_cells.has(cell)


## Makes the cell a wall. False when it is off the board or a piece stands on it or is about to.
func add_block(cell: Vector2i) -> bool:
	return set_cell_kind(cell, CellKinds.WALL)


## What the cell is made of (a CellKinds id); floor for a cell the grid lists nothing about, and for a
## cell off the board (there is nothing there: ask is_inside first).
func kind_at(cell: Vector2i) -> StringName:
	return cell_kind_by_cell.get(cell, CellKinds.FLOOR)


## Gives the cell a kind, and keeps everything derived from it in step: cell_kind_by_cell (floor is
## stored as the absence of an entry), blocked_cells, and layout_version (moved only when the kind really
## changed). The only way the terrain changes. Returns false and changes nothing when the cell is off the
## board, the kind does not exist, or the new kind cannot be walked on while a piece stands on the cell
## or has reserved it (a wall never grows under a piece; the caller waits and asks again). Returns true,
## changing nothing, when the cell already is that kind.
func set_cell_kind(cell: Vector2i, kind: StringName) -> bool:
	if not is_inside(cell) or not CellKinds.is_known(kind):
		return false
	if kind_at(cell) == kind:
		return true
	var walkable := CellKinds.is_walkable(kind)
	if not walkable and (entity_by_cell.has(cell) or move_reservations.has(cell)):
		return false
	if kind == CellKinds.FLOOR:
		cell_kind_by_cell.erase(cell)
	else:
		cell_kind_by_cell[cell] = kind
	if walkable:
		blocked_cells.erase(cell)
	else:
		blocked_cells[cell] = true
	_layout_version += 1
	return true


## Every cell of this kind, row by row and left to right. Floor is every cell the grid lists nothing for,
## so it is answered by walking the board.
func cells_of_kind(kind: StringName) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if kind == CellKinds.FLOOR:
		for y in range(bounds.position.y, bounds.end.y):
			for x in range(bounds.position.x, bounds.end.x):
				if not cell_kind_by_cell.has(Vector2i(x, y)):
					cells.append(Vector2i(x, y))
		return cells
	for cell: Vector2i in cell_kind_by_cell:
		if cell_kind_by_cell[cell] == kind:
			cells.append(cell)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	return cells


func register_entity(entity_id: int, cell: Vector2i) -> bool:
	if not is_walkable(cell) or entity_by_cell.has(cell) or move_reservations.has(cell):
		return false
	entity_by_cell[cell] = entity_id
	cell_by_entity[entity_id] = cell
	return true


## Takes the entity off the board: its cell, its reservation and, if it is in the air, its leap (a piece
## that falls mid-leap frees its landing cell and leaves nothing behind).
func unregister_entity(entity_id: int) -> void:
	if not cell_by_entity.has(entity_id) and not leap_by_entity.has(entity_id):
		return
	if cell_by_entity.has(entity_id):
		var cell: Vector2i = cell_by_entity[entity_id]
		entity_by_cell.erase(cell)
		cell_by_entity.erase(entity_id)
	leap_by_entity.erase(entity_id)
	for reserved_cell in move_reservations.keys():
		if move_reservations[reserved_cell] == entity_id:
			move_reservations.erase(reserved_cell)


func entity_at(cell: Vector2i) -> int:
	return entity_by_cell.get(cell, 0)


func can_begin_move(entity_id: int, destination: Vector2i) -> bool:
	if not is_walkable(destination):
		return false
	if entity_by_cell.has(destination) and entity_by_cell[destination] != entity_id:
		return false
	if move_reservations.has(destination) and move_reservations[destination] != entity_id:
		return false
	return cell_by_entity.has(entity_id)


func begin_move(entity_id: int, destination: Vector2i) -> bool:
	if not can_begin_move(entity_id, destination):
		return false
	move_reservations[destination] = entity_id
	return true


func finish_move(entity_id: int, destination: Vector2i) -> void:
	if not cell_by_entity.has(entity_id):
		return
	var origin: Vector2i = cell_by_entity[entity_id]
	entity_by_cell.erase(origin)
	move_reservations.erase(destination)
	entity_by_cell[destination] = entity_id
	cell_by_entity[entity_id] = destination


## The cell this entity has reserved (a step's destination or a leap's landing cell), or NO_CELL.
func get_reserved_cell(entity_id: int) -> Vector2i:
	for reserved_cell in move_reservations:
		if move_reservations[reserved_cell] == entity_id:
			return reserved_cell
	return NO_CELL


# --------------------------------------------------------------------------- leaps (docs/game-base-plan.md 5.11)
## Whether `entity_id` may take off from `from` for `to`: it stands on `from`, is not mid-step or already in
## the air, and `to` is another cell of the board that can be walked on and that nobody holds or has reserved.
## It does not look at what lies between the two cells: that is the skill's rule (can_leap_over asks it).
func can_begin_leap(entity_id: int, from: Vector2i, to: Vector2i) -> bool:
	if from == to or leap_by_entity.has(entity_id):
		return false
	if not cell_by_entity.has(entity_id) or cell_by_entity[entity_id] != from or get_reserved_cell(entity_id) != NO_CELL:
		return false
	return is_walkable(to) and not entity_by_cell.has(to) and not move_reservations.has(to)


## Takeoff. Unlike a step, which holds its origin until it lands, a leap lets go of the origin at once (a
## piece may enter it while the leaper is in the air) and reserves the landing cell (nobody may enter or
## reserve it before the leaper lands). While it is in the air the entity stands on no cell, so nothing
## aimed at a cell can hit it: that is what "untargetable in flight" means to the grid, and HealthSystem
## ignores damage to an airborne entity for the same reason. False and nothing changed when
## can_begin_leap says no.
func begin_leap(entity_id: int, from: Vector2i, to: Vector2i) -> bool:
	if not can_begin_leap(entity_id, from, to):
		return false
	entity_by_cell.erase(from)
	cell_by_entity.erase(entity_id)
	move_reservations[to] = entity_id
	leap_by_entity[entity_id] = {"from": from, "to": to}
	return true


## Touchdown: the entity stands on the cell it reserved. False when it was not in the air.
func finish_leap(entity_id: int) -> bool:
	if not leap_by_entity.has(entity_id):
		return false
	var landing_cell: Vector2i = leap_by_entity[entity_id]["to"]
	move_reservations.erase(landing_cell)
	entity_by_cell[landing_cell] = entity_id
	cell_by_entity[entity_id] = landing_cell
	leap_by_entity.erase(entity_id)
	return true


func is_airborne(entity_id: int) -> bool:
	return leap_by_entity.has(entity_id)


## The cell an airborne entity will land on, or NO_CELL when it is not in the air.
func leap_landing_cell(entity_id: int) -> Vector2i:
	if not leap_by_entity.has(entity_id):
		return NO_CELL
	return leap_by_entity[entity_id]["to"]


## Whether a leap may pass over this cell on its way to its landing cell: a cell of the board whose kind
## allows it (CellKinds: floor, gap, leapable block, chalk and corruption yes, a wall and a closed gate no)
## that is not a door. Pieces never matter: a leap passes over them.
func can_leap_over(cell: Vector2i) -> bool:
	return is_inside(cell) and CellKinds.is_leapable(kind_at(cell)) and not exit_by_cell.has(cell)


# --------------------------------------------------------------------------- rays (docs/game-base-plan.md 5.11)
## The cells a ray covers, nearest first: it starts on the cell next to `origin` in `direction` (the cardinal
## directions and the diagonals, any non-zero step) and goes on for at most `max_cells` cells, ending BEFORE
## the first cell that is off the board or whose kind is in `stop_kinds` (the kinds that stop a ray,
## CellKinds.default_ray_stop_kinds() unless the caller names its own: walls and blocks, never gaps). The
## origin is not in the list. Rook charges, Bishop lanes and Queen lines are made of this.
##
## Pieces are not terrain: the ray does not stop at a piece, and every cell of the list may hold one
## (entity_at). With `stop_before_occupied` the ray also ends before the first cell a piece stands on or has
## reserved, for a charge that cannot run through anyone.
func ray_cells(origin: Vector2i, direction: Vector2i, max_cells: int, stop_kinds: Array[StringName] = CellKinds.default_ray_stop_kinds(), stop_before_occupied := false) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if direction == Vector2i.ZERO:
		return cells
	var cell := origin
	for _step in range(max_cells):
		cell += direction
		if not is_inside(cell) or kind_at(cell) in stop_kinds:
			break
		if stop_before_occupied and (entity_by_cell.has(cell) or move_reservations.has(cell)):
			break
		cells.append(cell)
	return cells


## cell -> pickup entity id. Weapons lying on the floor, one per cell.
var item_by_cell: Dictionary = {}


func register_item(item_entity_id: int, cell: Vector2i) -> bool:
	if not is_inside(cell) or item_by_cell.has(cell):
		return false
	item_by_cell[cell] = item_entity_id
	return true


func take_item(cell: Vector2i) -> int:
	var item_entity_id: int = item_by_cell.get(cell, 0)
	item_by_cell.erase(cell)
	return item_entity_id


func item_at(cell: Vector2i) -> int:
	return item_by_cell.get(cell, 0)


func get_item_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in item_by_cell:
		cells.append(cell)
	return cells


func get_occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in entity_by_cell:
		cells.append(cell)
	return cells


func get_reservation_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in move_reservations:
		cells.append(cell)
	return cells


## Pathing — ported 1:1 from GridWorld (other movers and reservations are
## solid unless they sit on the goal).
##
## The walls are built into one AStarGrid2D per layout_version and kept (_pathfinder_for_this_layout);
## a question marks the pieces and reservations that are in the way solid for the length of the question
## and puts the grid back as it found it, so the answer is the one a pathfinder built from scratch for that
## question would give, cell for cell (tests/ecs/test_path_cache.gd checks that against the old
## build-per-question code). Building one costs a pass over the whole board, which a 72 x 40 world makes
## expensive, and an enemy asks a dozen times per decision.
func get_grid_path(entity_id: int, origin: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if not is_inside(origin) or not is_inside(goal):
		return []
	var pathfinder := _pathfinder_for_this_layout()
	var solid_for_this_question: Array[Vector2i] = []
	for cell: Vector2i in entity_by_cell:
		if entity_by_cell[cell] != entity_id and cell != goal and not pathfinder.is_point_solid(cell):
			pathfinder.set_point_solid(cell)
			solid_for_this_question.append(cell)
	for cell: Vector2i in move_reservations:
		if move_reservations[cell] != entity_id and cell != goal and not pathfinder.is_point_solid(cell):
			pathfinder.set_point_solid(cell)
			solid_for_this_question.append(cell)
	var path: Array[Vector2i] = pathfinder.get_id_path(origin, goal)
	for cell in solid_for_this_question:
		pathfinder.set_point_solid(cell, false)
	return path


## The pathfinder that holds the walls of the current layout, built when there is none or when the layout
## has changed since it was built (layout_version moved). Only walls, gaps and blocks (blocked_cells) are
## solid in it between questions.
func _pathfinder_for_this_layout() -> AStarGrid2D:
	if _pathfinder != null and _pathfinder_layout_version == _layout_version:
		return _pathfinder
	var pathfinder := AStarGrid2D.new()
	pathfinder.region = bounds
	pathfinder.cell_size = Vector2.ONE
	pathfinder.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	pathfinder.update()
	for cell: Vector2i in blocked_cells:
		if bounds.has_point(cell):
			pathfinder.set_point_solid(cell)
	_pathfinder = pathfinder
	_pathfinder_layout_version = _layout_version
	pathfinder_build_count += 1
	return pathfinder


func get_path_distance(entity_id: int, origin: Vector2i, goal: Vector2i) -> int:
	var path := get_grid_path(entity_id, origin, goal)
	return path.size() - 1 if not path.is_empty() else 999999


func get_next_path_cell(entity_id: int, origin: Vector2i, goal: Vector2i) -> Vector2i:
	var path := get_grid_path(entity_id, origin, goal)
	return path[1] if path.size() > 1 else origin


func is_plannable_cell(entity_id: int, cell: Vector2i) -> bool:
	if not is_walkable(cell):
		return false
	if entity_by_cell.has(cell) and entity_by_cell[cell] != entity_id:
		return false
	if move_reservations.has(cell) and move_reservations[cell] != entity_id:
		return false
	return true


func get_destinations(entity_id: int, origin: Vector2i, directions: Array[Vector2i]) -> Array[Vector2i]:
	var destinations: Array[Vector2i] = []
	for direction in directions:
		var destination: Vector2i = origin + direction
		if can_begin_move(entity_id, destination):
			destinations.append(destination)
	return destinations
