class_name CouragePips
extends HudWidget

## The pawn's Courage: a caption and one pip per point, filled for each point the pawn still has (docs/game-base-plan.md
## D-29). Draws the HudSnapshot's player_courage_current and player_courage_max; a world with no hero shows full
## Courage, so a room that has no pawn yet is not drawn as a defeat.
##
## The row holds at most MOST_PIPS pips, the number the asset list's Courage plate holds (hud_cluster_plates: "up to 5
## Courage pips"), so the extra Courage assist (+2) still fits.

## The most pips the row draws.
const MOST_PIPS := 5

## The scene of one pip (courage_pip.tscn).
@export var pip_scene: PackedScene
## How many full pips a world with no hero shows.
@export var pips_without_hero := 3

@onready var caption_label: Label = $Caption
@onready var pip_row: HBoxContainer = $PipRow

## The pip count and the filled count that are on screen, (-1, -1) before the first draw.
var _drawn_total := -1
var _drawn_filled := -1


func refresh(snapshot: HudSnapshot) -> void:
	var total := pips_without_hero
	var filled := pips_without_hero
	if snapshot.player_entity != 0:
		total = clampi(maxi(snapshot.player_courage_max, snapshot.player_courage_current), 0, MOST_PIPS)
		filled = clampi(snapshot.player_courage_current, 0, total)
	if pip_row == null or (total == _drawn_total and filled == _drawn_filled):
		return
	_drawn_total = total
	_drawn_filled = filled
	while pip_row.get_child_count() > total:
		var surplus := pip_row.get_child(pip_row.get_child_count() - 1)
		pip_row.remove_child(surplus)
		surplus.queue_free()
	while pip_row.get_child_count() < total:
		pip_row.add_child(pip_scene.instantiate())
	for index in total:
		(pip_row.get_child(index) as CouragePip).show_filled(index < filled)


func forget_drawn() -> void:
	_drawn_total = -1
	_drawn_filled = -1


## How many pips are on screen.
func pip_count() -> int:
	return pip_row.get_child_count() if pip_row != null else 0


## How many of them are filled (Courage the pawn has).
func filled_count() -> int:
	var count := 0
	for pip in pip_row.get_children():
		if (pip as CouragePip).is_filled:
			count += 1
	return count


## How many are empty (Courage the pawn has lost).
func empty_count() -> int:
	return pip_count() - filled_count()
