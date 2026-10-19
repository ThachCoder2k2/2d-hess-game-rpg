class_name HudBridge
extends EventBridge

## The HUD's responsibility: keeping GameHud (courage, skill slot, enemy count, whose strike is next,
## the cell the hero stands on, the result panel) true to the room. Two kinds of change:
##   - events: a hit on the hero flashes the screen and redraws the Courage pips, and so does a heal (a
##     checkpoint refill); the skill's cooldown changing redraws the slot;
##   - the snapshot, every frame: the enemy count, whose strike is next and the hero's cell and facing are
##     read from the HudSnapshot (refresh()), never from a component. M4's widgets draw the snapshot
##     themselves and this half goes away.
## The status line (the words) is the MessageBridge's, not this one's.
## Reads: events and the HudSnapshot. Writes: the HUD. Decides: nothing.

## The Courage a HUD shows before the room has a hero to ask.
const COURAGE_WITHOUT_HERO := 3

var hud: GameHud
## The enemy count the line was last drawn for, as (still standing, began with), so it is redrawn only
## when it changes. (-1, -1) means "never drawn for this room".
var last_enemy_count := Vector2i(-1, -1)
## The attack-token owner the strike line was last drawn for, so it is redrawn only when it changes.
## -1 means "never drawn for this room".
var last_token_owner := 0


func attach(hud_node: GameHud) -> void:
	hud = hud_node


func register(router: EventRouter) -> void:
	router.on(Events.DAMAGED, _on_damaged)
	router.on(Events.SKILL_COOLDOWN, _on_skill_cooldown)


## Draws the room that just booted: Courage, the enemy count, the skill slot at rest and the strike
## line. The caller says the room's opening line through the MessageBridge afterwards.
func show_room() -> void:
	last_enemy_count = Vector2i(-1, -1)
	last_token_owner = -1
	if hud == null:
		return
	hud.setup(snapshot.player_courage_current if snapshot.player_entity != 0 else COURAGE_WITHOUT_HERO)
	_refresh_enemy_count()
	_show_skill_cooldown(0.0)
	_refresh_token_owner()


## Once per frame, after the events: the enemy count, the strike line and the cell line follow the snapshot.
func refresh() -> void:
	_refresh_enemy_count()
	_refresh_token_owner()
	if hud != null and snapshot.player_entity != 0:
		hud.set_cell_status(snapshot.player_cell, facing_name(snapshot.player_facing))


func show_result(title: String, subtitle: String) -> void:
	if hud != null:
		hud.show_result(title, subtitle)


## The compass letter for a cell direction ("E" for anything that is not up, down or left).
static func facing_name(direction: Vector2i) -> String:
	if direction == Vector2i.UP:
		return "N"
	if direction == Vector2i.DOWN:
		return "S"
	if direction == Vector2i.LEFT:
		return "W"
	return "E"


func _on_damaged(event: Dictionary) -> void:
	if hud == null or not is_player(int(event.get("entity", 0))):
		return
	hud.flash_damage()
	hud.set_courage(int(event.get("remaining", 0)))


func _on_skill_cooldown(event: Dictionary) -> void:
	_show_skill_cooldown(float(event.get("time_left", 0.0)))


## Shows the skill slot for `time_left` seconds of cooldown. The slot is redrawn when a
## skill_cooldown event arrives (and at boot), as it always was, from the snapshot's length and
## sword flag. M4's widgets draw the snapshot every frame instead.
func _show_skill_cooldown(time_left: float) -> void:
	if hud != null:
		hud.set_skill_cooldown(time_left, snapshot.skill_cooldown_duration, snapshot.sword_unlocked)


func _refresh_enemy_count() -> void:
	var enemy_count := Vector2i(snapshot.room_enemies_remaining, snapshot.room_enemies_total)
	if hud == null or enemy_count == last_enemy_count:
		return
	last_enemy_count = enemy_count
	hud.set_encounter_count(enemy_count.x, enemy_count.y)


## A room with no enemies shows no strike line.
func _refresh_token_owner() -> void:
	var token_owner := snapshot.attack_token_owner
	if hud == null or token_owner == last_token_owner:
		return
	last_token_owner = token_owner
	if snapshot.room_enemies_total <= 0:
		hud.set_token_owner("", false)
	elif last_token_owner == 0:
		hud.set_token_owner("")
	else:
		hud.set_token_owner(piece_name_of(last_token_owner))
