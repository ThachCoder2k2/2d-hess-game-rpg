class_name RankBadge
extends HudWidget

## The Rank label as the child's blue tally marks, one mark for each step of the rank (docs/game-base-plan.md D-13, 6.1,
## D-29): a story label that reads defeated-boss flags and that nothing else reads, and never called a level. Draws the
## HudSnapshot's rank_label; the badge is hidden while the snapshot has none (0), which is every frame before M7c
## fills it, so the first minutes do not show a tally of a system that has not started.

## The most marks the badge draws (the Rank label goes from 2 to 8).
const MOST_MARKS := 8

## The colour of a mark: the child's blue crayon.
@export var mark_color := Color("#4f8fe0")
## The size of one mark in pixels.
@export var mark_size := Vector2(2, 10)

@onready var mark_row: HBoxContainer = $MarkRow

## The rank on screen. -1 before the first draw.
var _drawn_rank := -1


func refresh(snapshot: HudSnapshot) -> void:
	var rank := clampi(snapshot.rank_label, 0, MOST_MARKS)
	if mark_row == null or rank == _drawn_rank:
		return
	_drawn_rank = rank
	visible = rank > 0
	for mark in mark_row.get_children():
		mark_row.remove_child(mark)
		mark.queue_free()
	for _step in rank:
		var mark := ColorRect.new()
		mark.custom_minimum_size = mark_size
		mark.color = mark_color
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark_row.add_child(mark)


func forget_drawn() -> void:
	_drawn_rank = -1


## How many tally marks are on screen.
func mark_count() -> int:
	return mark_row.get_child_count() if mark_row != null else 0
