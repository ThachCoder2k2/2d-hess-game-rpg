class_name PlayerInputComponent
extends PlayerComponent

## Translates raw input into player intents: step (with buffering + held-key
## repeat), turn-in-place, attack, and skill. Owns only key-tracking state
## (hold_time, last_held_direction); gameplay state stays on the player, so
## swapping this node swaps the control scheme without touching combat.

const DIRECTIONS := {
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN,
	"move_left": Vector2i.LEFT,
	"move_right": Vector2i.RIGHT,
}

var hold_time := 0.0
var last_held_direction := Vector2i.ZERO


func _process(delta: float) -> void:
	if player == null or not player.control_enabled:
		return

	if Input.is_action_just_pressed("attack"):
		player.try_attack(player.wooden_sword)
	if Input.is_action_just_pressed("skill_1"):
		player.try_skill()

	var pressed_direction := _just_pressed_direction()
	if pressed_direction != Vector2i.ZERO:
		if Input.is_action_pressed("turn_mode"):
			player.try_turn(pressed_direction)
		elif player.is_moving or player.attack_on_cooldown:
			player.buffered_direction = pressed_direction
		else:
			player._attempt_step(pressed_direction)
		hold_time = 0.0
		last_held_direction = pressed_direction
		return

	if Input.is_action_pressed("turn_mode"):
		hold_time = 0.0
		last_held_direction = Vector2i.ZERO
		return

	var held_direction := _held_direction()
	if held_direction == Vector2i.ZERO:
		hold_time = 0.0
		last_held_direction = Vector2i.ZERO
		return

	if held_direction != last_held_direction:
		hold_time = 0.0
		last_held_direction = held_direction
	else:
		hold_time += delta

	if not player.is_moving and not player.attack_on_cooldown and hold_time >= player.held_repeat_delay:
		hold_time = 0.0
		player._attempt_step(held_direction)


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
