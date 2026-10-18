class_name WorldFlags
extends RefCounted

## The facts of one run that the story and the progression ask about: which beats were seen, which
## rooms are cleared, how many times the child helped (docs/game-base-plan.md 14.2). A flag is a
## StringName id and a value: a bool for a switch, an int for a counter. Nothing here decides; the
## systems that own a rule read and write flags through the `set_flag` command or directly, and
## the save (M3b) writes `to_dictionary()` and reads it back with `load_dictionary()`.
##
## EcsWorld.flags is a fresh, empty instance for every world, and the shell rebuilds the world for
## every room, so whatever must survive a room change is carried by the shell (the save and the
## PlayerSnapshot, M3b), not by this object.

## flag id (StringName) -> value (bool for a switch, int for a counter).
var value_by_flag_id: Dictionary = {}


func has_flag(flag_id: StringName) -> bool:
	return value_by_flag_id.has(flag_id)


## The flag's value, or `default_value` when it was never set.
func get_flag(flag_id: StringName, default_value: Variant = false) -> Variant:
	return value_by_flag_id.get(flag_id, default_value)


## Sets a switch or a counter. True when the stored value changed, false when it already was this.
func set_flag(flag_id: StringName, value: Variant) -> bool:
	if value_by_flag_id.has(flag_id) and typeof(value_by_flag_id[flag_id]) == typeof(value) and value_by_flag_id[flag_id] == value:
		return false
	value_by_flag_id[flag_id] = value
	return true


## Adds to a counter (a flag never set counts from 0) and returns its new value.
func add_to_counter(flag_id: StringName, amount: int = 1) -> int:
	var total := int(value_by_flag_id.get(flag_id, 0)) + amount
	value_by_flag_id[flag_id] = total
	return total


func clear() -> void:
	value_by_flag_id.clear()


## The flags as plain data for the save: flag id (String) -> value.
func to_dictionary() -> Dictionary:
	var saved: Dictionary = {}
	for flag_id: StringName in value_by_flag_id:
		saved[String(flag_id)] = value_by_flag_id[flag_id]
	return saved


## Replaces every flag with the saved ones (the reverse of to_dictionary()).
func load_dictionary(saved: Dictionary) -> void:
	value_by_flag_id.clear()
	for flag_name: String in saved:
		value_by_flag_id[StringName(flag_name)] = saved[flag_name]
