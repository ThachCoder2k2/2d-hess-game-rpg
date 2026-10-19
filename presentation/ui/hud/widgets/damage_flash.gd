class_name DamageFlash
extends ColorRect

## The red flash over the whole picture when the pawn is hit: one flash that fades out on its own (docs/game-base-plan.md 10:
## Player damage). Callers fire and forget; this node owns the whole lifecycle, so nothing drives it frame by frame. It is
## an effect, not a widget of a strip: it covers the screen for a fifth of a second and takes no mouse. With Reduce
## flashing (9.2) it does not appear at all: the Courage pips still change, so the hit is shown, and the flash is the part
## that can hurt.

## How long the flash takes to fade, in seconds.
const FADE_SECONDS := 0.22
## How opaque the red is at the moment of the hit.
const PEAK_ALPHA := 0.20

## The setting: when true, flash() does nothing and a flash in progress is cut short.
var reduce_flash := false:
	set(value):
		reduce_flash = value
		if value:
			_stop()

## The running fade; killed and restarted on each hit.
var _fade: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


## One red flash that fades out. Does nothing with Reduce flashing on.
func flash() -> void:
	if reduce_flash:
		return
	_stop()
	visible = true
	color.a = PEAK_ALPHA
	_fade = create_tween()
	_fade.tween_property(self, "color:a", 0.0, FADE_SECONDS)
	_fade.tween_callback(func() -> void: visible = false)


## Ends a flash at once and hides the node.
func _stop() -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()
	visible = false
