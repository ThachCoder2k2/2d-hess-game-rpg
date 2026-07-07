@tool
class_name HeroStartMarker
extends GridMarker

@export var show_editor_preview := true:
	set(value):
		show_editor_preview = value
		_sync_preview_visibility()


func get_hero_start_cell() -> Vector2i:
	return grid_cell


func _ready_marker() -> void:
	_sync_preview_visibility()


func _sync_preview_visibility() -> void:
	var preview := get_node_or_null("Preview") as CanvasItem
	if preview != null:
		preview.visible = Engine.is_editor_hint() and show_editor_preview


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_circle(Vector2.ZERO, 11.0, Color("#fff4d6", 0.18))
	draw_circle(Vector2.ZERO, 7.0, Color("#fff4d6", 0.78))
	draw_rect(Rect2(Vector2(-9, -9), Vector2(18, 18)), Color("#493f3a", 0.75), false, 1.5)
