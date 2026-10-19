extends UnboundTest

## Reduce flashing takes the flashes out and leaves the warnings (docs/game-base-plan.md 9.2, 10: "reduce-shake and
## reduce-flash remove effects but never telegraphs"). Three places flash today, and each is driven here on the real
## game scene through the real health system:
##   - the HUD's red screen flash on a hit: it appears with the setting off and does not with it on (the Courage pips
##     still change: the hit is shown);
##   - the hero's own picture: a hit tints it, and while it cannot be hurt it BLINKS about seven times a second; with the
##     setting on it is neither tinted nor blinking but a steady, fainter colour (the world's tuning knob, which the view
##     system reads);
##   - the board: its strike flash and the pulse of a danger mark (the flag the board draws by; a telegraph itself is
##     never removed).
## Turning it off again brings all of them back.

const SettingsSupport := preload("res://tests/settings/settings_support.gd")
const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "setting_reduce_flash"

## The window the blink is watched over, in real seconds, and how often the picture is sampled.
const WATCH_SECONDS := 0.5
const SAMPLE_SECONDS := 0.035


func _init() -> void:
	suite_title = "SETTING REDUCE FLASH TEST"
	watchdog_seconds = 50.0
	call_deferred("_run")


func _run() -> void:
	var booted := await SettingsSupport.boot_game(self, SUITE_NAME)
	var game: GameRoot = booted["game"]
	var app: AppRoot = booted["app"]
	if not _expect(game != null, "setup: the game is up in T4"):
		Support.end_suite(self, booted["save_service"])
		return
	var body := game.player_view.get_node("MotionRoot/SpriteRoot/BodySprite") as Sprite2D
	var hurt_color := game.player_view.hurt_modulate

	# --- Off: the effects are there ---
	_hit_the_hero(game)
	_expect(game.hud.damage_flash.visible, "off: a hit flashes the screen red")
	Support.pump(game, 0.02)
	_expect(body.modulate.r == hurt_color.r and body.modulate.g == hurt_color.g, "off: a hit tints the hero's picture")
	var alphas_off := await _alphas_while_invulnerable(game, body)
	_expect(_has_alpha(alphas_off, 0.35) and _has_alpha(alphas_off, 1.0), "off: the hero blinks while it cannot be hurt (alphas seen: %s)" % [_distinct(alphas_off)])

	# --- On ---
	app.settings.set_value(GameSettings.REDUCE_FLASH, true)
	_expect(game.hud.reduce_flash and game.board.reduce_flash, "the setting reaches the HUD and the board")
	Support.pump(game, 0.05)
	_expect(Support.ecs_of(game).tuning.reduce_flash, "and the world's tuning, once the command lands at the next tick")
	_hit_the_hero(game)
	_expect(not game.hud.damage_flash.visible, "on: a hit does not flash the screen")
	_expect(game.hud.courage_label.text != "" and Support.hud_courage_pips(game) == 2, "but the Courage pips changed: the hit is shown (%d)" % Support.hud_courage_pips(game))
	Support.pump(game, 0.02)
	_expect(body.modulate.r == 1.0 and body.modulate.g == 1.0 and body.modulate.b == 1.0, "on: the hero's picture is not tinted")
	var alphas_on := await _alphas_while_invulnerable(game, body)
	_expect(_distinct(alphas_on).size() == 1 and _has_alpha(alphas_on, 0.6), "on: the hero does not blink, it is a steady, fainter colour (alphas seen: %s)" % [_distinct(alphas_on)])
	game.board.queue_redraw()
	await process_frame
	_expect(game.board.reduce_flash, "on: the board draws without its strike flash and pulse")

	# --- Off again ---
	app.settings.set_value(GameSettings.REDUCE_FLASH, false)
	Support.pump(game, 0.05)
	_expect(not game.hud.reduce_flash and not game.board.reduce_flash and not Support.ecs_of(game).tuning.reduce_flash, "off again: every place is told")
	_hit_the_hero(game)
	_expect(game.hud.damage_flash.visible, "and a hit flashes the screen red again")
	Support.end_suite(self, booted["save_service"])


## A hit on the hero, with its Courage refilled and its last invulnerability run out so the hit lands.
func _hit_the_hero(game: GameRoot) -> void:
	var health := Support.player_health(game)
	health.current = health.max_value
	Support.wait_out_invulnerability(game)
	game.hud.damage_flash.visible = false
	Support.damage_player(game, 1)


## The alpha of the hero's picture sampled every SAMPLE_SECONDS of real time for WATCH_SECONDS while it cannot be hurt.
func _alphas_while_invulnerable(game: GameRoot, body: Sprite2D) -> Array[float]:
	var alphas: Array[float] = []
	var health := Support.player_health(game)
	health.invulnerable_left = 100.0
	for _sample in int(WATCH_SECONDS / SAMPLE_SECONDS):
		await create_timer(SAMPLE_SECONDS).timeout
		Support.pump(game, 0.016)
		alphas.append(snappedf(body.modulate.a, 0.05))
	health.invulnerable_left = 0.0
	return alphas


func _distinct(values: Array[float]) -> Array[float]:
	var distinct: Array[float] = []
	for value in values:
		if value not in distinct:
			distinct.append(value)
	distinct.sort()
	return distinct


func _has_alpha(alphas: Array[float], wanted: float) -> bool:
	for alpha in alphas:
		if is_equal_approx(alpha, wanted):
			return true
	return false
