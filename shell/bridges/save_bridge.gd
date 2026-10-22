class_name SaveBridge
extends ShellBridge

## The save's responsibility: what happens between the room and the run (SaveService.state), in both
## directions, and the ONLY place that asks for a save (R17, docs/game-base-plan.md 3.5, 5.2).
##
##   room -> run   A success event happened, so the fact is written into the run and a save is
##                 requested for it: a room cleared (room_cleared, D-17), a checkpoint reached
##                 (checkpoint_reached, D-16), a boss fallen (boss_defeated), a persistent pickup taken (pickup_taken), a gate unbarred
##                 (shortcut_opened), a verb unlocked (unlock_gained), a Book page written
##                 (rule_page_unlocked). A death, a hit, a plain trip between rooms, a floor weapon taken
##                 by an enemy or a quit is not one.
##   run -> room   Every room boot starts from the run: a cleared room's enemies stay gone, a persistent
##                 pickup that is taken stays gone, what is opened stays open, the sword stays in the
##                 hero's hand, the world's flags are the saved ones. The run is also asked, just before
##                 a save is written and when the hero falls, for the facts only the live world knows (its
##                 flags): a death keeps them, the file only learns them at the next success event.
##
## Two places in the run, kept apart on purpose (docs/game-base-plan.md 5.2): the ROOM the pawn is in and the
## entry it came by (`room_zone_id`, `room_entry_id`: moved at every room boot, in memory; a death and a
## Continue return to it), and the latest CHECKPOINT (a hub or a boss room the pawn came into through a
## door: only CheckpointSystem's event moves it).
##
## The nodes hold none of it. The run lives in the SaveService autoload; this bridge reads and writes
## it and shows the result on the markers of the room (a taken unlock, an opened gate).
## tests/save/test_request_save_callers.gd lists the files that call request_save().

## The SaveService autoload has no class_name (an autoload's name is a global), so its script is the type.
const SaveServiceScript := preload("res://shell/save/save_service.gd")


func register(router: EventRouter) -> void:
	router.on(Events.PICKUP_TAKEN, _on_pickup_taken)
	router.on(Events.PLAYER_UNLOCK, _on_player_unlock)
	router.on(Events.GATE_OPENED, _on_gate_opened)
	router.on(Events.ROOM_CLEARED, _on_room_cleared)
	router.on(Events.CHECKPOINT_SET, _on_checkpoint_set)
	router.on(Events.BOSS_DEFEATED, _on_boss_defeated)
	router.on(Events.RESPAWN_REQUESTED, _on_respawn_requested)


## Starts the run's session when the scene starts: a game that has just launched has no run yet, so the
## saved one is continued (GameFlow does this on Continue in M4). Also listens for the moment a save is
## about to be written, to hand the run the live world's flags first. Null-safe: a headless test without
## the autoload runs with no run at all.
func begin() -> void:
	var save := root.save_service()
	if save == null:
		return
	save.ensure_session()
	save.saving.connect(_on_save_service_saving)


## The zone the run says the pawn is in ("" = the scene's authored zone), and the entry it came in by.
func room_zone_id() -> StringName:
	var save := root.save_service()
	return save.state.room_id if save != null else &""


func room_entry_id() -> StringName:
	var save := root.save_service()
	return save.state.room_entry_id if save != null else &"start"


## The pawn is going to (or booting on) this room and entry: the run names them from now on. In memory
## only. A room outside the world graph (no zone id) is not remembered.
func record_room(zone_id: StringName, entry_id: StringName) -> void:
	var save := root.save_service()
	if save != null and zone_id != &"":
		save.note_room(zone_id, entry_id)


## Copies the facts only the live world knows into the run (its flags), so that a death, which rebuilds the
## world from the run, loses none of them. In memory only: the file learns them at the next success event.
func remember_world() -> void:
	var save := root.save_service()
	if save != null and root.ecs != null:
		save.state.player.flags = root.ecs.flags.to_dictionary()


