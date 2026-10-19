extends SchedulePhase

## Stage 6: attacks and skills play out. CombatSystem drives the Wooden Sword and the Pencil Thrust
## and keeps doing so beside SkillSystem (M7a) until the parity cutover of M7b; StatusSystem (M7a)
## follows them.


func phase_name() -> StringName:
	return &"act"


func systems() -> Array[GDScript]:
	return [
		CombatSystem,
	]
