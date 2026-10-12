class_name VisualDefinition
extends Resource

## How one kind of actor looks and moves, as data. An actor view (presentation/views/actors/
## actor_view_base.tscn, or a thin scene inheriting it) is the same for every piece; what makes a
## knight a knight lives here and in the enemy's own folder.

const MINIMUM_CLIP_SPEED_SCALE := 0.1
const MAXIMUM_CLIP_SPEED_SCALE := 10.0

@export var id: StringName
@export var telegraph_color := Color("#ff665e")
@export var impact_color := Color("#ff9a75")
@export var weapon_anchor := Vector2(5, -2)
@export var hurt_animation: StringName = &"hurt"
@export var defeat_animation: StringName = &"defeat"
## How fast each clip plays compared with the base's tempo: 1.25 plays it 25 % faster, 0.9 a
## little slower. The key is a clip's name (a state of the AnimationTree graph in
## actor_view_base.tscn: idle, step, hurt, telegraph, attack, defeat, wake); a clip that is not
## listed plays at 1.0. The clips themselves exist once, in the base scene, so this is the whole
## difference in tempo between, say, a nimble knight and a plodding pawn.
@export var clip_speed_scales: Dictionary[StringName, float] = {}


func validate() -> PackedStringArray:
	var warnings := PackedStringArray()
	for clip_name in clip_speed_scales:
		var speed_scale: float = clip_speed_scales[clip_name]
		if speed_scale < MINIMUM_CLIP_SPEED_SCALE or speed_scale > MAXIMUM_CLIP_SPEED_SCALE:
			warnings.append("Visual definition '%s': the speed scale of clip '%s' is %s; it must be between %s and %s." % [id, clip_name, speed_scale, MINIMUM_CLIP_SPEED_SCALE, MAXIMUM_CLIP_SPEED_SCALE])
	return warnings
