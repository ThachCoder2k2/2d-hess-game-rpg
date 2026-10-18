extends SchedulePhase

## Stage 5: intents become steps through the grid's reserve -> commit protocol.


func phase_name() -> StringName:
	return &"move"


func systems() -> Array[GDScript]:
	return [
		MovementSystem,
	]
