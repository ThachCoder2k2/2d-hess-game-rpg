class_name SkillSlot
extends Control

## One skill slot of the HUD: a 24 x 24 frame that fills from the bottom as the skill cools down, and the skill's name
## and state beside it ("THRUST READY", "THRUST 0.5", "FIND SWORD"). It draws what SkillSlots hands it. The key that
## fires the skill is not spelled here: the control prompts of the bottom strip show it, from the InputMap, for the
## hand the player is using (a pad shows the pad's button, not a letter this scene would have hard-coded).

## The frame's inner side in pixels: the fill is as tall as this when the skill is ready.
const FILL_HEIGHT := 22.0
## The frame's inside edge: where the fill starts from the left and the bottom.
const FILL_INSET := 1.0

const LOCKED_FILL := Color("#5d5360", 0.45)
const READY_FILL := Color("#8ec8e8", 0.9)
const COOLING_FILL := Color("#e8b83f", 0.82)

@onready var fill: ColorRect = $Frame/Fill
@onready var name_label: Label = $NameLabel

## Keeps the name in the player's language. Made on first use.
var _live_text: LiveText = null
## The state on screen as (unlocked, tenths of a second left, tenths of a second of a full cooldown), so the slot is
## redrawn only when the picture would change. (false, -1, -1) before the first draw.
var _drawn_state := Vector3i(0, -1, -1)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Shows the skill as locked (`unlocked` false), ready (`time_left` 0) or cooling down for `time_left` more seconds of a
## cooldown that lasts `cooldown_duration`.
func show_state(unlocked: bool, time_left: float, cooldown_duration: float) -> void:
	var state := Vector3i(1 if unlocked else 0, roundi(time_left * 10.0), roundi(cooldown_duration * 10.0))
	if state == _drawn_state or name_label == null:
		return
	_drawn_state = state
	if not unlocked:
		_live().set_text(name_label, "UI_HUD_SKILL_LOCKED")
	elif time_left <= 0.0:
		_live().set_text(name_label, "UI_HUD_SKILL_READY")
	else:
		_live().set_text(name_label, "UI_HUD_SKILL_COOLDOWN", {"seconds": "%.1f" % time_left})
	var ratio := 1.0
	if not unlocked:
		ratio = 0.0
	elif time_left > 0.0:
		ratio = clampf(1.0 - time_left / maxf(cooldown_duration, 0.001), 0.0, 1.0)
	fill.size = Vector2(FILL_HEIGHT, FILL_HEIGHT * ratio)
	fill.position = Vector2(FILL_INSET, FILL_INSET + FILL_HEIGHT * (1.0 - ratio))
	fill.color = LOCKED_FILL if not unlocked else READY_FILL if time_left <= 0.0 else COOLING_FILL


## Forgets what the slot last drew.
func forget_drawn() -> void:
	_drawn_state = Vector3i(0, -1, -1)


func _live() -> LiveText:
	if _live_text == null:
		_live_text = LiveText.new()
		add_child(_live_text)
	return _live_text
