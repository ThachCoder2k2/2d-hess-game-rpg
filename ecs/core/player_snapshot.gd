class_name PlayerSnapshot
extends RefCounted

## What the pawn takes with it from one room to the next, and into a save (docs/game-base-plan.md
## 14.2). The shell rebuilds the whole EcsWorld for every room, so everything that must outlive a
## room is captured from the old world at the exit and applied to the new one right after
## EcsBoot.boot(). Before M3b only an integer survived a room change; this is the whole contract, defined
## once so that the zone swap (ZoneTravelBridge, M3b), the checkpoint and the save all carry the same thing.
##
## Pure data with a dictionary form: the save is a versioned dictionary, and a Resource would tie
## the save file to script paths. Only the rows the plan marks PERSISTENT are fields. Everything
## the plan marks per-room or per-encounter is deliberately NOT here, so it resets with the world:
##
##   carried (a field below)              | resets with the room (no field)
##   courage current and max              | skill cooldowns, status (guard, untargetable, in_check,
##   believe current                      |   stagger, invulnerability, help_disrupted)
##   unlocked skills, applied upgrades    | the skill cast, the attack lock and token, telegraphs
##   equipped pages and Margin            | hit progress toward Believe (1 of 3)
##   the direction lock (Act 6)           | the floor weapon held
##   the flags and counters (WorldFlags)  | cell effects (chalk) and the raised block
##   facing (see apply_to)                |
##
## Several rows name components that later milestones add (Believe M10, SkillBook M7a, Loadout M7c,
## DirectionLock M13). The fields exist now with neutral values and round-trip through the save, so
## the milestone that adds the component adds one line to capture() and one to apply_to(), and the
## save format does not change. The rows with a component today are courage, the sword unlock,
## facing and the flags.

## The format of to_dictionary(). Bump it when a field changes meaning, and read the old one in from_dictionary().
const FORMAT_VERSION := 1

## The unlock id of the wooden sword, as a PlayerUnlockMarker names it and as the save stores it.
## Until SkillBook (M7a) is the list of unlocked skills, this one id is what "has the sword" means.
const SWORD_UNLOCK_ID := &"wooden_sword"

## Courage (Health.current and max_value) when the snapshot was taken.
var courage_current := 3
var courage_max := 3

## Believe marks the child's help has left (M10). 0 until the Believe component exists.
var believe_current := 0

## Skill ids the pawn has unlocked, and the ids of the upgrades applied to them (SkillBook, M7a).
## Today: SWORD_UNLOCK_ID when PlayerCombat.sword_unlocked.
var unlocked_skill_ids: Array[StringName] = []
var applied_upgrade_ids: Array[StringName] = []

## Rule Pages equipped in the Book, and the Margin they are paid from (Loadout, M7c).
var equipped_page_ids: Array[StringName] = []
var margin := 0

## Cell directions the Act 6 direction lock has taken away (DirectionLock, M13); empty when nothing is locked.
var locked_directions: Array[Vector2i] = []

## The cell direction the pawn faces. A room change does NOT restore it by default: the entry marker
## sets the facing of the new room (14.2, "per-room"). A checkpoint or a save resume asks for it with
## apply_to(..., restore_facing = true).
var facing := Vector2i.UP

## The flags and counters of the run (WorldFlags.to_dictionary()): flag id (String) -> bool or int.
## Includes child_calls_used, child_trust, the shard count and the death count.
var flags: Dictionary = {}


## Takes the snapshot of the hero `player_entity` and of the world's flags. A missing component
## leaves its fields at their neutral value.
static func capture(world: EcsWorld, player_entity: int) -> PlayerSnapshot:
	var snapshot := PlayerSnapshot.new()
	var health: EcsComponents.Health = world.get_component(player_entity, EcsComponents.HEALTH)
	if health != null:
		snapshot.courage_current = health.current
		snapshot.courage_max = health.max_value
	var combat: EcsComponents.PlayerCombat = world.get_component(player_entity, EcsComponents.PLAYER_COMBAT)
	if combat != null and combat.sword_unlocked:
		snapshot.unlocked_skill_ids.append(SWORD_UNLOCK_ID)
	var facing_component: EcsComponents.Facing = world.get_component(player_entity, EcsComponents.FACING)
	if facing_component != null:
		snapshot.facing = facing_component.direction
	snapshot.flags = world.flags.to_dictionary()
	return snapshot


