extends UnboundTest

## HudBridge (presentation/bridges/hud_bridge.gd, M3b step 2; M4 step 4): GameHud kept true to the room. The widgets draw the
## HudSnapshot themselves every frame (Courage, the skill slot, the enemy count, the Rank badge, the cell line); the bridge
## flashes the screen on a hit on the hero and tells the debug readout which enemy holds the attack token. The Courage pips
## need no event any more: the snapshot is rebuilt at the end of the tick that took the Courage, before the events are
## routed, so the frame that routes the hit draws it. Driven through a real router and the real HUD scene, with a snapshot
## and no world behind it.

const HERO := 1
const PAWN := 7
const KNIGHT := 8


func _init() -> void:
	suite_title = "HUD BRIDGE TEST"
	await process_frame
	_check_a_hit_on_the_hero_flashes_and_redraws_courage()
	_check_a_heal_on_the_hero_redraws_courage()
	_check_the_skill_slot_follows_the_cooldown()
	_check_the_skill_slot_follows_the_sword()
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


## The frame a hit lands in: the tick took the Courage and rebuilt the snapshot, then the router routes the event, then the
## bridge refreshes.
func _the_frame_of_a_hit(parts: Array, target: int, remaining: int) -> void:
	var bridge: HudBridge = parts[0]
	var router: EventRouter = parts[2]
	var snapshot: HudSnapshot = parts[3]
	if target == HERO:
		snapshot.player_courage_current = remaining
	router.route([{"type": Events.DAMAGED, "entity": target, "amount": 1, "remaining": remaining, "direction": Vector2i.LEFT, "source": PAWN if target == HERO else HERO, "tags": []}])
	bridge.refresh()


func _check_a_hit_on_the_hero_flashes_and_redraws_courage() -> void:
	var parts := _make_bridge()
	var hud: GameHud = parts[1]
	var bridge: HudBridge = parts[0]
	bridge.show_room()
	hud.damage_flash.visible = false
	_the_frame_of_a_hit(parts, HERO, 1)
	_expect(hud.damage_flash.visible, "a hit on the hero flashes the screen")
	_expect(hud.courage_pips.filled_count() == 1 and hud.courage_pips.empty_count() == 2, "and redraws the Courage pips from what is left")
	hud.damage_flash.visible = false
	_the_frame_of_a_hit(parts, PAWN, 1)
	_expect(not hud.damage_flash.visible and hud.courage_pips.filled_count() == 1, "a hit on an enemy leaves the HUD alone")


func _check_a_heal_on_the_hero_redraws_courage() -> void:
	var parts := _make_bridge()
	var bridge: HudBridge = parts[0]
	var hud: GameHud = parts[1]
	var router: EventRouter = parts[2]
	var snapshot: HudSnapshot = parts[3]
	bridge.show_room()
	_the_frame_of_a_hit(parts, HERO, 1)
	hud.damage_flash.visible = false
	snapshot.player_courage_current = 3
	router.route([{"type": Events.HEALED, "entity": HERO, "amount": 2, "remaining": 3, "source": 0}])
	bridge.refresh()
	_expect(hud.courage_pips.filled_count() == 3 and hud.courage_pips.empty_count() == 0, "a checkpoint refill (a heal on the hero) redraws the Courage pips")
	_expect(not hud.damage_flash.visible, "without the damage flash")
	router.route([{"type": Events.HEALED, "entity": PAWN, "amount": 1, "remaining": 1, "source": 0}])
	bridge.refresh()
	_expect(hud.courage_pips.filled_count() == 3, "a heal on an enemy leaves the HUD alone")


