extends UnboundTest

## The checkpoint and death rules of D-16 (docs/game-base-plan.md 5.2, 9.3), driven through the real scene,
## the real bridges and the real SaveService (a throwaway folder):
##   - a checkpoint is a hub entry or a boss-room entry, and which rooms those are is DATA on the room scene
##     (RoomEncounter.checkpoint_on_entry), never an id in a script;
##   - reaching one refills Courage, records the checkpoint in the run and saves (reason checkpoint_reached);
##     a plain trip between rooms heals nothing, records no checkpoint and saves nothing;
##   - a death resets only the room it happened in: the pawn starts again on the entry it came in by, with full
##     Courage, the room whole (a boss back at full health), and nothing saved; the checkpoint does not move,
##     and everything the run holds (unlocks, flags, cleared rooms, opened gates, rescues, Pages, shards,
##     defeated bosses) is untouched;
##   - a Continue puts the pawn back in the room it was in at the last save.
## The least punishing reading of "return to the latest checkpoint OR reset only the current room" is the second:
## no death takes the pawn farther back than the room it fell in (recorded in docs/game-base-plan.md 5.2).
## Autosave reasons are watched through SaveService.autosaved.

const Support := preload("res://tests/bridge/bridge_support.gd")
const ProjectFiles := preload("res://tests/architecture/project_files.gd")
const SUITE_NAME := "checkpoint_rules"

const T1 := &"t1_white_kings_fall"
const T2 := &"t2_fallen_sword_tile"
const T3 := &"t3_first_pawn_clash"
const T4 := &"t4_broken_rule_yard"
const B1 := &"b1_black_pawn_captain"
const H1 := &"h1_chess_rug_hub"

var saved_reasons: Array[StringName] = []
## Every reason the run was saved for, from the first frame to the last (saved_reasons is cleared stage by stage).
var every_saved_reason: Array[StringName] = []
## Every `respawn_requested` event the scene's router handed out.
var respawn_requests: Array[Dictionary] = []


func _init() -> void:
	suite_title = "CHECKPOINT RULES TEST"
	watchdog_seconds = 50.0
	_check_which_rooms_are_checkpoints_is_data()
	call_deferred("_run")


