extends UnboundTest

## HudBridge (presentation/bridges/hud_bridge.gd, M3b step 2): GameHud kept true to the room. The
## reactions are the ones game_root.gd had before the split: a hit on the hero flashes the screen and
## redraws the Courage pips, the skill slot is redrawn on a cooldown event, and every frame the strike
## line and the cell line follow the HudSnapshot. Driven through a real router and the real HUD scene,
## with a snapshot and no world behind it.

const HERO := 1
const PAWN := 7
const KNIGHT := 8


func _init() -> void:
	suite_title = "HUD BRIDGE TEST"
	await process_frame
	_check_a_hit_on_the_hero_flashes_and_redraws_courage()
	_check_the_skill_slot_follows_the_cooldown_event()
	_check_show_room_draws_the_room()
	_check_the_strike_line_follows_the_token()
	_check_the_cell_line_follows_the_hero()
	_check_counts_and_the_result_panel()
	_check_a_scene_without_a_hud()
	finish()


func _make_bridge() -> Array:
	var paths := TestPaths.new(self)
	var hud := paths.load_scene(paths.hud_scene()).instantiate() as GameHud
	root.add_child(hud)
	var snapshot := HudSnapshot.new()
	snapshot.player_entity = HERO
	snapshot.player_courage_current = 2
	snapshot.player_courage_max = 3
	snapshot.player_cell = Vector2i(3, 7)
	snapshot.player_facing = Vector2i.UP
	var bridge := HudBridge.new()
	bridge.attach(hud)
	bridge.bind_world(snapshot, {"piece_name_by_entity": {PAWN: "Black Pawn", KNIGHT: "Knight"}})
	var router := EventRouter.new()
	bridge.register(router)
	return [bridge, hud, router, snapshot]


func _check_a_hit_on_the_hero_flashes_and_redraws_courage() -> void:
	var parts := _make_bridge()
	var hud: GameHud = parts[1]
	var router: EventRouter = parts[2]
	router.route([{"type": Events.DAMAGED, "entity": HERO, "amount": 1, "remaining": 1, "direction": Vector2i.LEFT, "source": PAWN, "tags": []}])
	_expect(hud.damage_flash.visible, "a hit on the hero flashes the screen")
	_expect(hud.courage_label.text.count("◆") == 1 and hud.courage_label.text.count("◇") == 2, "and redraws the Courage pips from what is left")
	hud.damage_flash.visible = false
	router.route([{"type": Events.DAMAGED, "entity": PAWN, "amount": 1, "remaining": 1, "direction": Vector2i.UP, "source": HERO, "tags": []}])
	_expect(not hud.damage_flash.visible and hud.courage_label.text.count("◆") == 1, "a hit on an enemy leaves the HUD alone")


func _check_the_skill_slot_follows_the_cooldown_event() -> void:
	var parts := _make_bridge()
	var hud: GameHud = parts[1]
	var router: EventRouter = parts[2]
	var snapshot: HudSnapshot = parts[3]
	snapshot.sword_unlocked = false
	router.route([{"type": Events.SKILL_COOLDOWN, "entity": HERO, "time_left": 0.0}])
	_expect(hud.skill_label.text == "FIND SWORD", "the slot says to find the sword while the snapshot says it is not found")
	snapshot.sword_unlocked = true
	snapshot.skill_cooldown_duration = 2.0
	router.route([{"type": Events.SKILL_COOLDOWN, "entity": HERO, "time_left": 0.5}])
	_expect(hud.skill_label.text == "Q THRUST 0.5", "a cooldown event redraws the slot with the time left")
	router.route([{"type": Events.SKILL_COOLDOWN, "entity": HERO, "time_left": 0.0}])
	_expect(hud.skill_label.text == "Q THRUST READY", "and with the ready line when it is over")


