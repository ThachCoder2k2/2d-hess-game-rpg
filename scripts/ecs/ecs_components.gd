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