## Writes the snapshot into a freshly booted world: the hero's courage and sword, the world's flags
## and, when asked, the facing. Nothing else is touched, so every per-room row stays at the value the
## boot gave it. A hero without a component skips that row.
func apply_to(world: EcsWorld, player_entity: int, restore_facing := false) -> void:
	var health: EcsComponents.Health = world.get_component(player_entity, EcsComponents.HEALTH)
	if health != null:
		health.max_value = courage_max
		health.current = clampi(courage_current, 0, courage_max)
	var combat: EcsComponents.PlayerCombat = world.get_component(player_entity, EcsComponents.PLAYER_COMBAT)
	if combat != null:
		combat.sword_unlocked = SWORD_UNLOCK_ID in unlocked_skill_ids
	if restore_facing:
		var facing_component: EcsComponents.Facing = world.get_component(player_entity, EcsComponents.FACING)
		if facing_component != null:
			facing_component.direction = facing
	world.flags.load_dictionary(flags)


## The snapshot as plain data that survives JSON: String keys, ints, strings, arrays and one
## dictionary of flags. from_dictionary() is the reverse.
func to_dictionary() -> Dictionary:
	return {
		"format_version": FORMAT_VERSION,
		"courage_current": courage_current,
		"courage_max": courage_max,
		"believe_current": believe_current,
		"unlocked_skill_ids": _strings_of(unlocked_skill_ids),
		"applied_upgrade_ids": _strings_of(applied_upgrade_ids),
		"equipped_page_ids": _strings_of(equipped_page_ids),
		"margin": margin,
		"locked_directions": _pairs_of(locked_directions),
		"facing": [facing.x, facing.y],
		"flags": flags.duplicate(true),
	}


## Reads what to_dictionary() wrote, also after a trip through JSON (where every number comes back as
## a float). A key that is missing or has the wrong type keeps its neutral value: a save written by
## an older game, or damaged, still loads. Returns null for a save from a NEWER format, which only a
## newer game can read; the caller (the save service, M3b) decides what to do about that.
static func from_dictionary(saved: Dictionary) -> PlayerSnapshot:
	if _whole_number(saved.get("format_version", FORMAT_VERSION), FORMAT_VERSION) > FORMAT_VERSION:
		return null
	var snapshot := PlayerSnapshot.new()
	snapshot.courage_current = _whole_number(saved.get("courage_current"), snapshot.courage_current)
	snapshot.courage_max = _whole_number(saved.get("courage_max"), snapshot.courage_max)
	snapshot.believe_current = _whole_number(saved.get("believe_current"), snapshot.believe_current)
	snapshot.margin = _whole_number(saved.get("margin"), snapshot.margin)
	snapshot.unlocked_skill_ids = _ids_from(saved.get("unlocked_skill_ids"))
	snapshot.applied_upgrade_ids = _ids_from(saved.get("applied_upgrade_ids"))
	snapshot.equipped_page_ids = _ids_from(saved.get("equipped_page_ids"))
	snapshot.locked_directions = _directions_from(saved.get("locked_directions"))
	var saved_facing: Variant = _pair_from(saved.get("facing"))
	if saved_facing != null:
		snapshot.facing = saved_facing
	var saved_flags: Variant = saved.get("flags")
	if saved_flags is Dictionary:
		for flag_name: Variant in saved_flags:
			var flag_value: Variant = saved_flags[flag_name]
			if flag_value is bool:
				snapshot.flags[String(flag_name)] = flag_value
			elif flag_value is int or flag_value is float:
				snapshot.flags[String(flag_name)] = _whole_number(flag_value, 0)
	return snapshot


static func _strings_of(ids: Array[StringName]) -> Array:
	var strings: Array = []
	for id in ids:
		strings.append(String(id))
	return strings


static func _pairs_of(directions: Array[Vector2i]) -> Array:
	var pairs: Array = []
	for direction in directions:
		pairs.append([direction.x, direction.y])
	return pairs


## An int from a saved number (JSON hands back floats), or `fallback` when it is not a number.
static func _whole_number(value: Variant, fallback: int) -> int:
	if value is int or value is float:
		return int(value)
	return fallback


static func _ids_from(value: Variant) -> Array[StringName]:
	var ids: Array[StringName] = []
	if value is Array:
		for entry: Variant in value:
			if entry is String or entry is StringName:
				ids.append(StringName(entry))
	return ids


## A Vector2i from a saved [x, y], or null when it is not a pair of numbers.
static func _pair_from(value: Variant) -> Variant:
	if value is Array and value.size() == 2 and (value[0] is int or value[0] is float) and (value[1] is int or value[1] is float):
		return Vector2i(int(value[0]), int(value[1]))
	return null


static func _directions_from(value: Variant) -> Array[Vector2i]:
	var directions: Array[Vector2i] = []
	if value is Array:
		for entry: Variant in value:
			var direction: Variant = _pair_from(entry)
			if direction != null:
				directions.append(direction)
	return directions
