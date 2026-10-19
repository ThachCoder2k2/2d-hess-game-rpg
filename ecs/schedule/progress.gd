extends SchedulePhase

## Stage 9: consequences that outlast the tick, in this order once they exist: BossPhaseSystem
## (M8b), CheckpointSystem (M3b), ProgressionSystem (M7c), StoryBeatSystem (M6). Only CheckpointSystem
## exists so far.


func phase_name() -> StringName:
	return &"progress"


func systems() -> Array[GDScript]:
	return [
		CheckpointSystem,
	]
