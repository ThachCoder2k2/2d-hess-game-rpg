extends SchedulePhase

## Stage 9: consequences that outlast the tick, in this order once they exist: BossPhaseSystem
## (M8b), BossDefeatSystem (M5), CheckpointSystem (M3b), ProgressionSystem (M7c), StoryBeatSystem (M6).
## BossDefeatSystem and CheckpointSystem exist so far.


func phase_name() -> StringName:
	return &"progress"


func systems() -> Array[GDScript]:
	return [
		BossDefeatSystem,
		CheckpointSystem,
	]
