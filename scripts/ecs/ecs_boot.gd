class_name EcsBoot
extends RefCounted

## Turns editor-authored scenes into a running ECS world: parked ActorViews
## become entities (position -> cell, exports -> component values), painted
## solid tiles become blocks, pickup markers become item entities + views.
## WYSIWYG authoring survives the conversion — the scene is spawn data.


## Boots everything and returns the cast:
## { "player": id, "enemies": [ids], "view_by_entity": {id: Node2D},
##   "piece_name_by_entity": {id: String}, "pickup_view_by_entity": {id: Node2D} }
static func boot(world: EcsWorld, player_view: ActorView, room_root: Node, fallback_player_cell := Vector2i(3, 7)) -> Dictionary:
	var cast := {
		"player": 0,
		"enemies": [],
		"view_by_entity": {},
		"piece_name_by_entity": {},
		"pickup_view_by_entity": {},
	}
	if room_root != null:
		apply_solid_tiles(world, room_root)

	if player_view != null:
		var player_cell := world.grid.world_to_cell(player_view.position)
		if not world.grid.is_inside(player_cell):
			player_cell = fallback_player_cell
		var player_id := EcsActorFactory.spawn_player(world, player_cell, player_view.wooden_sword, player_view.pencil_thrust)
		_bind_view(world, player_id, player_view)
		_apply_component_nodes(world, player_id, player_view)
		cast["player"] = player_id
		cast["view_by_entity"][player_id] = player_view
		cast["piece_name_by_entity"][player_id] = "Pawn Hero"

	if room_root != null:
		for child in room_root.get_children():
			var enemy_view := child as ActorView
			if enemy_view == null or enemy_view.definition == null:
				continue
			var cell := world.grid.world_to_cell(enemy_view.position)
			var enemy_id := EcsActorFactory.spawn_enemy(world, enemy_view.definition, cell)
			_bind_view(world, enemy_id, enemy_view)
			_apply_component_nodes(world, enemy_id, enemy_view)
			cast["enemies"].append(enemy_id)
			cast["view_by_entity"][enemy_id] = enemy_view
			cast["piece_name_by_entity"][enemy_id] = enemy_view.definition.piece_name
		_spawn_pickups(world, room_root, cast)
	return cast


## Paint-once walls, ported from the node-era RoomEncounter: every TileMap cell
## whose tile carries solid=true custom data blocks movement and pathing.
static func apply_solid_tiles(world: EcsWorld, room_root: Node) -> void:
	var tilemap := room_root.get_node_or_null("RoomArt/TileMap") as TileMapLayer
	if tilemap == null:
		return
	for cell in tilemap.get_used_cells():
		var tile_data := tilemap.get_cell_tile_data(cell)
		if tile_data != null and bool(tile_data.get_custom_data("solid")):
			world.grid.add_block(cell)


static func _spawn_pickups(world: EcsWorld, room_root: Node, cast: Dictionary) -> void:
	for child in room_root.get_children():
		if not child.has_method("create_weapon"):
			continue
		var weapon := child.call("create_weapon") as EnemyWeapon
		if weapon == null:
			continue
		var cell: Vector2i = child.get("grid_cell")
		var item_id := EcsActorFactory.spawn_pickup(world, weapon, cell)
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
