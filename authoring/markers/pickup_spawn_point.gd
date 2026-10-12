@tool
class_name PickupSpawnPoint
extends GridMarker

@export var active := true
@export var pickup_scene: PackedScene
@export var weapon: EnemyWeapon
@export var show_editor_preview := true:
	set(value):
		show_editor_preview = value
		_sync_preview_visibility()


func create_weapon() -> EnemyWeapon:
	return weapon.duplicate(true) if active and weapon != null else null


func create_pickup() -> WeaponPickup:
	if not active:
		return null
	if pickup_scene == null:
		return WeaponPickup.new()
	var pickup := pickup_scene.instantiate() as WeaponPickup
	if pickup == null:
		push_warning("PickupSpawnPoint '%s' needs a WeaponPickup-compatible scene." % name)
	return pickup


func _ready_marker() -> void:
	_sync_preview_visibility()


func _sync_preview_visibility() -> void:
	var preview := get_node_or_null("Preview") as CanvasItem
	if preview != null:
		preview.visible = Engine.is_editor_hint() and show_editor_preview


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var color := Color("#e8b83f", 0.85)
	if weapon != null:
		color = weapon.color
	var fill := color
	fill.a = 0.22
	draw_rect(Rect2(Vector2(-8, -8), Vector2(16, 16)), fill)
	draw_rect(Rect2(Vector2(-8, -8), Vector2(16, 16)), Color("#fff4d6", 0.75), false, 1.5)
	draw_line(Vector2(-7, 5), Vector2(7, -5), color, 2.5)
