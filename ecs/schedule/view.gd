extends SchedulePhase

## Stage 10, the end of every tick: the simulation is published. HudSnapshotSystem (M3a, a later
## step) builds the read-only snapshot first, then ViewSyncSystem, the only system that touches
## nodes, moves and animates the puppets from what the tick decided.


func phase_name() -> StringName:
	return &"view"


func systems() -> Array[GDScript]:
	return [
		ViewSyncSystem,
	]
