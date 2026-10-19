class_name EcsBoot
extends RefCounted

## Turns editor-authored scenes into a running ECS world: parked ActorViews
## become entities (position -> cell, exports -> component values), painted
## solid tiles become blocks (a tile's `kind` gives its cell a gap, a leapable block, chalk or corruption
## instead), pickup markers become item entities + views.
## WYSIWYG authoring survives the conversion — the scene is spawn data.


## Boots everything `options` (EcsBootOptions) names and returns the cast:
## { "player": id, "enemies": [ids], "view_by_entity": {id: Node2D},
##   "piece_name_by_entity": {id: String (the piece's text key)}, "pickup_view_by_entity": {id: Node2D},
##   "pickup_name_by_entity": {id: String}, "persistent_pickup_by_entity": {id: true}, "room": id }
## `persistent_pickup_by_entity` holds the pickups whose marker is persistent (the save remembers them
## taken); every other pickup is a room-local floor weapon. `room` is the room's own entity (0 unless the
## options asked for room rules).
## What the save already knows (taken pickups, opened gates) arrives in the options: the bridge
## reads the save and EcsBoot never does.
static func boot(world: EcsWorld, options: EcsBootOptions) -> Dictionary:
	var player_view := options.player_view as ActorView
	assert(options.player_view == null or player_view != null, "EcsBootOptions.player_view must be an ActorView")
	var room_root := options.room_root
	var fallback_player_cell := options.fallback_player_cell
	var skipped_pickup_names := options.skipped_pickup_names
	var opened_gate_ids := options.opened_gate_ids
	var cast := {
		"player": 0,
		"enemies": [],
		"view_by_entity": {},
		"piece_name_by_entity": {},
		"pickup_view_by_entity": {},
		"pickup_name_by_entity": {},
		"persistent_pickup_by_entity": {},
		"room": 0,
	}
	if room_root != null:
		shape_grid(world, room_root, options.view_size)
		apply_tile_kinds(world, room_root)
		_bake_zone_exits(world, room_root)
		_bake_player_unlocks(world, room_root)
		_bake_gates(world, room_root, opened_gate_ids)

	if player_view != null:
		var player_cell := world.grid.world_to_cell(player_view.position)
		if not world.grid.is_inside(player_cell):
			player_cell = fallback_player_cell
		# The kit (courage, timings, attack profiles) comes from the view's PlayerDefinition
		# (content/player/player.tres); a view that names none plays on the definition's
		# defaults. EntityComponent nodes on the view are applied after it and win.
		var player_definition := player_view.player_definition
		if player_definition == null:
			player_definition = PlayerDefinition.new()
		var player_id := EcsActorFactory.spawn_player_from_definition(world, player_definition, player_cell)
		_bind_view(world, player_id, player_view)
		_apply_component_nodes(world, player_id, player_view)
		if options.player_snapshot != null:
			options.player_snapshot.apply_to(world, player_id, options.restore_player_facing)
		cast["player"] = player_id
		cast["view_by_entity"][player_id] = player_view
		cast["piece_name_by_entity"][player_id] = player_definition.piece_name

	if room_root != null:
		for child in room_root.get_children():
			var enemy_view := child as ActorView
			if enemy_view == null or enemy_view.definition == null:
				continue
			if options.room_already_cleared:
				# The run cleared this room before (D-17): its enemies stay gone, so the parked puppet goes too.
				room_root.remove_child(enemy_view)
				enemy_view.queue_free()
				continue
			var cell := world.grid.world_to_cell(enemy_view.position)
			var enemy_id := EcsActorFactory.spawn_enemy(world, enemy_view.definition, cell)
			_bind_view(world, enemy_id, enemy_view)
			_apply_component_nodes(world, enemy_id, enemy_view)
			cast["enemies"].append(enemy_id)
			cast["view_by_entity"][enemy_id] = enemy_view
			cast["piece_name_by_entity"][enemy_id] = enemy_view.definition.piece_name
		_spawn_pickups(world, room_root, cast, skipped_pickup_names)
		if options.with_room_rules:
			cast["room"] = _spawn_room_entity(world, room_root, cast, options)
	return cast


