class_name ContentDb
extends RefCounted

## The content registry (docs/game-base-plan.md 13.3, 14.1): the one place that knows
## what lives in content/ and the only code that loads it by id. A static class, not an
## autoload, so it works inside a suite's `_init()` and in any tool, before a single
## autoload exists. Nothing is loaded at process start.
##
##   ContentDb.ids(&"enemies")                    -> [&"backstep_pawn", &"bishop_zoner", ...]
##   ContentDb.fetch(&"enemies", &"pawn_recruit") -> the EnemyDefinition (null when unknown)
##   ContentDb.all(&"rules")                      -> {id: RuleEntry}
##   ContentDb.player()                           -> content/player/player.tres
##   ContentDb.piece_sizes()                      -> content/feel/piece_sizes.tres
##   ContentDb.credits()                          -> content/story/credits.tres
##
## The id of a thing is its folder name (or its file name for flat kinds), spelled in
## one place; ids are found by listing the folders, once per kind, on first use.
## Everything returned comes from ResourceLoader's shared cache: duplicate() a
## resource before changing it.
##
## validate() checks every entry of every kind (it loads, it is the right class, its
## own validate() is empty, its id property equals its folder, and no reference in its file
## was silently dropped: Godot leaves a property empty, with no message, when the resource
## it names is of another class than the property takes). validate_cross_refs()
## checks that references between content name ids that exist (a Book page's piece, a
## door's target zone and entry, a weapon preference, the world graph against the room
## folders and scenes: see WorldCheck). Both return readable sentences, empty when all is well. Tests and tools
## call them; nothing calls them at game start.
##
## Not built yet: the exported-build fallback `content/_index.json` of plan 14.1.
## ResourceLoader.list_directory is what lists folders, and it works inside a .pck.

const DEFAULT_CONTENT_ROOT := "res://content"
## A folder or file name that is a valid id: lowercase snake_case.
const ID_PATTERN := "^[a-z][a-z0-9_]*$"
## kind name -> ContentKind, built on the first call (a const cannot hold objects).
static var _kind_by_name: Dictionary[StringName, ContentKind] = {}
## kind names in the order validate() reports them.
static var _kind_names: Array[StringName] = []
## kind name -> the ids found on disk, sorted. Filled on the first ask for that kind.
static var _ids_by_kind: Dictionary[StringName, Array] = {}
## The folder every kind lives under. Tests point it at a throwaway tree.
static var _content_root := DEFAULT_CONTENT_ROOT


## Every kind the registry knows, in report order.
static func kinds() -> Array[StringName]:
	_ensure_kinds()
	return _kind_names.duplicate()


static func has_kind(kind_name: StringName) -> bool:
	_ensure_kinds()
	return _kind_by_name.has(kind_name)


## The ids of a kind, sorted. Empty for an unknown kind or an empty folder. Anything
## starting with an underscore (`_shared`) or a dot is not an id.
static func ids(kind_name: StringName) -> Array[StringName]:
	_ensure_kinds()
	var kind: ContentKind = _kind_by_name.get(kind_name)
	var found: Array[StringName] = []
	if kind == null:
		return found
	if not _ids_by_kind.has(kind_name):
		_ids_by_kind[kind_name] = _list_ids(kind)
	found.assign(_ids_by_kind[kind_name])
	return found


static func has_id(kind_name: StringName, id: StringName) -> bool:
	return id in ids(kind_name)


## The main file of an entry as a res:// path ("" for an unknown kind). Does not check
## that the file exists.
static func path_of(kind_name: StringName, id: StringName) -> String:
	_ensure_kinds()
	var kind: ContentKind = _kind_by_name.get(kind_name)
	if kind == null:
		return ""
	return kind.main_file_path(_content_root, id)


## Loads one entry's main file. Null when the kind or the id is unknown or the file is
## missing; it prints nothing, because asking is how code finds out. validate() is
## what explains a broken entry.
static func fetch(kind_name: StringName, id: StringName) -> Resource:
	if not has_id(kind_name, id):
		return null
	var path := path_of(kind_name, id)
	if not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path)


## Every entry of a kind, loaded: id -> resource, in id order. An entry that fails to
## load is left out (validate() reports it).
static func all(kind_name: StringName) -> Dictionary[StringName, Resource]:
	var loaded: Dictionary[StringName, Resource] = {}
	for id in ids(kind_name):
		var resource := fetch(kind_name, id)
		if resource != null:
			loaded[id] = resource
	return loaded