func _run() -> void:
	var save_service := Support.install_isolated_save_service(self, SUITE_NAME)
	save_service.autosaved.connect(func(_slot: int, reason: StringName) -> void:
		saved_reasons.append(reason)
		every_saved_reason.append(reason))
	var main := await Support.boot_main(self)
	(main.get("router") as EventRouter).on(Events.RESPAWN_REQUESTED, func(event: Dictionary) -> void: respawn_requests.append(event))
	var max_courage := Support.player_health(main).max_value
	var run := Support.run_of(save_service)

	# --- A plain trip between rooms is no checkpoint: nothing heals, nothing is recorded, nothing is saved ---
	Support.damage_player(main, 1)
	Support.wait_out_invulnerability(main)
	_expect(Support.player_health(main).current == max_courage - 1 and not run.has_checkpoint(), "setup: a wounded hero in T1 and no checkpoint yet")
	saved_reasons.clear()
	await Support.travel_to(main, T2, &"west_entry")
	await Support.travel_to(main, T3, &"west_entry")
	Support.pump(main, 0.3)
	_expect(Support.player_health(main).current == max_courage - 1, "two plain trips later the hero is still wounded: travel never heals")
	_expect(not run.has_checkpoint(), "and the run has no checkpoint: T2 and T3 are not hubs or boss rooms")
	_expect(not saved_reasons.has(&"checkpoint_reached"), "and no checkpoint was saved")

	# --- The boss room's door is a checkpoint ---
	await Support.travel_to(main, B1, &"west_entry")
	Support.remove_enemy_ai(main)
	saved_reasons.clear()
	Support.pump(main, 0.3)
	_expect(run.checkpoint_zone_id == B1 and run.checkpoint_entry_id == &"west_entry", "coming into the boss room is a checkpoint: the run names the room and the entry the pawn came by")
	_expect(Support.player_health(main).current == max_courage, "the pawn's Courage is full again")
	_expect(Support.hud_courage_pips(main) == max_courage, "and the HUD shows it")
	_expect(saved_reasons == [&"checkpoint_reached"], "the checkpoint is a success event: the run was saved for it, and for nothing else (%s)" % [saved_reasons])
	var saved_file := Support.read_save_file(save_service)
	_expect(String(saved_file.get_value("checkpoint", "zone_id", "")) == String(B1) and String(saved_file.get_value("checkpoint", "entry_id", "")) == "west_entry", "the file names the checkpoint")
	_expect(String(saved_file.get_value("meta", "room", "")) == String(B1) and String(saved_file.get_value("meta", "room_entry", "")) == "west_entry", "and the room and entry the pawn stands on")

	# --- A death resets only this room: back on its entry, full Courage, the boss whole, nothing saved ---
	var captain_id: int = main.get("cast")["enemies"][0]
	# One point of damage on the boss as a stand-in for "the hero wounded it": the setup needs a boss that is not at
	# full health when the hero falls, and nothing else (the subject is what a death resets).
	Events.emit_damage(Support.ecs_of(main), captain_id, 1, Vector2i.ZERO, Support.player_id_of(main))
	Support.pump(main, Support.SIM_STEP_SECONDS)
	var captain_health: EcsComponents.Health = Support.ecs_of(main).get_component(captain_id, EcsComponents.HEALTH)
	_expect(captain_health.current == captain_health.max_value - 1, "setup: the hero wounded the boss")
	_put_a_run_worth_keeping(run)
	var world_flags_command := Commands.set_flag(&"beat.after_checkpoint", true)
	Support.ecs_of(main).push_command(world_flags_command)
	Support.pump(main, Support.SIM_STEP_SECONDS)
	var run_before_death := _what_the_run_holds(run)
	saved_reasons.clear()
	Support.damage_player(main, 99)
	_expect(Support.room_ending(main), "the fall ends the room")
	_expect(await Support.wait_for_respawn(self, main), "after the defeat beat the room starts again")
	Support.remove_enemy_ai(main)
	_expect(main.get("current_zone_id") == B1 and Support.player_cell(main) == Support.entry_cell(main, main.get("current_room"), &"west_entry"), "in the same room, on the entry the pawn came in by")
	_expect(Support.player_health(main).current == max_courage and Support.player_tag(main).control_enabled, "with full Courage and the hero in control")
	_expect(respawn_requests.size() == 1 and respawn_requests[0]["zone"] == B1 and respawn_requests[0]["entry"] == &"west_entry" and respawn_requests[0]["entity"] == Support.player_id_of(main), "the simulation asked once, naming the boss room, the entry the pawn came by and the hero")
	_expect(respawn_requests[0]["zone"] == run.room_id and respawn_requests[0]["entry"] == run.room_entry_id, "which is what the run names, and what the rebuild used")
	var reborn_captain: int = main.get("cast")["enemies"][0]
	var reborn_health: EcsComponents.Health = Support.ecs_of(main).get_component(reborn_captain, EcsComponents.HEALTH)
	_expect(reborn_health.current == reborn_health.max_value and Support.total_enemies(main) == 3, "the boss is back at full health and its guards with it: a boss room starts over from the first phase (phases themselves arrive with M8b)")
	Support.pump(main, 0.3)
	_expect(saved_reasons.is_empty(), "the death saved nothing, and neither did the room starting again: it is not a new checkpoint (%s)" % [saved_reasons])
	_expect(run.checkpoint_zone_id == B1 and run.checkpoint_entry_id == &"west_entry", "the checkpoint is where it was")
	_expect(_what_the_run_holds(run) == run_before_death, "everything the run holds survived the death: unlocks, flags, cleared rooms, opened gates, rescues, Pages, shards, defeated bosses")
	_expect(Support.ecs_of(main).flags.get_flag(&"beat.after_checkpoint") == true, "and the flag set in the room that was lost is set in the rebuilt one")
	_expect(Support.player_combat(main).sword_unlocked, "the unlocked sword is in the hero's hand again")

	# --- The hub's door is a checkpoint too, by either entry; the latest one is the checkpoint ---
	Support.damage_player(main, 2)
	Support.wait_out_invulnerability(main)
	saved_reasons.clear()
	await Support.travel_to(main, H1, &"from_boss")
	Support.remove_enemy_ai(main)
	Support.pump(main, 0.3)
	_expect(run.checkpoint_zone_id == H1 and run.checkpoint_entry_id == &"from_boss", "the hub's door from the boss room is a checkpoint, and replaces the boss room's")
	_expect(Support.player_health(main).current == max_courage, "and refills the pawn's Courage")
	_expect(saved_reasons.count(&"checkpoint_reached") == 1, "saved once for it")
	await Support.travel_to(main, T4, &"from_b1")
	await Support.travel_to(main, H1, &"from_toybox")
	Support.pump(main, 0.3)
	_expect(run.checkpoint_zone_id == H1 and run.checkpoint_entry_id == &"from_toybox", "coming back into the hub by its other entry moves the checkpoint to that entry")

	# --- A death in an ordinary room does not send the pawn back to the checkpoint ---
	await Support.travel_to(main, T3, &"from_t4")
	Support.remove_enemy_ai(main)
	saved_reasons.clear()
	Support.damage_player(main, 99)
	_expect(await Support.wait_for_respawn(self, main), "the hero falls in T3, an ordinary room")
	_expect(main.get("current_zone_id") == T3 and Support.player_cell(main) == Support.entry_cell(main, main.get("current_room"), &"from_t4"), "and starts again in T3, on the entry it came by, not at the hub's checkpoint")
	_expect(run.checkpoint_zone_id == H1 and run.checkpoint_entry_id == &"from_toybox", "the checkpoint is still the hub's")
	_expect(Support.total_enemies(main) == 1 and Support.player_health(main).current == max_courage, "T3 is whole again (its pawn alive) and the hero at full Courage")
	_expect(saved_reasons.is_empty(), "no save")
	var restart_world := Support.ecs_of(main)
	Support.restart_room_from_the_menu(main)
	_expect(await Support.wait_for_respawn(self, main) and Support.ecs_of(main) != restart_world and main.get("current_zone_id") == T3, "Restart Room starts the room again the same way")
	_expect(saved_reasons.is_empty() and run.checkpoint_zone_id == H1, "and is no checkpoint and no save either")

	# --- A Continue returns to the room the pawn was in at the last save ---
	await Support.travel_to(main, H1, &"from_boss")
	Support.pump(main, 0.3)
	Support.remove_enemy_ai(main)
	_expect(saved_reasons.has(&"checkpoint_reached"), "setup: the hub was saved on the way in")
	main.free()
	Support.forget_the_run(save_service)
	var relaunched := await Support.boot_main(self)
	run = Support.run_of(save_service)
	_expect(relaunched.get("current_zone_id") == H1 and Support.player_cell(relaunched) == Support.entry_cell(relaunched, relaunched.get("current_room"), &"from_boss"), "after quitting and relaunching the pawn is in the hub, on the entry it came by")
	_expect(run.checkpoint_zone_id == H1 and run.checkpoint_entry_id == &"from_boss", "and the file still names the hub as the checkpoint")
	_expect(Support.player_health(relaunched).current == max_courage, "with full Courage: health never saves")
	_expect(run.player.unlocked_skill_ids.has(&"wooden_sword") and run.cleared_room_ids.has("t1_cleared_for_test"), "and what the run held is still held")

	var allowed_reasons: Array[StringName] = [&"checkpoint_reached", &"rule_page_unlocked"]
	var unexpected_reasons: Array[String] = []
	for reason in every_saved_reason:
		if reason not in allowed_reasons:
			unexpected_reasons.append(String(reason))
	_expect(not every_saved_reason.is_empty() and every_saved_reason.has(&"checkpoint_reached") and unexpected_reasons.is_empty(), "over the whole session the run was saved only for the success events in it (a checkpoint, a Book page): %s" % [every_saved_reason])
	_expect(respawn_requests.size() == 2, "and the simulation asked for a room to start again exactly twice, once per fall (the boss room, T3); Restart Room is the player's own request and not one of them (%d)" % respawn_requests.size())

	Support.end_suite(self, save_service)