## Gives the grid the shape of the room: the bounds from the board_size the room scene exports
## (RoomEncounter, so every zone can be a different board) and an origin that centres that board in the
## view (docs/game-base-plan.md D-02). A 16x9 room starts at (64, 36), an 18x9 arena at (32, 36); a board
## larger than the view keeps the fixed anchor on that axis, because the camera scrolls there. A view_size
## of zero means the project's own (project_view_size()).
##
## boot() calls this first. The shell calls it too, before boot, because it turns the room's entry
## marker and the hero's view position into cells with the same grid and needs the room's origin for that.
## It is safe to call twice. A null room leaves the grid as it is.
static func shape_grid(world: EcsWorld, room_root: Node, view_size := Vector2.ZERO) -> void:
	if room_root == null:
		return
	var size: Variant = room_root.get("board_size")
	if size is Vector2i and size.x > 0 and size.y > 0:
		world.grid.bounds = Rect2i(Vector2i.ZERO, size)
	var shown_size := view_size if view_size != Vector2.ZERO else project_view_size()
	world.grid.grid_origin = EcsGrid.centred_origin(world.grid.bounds.size, world.grid.cell_size, shown_size)


## The size of the picture the game draws in, in pixels: the base size set in project.godot
## (display/window/size, which the stretch mode keeps whatever the window size is). The one home of
## that number; nothing in code repeats 640 x 360.
static func project_view_size() -> Vector2:
	return Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width")),
		float(ProjectSettings.get_setting("display/window/size/viewport_height")))


## The room's own entity: what the room asks of the pawn (its RoomEncounter objective and zone id) and how
## many enemies it began with, for ObjectiveSystem to judge; whether coming in is a checkpoint
## (RoomEncounter.checkpoint_on_entry) and how the pawn arrived, for CheckpointSystem. Made last, so every
## other entity keeps the number it always had. Returns the entity id.
static func _spawn_room_entity(world: EcsWorld, room_root: Node, cast: Dictionary, options: EcsBootOptions) -> int:
	var room_entity := world.create_entity()
	var zone_value: Variant = room_root.get("zone_id")
	var zone_id: StringName = zone_value if zone_value is StringName else &""
	var objective_state := RoomObjectiveState.new()
	objective_state.zone_id = zone_id
	objective_state.objective = room_root.get("objective") as RoomObjective
	objective_state.enemies_total = cast["enemies"].size()
	objective_state.enemies_remaining = cast["enemies"].size()
	objective_state.cleared = options.room_already_cleared
	world.add_component(room_entity, RoomObjectiveState.KEY, objective_state)
	var checkpoint := RoomCheckpoint.new()
	checkpoint.zone_id = zone_id
	checkpoint.entry_id = options.entry_id
	checkpoint.checkpoint_on_entry = room_root.get("checkpoint_on_entry") == true
	checkpoint.entered_by_door = options.entered_by_door
	world.add_component(room_entity, RoomCheckpoint.KEY, checkpoint)
	return room_entity


## Shortcut gates: every GateMarker child blocks its cell unless the save
## already opened it (the bridge passes those ids in) — then it is floor.
static func _bake_gates(world: EcsWorld, room_root: Node, opened_gate_ids: Array) -> void:
	for child in room_root.get_children():
		var gate_marker := child as GateMarker
		if gate_marker == null or gate_marker.gate_id in opened_gate_ids:
			continue
		var cell := world.grid.world_to_cell(gate_marker.position)
		world.grid.add_block(cell)
		world.grid.gate_by_cell[cell] = {
			"id": gate_marker.gate_id,
			"opens_from": gate_marker.opens_from,
		}


