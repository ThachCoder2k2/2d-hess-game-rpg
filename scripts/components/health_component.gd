class_name HealthComponent
extends EnemyComponent

@export var animation_player_path: NodePath = ^"AnimationPlayer"
@export var hurt_animation: StringName = &"hurt"
@export var defeat_animation: StringName = &"defeat"
@export_range(0.01, 1.0, 0.01) var flash_duration := 0.12
@export_range(0.0, 16.0, 0.5) var recoil_pixels := 4.0

var animation_player: AnimationPlayer


func configure(host: FreeEnemy) -> void:
	super(host)
	_resolve_animation_player()


func get_health() -> int:
	return actor.health if actor != null else 0


func get_max_health() -> int:
	if actor != null and actor.definition != null:
		return actor.definition.max_health
	return get_health()


func apply_damage(amount: int, direction := Vector2i.ZERO) -> bool:
	if actor == null or actor.state == FreeEnemy.State.DEFEATED:
		return false
	actor.health = maxi(0, actor.health - amount)
	actor.flash_time = flash_duration
	actor.recoil = Vector2(direction) * recoil_pixels
	if actor.health <= 0:
		_defeat_actor()
	else:
		_play_feedback_animation(hurt_animation)
	return true


func _defeat_actor() -> void:
	actor.state = FreeEnemy.State.DEFEATED
	actor.emit_signal("telegraph_finished", actor)
	if actor.director != null:
		actor.director.release_attack(actor)
	if actor.grid_world != null:
		actor.grid_world.unregister_actor(actor)
	actor.emit_signal("defeated", actor)
	_play_defeat_feedback()


func _play_defeat_feedback() -> void:
	if _play_feedback_animation(defeat_animation) and is_inside_tree():
		await animation_player.animation_finished
	elif actor != null and actor.is_inside_tree():
		var tween := actor.create_tween()
		tween.tween_property(actor, "scale", Vector2(1.15, 0.15), 0.18)
		await tween.finished
	if actor != null and is_instance_valid(actor):
		actor.queue_free()


func _play_feedback_animation(animation_name: StringName) -> bool:
	_resolve_animation_player()
	if animation_player == null or animation_name.is_empty() or not animation_player.has_animation(animation_name):
		return false
	animation_player.play(animation_name)
	return true


func _resolve_animation_player() -> void:
	if animation_player == null:
		animation_player = get_node_or_null(animation_player_path) as AnimationPlayer
