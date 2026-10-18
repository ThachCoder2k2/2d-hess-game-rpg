class_name EcsSystem
extends RefCounted

## Base for all systems: logic over component data, ticked in fixed order by
## EcsWorld (the order is data, in ecs/schedule/). Systems never touch nodes — except
## ViewSyncSystem, the one sanctioned bridge to the scene tree. A system file carries
## `const PHASE := &"<stage>"` naming the schedule stage that lists it.

var world: EcsWorld


func setup(ecs_world: EcsWorld) -> void:
	world = ecs_world


func tick(_delta: float) -> void:
	pass


## True when this system must keep ticking while EcsWorld.frozen is true. Only the two systems that
## keep a frozen world alive say yes: CommandSystem (so the freeze can be lifted) and ViewSyncSystem
## (so the picture keeps being drawn and cutscenes can stage the views). Every rule of the game
## says no, and so waits exactly where it was.
func runs_while_frozen() -> bool:
	return false
