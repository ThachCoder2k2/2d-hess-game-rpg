class_name SkillSlots
extends HudWidget

## The HUD's skill slots (docs/game-base-plan.md D-29, 9.4: skill_slot_1 to 4, an empty slot is hidden). Slot 1 is the
## hero's thrust: it reads the snapshot's sword flag and cooldown, as the line of text did before. The other three are
## declared in the InputMap and have nothing to show before M7a, which makes the slots come from the skill data and
## gives the snapshot a list of them; each will be one more SkillSlot instance in this scene. The room for all four is
## the widget's rectangle, which the HUD safe zone holds in the top strip now, so adding a slot later moves nothing.

@onready var first_slot: SkillSlot = $FirstSlot


func refresh(snapshot: HudSnapshot) -> void:
	if first_slot != null:
		first_slot.show_state(snapshot.sword_unlocked, snapshot.skill_cooldown_left, snapshot.skill_cooldown_duration)


func forget_drawn() -> void:
	if first_slot != null:
		first_slot.forget_drawn()
