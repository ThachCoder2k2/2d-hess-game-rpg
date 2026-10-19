class_name ZoneStage
extends RefCounted

## The scene-tree plumbing of the stage a room is played on, kept out of game_root.gd so the scene
## reads as "build the world, tick it, route what it says": making the world node, finding where the
## hero enters a zone, and putting a zone or a hero's view in the place of the old one. Every function
## is static and takes the nodes it works on; none keeps state and none decides anything.

## The cell value that means "no entry marker found".
const NO_ENTRY_CELL := Vector2i(-1, -1)


## A new, empty EcsWorld under `host`, ticked by the host (manual_tick) with the systems of ecs/schedule/.
static func make_world(host: Node) -> EcsWorld:
	var world := EcsWorld.new()
	world.name = "EcsWorld"
	world.manual_tick = true
	host.add_child(world)
	Schedule.populate(world)
	return world


## The cell of the ZoneEntryMarker called `entry_id` in `zone_root`, else of its first marker, else
## NO_ENTRY_CELL. Cells are read with `grid`, so shape the grid with the room's origin first.
static func find_entry_cell(grid: EcsGrid, zone_root: Node, entry_id: StringName) -> Vector2i:
	if zone_root == null:
		return NO_ENTRY_CELL
	var fallback := NO_ENTRY_CELL
	for child in zone_root.get_children():
		var entry := child as ZoneEntryMarker
		if entry == null:
			continue
		var cell := grid.world_to_cell(entry.position)
		if entry.entry_id == entry_id:
			return cell
		if fallback == NO_ENTRY_CELL:
			fallback = cell
	return fallback


## The zone id a room scene root carries (RoomEncounter.zone_id), &"" for none.
static func zone_id_of(zone_root: Node) -> StringName:
	if zone_root == null:
		return &""
	var value: Variant = zone_root.get("zone_id")
	return value if value is StringName else &""


## The room's own prose for `getter` (its start, clear or defeat line: RoomEncounter.get_start_message...),
## or `fallback` when there is no room or it has no such line.
static func room_text(zone_root: Node, getter: StringName, fallback: String) -> String:
	if zone_root != null and zone_root.has_method(getter):
		return String(zone_root.call(getter))
	return fallback


## Puts a new instance of `zone_scene` in the place of `old_zone` under `host`, keeping the tree position so
## draw order (board below, HUD above) stays intact, and frees the old one. Returns the new zone node, or
## `old_zone` when there is no scene to build.
static func replace_zone_node(host: Node, old_zone: Node, zone_scene: PackedScene) -> Node:
	if zone_scene == null:
		return old_zone
	var slot_index := old_zone.get_index() if old_zone != null else host.get_child_count()
	if old_zone != null:
		host.remove_child(old_zone)
		old_zone.queue_free()
	var zone := zone_scene.instantiate()
	host.add_child(zone)
	host.move_child(zone, slot_index)
	return zone


## Swaps the hero's view for a fresh instance of its scene, in the same place in the tree and parked at
## `parked_position`, where the authored scene parks it. A defeated hero's view holds the end of its
## defeat clip; a new one boots in the pose its animation graph gives it (the hero gets up). Returns the
## new view, or `old_view` when it was not made from a scene file (a bare test view cannot be rebuilt).
static func replace_hero_view(host: Node, old_view: ActorView, parked_position: Vector2) -> ActorView:
	if old_view == null or old_view.scene_file_path.is_empty():
		return old_view
	var fresh_view := (load(old_view.scene_file_path) as PackedScene).instantiate() as ActorView
	if fresh_view == null:
		return old_view
	var slot_index := old_view.get_index()
	var view_name := old_view.name
	host.remove_child(old_view)
	old_view.queue_free()
	fresh_view.name = view_name
	fresh_view.position = parked_position
	host.add_child(fresh_view)
	host.move_child(fresh_view, slot_index)
	return fresh_view
