class_name VisualDefinition
extends Resource

@export var id: StringName
@export var telegraph_color := Color("#ff665e")
@export var impact_color := Color("#ff9a75")
@export var weapon_anchor := Vector2(5, -2)
@export var hurt_animation: StringName = &"hurt"
@export var defeat_animation: StringName = &"defeat"


func validate() -> PackedStringArray:
	return PackedStringArray()
