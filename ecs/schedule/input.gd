extends SchedulePhase

## Stage 2: the player's controls become intents (steps, turns, attack requests).


func phase_name() -> StringName:
	return &"input"


func systems() -> Array[GDScript]:
	return [
		PlayerInputSystem,
	]