## content/player/player.tres.
static func player() -> PlayerDefinition:
	return fetch(&"player", &"player") as PlayerDefinition


## content/world/world.tres: the one hard-coded content path of the project.
static func world() -> WorldGraph:
	return fetch(&"world", &"world") as WorldGraph


## content/feel/piece_sizes.tres: how big each kind of piece is drawn inside its cell.
static func piece_sizes() -> PieceSizeTable:
	return fetch(&"piece_sizes", &"piece_sizes") as PieceSizeTable


## content/story/credits.tres: the credits roll (the owner, the engine, the licences).
static func credits() -> CreditsDefinition:
	return fetch(&"credits", &"credits") as CreditsDefinition


## Points the registry at another content folder (a throwaway tree under user:// in a
## test) and forgets everything it listed. Pass DEFAULT_CONTENT_ROOT to go back.
static func configure_root(content_root: String) -> void:
	_content_root = content_root
	clear_cache()


## Forgets the listed ids, so the next call lists the folders again.
static func clear_cache() -> void:
	_ids_by_kind.clear()


## Problems with the entries themselves, one sentence each (empty = healthy). For every
## kind: the folder exists; each id is lowercase snake_case; the main file exists, loads
## and is the right class; the class's own validate() is empty; an `id` property equals
## the folder name and no two entries claim the same one; every property the main file (or a
## resource file it names) assigns a resource to actually holds one.
static func validate() -> PackedStringArray:
	_ensure_kinds()
	var problems := PackedStringArray()
	var checked_reference_paths: Dictionary[String, bool] = {}
	for kind_name in _kind_names:
		var kind: ContentKind = _kind_by_name[kind_name]
		if not DirAccess.dir_exists_absolute(kind.directory_path(_content_root)):
			problems.append("%s: the folder %s does not exist." % [kind_name, kind.directory_path(_content_root)])
			continue
		var entry_ids := ids(kind_name)
		if kind.id_source == ContentKind.IdSource.KIND_ITSELF and entry_ids.is_empty():
			problems.append("%s: the file %s does not exist." % [kind_name, kind.main_file_path(_content_root, kind_name)])
		var entry_by_claimed_id: Dictionary[String, StringName] = {}
		for id in entry_ids:
			_validate_entry(kind, id, entry_by_claimed_id, problems, checked_reference_paths)
		for misspelled_id in _ids_that_break_the_naming_rule(kind):
			problems.append("%s/%s: a name is the id, so it must be lowercase snake_case (a-z, 0-9, _), starting with a letter." % [kind_name, misspelled_id])
	return problems


## Problems with references between entries, one sentence each (empty = healthy):
## Book pages name an enemy that exists; an enemy's default weapon, difficulty and
## weapon preferences name pickups and difficulty profiles that exist; the player's
## attacks are skills; every visual's piece type is a row of the size table and its body
## picture fits that row (a tight picture inside the box, or the art spec's cell canvas with
## its drawn pixels inside the box); the world graph and the room folders agree; every door
## leads to a zone of the graph and to an entry marker that exists there; every room's
## zone_id equals its folder; every enemy parked in a room is a registered enemy.
static func validate_cross_refs() -> PackedStringArray:
	var problems := PackedStringArray()
	_check_rule_pages(problems)
	_check_enemy_references(problems)
	_check_player_references(problems)
	_check_visual_references(problems)
	_check_world_and_rooms(problems)
	return problems


