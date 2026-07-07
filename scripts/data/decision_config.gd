class_name DecisionConfig
extends Resource

## Single editor-authored AI profile for an enemy. Assign it on
## EnemyDefinition.decision, or override it per enemy on the EnemyBrainComponent
## node. Every knob the scoring engine reads lives here, so a new enemy
## personality (skirmisher, flanker, sniper, ...) is a .tres, not new code.

@export_group("Timing")
@export_range(0.0, 2.0, 0.01) var observe_delay := 0.42

@export_group("Action scores")
@export var attack_score := 100.0
@export var future_threat_score := 28.0
@export var distance_score := 10.0
@export var pickup_score := 60.0
@export var turn_threat_score := 44.0
@export var wait_score := 8.0

@export_group("Penalties and bonuses")
@export var repetition_penalty := 16.0
@export var recent_cell_penalty := 30.0
@export var path_step_bonus := 18.0
## Bonus for stepping onto a cell that already holds a collectable weapon.
@export var local_pickup_bonus := 50.0
## How strongly the enemy is pulled toward its preferred distance from the hero.
@export var preferred_distance_weight := 2.0
## How strongly a turn that closes facing distance to the hero is rewarded.
@export var turn_progress_weight := 3.0

@export_group("Positioning role")
@export var role_policy: StringName = &"skirmisher"
@export_range(1, 8) var preferred_distance := 2
## Extra score for moving to a cell that puts the hero inside this enemy's
## unarmed attack shape (data-driven flanking pressure; 0 = no flanking bias).
@export var flank_bonus := 0.0
## Extra score for changing movement axis versus the previous step (weaving).
@export var axis_change_bonus := 0.0