## Door cells: every ZoneExitMarker child becomes an exit_by_cell entry the
## MovementSystem watches for the player.
static func _bake_zone_exits(world: EcsWorld, room_root: Node) -> void:
	for child in room_root.get_children():
		var exit_marker := child as ZoneExitMarker
		if exit_marker == null:
			continue
		var cell := world.grid.world_to_cell(exit_marker.position)
		world.grid.exit_by_cell[cell] = {
			"zone": exit_marker.target_zone,
			"entry": exit_marker.target_entry,
			"requires_room_clear": exit_marker.requires_room_clear,
			"locked_message": exit_marker.locked_message,
		}


static func _bake_player_unlocks(world: EcsWorld, room_root: Node) -> void:
	for child in room_root.get_children():
		var unlock_marker := child as PlayerUnlockMarker
		if unlock_marker == null:
			continue
		var cell := world.grid.world_to_cell(unlock_marker.position)
		world.grid.player_unlock_by_cell[cell] = {
			"id": unlock_marker.unlock_id,
			"message": unlock_marker.message,
		}


## Paint-once terrain, grown from the node-era paint-once walls: every TileMap cell whose tile is not plain
## floor gives its grid cell that kind (docs/game-base-plan.md 5.11). What a tile says is
## CellKinds.kind_of_tile(): its `kind` custom data when filled in with a known kind, else a wall when
## `solid` is true. A wall blocks movement and pathing exactly as a solid tile always did; a gap, a leapable
## block, chalk or corruption is stored the same way and is read by the services that ask for kinds.
static func apply_tile_kinds(world: EcsWorld, room_root: Node) -> void:
	var tilemap := room_root.get_node_or_null("RoomArt/TileMap") as TileMapLayer
	if tilemap == null or tilemap.tile_set == null:
		return
	for cell in tilemap.get_used_cells():
		var tile_data := tilemap.get_cell_tile_data(cell)
		if tile_data == null:
			continue
		var kind := CellKinds.kind_of_tile(tilemap.tile_set, tile_data)
		if kind != CellKinds.FLOOR:
			world.grid.set_cell_kind(cell, kind)


static func _spawn_pickups(world: EcsWorld, room_root: Node, cast: Dictionary, skipped_pickup_names: Array = []) -> void:
	for child in room_root.get_children():
		if not child.has_method("create_weapon") or String(child.name) in skipped_pickup_names:
			continue
		var weapon := child.call("create_weapon") as EnemyWeapon
		if weapon == null:
			continue
		var cell: Vector2i = child.get("grid_cell")
		var item_id := EcsActorFactory.spawn_pickup(world, weapon, cell)
		cast["pickup_name_by_entity"][item_id] = String(child.name)
		if child.get("persistent") == true:
			cast["persistent_pickup_by_entity"][item_id] = true
		var pickup_view := _make_pickup_view(child, weapon)
		if pickup_view != null:
			room_root.add_child(pickup_view)
			pickup_view.z_index = 1
			pickup_view.position = world.grid.cell_to_world(cell)
			cast["pickup_view_by_entity"][item_id] = pickup_view


## The pickup view is the old WeaponPickup scene used as a dumb prop: no grid
## registration (its setup() is never called), just the floating sprite.
static func _make_pickup_view(marker: Node, weapon: EnemyWeapon) -> Node2D:
	var view: Node2D = null
	if marker.has_method("create_pickup"):
		view = marker.call("create_pickup") as Node2D
	if view == null:
		return null
	view.set("weapon", weapon)
	return view


static func _bind_view(world: EcsWorld, entity_id: int, view_node: Node2D) -> void:
	var view: EcsComponents.ViewRef = world.add_component(entity_id, EcsComponents.VIEW_REF, EcsComponents.ViewRef.new())
	view.node = view_node


## Editor-draggable components: every EntityComponent child of a view bakes its
## Inspector data into the freshly spawned entity (after the definition, so a
## component node on an instance always wins).
static func _apply_component_nodes(world: EcsWorld, entity_id: int, view_node: Node2D) -> void:
	for child in view_node.get_children():
		var component_node := child as EntityComponent
		if component_node != null:
			component_node.apply(world, entity_id)