# --------------------------------------------------------------------------- kinds
static func _ensure_kinds() -> void:
	if not _kind_names.is_empty():
		return
	_add_kind(ContentKind.new(&"player", ContentKind.IdSource.KIND_ITSELF, "player.tres", PlayerDefinition))
	_add_kind(ContentKind.new(&"world", ContentKind.IdSource.KIND_ITSELF, "world.tres", WorldGraph))
	_add_kind(ContentKind.new(&"piece_sizes", ContentKind.IdSource.KIND_ITSELF, "piece_sizes.tres", PieceSizeTable, &"feel"))
	_add_kind(ContentKind.new(&"credits", ContentKind.IdSource.KIND_ITSELF, "credits.tres", CreditsDefinition, &"story"))
	_add_kind(ContentKind.new(&"enemies", ContentKind.IdSource.FOLDER_NAME, "{id}/enemy.tres", EnemyDefinition))
	_add_kind(ContentKind.new(&"rooms", ContentKind.IdSource.FOLDER_NAME, "{id}/room.tscn", PackedScene))
	_add_kind(ContentKind.new(&"rules", ContentKind.IdSource.FOLDER_NAME, "{id}/page.tres", RuleEntry))
	_add_kind(ContentKind.new(&"skills", ContentKind.IdSource.FOLDER_NAME, "{id}/{id}.tres", AttackProfile))
	_add_kind(ContentKind.new(&"pickups", ContentKind.IdSource.FOLDER_NAME, "{id}/{id}.tres", EnemyWeapon))
	_add_kind(ContentKind.new(&"difficulty", ContentKind.IdSource.FILE_NAME, "{id}.tres", DifficultyProfile))
	_add_kind(ContentKind.new(&"tilesets", ContentKind.IdSource.FOLDER_NAME, "{id}/tileset.tres", TileSet))


static func _add_kind(kind: ContentKind) -> void:
	_kind_by_name[kind.kind_name] = kind
	_kind_names.append(kind.kind_name)


# --------------------------------------------------------------------------- listing
static func _list_ids(kind: ContentKind) -> Array[StringName]:
	var found: Array[StringName] = []
	var directory := kind.directory_path(_content_root)
	if not DirAccess.dir_exists_absolute(directory):
		return found
	match kind.id_source:
		ContentKind.IdSource.KIND_ITSELF:
			if ResourceLoader.exists(kind.main_file_path(_content_root, kind.kind_name)):
				found.append(kind.kind_name)
		ContentKind.IdSource.FOLDER_NAME:
			for entry_name in ResourceLoader.list_directory(directory):
				if entry_name.ends_with("/") and _is_listable_name(entry_name.trim_suffix("/")):
					found.append(StringName(entry_name.trim_suffix("/")))
		ContentKind.IdSource.FILE_NAME:
			var extension := kind.main_file_pattern.get_extension()
			for entry_name in ResourceLoader.list_directory(directory):
				if not entry_name.ends_with("/") and entry_name.get_extension() == extension \
						and _is_listable_name(entry_name.get_basename()):
					found.append(StringName(entry_name.get_basename()))
	found.sort_custom(func(first: StringName, second: StringName) -> bool: return String(first) < String(second))
	return found


## A name that can be an id: not `_shared`-style and not hidden.
static func _is_listable_name(entry_name: String) -> bool:
	return not entry_name.begins_with("_") and not entry_name.begins_with(".")


## Listed ids that break the lowercase snake_case rule. Reported once, by validate();
## the ids themselves stay usable.
static func _ids_that_break_the_naming_rule(kind: ContentKind) -> Array[String]:
	var offenders: Array[String] = []
	var id_pattern := RegEx.create_from_string(ID_PATTERN)
	for id in ids(kind.kind_name):
		if id_pattern.search(String(id)) == null:
			offenders.append(String(id))
	return offenders


# --------------------------------------------------------------------------- validate()
static func _validate_entry(kind: ContentKind, id: StringName, entry_by_claimed_id: Dictionary[String, StringName], problems: PackedStringArray, checked_reference_paths: Dictionary[String, bool]) -> void:
	var label := "%s/%s" % [kind.kind_name, id]
	var path := kind.main_file_path(_content_root, id)
	if not ResourceLoader.exists(path):
		problems.append("%s: the main file %s is missing." % [label, path])
		return
	var resource := ResourceLoader.load(path)
	if resource == null:
		problems.append("%s: %s does not load." % [label, path])
		return
	if not is_instance_of(resource, kind.expected_type):
		problems.append("%s: %s loads as %s, which is not the class this kind needs." % [label, path, _class_label(resource)])
		return
	if resource is PackedScene and not (resource as PackedScene).can_instantiate():
		problems.append("%s: %s is not a scene that can be instanced." % [label, path])
	_check_dropped_references(label, resource, problems, checked_reference_paths)
	if kind.expects_validate_method():
		if resource.has_method(&"validate"):
			for warning in resource.call(&"validate"):
				problems.append("%s: %s" % [label, warning])
		else:
			problems.append("%s: its class has no validate() method; every definition class needs one." % label)
	if kind.id_source != ContentKind.IdSource.KIND_ITSELF and &"id" in resource:
		var claimed_id := String(resource.get(&"id"))
		if claimed_id != String(id):
			problems.append("%s: its id property says '%s' but its folder (the id) says '%s'; they must be equal." % [label, claimed_id, id])
		elif entry_by_claimed_id.has(claimed_id):
			problems.append("%s: the id '%s' is already claimed by %s." % [label, claimed_id, entry_by_claimed_id[claimed_id]])
		entry_by_claimed_id[claimed_id] = id


