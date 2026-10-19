class_name SchedulePhase
extends RefCounted

## One stage of the tick: the systems that run in it, in the order they run (docs/game-base-plan.md
## 13.4). A stage is one file in ecs/schedule/, so six milestones adding six systems edit six
## different files instead of one list. A stage is not the same thing as the folder a system lives
## in (ecs/systems/<folder>/): the plan's order visits the `world` folder three times, so a stage is
## named for WHEN it runs and a folder for WHAT its systems are about.
##
## A stage file extends this class and overrides the two methods. Adding a system is one line in
## the stage's systems() list; the system file carries `const PHASE := &"<phase_name>"` and
## tests/architecture/test_schedule_complete.gd fails if the two disagree or a system is unlisted.


## The stage's name: the file name, and the PHASE const of every system listed in it.
func phase_name() -> StringName:
	return &""


## The scripts of the systems that run in this stage, in running order. Each one extends EcsSystem.
func systems() -> Array[GDScript]:
	return []
