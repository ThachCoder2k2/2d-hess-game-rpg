extends UnboundTest

## A boss falls, a flag is set, a door opens (docs/game-base-plan.md 5.4, 7.3, D-21, M5 step 2), driven through the real scene
## and its bridges on a throwaway save:
##   - the hub's five district doors are SHUT until the boss before each has fallen, and each says why in its own words;
##     the flag opens them (set in the live world here, since the boss fights are below);
##   - a boss that falls in its arena (the Knight Captain's) sets boss.knight_captain in the world, writes it to the run
##     with a boss_defeated autosave, and is remembered (defeated_boss_ids); the arena's way on waits for the clear;
##   - the flag opens the Bookshelf door of the hub, survives the trips between rooms and a relaunch;
##   - a skill lock (needs_rule_step) holds nothing: the Bookshelf door it is named on opens with the flag alone.

const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "boss_flow"

const H1 := &"h1_chess_rug_hub"
const TB3 := &"tb3_toy_track_ambush"
const TBB := &"tbb_knight_captain"
const TB4 := &"tb4_lid_path"
const BS1 := &"bs1_book_spine_steps"

## The hub's district doors: the room each leads to, the entry of the hub beside it, the flag it waits for.
const DISTRICT_DOORS := [
	{"zone": &"tb1_toybox_gate", "entry": &"from_toybox", "flag": &"boss.black_pawn_captain", "boss": "black_pawn_captain"},
	{"zone": &"bs1_book_spine_steps", "entry": &"from_bookshelf", "flag": &"boss.knight_captain", "boss": "knight_captain"},
	{"zone": &"bt1_block_yard", "entry": &"from_block_tower", "flag": &"boss.bishop_oracle", "boss": "bishop_oracle"},
	{"zone": &"dh1_foyer", "entry": &"from_dollhouse", "flag": &"boss.rook_warden", "boss": "rook_warden"},
	{"zone": &"ub1_castle_gate", "entry": &"from_under_bed", "flag": &"boss.queen_of_tricks", "boss": "queen_of_tricks"},
]

var save_service: Node
var autosave_reasons: Array[StringName] = []


func _init() -> void:
	suite_title = "BOSS FLOW TEST"
	watchdog_seconds = 55.0
	call_deferred("_run")


func _run() -> void:
	save_service = Support.install_isolated_save_service(self, SUITE_NAME)
	save_service.connect("autosaved", func(_slot: int, reason: StringName) -> void: autosave_reasons.append(reason))
	var main := await Support.boot_main(self)
	await Support.travel_to(main, H1, &"from_boss")
	_expect(main.get("current_zone_id") == H1 and not Support.ecs_of(main).flags.has_flag(&"boss.black_pawn_captain"), "setup: the hero stands in the hub and no boss has fallen")

	await _check_the_district_doors_wait_for_their_bosses(main)
	await _check_a_boss_falls_in_its_arena(main)
	await _check_the_flag_opens_the_bookshelf_and_survives(main)
	Support.end_suite(self, save_service)


## Steps from the hub entry beside the door onto the door cell. True when a trip began.
func _step_onto_the_door(main: Node, entry_id: StringName, zone_id: StringName) -> bool:
	var room: Node = main.get("current_room")
	var entry_cell := Support.entry_cell(main, room, entry_id)
	var door_cell := Support.exit_cell(main, room, zone_id)
	Support.teleport_player(main, entry_cell)
	Support.step_player(main, door_cell - entry_cell)
	return Support.travel_in_progress(main)


func _check_the_district_doors_wait_for_their_bosses(main: Node) -> void:
	var every_door_stays_shut := true
	var every_door_says_why := true
	for door: Dictionary in DISTRICT_DOORS:
		var line_key := Support.exit_locked_message(main.get("current_room"), door["zone"])
		var travelled := _step_onto_the_door(main, door["entry"], door["zone"])
		every_door_stays_shut = every_door_stays_shut and not travelled and main.get("current_zone_id") == H1
		var shown := String((main.get("hud") as GameHud).objective_line.text_label.text)
		every_door_says_why = every_door_says_why and not line_key.is_empty() and shown == TextService.t(line_key)
	_expect(every_door_stays_shut, "with no boss fallen, none of the hub's five district doors takes the hero anywhere")
	_expect(every_door_says_why, "...and each says its own line (the boss it waits for is named in it)")

	# The flag, set in the live world, opens the Toybox door: the lock is the flag and nothing else.
	var ecs := Support.ecs_of(main)
	ecs.flags.set_flag(&"boss.black_pawn_captain", true)
	var travelled := _step_onto_the_door(main, &"from_toybox", &"tb1_toybox_gate")
	_expect(travelled and await Support.wait_for_travel(self, main) and main.get("current_zone_id") == &"tb1_toybox_gate", "once boss.black_pawn_captain is set the Toybox door opens and the hero arrives in tb1")
	_expect(Support.ecs_of(main).flags.get_flag(&"boss.black_pawn_captain", false) == true, "...and the flag came with the hero into the next room's world")


