@tool
class_name TraversalGapMarker
extends GridMarker

## A mandatory crossing (docs/game-base-plan.md 5.7, 6.3, D-41, R22): a hole in the floor the critical path
## cannot go round, which the pawn has to cross with a verb it has just learned. The marker only SAYS SO; it
## paints nothing and decides nothing. The cells it covers are gap cells in the room's tiles (the layout builder
## paints them); EcsBoot bakes the marker into EcsGrid.marker_by_cell under KIND, one entry per covered cell; the
## verbs that cross it (Rule Step, Chalk Path: M7 and M10) read it. Behaviour arrives with those milestones.
##
## Why a marker and not just a gap: Chalk Path costs Believe, and a pawn with none left and no enemy to hit would be
## stuck at a door. A crossing flagged `free_when_calm` costs 0 Believe when no hostile is alive, still shows the
## hand, and counts as a child call (R22: the critical path forces at least three of them before the Queen).

## The key of this marker's entries in EcsGrid.marker_by_cell.
const KIND := &"traversal_gap"
## The verbs that cross a gap on the critical path (Eraser Guard crosses a Rule Mark, a different marker).
const VERBS: Array[StringName] = [&"chalk_path", &"rule_step"]
## Chalk Path covers up to three consecutive gap cells in a straight line (§6.3).
const MAX_LENGTH := 3

## Which verb crosses this gap: `chalk_path` (the page tear: up to three cells) or `rule_step` (the one-cell hole
## a leap clears).
@export var verb: StringName = &"chalk_path"
## How many gap cells the crossing covers, counting from `grid_cell` along `direction`.
@export_range(1, 3) var length := 1
## The straight line the gap runs along, from grid_cell: one of (1, 0), (-1, 0), (0, 1), (0, -1).
@export var direction := Vector2i.RIGHT
## True when crossing it costs 0 Believe while no hostile is alive (D-41). Only a Chalk Path crossing costs Believe.
@export var free_when_calm := true


## The cells the crossing covers, in order from grid_cell.
func get_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for step in range(maxi(length, 0)):
		cells.append(grid_cell + direction * step)
	return cells


## What EcsBoot copies to each covered cell of EcsGrid.marker_by_cell[KIND]: the verb, whether the cast is free
## while calm, the first cell and the number of cells of the whole crossing (so a system that finds one
## cell finds the rest), and the marker's node name.
func get_baked_data() -> Dictionary:
	return {
		"verb": verb,
		"free_when_calm": free_when_calm,
		"first_cell": grid_cell,
		"length": length,
		"direction": direction,
		"marker_name": String(name),
	}


func configuration_problems() -> PackedStringArray:
	var problems := PackedStringArray()
	if verb not in VERBS:
		problems.append("verb '%s' does not cross a gap (use chalk_path or rule_step)." % verb)
	if length < 1 or length > MAX_LENGTH:
		problems.append("length %d is out of range: a crossing covers 1 to %d cells." % [length, MAX_LENGTH])
	if verb == &"rule_step" and length > 1:
		problems.append("A Rule Step clears a one-cell hole: length must be 1 (use chalk_path for a tear).")
	if direction not in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		problems.append("direction %s must be a straight cardinal step: (1, 0), (-1, 0), (0, 1) or (0, -1)." % direction)
	else:
		var board := board_cells()
		for cell in get_cells():
			if cell.x < 0 or cell.y < 0 or cell.x >= board.x or cell.y >= board.y:
				problems.append("The crossing covers cell %s, which is off the %d x %d board." % [cell, board.x, board.y])
				break
	return problems


func _get_configuration_warnings() -> PackedStringArray:
	return configuration_problems()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var color := Color("#8fc8e8", 0.9)
	for cell in get_cells():
		var offset := Vector2((cell - grid_cell) * PREVIEW_CELL_SIZE)
		draw_rect(Rect2(offset - Vector2(14, 14), Vector2(28, 28)), Color(color, 0.18))
		draw_rect(Rect2(offset - Vector2(14, 14), Vector2(28, 28)), color, false, 1.5)
		draw_line(offset + Vector2(-8, 8), offset + Vector2(8, -8), color, 2.0)
