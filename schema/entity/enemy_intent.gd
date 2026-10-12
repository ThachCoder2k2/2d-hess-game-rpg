class_name EnemyIntent
extends RefCounted

enum Type { ATTACK, MOVE, PICKUP, TURN, WAIT }

var type := Type.WAIT
var action_id: StringName = &"wait"
var score := 0.0
var destination := Vector2i.ZERO
var direction := Vector2i.ZERO
var target_cells: Array[Vector2i] = []


static func attack(cells: Array[Vector2i], value: float) -> EnemyIntent:
	var intent := EnemyIntent.new()
	intent.type = Type.ATTACK
	intent.action_id = &"attack"
	intent.score = value
	intent.target_cells = cells.duplicate()
	return intent


static func move(cell: Vector2i, move_direction: Vector2i, value: float) -> EnemyIntent:
	var intent := EnemyIntent.new()
	intent.type = Type.MOVE
	intent.action_id = _directional_id(&"move", move_direction)
	intent.score = value
	intent.destination = cell
	intent.direction = move_direction
	return intent


static func pickup(value: float) -> EnemyIntent:
	var intent := EnemyIntent.new()
	intent.type = Type.PICKUP
	intent.action_id = &"pickup"
	intent.score = value
	return intent


static func turn(turn_direction: Vector2i, value: float) -> EnemyIntent:
	var intent := EnemyIntent.new()
	intent.type = Type.TURN
	intent.action_id = _directional_id(&"turn", turn_direction)
	intent.score = value
	intent.direction = turn_direction
	return intent


static func wait(value: float) -> EnemyIntent:
	var intent := EnemyIntent.new()
	intent.score = value
	return intent


static func _directional_id(prefix: StringName, intent_direction: Vector2i) -> StringName:
	var suffix := "north"
	if intent_direction == Vector2i.DOWN:
		suffix = "south"
	elif intent_direction == Vector2i.LEFT:
		suffix = "west"
	elif intent_direction == Vector2i.RIGHT:
		suffix = "east"
	return StringName("%s_%s" % [prefix, suffix])
