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
