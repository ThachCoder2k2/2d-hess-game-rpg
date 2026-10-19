extends SchedulePhase

## Stage 8: the world reacts to what the tick just resolved: held interactions and rescues
## (InteractionSystem), cell triggers (TriggerSystem, M6), room objectives (ObjectiveSystem, M3b). Only
## ObjectiveSystem exists so far.


func phase_name() -> StringName:
	return &"react"


func systems() -> Array[GDScript]:
	return [
		ObjectiveSystem,
	]
