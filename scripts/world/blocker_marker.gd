@tool
class_name BlockerMarker
extends GridMarker

@export var show_editor_label := true:
	set(value):
		show_editor_label = value
		_sync_editor_label()


func get_blocked_cell() -> Vector2i:
	return grid_cell


func _ready_marker() -> void:
	_sync_editor_label()


func _sync_editor_label() -> void:
	var label := get_node_or_null("EditorLabel") as CanvasItem
	if label != null:
		label.visible = Engine.is_editor_hint() and show_editor_label


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_rect(Rect2(Vector2(-14, -14), Vector2(28, 28)), Color("#fff4d6", 0.55), false, 1.0)
