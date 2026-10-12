@tool
class_name PlayerUnlockMarker
extends GridMarker

## Editor-placed player progression pickup. The runtime bakes its grid cell,
## and MovementSystem emits player_unlock when the hero steps onto it.

@export var unlock_id: StringName = &"wooden_sword"
@export_multiline var message := "The pawn grips the sword. The rules crack."


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_rect(Rect2(Vector2(-10, -10), Vector2(20, 20)), Color("#8fc8e8", 0.22))
	draw_rect(Rect2(Vector2(-10, -10), Vector2(20, 20)), Color("#fff4d6", 0.8), false, 1.5)
	draw_line(Vector2(-7, 7), Vector2(7, -7), Color("#8fc8e8", 0.95), 2.5)
