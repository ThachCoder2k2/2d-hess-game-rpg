extends RefCounted

## Measures where an actor view draws, in whole pixels from the middle of its cell. The owner's
## decision of 2026-10-12 is that a piece, and everything it shows, stays inside its own cell with
## a margin; this is the ruler. It looks at the real nodes (so it sees what ViewSyncSystem and an
## animation wrote, not what a scene file says) and at the opaque pixels of each picture (so a
## transparent border in the owner's png does not count as drawing).
##
## There is no class_name on purpose: callers preload() this script, which keeps it usable on a
## fresh checkout before the editor import pass has run. Shared by tools/render_actor_preview.gd
## and tests/architecture/test_pieces_inside_cell.gd.

## Part names, one per kind of sprite on an actor view.
const PART_BODY := &"body"
const PART_ARROW := &"facing_arrow"
const PART_WEAPON := &"weapon"
const PART_PIPS := &"health_pips"
const PART_AURA := &"telegraph_aura"

## Texture -> the Rect2i of its opaque pixels. A picture is measured once.
var _opaque_rect_by_texture: Dictionary[Texture2D, Rect2i] = {}


## Every sprite of the view that is drawn right now, as one dictionary each:
##   "part"   the part name above (or the node's name for a sprite this does not know)
##   "node"   the Sprite2D
##   "rect"   the box of its opaque pixels, in pixels from the view's origin (the cell's centre)
## Hidden sprites, and sprites whose picture is missing or fully transparent, are left out. The view
## must be inside a scene tree.
func drawn_parts(view: Node2D) -> Array[Dictionary]:
	var parts: Array[Dictionary] = []
	var view_from_world := view.get_global_transform().affine_inverse()
	_collect(view, view, view_from_world, parts)
	return parts


## The smallest rectangle holding every part, or an empty Rect2 for no parts.
static func union_of(parts: Array[Dictionary]) -> Rect2:
	var union := Rect2()
	var is_first := true
	for part in parts:
		var rect: Rect2 = part["rect"]
		union = rect if is_first else union.merge(rect)
		is_first = false
	return union


## How many pixels of empty space `rect` leaves to each edge of the cell: x = left, y = top,
## z = right, w = bottom. Negative means it crosses that edge.
static func margins_inside_cell(rect: Rect2, cell_size: int) -> Vector4:
	var half_cell := cell_size / 2.0
	return Vector4(rect.position.x + half_cell, rect.position.y + half_cell, half_cell - rect.end.x, half_cell - rect.end.y)


## The smallest of the four margins.
static func smallest_margin(rect: Rect2, cell_size: int) -> float:
	var margins := margins_inside_cell(rect, cell_size)
	return minf(minf(margins.x, margins.y), minf(margins.z, margins.w))


## The opaque pixels of a picture, as a rectangle in the picture's own pixels. A picture whose
## pixels cannot be read counts as filled edge to edge, the cautious answer.
func opaque_rect_of(texture: Texture2D) -> Rect2i:
	if _opaque_rect_by_texture.has(texture):
		return _opaque_rect_by_texture[texture]
	var size := Vector2i(texture.get_size())
	var used := Rect2i(Vector2i.ZERO, size)
	var image := texture.get_image()
	if image != null:
		if image.is_compressed():
			image.decompress()
		used = image.get_used_rect()
	_opaque_rect_by_texture[texture] = used
	return used


func _collect(node: Node, view: Node2D, view_from_world: Transform2D, parts: Array[Dictionary]) -> void:
	var sprite := node as Sprite2D
	if sprite != null and sprite.is_visible_in_tree() and sprite.texture != null and sprite.modulate.a > 0.0:
		var used := opaque_rect_of(sprite.texture)
		if used.size.x > 0 and used.size.y > 0:
			var local_rect := sprite.get_rect()
			var opaque_in_sprite := Rect2(local_rect.position + Vector2(used.position), Vector2(used.size))
			var view_from_sprite := view_from_world * sprite.get_global_transform()
			parts.append({"part": _part_name(sprite, view), "node": sprite, "rect": view_from_sprite * opaque_in_sprite})
	for child in node.get_children():
		_collect(child, view, view_from_world, parts)


func _part_name(sprite: Sprite2D, view: Node2D) -> StringName:
	var path := String(view.get_path_to(sprite))
	if path.ends_with("BodySprite"):
		return PART_BODY
	if path.ends_with("FacingArrow"):
		return PART_ARROW
	if path.ends_with("WeaponSprite"):
		return PART_WEAPON
	if path.contains("HealthPips/"):
		return PART_PIPS
	if path.ends_with("TelegraphAura"):
		return PART_AURA
	return sprite.name
