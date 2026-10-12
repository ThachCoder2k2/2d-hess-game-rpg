class_name PlayerInputSystem
extends EcsSystem

## Keys -> intents for every entity with PlayerTag + PlayerInput. Ports the
## node-era PlayerInputComponent: step with buffering + held-key repeat, and
## turn-in-place while turn_mode is held. Attack/skill keys arrive in plan
## phase B as combat events.

const DIRECTIONS := {
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN,
	"move_left": Vector2i.LEFT,
	"move_right": Vector2i.RIGHT,
}


func tick(delta: float) -> void:
	for entity_id in world.query([EcsComponents.PLAYER_TAG, EcsComponents.PLAYER_INPUT, EcsComponents.MOVE_STATE]):
		var tag: EcsComponents.PlayerTag = world.get_component(entity_id, EcsComponents.PLAYER_TAG)
		if not tag.control_enabled:
			continue
		var input_state: EcsComponents.PlayerInput = world.get_component(entity_id, EcsComponents.PLAYER_INPUT)
		var move: EcsComponents.MoveState = world.get_component(entity_id, EcsComponents.MOVE_STATE)

		var attack_intent: EcsComponents.AttackIntent = world.get_component(entity_id, EcsComponents.ATTACK_INTENT)
		if attack_intent != null:
			if Input.is_action_just_pressed("attack"):
				attack_intent.kind = &"sword"
			elif Input.is_action_just_pressed("skill_1"):
				attack_intent.kind = &"skill"

		var pressed_direction := _just_pressed_direction()
		if pressed_direction != Vector2i.ZERO:
			if Input.is_action_pressed("turn_mode"):
				_turn(entity_id, pressed_direction)
			elif move.moving:
				input_state.buffered_direction = pressed_direction
			else:
				_request_step(entity_id, pressed_direction)
			input_state.hold_time = 0.0
			input_state.last_held_direction = pressed_direction
			continue

		if not move.moving and input_state.buffered_direction != Vector2i.ZERO:
			_request_step(entity_id, input_state.buffered_direction)
			input_state.buffered_direction = Vector2i.ZERO

		if Input.is_action_pressed("turn_mode"):
			input_state.hold_time = 0.0
			input_state.last_held_direction = Vector2i.ZERO
			continue

		var held_direction := _held_direction()
		if held_direction == Vector2i.ZERO:
			input_state.hold_time = 0.0
			input_state.last_held_direction = Vector2i.ZERO
			continue

		if held_direction != input_state.last_held_direction:
			input_state.hold_time = 0.0
			input_state.last_held_direction = held_direction
		else:
			input_state.hold_time += delta

		if not move.moving and input_state.hold_time >= input_state.held_repeat_delay:
			input_state.hold_time = 0.0
			_request_step(entity_id, held_direction)


func _request_step(entity_id: int, direction: Vector2i) -> void:
	var intent: EcsComponents.MoveIntent = world.get_component(entity_id, EcsComponents.MOVE_INTENT)
	if intent != null:
		intent.direction = direction


func _turn(entity_id: int, direction: Vector2i) -> void:
	var facing: EcsComponents.Facing = world.get_component(entity_id, EcsComponents.FACING)
	if facing != null:
		facing.direction = direction


func _just_pressed_direction() -> Vector2i:
	for action in DIRECTIONS:
		if Input.is_action_just_pressed(action):
			return DIRECTIONS[action]
	return Vector2i.ZERO


func _held_direction() -> Vector2i:
	for action in DIRECTIONS:
		if Input.is_action_pressed(action):
			return DIRECTIONS[action]
	return Vector2i.ZERO
