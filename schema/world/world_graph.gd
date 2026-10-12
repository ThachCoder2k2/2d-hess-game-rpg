class_name WorldGraph
extends Resource

## The world as one editor-authored resource: zone id -> zone scene. Adding a
## zone to the game = author the scene, add one entry here. Exits inside zone
## scenes name their destination by these ids (ZoneExitMarker.target_zone).

@export var zone_scene_by_id: Dictionary[StringName, PackedScene] = {}


func get_zone_scene(zone_id: StringName) -> PackedScene:
	return zone_scene_by_id.get(zone_id)


func has_zone(zone_id: StringName) -> bool:
	return zone_scene_by_id.has(zone_id)


func validate() -> PackedStringArray:
	var warnings := PackedStringArray()
	if zone_scene_by_id.is_empty():
		warnings.append("World graph has no zones.")
	for zone_id: StringName in zone_scene_by_id:
		if zone_scene_by_id[zone_id] == null:
			warnings.append("Zone '%s' has no scene." % zone_id)
	return warnings
