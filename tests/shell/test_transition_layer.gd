extends UnboundTest

## The persistent fade (shell/transition_layer.gd, docs/game-base-plan.md 9.1): it goes to black and back in the
## time it is given, swallows the mouse while it is visible, keeps running when the tree is paused, and a fade that
## is replaced by a newer one releases whoever awaited it, so a screen change can never wait on a fade nobody
## finishes. Built from the layer's script and a plain ColorRect, the way app_root.tscn wires it.

var layer: TransitionLayer
var cover: ColorRect


func _init() -> void:
	suite_title = "TRANSITION LAYER TEST"
	call_deferred("_run")


func _run() -> void:
	cover = ColorRect.new()
	cover.color = Color.BLACK
	layer = TransitionLayer.new()
	layer.cover_rect = cover
	layer.add_child(cover)
	root.add_child(layer)
	await process_frame

	# --- cover() is instant ---
	layer.cover()
	_expect(layer.is_black() and not layer.is_clear(), "cover() goes to black at once")
	_expect(cover.mouse_filter == Control.MOUSE_FILTER_STOP, "and the cover swallows the mouse")
	_expect(layer.process_mode == Node.PROCESS_MODE_ALWAYS, "the layer runs while the tree is paused")

	# --- A fade takes about the time it is given ---
	var started := Time.get_ticks_msec()
	await layer.fade_in(0.3)
	var elapsed_seconds := (Time.get_ticks_msec() - started) / 1000.0
	_expect(layer.is_clear() and cover.mouse_filter == Control.MOUSE_FILTER_IGNORE, "fade_in() returns when the screen is clear, and the mouse passes through again")
	# The tween's first step carries the frame time that passed before it was made, so the bound below is loose.
	_expect(elapsed_seconds >= 0.1 and elapsed_seconds < 1.0, "in the time it was given, not at once and not forever (%.2f s for 0.3 s)" % elapsed_seconds)
	started = Time.get_ticks_msec()
	await layer.fade_out(0.2)
	_expect(layer.is_black() and (Time.get_ticks_msec() - started) / 1000.0 < 1.0, "fade_out() returns when the screen is black")

	# --- The default time, and zero ---
	layer.default_fade_seconds = 0.1
	started = Time.get_ticks_msec()
	await layer.fade_in()
	_expect(layer.is_clear() and (Time.get_ticks_msec() - started) / 1000.0 < 0.6, "a fade with no time given uses the layer's own (0.1 s)")
	started = Time.get_ticks_msec()
	await layer.fade_out(0.0)
	_expect(layer.is_black() and Time.get_ticks_msec() - started < 100, "a fade of zero seconds is instant")
	await layer.fade_out(0.5)
	_expect(layer.is_black(), "fading to where it already is returns at once")

	# --- A newer fade replaces a running one and releases its waiter ---
	var released := [false]
	var older_fade := func() -> void:
		await layer.fade_in(3.0)
		released[0] = true
	older_fade.call()
	await create_timer(0.1).timeout
	_expect(not released[0] and not layer.is_black() and not layer.is_clear(), "setup: a three second fade is running and has not been released")
	var halfway_alpha := cover.modulate.a
	await layer.fade_out(0.1)
	_expect(released[0], "the fade it replaced was released at once, not left waiting for three seconds")
	_expect(layer.is_black() and cover.modulate.a > halfway_alpha, "and the new fade took over from where the old one had got to")

	# --- It runs while the tree is paused ---
	paused = true
	await layer.fade_in(0.1)
	paused = false
	_expect(layer.is_clear(), "a fade finishes while the tree is paused")

	layer.queue_free()
	finish()