func _check_show_room_draws_the_room() -> void:
	var parts := _make_bridge()
	var bridge: HudBridge = parts[0]
	var hud: GameHud = parts[1]
	var snapshot: HudSnapshot = parts[3]
	hud.show_result("OLD RESULT", "STILL UP")
	bridge.show_room(3, 4)
	_expect(hud.courage_label.text.count("◆") == 2, "a room shows the Courage the snapshot says the hero has")
	_expect(hud.encounter_label.text == "ENEMIES 3/4", "and its enemy count")
	_expect(not hud.result_panel.visible and not hud.result_label.visible, "and no result panel left over from the last room")
	_expect(hud.skill_label.text == "FIND SWORD", "and the skill slot at rest")
	_expect(hud.token_label.text == "ENEMY STRIKE READY", "and the strike line for a room with enemies and a free token")
	snapshot.player_entity = 0
	bridge.show_room(0, 0)
	_expect(hud.courage_label.text.count("◆") == 3, "a room whose snapshot has no hero shows full Courage")
	_expect(hud.token_label.text == "", "and a room with no enemies shows no strike line")


func _check_the_strike_line_follows_the_token() -> void:
	var parts := _make_bridge()
	var bridge: HudBridge = parts[0]
	var hud: GameHud = parts[1]
	var snapshot: HudSnapshot = parts[3]
	bridge.show_room(2, 2)
	snapshot.attack_token_owner = PAWN
	bridge.refresh()
	_expect(hud.token_label.text == "STRIKE: BLACK PAWN", "the strike line names the piece that holds the token")
	snapshot.attack_token_owner = 99
	bridge.refresh()
	_expect(hud.token_label.text == "STRIKE: ENEMY", "a holder the cast does not know is called Enemy")
	snapshot.attack_token_owner = 0
	bridge.refresh()
	_expect(hud.token_label.text == "ENEMY STRIKE READY", "and says the strike is ready when the token is free")
	hud.token_label.text = "touched"
	bridge.refresh()
	_expect(hud.token_label.text == "touched", "the line is redrawn only when the holder changes")


func _check_the_cell_line_follows_the_hero() -> void:
	var parts := _make_bridge()
	var bridge: HudBridge = parts[0]
	var hud: GameHud = parts[1]
	var snapshot: HudSnapshot = parts[3]
	bridge.refresh()
	_expect(hud.status_label.text == "CELL 03,07  FACE N", "the cell line shows the hero's cell and compass facing")
	snapshot.player_cell = Vector2i(10, 2)
	snapshot.player_facing = Vector2i.LEFT
	bridge.refresh()
	_expect(hud.status_label.text == "CELL 10,02  FACE W", "and follows the snapshot each frame")
	_expect(HudBridge.facing_name(Vector2i.DOWN) == "S" and HudBridge.facing_name(Vector2i.RIGHT) == "E" and HudBridge.facing_name(Vector2i.ZERO) == "E", "south and east are the other letters, and anything else reads east")
	snapshot.player_entity = 0
	hud.status_label.text = "kept"
	bridge.refresh()
	_expect(hud.status_label.text == "kept", "with no hero the cell line is left alone")


func _check_counts_and_the_result_panel() -> void:
	var parts := _make_bridge()
	var bridge: HudBridge = parts[0]
	var hud: GameHud = parts[1]
	bridge.show_encounter_count(1, 4)
	_expect(hud.encounter_label.text == "ENEMIES 1/4", "the room outcome updates the enemy count through the bridge")
	bridge.show_result("ROOM CLEARED", "PRESS R TO RESET")
	_expect(hud.result_panel.visible and hud.result_label.text == "ROOM CLEARED\nPRESS R TO RESET", "and puts the result panel up")


func _check_a_scene_without_a_hud() -> void:
	var bridge := HudBridge.new()
	var router := EventRouter.new()
	bridge.register(router)
	router.route([
		{"type": Events.DAMAGED, "entity": 0, "amount": 1, "remaining": 1, "direction": Vector2i.ZERO, "source": 0, "tags": []},
		{"type": Events.SKILL_COOLDOWN, "entity": 0, "time_left": 0.0},
	])
	bridge.show_room(1, 1)
	bridge.refresh()
	bridge.show_encounter_count(0, 1)
	bridge.show_result("a", "b")
	_expect(true, "a scene with no HUD runs the same events and frames without a word")