## Pages of the Book written for these pieces (the first meeting with each). True, and a save, when any
## was new; the pieces already known change nothing.
func record_rule_pages(piece_ids: Array[String]) -> bool:
	var save := root.save_service()
	if save == null:
		return false
	var any_new := false
	for piece_id in piece_ids:
		if not save.state.unlocked_rule_ids.has(piece_id):
			save.state.unlocked_rule_ids[piece_id] = true
			any_new = true
	if any_new:
		save.request_save(&"rule_page_unlocked")
	return any_new


## The piece ids whose pages the run has written, for the Book to show.
func rule_page_ids() -> Array:
	var save := root.save_service()
	var ids: Array = []
	if save == null:
		return ids
	for key in save.state.unlocked_rule_ids:
		ids.append(StringName(key))
	return ids


## Before the room boots: what the run already knows that EcsBoot must not spawn again. A cleared room's
## enemies stay gone (D-17), persistent pickups that were taken never respawn, opened gates boot as floor.
func fill_boot_options(options: EcsBootOptions, zone_root: Node) -> void:
	var zone_id := ZoneStage.zone_id_of(zone_root)
	options.skipped_pickup_names = _taken_pickup_names(zone_id, zone_root)
	options.opened_gate_ids = _opened_gate_ids()
	options.room_already_cleared = is_room_cleared(zone_id)


## Whether the run recorded the zone as cleared (D-17). A room outside the world graph (no zone id) never is.
func is_room_cleared(zone_id: StringName) -> bool:
	var save := root.save_service()
	return save != null and zone_id != &"" and save.state.cleared_room_ids.has(String(zone_id))


## After the room booted: the run's facts enter the new world before anything can ask for a save. The
## world's flags are the run's, the run knows which room and entry this is, and the gates the run opened
## stop showing as closed.
func restore_run(zone_id: StringName, entry_id: StringName) -> void:
	var save := root.save_service()
	if save != null:
		root.ecs.flags.load_dictionary(save.state.player.flags)
	record_room(zone_id, entry_id)
	hide_opened_gate_visuals()


## The hero holds what the run says it unlocked, and the unlock markers already taken stay hidden. The
## sword is only the run's to give in world mode (a standalone room keeps what its scene says).
func apply_unlocks() -> void:
	var combat: EcsComponents.PlayerCombat = root.ecs.get_component(root.player_id, EcsComponents.PLAYER_COMBAT)
	if combat == null:
		return
	var save := root.save_service()
	if root.world_graph != null and save != null:
		combat.sword_unlocked = save.state.has_unlock(PlayerSnapshot.SWORD_UNLOCK_ID)
		# The shell just wrote a component the snapshot copies; publish it now rather than a tick late.
		HudSnapshotSystem.build(root.ecs)
	_hide_taken_unlock_markers()


## Closed-gate pictures show only for the gates the run has not opened.
func hide_opened_gate_visuals() -> void:
	if root.current_room == null:
		return
	var opened := _opened_gate_ids()
	for child in root.current_room.get_children():
		var gate_marker := child as GateMarker
		if gate_marker != null:
			gate_marker.visible = gate_marker.gate_id not in opened


## A floor weapon is room-local (D-16): the room puts it back on the floor every time it starts, so
## taking it is no fact for the run and no success event. Only a persistent pickup is remembered and saved.
func _on_pickup_taken(event: Dictionary) -> void:
	var save := root.save_service()
	if save == null or root.current_zone_id == &"":
		return
	var item_id := int(event.get("item", 0))
	if not cast.get("persistent_pickup_by_entity", {}).has(item_id):
		return
	var marker_name := String(cast.get("pickup_name_by_entity", {}).get(item_id, ""))
	if not marker_name.is_empty():
		save.state.taken_pickup_ids[SaveData.pickup_id(root.current_zone_id, marker_name)] = true
		save.request_save(&"pickup_taken")


## The room's objective was met: the room stays cleared for the rest of the run (D-17), and it is a
## success event, so the run is saved. A room outside the world graph has no zone id and is not remembered.
func _on_room_cleared(event: Dictionary) -> void:
	var save := root.save_service()
	var zone_id := StringName(event.get("zone", &""))
	if save == null or zone_id == &"":
		return
	save.state.cleared_room_ids[String(zone_id)] = true
	save.request_save(&"room_cleared")


