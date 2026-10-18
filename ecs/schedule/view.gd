extends SchedulePhase

## Stage 10, the end of every tick: the simulation is published. HudSnapshotSystem builds the
## read-only snapshot first, so the HUD and the board draw what the tick decided, then
## ViewSyncSystem, the only system that touches nodes, moves and animates the puppets from it.


func phase_name() -> StringName:
	return &"view"


func systems() -> Array[GDScript]:
	return [
		HudSnapshotSystem,
		ViewSyncSystem,
	]
