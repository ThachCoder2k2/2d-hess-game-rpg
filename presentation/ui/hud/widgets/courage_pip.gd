class_name CouragePip
extends Panel

## One Courage mark: an ivory chess base when the pawn has that point of Courage, an empty ring when it has lost it
## (docs/game-base-plan.md req 153: "Courage as ivory chess bases"). The two looks are StyleBoxes the scene names, so the
## owner restyles them in the Inspector (or replaces them with the pictures of the asset list's hud_courage_pips group)
## without touching this script. It only swaps between them.

@export var full_style: StyleBox
@export var empty_style: StyleBox

## Whether the pip shows a Courage point the pawn still has.
var is_filled := true


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	show_filled(is_filled)


func show_filled(filled: bool) -> void:
	is_filled = filled
	var style := full_style if filled else empty_style
	if style != null:
		add_theme_stylebox_override(&"panel", style)
