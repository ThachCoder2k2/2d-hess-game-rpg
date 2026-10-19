class_name GameHud
extends CanvasLayer

## The in-game HUD (docs/game-base-plan.md D-29, 9.2, 10): a layer that holds the widgets, each a scene of its own
## (presentation/ui/hud/widgets/), and routes to them. It decides nothing. The widgets that show the simulation read the
## HudSnapshot (refresh()); the few things that are not in it come from the bridges: the status line's words (MessageBridge),
## the damage flash and the result panel (HudBridge), the name of the enemy that strikes next (HudBridge, for the debug
## readout) and the debug switch (ShellKeys).
##
## The picture keeps to two strips (docs/game-base-plan.md 10): the top strip (y 0 to 32, nothing taller than 28 px) holds
## Courage, the reserved Believe slot, the skill slots, the reserved boss bar, the enemy count and the Rank badge; the
## bottom strip (y 326 to 360) holds the status line and the control hints, which the F3 debug readout replaces. No widget is
## ever on a row of the board (tests/presentation/test_hud_safe_zone.gd); only the damage flash and the result panel, which
## are effects of a moment and of the end of a room, cover it. Every word on it is a text key resolved by TextService.

@onready var courage_pips: CouragePips = $CouragePips
@onready var believe_slot: BelieveSlot = $BelieveSlot
@onready var skill_slots: SkillSlots = $SkillSlots
@onready var boss_bar_slot: BossBarSlot = $BossBarSlot
@onready var enemy_count: EnemyCount = $EnemyCount
@onready var rank_badge: RankBadge = $RankBadge
@onready var objective_line: ObjectiveLine = $ObjectiveLine
@onready var control_prompts: ControlPrompts = $ControlPrompts
@onready var debug_readout: DebugReadout = $DebugReadout
@onready var damage_flash: DamageFlash = $DamageFlash
@onready var result_panel: ResultPanel = $ResultPanel

## Reduce flashing (the setting, docs/game-base-plan.md 10): the red screen flash is left out. The Courage pips still
## change, so the hit is shown; the flash is the part that can hurt.
var reduce_flash := false:
	set(value):
		reduce_flash = value
		if damage_flash != null:
			damage_flash.reduce_flash = value


func _ready() -> void:
	damage_flash.reduce_flash = reduce_flash


## Every widget of the strips, shown or reserved, in scene order. The safe zone test walks this list.
func widgets() -> Array[HudWidget]:
	var found: Array[HudWidget] = []
	for child in get_children():
		if child is HudWidget:
			found.append(child)
	return found


## Draws the room that just booted: every widget from the snapshot at once, the status line empty, no result panel and no
## flash left over from the last room. The caller says the room's opening line through the status line afterwards.
func show_room(snapshot: HudSnapshot) -> void:
	for widget in widgets():
		widget.forget_drawn()
	refresh(snapshot)
	objective_line.clear()
	result_panel.hide_result()


## Once per frame: every widget draws what the snapshot says now (and only what changed).
func refresh(snapshot: HudSnapshot) -> void:
	for widget in widgets():
		widget.refresh(snapshot)


## Gives the control hints the glyph finder and the tracker of the last input device (AppRoot owns both).
func configure_controls(glyph_source: InputGlyphs, device_tracker: LastInputDevice) -> void:
	control_prompts.configure(glyph_source, device_tracker)


## Puts the words of `key` on the status line ("" empties it). `params` fill its {name}s.
func set_status(key: String, params: Dictionary = {}) -> void:
	objective_line.say(key, params)


## One red screen flash that fades out on its own.
func flash_damage() -> void:
	damage_flash.flash()


## Shows the result panel with two keys: the title and the line under it.
func show_result(title_key: String, subtitle_key: String) -> void:
	result_panel.show_result(title_key, subtitle_key)


## Names the enemy that holds the attack token on the debug readout (null = free, `active` false = no enemies).
func set_strike_owner(owner_piece: TextKey = null, active := true) -> void:
	debug_readout.set_strike_owner(owner_piece, active)


## F3: the debug readout (the pawn's cell and the strike line) takes the place of the control hints, or gives it back.
func set_debug_visible(value: bool) -> void:
	debug_readout.visible = value
	control_prompts.visible = not value
