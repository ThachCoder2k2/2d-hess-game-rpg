extends UnboundTest

## Architecture guard (ENFORCING since M1b moved the content): content/ is the
## owner's folder (data, art, audio, words) and holds ZERO .gd files, so the owner
## can change any of it without touching code (docs/game-base-plan.md 13.1, 13.2).
## It also checks that "folder = id" holds: every id folder carries the role file
## its kind needs (an enemy folder holds enemy.tres, a room folder holds room.tscn,
## a rule page folder holds page.tres). A leading underscore (_shared) is not an id.
##
## The scan asserts a minimum number of files, so a stale path or an empty content/
## folder fails instead of passing vacuously ("zero scripts among zero files").

const ProjectFiles := preload("res://tests/architecture/project_files.gd")

const CONTENT_DIRECTORY := "res://content"
## content/ today holds 35 .tres, 8 .tscn and 8 .png. Fewer than this means files vanished
## or the walk is broken, never that the tree got tidier.
const MINIMUM_CONTENT_FILES := 40
const MINIMUM_ROOMS := 6
const MINIMUM_ENEMIES := 7
const MINIMUM_RULE_PAGES := 5
## id folder under content/ -> the file every folder of that kind must contain.
const ROLE_FILE_BY_KIND_FOLDER := {
	"enemies": "enemy.tres",
	"rooms": "room.tscn",
	"rules": "page.tres",
}
const MINIMUM_IDS_BY_KIND_FOLDER := {
	"enemies": MINIMUM_ENEMIES,
	"rooms": MINIMUM_ROOMS,
	"rules": MINIMUM_RULE_PAGES,
}


func _init() -> void:
	suite_title = "ARCHITECTURE CONTENT HAS NO GD TEST"
	if not _expect(DirAccess.dir_exists_absolute(CONTENT_DIRECTORY), "content/ exists"):
		finish()
		return

	var script_paths := ProjectFiles.collect_files(["gd"], CONTENT_DIRECTORY)
	for script_path in script_paths:
		print("REPORT   script in content/: %s" % script_path)
	_expect(script_paths.is_empty(), "content/ holds no .gd file (%d found; a script belongs in schema, ecs, authoring, presentation or shell)" % script_paths.size())

	var data_files := ProjectFiles.collect_files(["tres", "tscn", "png", "svg", "wav", "ogg", "po", "txt", "json"], CONTENT_DIRECTORY)
	_expect(data_files.size() >= MINIMUM_CONTENT_FILES, "the scan saw %d content files (at least %d, so an empty folder cannot pass)" % [data_files.size(), MINIMUM_CONTENT_FILES])

	for kind_folder: String in ROLE_FILE_BY_KIND_FOLDER:
		var role_file: String = ROLE_FILE_BY_KIND_FOLDER[kind_folder]
		var kind_directory := CONTENT_DIRECTORY.path_join(kind_folder)
		var id_count := 0
		var folders_without_role_file: Array[String] = []
		for id_folder in DirAccess.get_directories_at(kind_directory):
			if id_folder.begins_with("_"):
				continue
			id_count += 1
			if not FileAccess.file_exists(kind_directory.path_join(id_folder).path_join(role_file)):
				folders_without_role_file.append(id_folder)
		_expect(id_count >= int(MINIMUM_IDS_BY_KIND_FOLDER[kind_folder]), "content/%s holds at least %d id folders (found %d)" % [kind_folder, MINIMUM_IDS_BY_KIND_FOLDER[kind_folder], id_count])
		_expect(folders_without_role_file.is_empty(), "every content/%s/<id>/ folder holds %s (missing in: %s)" % [kind_folder, role_file, ", ".join(folders_without_role_file)])
	finish()
