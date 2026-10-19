class_name BoardBridge
extends EventBridge

## The board overlay's responsibility: what the combat events draw on PrototypeBoard. The warning cells
## of a telegraph, the flash of a strike (the enemy's and the hero's), the F3 intent paths, and taking
## a defeated enemy's marks off the board. The overlay draws; this bridge only tells it what happened.
## Reads: events. Writes: the board node. Decides: nothing.

var board: PrototypeBoard


func attach(board_node: PrototypeBoard) -> void:
	board = board_node


func register(router: EventRouter) -> void:
	router.on(Events.TELEGRAPH_STARTED, _on_telegraph_started)
	router.on(Events.TELEGRAPH_FINISHED, _on_telegraph_finished)
	router.on(Events.ATTACK_RESOLVED, _on_attack_resolved)
	router.on(Events.ATTACK_LANDED, _on_player_attack_landed)
	router.on(Events.INTENT_CHANGED, _on_intent_changed)
	router.on(Events.DEFEATED, _on_defeated)


## Binds the overlay to the room that just booted: its grid (untyped, the overlay reads the board
## geometry from it), the snapshot it draws telegraph progress and intent paths from, and whether the
## F3 debug layer is on.
func show_room(grid, debug_enabled: bool) -> void:
	if board == null:
		return
	board.z_index = -5
	board.setup(grid, snapshot)
	board.set_debug_enabled(debug_enabled)


## F3: the boundaries, paths and behaviour labels layer.
func set_debug_view(value: bool) -> void:
	if board != null:
		board.set_debug_enabled(value)


func _on_telegraph_started(event: Dictionary) -> void:
	if board != null:
		board.set_telegraph(int(event.get("entity", 0)), event.get("cells", []))


func _on_telegraph_finished(event: Dictionary) -> void:
	if board != null:
		board.clear_telegraph(int(event.get("entity", 0)))


func _on_attack_resolved(event: Dictionary) -> void:
	if board != null:
		board.show_enemy_attack(event.get("cells", []))


func _on_player_attack_landed(event: Dictionary) -> void:
	var profile := event.get("profile") as AttackProfile
	if board != null and profile != null:
		board.show_player_attack(event.get("cells", []), int(event.get("hit_count", 0)), profile)


func _on_intent_changed(event: Dictionary) -> void:
	if board != null and event.get("intent") is EnemyIntent:
		board.set_enemy_intent(int(event.get("entity", 0)), event.get("intent"))


## An enemy that fell leaves no warning cells or debug path behind. (The hero's own defeat is the
## room outcome's business; the overlay keeps drawing what it drew.)
func _on_defeated(event: Dictionary) -> void:
	var entity := int(event.get("entity", 0))
	if board == null or is_player(entity):
		return
	board.clear_telegraph(entity)
	board.clear_enemy_debug(entity)