## A verb unlocked: permanent from this moment, and the live hero has it at once. Only a NEW unlock is a
## success event: the cell stays a trigger after it was taken (its marker is hidden, not removed), so stepping
## onto it again raises the event again, and that must change nothing and save nothing.
func _on_player_unlock(event: Dictionary) -> void:
	var unlock_id := StringName(event.get("id", &""))
	if unlock_id == &"":
		return
	var save := root.save_service()
	if save != null and save.state.add_unlock(unlock_id):
		save.request_save(&"unlock_gained")
	apply_unlocks()


## A shortcut gate unbarred: permanent from this moment, across deaths and launches. The marker's
## closed-gate picture disappears.
func _on_gate_opened(event: Dictionary) -> void:
	var gate_id := StringName(event.get("gate", &""))
	var save := root.save_service()
	if save != null and gate_id != &"":
		save.state.opened_gate_ids[String(gate_id)] = true
		save.request_save(&"shortcut_opened")
	hide_opened_gate_visuals()


## The pawn came into a hub or a boss room through a door: that is the checkpoint now, and it is a success
## event, so the run is saved. (CheckpointSystem already refilled the Courage.)
func _on_checkpoint_set(event: Dictionary) -> void:
	var save := root.save_service()
	var zone_id := StringName(event.get("zone", &""))
	if save == null or zone_id == &"":
		return
	save.state.checkpoint_zone_id = zone_id
	save.state.checkpoint_entry_id = StringName(event.get("entry", &"start"))
	save.request_save(&"checkpoint_reached")


## A boss fell: the run remembers it for good (a boss never comes back, D-17) and it is a success event, so the run
## is saved. The flag the doors wait for (`boss.<id>`) is in the world's flags already; the save learns the flags
## in the moment it is written (`_on_save_service_saving`).
func _on_boss_defeated(event: Dictionary) -> void:
	var save := root.save_service()
	var boss_id := StringName(event.get("boss", &""))
	if save == null or boss_id == &"":
		return
	save.state.defeated_boss_ids[String(boss_id)] = true
	save.request_save(&"boss_defeated")


## The hero fell: the room is about to start again from the run, so the run takes the world's flags first.
## No save: a death is not a success event (R17).
func _on_respawn_requested(_event: Dictionary) -> void:
	remember_world()


## The save is about to be written: it learns the flags of the world that is running now, because the
## world is where they change (the run only holds them between rooms).
func _on_save_service_saving(_reason: StringName) -> void:
	remember_world()


func _opened_gate_ids() -> Array:
	var save := root.save_service()
	var ids: Array = []
	if save == null:
		return ids
	for key in save.state.opened_gate_ids:
		ids.append(StringName(key))
	return ids


## Pickup marker names already taken in this zone: EcsBoot skips them so a taken reward never respawns.
## Only a PERSISTENT marker is honoured: the marker's flag is the truth, so a record the run holds for a
## floor weapon (a save from before D-16 kept every weapon an enemy took) is ignored and the weapon is on
## the floor again like every other room-local weapon.
func _taken_pickup_names(zone_id: StringName, zone_root: Node) -> Array:
	var save := root.save_service()
	var names: Array = []
	if save == null or zone_id == &"" or zone_root == null:
		return names
	var prefix := String(zone_id) + "/"
	for key: String in save.state.taken_pickup_ids:
		if not key.begins_with(prefix):
			continue
		var marker_name := key.substr(prefix.length())
		var marker := zone_root.get_node_or_null(NodePath(marker_name)) as PickupSpawnPoint
		if marker != null and marker.persistent:
			names.append(marker_name)
	return names


func _hide_taken_unlock_markers() -> void:
	var save := root.save_service()
	if save == null or root.current_room == null:
		return
	for child in root.current_room.get_children():
		var marker := child as PlayerUnlockMarker
		if marker != null and save.state.has_unlock(marker.unlock_id):
			marker.visible = false
