class_name PlayerDefinition
extends Resource

## The pawn's tuning as data: one file, content/player/player.tres, holds every number
## that decides how the hero feels. The player view (ActorView.player_definition)
## names it and EcsBoot bakes it into the player entity at spawn, exactly as an
## EnemyDefinition is baked into an enemy. An EntityComponent node placed under the
## player view still beats this definition field by field (HealthComponent,
## MovementComponent, InputComponent, CombatComponent), so one room or scene can
## override a value without touching the shared file.
##
## Defaults equal the values the hero had before this class existed, so a definition
## with no overrides plays identically to the old scene. The authored values live in
## content/player/player.tres; this file only gives the Inspector its starting point.

## Text key (CHAR_PAWN_HERO_PIECE in story.po): the label shown in status text (for example when the hero picks
## something up).
@export var piece_name := "CHAR_PAWN_HERO_PIECE"
## How the hero looks and how fast its clips play (content/player/visual.tres). The player
## view reads it exactly as an enemy view reads EnemyDefinition.visual. Null shows the
## view's built-in stand-in body at the base's tempo.
@export var visual: VisualDefinition

@export_group("Courage")
## Starting and maximum Courage (the hero's health). The entity spawns full.
@export_range(1, 9) var max_courage := 3
## Seconds after a hit during which the hero cannot be hurt again.
@export_range(0.0, 3.0, 0.05) var invulnerability_duration := 0.70

@export_group("Movement")
## Seconds one cell-to-cell step takes (the slide the dodge window is built on).
@export_range(0.05, 1.0, 0.01) var step_duration := 0.18
## Seconds a direction key must be held before the hero repeats the step.
@export_range(0.05, 1.0, 0.01) var held_repeat_delay := 0.22

@export_group("Combat")
## The Space attack. Null leaves the slot empty (a test hero with no weapon).
@export var wooden_sword: AttackProfile
## The Q skill. Null leaves the slot empty.
@export var pencil_thrust: AttackProfile
## False starts the hero with the sword locked (a PlayerUnlockMarker grants it later).
@export var starts_with_sword := true
## Seconds the skill (Q) is unavailable after it is used.
@export_range(0.1, 5.0, 0.05) var skill_cooldown_duration := 1.25


func validate() -> PackedStringArray:
	var warnings := PackedStringArray()
	if piece_name.strip_edges().is_empty():
		warnings.append("Player definition requires a piece_name.")
	if max_courage < 1:
		warnings.append("Player definition needs max_courage of at least 1.")
	if invulnerability_duration < 0.0:
		warnings.append("Player definition invulnerability_duration cannot be negative.")
	if step_duration <= 0.0:
		warnings.append("Player definition needs a step_duration above 0.")
	if held_repeat_delay <= 0.0:
		warnings.append("Player definition needs a held_repeat_delay above 0.")
	if skill_cooldown_duration <= 0.0:
		warnings.append("Player definition needs a skill_cooldown_duration above 0.")
	if wooden_sword == null:
		warnings.append("Player definition requires the wooden_sword AttackProfile.")
	else:
		warnings.append_array(wooden_sword.validate())
	if pencil_thrust == null:
		warnings.append("Player definition requires the pencil_thrust AttackProfile.")
	else:
		warnings.append_array(pencil_thrust.validate())
	if visual == null:
		warnings.append("Player definition requires a VisualDefinition (content/player/visual.tres).")
	else:
		warnings.append_array(visual.validate())
	return warnings
