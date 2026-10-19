extends UnboundTest

## The autosave tick (presentation/ui/autosave_indicator, docs/game-base-plan.md 9.2: "a small tick icon shows for
## 1 s after every autosave"): hidden until flash(), on screen for its time, restarted by a second flash instead of
## flickering, and wired by AppRoot to the SaveService's `autosaved` signal. The wiring through a real save is in
## test_app_flow.gd; this suite pins the widget and the default second.


func _init() -> void:
	suite_title = "AUTOSAVE INDICATOR TEST"
	call_deferred("_run")


func _run() -> void:
	var scene := load("res://presentation/ui/autosave_indicator/autosave_indicator.tscn") as PackedScene
	var indicator := scene.instantiate() as AutosaveIndicator
	root.add_child(indicator)
	await process_frame
	_expect(is_equal_approx(indicator.visible_seconds, 1.0), "the tick shows for one second by default (the plan)")
	_expect(not indicator.is_showing() and indicator.mouse_filter == Control.MOUSE_FILTER_IGNORE, "it is hidden until a save, and never takes the mouse")
	_expect(indicator.get_node_or_null("Tick") is Line2D and indicator.get_node_or_null("TickOutline") is Line2D, "the tick is two Line2D nodes of the scene, restyled in the editor")

	indicator.visible_seconds = 0.5
	indicator.fade_seconds = 0.1
	indicator.flash()
	_expect(indicator.is_showing() and is_equal_approx(indicator.modulate.a, 1.0), "flash() shows the tick at full strength")
	await create_timer(0.3).timeout
	_expect(indicator.is_showing(), "it is still there after 0.3 s")
	await create_timer(0.4).timeout
	_expect(not indicator.is_showing(), "and gone after its 0.5 s")

	# A second flash while one shows starts the time over.
	indicator.flash()
	await create_timer(0.35).timeout
	indicator.flash()
	await create_timer(0.35).timeout
	_expect(indicator.is_showing() and is_equal_approx(indicator.modulate.a, 1.0), "a flash during a flash starts the time over: 0.7 s after the first it is still at full strength")
	await create_timer(0.4).timeout
	_expect(not indicator.is_showing(), "and it goes out 0.5 s after the last one")

	# The scene AppRoot owns carries one, anchored in the top right corner.
	var app_scene := load("res://shell/app_root.tscn") as PackedScene
	var app := app_scene.instantiate()
	var in_app := app.get_node_or_null("OverlayLayer/AutosaveIndicator") as AutosaveIndicator
	_expect(in_app != null and is_equal_approx(in_app.anchor_left, 1.0) and is_equal_approx(in_app.anchor_right, 1.0) and in_app.anchor_top == 0.0, "AppRoot's overlay carries the tick, anchored to the top right corner")
	_expect(app.get_node("OverlayLayer").process_mode == Node.PROCESS_MODE_ALWAYS, "in a layer that keeps running while the tree is paused")
	app.free()
	indicator.queue_free()
	finish()
