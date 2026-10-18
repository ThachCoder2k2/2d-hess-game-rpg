extends SchedulePhase

## Stage 3: enemies choose what to do. EnemyAISystem keeps one owner from M8a to M13 because every
## enemy family changes its brain; families extend it through AttackStage data, not new systems here.


func phase_name() -> StringName:
	return &"decide"


func systems() -> Array[GDScript]:
	return [
		EnemyAISystem,
	]
