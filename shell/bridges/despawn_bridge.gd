class_name DespawnBridge
extends ShellBridge

## What happens to a view when its entity leaves the room: the floor weapon an enemy picked up
## disappears at once, and a defeated enemy's view stays long enough for its defeat clip (squash and
## crumple, editor-owned: ViewSyncSystem travels the view's AnimationTree to it) and is then freed.
## The hero's view is never despawned: it is the one view that outlives every room.
## Reads: events and the cast. Writes: frees views and drops the entity's VIEW_REF.

## Seconds a defeated enemy's view is kept for its defeat clip.
const DEFEAT_CLIP_SECONDS := 0.6


func register(router: EventRouter) -> void:
	router.on(Events.PICKUP_TAKEN, _on_pickup_taken)
	router.on(Events.DEFEATED, _on_defeated)


func _on_pickup_taken(event: Dictionary) -> void:
	var item_id := int(event.get("item", 0))
	var pickup_views: Dictionary = cast.get("pickup_view_by_entity", {})
	var view := pickup_views.get(item_id) as Node2D
	if view != null and is_instance_valid(view):
		view.queue_free()
	pickup_views.erase(item_id)


func _on_defeated(event: Dictionary) -> void:
	var entity := int(event.get("entity", 0))
	if is_player(entity):
		return
	var view := cast.get("view_by_entity", {}).get(entity) as Node2D
	if view == null or not is_instance_valid(view):
		return
	# The world that owns the entity, not the one running when the timer ends: a trip or a respawn
	# inside the 0.6 s builds a new world whose entity numbers start over, and dropping the VIEW_REF of
	# "entity 2" there would freeze somebody else's puppet.
	var world := root.ecs
	var tween := root.create_tween()
	tween.tween_interval(DEFEAT_CLIP_SECONDS)
	tween.tween_callback(func() -> void:
		if is_instance_valid(world):
			world.remove_component(entity, EcsComponents.VIEW_REF)
		if is_instance_valid(view):
			view.queue_free())
