class_name ContentKind
extends RefCounted

## One kind of content the registry (ContentDb) knows: which folder of content/ holds
## it, how its ids are spelled on disk, which file is its main file and which class that
## file must load as. A kind is a row in ContentDb._build_kinds(); adding one is one line.

## Where the ids of a kind are spelled on disk.
enum IdSource {
	## content/<name>/<id>/<main file>: the id is the folder name. A folder starting with
	## an underscore (_shared) or a dot is not an id.
	FOLDER_NAME,
	## content/<name>/<id>.<extension>: the id is the file name without its extension.
	FILE_NAME,
	## content/<name>/<main file>: one-of-a-kind content (the player, the world). The
	## kind's own name is its only id.
	KIND_ITSELF,
}

## The kind's name (for example `enemies`).
var kind_name: StringName
## The folder it owns under content/. The kind's own name unless the constructor was given
## another: `piece_sizes` lives in content/feel/ next to the other feel files.
var folder_name: StringName
var id_source: IdSource
## The main file, relative to content/<name>/. `{id}` stands for the id: `{id}/enemy.tres`
## for a folder kind, `{id}.tres` for a file kind, `player.tres` for a one-of-a-kind file.
var main_file_pattern: String
## The class the main file must load as: a script class (EnemyDefinition) or an engine
## class (PackedScene). Checked with is_instance_of, so a subclass passes.
var expected_type: Variant


func _init(kind_name_value: StringName, source: IdSource, pattern: String, type: Variant, folder_name_value: StringName = &"") -> void:
	kind_name = kind_name_value
	folder_name = folder_name_value if folder_name_value != &"" else kind_name_value
	id_source = source
	main_file_pattern = pattern
	expected_type = type


## The main file of `id` under `content_root` (no check that it exists).
func main_file_path(content_root: String, id: StringName) -> String:
	return directory_path(content_root).path_join(main_file_pattern.replace("{id}", String(id)))


## The folder this kind owns.
func directory_path(content_root: String) -> String:
	return content_root.path_join(String(folder_name))


## True when the kind's class is a script class, so it must define `validate()`.
func expects_validate_method() -> bool:
	return expected_type is Script
