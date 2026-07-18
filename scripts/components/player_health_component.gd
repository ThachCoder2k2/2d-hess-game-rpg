class_name PlayerHealthComponent
extends PlayerComponent

## Courage loss, hit feedback timing, and the post-hit invulnerability window.
## State (courage, is_invulnerable, hurt_visual_time) stays on the player so the
## HUD, appearance, and tests keep one source of truth; this node owns the rules.


func apply_damage(amount: int) -> bool:
	if player == null or player.is_invulnerable or player.courage <= 0:
		return false
	player.courage = maxi(0, player.courage - amount)
	player.hurt_visual_time = 0.18
	player.emit_signal("courage_changed", player.courage)
	player.emit_signal("damaged", amount, player.courage)
	if player.courage <= 0:
		player.control_enabled = false
		player.emit_signal("defeated")
	else:
		start_invulnerability()
	return true


func start_invulnerability() -> void:
	player.is_invulnerable = true
	if not player.is_inside_tree():
		player.is_invulnerable = false
		return
	var tree := player.get_tree()
	if tree == null:
		player.is_invulnerable = false
		return
	await tree.create_timer(player.invulnerability_duration).timeout
	if not is_instance_valid(player) or not player.is_inside_tree():
		return
	player.is_invulnerable = false
