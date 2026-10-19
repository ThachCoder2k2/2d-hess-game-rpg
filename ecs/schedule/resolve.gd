extends SchedulePhase

## Stage 7: what the act stage requested is applied: damage and healing change Health, defeats
## happen. KnockbackSystem (M8c) follows HealthSystem.


func phase_name() -> StringName:
	return &"resolve"


func systems() -> Array[GDScript]:
	return [
		HealthSystem,
	]
