class_name WorldRoom
extends Resource

## One room of the world graph (docs/game-base-plan.md 7.1): which scene it is and which slot of the map it
## sits in. The room's folder is its id, so `room_id` must equal the folder name of `scene`
## (content/rooms/<room_id>/room.tscn); `ContentDb.validate_cross_refs()` and `tests/content/test_world_graph.gd`
## check that. The room's own prose and meta (district, act, status...) live on the scene's RoomEncounter root,
## not here: this resource holds only what is true of the room in the WORLD, and `map_slot` has no other home.

## The room's id: the folder name under content/rooms/, lowercase snake_case (D-05).
@export var room_id: StringName = &""
## The room scene (content/rooms/<room_id>/room.tscn).
@export var scene: PackedScene
## The slot the room occupies on the world map: column, row of the 8 x 10 slot grid (WorldGraph.MAP_COLUMNS,
## WorldGraph.MAP_ROWS). One room to a slot, and the slot lies inside the room's district region.
@export var map_slot := Vector2i.ZERO