# --------------------------------------------------------------------------- dropped references
## A property whose file line says `name = ExtResource(...)` (or SubResource) must hold something
## once loaded. When the named resource is of another class than the property takes (a skill
## where a weapon belongs), Godot leaves the property null and prints nothing, and an optional
## field would then lose its value in silence. The `.tres` text is read for the names assigned a
## resource in its `[resource]` section and each is compared with the loaded value. Resource files
## the property names (a visual, an attack) are checked the same way, once each per validate().
static func _check_dropped_references(label: String, resource: Resource, problems: PackedStringArray, checked_reference_paths: Dictionary[String, bool]) -> void:
	var path := resource.resource_path
	if not path.ends_with(".tres") or checked_reference_paths.has(path):
		return
	checked_reference_paths[path] = true
	for property_name in _property_names_assigned_a_resource_in(path):
		if not (property_name in resource):
			continue
		var value: Variant = resource.get(property_name)
		if value == null:
			problems.append("%s: in %s the property '%s' names a resource, but it is empty: the file is missing, does not load, or is not the class this property takes." % [label, path, property_name])
		elif value is Resource:
			_check_dropped_references(label, value as Resource, problems, checked_reference_paths)


## The names of the properties the `[resource]` section of a .tres assigns an ExtResource or
## SubResource (a single resource, not an array or dictionary of them).
static func _property_names_assigned_a_resource_in(path: String) -> Array[StringName]:
	var names: Array[StringName] = []
	var assignment := RegEx.create_from_string("^([A-Za-z_][A-Za-z0-9_]*) = (ExtResource|SubResource)\\(")
	var in_resource_section := false
	for line in FileAccess.get_file_as_string(path).split("\n"):
		if line.begins_with("["):
			in_resource_section = line.strip_edges() == "[resource]"
			continue
		if not in_resource_section:
			continue
		var found := assignment.search(line)
		if found != null:
			names.append(StringName(found.get_string(1)))
	return names


# --------------------------------------------------------------------------- cross references
static func _check_rule_pages(problems: PackedStringArray) -> void:
	for page_id in ids(&"rules"):
		var page := fetch(&"rules", page_id) as RuleEntry
		if page != null and not has_id(&"enemies", page.piece_id):
			problems.append("rules/%s: piece_id '%s' is not an enemy (content/enemies/ has: %s)." % [page_id, page.piece_id, _id_list(&"enemies")])


static func _check_enemy_references(problems: PackedStringArray) -> void:
	for enemy_id in ids(&"enemies"):
		var enemy := fetch(&"enemies", enemy_id) as EnemyDefinition
		if enemy == null:
			continue
		var label := "enemies/%s" % enemy_id
		_expect_registered(problems, label, "difficulty", enemy.difficulty, &"difficulty")
		_expect_registered(problems, label, "default_weapon", enemy.default_weapon, &"pickups")
		for weapon_id: Variant in enemy.weapon_preferences:
			if not has_id(&"pickups", StringName(String(weapon_id))):
				problems.append("%s: weapon_preferences names '%s', which is not a pickup (content/pickups/ has: %s)." % [label, weapon_id, _id_list(&"pickups")])


static func _check_player_references(problems: PackedStringArray) -> void:
	var definition := player()
	if definition == null:
		return
	_expect_registered(problems, "player/player", "wooden_sword", definition.wooden_sword, &"skills")
	_expect_registered(problems, "player/player", "pencil_thrust", definition.pencil_thrust, &"skills")


