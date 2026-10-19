class_name DebugReadout
extends HudWidget

## The numbers a developer wants and a player does not (docs/game-base-plan.md D-29, requirement 181): the cell the pawn
## stands on and the way it faces, and which enemy holds the room's one attack token. It sits in the bottom strip where the
## control hints are and takes their place while the debug view is on; F3 switches both (GameHud.set_debug_visible). It is
## hidden when the game starts, and the game scene never starts with it shown in a release build (see
## ShellKeys.debug_view_at_start).
##
## The cell line is drawn from the HudSnapshot. The strike line names a piece, which the snapshot does not know (a name is the
## cast's), so the HudBridge hands it over as a TextKey. Both are kept up to date while the readout is hidden, so the
## numbers are right the moment F3 shows them.

@onready var cell_label: Label = $CellLabel
@onready var strike_label: Label = $StrikeLabel

## The cell and facing on screen. A cell far outside any board before the first draw.
var _drawn_cell := Vector2i(-9999, -9999)
var _drawn_facing := Vector2i.ZERO
## Keeps both lines in the player's language. Made on first use.
var _live_text: LiveText = null


## The text key of the compass word for a cell direction (east for anything that is not up, down or left).
static func compass_key(direction: Vector2i) -> String:
	if direction == Vector2i.UP:
		return "UI_COMPASS_NORTH"
	if direction == Vector2i.DOWN:
		return "UI_COMPASS_SOUTH"
	if direction == Vector2i.LEFT:
		return "UI_COMPASS_WEST"
	return "UI_COMPASS_EAST"


## A world with no hero leaves the cell line as it was.
func refresh(snapshot: HudSnapshot) -> void:
	if cell_label == null or snapshot.player_entity == 0:
		return
	if snapshot.player_cell == _drawn_cell and snapshot.player_facing == _drawn_facing:
		return
	_drawn_cell = snapshot.player_cell
	_drawn_facing = snapshot.player_facing
	_live().set_text(cell_label, "UI_HUD_CELL", {
		"x": "%02d" % _drawn_cell.x,
		"y": "%02d" % _drawn_cell.y,
		"facing": TextKey.of(compass_key(_drawn_facing)),
	})


func forget_drawn() -> void:
	_drawn_cell = Vector2i(-9999, -9999)
	_drawn_facing = Vector2i.ZERO


## Names the enemy that holds the attack token; null = the token is free (any enemy may strike next). `active` false
## empties the line (a room with no enemies).
func set_strike_owner(owner_piece: TextKey = null, active := true) -> void:
	if strike_label == null:
		return
	if not active:
		_live().release(strike_label)
		strike_label.text = ""
	elif owner_piece == null:
		_live().set_text(strike_label, "UI_HUD_TOKEN_FREE")
	else:
		_live().set_text(strike_label, "UI_HUD_TOKEN_OWNER", {"piece": owner_piece.uppercased()})


func _live() -> LiveText:
	if _live_text == null:
		_live_text = LiveText.new()
		add_child(_live_text)
	return _live_text
