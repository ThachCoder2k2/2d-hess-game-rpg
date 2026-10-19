class_name TransitionLayer
extends CanvasLayer

## The persistent fade over everything (docs/game-base-plan.md 9.1: "a persistent transition layer"). AppRoot
## owns one; it survives every screen change, so a screen can be freed while the screen is black. A cover
## rectangle (an editor-owned ColorRect) is faded in and out with a Tween; the layer decides nothing.
##
##   await transition.fade_out()     the screen goes to black (returns when it is black)
##   transition.fade_in()            the screen comes back (await it to wait for it)
##
## A fade started while another is running replaces it, from the alpha it had reached, and the one it replaced
## returns at once, so a caller that awaits can never be left waiting on a fade nobody finishes. While the cover is
## visible it swallows the mouse, so a button under a fading screen cannot be pressed. It runs while the tree is
## paused (a pause menu leaves for the title through it).
##
## The zone trip of the game scene has a fade of its own (the scene's FadeLayer, ZoneTravelBridge): a trip
## between two rooms is the game's, a change of screen is the app's.

## Emitted when a fade reached its end, and when a newer fade replaced a running one.
signal fade_ended

## The black rectangle. Its alpha is the fade.
@export var cover_rect: ColorRect
## The seconds a fade takes unless the caller names another.
@export_range(0.0, 2.0, 0.01, "suffix:s") var default_fade_seconds := 0.25

var _latest_fade := 0
var _finished_fade := 0
var _fade_tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_swallow_mouse_while_visible()


## Goes to black at once, with no fade (the app starts behind it).
func cover() -> void:
	_stop_running_fade()
	cover_rect.modulate.a = 1.0
	_swallow_mouse_while_visible()


## Fades to black. Returns when the screen is black (or when a newer fade replaced this one).
func fade_out(seconds := -1.0) -> void:
	await _fade_to(1.0, seconds)


## Fades back to the screen. Returns when it is clear (or when a newer fade replaced this one).
func fade_in(seconds := -1.0) -> void:
	await _fade_to(0.0, seconds)


## True when the cover is fully black.
func is_black() -> bool:
	return is_equal_approx(cover_rect.modulate.a, 1.0)


## True when the cover is fully clear.
func is_clear() -> bool:
	return is_zero_approx(cover_rect.modulate.a)


func _fade_to(target_alpha: float, seconds: float) -> void:
	var duration := default_fade_seconds if seconds < 0.0 else seconds
	_stop_running_fade()
	_latest_fade += 1
	var this_fade := _latest_fade
	if is_equal_approx(cover_rect.modulate.a, target_alpha) or duration <= 0.0:
		cover_rect.modulate.a = target_alpha
		_finished_fade = this_fade
		_swallow_mouse_while_visible()
		fade_ended.emit()
		return
	cover_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade_tween = create_tween()
	_fade_tween.tween_property(cover_rect, "modulate:a", target_alpha, duration)
	_fade_tween.finished.connect(_on_fade_finished.bind(this_fade))
	# Whoever awaited the fade this one replaces is released here, after the new fade is set up: what that
	# caller does next may start a fade of its own, which then replaces this one cleanly.
	fade_ended.emit()
	while _finished_fade < this_fade and _latest_fade == this_fade:
		await fade_ended


func _on_fade_finished(this_fade: int) -> void:
	_finished_fade = maxi(_finished_fade, this_fade)
	_swallow_mouse_while_visible()
	fade_ended.emit()


func _stop_running_fade() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null


func _swallow_mouse_while_visible() -> void:
	cover_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE if is_zero_approx(cover_rect.modulate.a) else Control.MOUSE_FILTER_STOP
