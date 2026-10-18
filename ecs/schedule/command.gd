extends SchedulePhase

## Stage 1, the head of every tick: requests that presentation and settings pushed on
## world.commands since the last tick are applied before anything simulates, so a freeze, a flag
## or a tuning change lands at one known point of the order (docs/game-base-plan.md D-38).


func phase_name() -> StringName:
	return &"command"


func systems() -> Array[GDScript]:
	return [
		CommandSystem,
	]
