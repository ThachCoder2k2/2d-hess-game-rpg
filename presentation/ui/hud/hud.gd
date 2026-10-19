class_name GameHud
extends CanvasLayer

## The in-game HUD. It draws what the bridges hand it and decides nothing. Every word on it is a key resolved by
## TextService: the labels a scene authored (the banner, the help line) hold their key in `text` and the engine
## translates them; the ones set from here (Courage, the skill slot, the strike line, the counts, the cell, the
## status line, the result panel) are bound to their key on a LiveText, so a language switch redraws them with
## their numbers and names intact.

@onready var courage_label: Label = $CourageLabel
@onready var skill_label: Label = $SkillLabel
@onready var skill_fill: ColorRect = $SkillFill
@onready var status_label: Label = $StatusLabel
@onready var encounter_label: Label = $EncounterLabel
@onready var objective_label: Label = $ObjectiveLabel
@onready var token_label: Label = $TokenLabel
@onready var damage_flash: ColorRect = $DamageFlash
@onready var result_panel: ColorRect = $ResultPanel
@onready var result_label: Label = $ResultLabel

const SKILL_BAR_WIDTH := 92.0
const DAMAGE_FLASH_DURATION := 0.22

## Reduce flashing (the setting, docs/game-base-plan.md 10): the red screen flash is left out. The Courage pips still
## change, so the hit is shown; the flash is the part that can hurt.
var reduce_flash := false:
	set(value):
		reduce_flash = value
		if value and _damage_flash_tween != null and _damage_flash_tween.is_valid():
			_damage_flash_tween.kill()
		if value and damage_flash != null:
			damage_flash.visible = false

## The running fade tween for the damage flash; killed and restarted on each hit.
var _damage_flash_tween: Tween
## Keeps the labels set from code in the player's language. Made on first use, so a HUD that is not in the tree yet
## can still be driven.
var _live_text: LiveText = null


func setup(initial_courage: int) -> void:
	set_courage(initial_courage)
	set_skill_cooldown(0.0, 1.0, false)
	set_encounter_count(0, 0)
	set_token_owner(null, false)
	set_status("")
	if damage_flash != null:
		damage_flash.visible = false
	if result_panel != null:
		result_panel.visible = false
	if result_label != null:
		result_label.visible = false


func set_courage(value: int) -> void:
	if courage_label == null:
		return
	_live().set_text(courage_label, "UI_HUD_COURAGE", {"pips": "◆".repeat(value) + "◇".repeat(3 - value)})
	var color := Color("#d84a3a") if value <= 1 else Color("#ff9a75")
	courage_label.add_theme_color_override("font_color", color)


func set_skill_cooldown(time_left: float, cooldown_duration: float, unlocked := true) -> void:
	if skill_label != null:
		if not unlocked:
			_live().set_text(skill_label, "UI_HUD_SKILL_LOCKED")
		elif time_left <= 0.0:
			_live().set_text(skill_label, "UI_HUD_SKILL_READY")
		else:
			_live().set_text(skill_label, "UI_HUD_SKILL_COOLDOWN", {"seconds": "%.1f" % time_left})
	if skill_fill == null:
		return
	var ratio := 1.0
	if not unlocked:
		ratio = 0.0
	elif time_left > 0.0:
		ratio = clampf(1.0 - time_left / maxf(cooldown_duration, 0.001), 0.0, 1.0)
	skill_fill.size.x = SKILL_BAR_WIDTH * ratio
	skill_fill.color = Color("#5d5360", 0.45) if not unlocked else Color("#8ec8e8", 0.9) if time_left <= 0.0 else Color("#e8b83f", 0.82)


## `owner_piece` is the name of the piece that holds the attack token; null = the token is free (any enemy may
## strike next). `active` false hides the line (a room with no enemies).
func set_token_owner(owner_piece: TextKey = null, active := true) -> void:
	if token_label == null:
		return
	if not active:
		_live().release(token_label)
		token_label.text = ""
	elif owner_piece == null:
		_live().set_text(token_label, "UI_HUD_TOKEN_FREE")
	else:
		_live().set_text(token_label, "UI_HUD_TOKEN_OWNER", {"piece": owner_piece.uppercased()})


func set_encounter_count(remaining: int, total: int) -> void:
	if encounter_label != null:
		_live().set_text(encounter_label, "UI_HUD_ENEMIES", {"remaining": remaining, "total": total})


## `facing` is the compass word the hero faces (a TextKey of the UI_COMPASS_ rows).
func set_cell_status(cell: Vector2i, facing: TextKey) -> void:
	if status_label != null:
		_live().set_text(status_label, "UI_HUD_CELL", {"x": "%02d" % cell.x, "y": "%02d" % cell.y, "facing": facing})


## Puts the words of `key` on the status line ("" empties it). `params` fill its {name}s.
func set_status(key: String, params: Dictionary = {}) -> void:
	if objective_label == null:
		return
	if key.is_empty():
		_live().release(objective_label)
		objective_label.text = ""
	else:
		_live().set_text(objective_label, key, params)


## One red screen flash that fades out on its own. Callers fire-and-forget;
## the HUD owns the whole lifecycle (no per-frame driving from outside).
func flash_damage() -> void:
	if damage_flash == null or reduce_flash:
		return
	if _damage_flash_tween != null and _damage_flash_tween.is_valid():
		_damage_flash_tween.kill()
	damage_flash.visible = true
	damage_flash.color = Color("#d84a3a", 0.20)
	_damage_flash_tween = create_tween()
	_damage_flash_tween.tween_property(damage_flash, "color:a", 0.0, DAMAGE_FLASH_DURATION)
	_damage_flash_tween.tween_callback(func() -> void: damage_flash.visible = false)


## Shows the result panel with two keys: the title and the line under it.
func show_result(title_key: String, subtitle_key: String) -> void:
	if result_panel != null:
		result_panel.visible = true
	if result_label == null:
		return
	_live().set_text(result_label, "UI_RESULT_PANEL", {"title": TextKey.of(title_key), "subtitle": TextKey.of(subtitle_key)})
	result_label.visible = true


func _live() -> LiveText:
	if _live_text == null:
		_live_text = LiveText.new()
		add_child(_live_text)
	return _live_text
