class_name EcsSystem
extends RefCounted

## Base for all systems: logic over component data, ticked in fixed order by
## EcsWorld. Systems never touch nodes — except ViewSyncSystem, the one
## sanctioned bridge to the scene tree.

var world: EcsWorld


func setup(ecs_world: EcsWorld) -> void:
	world = ecs_world


func tick(_delta: float) -> void:
	pass
