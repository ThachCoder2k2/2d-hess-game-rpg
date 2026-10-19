extends UnboundTest

## High-contrast danger changes how the board draws a cell that is about to hurt (docs/game-base-plan.md 9.2, 10: "high-
## contrast danger adds a pattern and a thicker outline"). On the real game scene: the setting reaches the board node;
## with it on the board draws a danger cell (a real telegraph set on it, drawn by the real `_draw`) with the high-contrast
## look and with it off the ordinary one; and the high-contrast look really is thicker and patterned than the ordinary
## outline. What the cell looks like on screen is the owner's to judge; this suite holds that the setting reaches the
## board, that the drawing path runs for both looks without error, and the numbers that make the one bolder than the other.

const SettingsSupport := preload("res://tests/settings/settings_support.gd")
const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "setting_high_contrast_danger"

## The width of the outline of the ordinary danger cell (prototype_board.gd draws it with a literal 2.0).
const ORDINARY_OUTLINE_WIDTH := 2.0


func _init() -> void:
	suite_title = "SETTING HIGH CONTRAST DANGER TEST"
	watchdog_seconds = 40.0
	call_deferred("_run")


func _run() -> void:
	var booted := await SettingsSupport.boot_game(self, SUITE_NAME)
	var game: GameRoot = booted["game"]
	var app: AppRoot = booted["app"]
	if not _expect(game != null, "setup: the game is up in T4"):
		Support.end_suite(self, booted["save_service"])
		return
	var board := game.board
	_expect(not board.high_contrast_danger, "off: the board draws the ordinary danger cell")
	var cells: Array[Vector2i] = [Vector2i(3, 3), Vector2i(4, 3)]
	board.set_telegraph(9001, cells)
	await process_frame
	await process_frame
	_expect(board.telegraphs.has(9001), "setup: a telegraph is on the board and has been drawn")

	app.settings.set_value(GameSettings.HIGH_CONTRAST_DANGER, true)
	_expect(board.high_contrast_danger, "on: the setting reaches the board")
	await process_frame
	await process_frame
	_expect(board.telegraphs.has(9001), "and the danger cell is still there (a warning is never removed), drawn the high-contrast way")
	_expect(PrototypeBoard.HIGH_CONTRAST_OUTLINE_WIDTH > ORDINARY_OUTLINE_WIDTH, "the high-contrast outline is thicker than the ordinary one (%.0f against %.0f px)" % [PrototypeBoard.HIGH_CONTRAST_OUTLINE_WIDTH, ORDINARY_OUTLINE_WIDTH])
	_expect(PrototypeBoard.HIGH_CONTRAST_STRIPE_SPACING > 0.0 and PrototypeBoard.HIGH_CONTRAST_FILL_ALPHA > 0.8, "and it is striped over a near-opaque fill, a pattern and not only a colour")

	app.settings.set_value(GameSettings.HIGH_CONTRAST_DANGER, false)
	_expect(not board.high_contrast_danger, "off again: the board draws the ordinary cell")
	await process_frame
	board.clear_telegraph(9001)
	Support.end_suite(self, booted["save_service"])
