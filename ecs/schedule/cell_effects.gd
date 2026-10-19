extends SchedulePhase

## Stage 4: effects that live on cells (chalk, corruption) update before anyone moves, so a step
## sees the cell as it will be when it lands. Empty until the first cell effect (CellEffectSystem,
## planned with the chalk verbs of M10).


func phase_name() -> StringName:
	return &"cell_effects"


func systems() -> Array[GDScript]:
	return [
	]
