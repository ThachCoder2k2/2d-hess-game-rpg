class_name HudBridge
extends EventBridge

## The HUD's responsibility: keeping GameHud true to the room. Two kinds of change:
##   - the snapshot, every frame: Courage, the skill slot, the enemy count, the Rank badge and the debug readout's cell line
##     are drawn by the widgets themselves from the HudSnapshot (GameHud.refresh); this bridge only calls it, and tells the
##     debug readout which enemy holds the attack token (the name of a piece is the cast's, not the snapshot's);
##   - events: a hit on the hero flashes the screen. The Courage pips need no event: the snapshot is rebuilt at the end of the
##     tick that took the Courage, before the events are routed.
## The status line (the words) is the MessageBridge's, not this one's.
## Reads: events and the HudSnapshot. Writes: the HUD. Decides: nothing.

var hud: GameHud
## The attack-token owner the debug readout's strike line was last drawn for, so it is redrawn only when it changes.
## -1 means "never drawn for this room".
var last_token_owner := 0


func attach(hud_node: GameHud) -> void:
	hud = hud_node


func register(router: EventRouter) -> void:
	router.on(Events.DAMAGED, _on_damaged)


## Draws the room that just booted: every widget from the snapshot, no result panel, no status line. The caller says the
## room's opening line through the MessageBridge afterwards.
func show_room() -> void:
	last_token_owner = -1
	if hud == null:
		return
	hud.show_room(snapshot)
	_refresh_token_owner()


## Once per frame, after the events: the widgets draw the snapshot, and the strike line follows the token.
func refresh() -> void:
	if hud != null:
		hud.refresh(snapshot)
	_refresh_token_owner()


## Shows the result panel: `title_key` and `subtitle_key` are text keys (the room's clear or defeat lines).
func show_result(title_key: String, subtitle_key: String) -> void:
	if hud != null:
		hud.show_result(title_key, subtitle_key)


## F3: the debug readout instead of the control hints, or the hints again.
func set_debug_view(value: bool) -> void:
	if hud != null:
		hud.set_debug_visible(value)


func _on_damaged(event: Dictionary) -> void:
	if hud != null and is_player(int(event.get("entity", 0))):
		hud.flash_damage()


## A room with no enemies shows no strike line.
func _refresh_token_owner() -> void:
	var token_owner := snapshot.attack_token_owner
	if hud == null or token_owner == last_token_owner:
		return
	last_token_owner = token_owner
	if snapshot.room_enemies_total <= 0:
		hud.set_strike_owner(null, false)
	elif last_token_owner == 0:
		hud.set_strike_owner(null)
	else:
		hud.set_strike_owner(piece_name_of(last_token_owner))
