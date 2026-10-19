class_name AutosaveIndicator
extends Control

## The small tick that shows for a moment after every autosave (docs/game-base-plan.md 9.2: "a small tick icon
## shows for 1 s after every autosave"). A dumb view: whoever hears the save (AppRoot, from the SaveService's
## `autosaved` signal) calls flash(). The tick is drawn by two Line2D nodes of the scene (a dark outline and an
## ivory stroke), so the owner restyles it in the editor; the colours are a stand-in until the owner's icon
## (docs/assets, `save_icons`) overwrites them.

## How long the tick is on screen in all, fade included.
@export_range(0.2, 5.0, 0.1, "suffix:s") var visible_seconds := 1.0
## How much of that time is the fade out at the end.
@export_range(0.0, 1.0, 0.05, "suffix:s") var fade_seconds := 0.25

var _fade_tween: Tween = null


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Shows the tick now and hides it again after `visible_seconds`. A second flash while one is showing starts the
## time over, so a burst of saves is one long tick and never a flicker.
func flash() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	modulate.a = 1.0
	visible = true
	_fade_tween = create_tween()
	_fade_tween.tween_interval(maxf(visible_seconds - fade_seconds, 0.0))
	_fade_tween.tween_property(self, "modulate:a", 0.0, fade_seconds)
	_fade_tween.tween_callback(hide)


## Whether the tick is on screen.
func is_showing() -> bool:
	return visible