## Every actor's VisualDefinition names a kind of piece the size table has a row for, and its body
## picture fits that row (the owner's rule: a piece is smaller than its cell): no larger than the
## row's box, or the cell-sized canvas of the art spec with its drawn pixels inside the box
## (PieceSizeTable.picture_problems).
static func _check_visual_references(problems: PackedStringArray) -> void:
	var table := piece_sizes()
	if table == null:
		return
	var visual_by_owner: Dictionary[String, VisualDefinition] = {}
	var player_definition := player()
	if player_definition != null and player_definition.visual != null:
		visual_by_owner["player/player"] = player_definition.visual
	for enemy_id in ids(&"enemies"):
		var enemy := fetch(&"enemies", enemy_id) as EnemyDefinition
		if enemy != null and enemy.visual != null:
			visual_by_owner["enemies/%s" % enemy_id] = enemy.visual
	for owner_label in visual_by_owner:
		var visual: VisualDefinition = visual_by_owner[owner_label]
		if visual.piece_type == &"":
			continue
		var row := table.row_for(visual.piece_type)
		if row == null:
			var kinds := PackedStringArray()
			for piece_type in table.piece_types():
				kinds.append(String(piece_type))
			problems.append("%s: its visual's piece_type '%s' is not a row of content/feel/piece_sizes.tres (rows: %s)." % [owner_label, visual.piece_type, ", ".join(kinds)])
			continue
		if visual.body_texture != null:
			for sentence in table.picture_problems_of_texture(visual.piece_type, visual.body_texture):
				problems.append("%s: %s" % [owner_label, sentence])


## The world graph against the room folders and the room scenes: WorldCheck does the checking (its header lists
## what), this reports every sentence of it except the graph-as-data ones (validate() already reports those with the
## entry's label) and asks each room's parked enemies to be registered.
static func _check_world_and_rooms(problems: PackedStringArray) -> void:
	var graph := world()
	if graph == null:
		return
	var scan_by_room: Dictionary[StringName, RoomScan] = {}
	for room_id in graph.room_ids():
		var scan := RoomScan.of(graph.get_zone_scene(room_id))
		if scan != null:
			scan_by_room[room_id] = scan
	var scene_path_of := func(room_id: StringName) -> String: return path_of(&"rooms", room_id)
	var problems_by_check := WorldCheck.run(graph, scan_by_room, ids(&"rooms"), scene_path_of, TextService.has_key)
	for check in WorldCheck.CHECKS:
		if check != WorldCheck.CHECK_GRAPH:
			problems.append_array(problems_by_check[check])
	for room_id in scan_by_room:
		for enemy in (scan_by_room[room_id] as RoomScan).enemy_definitions:
			_expect_registered(problems, "rooms/%s" % room_id, "an enemy parked here", enemy, &"enemies")



## Adds a problem unless `resource` is null (validate() reports a missing required
## field) or its file is the main file of a registered entry of `kind_name`.
static func _expect_registered(problems: PackedStringArray, owner_label: String, field_label: String, resource: Resource, kind_name: StringName) -> void:
	if resource == null:
		return
	var registered_id := _registered_id_of(resource, kind_name)
	if registered_id == &"" or not has_id(kind_name, registered_id):
		problems.append("%s: %s is %s, which is not an entry of content/%s/ (ids: %s)." % [owner_label, field_label, resource.resource_path, kind_name, _id_list(kind_name)])


## The id of the entry whose files include `resource`, or &"" when it lives elsewhere.
static func _registered_id_of(resource: Resource, kind_name: StringName) -> StringName:
	_ensure_kinds()
	var kind: ContentKind = _kind_by_name.get(kind_name)
	if kind == null:
		return &""
	var folder_prefix := kind.directory_path(_content_root) + "/"
	if not resource.resource_path.begins_with(folder_prefix):
		return &""
	var below_folder := resource.resource_path.trim_prefix(folder_prefix)
	if kind.id_source == ContentKind.IdSource.FILE_NAME:
		return StringName(below_folder.get_basename())
	return StringName(below_folder.get_slice("/", 0))


## The class a resource is, by the name a person knows it as (RuleEntry, not Resource).
static func _class_label(resource: Resource) -> String:
	var resource_script := resource.get_script() as Script
	if resource_script != null and not resource_script.get_global_name().is_empty():
		return String(resource_script.get_global_name())
	return resource.get_class()


static func _id_list(kind_name: StringName) -> String:
	var texts := PackedStringArray()
	for id in ids(kind_name):
		texts.append(String(id))
	return ", ".join(texts)
