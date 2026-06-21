class_name VisualDefinition
extends Resource

@export var id: StringName
@export var visual_scene: PackedScene
@export var legacy_draw_kind: StringName
@export var telegraph_color := Color("#ff665e")
@export var impact_color := Color("#ff9a75")
@export var weapon_anchor := Vector2(5, -2)
@export var hurt_animation: StringName = &"hurt"
@export var defeat_animation: StringName = &"defeat"


func validate() -> PackedStringArray:
	var warnings := PackedStringArray()
	if visual_scene == null and legacy_draw_kind.is_empty():
		warnings.append("Assign a visual scene or a temporary legacy draw kind.")
	return warnings
