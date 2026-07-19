class_name EcsComponents
extends RefCounted

## Pure data only — no behavior. Every decision lives in a system
## (docs/ecs-conversion-plan.md). Store keys name the component once.

const GRID_POS := &"grid_pos"
const FACING := &"facing"
const MOVE_INTENT := &"move_intent"
const MOVE_STATE := &"move_state"
const PLAYER_TAG := &"player_tag"
const PLAYER_INPUT := &"player_input"
const VIEW_REF := &"view_ref"
const PLAYER_COMBAT := &"player_combat"
const ATTACK_INTENT := &"attack_intent"
const HEALTH := &"health"
const ENEMY_AI := &"enemy_ai"
const WEAPON_SLOT := &"weapon_slot"
const PICKUP_ITEM := &"pickup_item"


class GridPos:
	var cell := Vector2i.ZERO


class Facing:
	var direction := Vector2i.UP


class MoveIntent:
	## Consumed (reset to ZERO) by MovementSystem each tick.
	var direction := Vector2i.ZERO


class MoveState:
	var from_cell := Vector2i.ZERO
	var to_cell := Vector2i.ZERO
	var progress := 0.0
	var duration := 0.18
	var moving := false


class PlayerTag:
	var control_enabled := true


class PlayerInput:
	var buffered_direction := Vector2i.ZERO
	var hold_time := 0.0
	var last_held_direction := Vector2i.ZERO
	var held_repeat_delay := 0.22


class ViewRef:
	## The puppet node. Only ViewSyncSystem may touch it.
	var node: Node2D


class AttackIntent:
	## &"none" | &"sword" | &"skill". Consumed by CombatSystem each tick.
	var kind: StringName = &"none"


class PlayerCombat:
	var wooden_sword: AttackProfile
	var pencil_thrust: AttackProfile
	var skill_cooldown_duration := 1.25
	var attack_on_cooldown := false
	var active_attack: AttackProfile
	## Cells locked at swing start; damage resolves against them at impact.
	var pending_cells: Array[Vector2i] = []
	var impact_left := 0.0
	var recovery_left := 0.0
	var attack_visual_time := 0.0
	var skill_cooldown_left := 0.0


class Health:
	var current := 3
	var max_value := 3
	## Only entities with PlayerTag get the invulnerability window on hit.
	var invulnerability_duration := 0.70
	var invulnerable_left := 0.0
	var flash_left := 0.0
	var hurt_visual_time := 0.0
	## Knockback offset for the view; set on hit, decayed by HealthSystem.
	var recoil := Vector2.ZERO


class EnemyAI:
	const STATE_OBSERVE := 0
	const STATE_TELEGRAPH := 1
	const STATE_COMMIT := 2
	const STATE_RECOVER := 3
	const STATE_DEFEATED := 4

	var state := STATE_OBSERVE
	var state_time_left := 0.0
	var observe_delay := 0.42
	var move_recovery_time := 0.18
	var unarmed_telegraph_time := 0.58
	var unarmed_recovery_time := 0.48
	## Duration of the running telegraph, for progress display.
	var telegraph_duration := 0.0
	var attack_pattern: AttackPattern
	var decision_profile: DecisionConfig
	var definition: EnemyDefinition
	var allowed_directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var path_memory_size := 6
	var goal_commitment_decisions := 2
	var action_memory: Array[StringName] = []
	var recent_cells: Array[Vector2i] = []
	var last_move_direction := Vector2i.ZERO
	var committed_goal := Vector2i(-999, -999)
	var committed_goal_kind: StringName = &"none"
	var committed_target_snapshot := Vector2i(-999, -999)
	var goal_decisions_left := 0
	## Cells locked when the telegraph starts; the strike resolves against
	## these, which is what makes dodging possible.
	var locked_attack_cells: Array[Vector2i] = []


class WeaponSlot:
	var weapon: EnemyWeapon


class PickupItem:
	var weapon: EnemyWeapon
