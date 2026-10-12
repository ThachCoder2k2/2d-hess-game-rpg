extends RefCounted

## Shared by the architecture guards in this folder: one way to walk the project
## tree, so every guard sees the same files. No class_name on purpose: guards
## preload() it, which works on a fresh checkout before the import pass.

## Folders no guard looks into: Godot's cache, git, agent worktrees and third-party code.
const SKIPPED_DIRECTORY_NAMES: Array[String] = [".godot", ".git", ".claude", "addons"]


## Every file under directory_path (default: the project) whose extension is in extensions,
## as sorted res:// paths. A folder holding a .gdignore file is skipped, like Godot does.
static func collect_files(extensions: Array[String], directory_path := "res://") -> Array[String]:
	var found_paths: Array[String] = []
	_collect(extensions, directory_path, found_paths)
	found_paths.sort()
	return found_paths


static func _collect(extensions: Array[String], directory_path: String, found_paths: Array[String]) -> void:
	if FileAccess.file_exists(directory_path.path_join(".gdignore")):
		return
	for file_name in DirAccess.get_files_at(directory_path):
		if file_name.get_extension() in extensions:
			found_paths.append(directory_path.path_join(file_name))
	for directory_name in DirAccess.get_directories_at(directory_path):
		if directory_name in SKIPPED_DIRECTORY_NAMES:
			continue
		_collect(extensions, directory_path.path_join(directory_name), found_paths)


## The text of a file, or "" when it cannot be read. Callers assert non-empty where it matters.
static func read_text(path: String) -> String:
	return FileAccess.get_file_as_string(path)


## The lines of `git ls-files` for the project, or an empty array (and a reason) when git or the
## repository is unavailable. Returns { "files": Array[String] of root-relative paths, "error": String }.
static func git_tracked_files() -> Dictionary:
	var project_directory := ProjectSettings.globalize_path("res://").trim_suffix("/")
	var output: Array = []
	# One path per line (no -z: Godot's string decoding rejects the NUL separators). quotepath=false keeps
	# non-ASCII names unquoted. Names with a newline in them do not exist in this project.
	var exit_code := OS.execute("git", ["-C", project_directory, "-c", "core.quotepath=false", "ls-files"], output, true)
	if exit_code != 0 or output.is_empty():
		return {"files": [] as Array[String], "error": "git ls-files failed (exit %d); is this a git checkout with git on PATH?" % exit_code}
	var tracked: Array[String] = []
	for name in String(output[0]).split("\n", false):
		tracked.append(name)
	return {"files": tracked, "error": ""}
