class_name GameHud
extends CanvasLayer

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

## The running fade tween for the damage flash; killed and restarted on each hit.
var _damage_flash_tween: Tween


func setup(initial_courage: int) -> void:
	set_courage(initial_courage)
	set_skill_cooldown(0.0, 1.0)
	set_encounter_count(0, 0)
	set_token_owner(null)
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
	courage_label.text = "COURAGE " + "◆".repeat(value) + "◇".repeat(3 - value)
	var color := Color("#d84a3a") if value <= 1 else Color("#ff9a75")
	courage_label.add_theme_color_override("font_color", color)


func set_skill_cooldown(time_left: float, cooldown_duration: float) -> void:
	if skill_label != null:
		skill_label.text = "Q THRUST READY" if time_left <= 0.0 else "Q THRUST %.1f" % time_left
	if skill_fill == null:
		return
	var ratio := 1.0
	if time_left > 0.0:
		ratio = clampf(1.0 - time_left / maxf(cooldown_duration, 0.001), 0.0, 1.0)
	skill_fill.size.x = SKILL_BAR_WIDTH * ratio
	skill_fill.color = Color("#8ec8e8", 0.9) if time_left <= 0.0 else Color("#e8b83f", 0.82)


func set_token_owner(token_owner: Node) -> void:
	if token_label == null:
		return
	if token_owner == null:
		token_label.text = "ENEMY STRIKE READY"
	else:
		token_label.text = "STRIKE: " + _enemy_piece_name(token_owner).to_upper()


func set_encounter_count(remaining: int, total: int) -> void:
	if encounter_label != null:
		encounter_label.text = "ENEMIES %d/%d" % [remaining, total]


func set_cell_status(cell: Vector2i, facing_name: String) -> void:
	if status_label != null:
		status_label.text = "CELL %02d,%02d  FACE %s" % [cell.x, cell.y, facing_name]


func set_status(text: String) -> void:
	if objective_label != null:
		objective_label.text = text


## One red screen flash that fades out on its own. Callers fire-and-forget;
## the HUD owns the whole lifecycle (no per-frame driving from outside).
func flash_damage() -> void:
	if damage_flash == null:
		return
	if _damage_flash_tween != null and _damage_flash_tween.is_valid():
		_damage_flash_tween.kill()
	damage_flash.visible = true
	damage_flash.color = Color("#d84a3a", 0.20)
	_damage_flash_tween = create_tween()
	_damage_flash_tween.tween_property(damage_flash, "color:a", 0.0, DAMAGE_FLASH_DURATION)
	_damage_flash_tween.tween_callback(func() -> void: damage_flash.visible = false)


func show_result(title: String, subtitle: String) -> void:
	if result_panel != null:
		result_panel.visible = true
	if result_label == null:
		return
	result_label.text = title + "\n" + subtitle
	result_label.visible = true


func _enemy_piece_name(enemy: Node) -> String:
	if enemy != null and enemy.has_method("get_piece_display_name"):
		return String(enemy.call("get_piece_display_name"))
	return "Enemy"
