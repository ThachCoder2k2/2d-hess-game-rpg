class_name EnemyCount
extends HudWidget

## How many enemies are left in the room, "ENEMIES 3/4" (docs/game-base-plan.md D-29: the optional count of the
## first-chain HUD). Draws the HudSnapshot's room_enemies_remaining and room_enemies_total, which ObjectiveSystem keeps
## true, and draws again only when the pair changes.

@onready var count_label: Label = $CountLabel

## The (still standing, began with) pair on screen. (-1, -1) before the first draw.
var _drawn_count := Vector2i(-1, -1)
## Keeps the line in the player's language. Made on first use.
var _live_text: LiveText = null


func refresh(snapshot: HudSnapshot) -> void:
	var count := Vector2i(snapshot.room_enemies_remaining, snapshot.room_enemies_total)
	if count_label == null or count == _drawn_count:
		return
	_drawn_count = count
	_live().set_text(count_label, "UI_HUD_ENEMIES", {"remaining": count.x, "total": count.y})


func forget_drawn() -> void:
	_drawn_count = Vector2i(-1, -1)


func _live() -> LiveText:
	if _live_text == null:
		_live_text = LiveText.new()
		add_child(_live_text)
	return _live_text
