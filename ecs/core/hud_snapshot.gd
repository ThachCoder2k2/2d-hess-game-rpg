class_name HudSnapshot
extends RefCounted

## The read-only picture of the simulation that the HUD draws from (docs/game-base-plan.md 14.3, D-38):
## HudSnapshotSystem builds it at the end of every tick, so presentation reads this data object and
## never reaches into components (the dependency test then forbids presentation -> ecs/components).
## Presentation never writes it; it asks the simulation for changes with commands.
##
## EcsWorld.hud_snapshot holds the current one. The fields the HUD widgets need arrive with
## HudSnapshotSystem (M3a, a later step) and with each widget that reads them.

## How many times HudSnapshotSystem has rebuilt this snapshot; 0 means it was never built. A widget
## can compare it with the revision it last drew to know whether anything may have changed.
var revision := 0