func _check_the_skill_slot_follows_the_cooldown() -> void:
	var parts := _make_bridge()
	var bridge: HudBridge = parts[0]
	var hud: GameHud = parts[1]
	var snapshot: HudSnapshot = parts[3]
	var slot_text := hud.skill_slots.first_slot.name_label
	snapshot.sword_unlocked = false
	bridge.show_room()
	_expect(slot_text.text == "FIND SWORD", "the slot says to find the sword while the snapshot says it is not found")
	snapshot.sword_unlocked = true
	snapshot.skill_cooldown_duration = 2.0
	snapshot.skill_cooldown_left = 0.5
	bridge.refresh()
	_expect(slot_text.text == "THRUST 0.5", "a cooldown in the snapshot redraws the slot with the time left")
	snapshot.skill_cooldown_left = 0.0
	bridge.refresh()
	_expect(slot_text.text == "THRUST READY", "and with the ready line when it is over")
	var fill := hud.skill_slots.first_slot.fill
	snapshot.skill_cooldown_left = 1.0
	bridge.refresh()
	_expect(is_equal_approx(fill.size.y, SkillSlot.FILL_HEIGHT * 0.5), "the slot's frame fills as the cooldown runs: half full at half the time")


## Taking the sword raises no skill_cooldown event, so the slot kept saying "FIND SWORD" until the next room or the first
## swing (found by playing T2 to the sword on foot). The snapshot's flag redraws it, and the slot reads the snapshot every frame.
func _check_the_skill_slot_follows_the_sword() -> void:
	var parts := _make_bridge()
	var bridge: HudBridge = parts[0]
	var hud: GameHud = parts[1]
	var snapshot: HudSnapshot = parts[3]
	var slot_text := hud.skill_slots.first_slot.name_label
	snapshot.sword_unlocked = false
	snapshot.skill_cooldown_duration = 2.0
	bridge.show_room()
	bridge.refresh()
	_expect(slot_text.text == "FIND SWORD", "before the sword the slot says to find it, and a frame that changes nothing keeps it so")
	snapshot.sword_unlocked = true
	bridge.refresh()
	_expect(slot_text.text == "THRUST READY", "the frame the snapshot says the sword is found, the slot reads ready: no cooldown event is needed")
	slot_text.text = "touched"
	bridge.refresh()
	_expect(slot_text.text == "touched", "and it is redrawn only when the flag changes, not every frame")
	snapshot.sword_unlocked = false
	bridge.refresh()
	_expect(slot_text.text == "FIND SWORD", "a hero without the sword (a new room, a standalone scene) puts the line back")
	snapshot.sword_unlocked = true
	snapshot.skill_cooldown_left = 0.5
	bridge.refresh()
	_expect(slot_text.text == "THRUST 0.5", "a sword found in the middle of a cooldown shows the time left")


func _check_show_room_draws_the_room() -> void:
	var parts := _make_bridge()
	var bridge: HudBridge = parts[0]
	var hud: GameHud = parts[1]
	var snapshot: HudSnapshot = parts[3]
	hud.show_result("OLD RESULT", "STILL UP")
	hud.set_status("MSG_NO_WEAPON_YET")
	snapshot.room_enemies_remaining = 3
	snapshot.room_enemies_total = 4
	bridge.show_room()
	_expect(hud.courage_pips.filled_count() == 2, "a room shows the Courage the snapshot says the hero has")
	_expect(hud.enemy_count.count_label.text == "ENEMIES 3/4", "and its enemy count")
	_expect(not hud.result_panel.visible and not hud.result_panel.text_label.is_visible_in_tree(), "and no result panel left over from the last room")
	_expect(hud.objective_line.text_label.text == "", "and an empty status line, for the room's own opening line to fill")
	_expect(hud.skill_slots.first_slot.name_label.text == "FIND SWORD", "and the skill slot at rest")
	_expect(hud.debug_readout.strike_label.text == "ENEMY STRIKE READY", "and the strike line for a room with enemies and a free token")
	snapshot.player_entity = 0
	snapshot.room_enemies_remaining = 0
	snapshot.room_enemies_total = 0
	bridge.show_room()
	_expect(hud.courage_pips.filled_count() == 3, "a room whose snapshot has no hero shows full Courage")
	_expect(hud.debug_readout.strike_label.text == "", "and a room with no enemies shows no strike line")


