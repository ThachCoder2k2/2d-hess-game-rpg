class_name EntityComponent
extends Node

## An editor-draggable component for the ECS: add one as a child of any actor
## view (player or enemy) and EcsBoot bakes it into that entity's runtime
## components at spawn. The node itself holds only Inspector data — it never
## runs logic (systems own all decisions). This is the authoring-component
## pattern: nodes in the dock, tables at runtime.


## Override in each spec: write/override the entity's components.
func apply(_world: EcsWorld, _entity_id: int) -> void:
	pass


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if get_parent() is not ActorView:
		warnings.append("EntityComponent nodes belong under an actor view (player or enemy scene root).")
	return warnings