## Which rooms are checkpoints is data on the room scene, and no script names a room.
func _check_which_rooms_are_checkpoints_is_data() -> void:
	var checkpoint_flag_by_room := {H1: true, B1: true, T1: false, T2: false, T3: false, T4: false}
	for room_id: StringName in checkpoint_flag_by_room:
		var room_scene := ContentDb.fetch(&"rooms", room_id) as PackedScene
		var room := room_scene.instantiate()
		_expect(room.get("checkpoint_on_entry") == checkpoint_flag_by_room[room_id], "%s: checkpoint_on_entry is %s on the room's scene" % [room_id, checkpoint_flag_by_room[room_id]])
		room.free()
	var literal_regex := RegEx.create_from_string("[\"'&]+(?:h1|b1|t[1-4])_[a-z_]+")
	var offenders: Array[String] = []
	var scanned := 0
	for directory in ["res://ecs", "res://shell", "res://authoring", "res://presentation"]:
		for script_path in ProjectFiles.collect_files(["gd"], directory):
			scanned += 1
			var code := RegEx.create_from_string("#[^\\n]*").sub(ProjectFiles.read_text(script_path), "", true)
			if literal_regex.search(code) != null:
				offenders.append(script_path)
	_expect(scanned >= 50, "the scan read %d scripts of the game's layers (at least 50)" % scanned)
	_expect(offenders.is_empty(), "no script of the game names a room by its id: the checkpoints are data (%s)" % ", ".join(PackedStringArray(offenders)))
	_expect(literal_regex.search("var hub := &\"h1_chess_rug_hub\"") != null and literal_regex.search("# &\"h1_chess_rug_hub\"") != null, "the scan can fail: it finds an id written as a StringName literal")


