class_name RoomScan
extends RefCounted

## What the validators and tools need to know about one room scene, read once: the scene is instanced (never
## added to a tree) and freed straight away. ContentDb.validate_cross_refs(), WorldCheck, tools/print_world_map.gd
## and the world-graph test all read rooms through this one scan, so they cannot disagree about what a room holds.

## True when the scene root is a RoomEncounter (anything else is not a room).
var root_is_room_encounter := false
## The root's own zone_id export.
var declared_zone_id: StringName = &""
## entry_id of every ZoneEntryMarker child.
var entry_ids: Array[StringName] = []
## One {door, target_zone, target_entry, requires_room_clear, locked_message, requires_flag, ends_run} per
## ZoneExitMarker child. `door` is the marker's node name, which a WorldEdge names; `requires_flag` is the world
## flag the door waits for (&"" = none) and `ends_run` is true for the door that ends the game (it leads nowhere).
var exits: Array[Dictionary] = []
## The definition of every ActorView child (parked enemies).
var enemy_definitions: Array[EnemyDefinition] = []
## The root's board_size, and what RoomEncounter.configuration_problems() says about the room.
var board_size := Vector2i.ZERO
var configuration_problems := PackedStringArray()
## The meta of the room (RoomEncounter): act, district, layout_archetype and the three enums as the layout
## files spell them (status, time_of_night, recipe), and checkpoint_on_entry.
var act := 0
var district: StringName = &""
var layout_archetype: StringName = &""
var recipe_name := ""
var status_name := ""
var time_of_night_name := ""
var checkpoint_on_entry := false
## The text key of the room's start line (RoomEncounter.room_message).
var start_message_key := ""


static func of(scene: PackedScene) -> RoomScan:
	if scene == null or not scene.can_instantiate():
		return null
	var root := scene.instantiate()
	var scan := RoomScan.new()
	var room := root as RoomEncounter
	scan.root_is_room_encounter = room != null
	if room != null:
		scan.declared_zone_id = room.zone_id
		scan.board_size = room.board_size
		scan.configuration_problems = room.configuration_problems()
		scan.act = room.act
		scan.district = room.district
		scan.layout_archetype = room.layout_archetype
		scan.recipe_name = RoomEncounter.recipe_name(room.recipe)
		scan.status_name = RoomEncounter.status_name(room.content_status)
		scan.time_of_night_name = RoomEncounter.time_of_night_name(room.time_of_night)
		scan.checkpoint_on_entry = room.checkpoint_on_entry
		scan.start_message_key = room.room_message
	for child in root.get_children():
		if child is ZoneEntryMarker:
			scan.entry_ids.append((child as ZoneEntryMarker).entry_id)
		elif child is ZoneExitMarker:
			var exit_marker := child as ZoneExitMarker
			scan.exits.append({
				"door": StringName(exit_marker.name),
				"target_zone": exit_marker.target_zone,
				"target_entry": exit_marker.target_entry,
				"requires_room_clear": exit_marker.requires_room_clear,
				"locked_message": exit_marker.locked_message,
				"requires_flag": exit_marker.requires_flag,
				"ends_run": exit_marker.ends_run,
			})
		elif child is ActorView and (child as ActorView).definition != null:
			scan.enemy_definitions.append((child as ActorView).definition)
	root.free()
	return scan
