class_name ShellBridge
extends EventBridge

## A bridge that has to reach what presentation may not: the live world, the save, the scene tree and
## the hero's components. It lives in the shell, the one layer allowed to name everything
## (docs/game-base-plan.md 13.1), and it is still ONE responsibility with the same shape as the
## bridges in presentation/bridges/: it registers for event types and reacts. The presentation bridges
## draw, say and play; these write the run, move the hero between rooms and decide what a room's end is.
##
## `root` is the in-game scene the bridge belongs to. Through it the bridge reads the booted world
## (`root.ecs`), the save (`root.save_service()`) and the zone it stands in; it never holds them, because
## every room replaces the world.

var root: GameRoot


func attach(game_root: GameRoot) -> void:
	root = game_root