## Puts something in every set the run keeps that a death must not touch.
func _put_a_run_worth_keeping(run: SaveData) -> void:
	run.cleared_room_ids["t1_cleared_for_test"] = true
	run.defeated_boss_ids["a_boss_for_test"] = true
	run.opened_gate_ids["a_gate_for_test"] = true
	run.rescued_piece_ids["a_rescue_for_test"] = true
	run.collected_page_ids["a_page_for_test"] = true
	run.courage_shard_ids["a_shard_for_test"] = true
	run.unlocked_rule_ids["a_rule_for_test"] = true
	run.add_unlock(&"wooden_sword")


## Everything a death must leave alone, as plain data.
func _what_the_run_holds(run: SaveData) -> Dictionary:
	return {
		"cleared": run.cleared_room_ids.duplicate(),
		"bosses": run.defeated_boss_ids.duplicate(),
		"gates": run.opened_gate_ids.duplicate(),
		"rescues": run.rescued_piece_ids.duplicate(),
		"pages": run.collected_page_ids.duplicate(),
		"shards": run.courage_shard_ids.duplicate(),
		"rules": run.unlocked_rule_ids.duplicate(),
		"unlocks": run.player.unlocked_skill_ids.duplicate(),
		"taken": run.taken_pickup_ids.duplicate(),
		"checkpoint": [run.checkpoint_zone_id, run.checkpoint_entry_id],
	}
