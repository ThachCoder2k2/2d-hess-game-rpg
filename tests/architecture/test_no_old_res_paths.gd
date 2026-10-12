extends UnboundTest

## Architecture guard (ENFORCING since M1b emptied the old folders): no text file
## names a path under a folder the migration removed. The plan's acceptance line
## (docs/game-base-plan.md 15, M1b) is "grep for res://scripts|objects|scenes|resources
## returns 0 outside docs/archive"; this is that grep, run on every suite pass, plus
## the two asset folders that moved (assets/sprites, assets/art).
##
## It reads the same kinds of file tools/move_res.py rewrites (scripts, scenes,
## resources, config, import sidecars, shaders, shell and python tools, markdown,
## json, yaml, dump baselines). Left alone on purpose: docs/archive (history keeps its
## old paths), docs/research (a record of what the codebase looked like), the plan
## itself (it quotes this pattern in its acceptance line), tools/move_res.py (its
## examples) and this file (it names the prefixes).
##
## The prefixes are built from two halves so this file does not match itself.

const ProjectFiles := preload("res://tests/architecture/project_files.gd")

const SCHEME := "res://"
## Folder names that no longer exist at the top of the project (or under assets/).
const REMOVED_FOLDERS: Array[String] = ["scripts/", "objects/", "scenes/", "resources/", "assets/sprites/", "assets/art/"]
const SCANNED_EXTENSIONS: Array[String] = ["gd", "tscn", "tres", "cfg", "godot", "import", "gdshader", "sh", "py", "md", "json", "yml", "yaml", "txt"]
const SKIPPED_PATH_PREFIXES: Array[String] = [
	"res://docs/archive/",
	"res://docs/research/",
	"res://docs/game-base-plan.md",
	"res://tools/move_res.py",
	"res://tests/architecture/test_no_old_res_paths.gd",
]
## Fewer files than this means the walk is broken, not that the tree is clean.
const MINIMUM_FILES_SCANNED := 200
const MAX_LISTED := 25


func _init() -> void:
	suite_title = "ARCHITECTURE NO OLD RES PATHS TEST"
	var removed_prefixes: Array[String] = []
	for removed_folder in REMOVED_FOLDERS:
		removed_prefixes.append(SCHEME + removed_folder)

	var scanned_file_count := 0
	var hit_lines: Array[String] = []
	for file_path in ProjectFiles.collect_files(SCANNED_EXTENSIONS):
		if _is_skipped(file_path):
			continue
		var file_text := ProjectFiles.read_text(file_path)
		scanned_file_count += 1
		if file_text.is_empty():
			continue  # an empty text file names nothing
		var line_number := 0
		for line in file_text.split("\n"):
			line_number += 1
			for removed_prefix in removed_prefixes:
				if line.contains(removed_prefix):
					hit_lines.append("%s:%d  %s" % [file_path, line_number, line.strip_edges().left(120)])
					break

	_expect(scanned_file_count >= MINIMUM_FILES_SCANNED, "the scan read %d text files (at least %d, so a stale path cannot pass vacuously)" % [scanned_file_count, MINIMUM_FILES_SCANNED])
	for index in range(mini(hit_lines.size(), MAX_LISTED)):
		print("REPORT   old path: %s" % hit_lines[index])
	if hit_lines.size() > MAX_LISTED:
		print("REPORT   ... and %d more" % (hit_lines.size() - MAX_LISTED))
	_expect(hit_lines.is_empty(), "no text file names a path under a removed folder (%s): %d line(s) do" % [", ".join(REMOVED_FOLDERS), hit_lines.size()])
	finish()


func _is_skipped(file_path: String) -> bool:
	for skipped_prefix in SKIPPED_PATH_PREFIXES:
		if file_path.begins_with(skipped_prefix):
			return true
	return false