func _check_the_strike_line_follows_the_token() -> void:
	var parts := _make_bridge()
	var bridge: HudBridge = parts[0]
	var hud: GameHud = parts[1]
	var snapshot: HudSnapshot = parts[3]
	snapshot.room_enemies_remaining = 2
	snapshot.room_enemies_total = 2
	bridge.show_room()
	snapshot.attack_token_owner = PAWN
	bridge.refresh()
	_expect(hud.debug_readout.strike_label.text == "STRIKE: BLACK PAWN", "the strike line names the piece that holds the token")
	snapshot.attack_token_owner = 99
	bridge.refresh()
	_expect(hud.debug_readout.strike_label.text == "STRIKE: ENEMY", "a holder the cast does not know is called Enemy")
	snapshot.attack_token_owner = 0
	bridge.refresh()
	_expect(hud.debug_readout.strike_label.text == "ENEMY STRIKE READY", "and says the strike is ready when the token is free")
	hud.debug_readout.strike_label.text = "touched"
	bridge.refresh()
	_expect(hud.debug_readout.strike_label.text == "touched", "the line is redrawn only when the holder changes")


func _check_the_cell_line_follows_the_hero() -> void:
	var parts := _make_bridge()
	var bridge: HudBridge = parts[0]
	var hud: GameHud = parts[1]
	var snapshot: HudSnapshot = parts[3]
	var cell_text := hud.debug_readout.cell_label
	bridge.refresh()
	_expect(cell_text.text == "CELL 03,07  FACE N", "the cell line shows the hero's cell and compass facing")
	snapshot.player_cell = Vector2i(10, 2)
	snapshot.player_facing = Vector2i.LEFT
	bridge.refresh()
	_expect(cell_text.text == "CELL 10,02  FACE W", "and follows the snapshot each frame")
	_expect(TextService.t(DebugReadout.compass_key(Vector2i.DOWN)) == "S" and TextService.t(DebugReadout.compass_key(Vector2i.RIGHT)) == "E" and TextService.t(DebugReadout.compass_key(Vector2i.ZERO)) == "E", "south and east are the other letters, and anything else reads east")
	snapshot.player_entity = 0
	cell_text.text = "kept"
	bridge.refresh()
	_expect(cell_text.text == "kept", "with no hero the cell line is left alone")


func _check_counts_and_the_result_panel() -> void:
	var parts := _make_bridge()
	var bridge: HudBridge = parts[0]
	var hud: GameHud = parts[1]
	var snapshot: HudSnapshot = parts[3]
	snapshot.room_enemies_remaining = 4
	snapshot.room_enemies_total = 4
	bridge.show_room()
	snapshot.room_enemies_remaining = 1
	bridge.refresh()
	_expect(hud.enemy_count.count_label.text == "ENEMIES 1/4", "the enemy count follows the snapshot each frame (ObjectiveSystem keeps it true)")
	hud.enemy_count.count_label.text = "touched"
	bridge.refresh()
	_expect(hud.enemy_count.count_label.text == "touched", "and is redrawn only when the count changes")
	bridge.show_result(RoomObjective.STOCK_CLEAR_KEY, RoomObjective.STOCK_CLEAR_SUBTITLE_KEY)
	_expect(hud.result_panel.visible and hud.result_panel.text_label.text == "ROOM CLEARED\n" + TextService.t(RoomObjective.STOCK_CLEAR_SUBTITLE_KEY), "and puts the result panel up")


func _check_a_scene_without_a_hud() -> void:
	var bridge := HudBridge.new()
	var router := EventRouter.new()
	bridge.register(router)
	router.route([
		{"type": Events.DAMAGED, "entity": 0, "amount": 1, "remaining": 1, "direction": Vector2i.ZERO, "source": 0, "tags": []},
		{"type": Events.SKILL_COOLDOWN, "entity": 0, "time_left": 0.0},
	])
	bridge.show_room()
	bridge.refresh()
	bridge.show_result("a", "b")
	bridge.set_debug_view(true)
	_expect(true, "a scene with no HUD runs the same events and frames without a word")