func _check_a_boss_falls_in_its_arena(main: Node) -> void:
	await Support.travel_to(main, TBB, &"from_tb3")
	var room: Node = main.get("current_room")
	var ecs := Support.ecs_of(main)
	_expect(room.get("zone_id") == TBB and room.get("checkpoint_on_entry") == true, "setup: the hero stands in the Knight Captain's arena, a checkpoint room")
	var captain := _enemy_with_id(ecs, &"knight_captain")
	var guard := _enemy_with_id(ecs, &"pawn_recruit")
	_expect(captain != 0 and guard != 0 and (main.get("cast")["enemies"] as Array).size() == 2, "the arena holds the Knight Captain and one Recruit")
	var way_on := Support.exit_cell(main, room, TB4)
	var way_on_entry := Support.entry_cell(main, room, &"from_tb4")
	Support.teleport_player(main, way_on_entry)
	Support.step_player(main, way_on - way_on_entry)
	_expect(not Support.travel_in_progress(main) and main.get("current_zone_id") == TBB, "the arena's way on waits for the clear while the boss stands")

	autosave_reasons.clear()
	Support.remove_enemy_ai(main)
	Events.emit_damage(ecs, captain, 99, Vector2i.ZERO, Support.player_id_of(main))
	Support.pump(main, 0.1)
	_expect(ecs.flags.get_flag(&"boss.knight_captain", false) == true, "the Knight Captain's fall sets boss.knight_captain in the live world")
	_expect(Support.run_of(save_service).defeated_boss_ids.has("knight_captain"), "the run remembers the boss for good (defeated_boss_ids)")
	_expect(&"boss_defeated" in autosave_reasons, "the fall is a success event: the run autosaved with the reason boss_defeated (%s)" % [autosave_reasons])
	_expect(Support.read_save_file(save_service).get_value("flags", "boss.knight_captain", false) == true, "...and the file written holds the flag under [flags]")
	_expect(not Support.run_of(save_service).cleared_room_ids.has(String(TBB)), "the room is not cleared yet: the Recruit still stands")

	Events.emit_damage(ecs, guard, 99, Vector2i.ZERO, Support.player_id_of(main))
	Support.pump(main, 0.1)
	_expect(Support.run_of(save_service).cleared_room_ids.has(String(TBB)), "when the Recruit falls too the room is cleared")
	Support.teleport_player(main, way_on_entry)
	Support.step_player(main, way_on - way_on_entry)
	_expect(Support.travel_in_progress(main) and await Support.wait_for_travel(self, main) and main.get("current_zone_id") == TB4, "...and the way on opens: the hero reaches the shortcut room tb4")
	var home := Support.exit_cell(main, main.get("current_room"), H1)
	var home_entry := Support.entry_cell(main, main.get("current_room"), &"from_tbb")
	_expect(home != Vector2i(-999, -999) and home_entry != Vector2i(-999, -999), "setup: tb4 has its door home")


func _check_the_flag_opens_the_bookshelf_and_survives(main: Node) -> void:
	_expect(Support.ecs_of(main).flags.get_flag(&"boss.knight_captain", false) == true, "the flag is still set in tb4's world: it was carried through the trip")
	await Support.travel_to(main, H1, &"from_toybox")
	var travelled := _step_onto_the_door(main, &"from_bookshelf", BS1)
	_expect(travelled and await Support.wait_for_travel(self, main) and main.get("current_zone_id") == BS1, "back in the hub, the Bookshelf door is open: the boss that fell opened it, and its skill lock (Rule Step) held nothing, because that lock is data until M7c and a route never dead-ends on a skill that is not built")

	# A relaunch continues the run and its flags.
	var flags_before := Support.ecs_of(main).flags.to_dictionary()
	Support.write_the_run(save_service)
	main.free()
	Support.forget_the_run(save_service)
	var relaunched := await Support.boot_main(self)
	_expect(Support.ecs_of(relaunched).flags.get_flag(&"boss.knight_captain", false) == true and Support.ecs_of(relaunched).flags.to_dictionary() == flags_before, "after a relaunch the world still has boss.knight_captain")
	_expect(Support.run_of(save_service).defeated_boss_ids.has("knight_captain"), "and the run still remembers the boss")


func _enemy_with_id(ecs: EcsWorld, enemy_id: StringName) -> int:
	for entity in ecs.query([EcsComponents.ENEMY_AI]):
		var ai: EcsComponents.EnemyAI = ecs.get_component(entity, EcsComponents.ENEMY_AI)
		if ai.definition != null and ai.definition.id == enemy_id:
			return entity
	return 0
