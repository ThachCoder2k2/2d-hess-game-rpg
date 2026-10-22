class_name WorldRegion
extends Resource

## The part of the world map one district may use (docs/game-base-plan.md 7.1: "District regions on the slot
## grid, the owner may rearrange in world.tres"). A room's map slot must lie inside the region of its district
## (RoomEncounter.district), so the map keeps its shape while rooms are added.

## The district this region belongs to (one of WorldGraph.DISTRICT_IDS).
@export var district: StringName = &""
## The slots the district may use: position is the first column and row, size the number of columns and rows.
@export var slots := Rect2i()
