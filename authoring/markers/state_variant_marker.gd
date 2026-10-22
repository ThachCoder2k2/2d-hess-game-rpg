@tool
class_name StateVariantMarker
extends Node2D

## A prop that is there only while the run is in a certain state (docs/game-base-plan.md 7.3, 8.5): the hub's
## banners and train, a clue, the memory wall, the boxed hub, an ending's last shot. The prop is this node's
## CHILDREN (a sprite, a Polygon2D, a whole scene); the marker holds only the condition for it to be shown, so the
## owner adds a prop that appears after something happened without writing code: drop the node in, fill in two lists.
##
## DATA ONLY at M5. The condition is two lists of flags (`requires_flags` all set, `forbids_flags` none set), the
## shape the trigger markers will use too; M6 bakes it into a FlagVisible component that ViewSyncSystem reads, and
## M7c may widen it to the full Condition[] of the progression plan. Until then nothing hides the prop at run time.
##
## `variant_id` names the variant so a test can ask "every hub state and clue named in a milestone or room meta has
## at least one variant node" (docs/game-base-plan.md 8.5).

## The name of this variant, lowercase snake_case: `hub_state_1`, `clue_2`, `boxed`.
@export var variant_id: StringName = &""
## Flags that must ALL be set for the prop to show (WorldFlags ids such as boss.knight_captain).
@export var requires_flags: Array[StringName] = []
## Flags of which NONE may be set for the prop to show.
@export var forbids_flags: Array[StringName] = []


## True when the prop is shown with these flags set: every required flag is in `set_flag_ids`, no forbidden one is.
## A pure question about the data, for the tests and for the system that will bake it; nothing calls it at run time yet.
func is_shown_with(set_flag_ids: Array[StringName]) -> bool:
	for flag_id in requires_flags:
		if flag_id not in set_flag_ids:
			return false
	for flag_id in forbids_flags:
		if flag_id in set_flag_ids:
			return false
	return true


func configuration_problems() -> PackedStringArray:
	var problems := PackedStringArray()
	if RegEx.create_from_string("^[a-z][a-z0-9_]*$").search(String(variant_id)) == null:
		problems.append("variant_id '%s' must be lowercase snake_case (hub_state_1, clue_2...): tests find the variant by it." % variant_id)
	if requires_flags.is_empty() and forbids_flags.is_empty():
		problems.append("The marker has no condition, so its prop is always shown: it is not a variant. Fill in requires_flags or forbids_flags.")
	for flag_id in requires_flags:
		if not FlagId.is_valid(flag_id):
			problems.append("requires_flags holds '%s', which is not a flag id (lowercase words, groups joined by a dot: boss.knight_captain)." % flag_id)
		if flag_id in forbids_flags:
			problems.append("The flag '%s' is both required and forbidden: the prop could never be shown." % flag_id)
	for flag_id in forbids_flags:
		if not FlagId.is_valid(flag_id):
			problems.append("forbids_flags holds '%s', which is not a flag id (lowercase words, groups joined by a dot: boss.knight_captain)." % flag_id)
	return problems


func _get_configuration_warnings() -> PackedStringArray:
	return configuration_problems()


## Editor only: a small diamond so an empty marker can be found and dragged. It is not drawn in the game.
func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var outline := PackedVector2Array([Vector2(0, -8), Vector2(8, 0), Vector2(0, 8), Vector2(-8, 0), Vector2(0, -8)])
	draw_polyline(outline, Color("#e8b83f", 0.9), 1.5)
