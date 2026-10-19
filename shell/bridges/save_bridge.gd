class_name SaveBridge
extends ShellBridge

## The save's responsibility: what happens between the room and the run (SaveService.state), in both
## directions, and the ONLY place that asks for a save (R17, docs/game-base-plan.md 3.5, 5.2).
##
##   room -> run   A success event happened, so the fact is written into the run and a save is
##                 requested for it: a floor weapon taken (pickup_taken), a gate unbarred
##                 (shortcut_opened), a verb unlocked (unlock_gained), a Book page written
##                 (rule_page_unlocked), a zone entered (checkpoint_reached; interim until the
##                 checkpoint rules of D-16, step 3). A death, a hit or a quit is not one.
##   run -> room   Every room boot starts from the run: what is taken stays gone, what is opened
##                 stays open, the sword stays in the hero's hand, the world's flags are the saved
##                 ones. The run is also asked, just before a save is written, for the facts only
##                 the live world knows (its flags).
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


## The zone the run says the pawn is in ("" = the scene's authored zone), and where in it.
func checkpoint_zone_id() -> StringName:
	var save := root.save_service()
	return save.state.checkpoint_zone_id if save != null else &""


func checkpoint_entry_id() -> StringName:
	var save := root.save_service()
	return save.state.checkpoint_entry_id if save != null else &"start"


## The zone trip began: the destination is the new checkpoint (interim: every zone entry, not only a hub
## or a boss room) and it is a success event, so the run is saved before the fade.
func record_checkpoint(zone_id: StringName, entry_id: StringName) -> void:
	var save := root.save_service()
	if save == null:
		return
	save.state.checkpoint_zone_id = zone_id
	save.state.checkpoint_entry_id = entry_id
	save.request_save(&"checkpoint_reached")


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


## Before the room boots: what the run already knows that EcsBoot must not spawn again. Taken pickups
## never respawn; opened gates boot as floor.
func fill_boot_options(options: EcsBootOptions, zone_root: Node) -> void:
	options.skipped_pickup_names = _taken_pickup_names(ZoneStage.zone_id_of(zone_root))
	options.opened_gate_ids = _opened_gate_ids()


## After the room booted: the run's facts enter the new world before anything can ask for a save. The
## world's flags are the saved ones, the run knows which zone this is, and the gates the run opened
## stop showing as closed.
func restore_run(zone_id: StringName) -> void:
	var save := root.save_service()
	if save != null:
		root.ecs.flags.load_dictionary(save.state.player.flags)
		if zone_id != &"":
			save.state.checkpoint_zone_id = zone_id
			save.current_room_id = zone_id
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


func _on_pickup_taken(event: Dictionary) -> void:
	var save := root.save_service()
	if save == null or root.current_zone_id == &"":
		return
	var item_id := int(event.get("item", 0))
	var marker_name := String(cast.get("pickup_name_by_entity", {}).get(item_id, ""))
	if not marker_name.is_empty():
		save.state.taken_pickup_ids[SaveData.pickup_id(root.current_zone_id, marker_name)] = true
		save.request_save(&"pickup_taken")


## A verb unlocked: permanent from this moment, and the live hero has it at once.
func _on_player_unlock(event: Dictionary) -> void:
	var unlock_id := StringName(event.get("id", &""))
	if unlock_id == &"":
		return
	var save := root.save_service()
	if save != null:
		save.state.add_unlock(unlock_id)
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


## The save is about to be written: it learns the flags of the world that is running now, because the
## world is where they change (the run only holds them between rooms).
func _on_save_service_saving(_reason: StringName) -> void:
	var save := root.save_service()
	if save != null and root.ecs != null:
		save.state.player.flags = root.ecs.flags.to_dictionary()


func _opened_gate_ids() -> Array:
	var save := root.save_service()
	var ids: Array = []
	if save == null:
		return ids
	for key in save.state.opened_gate_ids:
		ids.append(StringName(key))
	return ids


## Pickup marker names already taken in this zone: EcsBoot skips them so grabbed weapons never respawn.
func _taken_pickup_names(zone_id: StringName) -> Array:
	var save := root.save_service()
	var names: Array = []
	if save == null or zone_id == &"":
		return names
	var prefix := String(zone_id) + "/"
	for key: String in save.state.taken_pickup_ids:
		if key.begins_with(prefix):
			names.append(key.substr(prefix.length()))
	return names


func _hide_taken_unlock_markers() -> void:
	var save := root.save_service()
	if save == null or root.current_room == null:
		return
	for child in root.current_room.get_children():
		var marker := child as PlayerUnlockMarker
		if marker != null and save.state.has_unlock(marker.unlock_id):
			marker.visible = false
