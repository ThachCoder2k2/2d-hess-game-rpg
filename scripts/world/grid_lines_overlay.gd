@tool
class_name GridLinesOverlay
extends Node2D

## Draws the room's cell grid as one node instead of a Line2D per line. Decorative
## overlay (allowed to use _draw); shows in editor and at runtime.

@export var grid_origin := Vector2(64, 36):
	set(value):
		grid_origin = value
		queue_redraw()
@export_range(4, 128) var cell_size := 32:
	set(value):
		cell_size = value
		queue_redraw()
@export_range(1, 64) var columns := 16:
	set(value):
		columns = value
		queue_redraw()
@export_range(1, 64) var rows := 9:
	set(value):
		rows = value
		queue_redraw()
@export var line_color := Color(0.0941176, 0.0627451, 0.0705882, 0.42):
	set(value):
		line_color = value
		queue_redraw()
@export_range(0.25, 8.0, 0.25) var line_width := 1.0:
	set(value):
		line_width = value
		queue_redraw()


func _draw() -> void:
	var width := columns * cell_size
	var height := rows * cell_size
	for i in columns + 1:
		var x := grid_origin.x + i * cell_size
		draw_line(Vector2(x, grid_origin.y), Vector2(x, grid_origin.y + height), line_color, line_width)
	for j in rows + 1:
		var y := grid_origin.y + j * cell_size
		draw_line(Vector2(grid_origin.x, y), Vector2(grid_origin.x + width, y), line_color, line_width)
