extends UnboundTest

## Every definition under content/ passes its own validate(), every id equals its folder,
## no id is claimed twice and the registry sees at least as much as is on disk (docs/
## game-base-plan.md 15 M2 acceptance). The scan asserts minimum counts, so a stale
## path or an empty folder fails instead of passing vacuously.
##
## ContentDb.validate() does the checking; this suite re-checks the claims that matter
## through a second route (a plain folder listing, a direct validate() call per entry), so
## a bug in the registry cannot hide a problem in the content, and a content kind added
## without a minimum here fails and has to be given one.

## kind -> the fewest entries content/ holds today. Raise it when content is added;
## lowering it means content vanished.
const MINIMUM_IDS_BY_KIND := {
	&"player": 1,
	&"world": 1,
	&"piece_sizes": 1,
	&"credits": 1,
	&"ending": 1,
	&"enemies": 14,
	&"rooms": 34,
	&"rules": 5,
	&"skills": 2,
	&"pickups": 3,
	&"difficulty": 1,
	&"tilesets": 3,
}
## Kinds that are one file with the kind's own name as its only id (content/player/player.tres,
## content/feel/piece_sizes.tres): they have no id property to compare with a folder.
const ONE_OF_A_KIND_KINDS: Array[StringName] = [&"player", &"world", &"piece_sizes", &"credits", &"ending"]
## Entries whose class is a script class and so must answer validate(): player, world, the piece
## size table, the credits, the ending, 14 enemies, 5 rules, 2 skills, 3 pickups and 1 difficulty profile.
const MINIMUM_VALIDATED_DEFINITIONS := 30


func _init() -> void:
	suite_title = "TEST VALIDATE ALL"
	var validated_definition_count := 0
	var claimed_id_count := 0
	for kind_name in ContentDb.kinds():
		_expect(MINIMUM_IDS_BY_KIND.has(kind_name), "kind '%s' has a minimum entry count in this suite" % kind_name)
		var entry_ids := ContentDb.ids(kind_name)
		_expect(entry_ids.size() >= int(MINIMUM_IDS_BY_KIND.get(kind_name, 1)),
			"content/%s holds at least %d entries (found %d)" % [kind_name, int(MINIMUM_IDS_BY_KIND.get(kind_name, 1)), entry_ids.size()])
		_expect(_ids_are_unique(entry_ids), "content/%s lists no id twice" % kind_name)
		_expect(_ids_match_a_plain_listing(kind_name, entry_ids), "content/%s: the registry's ids are exactly the folders (or files) on disk" % kind_name)

		var claimed_owner_by_id: Dictionary[String, StringName] = {}
		for id in entry_ids:
			var resource := ContentDb.fetch(kind_name, id)
			if not _expect(resource != null, "%s/%s loads" % [kind_name, id]):
				continue
			if resource.has_method(&"validate"):
				var warnings: PackedStringArray = resource.call(&"validate")
				for warning in warnings:
					printerr("  %s/%s: %s" % [kind_name, id, warning])
				_expect(warnings.is_empty(), "%s/%s passes its own validate()" % [kind_name, id])
				validated_definition_count += 1
			if kind_name not in ONE_OF_A_KIND_KINDS and &"id" in resource:
				var claimed_id := String(resource.get(&"id"))
				_expect(claimed_id == String(id), "%s/%s: its id property '%s' equals its folder" % [kind_name, id, claimed_id])
				_expect(not claimed_owner_by_id.has(claimed_id), "%s/%s: the id '%s' is claimed once" % [kind_name, id, claimed_id])
				claimed_owner_by_id[claimed_id] = id
				claimed_id_count += 1

	_expect(validated_definition_count >= MINIMUM_VALIDATED_DEFINITIONS,
		"validate() was called on %d definitions (at least %d, so the loop cannot be empty)" % [validated_definition_count, MINIMUM_VALIDATED_DEFINITIONS])
	_expect(claimed_id_count >= 10, "%d entries carry an id property that was compared with their folder (at least 10)" % claimed_id_count)

	var registry_problems := ContentDb.validate()
	for problem in registry_problems:
		printerr("  problem: %s" % problem)
	_expect(registry_problems.is_empty(), "ContentDb.validate() reports nothing (%d problem(s))" % registry_problems.size())
	var reference_problems := ContentDb.validate_cross_refs()
	for problem in reference_problems:
		printerr("  problem: %s" % problem)
	_expect(reference_problems.is_empty(), "ContentDb.validate_cross_refs() reports nothing (%d problem(s))" % reference_problems.size())
	finish()


func _ids_are_unique(entry_ids: Array[StringName]) -> bool:
	var seen: Dictionary[StringName, bool] = {}
	for id in entry_ids:
		if seen.has(id):
			return false
		seen[id] = true
	return true


## Lists the kind's folder with DirAccess (not ResourceLoader.list_directory, which the
## registry uses) and compares. A one-of-a-kind file has the kind's own name as its id.
func _ids_match_a_plain_listing(kind_name: StringName, entry_ids: Array[StringName]) -> bool:
	if kind_name in ONE_OF_A_KIND_KINDS:
		return entry_ids == [kind_name] and FileAccess.file_exists(ContentDb.path_of(kind_name, kind_name))
	var directory := "res://content/%s" % kind_name
	var on_disk: Array[StringName] = []
	if kind_name == &"difficulty":
		for file_name in DirAccess.get_files_at(directory):
			if file_name.ends_with(".tres") and not file_name.begins_with("_"):
				on_disk.append(StringName(file_name.get_basename()))
	else:
		for folder_name in DirAccess.get_directories_at(directory):
			if not folder_name.begins_with("_") and not folder_name.begins_with("."):
				on_disk.append(StringName(folder_name))
	on_disk.sort_custom(func(first: StringName, second: StringName) -> bool: return String(first) < String(second))
	return on_disk == entry_ids
